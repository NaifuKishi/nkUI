local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local lowerBar      = privateVars.lowerBar
local internalFunc  = privateVars.internalFunc

---------- init local variables ---------

local inspectCurrencyDetail = Inspect.Currency.Detail
local stringFormat          = string.format
local mathFloor             = math.floor

---------- local functions ---------

-- Creates and manages the currency display
function lowerBar.currency()
    local currencyText = '%s (%d)'
    local freeBagCount = 0
    
    local freeBagSlots = LibEKL.Inventory.getAvailableSlots()
    if freeBagSlots == false then
        LibEKL.Inventory.updateDB()
        freeBagSlots = LibEKL.Inventory.getAvailableSlots()
        if freeBagSlots ~= false then freeBagCount = #freeBagSlots end
    else
        freeBagCount = #freeBagSlots
    end

    local name = "lowerBar.datasetcurrency"
    local width = (uiElements.lowerBarCanvas:GetWidth() - uiElements.lowerBarTimeDate:GetWidth()) /8
    local height = uiElements.lowerBarCanvas:GetHeight()

    local datasetFrame = LibEKL.UICreateFrame("nkFrame", name .. ".frame", lowerBar.contextRestricted)
    datasetFrame:SetWidth(width)
    datasetFrame:SetHeight(height)
    datasetFrame:SetPoint("CENTERRIGHT", uiElements.lowerBarCanvas, "CENTERRIGHT", -width, 0)    
    --datasetFrame:SetBackgroundColor(1, 0, 0, 1)
    datasetFrame:SetLayer(2)    

    --print ("currency", -data.aFourth - (13/2))
    
    local datasetCurrency = LibEKL.UICreateFrame("nkText", "lowerBar.currency", lowerBar.contextRestricted)
    datasetCurrency:SetPoint("CENTER", datasetFrame, "CENTER", 21, 0)
    datasetCurrency:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetCurrency:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetCurrency:SetTextFont(addonInfo.id, "MontserratMedium")
    datasetCurrency:SetEffectGlow({ strength = 1})
    datasetCurrency:SetLayer(10)
        
    datasetCurrency:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        internalFunc.oneBagInit()
    end, "nkUI.lowerbar.currency.Left.Click")

    local datasetCurrencyIcon = LibEKL.UICreateFrame("nkTexture", "lowerBar.currency.icon", datasetCurrency)
    datasetCurrencyIcon:SetPoint("CENTERRIGHT", datasetCurrency, "CENTERLEFT", -5, 0)
    datasetCurrencyIcon:SetHeight(16)
    datasetCurrencyIcon:SetWidth(16)
    datasetCurrencyIcon:SetTextureAsync("nkUI", "gfx/questIconCoin.png")
    
    function datasetFrame:Redraw()
        datasetCurrency:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    end
    
    local function updateCoin(_, currency)
        if currency['coin'] == nil then return end
        
        local details = inspectCurrencyDetail('coin')
        
        if details ~= nil and details.stack ~= nil then
            local platin = math.floor(details.stack / 10000)
            local gold = math.floor((details.stack - (platin * 10000)) / 100)
            local silver = details.stack - (platin * 10000) - (gold * 100)

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

            datasetCurrency:SetText(stringFormat(currencyText, coinText, freeBagCount), true)
        end
    end
    
    Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].Update, function(_, a, b)
        local freeBagSlots = LibEKL.Inventory.getAvailableSlots()
        if freeBagSlots ~= false then freeBagCount = #freeBagSlots end
        updateCoin(_, {coin = true})
    end, "nkUI.LibEKL.InventoryManager.Update")
    
    Command.Event.Attach(Event.Currency, updateCoin, "nkUI.lowerbar.Currency.Currency")
    
    updateCoin(_, {coin = true})
    
    table.insert(uiElements.lowerBarModules, datasetFrame)
end