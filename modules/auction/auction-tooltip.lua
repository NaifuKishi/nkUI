local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local auction       = privateVars.auction
local langTexts     = privateVars.langTexts

local stringFormat  = string.format
local mathFloor     = math.floor
local mathMax       = math.max
local mathMin       = math.min
local pairs         = pairs

---------- init local variables ---------

local TIP_W     = 260
local TIP_PAD   = 10
local CHART_H   = 70
local LINE_H    = 18

local COL_WHITE  = { r = 0.85, g = 0.85, b = 0.85, a = 1 }
local COL_GREY   = { r = 0.50, g = 0.52, b = 0.55, a = 1 }
local COL_GOLD   = { r = 0.90, g = 0.75, b = 0.10, a = 1 }
local COL_GREEN  = { r = 0.30, g = 0.85, b = 0.30, a = 1 }
local COL_RED    = { r = 0.85, g = 0.25, b = 0.25, a = 1 }
local COL_CHART  = { r = 0.40, g = 0.75, b = 1.00, a = 1 }

---------- rarity color helper ----------

local function getRarityColor(rarity)
    local c = LibEKL.Inventory.GetItemColor(rarity)
    if c then return c end
    return COL_WHITE
end

---------- chart drawing ----------

local function buildChartPath(snapshots, head, capacity, chartW, chartH)
    -- Collect lo values in chronological order (oldest first)
    local points = {}
    local depth = mathMin(14, capacity)
    for i = depth - 1, 0, -1 do
        local idx = (head - 1 - i) % capacity + 1
        local snap = snapshots[idx]
        if snap and snap.d and snap.d > 0 then
            points[#points + 1] = snap.lo
        end
    end

    if #points < 2 then return nil, nil, points end

    -- Normalize: find min/max with 10% padding
    local minP, maxP = points[1], points[1]
    for i = 2, #points do
        if points[i] < minP then minP = points[i] end
        if points[i] > maxP then maxP = points[i] end
    end
    local spread = maxP - minP
    if spread == 0 then spread = 1 end
    local pad = spread * 0.1
    minP = minP - pad
    maxP = maxP + pad

    local n = #points

    -- Fill path: bottom-left → data points → bottom-right → close
    local fillPath = {}
    fillPath[1] = { xProportional = 0, yProportional = 1 }
    for i = 1, n do
        local x = (i - 1) / (n - 1)
        local y = 1 - (points[i] - minP) / (maxP - minP)
        fillPath[#fillPath + 1] = { xProportional = x, yProportional = y }
    end
    fillPath[#fillPath + 1] = { xProportional = 1, yProportional = 1 }
    fillPath[#fillPath + 1] = { xProportional = 0, yProportional = 1 }

    -- Line path: only data points
    local linePath = {}
    for i = 1, n do
        local x = (i - 1) / (n - 1)
        local y = 1 - (points[i] - minP) / (maxP - minP)
        linePath[i] = { xProportional = x, yProportional = y }
    end

    return fillPath, linePath, points
end

---------- build tooltip frame ----------

function auction.buildTooltip()
    local name    = "nkUI.auction.tooltip"
    local context = uiElements.auctionSellWindow and
                    uiElements.auctionSellWindow:GetParent() or UIParent

    local tip = LibEKL.UICreateFrame("nkFrame", name, context)
    tip:SetWidth(TIP_W)
    tip:SetBackgroundColor(0.05, 0.06, 0.10, 0.97)
    tip:SetLayer(50)
    tip:SetVisible(false)

    -- Border (native Canvas, not nkCanvas wrapper)
    local border = UI.CreateFrame("Canvas", name .. ".border", tip)
    border:SetAllPoints(tip)
    border:SetLayer(1)
    local bPath = {
        { xProportional = 0, yProportional = 0 },
        { xProportional = 1, yProportional = 0 },
        { xProportional = 1, yProportional = 1 },
        { xProportional = 0, yProportional = 1 },
        { xProportional = 0, yProportional = 0 },
    }
    local bStroke = { r = 0x66/255, g = 0x56/255, b = 0x2e/255, a = 1,
                      cap = "round", miter = "miter", thickness = 2 }
    border:SetShape(bPath, nil, bStroke)

    -- Item icon
    local icon = LibEKL.UICreateFrame("nkTexture", name .. ".icon", tip)
    icon:SetPoint("TOPLEFT", tip, "TOPLEFT", TIP_PAD, TIP_PAD)
    icon:SetWidth(32)
    icon:SetHeight(32)
    icon:SetLayer(2)

    -- Item name
    local itemName = LibEKL.UICreateFrame("nkText", name .. ".name", tip)
    itemName:SetPoint("TOPLEFT",  icon, "CENTERRIGHT", 8, -10)
    itemName:SetPoint("TOPRIGHT", tip,  "TOPRIGHT",   -TIP_PAD, TIP_PAD)
    LibEKL.UI.SetFont(itemName, addonInfo.id, "MontserratBold")
    itemName:SetFontSize(11)
    itemName:SetFontColor(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, 1)
    itemName:SetLayer(2)

    -- Rarity label
    local rarityLabel = LibEKL.UICreateFrame("nkText", name .. ".rarity", tip)
    rarityLabel:SetPoint("TOPLEFT", icon, "CENTERRIGHT", 8, 2)
    LibEKL.UI.SetFont(rarityLabel, addonInfo.id, "MontserratMedium")
    rarityLabel:SetFontSize(9)
    rarityLabel:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    rarityLabel:SetLayer(2)

    -- Divider 1 (below header)
    local div1 = LibEKL.UICreateFrame("nkFrame", name .. ".div1", tip)
    div1:SetPoint("TOPLEFT",  tip, "TOPLEFT",  TIP_PAD,   TIP_PAD + 38)
    div1:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -TIP_PAD,  TIP_PAD + 38)
    div1:SetHeight(1)
    div1:SetBackgroundColor(0.3, 0.3, 0.3, 0.6)
    div1:SetLayer(2)

    -- Price rows: icon + label + value
    local ICON_W = 12
    local ICON_GAP = 4

    local function makeRow(rowName, yOff, iconPath)
        local ico = LibEKL.UICreateFrame("nkTexture", rowName .. ".ico", tip)
        ico:SetPoint("TOPLEFT", tip, "TOPLEFT", TIP_PAD, yOff + 3)
        ico:SetWidth(ICON_W)
        ico:SetHeight(ICON_W)
        ico:SetLayer(2)
        if iconPath then
            ico:SetTextureAsync("nkUI", iconPath)
        end

        local lbl = LibEKL.UICreateFrame("nkText", rowName .. ".lbl", tip)
        lbl:SetPoint("CENTERLEFT", ico, "CENTERRIGHT", ICON_GAP, 0)
        LibEKL.UI.SetFont(lbl, addonInfo.id, "MontserratMedium")
        lbl:SetFontSize(10)
        lbl:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
        lbl:SetLayer(2)

        local val = LibEKL.UICreateFrame("nkText", rowName .. ".val", tip)
        val:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -TIP_PAD, yOff)
        LibEKL.UI.SetFont(val, addonInfo.id, "MontserratSemiBold")
        val:SetFontSize(10)
        val:SetFontColor(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, 1)
        val:SetLayer(2)

        return ico, lbl, val
    end

    local ROW1 = TIP_PAD + 44
    local icoSuggest,  lblSuggest,  valSuggest  = makeRow(name .. ".suggest",  ROW1,            "gfx/questIconCoin.png")
    local icoLastLo,   lblLastLo,   valLastLo   = makeRow(name .. ".lastlo",   ROW1 + LINE_H,   "gfx/questIconCoin.png")
    local icoAvg,      lblAvg,      valAvg      = makeRow(name .. ".avg",      ROW1 + LINE_H*2, "gfx/iconAuction.png")
    local icoHi,       lblHi,       valHi       = makeRow(name .. ".hi",       ROW1 + LINE_H*3, "gfx/questIconCoin.png")

    -- Divider 2 (above chart)
    local CHART_Y = ROW1 + LINE_H * 4 + 4
    local div2 = LibEKL.UICreateFrame("nkFrame", name .. ".div2", tip)
    div2:SetPoint("TOPLEFT",  tip, "TOPLEFT",  TIP_PAD,  CHART_Y)
    div2:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -TIP_PAD, CHART_Y)
    div2:SetHeight(1)
    div2:SetBackgroundColor(0.3, 0.3, 0.3, 0.6)
    div2:SetLayer(2)

    -- Chart label
    local chartLabel = LibEKL.UICreateFrame("nkText", name .. ".chartLabel", tip)
    chartLabel:SetPoint("TOPLEFT", tip, "TOPLEFT", TIP_PAD, CHART_Y + 5)
    LibEKL.UI.SetFont(chartLabel, addonInfo.id, "MontserratBold")
    chartLabel:SetFontSize(9)
    chartLabel:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    chartLabel:SetText(langTexts.auction.tooltipChartLabel or "PRICE HISTORY")
    chartLabel:SetLayer(2)

    -- Chart area background
    local INNER_W   = TIP_W - TIP_PAD * 2
    local CHART_TOP = CHART_Y + 20
    local chartBg = LibEKL.UICreateFrame("nkFrame", name .. ".chartBg", tip)
    chartBg:SetPoint("TOPLEFT", tip, "TOPLEFT", TIP_PAD, CHART_TOP)
    chartBg:SetWidth(INNER_W)
    chartBg:SetHeight(CHART_H)
    chartBg:SetBackgroundColor(0, 0, 0, 0.3)
    chartBg:SetLayer(2)

    -- Fill canvas (area under line) – native Canvas, not nkCanvas wrapper
    local fillCanvas = UI.CreateFrame("Canvas", name .. ".chartFill", chartBg)
    fillCanvas:SetAllPoints(chartBg)
    fillCanvas:SetLayer(3)
    fillCanvas:SetVisible(false)

    -- Line canvas (the actual line) – native Canvas
    local lineCanvas = UI.CreateFrame("Canvas", name .. ".chartLine", chartBg)
    lineCanvas:SetAllPoints(chartBg)
    lineCanvas:SetLayer(4)
    lineCanvas:SetVisible(false)

    -- "Not enough data" label (shown when < 2 snapshots)
    local noDataLabel = LibEKL.UICreateFrame("nkText", name .. ".noData", chartBg)
    noDataLabel:SetPoint("CENTER", chartBg, "CENTER", 0, 0)
    LibEKL.UI.SetFont(noDataLabel, addonInfo.id, "MontserratMedium")
    noDataLabel:SetFontSize(9)
    noDataLabel:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    noDataLabel:SetText(langTexts.auction.tooltipNoData or "Not enough data")
    noDataLabel:SetLayer(5)
    noDataLabel:SetVisible(false)

    -- X-axis labels (oldest / today)
    local xLabelLeft = LibEKL.UICreateFrame("nkText", name .. ".xLeft", tip)
    xLabelLeft:SetPoint("TOPLEFT", tip, "TOPLEFT", TIP_PAD, CHART_TOP + CHART_H + 2)
    LibEKL.UI.SetFont(xLabelLeft, addonInfo.id, "MontserratMedium")
    xLabelLeft:SetFontSize(8)
    xLabelLeft:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    xLabelLeft:SetLayer(2)

    local xLabelRight = LibEKL.UICreateFrame("nkText", name .. ".xRight", tip)
    xLabelRight:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -TIP_PAD, CHART_TOP + CHART_H + 2)
    LibEKL.UI.SetFont(xLabelRight, addonInfo.id, "MontserratMedium")
    xLabelRight:SetFontSize(8)
    xLabelRight:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    xLabelRight:SetLayer(2)

    -- Divider 3 (above footer)
    local FOOTER_Y = CHART_TOP + CHART_H + 16
    local div3 = LibEKL.UICreateFrame("nkFrame", name .. ".div3", tip)
    div3:SetPoint("TOPLEFT",  tip, "TOPLEFT",  TIP_PAD,  FOOTER_Y)
    div3:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -TIP_PAD, FOOTER_Y)
    div3:SetHeight(1)
    div3:SetBackgroundColor(0.3, 0.3, 0.3, 0.6)
    div3:SetLayer(2)

    -- Auctions seen footer
    local icoSeen, lblSeen, valSeen = makeRow(name .. ".seen", FOOTER_Y + 4, "gfx/iconAuction.png")

    -- Total height
    local TOTAL_H = FOOTER_Y + LINE_H + TIP_PAD
    tip:SetHeight(TOTAL_H)

    -- Store all references
    tip._icon         = icon
    tip._itemName     = itemName
    tip._rarityLabel  = rarityLabel
    tip._icoLastLo    = icoLastLo
    tip._lblSuggest   = lblSuggest
    tip._valSuggest   = valSuggest
    tip._lblLastLo    = lblLastLo
    tip._valLastLo    = valLastLo
    tip._lblAvg       = lblAvg
    tip._valAvg       = valAvg
    tip._lblHi        = lblHi
    tip._valHi        = valHi
    tip._chartLabel   = chartLabel
    tip._fillCanvas   = fillCanvas
    tip._lineCanvas   = lineCanvas
    tip._noDataLabel  = noDataLabel
    tip._xLabelLeft   = xLabelLeft
    tip._xLabelRight  = xLabelRight
    tip._lblSeen      = lblSeen
    tip._valSeen      = valSeen

    uiElements.auctionTooltip = tip
end

---------- rarity name ----------

local RARITY_NAMES = { [0]="Common", [1]="Uncommon", [2]="Rare", [3]="Epic",
                       [4]="Relic", [5]="Transcendent", [6]="Quest" }

---------- show / hide ----------

function auction.showItemTooltip(item)
    if not uiElements.auctionTooltip then
        auction.buildTooltip()
    end
    local tip = uiElements.auctionTooltip

    -- Icon
    if item.icon then
        tip._icon:SetTextureAsync("Rift", item.icon)
        tip._icon:SetVisible(true)
    else
        tip._icon:SetVisible(false)
    end

    -- Name
    local color = getRarityColor(item.rarity)
    tip._itemName:SetFontColor(color.r, color.g, color.b, 1)
    tip._itemName:SetText(item.name or "")

    -- Rarity label
    local rarityName = RARITY_NAMES[item.rarity] or ""
    tip._rarityLabel:SetFontColor(color.r, color.g, color.b, 0.8)
    tip._rarityLabel:SetText(rarityName)

    -- Prices
    local lt = langTexts.auction
    local summary = item._summary
    local suggestedPrice = item._suggestedPrice

    tip._lblSuggest:SetText(lt.tooltipSuggest  or "Suggested")
    tip._lblLastLo:SetText( lt.tooltipLastLo   or "Last min")
    tip._lblAvg:SetText(    lt.tooltipAvg      or "Avg (days)")
    tip._lblHi:SetText(     lt.tooltipHi       or "High")
    tip._lblSeen:SetText(   lt.tooltipSeen     or "Auctions seen")

    if suggestedPrice and suggestedPrice > 0 then
        tip._valSuggest:SetText(internalFunc.formatCoins(suggestedPrice), true)
        tip._valSuggest:SetFontColor(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 1)
    else
        tip._valSuggest:SetText("—")
        tip._valSuggest:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    end

    if summary then
        -- Trend arrow on "Last min" icon
        local trend = item._trend
        if trend == "up" then
            tip._icoLastLo:SetTextureAsync("nkUI", "gfx/arrow-up.png")
        elseif trend == "down" then
            tip._icoLastLo:SetTextureAsync("nkUI", "gfx/arrow-down.png")
        else
            tip._icoLastLo:SetTextureAsync("nkUI", "gfx/arrow-right.png")
        end

        tip._valLastLo:SetText(internalFunc.formatCoins(summary.lastLo or 0), true)
        tip._valLastLo:SetFontColor(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, 1)

        tip._valAvg:SetText(internalFunc.formatCoins(summary.avg or 0), true)
        tip._valAvg:SetFontColor(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, 1)

        tip._valHi:SetText(internalFunc.formatCoins(summary.hi or 0), true)
        tip._valHi:SetFontColor(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, 1)

        tip._valSeen:SetText(tostring(summary.totalSeen or 0))
        tip._valSeen:SetFontColor(COL_GREY.r, COL_GREY.g, COL_GREY.b, 1)
    else
        tip._icoLastLo:SetTextureAsync("nkUI", "gfx/arrow-right.png")
    end

    -- Chart
    local itemData = auction.getItemData(item.itemType)
    local fillPath, linePath, points = nil, nil, {}
    if itemData and itemData.h and itemData.hh then
        fillPath, linePath, points = buildChartPath(
            itemData.h, itemData.hh, 14, TIP_W - TIP_PAD * 2, CHART_H)
    end

    if linePath then
        -- Draw fill (semi-transparent area)
        local fillColor = { type = "solid", r = COL_CHART.r, g = COL_CHART.g, b = COL_CHART.b, a = 0.12 }
        tip._fillCanvas:SetShape(fillPath, fillColor, nil)
        tip._fillCanvas:SetVisible(true)

        -- Draw line
        local lineStroke = { r = COL_CHART.r, g = COL_CHART.g, b = COL_CHART.b, a = 0.9,
                              thickness = 1.5, cap = "round", miter = "round" }
        tip._lineCanvas:SetShape(linePath, nil, lineStroke)
        tip._lineCanvas:SetVisible(true)

        tip._noDataLabel:SetVisible(false)

        -- X-axis labels
        local n = #points
        tip._xLabelLeft:SetText(stringFormat("%d days ago", n - 1))
        tip._xLabelRight:SetText("today")
    else
        -- Not enough data: hide canvases, show message
        tip._fillCanvas:SetVisible(false)
        tip._lineCanvas:SetVisible(false)
        tip._noDataLabel:SetVisible(true)
        tip._xLabelLeft:SetText("")
        tip._xLabelRight:SetText("")
    end

    -- Position: top-left corner at mouse cursor
    local mouse    = Inspect.Mouse()
    local parent   = tip:GetParent()
    local tipX     = mouse.x - parent:GetLeft()
    local tipY     = mouse.y - parent:GetTop()

    tip:SetPoint("TOPLEFT", parent, "TOPLEFT", tipX, tipY)
    tip:SetVisible(true)
end

function auction.hideTooltip()
    if uiElements.auctionTooltip then
        uiElements.auctionTooltip:SetVisible(false)
    end
end
