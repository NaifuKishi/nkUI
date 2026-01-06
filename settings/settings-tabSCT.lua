local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local langTexts     = privateVars.langTexts

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabSCT (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckbox, showXPCheckbox, showLootCheckbox

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, langTexts.settings.activateModule, true, function(newValue)
            nkUISetup.modules.sct.activate = newValue
            internalFunc.sctToggle(newValue)

            --if messageOffsetSizeSlider then messageOffsetSizeSlider:SetActive(newValue) end
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.sct.activate, true)

        showXPCheckbox = settingsUI.checkbox(name .. ".showXPCheckbox", frame, langTexts.settings.showXPGains, true, function(newValue)
             nkUISetup.modules.sct.showExpGains = newValue
             LibEKL.UI.reloadDialog("nkUI")
        end)

        showXPCheckbox:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, 10)
        showXPCheckbox:SetChecked(nkUISetup.modules.sct.showExpGains, true)

        showLootCheckbox = settingsUI.checkbox(name .. ".showLootCheckbox", frame, langTexts.settings.showLootGains, true, function(newValue)
             nkUISetup.modules.sct.showLoot = newValue
             LibEKL.UI.reloadDialog("nkUI")
        end)

        showLootCheckbox:SetPoint("TOPLEFT", showXPCheckbox, "BOTTOMLEFT", 0, 10)
        showLootCheckbox:SetChecked(nkUISetup.modules.sct.showLoot, true)

    end

    return frame

end