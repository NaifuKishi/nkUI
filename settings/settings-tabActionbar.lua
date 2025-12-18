local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local _settings     = privateVars.settings
local uiElements	= privateVars.uiElements

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabActionBar (name, parent)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local activateCheckbox, combatAlphaSlider, nonCombatAlphaSlider, offsetSlider, spacingSlider, noOfMainBarsSlider, rightBarCheckbox

    function frame:build()

        activateCheckbox = _settings.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.actionBars.activate = newValue

            if combatAlphaSlider then combatAlphaSlider:SetActive(newValue) end
            if nonCombatAlphaSlider then nonCombatAlphaSlider:SetActive(newValue) end
            if offsetSlider then offsetSlider:SetActive(newValue) end

            internalFunc.uiActionBarInit (newValue)
        end)

        local moduleActive = nkUISetup.modules.actionBars.activate

        activateCheckbox:SetChecked(nkUISetup.modules.actionBars.activate, true)
        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
       
        combatAlphaSlider = _settings.slider(name .. ".combatAlphaSlider", frame, "Combat alpha <font color='#3399FF'>%d</font>%%", moduleActive, function (newValue)
             nkUISetup.modules.actionBars.combatAlpha = newValue / 100
        end)

        combatAlphaSlider:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, 30)
        combatAlphaSlider:SetRange(0, 100)
        combatAlphaSlider:SetMidValue(50)
        combatAlphaSlider:SetPrecision(5)
        combatAlphaSlider:AdjustValue(nkUISetup.modules.actionBars.combatAlpha * 100)

        nonCombatAlphaSlider = _settings.slider(name .. ".nonCombatAlphaSlider", frame, "Non combat alpha <font color='#3399FF'>%d</font>%%", moduleActive, function (newValue)
            nkUISetup.modules.actionBars.nonCombatAlpha = newValue / 100
            internalFunc.actionBarToggleAlpha()
        end)
        
        nonCombatAlphaSlider:SetPoint("TOPLEFT", combatAlphaSlider, "BOTTOMLEFT", 0, 10)
        nonCombatAlphaSlider:SetRange(0, 100)
        nonCombatAlphaSlider:SetMidValue(50)
        nonCombatAlphaSlider:SetPrecision(5)    
        nonCombatAlphaSlider:AdjustValue(nkUISetup.modules.actionBars.nonCombatAlpha * 100)

        noOfMainBarsSlider = _settings.slider(name .. ".noOfMainBarsSlider", frame, "Number of main bars <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.actionBars.mainbars = newValue
            EnKai.ui.reloadDialog ("nkUI")
        end)
        
        noOfMainBarsSlider:SetPoint("TOPLEFT", nonCombatAlphaSlider, "BOTTOMLEFT", 0, 10)
        noOfMainBarsSlider:SetRange(1, 3)
        --noOfMainBarsSlider:SetMidValue(1.5)
        noOfMainBarsSlider:AdjustValue(nkUISetup.modules.actionBars.mainbars)

        rightBarCheckbox = _settings.checkbox(name .. ".rightBarCheckbox", frame, "Activate right side bar", true, function(newValue)        
            nkUISetup.modules.actionBars.rightbar = newValue
            uiElements.actionbars.rightScreen:SetVisible(newValue)
        end)

        rightBarCheckbox:SetPoint("TOPLEFT", noOfMainBarsSlider, "BOTTOMLEFT", 0, 10)
        rightBarCheckbox:SetChecked(nkUISetup.modules.actionBars.rightbar, true)


    end

    return frame

end