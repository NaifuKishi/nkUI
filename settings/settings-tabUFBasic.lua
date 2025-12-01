local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabUFBasic (name, parent)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local activateCheckbox, buffsUnitBarCheckbox, combatAlphaSlider, nonCombatAlphaSlider

    function frame:build()

        activateCheckbox = _settings.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.unitFrames.activate = newValue
            if buffsUnitBarCheckbox then buffsUnitBarCheckbox:SetActive(newValue) end
            if combatAlphaSlider then combatAlphaSlider:SetActive(newValue) end
            if nonCombatAlphaSlider then nonCombatAlphaSlider:SetActive(newValue) end

            _internal.uiFramesToggle(newValue)

            if newValue == false then 
                _internal.uiFramesRemoveBuffs()
            else
                _internal.uiFramesLoadAllBuffs()
            end
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.sct.activate)

        local moduleActive = nkUISetup.modules.unitFrames.activate

        buffsUnitBarCheckbox = _settings.checkbox(name .. ".buffsUnitBarCheckbox", frame, "Show buffs and debuffs", moduleActive, function(newValue)        
            nkUISetup.modules.unitFrames.showBuffs = newValue
            if newValue == false then 
                _internal.uiFramesRemoveBuffs()
            else
                _internal.uiFramesLoadAllBuffs()
            end
        end)

        buffsUnitBarCheckbox:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, 15)
        buffsUnitBarCheckbox:SetChecked(nkUISetup.modules.unitFrames.showBuffs)

        combatAlphaSlider = _settings.slider(name .. ".combatAlphaSlider", frame, "Combat alpha %d%%", moduleActive, function (newValue)
            nkUISetup.modules.unitFrames.combatAlpha = newValue / 100
        end)

        combatAlphaSlider:SetPoint("TOPLEFT", buffsUnitBarCheckbox, "BOTTOMLEFT", 0, 5)
        combatAlphaSlider:SetRange(0, 100)
        combatAlphaSlider:SetMidValue(50)
        combatAlphaSlider:SetPrecision(5)
        combatAlphaSlider:AdjustValue(nkUISetup.modules.unitFrames.combatAlpha * 100)

        nonCombatAlphaSlider = _settings.slider(name .. ".nonCombatAlphaSlider", frame, "Non combat alpha %d%%", moduleActive, function (newValue)
            nkUISetup.modules.unitFrames.nonCombatAlpha = newValue / 100
            _internal.actionBarToggleAlpha()
        end)
        
        nonCombatAlphaSlider:SetPoint("TOPLEFT", combatAlphaSlider, "BOTTOMLEFT", 0, 5)
        nonCombatAlphaSlider:SetRange(0, 100)
        nonCombatAlphaSlider:SetMidValue(50)
        nonCombatAlphaSlider:SetPrecision(5)    
        nonCombatAlphaSlider:AdjustValue(nkUISetup.modules.unitFrames.nonCombatAlpha * 100)
    end

    return frame

end