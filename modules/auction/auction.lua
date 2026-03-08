local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.auction = {}

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local auction       = privateVars.auction
local langTexts     = privateVars.langTexts

local InspectTimeReal       = Inspect.Time.Real
local InspectAuctionDetail  = Inspect.Auction.Detail
local InspectItemDetail     = Inspect.Item.Detail
local InspectShard          = Inspect.Shard

local osTime        = os.time
local osDate        = os.date
local stringFormat  = string.format
local mathFloor     = math.floor
local mathMax       = math.max
local mathMin       = math.min
local tableInsert   = table.insert
local pairs         = pairs
local pcall         = pcall
local tostring      = tostring

---------- init local variables ---------

local HISTORY_CAPACITY = 14   -- max daily snapshots per item (ring buffer)
local BATCH_SIZE       = 50   -- auctions processed per coroutine yield

---------- scan state ----------

local sessionAuctions = {}    -- { [auctionID] = true } dedup within session
local scanInProgress  = false

---------- data model helpers ----------

local function getTodayInt()
    local t = osDate("*t")
    return t.year * 10000 + t.month * 100 + t.day
end

local function getShardName()
    local ok, shard = pcall(InspectShard)
    if ok and shard and shard.name then return shard.name end
    return "unknown"
end

local function initShard(shard)
    if not nkUIAucData then nkUIAucData = {} end
    if not nkUIAucData[shard] then
        nkUIAucData[shard] = {
            schemaVer = 2,
            items     = {},
        }
    end
    return nkUIAucData[shard]
end

---------- schema migration (v1 to v2) ----------

local function migrateV1toV2(shardData)
    shardData.schemaVer = 2
    shardData.auctions  = nil  -- drop old auction ID table if present

    local items = shardData.items
    if not items then return end

    for itemType, old in pairs(items) do
        -- v1 had long key names; convert to short keys
        local migrated = {
            n  = old.name or old.n,
            ic = old.icon or old.ic,
            r  = old.rarity or old.r,
            v  = old.vendor or old.v,
            h  = {},
            hh = 0,
        }

        -- Convert old snapshots (ring buffer) to new format
        if old.snapshots and old.snapshotHead then
            local head = old.snapshotHead
            local cap  = 30  -- old SNAPSHOT_CAPACITY
            local newIdx = 0
            for i = 0, mathMin(HISTORY_CAPACITY, cap) - 1 do
                local idx = (head - 1 - i) % cap + 1
                local snap = old.snapshots[idx]
                if snap and snap.t and snap.t > 0 then
                    newIdx = newIdx + 1
                    local dt = osDate("*t", snap.t)
                    migrated.h[newIdx] = {
                        d   = dt.year * 10000 + dt.month * 100 + dt.day,
                        lo  = snap.lo,
                        hi  = snap.hi,
                        avg = snap.lo,  -- old schema had no avg per snapshot
                        cnt = snap.count or 1,
                    }
                end
            end
            migrated.hh = newIdx
        elseif old.lowestPrice then
            -- very old flat schema (pre-phase1)
            local t = old.lastSeen or 0
            local dt = osDate("*t", t > 0 and t or osTime())
            migrated.h[1] = {
                d   = dt.year * 10000 + dt.month * 100 + dt.day,
                lo  = old.lowestPrice,
                hi  = old.highestPrice or old.lowestPrice,
                avg = old.lowestPrice,
                cnt = old.count or 1,
            }
            migrated.hh = 1
        end

        items[itemType] = migrated
    end
end

local function ensureSchema(shardData)
    if shardData.schemaVer == nil or shardData.schemaVer < 2 then
        migrateV1toV2(shardData)
    end
end

---------- item seeding ----------

local function seedItem(shardData, itemType, name, icon, rarity, vendor)
    local items = shardData.items
    if not items[itemType] then
        items[itemType] = {
            n  = name,
            ic = icon,
            r  = rarity,
            v  = vendor,
            h  = {},
            hh = 0,
        }
    else
        local item = items[itemType]
        if name   then item.n  = name   end
        if icon   then item.ic = icon   end
        if rarity then item.r  = rarity end
        if vendor then item.v  = vendor end
    end
end

---------- snapshot write (daily aggregation) ----------

local function writeSnapshot(item, lo, hi, total, count)
    local today = getTodayInt()
    local head  = item.hh or 0

    -- Check if latest snapshot is from today: update instead of new entry
    if head > 0 and item.h[head] and item.h[head].d == today then
        local snap = item.h[head]
        local oldTotal = snap.avg * snap.cnt
        local newTotal = oldTotal + total
        snap.lo  = mathMin(snap.lo, lo)
        snap.hi  = mathMax(snap.hi, hi)
        snap.cnt = snap.cnt + count
        snap.avg = mathFloor(newTotal / snap.cnt)
    else
        -- New day: advance ring buffer
        head = head % HISTORY_CAPACITY + 1
        item.h[head] = {
            d   = today,
            lo  = lo,
            hi  = hi,
            avg = mathFloor(total / count),
            cnt = count,
        }
        item.hh = head
    end
end

---------- scan accumulator ----------

local accumulator = {}  -- { [itemType] = { lo, hi, total, count } }

local function resetAccumulator()
    accumulator = {}
end

local function flushAccumulator(shardData)
    for itemType, acc in pairs(accumulator) do
        local item = shardData.items[itemType]
        if item then
            writeSnapshot(item, acc.lo, acc.hi, acc.total, acc.count)
        end
    end
    resetAccumulator()
end

---------- scan processing (coroutine-based) ----------

local function processBatch(batch, shardData)
    local newCount = 0
    for i = 1, #batch do
        local auctionID = batch[i]

        -- Deduplication: skip already-seen auctions in this session
        if not sessionAuctions[auctionID] then
            sessionAuctions[auctionID] = true

            local ok, detail = pcall(InspectAuctionDetail, auctionID)
            if ok and detail and detail.itemType and detail.buyout then
                local stack = detail.itemStack or 1
                local unitPrice = mathFloor(detail.buyout / stack)

                -- Fetch item metadata
                local itemKey = detail.item or detail.itemType
                local ok2, itemDetail = pcall(InspectItemDetail, itemKey)
                local name, icon, rarity, vendor
                if ok2 and itemDetail then
                    name   = itemDetail.name
                    icon   = itemDetail.icon
                    rarity = itemDetail.rarity
                    vendor = itemDetail.sell
                end

                -- Seed or update item metadata
                seedItem(shardData, detail.itemType, name, icon, rarity, vendor)

                -- Accumulate prices
                local acc = accumulator[detail.itemType]
                if not acc then
                    accumulator[detail.itemType] = {
                        lo    = unitPrice,
                        hi    = unitPrice,
                        total = unitPrice,
                        count = 1,
                    }
                else
                    acc.lo    = mathMin(acc.lo, unitPrice)
                    acc.hi    = mathMax(acc.hi, unitPrice)
                    acc.total = acc.total + unitPrice
                    acc.count = acc.count + 1
                end

                newCount = newCount + 1
            end
        end
    end
    return newCount
end

local function runScanProcessing(rawAuctions, onProgress, onComplete)
    local shard = getShardName()
    local shardData = initShard(shard)
    ensureSchema(shardData)

    -- Flatten auction IDs into batches
    local list = {}
    for aID in pairs(rawAuctions) do
        list[#list + 1] = aID
    end

    local totalCount = #list
    if totalCount == 0 then
        scanInProgress = false
        if onComplete then onComplete(0) end
        return
    end

    local batches = {}
    for i = 1, totalCount, BATCH_SIZE do
        local batch = {}
        for j = i, mathMin(i + BATCH_SIZE - 1, totalCount) do
            batch[#batch + 1] = list[j]
        end
        batches[#batches + 1] = batch
    end

    resetAccumulator()

    local co = coroutine.create(function()
        local processed = 0
        local newTotal  = 0
        for bIdx = 1, #batches do
            local newInBatch = processBatch(batches[bIdx], shardData)
            newTotal  = newTotal + newInBatch
            processed = processed + #batches[bIdx]
            if onProgress then
                onProgress(mathFloor(processed / totalCount * 100))
            end
            coroutine.yield(bIdx)
        end
        return newTotal
    end)

    LibEKL.Coroutines.Add({
        func     = co,
        counter  = #batches,
        active   = true,
        delay    = 0,
        callBack = function()
            flushAccumulator(shardData)
            shardData.lastScan = osTime()
            scanInProgress = false
            if onComplete then onComplete(totalCount) end
        end,
    })
end

---------- public price API ----------

function auction.getPriceSummary(itemType)
    if not nkUIAucData then return nil end
    local shard = getShardName()
    local shardData = nkUIAucData[shard]
    if not shardData then return nil end
    local item = shardData.items and shardData.items[itemType]
    if not item or not item.h then return nil end

    local depth = (nkUISetup and nkUISetup.modules.auction
                   and nkUISetup.modules.auction.scanDepth) or 3
    local head = item.hh or 0
    if head == 0 then return nil end

    local loAll, hiAll = math.huge, 0
    local total, snapCount, countAll = 0, 0, 0
    local latestDate, latestLo = 0, nil

    for i = 0, mathMin(depth, HISTORY_CAPACITY) - 1 do
        local idx = (head - 1 - i) % HISTORY_CAPACITY + 1
        local snap = item.h[idx]
        if snap and snap.d and snap.d > 0 then
            loAll     = mathMin(loAll, snap.lo)
            hiAll     = mathMax(hiAll, snap.hi)
            total     = total + snap.avg
            snapCount = snapCount + 1
            countAll  = countAll + (snap.cnt or 1)
            if snap.d > latestDate then
                latestDate = snap.d
                latestLo   = snap.lo
            end
        end
    end

    if snapCount == 0 then return nil end

    -- Convert YYYYMMDD int to os.time; use hour=12 so result is always
    -- at noon – prevents negative daysSince when called before midday
    local ly = mathFloor(latestDate / 10000)
    local lm = mathFloor((latestDate % 10000) / 100)
    local ld = latestDate % 100
    local latestTime = os.time({ year = ly, month = lm, day = ld, hour = 12, min = 0, sec = 0 })
    local daysSince  = mathMax(0, mathFloor((osTime() - latestTime) / 86400))

    return {
        lo        = loAll,
        hi        = hiAll,
        avg       = mathFloor(total / snapCount),
        lastLo    = latestLo,
        snapCount = snapCount,
        totalSeen = countAll,
        lastSeen  = latestTime,
        daysSince = daysSince,
    }
end

function auction.getItemData(itemType)
    if not nkUIAucData then return nil end
    local shard = getShardName()
    local shardData = nkUIAucData[shard]
    if not shardData or not shardData.items then return nil end
    return shardData.items[itemType]
end

function auction.getLastScanTime()
    if not nkUIAucData then return nil end
    local shard = getShardName()
    local shardData = nkUIAucData[shard]
    if not shardData then return nil end
    return shardData.lastScan
end

function auction.isScanInProgress()
    return scanInProgress
end

function auction.clearSessionAuctions()
    sessionAuctions = {}
end

---------- public scan trigger ----------

function auction.startScan(onProgress, onComplete)
    if scanInProgress then return false end
    scanInProgress = true

    local ok, err = pcall(Command.Auction.Scan, { type = "search" })
    if not ok then
        scanInProgress = false
        if onComplete then onComplete(0) end
        return false
    end

    -- Store callbacks for when Event.Auction.Scan fires
    auction._scanOnProgress = onProgress
    auction._scanOnComplete = onComplete
    return true
end

---------- Event.Auction.Scan handler ----------

Command.Event.Attach(Event.Auction.Scan, function(_, info, auctions)
    if info.type ~= "search" then return end
    if not scanInProgress then return end

    if not auctions then
        scanInProgress = false
        if auction._scanOnComplete then auction._scanOnComplete(0) end
        return
    end

    runScanProcessing(auctions,
        auction._scanOnProgress,
        auction._scanOnComplete)
end, "nkUI.Auction.Scan")

---------- public entry point ----------

function internalFunc.auctionOpen()

    -- Bootstrap settings
    if nkUISetup and nkUISetup.modules and not nkUISetup.modules.auction then
        nkUISetup.modules.auction = {
            activate       = true,
            x              = 100,
            y              = 50,
            scanDepth      = 3,
            trendThreshold = 0.15,
            priceFloor     = 0.85,
            undercutAmount = 1,
        }
    end

    if uiElements.auctionSellWindow == nil then
        auction.buildSellWindow()
    end

    local win = uiElements.auctionSellWindow
    if win then
        win:SetVisible(not win:GetVisible())
    end
end

function internalFunc.auctionSetVisible(visible)
    if nkUISetup and nkUISetup.modules and nkUISetup.modules.auction
       and not nkUISetup.modules.auction.activate then
        return
    end

    if visible then
        if nkUISetup and nkUISetup.modules and not nkUISetup.modules.auction then
            nkUISetup.modules.auction = {
                activate       = true,
                x              = 100,
                y              = 50,
                scanDepth      = 3,
                trendThreshold = 0.15,
            }
        end

        if uiElements.auctionSellWindow == nil then
            auction.buildSellWindow()
        end
    end

    if uiElements.auctionSellWindow then
        uiElements.auctionSellWindow:SetVisible(visible)
        if visible then
            auction.refreshSellList()
        else
            auction.clearSessionAuctions()
        end
    end
end
