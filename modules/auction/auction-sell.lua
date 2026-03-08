local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local auction       = privateVars.auction
local langTexts     = privateVars.langTexts

local InspectItemList       = Inspect.Item.List
local InspectItemDetail     = Inspect.Item.Detail
local InspectTimeReal       = Inspect.Time.Real
local InspectSystemWatchdog = Inspect.System.Watchdog
local UtilityItemSlotInventory = Utility.Item.Slot.Inventory

local stringFormat  = string.format
local mathFloor     = math.floor
local mathMax       = math.max
local pairs         = pairs
local pcall         = pcall
local tostring      = tostring
local tableInsert   = table.insert
local tableRemove   = table.remove

---------- init local variables ---------

local WIN_W       = 390
local WIN_H       = 600
local ROW_H       = 24
local ICON_SIZE   = 20
local HEADER_H    = 30    -- nkWindow title bar height
local BOTTOM_H    = 60
local PAD         = 6

local COL_GREEN   = { r = 0.30, g = 0.85, b = 0.30, a = 1 }
local COL_YELLOW  = { r = 0.90, g = 0.75, b = 0.10, a = 1 }
local COL_RED     = { r = 0.85, g = 0.25, b = 0.25, a = 1 }
local COL_GREY    = { r = 0.45, g = 0.48, b = 0.52, a = 1 }
local COL_WHITE   = { r = 0.85, g = 0.85, b = 0.85, a = 1 }

local context = UI.CreateContext("nkUI.auction")
context:SetStrata("dialog")
context:SetLayer(3)

---------- recycling bin ----------

local rowPool    = {}
local activeRows = {}

---------- row creation ----------

local function createRow(parent, name, idx)
    local rowName = name .. ".row." .. idx

    local row = LibEKL.UICreateFrame("nkFrame", rowName, parent)
    row:SetHeight(ROW_H)
    row:SetBackgroundColor(0, 0, 0, 0)

    -- Icon texture
    local icon = LibEKL.UICreateFrame("nkTexture", rowName .. ".icon", row)
    icon:SetPoint("CENTERLEFT", row, "CENTERLEFT", PAD, 0)
    icon:SetWidth(ICON_SIZE)
    icon:SetHeight(ICON_SIZE)

    -- Item name text (includes quantity in parentheses)
    local itemText = LibEKL.UICreateFrame("nkText", rowName .. ".item", row)
    itemText:SetPoint("CENTERLEFT", icon, "CENTERRIGHT", PAD, 0)
    LibEKL.UI.SetFont(itemText, addonInfo.id, "MontserratMedium")
    itemText:SetFontSize(11)
    itemText:SetFontColor(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, 1)

    -- Price text
    local priceText = LibEKL.UICreateFrame("nkText", rowName .. ".price", row)
    priceText:SetPoint("CENTERRIGHT", row, "CENTERRIGHT", -30, 0)
    LibEKL.UI.SetFont(priceText, addonInfo.id, "MontserratMedium")
    priceText:SetFontSize(11)
    priceText:SetFontColor(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, 1)

    -- Trend indicator text
    local trendText = LibEKL.UICreateFrame("nkText", rowName .. ".trend", row)
    trendText:SetPoint("CENTERLEFT", priceText, "CENTERRIGHT", PAD, 0)
    LibEKL.UI.SetFont(trendText, addonInfo.id, "MontserratBold")
    trendText:SetFontSize(12)

    -- Alternating row background
    local bg = LibEKL.UICreateFrame("nkFrame", rowName .. ".bg", row)
    bg:SetAllPoints(row)
    bg:SetLayer(-1)
    bg:SetBackgroundColor(0, 0, 0, 0)

    row._icon      = icon
    row._itemText  = itemText
    row._priceText = priceText
    row._trendText = trendText
    row._bg        = bg

    -- Hover events for tooltip
    row:EventAttach(Event.UI.Input.Mouse.Cursor.In, function()
        if row._item then
            auction.showItemTooltip(row._item)
        end
    end, rowName .. ".CursorIn")

    row:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function()
        auction.hideTooltip()
    end, rowName .. ".CursorOut")

    -- Right-click to post item on AH at suggested price (48h, buyout only)
    row:EventAttach(Event.UI.Input.Mouse.Right.Up, function()
        local item = row._item
        if not item then return end
        if not item.itemKey then
            Command.Console.Display("general", true,
                '<font color="#FF6A00">nkUI AH: no itemKey for ' .. tostring(item.name) .. '</font>', true)
            return
        end
        if not item._suggestedPrice or item._suggestedPrice <= 0 then return end
        local ok, err = pcall(Command.Auction.Post, item.itemKey, 48, nil, item._suggestedPrice, false,
            function(h, status, errMsg)
                if status == "failed" then
                    Command.Console.Display("general", true,
                        '<font color="#FF6A00">nkUI AH Post failed: ' .. tostring(errMsg) .. '</font>', true)
                else
                    auction.refreshSellList()
                end
            end)
        if not ok then
            Command.Console.Display("general", true,
                '<font color="#FF6A00">nkUI AH Post error: ' .. tostring(err) .. '</font>', true)
        end
    end, rowName .. ".Right.Up")

    return row
end

local rowCounter = 0

local function getRow(parent, name)
    if #rowPool > 0 then
        local row = rowPool[#rowPool]
        rowPool[#rowPool] = nil
        row:SetVisible(true)
        return row
    end
    rowCounter = rowCounter + 1
    return createRow(parent, name, rowCounter)
end

local function releaseRow(row)
    row:SetVisible(false)
    rowPool[#rowPool + 1] = row
end

local function releaseAllRows()
    for i = #activeRows, 1, -1 do
        releaseRow(activeRows[i])
        activeRows[i] = nil
    end
end

---------- trend calculation ----------

local function getTrend(itemType)
    local summary = auction.getPriceSummary(itemType)
    if not summary or not summary.avg or summary.avg <= 0 then
        return nil, nil, nil
    end

    local threshold = (nkUISetup and nkUISetup.modules.auction
                       and nkUISetup.modules.auction.trendThreshold) or 0.15

    local ratio = summary.lastLo / summary.avg

    local trend
    if ratio >= (1 + threshold) then
        trend = "up"
    elseif ratio <= (1 - threshold) then
        trend = "down"
    else
        trend = "neutral"
    end

    return trend, summary.lastLo, summary
end

---------- suggested price calculation ----------

local function getSuggestedPrice(summary)
    if not summary or not summary.lastLo or summary.lastLo <= 0 then return nil end

    local cfg     = nkUISetup and nkUISetup.modules and nkUISetup.modules.auction
    local floor   = (cfg and cfg.priceFloor     or 0.85)
    local undercut = (cfg and cfg.undercutAmount or 1)

    local undercut_price = summary.lastLo - undercut
    local floor_price    = mathFloor(summary.avg * floor)

    return mathMax(undercut_price, floor_price)
end

---------- inventory scanning ----------

local function getInventoryItems()
    local grouped = {}  -- { [itemType] = { name, icon, rarity, stack, vendor, itemType } }

    -- Utility.Item.Slot.Inventory() without argument returns ALL bag slots at once
    local ok, slots = pcall(InspectItemList, UtilityItemSlotInventory())
    if ok and slots then
        for slot, itemKey in pairs(slots) do
            if itemKey and itemKey ~= false then
                local ok2, detail = pcall(InspectItemDetail, itemKey)
                if ok2 and detail and detail.name then
                    local iType = detail.type or detail.id
                    -- rarity is a number: 0=sellable, 1=uncommon, 2=rare, 3=epic,
                    --                     4=relic, 5=transcendent, 6=quest
                    -- Show all non-quest, non-bag items (bags have detail.slots set)
                    if detail.rarity ~= 6 and iType and not detail.slots then
                        if not grouped[iType] then
                            grouped[iType] = {
                                name     = detail.name,
                                icon     = detail.icon,
                                rarity   = detail.rarity,
                                stack    = detail.stack or 1,
                                vendor   = detail.sell,
                                itemType = iType,
                                itemKey  = itemKey,  -- instance key for Command.Auction.Post
                            }
                        else
                            grouped[iType].stack = grouped[iType].stack + (detail.stack or 1)
                        end
                    end
                end
            end
        end
    end

    -- Convert to array, filter to only items with AH price data AND a valid suggested price
    local list = {}
    for _, item in pairs(grouped) do
        local trend, lastLo, summary = getTrend(item.itemType)
        if trend then
            local suggestedPrice = getSuggestedPrice(summary)
            if suggestedPrice and suggestedPrice > 0 then
                item._trend          = trend
                item._lastLo         = lastLo
                item._summary        = summary
                item._suggestedPrice = suggestedPrice
                list[#list + 1] = item
            end
        end
    end

    -- Sort: up (green) first, neutral second, down (red) last;
    --       within each group descending by suggested price
    local trendOrder = { up = 1, neutral = 2, down = 3 }
    table.sort(list, function(a, b)
        local ta = trendOrder[a._trend] or 2
        local tb = trendOrder[b._trend] or 2
        if ta ~= tb then return ta < tb end
        return (a._suggestedPrice or 0) > (b._suggestedPrice or 0)
    end)

    return list
end

---------- rarity color lookup ----------

-- rarity is a number (0-6), LibEKL.Inventory.GetItemColor expects a number
local function getRarityColor(rarity)
    local c = LibEKL.Inventory.GetItemColor(rarity)
    if c then return c end
    return COL_WHITE
end

---------- populate rows ----------

local function populateRow(row, item, yPos)
    -- Icon
    if item.icon then
        row._icon:SetTextureAsync("Rift", item.icon)
        row._icon:SetVisible(true)
    else
        row._icon:SetVisible(false)
    end

    -- Item name with quantity in parentheses and rarity color
    local color = getRarityColor(item.rarity)
    local nameHex = stringFormat("#%02X%02X%02X",
        mathFloor(color.r * 255), mathFloor(color.g * 255), mathFloor(color.b * 255))
    local nameHtml
    if item.stack > 1 then
        nameHtml = stringFormat('<font color="%s">%s</font> <font color="#888888">(%d)</font>',
            nameHex, item.name, item.stack)
    else
        nameHtml = stringFormat('<font color="%s">%s</font>', nameHex, item.name)
    end
    row._itemText:SetText(nameHtml, true)

    -- Price
    local suggestedPrice = item._suggestedPrice
    if suggestedPrice and suggestedPrice > 0 then
        row._priceText:SetText(internalFunc.formatCoins(suggestedPrice), true)
        row._priceText:SetVisible(true)
    else
        row._priceText:SetText("")
        row._priceText:SetVisible(true)
    end

    -- Trend (pre-computed by getInventoryItems)
    local trend = item._trend

    if trend == "up" then
        row._trendText:SetText("^")
        row._trendText:SetFontColor(COL_GREEN.r, COL_GREEN.g, COL_GREEN.b, 1)
        row._trendText:SetVisible(true)
    elseif trend == "down" then
        row._trendText:SetText("v")
        row._trendText:SetFontColor(COL_RED.r, COL_RED.g, COL_RED.b, 1)
        row._trendText:SetVisible(true)
    elseif trend == "neutral" then
        row._trendText:SetText("-")
        row._trendText:SetFontColor(COL_YELLOW.r, COL_YELLOW.g, COL_YELLOW.b, 1)
        row._trendText:SetVisible(true)
    else
        row._trendText:SetText("")
        row._trendText:SetVisible(false)
    end

    -- Alternating row background
    if yPos % 2 == 0 then
        row._bg:SetBackgroundColor(1, 1, 1, 0.03)
    else
        row._bg:SetBackgroundColor(0, 0, 0, 0)
    end

    row._item = item   -- stored for tooltip hover handler

    row:SetPoint("TOPLEFT", row:GetParent(), "TOPLEFT", 0, yPos * ROW_H)
    row:SetWidth(WIN_W - 14)   -- fixed width matching scrollContent
    row:SetVisible(true)
end

---------- last updated text ----------

local function formatLastUpdated(lastScanTime)
    if not lastScanTime then
        return langTexts.auction.neverScanned or "Not yet scanned"
    end

    local diff = os.time() - lastScanTime
    if diff < 60 then
        return "LAST UPDATED: just now"
    elseif diff < 3600 then
        return stringFormat("LAST UPDATED: %d min ago", mathFloor(diff / 60))
    elseif diff < 86400 then
        local hours = mathFloor(diff / 3600)
        if hours == 1 then
            return "LAST UPDATED: 1 hour ago"
        end
        return stringFormat("LAST UPDATED: %d hours ago", hours)
    else
        local days = mathFloor(diff / 86400)
        if days == 1 then
            return "LAST UPDATED: 1 day ago"
        end
        return stringFormat("LAST UPDATED: %d days ago", days)
    end
end

---------- build sell window ----------

function auction.buildSellWindow()

    local name = "nkUI.auction"

    -- Window
    local win = LibEKL.UICreateFrame("nkWindow", name .. ".sell", context)
    win:SetWidth(WIN_W)
    win:SetHeight(WIN_H)
    win:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
        nkUISetup.modules.auction.x,
        nkUISetup.modules.auction.y)
    win:SetTitle(langTexts.auction.sellTitle or "Sell")
    win:SetTitleFont(addonInfo.id, "MontserratBold")
    win:SetTitleFontSize(14)
    win:SetTitleEffect({ strength = 3 })
    win:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g,
                          data.theme.labelColor.b, data.theme.labelColor.a)
    win:SetCloseable(true)
    win:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(12, 12, math.pi / 4, 0, 0),
        color = {
            { r = 0.1294, g = 0.1533, b = 0.2157, a = 1, position = 0 },
            { r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1 },
        },
    }, data.theme.STROKE_BORDER)

    -- Save position on move
    Command.Event.Attach(LibEKL.Events[name .. ".sell"].Moved, function()
        nkUISetup.modules.auction.x = win:GetLeft() - UIParent:GetLeft()
        nkUISetup.modules.auction.y = win:GetTop()  - UIParent:GetTop()
    end, name .. ".sell.Moved")

    local content = win:GetContent()

    -- Column headers
    local headerItem = LibEKL.UICreateFrame("nkText", name .. ".hdr.item", content)
    headerItem:SetPoint("TOPLEFT", content, "TOPLEFT", PAD + ICON_SIZE + PAD + PAD, 4)
    LibEKL.UI.SetFont(headerItem, addonInfo.id, "MontserratBold")
    headerItem:SetFontSize(10)
    headerItem:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    headerItem:SetText(langTexts.auction.colItem or "ITEM")

    local headerPrice = LibEKL.UICreateFrame("nkText", name .. ".hdr.price", content)
    headerPrice:SetPoint("TOPRIGHT", content, "TOPRIGHT", -30, 4)
    LibEKL.UI.SetFont(headerPrice, addonInfo.id, "MontserratBold")
    headerPrice:SetFontSize(10)
    headerPrice:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    headerPrice:SetText(langTexts.auction.colPrice or "PRICE")

    -- Separator line under headers
    local separator = LibEKL.UICreateFrame("nkFrame", name .. ".hdr.sep", content)
    separator:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, 20)
    separator:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PAD, 20)
    separator:SetHeight(1)
    separator:SetBackgroundColor(0.3, 0.3, 0.3, 0.5)

    -- Scroll pane: needs explicit SetWidth/SetHeight (anchoring both sides gives GetWidth() = 0)
    local SCROLL_W = WIN_W - 2
    local SCROLL_H = WIN_H - HEADER_H - 24 - BOTTOM_H - 4
    local scrollPane = LibEKL.UICreateFrame("nkScrollPane", name .. ".scroll", content)
    scrollPane:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 24)
    scrollPane:SetWidth(SCROLL_W)
    scrollPane:SetHeight(SCROLL_H)
    scrollPane:SetAdjust(ROW_H)
    scrollPane:SetColor(0, 0, 0, 0)
    scrollPane:SetColorInner({ r = 0, g = 0, b = 0, a = 0.2 })
    scrollPane:SetColorHighlight(data.theme.formElementColorMain)

    -- Scroll content frame: explicit width, placed as direct child of scrollPane
    local scrollContent = UI.CreateFrame("Frame", name .. ".scrollContent", scrollPane)
    scrollContent:SetWidth(SCROLL_W - 12)  -- -12 for scrollbar

    -- Bottom bar
    local bottomBar = LibEKL.UICreateFrame("nkFrame", name .. ".bottom", content)
    bottomBar:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    bottomBar:SetHeight(BOTTOM_H)
    bottomBar:SetBackgroundColor(0, 0, 0, 0.3)

    -- Scan button
    local btnScan = LibEKL.UICreateFrame("nkButton", name .. ".btnScan", bottomBar)
    btnScan:SetPoint("CENTERRIGHT", bottomBar, "CENTERRIGHT", -PAD, -8)
    btnScan:SetWidth(70)
    btnScan:SetHeight(24)
    btnScan:SetFillColor({ type = "solid", r = 0.15, g = 0.15, b = 0.20, a = 1 })
    btnScan:SetBorderColor(data.theme.STROKE_BORDER)
    btnScan:SetLabelColor(data.theme.labelColor)
    btnScan:SetFont(addonInfo.id, "MontserratBold")
    btnScan:SetFontSize(10)
    btnScan:SetText(langTexts.auction.btnScan or "Scan")

    -- Status text (scanning progress)
    local statusText = LibEKL.UICreateFrame("nkText", name .. ".status", bottomBar)
    statusText:SetPoint("BOTTOMLEFT", bottomBar, "BOTTOMLEFT", PAD, -4)
    LibEKL.UI.SetFont(statusText, addonInfo.id, "MontserratMedium")
    statusText:SetFontSize(9)
    statusText:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    statusText:SetText("")

    -- Last updated text
    local lastUpdatedText = LibEKL.UICreateFrame("nkText", name .. ".lastUpdated", bottomBar)
    lastUpdatedText:SetPoint("BOTTOMRIGHT", bottomBar, "BOTTOMRIGHT", -PAD, -4)
    LibEKL.UI.SetFont(lastUpdatedText, addonInfo.id, "MontserratBold")
    lastUpdatedText:SetFontSize(9)
    lastUpdatedText:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    lastUpdatedText:SetText(formatLastUpdated(auction.getLastScanTime()))

    -- Store references
    win._scrollPane    = scrollPane
    win._scrollContent = scrollContent
    win._statusText    = statusText
    win._lastUpdated   = lastUpdatedText
    win._btnScan       = btnScan

    -- Scan button handler
    btnScan:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        if auction.isScanInProgress() then return end

        statusText:SetText(langTexts.auction.scanStarted or "SCANNING: All auctions (initiating)....")
        statusText:SetFontColor(COL_YELLOW.r, COL_YELLOW.g, COL_YELLOW.b, 1)

        auction.startScan(
            -- onProgress
            function(pct)
                statusText:SetText(stringFormat(
                    langTexts.auction.scanProgress or "SCANNING: %d%%...", pct))
            end,
            -- onComplete
            function(total)
                statusText:SetText("")
                statusText:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
                lastUpdatedText:SetText(formatLastUpdated(auction.getLastScanTime()))

                -- Color "last updated" based on recency
                local lastScan = auction.getLastScanTime()
                if lastScan then
                    local diff = os.time() - lastScan
                    if diff < 3600 then
                        lastUpdatedText:SetFontColor(COL_GREEN.r, COL_GREEN.g, COL_GREEN.b, 1)
                    elseif diff < 86400 then
                        lastUpdatedText:SetFontColor(COL_YELLOW.r, COL_YELLOW.g, COL_YELLOW.b, 1)
                    else
                        lastUpdatedText:SetFontColor(COL_RED.r, COL_RED.g, COL_RED.b, 1)
                    end
                end

                -- Refresh the sell list with updated prices
                auction.refreshSellList()
            end
        )
    end, name .. ".btnScan.LeftUp")

    -- Inventory change events: refresh list
    Command.Event.Attach(Event.Item.Slot, function()
        if win:GetVisible() then
            auction.refreshSellList()
        end
    end, name .. ".Item.Slot")

    Command.Event.Attach(Event.Item.Update, function()
        if win:GetVisible() then
            auction.refreshSellList()
        end
    end, name .. ".Item.Update")

    win:SetVisible(false)
    uiElements.auctionSellWindow = win
end

---------- refresh sell list ----------

function auction.refreshSellList()
    local win = uiElements.auctionSellWindow
    if not win or not win:GetVisible() then return end

    local scrollContent = win._scrollContent

    -- Hide tooltip when list refreshes (avoids stale tooltip)
    auction.hideTooltip()

    -- Release all existing rows
    releaseAllRows()

    -- Get inventory items
    local items = getInventoryItems()

    -- Populate rows
    for i = 1, #items do
        local row = getRow(scrollContent, "nkUI.auction")
        populateRow(row, items[i], i - 1)
        activeRows[#activeRows + 1] = row
    end

    -- Update scroll content height and notify scrollPane
    local totalH = mathMax(#items * ROW_H, 1)
    scrollContent:SetHeight(totalH)
    win._scrollPane:SetContent(scrollContent)

    -- Update last updated display
    local lastUpdatedText = win._lastUpdated
    if lastUpdatedText then
        lastUpdatedText:SetText(formatLastUpdated(auction.getLastScanTime()))

        local lastScan = auction.getLastScanTime()
        if lastScan then
            local diff = os.time() - lastScan
            if diff < 3600 then
                lastUpdatedText:SetFontColor(COL_GREEN.r, COL_GREEN.g, COL_GREEN.b, 1)
            elseif diff < 86400 then
                lastUpdatedText:SetFontColor(COL_YELLOW.r, COL_YELLOW.g, COL_YELLOW.b, 1)
            else
                lastUpdatedText:SetFontColor(COL_RED.r, COL_RED.g, COL_RED.b, 1)
            end
        end
    end
end
