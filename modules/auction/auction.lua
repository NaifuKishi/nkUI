local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.auction = {}

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events
local auction       = privateVars.auction
local langTexts     = privateVars.langTexts

local InspectTimeReal       = Inspect.Time.Real
local InspectAuctionDetail  = Inspect.Auction.Detail
local InspectItemDetail     = Inspect.Item.Detail
local InspectShard          = Inspect.Shard

local osTime        = os.time
local stringFormat  = string.format
local mathFloor     = math.floor
local mathMax       = math.max
local mathMin       = math.min

local SNAPSHOT_CAPACITY = 30  -- ring buffer size per item

local context = UI.CreateContext("nkUI.auction")
context:SetStrata('dialog')
context:SetLayer(3)

---------- scan state ----------

local fullScanPending = false
local browseSearchPending = false

---------- data model helpers ----------

local function initShard(shard)
    if not nkUIAucData then nkUIAucData = {} end
    if not nkUIAucData[shard] then
        nkUIAucData[shard] = {
            schemaVer   = 1,
            lastScan    = nil,
            items       = {},
        }
    end
    -- migrate old schema (pre-phase1): contained auctions{} and flat price fields
    local shardData = nkUIAucData[shard]
    if shardData.schemaVer == nil then
        shardData.schemaVer  = 1
        shardData.auctions   = nil   -- drop old auction ID table
        -- old items had lowestPrice/highestPrice/avgPrice/count — convert to one snapshot
        for itemType, old in pairs(shardData.items or {}) do
            if old.lowestPrice ~= nil then
                shardData.items[itemType] = {
                    name         = old.name,
                    icon         = old.icon,
                    rarity       = old.rarity,
                    vendor       = nil,
                    snapshots    = { [1] = { t = old.lastSeen or 0, lo = old.lowestPrice, hi = old.highestPrice, count = old.count or 1 } },
                    snapshotHead = 1,
                }
            end
        end
    end
end

-- Write one snapshot entry into the ring buffer for itemType.
local function writeSnapshot(shard, itemType, scanTime, lo, hi, count)
    local shardData = nkUIAucData[shard]
    local item = shardData.items[itemType]

    if item == nil then return end  -- must be seeded via seedItem first

    local head = (item.snapshotHead or 0) % SNAPSHOT_CAPACITY + 1
    item.snapshots[head] = { t = scanTime, lo = lo, hi = hi, count = count }
    item.snapshotHead = head
end

-- Seed item metadata on first encounter.
local function seedItem(shard, itemType, name, icon, rarity, vendor)
    local shardData = nkUIAucData[shard]
    if shardData.items[itemType] == nil then
        shardData.items[itemType] = {
            name         = name,
            icon         = icon,
            rarity       = rarity or 0,
            vendor       = vendor,
            snapshots    = {},
            snapshotHead = 0,
        }
    else
        -- update mutable fields in case they were missing
        local item = shardData.items[itemType]
        if name   ~= nil then item.name   = name   end
        if icon   ~= nil then item.icon   = icon   end
        if rarity ~= nil then item.rarity = rarity end
        if vendor ~= nil then item.vendor = vendor end
    end
end

---------- public price API ----------

-- Returns a price summary across the last `depth` snapshots (default: scanDepth setting).
-- Returns nil if no data exists for the item.
function auction.getPriceSummary(itemType)
    if not nkUIAucData then return nil end
    local shard = InspectShard().name
    local shardData = nkUIAucData[shard]
    if shardData == nil then return nil end
    local item = shardData.items[itemType]
    if item == nil or item.snapshots == nil then return nil end

    local depth = (nkUISetup and nkUISetup.modules.auction and nkUISetup.modules.auction.scanDepth) or 3
    local head  = item.snapshotHead or 0
    if head == 0 then return nil end

    local loAll, hiAll, loRecent, count = math.huge, 0, nil, 0
    local total, snapCount = 0, 0
    local latestTime = 0

    for i = 0, mathMin(depth, SNAPSHOT_CAPACITY) - 1 do
        local idx = (head - 1 - i) % SNAPSHOT_CAPACITY + 1
        local snap = item.snapshots[idx]
        if snap and snap.t and snap.t > 0 then
            loAll    = mathMin(loAll, snap.lo)
            hiAll    = mathMax(hiAll, snap.hi)
            total    = total + snap.lo   -- average over lowest price per scan
            snapCount = snapCount + 1
            count    = count + (snap.count or 1)
            if snap.t > latestTime then
                latestTime = snap.t
                loRecent   = snap.lo
            end
        end
    end

    if snapCount == 0 then return nil end

    return {
        lo        = loAll,
        hi        = hiAll,
        avg       = mathFloor(total / snapCount),
        lastLo    = loRecent,
        snapCount = snapCount,
        totalSeen = count,
        lastSeen  = latestTime,
        daysSince = mathFloor((osTime() - latestTime) / 86400),
    }
end

-- Returns the ratio of the last-known AH floor price to vendor sell value.
-- e.g. 3.5 means cheapest AH listing is 3.5x vendor price.
-- Returns nil if either value is unknown or vendor is zero.
function auction.getVendorRatio(itemType)
    if not nkUIAucData then return nil end
    local shard = InspectShard().name
    local shardData = nkUIAucData[shard]
    if shardData == nil then return nil end
    local item = shardData.items[itemType]
    if item == nil then return nil end

    local vendor = item.vendor
    if vendor == nil or vendor <= 0 then return nil end

    local summary = auction.getPriceSummary(itemType)
    if summary == nil or summary.lastLo == nil then return nil end

    return summary.lastLo / vendor
end

---------- scan engine ----------

-- Processes one batch (table of up to 50 auction IDs) within a coroutine.
-- Accumulates per-item lo/hi/count, then writes one snapshot per item at end.
local function processBatch(batch, scanTime, shard, accumulator)
    for i = 1, #batch do
        local detail = InspectAuctionDetail(batch[i])
        if detail and detail.itemType and detail.buyout then
            local stack = detail.itemStack or 1
            local unitPrice = mathFloor(detail.buyout / stack)

            local itemType = detail.itemType
            local acc = accumulator[itemType]

            if acc == nil then
                -- First time seeing this item in this scan — fetch metadata
                local itemDetail = InspectItemDetail(detail.item or detail.itemType)
                local name, icon, rarity, vendor
                if itemDetail then
                    name   = itemDetail.name
                    icon   = itemDetail.icon
                    rarity = itemDetail.rarity
                    vendor = itemDetail.sell  -- copper value from vendor
                end
                seedItem(shard, itemType, name, icon, rarity, vendor)

                accumulator[itemType] = { lo = unitPrice, hi = unitPrice, count = 1 }
            else
                if unitPrice < acc.lo then acc.lo = unitPrice end
                if unitPrice > acc.hi then acc.hi = unitPrice end
                acc.count = acc.count + 1
            end
        end
    end
end

-- Flushes the scan accumulator: writes one snapshot per item.
local function flushAccumulator(accumulator, scanTime, shard)
    for itemType, acc in pairs(accumulator) do
        writeSnapshot(shard, itemType, scanTime, acc.lo, acc.hi, acc.count)
    end
end

-- Internal: called from Event.Auction.Scan handler.
-- onProgress(pct)          — called each coroutine tick (0–100)
-- onComplete(newCount)     — called when processing finishes
local function runScanProcessing(rawAuctions, onProgress, onComplete)

    local shard    = InspectShard().name
    local scanTime = osTime()

    initShard(shard)

    -- Split all auction IDs into batches of 50
    local batches   = {}
    local batch     = {}
    local total     = 0
    for auctionID in pairs(rawAuctions) do
        table.insert(batch, auctionID)
        total = total + 1
        if #batch >= 50 then
            table.insert(batches, batch)
            batch = {}
        end
    end
    if #batch > 0 then table.insert(batches, batch) end

    if total == 0 then
        if onComplete then onComplete(0) end
        return
    end

    local accumulator = {}
    local processed   = 0

    local co = coroutine.create(function()
        for b = 1, #batches do
            processBatch(batches[b], scanTime, shard, accumulator)
            processed = processed + #batches[b]
            if onProgress then
                onProgress(mathFloor(processed / total * 100))
            end
            coroutine.yield(true)   -- yield between batches, not per-auction
        end
        flushAccumulator(accumulator, scanTime, shard)
        nkUIAucData[shard].lastScan = scanTime
        if onComplete then onComplete(total) end
    end)

    LibEKL.Coroutines.Add({ func = co, active = true })
end

---------- scan dialog (called from bag UI) ----------

local scanDialog

local function buildScanDialog()
    scanDialog = LibEKL.UICreateFrame("nkWindow", "nkUI.auction.scanDialog", context)
    scanDialog:ClearAll()
    scanDialog:SetTitle("nkUI")
    scanDialog:SetTitleAlign('center')
    scanDialog:SetWidth(400)
    scanDialog:SetHeight(150)
    scanDialog:SetCloseable(false)
    scanDialog:SetTitleFont(addonInfo.id, "MontserratBold")
    scanDialog:SetTitleFontSize(16)
    scanDialog:SetTitleEffect({ strength = 3 })
    scanDialog:SetTitleFontColor(1, .8, 0, 1)

    scanDialog:SetColor({
        type      = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, math.pi, 0, 0),
        color     = {
            { r = 0.13, g = 0.15, b = 0.20, a = 1, position = 0 },
            { r = 0.10, g = 0.11, b = 0.15, a = 1, position = 1 },
        }
    }, data.theme.STROKE_BORDER)

    local msg = LibEKL.UICreateFrame("nkText", "nkUI.auction.scanDialog.msg", scanDialog:GetContent())
    msg:SetPoint("CENTERTOP", scanDialog:GetContent(), "CENTERTOP", 0, 20)
    msg:SetFontSize(16)
    msg:SetFontColor(1, 1, 1, 1)
    LibEKL.UI.SetFont(msg, addonInfo.id, "MontserratSemiBold")

    scanDialog:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
        (LibEKL.UI.getBoundRight() / 2) - (scanDialog:GetWidth() / 2), 100)

    function scanDialog:SetMessage(text) msg:SetText(text) end

    -- Attach the scan result event once, here
    Command.Event.Attach(Event.Auction.Scan, function(_, info, auctions)
        if info.type ~= "search" then return end
        if not fullScanPending then return end
        fullScanPending = false

        Command.System.Watchdog.Quiet()

        local shard = InspectShard().name
        initShard(shard)

        scanDialog:SetVisible(true)
        scanDialog:SetMessage(langTexts.auction.scanStarted)

        -- Also populate the browse grid if it is built
        if auction.populateBrowseGrid then
            auction.refreshOwnAuctions()
            auction.populateBrowseGrid(auctions)
        end

        runScanProcessing(
            auctions,
            function(pct)
                scanDialog:SetMessage(stringFormat(langTexts.auction.scanProgress, pct))
            end,
            function(newCount)
                scanDialog:SetVisible(false)
                Command.Console.Display("general", true,
                    stringFormat(langTexts.auction.newAuctions, newCount), true)
                auction.refreshStatusStrip()
            end
        )
    end, "nkUI.Auction.Scan")
end

function internalFunc.ahScanDialog()
    if not scanDialog then
        buildScanDialog()
    end

    local shard = InspectShard().name
    initShard(shard)

    scanDialog:SetVisible(true)
    scanDialog:SetMessage(langTexts.auction.scanStarted)

    browseSearchPending = false   -- full scan supersedes any pending browse
    fullScanPending     = true
    Command.Auction.Scan({ type = "search" })
end

---------- helpers ----------

function auction.makeBtn(name, parent, label, w, h)
    local btn = LibEKL.UICreateFrame("nkButton", name, parent)
    btn:SetWidth(w or 100)
    btn:SetHeight(h or 22)
    btn:SetText(label)
    btn:SetFont(addonInfo.id, "MontserratSemiBold")
    btn:SetEffectGlow({ strength = 3 })
    btn:SetLabelColor(data.theme.labelColor)
    btn:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = 0.4 })
    btn:SetBorderColor({ r = 0, g = 0, b = 0, a = 0.7, thickness = 1 })
    return btn
end

function auction.formatExpiry(seconds)
    if not seconds then return "?" end
    local h = mathFloor(seconds / 3600)
    local m = mathFloor((seconds % 3600) / 60)
    if h > 0 then return stringFormat("%dh%dm", h, m) end
    return stringFormat("%dm", m)
end

---------- interaction state ----------

local atAuctionHouse = false   -- tracked via Event.Interaction; Inspect.Interaction() is unreliable when polled

Command.Event.Attach(Event.Interaction, function(_, interaction)
    atAuctionHouse = (interaction == "auction")
end, "nkUI.Auction.InteractionState")

function auction.isAtAH()
    return atAuctionHouse
end

---------- phase 0: placeholder for browse tab ----------

-- Browse tab implementation moved to auction-browse.lua
-- Phase 1A will add: rarity filters, bid column, my price column, sort persistence

-- Own auctions cache: [itemType] = lowestUnitPrice
auction.ownAuctions = {}

-- Accessor to check if browse search is pending
function auction.isBrowseSearchPending()
    return browseSearchPending
end

-- Setter for browse search pending
function auction.setBrowseSearchPending(flag)
    browseSearchPending = flag
end

---------- main window (neues Design – Schritt 2: Filter-Leiste) ----------

local WIN_W     = 1280
local WIN_H     = 720
local FILTER_H  = 68
local SIDEBAR_W = 148
local RIGHT_W   = 220
local BOTTOM_H  = 44

---------- filter bar option tables ----------

local FILTER_RARITY_OPTIONS = {
    { label = "All Rarities",   value = nil           },
    { label = "Common",         value = "sellable"    },
    { label = "Uncommon",       value = "uncommon"    },
    { label = "Rare",           value = "rare"        },
    { label = "Epic",           value = "epic"        },
    { label = "Relic",          value = "relic"       },
    { label = "Transcendent",   value = "transcendent"},
}

local FILTER_CALLING_OPTIONS = {
    { label = "All Callings",   value = nil           },
    { label = "Warrior",        value = "warrior"     },
    { label = "Cleric",         value = "cleric"      },
    { label = "Rogue",          value = "rogue"       },
    { label = "Mage",           value = "mage"        },
    { label = "Primalist",      value = "primalist"   },
}

local FILTER_STATS_OPTIONS = {
    { label = "All Stats",      value = nil           },
    { label = "Strength",       value = "str"         },
    { label = "Dexterity",      value = "dex"         },
    { label = "Intelligence",   value = "int"         },
    { label = "Wisdom",         value = "wis"         },
    { label = "Endurance",      value = "end"         },
}

---------- sidebar category tree ----------

local CATEGORY_TREE = {
    { id = "all",        label = "ALL",         value = nil,          children = nil },
    { id = "rex",        label = "REX",         value = "currency",   children = nil },
    { id = "armor",      label = "ARMOR",       value = "armor",      children = {
        { id = "armor.head",     label = "Head",      value = "armor.head"     },
        { id = "armor.shoulder", label = "Shoulder",  value = "armor.shoulder" },
        { id = "armor.chest",    label = "Chest",     value = "armor.chest"    },
        { id = "armor.hands",    label = "Hands",     value = "armor.hands"    },
        { id = "armor.legs",     label = "Legs",      value = "armor.legs"     },
        { id = "armor.feet",     label = "Feet",      value = "armor.feet"     },
        { id = "armor.back",     label = "Back",      value = "armor.back"     },
        { id = "armor.neck",     label = "Neck",      value = "armor.neck"     },
        { id = "armor.waist",    label = "Waist",     value = "armor.waist"    },
        { id = "armor.finger",   label = "Ring",      value = "armor.finger"   },
        { id = "armor.ear",      label = "Earring",   value = "armor.ear"      },
        { id = "armor.trinket",  label = "Trinket",   value = "armor.trinket"  },
    }},
    { id = "weapon",     label = "WEAPON",      value = "weapon",     children = {
        { id = "weapon.1h",     label = "1-Hand",    value = "weapon.onehand" },
        { id = "weapon.2h",     label = "2-Hand",    value = "weapon.twohand" },
        { id = "weapon.off",    label = "Off-Hand",  value = "weapon.offhand" },
        { id = "weapon.shield", label = "Shield",    value = "weapon.shield"  },
        { id = "weapon.ranged", label = "Ranged",    value = "weapon.ranged"  },
    }},
    { id = "planar",     label = "PLANAR",      value = "planar",     children = {
        { id = "planar.sigil",  label = "Sigil",     value = "sigil"          },
        { id = "planar.ess",    label = "Essence",   value = "planarEssence"  },
    }},
    { id = "consumable", label = "CONSUMABLES", value = "consumable",    children = nil },
    { id = "container",  label = "CONTAINERS",  value = "container",     children = nil },
    { id = "crafting",   label = "CRAFTING",    value = "recipe",        children = nil },
    { id = "misc",       label = "MISC",        value = "miscellaneous", children = nil },
    { id = "dimension",  label = "DIMENSION",   value = "dimension",     children = nil },
    { id = "artifact",   label = "ARTIFACTS",   value = "artifact",      children = nil },
}

local function buildWindow()
    local name = "nkUI.auction"

    local win = LibEKL.UICreateFrame("nkWindow", name, context)
    win:SetTitle("AUCTION HOUSE")
    win:SetTitleAlign('center')
    win:SetTitleFont(addonInfo.id, "MontserratBold")
    win:SetTitleFontSize(18)
    win:SetTitleEffect({ strength = 4 })
    win:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    win:SetCloseable(true)
    win:SetWidth(WIN_W)
    win:SetHeight(WIN_H)
    win:SetLayer(2)

    win:SetColor({
        type      = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, math.pi, 0, 0),
        color     = {
            { r = 0.13, g = 0.15, b = 0.20, a = 1, position = 0 },
            { r = 0.10, g = 0.11, b = 0.15, a = 1, position = 1 },
        }
    }, data.theme.STROKE_BORDER)

    local cfg = nkUISetup.modules.auction
    win:SetPoint("TOPLEFT", UIParent, "TOPLEFT", cfg.x, cfg.y)

    local body = win:GetContent()

    -- ===== FILTER-LEISTE =====
    local filterBar = LibEKL.UICreateFrame("nkFrame", name .. ".filter", body)
    filterBar:SetPoint("TOPLEFT",  body, "TOPLEFT",  0, 0)
    filterBar:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)
    filterBar:SetHeight(FILTER_H)

    -- Hilfsfunktionen für wiederkehrende Elemente
    local function mkLabel(fname, parent, text, xOff, yOff)
        local lbl = LibEKL.UICreateFrame("nkText", fname, parent)
        lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
        lbl:SetFontSize(10)
        LibEKL.UI.SetFont(lbl, addonInfo.id, "MontserratMedium")
        lbl:SetFontColor(0.55, 0.55, 0.55, 1)
        lbl:SetText(text)
        return lbl
    end

    local function mkInput(fname, parent, xOff, yOff, w)
        local tf = LibEKL.UICreateFrame("nkTextField", fname, parent)
        tf:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
        tf:SetWidth(w or 160)
        tf:SetHeight(24)
        tf:SetInnerColor({r = 0.05, g = 0.06, b = 0.09, a = 1})
        tf:SetFocusColor(data.theme.labelColor)
        tf:SetBorderColor({r = 0.25, g = 0.25, b = 0.30, a = 1})
        return tf
    end

    local function mkCombo(fname, parent, options, xOff, yOff, w)
        local cb = LibEKL.UICreateFrame("nkCombobox", fname, parent)
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
        cb:SetWidth(w or 120)
        cb:SetHeight(24)
        cb:SetLabelWidth(0)
        cb:SetFont(addonInfo.id, "MontserratMedium")
        cb:SetLabelColor(data.theme.labelColor)
        cb:SetColorInner(0.05, 0.06, 0.09, 1)
        cb:SetColor(0.18, 0.20, 0.26, 1)
        cb:SetColorSelected(data.theme.labelColor)
        cb:SetColorBorder(0.25, 0.25, 0.30, 1)
        cb:SetSelection(options, false)
        cb:SetSelectedValue(options[1].value)
        return cb
    end

    local function mkCheck(fname, parent, text, xOff, yOff)
        local ck = LibEKL.UICreateFrame("nkCheckbox", fname, parent)
        ck:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
        ck:SetText(text)
        ck:SetFontSize(11)
        ck:SetTextFont(addonInfo.id, "MontserratMedium")
        ck:SetLabelColor(data.theme.labelColor)
        ck:SetColor(data.theme.labelColor)
        ck:SetColorInner(0.05, 0.06, 0.09, 1)
        ck:SetLabelInFront(false)
        ck:SetLabelWidth(90)
        ck:SetChecked(false, true)
        return ck
    end

    -- Zeilen-Offsets: Zeile 1 = Labels (y=6), Zeile 2 = Controls (y=22)
    local LBL_Y  = 6
    local CTRL_Y = 22

    -- SEARCH
    mkLabel(name .. ".filter.lSearch", filterBar, "SEARCH", 8, LBL_Y)
    local filterSearch = mkInput(name .. ".filter.search", filterBar, 8, CTRL_Y, 160)

    -- LEVEL
    mkLabel(name .. ".filter.lLevel", filterBar, "LEVEL", 176, LBL_Y)
    local filterLevelMin = mkInput(name .. ".filter.levelMin", filterBar, 176, CTRL_Y, 38)
    local filterLevelSep = LibEKL.UICreateFrame("nkText", name .. ".filter.levelSep", filterBar)
    filterLevelSep:SetPoint("TOPLEFT", filterBar, "TOPLEFT", 218, CTRL_Y + 5)
    filterLevelSep:SetFontSize(11)
    LibEKL.UI.SetFont(filterLevelSep, addonInfo.id, "MontserratMedium")
    filterLevelSep:SetFontColor(0.5, 0.5, 0.5, 1)
    filterLevelSep:SetText("–")
    local filterLevelMax = mkInput(name .. ".filter.levelMax", filterBar, 228, CTRL_Y, 38)

    -- STATS
    mkLabel(name .. ".filter.lStats", filterBar, "STATS", 274, LBL_Y)
    local filterStats = mkCombo(name .. ".filter.stats", filterBar, FILTER_STATS_OPTIONS, 274, CTRL_Y, 118)

    -- CALLING
    mkLabel(name .. ".filter.lCalling", filterBar, "CALLING", 400, LBL_Y)
    local filterCalling = mkCombo(name .. ".filter.calling", filterBar, FILTER_CALLING_OPTIONS, 400, CTRL_Y, 128)

    -- RARITY
    mkLabel(name .. ".filter.lRarity", filterBar, "RARITY", 536, LBL_Y)
    local filterRarity = mkCombo(name .. ".filter.rarity", filterBar, FILTER_RARITY_OPTIONS, 536, CTRL_Y, 128)

    -- USABLE ONLY
    local filterUsable  = mkCheck(name .. ".filter.usable",  filterBar, "Usable Only",  672, CTRL_Y - 2)

    -- BUYOUTS ONLY
    local filterBuyouts = mkCheck(name .. ".filter.buyouts", filterBar, "Buyouts Only", 774, CTRL_Y - 2)

    -- BUYOUT PRICE – TOTAL (rechts verankert)
    -- Layout (von rechts): [8] [Max 65px] [4] [Min 65px]
    -- Header-Label (rechts ausgerichtet, Zeile 1)
    local bpLabel = LibEKL.UICreateFrame("nkText", name .. ".filter.lBuyout", filterBar)
    bpLabel:SetPoint("TOPRIGHT", filterBar, "TOPRIGHT", -8, LBL_Y)
    bpLabel:SetFontSize(10)
    LibEKL.UI.SetFont(bpLabel, addonInfo.id, "MontserratMedium")
    bpLabel:SetFontColor(0.55, 0.55, 0.55, 1)
    bpLabel:SetText("BUYOUT PRICE – TOTAL")

    -- Max-Feld (Zeile 2, rechtsbündig)
    local filterPriceMax = LibEKL.UICreateFrame("nkTextField", name .. ".filter.priceMax", filterBar)
    filterPriceMax:SetPoint("TOPRIGHT", filterBar, "TOPRIGHT", -8, CTRL_Y)
    filterPriceMax:SetWidth(65)
    filterPriceMax:SetHeight(24)
    filterPriceMax:SetInnerColor({r = 0.05, g = 0.06, b = 0.09, a = 1})
    filterPriceMax:SetFocusColor(data.theme.labelColor)
    filterPriceMax:SetBorderColor({r = 0.25, g = 0.25, b = 0.30, a = 1})

    -- Min-Feld (Zeile 2, links von Max)
    local filterPriceMin = LibEKL.UICreateFrame("nkTextField", name .. ".filter.priceMin", filterBar)
    filterPriceMin:SetPoint("TOPRIGHT", filterBar, "TOPRIGHT", -(8 + 65 + 4), CTRL_Y)
    filterPriceMin:SetWidth(65)
    filterPriceMin:SetHeight(24)
    filterPriceMin:SetInnerColor({r = 0.05, g = 0.06, b = 0.09, a = 1})
    filterPriceMin:SetFocusColor(data.theme.labelColor)
    filterPriceMin:SetBorderColor({r = 0.25, g = 0.25, b = 0.30, a = 1})

    -- Filter-Controls am filterBar-Objekt speichern (für Schritt 9)
    filterBar.search    = filterSearch
    filterBar.levelMin  = filterLevelMin
    filterBar.levelMax  = filterLevelMax
    filterBar.stats     = filterStats
    filterBar.calling   = filterCalling
    filterBar.rarity    = filterRarity
    filterBar.usable    = filterUsable
    filterBar.buyouts   = filterBuyouts
    filterBar.priceMin  = filterPriceMin
    filterBar.priceMax  = filterPriceMax

    -- ===== SIDEBAR (links) =====
    local HEADER_H         = 30   -- nkWindow title bar height
    local SIDEBAR_SCROLL_H = WIN_H - HEADER_H - FILTER_H - BOTTOM_H  -- 578

    local sidebar = LibEKL.UICreateFrame("nkFrame", name .. ".sidebar", body)
    sidebar:SetPoint("TOPLEFT",    body, "TOPLEFT",    0,  FILTER_H)
    sidebar:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 0, -BOTTOM_H)
    sidebar:SetWidth(SIDEBAR_W)

    -- Separator line on the right edge
    local sidebarSep = LibEKL.UICreateFrame("nkFrame", name .. ".sidebar.sep", sidebar)
    sidebarSep:SetPoint("TOPRIGHT",    sidebar, "TOPRIGHT",    0, 0)
    sidebarSep:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0, 0)
    sidebarSep:SetWidth(1)
    sidebarSep:SetBackgroundColor(0.22, 0.22, 0.28, 1)

    local sidebarScroll = LibEKL.UICreateFrame("nkScrollPane", name .. ".sidebar.scroll", sidebar)
    sidebarScroll:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, 0)
    sidebarScroll:SetWidth(SIDEBAR_W - 1)
    sidebarScroll:SetHeight(SIDEBAR_SCROLL_H)
    sidebarScroll:SetAdjust(22)

    -- Container for all category rows (reparented into scrollPane via SetContent)
    local sbContainer = LibEKL.UICreateFrame("nkFrame", name .. ".sidebar.container", sidebar)
    sbContainer:SetWidth(SIDEBAR_W - 2)

    -- State
    local sbExpanded = {}   -- { [categoryId] = true }
    local sbSelected = nil  -- selected category value (nil = ALL)
    local sbRows     = {}
    local sbRowCount = 0

    local SB_ROW_H  = 22
    local SB_INDENT = 10
    local SB_CLR_HEAD = data.theme.labelColor
    local SB_CLR_SUB  = { r = 0.60, g = 0.60, b = 0.60, a = 1 }
    local SB_CLR_SEL  = { r = 0.18, g = 0.22, b = 0.30, a = 0.9 }

    local function sbRelayout()
        local y = 0
        for i = 1, sbRowCount do
            local info = sbRows[i]
            local row  = info.frame
            local show = (info.parentId == nil) or (sbExpanded[info.parentId] == true)
            row:SetVisible(show)
            if show then
                row:SetPoint("TOPLEFT", sbContainer, "TOPLEFT", 0, y)
                row:SetWidth(SIDEBAR_W - 2)
                y = y + SB_ROW_H
            end
            info.selBg:SetVisible(sbSelected == info.catData.value)
            if info.arrow then
                info.arrow:SetText(sbExpanded[info.catData.id] and "v" or ">")
            end
        end
        sbContainer:SetHeight(math.max(y, 1))
        sidebarScroll:SetContent(sbContainer)
    end

    local function sbSelect(value)
        sbSelected = value
        sbRelayout()
        if sidebar.onSelect then sidebar.onSelect(value) end
    end

    local function sbToggle(catId)
        sbExpanded[catId] = not sbExpanded[catId]
        sbRelayout()
    end

    -- Build all rows from CATEGORY_TREE
    for i = 1, #CATEGORY_TREE do
        local cat     = CATEGORY_TREE[i]
        local rowName = name .. ".sb.r." .. i

        local row = LibEKL.UICreateFrame("nkFrame", rowName, sbContainer)
        row:SetHeight(SB_ROW_H)
        row:SetVisible(false)

        local selBg = LibEKL.UICreateFrame("nkFrame", rowName .. ".bg", row)
        selBg:SetPoint("TOPLEFT",     row, "TOPLEFT",     0, 0)
        selBg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        selBg:SetBackgroundColor(SB_CLR_SEL.r, SB_CLR_SEL.g, SB_CLR_SEL.b, SB_CLR_SEL.a)
        selBg:SetVisible(false)

        local lbl = LibEKL.UICreateFrame("nkText", rowName .. ".lbl", row)
        lbl:SetPoint("CENTERLEFT", row, "CENTERLEFT", 6, 0)
        lbl:SetFontSize(11)
        LibEKL.UI.SetFont(lbl, addonInfo.id, "MontserratSemiBold")
        lbl:SetFontColor(SB_CLR_HEAD.r, SB_CLR_HEAD.g, SB_CLR_HEAD.b, SB_CLR_HEAD.a)
        lbl:SetText(cat.label)

        local arrow = nil
        if cat.children then
            arrow = LibEKL.UICreateFrame("nkText", rowName .. ".arr", row)
            arrow:SetPoint("CENTERRIGHT", row, "CENTERRIGHT", -4, 0)
            arrow:SetFontSize(10)
            LibEKL.UI.SetFont(arrow, addonInfo.id, "MontserratMedium")
            arrow:SetFontColor(0.45, 0.45, 0.45, 1)
            arrow:SetText(">")
        end

        sbRowCount = sbRowCount + 1
        sbRows[sbRowCount] = { frame = row, parentId = nil, catData = cat, selBg = selBg, arrow = arrow }

        local thisCat = cat
        row:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
            if thisCat.children then sbToggle(thisCat.id) end
            sbSelect(thisCat.value)
        end, rowName .. ".Click")

        if cat.children then
            for j = 1, #cat.children do
                local sub     = cat.children[j]
                local subName = name .. ".sb.r." .. i .. "." .. j

                local subRow = LibEKL.UICreateFrame("nkFrame", subName, sbContainer)
                subRow:SetHeight(SB_ROW_H)
                subRow:SetVisible(false)

                local subBg = LibEKL.UICreateFrame("nkFrame", subName .. ".bg", subRow)
                subBg:SetPoint("TOPLEFT",     subRow, "TOPLEFT",     0, 0)
                subBg:SetPoint("BOTTOMRIGHT", subRow, "BOTTOMRIGHT", 0, 0)
                subBg:SetBackgroundColor(SB_CLR_SEL.r, SB_CLR_SEL.g, SB_CLR_SEL.b, SB_CLR_SEL.a)
                subBg:SetVisible(false)

                local subLbl = LibEKL.UICreateFrame("nkText", subName .. ".lbl", subRow)
                subLbl:SetPoint("CENTERLEFT", subRow, "CENTERLEFT", SB_INDENT, 0)
                subLbl:SetFontSize(11)
                LibEKL.UI.SetFont(subLbl, addonInfo.id, "MontserratMedium")
                subLbl:SetFontColor(SB_CLR_SUB.r, SB_CLR_SUB.g, SB_CLR_SUB.b, SB_CLR_SUB.a)
                subLbl:SetText(sub.label)

                sbRowCount = sbRowCount + 1
                sbRows[sbRowCount] = { frame = subRow, parentId = cat.id, catData = sub, selBg = subBg, arrow = nil }

                local thisSub = sub
                subRow:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
                    sbSelect(thisSub.value)
                end, subName .. ".Click")
            end
        end
    end

    sbRelayout()

    sidebar.onSelect       = nil
    sidebar.getSelected    = function() return sbSelected end
    sidebar.selectCategory = sbSelect

    -- ===== RECHTES PANEL =====
    local rightPanel = LibEKL.UICreateFrame("nkFrame", name .. ".rightPanel", body)
    rightPanel:SetPoint("TOPRIGHT",    body, "TOPRIGHT",    0,  FILTER_H)
    rightPanel:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, -BOTTOM_H)
    rightPanel:SetWidth(RIGHT_W)

    local rightPlaceholder = LibEKL.UICreateFrame("nkText", name .. ".rightPanel.placeholder", rightPanel)
    rightPlaceholder:SetPoint("TOPCENTER", rightPanel, "TOPCENTER", 0, 10)
    rightPlaceholder:SetFontSize(11)
    LibEKL.UI.SetFont(rightPlaceholder, addonInfo.id, "MontserratMedium")
    rightPlaceholder:SetFontColor(0.4, 0.4, 0.4, 1)
    rightPlaceholder:SetText("[Price History\n+ Preview\nSchritt 6/7]")

    -- ===== HAUPT-INHALT (Mitte) =====
    local mainContent = LibEKL.UICreateFrame("nkFrame", name .. ".main", body)
    mainContent:SetPoint("TOPLEFT",     sidebar,    "TOPRIGHT",   0, 0)
    mainContent:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMLEFT", 0, 0)

    local mainPlaceholder = LibEKL.UICreateFrame("nkText", name .. ".main.placeholder", mainContent)
    mainPlaceholder:SetPoint("CENTER", mainContent, "CENTER", 0, 0)
    mainPlaceholder:SetFontSize(14)
    LibEKL.UI.SetFont(mainPlaceholder, addonInfo.id, "MontserratMedium")
    mainPlaceholder:SetFontColor(0.4, 0.4, 0.4, 1)
    mainPlaceholder:SetText("[Haupt-Grid – Schritt 4]")

    -- ===== BOTTOM BAR =====
    local bottomBar = LibEKL.UICreateFrame("nkFrame", name .. ".bottom", body)
    bottomBar:SetPoint("BOTTOMLEFT",  body, "BOTTOMLEFT",  0, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
    bottomBar:SetHeight(BOTTOM_H)

    local bottomPlaceholder = LibEKL.UICreateFrame("nkText", name .. ".bottom.placeholder", bottomBar)
    bottomPlaceholder:SetPoint("CENTER", bottomBar, "CENTER", 0, 0)
    bottomPlaceholder:SetFontSize(11)
    LibEKL.UI.SetFont(bottomPlaceholder, addonInfo.id, "MontserratMedium")
    bottomPlaceholder:SetFontColor(0.4, 0.4, 0.4, 1)
    bottomPlaceholder:SetText("[Bottom Bar – Schritt 8]")

    -- Position speichern beim Verschieben
    win:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        if win:GetLeft() ~= nil then
            nkUISetup.modules.auction.x = win:GetLeft()
            nkUISetup.modules.auction.y = win:GetTop()
        end
    end, name .. ".Moved")

    -- Sub-Frames für spätere Schritte zugänglich machen
    win.filterBar   = filterBar
    win.sidebar     = sidebar
    win.mainContent = mainContent
    win.rightPanel  = rightPanel
    win.bottomBar   = bottomBar

    -- Stub: Kompatibilität mit Scan-Engine
    function win:UpdateStatus() end

    win:SetVisible(false)
    return win
end

-- Stub: wird von der Scan-Engine aufgerufen
function auction.refreshStatusStrip()
    -- no-op in neuem Design
end

---------- public entry point ----------

function internalFunc.auctionOpen()

    -- bootstrap: Settings falls fehlend
    if nkUISetup and nkUISetup.modules and nkUISetup.modules.auction == nil then
        nkUISetup.modules.auction = { activate = true, x = 100, y = 50,
                                      autoOpenWithAH = false, showInTooltip = true, scanDepth = 3 }
    end
    if nkUISetup and nkUISetup.modules and nkUISetup.modules.auction and nkUISetup.modules.auction.browse == nil then
        nkUISetup.modules.auction.browse = { sortCol = 7, sortAsc = true, rarityFilter = {} }
    end

    if uiElements.auctionWindow == nil then
        uiElements.auctionWindow = buildWindow()
    end

    local win = uiElements.auctionWindow
    win:SetVisible(not win:GetVisible())
end

---------- auto-open with AH (optional) ----------

Command.Event.Attach(Event.Interaction, function(_, interaction)
    if not nkUISetup or not nkUISetup.modules.auction then return end
    if not nkUISetup.modules.auction.autoOpenWithAH then return end

    if interaction == "auction" then
        if uiElements.auctionWindow == nil then
            uiElements.auctionWindow = buildWindow()
        end
        uiElements.auctionWindow:SetVisible(true)
    elseif interaction == nil then
        if uiElements.auctionWindow and uiElements.auctionWindow:GetVisible() then
            uiElements.auctionWindow:SetVisible(false)
        end
    end
end, "nkUI.Auction.Interaction")
