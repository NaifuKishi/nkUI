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
    local logoComboBox, themeComboBox, managerComboBox, bankCheckBox, chatCheckBox, oneBagSizeSlider

    function frame:build()

        logoComboBox = settingsUI.checkbox(name .. ".logoComboBox", frame, langTexts.settings.showLogo, true, function(newValue)
            nkUISetup.showLogo = newValue
        end)

        logoComboBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, settingsUI.PADDING.ACTIVE)
        logoComboBox:SetChecked(nkUISetup.showLogo, true)

        chatCheckBox = settingsUI.checkbox(name .. ".chatCheckBox", frame, langTexts.settings.showChat, true, function(newValue)
            nkUISetup.modules.chat.activate = newValue
            LibEKL.UI.reloadDialog("nkUI")
        end)

        chatCheckBox:SetPoint("TOPLEFT", logoComboBox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        chatCheckBox:SetChecked(nkUISetup.modules.chat.activate, true)

        bankCheckBox = settingsUI.checkbox(name .. ".bankCheckBox", frame, langTexts.settings.useBank, true, function(newValue)
            nkUISetup.modules.oneBag.bankActivate = newValue
            LibEKL.UI.reloadDialog("nkUI")
        end)

        bankCheckBox:SetPoint("TOPLEFT", chatCheckBox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        bankCheckBox:SetChecked(nkUISetup.modules.oneBag.bankActivate, true)

        oneBagSizeSlider = settingsUI.slider(name .. ".oneBagSizeSlider", frame, langTexts.settings.oneBagScale, true, function(newValue)
            nkUISetup.modules.oneBag.scale = newValue / 100
            LibEKL.UI.reloadDialog("nkUI")
        end)

        oneBagSizeSlider:SetPoint("TOPLEFT", bankCheckBox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        oneBagSizeSlider:SetRange(30, 300)
        oneBagSizeSlider:SetMidValue(165)
        oneBagSizeSlider:AdjustValue(nkUISetup.modules.oneBag.scale * 100)        

        managerComboBox = settingsUI.checkbox(name .. ".managerComboBox", frame, langTexts.settings.minimapIconFrame, true, function(newValue)
            nkUISetup.useManager = newValue
            LibEKL.UI.reloadDialog("nkUI")
        end)

        managerComboBox:SetPoint("TOPLEFT", oneBagSizeSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        managerComboBox:SetChecked(nkUISetup.useManager, true)

        local themeList = {{ label = "Rift", value = "rift"}, { label = "WoW", value = "wow"}}

        themeComboBox = settingsUI.combobox(name .. ".theme", frame, langTexts.settings.selectColoringMode, true, function(newValue)
            nkUISetup.modules.unitFrames.colorScheme = newValue
            LibEKL.UI.reloadDialog("nkUI")
        end)

        local currentTheme = nkUISetup.modules.unitFrames.colorScheme

        themeComboBox:SetSelection(themeList)
        themeComboBox:SetSelectedValue(currentTheme, false)
        themeComboBox:SetPoint("TOPLEFT", managerComboBox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)

    end

    return frame

end