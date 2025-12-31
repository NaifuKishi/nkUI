local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI     = privateVars.settingsUI

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabSCT (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckbox, showXPCheckbox, showLootCheckbox

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.sct.activate = newValue
            internalFunc.sctToggle(newValue)

            --if messageOffsetSizeSlider then messageOffsetSizeSlider:SetActive(newValue) end
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.sct.activate, true)

        showXPCheckbox = settingsUI.checkbox(name .. ".showXPCheckbox", frame, "Show XP gains", true, function(newValue)        
             nkUISetup.modules.sct.showExpGains = newValue
             LibEKL.UI.reloadDialog ("nkUI")
        end)

        showXPCheckbox:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, 10)
        showXPCheckbox:SetChecked(nkUISetup.modules.sct.showExpGains, true)

        showLootCheckbox = settingsUI.checkbox(name .. ".showLootCheckbox", frame, "Show Loot gains", true, function(newValue)        
             nkUISetup.modules.sct.showLoot = newValue
             LibEKL.UI.reloadDialog ("nkUI")
        end)

        showLootCheckbox:SetPoint("TOPLEFT", showXPCheckbox, "BOTTOMLEFT", 0, 10)
        showLootCheckbox:SetChecked(nkUISetup.modules.sct.showLoot, true)

    end

    return frame

end