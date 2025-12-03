local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabUFBasic (name, parent)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local activateCheckbox, buffsUnitBarCheckbox, combatAlphaSlider, nonCombatAlphaSlider
    local buffDurationLabel

    function frame:build()

        activateCheckbox = _settings.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.unitFrames.activate = newValue
            if buffsUnitBarCheckbox then buffsUnitBarCheckbox:SetActive(newValue) end
            if combatAlphaSlider then combatAlphaSlider:SetActive(newValue) end
            if nonCombatAlphaSlider then nonCombatAlphaSlider:SetActive(newValue) end
            if buffDurationSlider then buffDurationSlider:SetActive(newValue) end

            _internal.uiFramesToggle(newValue)

            if newValue == false then 
                _internal.uiFramesRemoveBuffs()
            else
                _internal.uiFramesLoadAllBuffs()
            end
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.unitFrames.activate, true)

        local moduleActive = nkUISetup.modules.unitFrames.activate

        combatAlphaSlider = _settings.slider(name .. ".combatAlphaSlider", frame, "Combat alpha %d%%", moduleActive, function (newValue)
            nkUISetup.modules.unitFrames.combatAlpha = newValue / 100
            __internal.toggleAlpha()
        end)

        combatAlphaSlider:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, 15)
        combatAlphaSlider:SetRange(0, 100)
        combatAlphaSlider:SetMidValue(50)
        combatAlphaSlider:SetPrecision(1)
        combatAlphaSlider:AdjustValue(nkUISetup.modules.unitFrames.combatAlpha * 100)

        nonCombatAlphaSlider = _settings.slider(name .. ".nonCombatAlphaSlider", frame, "Non combat alpha %d%%", moduleActive, function (newValue)
            nkUISetup.modules.unitFrames.nonCombatAlpha = newValue / 100
            _internal.toggleAlpha()
        end)
        
        nonCombatAlphaSlider:SetPoint("TOPLEFT", combatAlphaSlider, "BOTTOMLEFT", 0, 5)
        nonCombatAlphaSlider:SetRange(0, 100)
        nonCombatAlphaSlider:SetMidValue(50)
        nonCombatAlphaSlider:SetPrecision(1)    
        nonCombatAlphaSlider:AdjustValue(nkUISetup.modules.unitFrames.nonCombatAlpha * 100)        

        buffsUnitBarCheckbox = _settings.checkbox(name .. ".buffsUnitBarCheckbox", frame, "Show buffs and debuffs", moduleActive, function(newValue)        
            nkUISetup.modules.unitFrames.showBuffs = newValue            

            if newValue == false then 
                _internal.uiFramesRemoveBuffs()
            else
                _internal.uiFramesLoadAllBuffs()
            end
        end)

        buffsUnitBarCheckbox:SetPoint("TOPLEFT", nonCombatAlphaSlider, "BOTTOMLEFT", 0, 30)
        buffsUnitBarCheckbox:SetChecked(nkUISetup.modules.unitFrames.showBuffs, true)

        buffDurationLabel = EnKai.uiCreateFrame("nkText", name .. ".buffDurationLabel", frame)
        buffDurationLabel:SetPoint("TOPLEFT", buffsUnitBarCheckbox, "BOTTOMLEFT", 0, 15)
        buffDurationLabel:SetFontSize(14)
        buffDurationLabel:SetTextFont(addonInfo.id, "Montserrat")
        buffDurationLabel:SetText("Only show buffs with duration")

        buffDurationSlider = _settings.slider(name .. ".buffDurationSlider", frame, "less than %d sec", moduleActive, function (newValue)
            nkUISetup.modules.unitFrames.buffDuration = newValue
        end)

        buffDurationSlider:SetPoint("TOPLEFT", buffDurationLabel, "BOTTOMLEFT", 0, 5)
        buffDurationSlider:SetRange(10, 3600)
        buffDurationSlider:SetMidValue(1805)
        buffDurationSlider:SetPrecision(1)
        buffDurationSlider:AdjustValue(nkUISetup.modules.unitFrames.buffDuration)

        
    end

    return frame

end