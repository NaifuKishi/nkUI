local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabTooltip (name, parent)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local activateCheckbox

    function frame:build()

        activateCheckbox = _settings.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.tooltip.activate = newValue
            _internal.sctToggle(newValue)
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.tooltip.activate, false)

    end

    return frame

end
