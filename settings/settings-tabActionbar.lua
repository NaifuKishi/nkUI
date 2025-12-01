local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabActionBar (name, parent)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local activateCheckbox, combatAlphaSlider, nonCombatAlphaSlider, offsetSlider, spacingSlider

    function frame:build()

        activateCheckbox = _settings.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.actionBars.activate = newValue

            if combatAlphaSlider then combatAlphaSlider:SetActive(newValue) end
            if nonCombatAlphaSlider then nonCombatAlphaSlider:SetActive(newValue) end
            if offsetSlider then offsetSlider:SetActive(newValue) end

            _internal.uiActionBarInit (newValue)        
        end)

        local moduleActive = nkUISetup.modules.actionBars.activate

        activateCheckbox:SetChecked(nkUISetup.modules.actionBars.activate)
        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
       
        combatAlphaSlider = _settings.slider(name .. ".combatAlphaSlider", frame, "Combat alpha <font color='#3399FF'>%d</font>%%", moduleActive, function (newValue)
             nkUISetup.modules.actionBars.combatAlpha = newValue / 100
        end)

        combatAlphaSlider:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, 15)
        combatAlphaSlider:SetRange(0, 100)
        combatAlphaSlider:SetMidValue(50)
        combatAlphaSlider:SetPrecision(5)
        combatAlphaSlider:AdjustValue(nkUISetup.modules.actionBars.combatAlpha * 100)

        nonCombatAlphaSlider = _settings.slider(name .. ".nonCombatAlphaSlider", frame, "Non combat alpha <font color='#3399FF'>%d</font>%%", moduleActive, function (newValue)
            nkUISetup.modules.actionBars.nonCombatAlpha = newValue / 100
            _internal.actionBarToggleAlpha()
        end)
        
        nonCombatAlphaSlider:SetPoint("TOPLEFT", combatAlphaSlider, "TOPRIGHT", 30, 0)
        nonCombatAlphaSlider:SetRange(0, 100)
        nonCombatAlphaSlider:SetMidValue(50)
        nonCombatAlphaSlider:SetPrecision(5)    
        nonCombatAlphaSlider:AdjustValue(nkUISetup.modules.actionBars.nonCombatAlpha * 100)

        offsetSlider = _settings.slider(name .. ".offsetSlider", frame, "Offset <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.actionBars.offset = newValue
        end)
        
        offsetSlider:SetPoint("TOPLEFT", combatAlphaSlider, "BOTTOMLEFT", 0, 5)
        offsetSlider:SetRange(-1000, 1000)
        offsetSlider:SetMidValue(0)
        offsetSlider:SetPrecision(5)    
        offsetSlider:AdjustValue(nkUISetup.modules.actionBars.offset)

        spacingSlider = _settings.slider(name .. ".spacingSlider", frame, "Spacing <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.actionBars.spacing = newValue
        end)
        
        spacingSlider:SetPoint("TOPLEFT", offsetSlider, "TOPRIGHT", 30, 0)
        spacingSlider:SetRange(-50, 50)
        spacingSlider:SetMidValue(0)
        spacingSlider:SetPrecision(5)    
        spacingSlider:AdjustValue(nkUISetup.modules.actionBars.spacing)        

    end

    return frame

end