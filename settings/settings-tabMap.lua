local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local langTexts     = privateVars.langTexts
local uiElements    = privateVars.uiElements
local map           = privateVars.map

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabMap (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckbox, lockedCheckBox
    local labelDisplay, poiCheckbox, zoneTitleCheckbox, animationsCheckbox, rareCheckbox, rareCheckboxInfo, labelTrack, gatheringCheckbox, artifactCheckbox, animationsCheckboxheckboxInfo, animationSpeedSlider
    local questCheckbox, unknownCheckbox    

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, langTexts.settings.activateModule, true, function(newValue)
            nkUISetup.modules.map.activate = newValue
            
            if lockedCheckBox then lockedCheckBox:SetActive(newValue) end
            if poiCheckbox then poiCheckbox:SetActive(newValue) end
            if zoneTitleCheckbox then zoneTitleCheckbox:SetActive(newValue) end
            if animationsCheckbox then animationsCheckbox:SetActive(newValue) end
            if rareCheckbox then rareCheckbox:SetActive(newValue) end
            if gatheringCheckbox then gatheringCheckbox:SetActive(newValue) end
            if artifactCheckbox then artifactCheckbox:SetActive(newValue) end
            if animationSpeedSlider then animationSpeedSlider:SetActive(newValue) end
            if questCheckbox then questCheckbox:SetActive(newValue) end
            if unknownCheckbox then unknownCheckbox:SetActive(newValue) end

            LibEKL.UI.reloadDialog("nkUI")
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, settingsUI.PADDING.ACTIVE)
        activateCheckbox:SetChecked(nkUISetup.modules.map.activate, true)

        local moduleActive = nkUISetup.modules.map.activate

        lockedCheckBox = settingsUI.checkbox(name .. ".lockedCheckBox", frame, langTexts.map.lockedCheckbox, moduleActive, function(newValue)
            nkUISetup.modules.map.locked = newValue            
        end)

        lockedCheckBox:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        lockedCheckBox:SetChecked(nkUISetup.modules.map.locked)

        labelDisplay = settingsUI.header ( name .. ".labelDisplay", frame, langTexts.map.labelDisplaySettings)
        labelDisplay:SetPoint("TOPLEFT", lockedCheckBox, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)

        poiCheckbox = settingsUI.checkbox(name .. ".poiCheckbox", frame, langTexts.map.poiCheckbox, moduleActive, function(newValue)        
            nkUISetup.modules.map.showPOI = newValue
            map.ShowPOI(newValue)
        end)

        poiCheckbox:SetPoint("TOPLEFT", labelDisplay, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        poiCheckbox:SetChecked(nkUISetup.modules.map.showPOI)

        zoneTitleCheckbox = settingsUI.checkbox(name .. ".zoneTitleCheckbox", frame, langTexts.map.zoneTitleCheckbox, moduleActive, function(newValue)        
            nkUISetup.modules.map.showZoneTitle = newValue
            if uiElements.mapUI then uiElements.mapUI:SetZoneTitle(newValue) end
        end)

        zoneTitleCheckbox:SetPoint("TOPLEFT", poiCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        zoneTitleCheckbox:SetChecked(nkUISetup.modules.map.showZoneTitle)

        animationsCheckbox = settingsUI.checkbox(name .. ".animationsCheckbox", frame, langTexts.map.animationsCheckbox, moduleActive, function(newValue)        
            nkUISetup.modules.map.animations = newValue
            
            if uiElements.mapUI then uiElements.mapUI:SetAnimated(newValue, nkUISetup.modules.map.animationSpeed) end            
            if animationSpeedSlider then animationSpeedSlider:SetVisible(newValue) end

            if rareCheckBox then
                if newValue == true then
                    rareCheckbox:SetPoint("TOPLEFT", animationSpeedSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
                else
                    rareCheckbox:SetPoint("TOPLEFT", animationsCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
                end
            end
        end)

        animationsCheckbox:SetPoint("TOPLEFT", zoneTitleCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        animationsCheckbox:SetChecked(nkUISetup.modules.map.animations)
        
        animationsCheckboxheckboxInfo = settingsUI.label (name .. '.animationsCheckboxheckboxInfo', frame, langTexts.map.animationsCheckboxheckboxInfo)
        animationsCheckboxheckboxInfo:SetPoint("CENTERLEFT", animationsCheckbox, "CENTERRIGHT", 10, 0)
        animationsCheckboxheckboxInfo:SetFontColor(1, 0, 0, 1)
            
        animationSpeedSlider = settingsUI.slider (name .. ".animationSpeedSlider", frame, langTexts.map.animationSpeedSlider, moduleActive, function (newValue)
            nkUISetup.modules.map.animationSpeed = (100 - newValue) / 1000
            if uiElements.mapUI then uiElements.mapUI:SetAnimated(nkUISetup.modules.map.animations, nkUISetup.modules.map.animationSpeed) end
        end)
        
        animationSpeedSlider:SetPoint("TOPLEFT", animationsCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        animationSpeedSlider:SetRange(0, 100)
        animationSpeedSlider:SetMidValue(50)
        animationSpeedSlider:SetPrecision(1)
        animationSpeedSlider:AdjustValue(100 - nkUISetup.modules.map.animationSpeed * 1000)
                
        rareCheckbox = settingsUI.checkbox(name .. ".rareCheckbox", frame, langTexts.map.rareCheckbox, moduleActive, function(newValue)        
            nkUISetup.modules.map.rareMobs = newValue
            map.ShowRareMobs(newValue)
        end)
        
        rareCheckbox:SetPoint("TOPLEFT", animationSpeedSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        rareCheckbox:SetChecked(nkUISetup.modules.map.rareMobs)
        
        rareCheckboxInfo = settingsUI.label (name .. '.rareCheckboxInfo', frame, langTexts.map.rareCheckboxInfo)
        rareCheckboxInfo:SetPoint("CENTERLEFT", rareCheckbox, "CENTERRIGHT", 10, 0)
        rareCheckboxInfo:SetFontColor(1, 0, 0, 1)

        questCheckbox = settingsUI.checkbox(name .. ".questCheckbox", frame, langTexts.map.questCheckBox, moduleActive, function(newValue)        
            nkUISetup.modules.map.showQuest = newValue
            map.ShowQuest(newValue)
        end)
        
        questCheckbox:SetPoint("TOPLEFT", rareCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        questCheckbox:SetChecked(nkUISetup.modules.map.showQuest)

        unknownCheckbox = settingsUI.checkbox(name .. ".unknownCheckbox", frame, langTexts.map.unknownCheckbox, moduleActive, function(newValue)        
            nkUISetup.modules.map.showUnknown = newValue
        end)
        
        unknownCheckbox:SetPoint("TOPLEFT", questCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        unknownCheckbox:SetChecked(nkUISetup.modules.map.showUnknown)

        labelTrack = settingsUI.header ( name .. ".labelTrack", frame, langTexts.map.labelTrackSettings)
        labelTrack:SetPoint("TOPLEFT", unknownCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)
        
        gatheringCheckbox = settingsUI.checkbox(name .. ".gatheringCheckbox", frame, langTexts.map.gatheringCheckbox, moduleActive, function(newValue)        
            nkUISetup.modules.map.trackGathering = newValue
            map.ShowGathering(newValue)
        end)

        gatheringCheckbox:SetPoint("TOPLEFT", labelTrack, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        gatheringCheckbox:SetChecked(nkUISetup.modules.map.trackGathering)

        artifactCheckbox = settingsUI.checkbox(name .. ".artifactCheckbox", frame, langTexts.map.artifactCheckbox, moduleActive, function(newValue)        
            nkUISetup.modules.map.trackArtifacts = newValue
            map.ShowArtifacts(newValue)
        end)
        
        artifactCheckbox:SetPoint("TOPLEFT", gatheringCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        artifactCheckbox:SetChecked(nkUISetup.modules.map.trackArtifacts)

    end

    return frame

end