local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local oneBag        = privateVars.oneBag

local inspectItemDetail = Inspect.Item.Detail

local stringFormat  = string.format
local mathFloor     = math.floor

local currencyTextPlatinum = '%d<font color="#efebff"> platinum</font>'
local currencyTextGold = '%d<font color="#eed234"> gold</font>'
local currencyTextSilver = '%d<font color="#a7aba7"> silver</font>'

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
        
    local valueText = LibEKL.UICreateFrame("nkText", "nkUI.oneBag.tooltip.valueText", tooltip)
    valueText:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 5, 5)
    valueText:SetFontSize(12 * data.bagScale)
    valueText:SetEffectGlow({strength = 3})
    valueText:SetFontColor(1, 1, 1, 1)

    LibEKL.UI.SetFont(valueText, addonInfo.id, "MontserratSemiBold")

    local countText = LibEKL.UICreateFrame("nkText", "nkUI.oneBag.tooltip.countText", tooltip)
    countText:SetPoint("TOPLEFT", valueText, "BOTTOMLEFT")
    countText:SetFontSize(12 * data.bagScale)
    countText:SetEffectGlow({strength = 3})
    countText:SetFontColor(1, 1, 1, 1)

    LibEKL.UI.SetFont(countText, addonInfo.id, "MontserratSemiBold")

    function tooltip:SetItem(itemID)

        local flag, details = pcall(inspectItemDetail, itemID)        
        local qty = 0

        if flag and details and details.sell then 
            qty = LibEKL.Inventory.queryQtyById (itemID)

            local platin = mathFloor(details.sell / 10000)
            local gold = mathFloor((details.sell - (platin * 10000)) / 100)
            local silver = details.sell - (platin * 10000) - (gold * 100)  
            
            local currencyText

            if platin > 0 then
                if currencyText then
                    currencyText = currency .. " " .. stringFormat(currencyTextPlatinum, platin)
                else
                    currencyText = stringFormat(currencyTextPlatinum, platin)
                end
            end

            if gold > 0 then
                if currencyText then
                    currencyText = currencyText .. " " .. stringFormat(currencyTextGold, gold)
                else
                    currencyText = stringFormat(currencyTextGold, gold)
                end
            end

            if silver > 0 then
                if currencyText then
                    currencyText = currencyText .. " " .. stringFormat(currencyTextSilver, silver)
                else
                    currencyText = stringFormat(currencyTextSilver, silver)
                end
            end

            valueText:SetText(stringFormat("Item value: %s", currencyText), true)
        else
            valueText:SetText("No price information")
        end
        
        if qty > 0 then countText:SetText(stringFormat("You own: %d", qty)) end
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