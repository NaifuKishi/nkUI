local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local internalFunc = privateVars.internalFunc
local oneBag        = privateVars.oneBag

---------- local functions ---------

-- Creates the main bag UI window
function oneBag.createBagUI()
    
    local bagWindow = EnKai.uiCreateFrame("nkWindowMetro", "nkUI.bagWindow", uiElements.contextDialog)
    bagWindow:SetTitle("nkUI Inventory")
    bagWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    bagWindow:SetWidth(680 * data.uiScale)
    bagWindow:SetHeight(600 * data.uiScale)
    bagWindow:SetShadow(true)
    bagWindow:SetLayer(1)
    bagWindow:SetPoint("CENTER", UIParent, "CENTER", 1000 * data.uiScale, 000 * data.uiScale)
    
    bagWindow:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        Command.Cursor(nil)
    end, "nkUI.bagWindow.Event.Left.Up")
    
    return bagWindow
end