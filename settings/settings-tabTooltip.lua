local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI     = privateVars.settingsUI

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabTooltip (name, parent)

    local frame = LibEKL.uiCreateFrame("nkFrame", name, parent)
    local activateCheckbox

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.tooltip.activate = newValue
            internalFunc.sctToggle(newValue)
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.tooltip.activate, false)

    end

    return frame

end
