local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local internalFunc = privateVars.internalFunc
local oneBag        = privateVars.oneBag

---------- local functions ---------

local stringFormat  = string.format

-- Creates the main bag UI window
function oneBag.createBagUI()
    
    local bagWindow = EnKai.uiCreateFrame("nkWindowMetro", "nkUI.bagWindow", uiElements.contextDialog)
    bagWindow:SetTitle(stringFormat("%s's inventory", EnKai.unit.getPlayerDetails().name))
    bagWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    bagWindow:SetTitleEffect({ strength = 3})
    bagWindow:SetWidth(680 * data.uiScale)
    bagWindow:SetHeight(600 * data.uiScale)
    bagWindow:SetShadow(true)
    bagWindow:SetLayer(1)
    bagWindow:SetPoint("CENTER", UIParent, "CENTER", 1000 * data.uiScale, 000 * data.uiScale)
    bagWindow:SetColor(nil, 
     { type = "solid", r = nkUISetup.modules.oneBag.windowColor.r, g  = nkUISetup.modules.oneBag.windowColor.g, b = nkUISetup.modules.oneBag.windowColor.b, a = nkUISetup.modules.oneBag.windowColor.a} 
    )
    
    bagWindow:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        Command.Cursor(nil)
    end, "nkUI.bagWindow.Event.Left.Up")
    
    return bagWindow
end