local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local langTexts     = privateVars.langTexts

---------- init local variables ---------

function settingsUI.uiConfigTabOneBag (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckbox, bankCheckBox, oneBagSizeSlider

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, langTexts.settings.activateModule, true, function(newValue)
            nkUISetup.modules.oneBag.activate = newValue
            LibEKL.UI.reloadDialog("nkUI")
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, settingsUI.PADDING.ACTIVE)
        activateCheckbox:SetChecked(nkUISetup.modules.oneBag.activate, true)

        bankCheckBox = settingsUI.checkbox(name .. ".bankCheckBox", frame, langTexts.settings.useBank, true, function(newValue)
            nkUISetup.modules.oneBag.bankActivate = newValue
            LibEKL.UI.reloadDialog("nkUI")
        end)

        bankCheckBox:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        bankCheckBox:SetChecked(nkUISetup.modules.oneBag.bankActivate, true)

        oneBagSizeSlider = settingsUI.slider(name .. ".oneBagSizeSlider", frame, langTexts.settings.oneBagScale, true, function(newValue)
            nkUISetup.modules.oneBag.scale = newValue / 100
            LibEKL.UI.reloadDialog("nkUI")
        end)

        oneBagSizeSlider:SetPoint("TOPLEFT", bankCheckBox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        oneBagSizeSlider:SetRange(30, 300)
        oneBagSizeSlider:SetMidValue(165)
        oneBagSizeSlider:AdjustValue(nkUISetup.modules.oneBag.scale * 100)

    end

    return frame

end
