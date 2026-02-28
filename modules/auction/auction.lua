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
        daysSince = mathFloor((InspectTimeReal() - latestTime) / 86400),
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
    local scanTime = InspectTimeReal()

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

---------- main window skeleton ----------

local WIN_W, WIN_H = 900, 600

local function buildWindow()
    local name = "nkUI.auction"

    local win = LibEKL.UICreateFrame("nkWindow", name, context)
    win:SetTitle(langTexts.auction.windowTitle)
    win:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    win:SetTitleFontSize(16)
    win:SetTitleEffect({ strength = 3 })
    win:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
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

    -- Tab pane fills the top portion of the content area
    local tabs = LibEKL.UICreateFrame("nkTabPane", name .. ".tabs", win:GetContent())
    tabs:SetPoint("TOPLEFT",     win:GetContent(), "TOPLEFT",     0,    0)
    tabs:SetPoint("BOTTOMRIGHT", win:GetContent(), "BOTTOMRIGHT", 0, -30)

    -- Create content frames that live inside the tab pane's body
    local bodyFrame = tabs:GetBodyFrame()

    local browseFrame = LibEKL.UICreateFrame("nkFrame", name .. ".tab.browse", bodyFrame)
    browseFrame:SetPoint("TOPLEFT",     bodyFrame, "TOPLEFT",     0, 0)
    browseFrame:SetPoint("BOTTOMRIGHT", bodyFrame, "BOTTOMRIGHT", 0, 0)
    browseFrame:SetVisible(false)

    local postFrame = LibEKL.UICreateFrame("nkFrame", name .. ".tab.post", bodyFrame)
    postFrame:SetPoint("TOPLEFT",     bodyFrame, "TOPLEFT",     0, 0)
    postFrame:SetPoint("BOTTOMRIGHT", bodyFrame, "BOTTOMRIGHT", 0, 0)
    postFrame:SetVisible(false)

    local mineFrame = LibEKL.UICreateFrame("nkFrame", name .. ".tab.mine", bodyFrame)
    mineFrame:SetPoint("TOPLEFT",     bodyFrame, "TOPLEFT",     0, 0)
    mineFrame:SetPoint("BOTTOMRIGHT", bodyFrame, "BOTTOMRIGHT", 0, 0)
    mineFrame:SetVisible(false)

    local pricesFrame = LibEKL.UICreateFrame("nkFrame", name .. ".tab.prices", bodyFrame)
    pricesFrame:SetPoint("TOPLEFT",     bodyFrame, "TOPLEFT",     0, 0)
    pricesFrame:SetPoint("BOTTOMRIGHT", bodyFrame, "BOTTOMRIGHT", 0, 0)
    pricesFrame:SetVisible(false)

    local tabStroke = { r = 0x66/255, g = 0x56/255, b = 0x2e/255, a = 1, thickness = 1 }
    local tabFill   = { type = "solid", r = 0.13, g = 0.15, b = 0.20, a = 1 }
    tabs:SetColor(tabStroke, tabFill, data.theme.labelColor, { r = 1, g = 1, b = 1, a = 1 })
    tabs:SetFont(addonInfo.id, "MontserratSemiBold")

    tabs:AddPane({ label = langTexts.auction.tabBrowse,  frame = browseFrame,  effect = { strength = 3 },
        initFunc = function()
            if auction.buildBrowseTab then
                auction.buildBrowseTab(browseFrame)
            end
        end }, false)
    tabs:AddPane({ label = langTexts.auction.tabPost,    frame = postFrame,    effect = { strength = 3 },
        initFunc = function() -- Phase 3: post tab builder goes here
        end }, false)
    tabs:AddPane({ label = langTexts.auction.tabMine,    frame = mineFrame,    effect = { strength = 3 },
        initFunc = function() -- Phase 1B: my auctions tab builder goes here
        end }, false)
    tabs:AddPane({ label = langTexts.auction.tabPrices,  frame = pricesFrame,  effect = { strength = 3 },
        initFunc = function() -- Phase 2: prices tab builder goes here
        end }, false)

    tabs:UpdatePanes()

    -- Status strip at the bottom: "Last scan: X" + [Scan Now] button
    local strip = LibEKL.UICreateFrame("nkFrame", name .. ".strip", win:GetContent())
    strip:SetPoint("BOTTOMLEFT",  win:GetContent(), "BOTTOMLEFT",  0, 0)
    strip:SetPoint("BOTTOMRIGHT", win:GetContent(), "BOTTOMRIGHT", 0, 0)
    strip:SetHeight(30)

    local statusLabel = LibEKL.UICreateFrame("nkText", name .. ".strip.status", strip)
    statusLabel:SetPoint("CENTERLEFT", strip, "CENTERLEFT", 10, 0)
    statusLabel:SetFontSize(13)
    statusLabel:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    LibEKL.UI.SetFont(statusLabel, addonInfo.id, "MontserratSemiBold")

    local scanBtn = auction.makeBtn(name .. ".strip.scan", strip, langTexts.auction.btnScan, 100, 22)
    scanBtn:SetPoint("CENTERRIGHT", strip, "CENTERRIGHT", -10, 0)

    scanBtn:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        if not atAuctionHouse then
            Command.Console.Display("general", true, langTexts.auction.notAtAH, true)
            return
        end
        internalFunc.ahScanDialog()
    end, name .. ".strip.scan.Up")

    -- Save position on move
    win:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        if win:GetLeft() ~= nil then
            nkUISetup.modules.auction.x = win:GetLeft()
            nkUISetup.modules.auction.y = win:GetTop()
        end
    end, name .. ".Moved")

    -- Helper: update the status strip text
    function win:UpdateStatus()
        local shard = InspectShard().name
        if nkUIAucData and nkUIAucData[shard] and nkUIAucData[shard].lastScan then
            local elapsed = InspectTimeReal() - nkUIAucData[shard].lastScan
            local hours   = mathFloor(elapsed / 3600)
            local mins    = mathFloor((elapsed % 3600) / 60)
            local timeStr
            if hours > 0 then
                timeStr = stringFormat("%dh %dm", hours, mins)
            else
                timeStr = stringFormat("%dm", mins)
            end
            statusLabel:SetText(stringFormat(langTexts.auction.lastScan, timeStr))
        else
            statusLabel:SetText(langTexts.auction.neverScanned)
        end
    end

    win:UpdateStatus()
    win:SetVisible(false)

    return win
end

-- Called by other sub-modules (browse, post, mine, prices) to refresh the strip.
function auction.refreshStatusStrip()
    if uiElements.auctionWindow then
        uiElements.auctionWindow:UpdateStatus()
    end
end

---------- public entry point ----------

function internalFunc.auctionOpen()

    -- bootstrap settings if the auction block is missing from an older save
    if nkUISetup and nkUISetup.modules and nkUISetup.modules.auction == nil then
        nkUISetup.modules.auction = { activate = true, x = 300, y = 200,
                                      autoOpenWithAH = false, showInTooltip = true, scanDepth = 3 }
    end
    -- bootstrap browse sub-table if missing
    if nkUISetup and nkUISetup.modules and nkUISetup.modules.auction and nkUISetup.modules.auction.browse == nil then
        nkUISetup.modules.auction.browse = { sortCol = 7, sortAsc = true, rarityFilter = {} }
    end

    if uiElements.auctionWindow == nil then
        uiElements.auctionWindow = buildWindow()
    end

    local win = uiElements.auctionWindow
    win:SetVisible(not win:GetVisible())
    if win:GetVisible() then
        win:UpdateStatus()
    end
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
        uiElements.auctionWindow:UpdateStatus()
    elseif interaction == nil then
        if uiElements.auctionWindow and uiElements.auctionWindow:GetVisible() then
            uiElements.auctionWindow:SetVisible(false)
        end
    end
end, "nkUI.Auction.Interaction")
