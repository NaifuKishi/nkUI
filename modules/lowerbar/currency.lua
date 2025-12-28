local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local lowerBar      = privateVars.lowerBar

---------- init local variables ---------

local inspectCurrencyDetail = Inspect.Currency.Detail
local stringFormat          = string.format
local mathFloor             = math.floor

---------- local functions ---------

-- Creates and manages the currency display
function lowerBar.currency()
    local currencyText = '%d<font color="#efebff">p</font> %d<font color="#eed234">g</font> %d<font color="#a7aba7">s</font> (%d)'
    local freeBagCount = 0
    
    local freeBagSlots = LibEKL.Inventory.getAvailableSlots()
    if freeBagSlots == false then
        LibEKL.Inventory.updateDB()
        freeBagSlots = LibEKL.Inventory.getAvailableSlots()
        if freeBagSlots ~= false then freeBagCount = #freeBagSlots end
    else
        freeBagCount = #freeBagSlots
    end
    
    local datasetCurrency = LibEKL.UICreateFrame("nkText", "lowerBar.currency", lowerBar.contextRestricted)
    datasetCurrency:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMRIGHT", -data.aThird - 10, -5)
    datasetCurrency:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetCurrency:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetCurrency:SetTextFont(addonInfo.id, "Montserrat")
    datasetCurrency:SetEffectGlow({ strength = 1})
    
    datasetCurrency:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        internalFunc.oneBagInit()
    end, "nkUI.lowerbar.currency.Left.Click")

    local datasetCurrencyIcon = LibEKL.UICreateFrame("nkTexture", "lowerBar.currency.icon", datasetCurrency)
    datasetCurrencyIcon:SetPoint("CENTERRIGHT", datasetCurrency, "CENTERLEFT", -5, 0)
    datasetCurrencyIcon:SetHeight(16)
    datasetCurrencyIcon:SetWidth(16)
    datasetCurrencyIcon:SetTextureAsync("nkUI", "gfx/lowerbarGold.png")
    
    function datasetCurrency:Redraw()
        datasetCurrency:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    end
    
    local function updateCoin(_, currency)
        if currency['coin'] == nil then return end
        
        local details = inspectCurrencyDetail('coin')
        
        if details ~= nil and details.stack ~= nil then
            local platin = mathFloor(details.stack / 10000)
            local gold = mathFloor((details.stack - (platin * 10000)) / 100)
            local silver = details.stack - (platin * 10000) - (gold * 100)
            
            datasetCurrency:SetText(stringFormat(currencyText, platin, gold, silver, freeBagCount), true)
        end
    end
    
    Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].Update, function(_, a, b)
        local freeBagSlots = LibEKL.Inventory.getAvailableSlots()
        if freeBagSlots ~= false then freeBagCount = #freeBagSlots end
        updateCoin(_, {coin = true})
    end, "nkUI.LibEKL.InventoryManager.Update")
    
    Command.Event.Attach(Event.Currency, updateCoin, "nkUI.lowerbar.Currency.Currency")
    
    updateCoin(_, {coin = true})
    
    table.insert(uiElements.lowerBarModules, datasetCurrency)
end