local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local oneBag        = privateVars.oneBag

---------- local functions ---------

local stringFormat  = string.format

-- Creates the main bag UI window
function oneBag.createBagUI()
    
    local bagWindow = LibEKL.uiCreateFrame("nkwindow", "nkUI.bagWindow", uiElements.contextDialog)
    bagWindow:SetTitle(stringFormat("%s's inventory", LibEKL.unit.getPlayerDetails().name))
    bagWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    bagWindow:SetTitleFontSize(16)
    bagWindow:SetTitleEffect({ strength = 3})
    bagWindow:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

    bagWindow:SetWidth(690 * data.uiScale)
    bagWindow:SetHeight(600 * data.uiScale)
    bagWindow:SetLayer(1)    
    bagWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 2000 * data.uiScale, 600 * data.uiScale)

    bagWindow:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, -(math.pi / 6), 0, 0), -- Negative angle for opposite direction
        color = {
            data.theme.windowStartColor,
            data.theme.windowEndColor
            }
    },  { r = 0, g = 0, b = 0, a = 1, thickness = 1})
    
    bagWindow:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        Command.Cursor(nil)
    end, "nkUI.bagWindow.Event.Left.Up")

    bagWindow:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function()
        oneBag.hideItemTooltip()
    end, "nkUI.bagWindow.Event.Mouse.Cursor.Out")
    
    return bagWindow
end