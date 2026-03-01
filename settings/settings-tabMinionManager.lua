local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local langTexts     = privateVars.langTexts

---------- init local variables ---------

function settingsUI.uiConfigTabMinionManager(name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckbox

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame,
            langTexts.settings.activateModule, true, function(newValue)
                nkUISetup.modules.minionManager.activate = newValue
                LibEKL.UI.reloadDialog("nkUI")
            end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, settingsUI.PADDING.ACTIVE)
        activateCheckbox:SetChecked(nkUISetup.modules.minionManager.activate, true)

    end

    return frame

end
