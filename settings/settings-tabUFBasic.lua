local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local langTexts     = privateVars.langTexts
local uiElements    = privateVars.uiElements

local stringFormat = string.format


---------- init local variables ---------

function settingsUI.uiConfigTabUFBasic (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckbox, buffsUnitBarCheckbox, combatAlphaSlider, nonCombatAlphaSlider, maxBuffSlider, onlyOwnBuffsCheckbox, smoothAnimationCheckbox, alwaysShowRessourceBarCheckbox
    local buffDurationLabel

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, langTexts.settings.activateModule, true, function(newValue)
            nkUISetup.modules.unitFrames.activate = newValue
            if buffsUnitBarCheckbox then buffsUnitBarCheckbox:SetActive(newValue) end
            if combatAlphaSlider then combatAlphaSlider:SetActive(newValue) end
            if nonCombatAlphaSlider then nonCombatAlphaSlider:SetActive(newValue) end
            if buffDurationSlider then buffDurationSlider:SetActive(newValue) end
            if maxBuffSlider then maxBuffSlider:SetActive(newValue) end
            if onlyOwnBuffsCheckbox then onlyOwnBuffsCheckbox:SetActive(newValue) end
            if smoothAnimationCheckbox then smoothAnimationCheckbox:SetActive(newValue) end
            if alwaysShowRessourceBarCheckbox then alwaysShowRessourceBarCheckbox:SetActive(newValue) end

            internalFunc.uiFramesToggle(newValue)

            if newValue == false then
                internalFunc.uiFramesRemoveBuffs()
            else
                internalFunc.uiFramesLoadAllBuffs()
            end
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, settingsUI.PADDING.ACTIVE)
        activateCheckbox:SetChecked(nkUISetup.modules.unitFrames.activate, true)

        local moduleActive = nkUISetup.modules.unitFrames.activate

        smoothAnimationCheckbox = settingsUI.checkbox(name .. ".smoothAnimationCheckbox", frame, langTexts.settings.smoothAnimations, moduleActive, function(newValue)
            nkUISetup.modules.unitFrames.smoothAnimation = newValue
        end)

        smoothAnimationCheckbox:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        smoothAnimationCheckbox:SetChecked(nkUISetup.modules.unitFrames.smoothAnimation, true)

        combatAlphaSlider = settingsUI.slider(name .. ".combatAlphaSlider", frame, langTexts.settings.combatAlpha, moduleActive, function (newValue)
            nkUISetup.modules.unitFrames.combatAlpha = newValue / 100
            internalFunc.toggleAlpha()
        end)

        combatAlphaSlider:SetPoint("TOPLEFT", smoothAnimationCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        combatAlphaSlider:SetRange(0, 100)
        combatAlphaSlider:SetMidValue(50)
        combatAlphaSlider:SetPrecision(1)
        combatAlphaSlider:AdjustValue(nkUISetup.modules.unitFrames.combatAlpha * 100)

        nonCombatAlphaSlider = settingsUI.slider(name .. ".nonCombatAlphaSlider", frame, langTexts.settings.nonCombatAlpha, moduleActive, function (newValue)
            nkUISetup.modules.unitFrames.nonCombatAlpha = newValue / 100
            internalFunc.toggleAlpha()
        end)

        nonCombatAlphaSlider:SetPoint("TOPLEFT", combatAlphaSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        nonCombatAlphaSlider:SetRange(0, 100)
        nonCombatAlphaSlider:SetMidValue(50)
        nonCombatAlphaSlider:SetPrecision(1)
        nonCombatAlphaSlider:AdjustValue(nkUISetup.modules.unitFrames.nonCombatAlpha * 100)

        buffsUnitBarCheckbox = settingsUI.checkbox(name .. ".buffsUnitBarCheckbox", frame, langTexts.settings.showBuffs, moduleActive, function(newValue)
            nkUISetup.modules.unitFrames.showBuffs = newValue

            if newValue == false then
                internalFunc.uiFramesRemoveBuffs()
            else
                internalFunc.uiFramesLoadAllBuffs()
            end
        end)

        buffsUnitBarCheckbox:SetPoint("TOPLEFT", nonCombatAlphaSlider, "BOTTOMLEFT", 0, 30)
        buffsUnitBarCheckbox:SetChecked(nkUISetup.modules.unitFrames.showBuffs, true)

        buffDurationLabel = settingsUI.label(name .. ".buffDurationLabel", frame, langTexts.settings.buffDuration)
        buffDurationLabel:SetPoint("TOPLEFT", buffsUnitBarCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)

        buffDurationSlider = settingsUI.slider(name .. ".buffDurationSlider", frame, langTexts.settings.lessThan, moduleActive, function (newValue)
            nkUISetup.modules.unitFrames.buffDuration = newValue
        end)

        buffDurationSlider:SetPoint("TOPLEFT", buffDurationLabel, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        buffDurationSlider:SetRange(10, 3600)
        buffDurationSlider:SetMidValue(1805)
        buffDurationSlider:SetPrecision(1)
        buffDurationSlider:AdjustValue(nkUISetup.modules.unitFrames.buffDuration)

        maxBuffSlider = settingsUI.slider(name .. ".maxBuffSlider", frame, langTexts.settings.maxBuffs, moduleActive, function (newValue)
            nkUISetup.modules.unitFrames.maxBuffCount = newValue
        end)

        maxBuffSlider:SetPoint("TOPLEFT", buffDurationSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        maxBuffSlider:SetRange(1, 15)
        maxBuffSlider:SetMidValue(7)
        maxBuffSlider:SetPrecision(1)
        maxBuffSlider:AdjustValue(nkUISetup.modules.unitFrames.maxBuffCount)

        onlyOwnBuffsCheckbox = settingsUI.checkbox(name .. ".onlyOwnBuffsCheckbox", frame, langTexts.settings.onlyOwnBuffs, moduleActive, function(newValue)
            nkUISetup.modules.unitFrames.showBuffs = newValue
        end)

        onlyOwnBuffsCheckbox:SetPoint("TOPLEFT", maxBuffSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        onlyOwnBuffsCheckbox:SetChecked(nkUISetup.modules.unitFrames.showOnlyOwnBuffs, true)        

    end

    return frame

end