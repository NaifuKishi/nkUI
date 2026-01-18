local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local oneBag        = privateVars.oneBag
local langTexts     = privateVars.langTexts

local inspectItemDetail = Inspect.Item.Detail

local stringFormat  = string.format
local mathFloor     = math.floor

---------- local functions ---------

local function uiItemTooltip ()

    local tooltip = LibEKL.UICreateFrame("nkCanvas", "nkUI.oneBag.tooltip", uiElements.contextTooltip)
    tooltip:SetPoint("TOPLEFT", UI.Native.Tooltip, "BOTTOMLEFT", 5, 5)
    tooltip:SetPoint("BOTTOMRIGHT", UI.Native.Tooltip, "BOTTOMRIGHT", -5, 55)
    
    local stroke = {r = .6, g = .6, b = .6, a = .8, thickness = 1 }
    local path =  {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }  
    local fill = {type = "solid", r = 0, g = 0, b = 0, a = .8}

    tooltip:SetShape(path, fill, stroke)

    local currencyIcon = LibEKL.UICreateFrame("nkTexture", "nkUI.oneBag.tooltip.Currency.icon", tooltip)
    currencyIcon:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, 10)
    currencyIcon:SetHeight(12)
    currencyIcon:SetWidth(12)
    currencyIcon:SetTextureAsync("nkUI", "gfx/questIconCoin.png")

    local valueText = LibEKL.UICreateFrame("nkText", "nkUI.oneBag.tooltip.valueText", tooltip)
    valueText:SetPoint("CENTERLEFT", currencyIcon, "CENTERRIGHT", 5, 0)
    valueText:SetFontSize(12 * data.bagScale)
    valueText:SetEffectGlow({strength = 3})
    valueText:SetFontColor(1, 1, 1, 1)

    LibEKL.UI.SetFont(valueText, addonInfo.id, "MontserratSemiBold")

    local bagIcon = LibEKL.UICreateFrame("nkTexture", "nkUI.oneBag.tooltip.BagSlotsIcon.icon", tooltip)
    bagIcon:SetPoint("TOPLEFT", currencyIcon, "BOTTOMLEFT", 0, 5)
    bagIcon:SetHeight(12)
    bagIcon:SetWidth(12)
    bagIcon:SetTextureAsync("nkUI", "gfx/iconPackage.png")

    local countText = LibEKL.UICreateFrame("nkText", "nkUI.oneBag.tooltip.countText", tooltip)
    countText:SetPoint("CENTERLEFT", bagIcon, "CENTERRIGHT", 5, 0)
    countText:SetFontSize(12 * data.bagScale)
    countText:SetEffectGlow({strength = 3})    
    countText:SetFontColor(0x85 / 255, 0xCB / 255, 0xCB / 255, 1)

    LibEKL.UI.SetFont(countText, addonInfo.id, "MontserratSemiBold")

    function tooltip:SetItem(itemID)

        local flag, details = pcall(inspectItemDetail, itemID)        
        local qty = 0

        if flag and details and details.sell then 
            qty = LibEKL.Inventory.queryQtyById (itemID)

            local platin = math.floor(details.sell / 10000)
            local gold = math.floor((details.sell - (platin * 10000)) / 100)
            local silver = details.sell - (platin * 10000) - (gold * 100)

            -- Build the coin string with only non-zero values
            local coinParts = {}
            if platin > 0 then
                table.insert(coinParts, string.format("<font color=\"#efebff\">%dp</font>", platin))
            end
            
            if gold > 0 or platin > 0 then
                table.insert(coinParts, string.format("<font color=\"#eed234\">%dg</font>", gold))
            end
            if silver > 0 or (platin > 0 or gold > 0) then
                table.insert(coinParts, string.format("<font color=\"#a7aba7\">%ds</font>", silver))
            end

            -- Combine the parts with spaces
            local coinText = table.concat(coinParts, " ")

            valueText:SetText(coinText, true)
        else
            valueText:SetText(langTexts.oneBag.noPrice)
        end
        
        if qty > 0 then countText:SetText(stringFormat(langTexts.oneBag.youOwn, qty)) end
    end

    return tooltip

end

function oneBag.showItemTooltip (thisItemID)

    if uiElements.oneBagItemTooltip == nil then
        uiElements.oneBagItemTooltip = uiItemTooltip()
    end

    uiElements.oneBagItemTooltip:SetItem(thisItemID)
    uiElements.oneBagItemTooltip:SetVisible(true)

end

function oneBag.hideItemTooltip ()

    if uiElements.oneBagItemTooltip then uiElements.oneBagItemTooltip:SetVisible(false) end

end