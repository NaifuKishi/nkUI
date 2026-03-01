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

    local datasetFrame = lowerBar.dataSet("lowerBar.datasetcurrency", "gfx/questIconCoin.png", "right")
        
    datasetFrame:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        internalFunc.oneBagInit()
    end, "nkUI.lowerbar.currency.Left.Click")

    function datasetFrame:Redraw()
        datasetFrame:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
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
                table.insert(coinParts, string.format("<font color=\"#efebff\">%sp</font>", LibEKL.strings.formatNumber(platin)))
            end
            
            if gold > 0 or platin > 0 then
                table.insert(coinParts, string.format("<font color=\"#eed234\">%dg</font>", gold))
            end
            if silver > 0 or (platin > 0 or gold > 0) then
                table.insert(coinParts, string.format("<font color=\"#a7aba7\">%ds</font>", silver))
            end

            -- Combine the parts with spaces
            local coinText = table.concat(coinParts, " ")

            datasetFrame:SetText(stringFormat(currencyText, coinText, freeBagCount), true)
        end
    end
    
    Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].Update, function(_, a, b)
        local freeBagSlots = LibEKL.Inventory.getAvailableSlots()
        if freeBagSlots ~= false then freeBagCount = #freeBagSlots end
        updateCoin(_, {coin = true})
    end, "nkUI.LibEKL.InventoryManager.Update")
    
    Command.Event.Attach(Event.Currency, updateCoin, "nkUI.lowerbar.Currency.Currency")
    
    updateCoin(_, {coin = true})
    
    return datasetFrame
end