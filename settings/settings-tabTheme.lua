local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI     = privateVars.settingsUI
local uiElements    = privateVars.uiElements
local langTexts     = privateVars.langTexts

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabTheme (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local logoComboBox, themeComboBox, managerComboBox, bankCheckBox

    function frame:build()

        logoComboBox = settingsUI.checkbox(name .. ".logoComboBox", frame, langTexts.settings.showLogo, true, function(newValue)
            nkUISetup.showLogo = newValue
        end)

        logoComboBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        logoComboBox:SetChecked(nkUISetup.showLogo, true)

        bankCheckBox = settingsUI.checkbox(name .. ".bankCheckBox", frame, langTexts.settings.useBank, true, function(newValue)
            nkUISetup.modules.oneBag.bankActivate = newValue
            LibEKL.UI.reloadDialog("nkUI")
        end)

        bankCheckBox:SetPoint("TOPLEFT", logoComboBox, "BOTTOMLEFT", 0, 10)
        bankCheckBox:SetChecked(nkUISetup.modules.oneBag.bankActivate, true)

        managerComboBox = settingsUI.checkbox(name .. ".managerComboBox", frame, langTexts.settings.minimapIconFrame, true, function(newValue)
            nkUISetup.useManager = newValue
            LibEKL.UI.reloadDialog("nkUI")
        end)

        managerComboBox:SetPoint("TOPLEFT", bankCheckBox, "BOTTOMLEFT", 0, 10)
        managerComboBox:SetChecked(nkUISetup.useManager, true)

        local themeList = {{ label = "Rift", value = "rift"}, { label = "WoW", value = "wow"}}

        themeComboBox = settingsUI.combobox(name .. ".theme", frame, langTexts.settings.selectColoringMode, true, function(newValue)
            nkUISetup.modules.unitFrames.colorScheme = newValue
            LibEKL.UI.reloadDialog("nkUI")
        end)

        local currentTheme = nkUISetup.modules.unitFrames.colorScheme

        themeComboBox:SetSelection(themeList)
        themeComboBox:SetSelectedValue(currentTheme, false)
        themeComboBox:SetPoint("TOPLEFT", managerComboBox, "BOTTOMLEFT", 0, 10)

    end

    return frame

end