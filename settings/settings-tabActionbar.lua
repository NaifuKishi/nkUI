local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local uiElements	= privateVars.uiElements
local langTexts     = privateVars.langTexts

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabActionBar (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckbox, combatAlphaSlider, nonCombatAlphaSlider, offsetSlider, spacingSlider, noOfMainBarsSlider, rightBarCheckbox, iconSizeSlider

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, langTexts.settings.activateModule, true, function(newValue)        
            nkUISetup.modules.actionBars.activate = newValue

            if combatAlphaSlider then combatAlphaSlider:SetActive(newValue) end
            if nonCombatAlphaSlider then nonCombatAlphaSlider:SetActive(newValue) end
            if offsetSlider then offsetSlider:SetActive(newValue) end
            if noOfMainBarsSlider then noOfMainBarsSlider:SetActive(newValue) end
            if rightBarCheckbox then rightBarCheckbox:SetActive(newValue) end
            if nonCombatAlphaSlider then nonCombatAlphaSlider:SetActive(newValue) end
            if rightBarCheckbox then rightBarCheckbox:SetActive(newValue) end
            if iconSizeSlider then iconSizeSlider:SetActive(newValue) end

            internalFunc.uiActionBarInit (newValue)
        end)

        local moduleActive = nkUISetup.modules.actionBars.activate

        activateCheckbox:SetChecked(nkUISetup.modules.actionBars.activate, true)
        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, settingsUI.PADDING.ACTIVE)
       
        combatAlphaSlider = settingsUI.slider(name .. ".combatAlphaSlider", frame, langTexts.settings.combatAlpha, moduleActive, function (newValue)
             nkUISetup.modules.actionBars.combatAlpha = newValue / 100
        end)

        combatAlphaSlider:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)
        combatAlphaSlider:SetRange(0, 100)
        combatAlphaSlider:SetMidValue(50)
        combatAlphaSlider:SetPrecision(5)
        combatAlphaSlider:AdjustValue(nkUISetup.modules.actionBars.combatAlpha * 100)

        nonCombatAlphaSlider = settingsUI.slider(name .. ".nonCombatAlphaSlider", frame, langTexts.settings.nonCombatAlpha, moduleActive, function (newValue)
            nkUISetup.modules.actionBars.nonCombatAlpha = newValue / 100
            internalFunc.actionBarToggleAlpha()
        end)
        
        nonCombatAlphaSlider:SetPoint("TOPLEFT", combatAlphaSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        nonCombatAlphaSlider:SetRange(0, 100)
        nonCombatAlphaSlider:SetMidValue(50)
        nonCombatAlphaSlider:SetPrecision(5)    
        nonCombatAlphaSlider:AdjustValue(nkUISetup.modules.actionBars.nonCombatAlpha * 100)

        noOfMainBarsSlider = settingsUI.slider(name .. ".noOfMainBarsSlider", frame, langTexts.settings.numberOfMainBars, moduleActive, function (newValue)
            nkUISetup.modules.actionBars.mainbars = newValue
            LibEKL.UI.reloadDialog ("nkUI")
        end)
        
        noOfMainBarsSlider:SetPoint("TOPLEFT", nonCombatAlphaSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        noOfMainBarsSlider:SetRange(1, 3)
        noOfMainBarsSlider:AdjustValue(nkUISetup.modules.actionBars.mainbars)

        rightBarCheckbox = settingsUI.checkbox(name .. ".rightBarCheckbox", frame, langTexts.settings.activateRightBar, moduleActive, function(newValue)        
            nkUISetup.modules.actionBars.rightbar = newValue
            uiElements.actionbars.rightScreen:SetVisible(newValue)
        end)

        rightBarCheckbox:SetPoint("TOPLEFT", noOfMainBarsSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        rightBarCheckbox:SetChecked(nkUISetup.modules.actionBars.rightbar, true)

        iconSizeSlider = settingsUI.slider(name .. ".iconSizeSlider", frame, langTexts.settings.iconSize, moduleActive, function (newValue)
            nkUISetup.modules.actionBars.iconSize = newValue
            LibEKL.UI.reloadDialog ("nkUI")
        end)
        
        iconSizeSlider:SetPoint("TOPLEFT", rightBarCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        iconSizeSlider:SetRange(20, 60)
        iconSizeSlider:SetMidValue(40)
        iconSizeSlider:SetPrecision(1)
        iconSizeSlider:AdjustValue(nkUISetup.modules.actionBars.iconSize)


    end

    return frame

end