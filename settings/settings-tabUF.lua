local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI     = privateVars.settingsUI
local langTexts     = privateVars.langTexts

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabUF (name, parent, unitType, thisSettings)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local widthSlider, heightSlider, reverseCheckbox, nameFontSize, healthFontSize, energyFontSize, planarFontSize, nameMargins, healthMargins, energyMargins, planarMargins, combatIconMargins, roleIconMargins, tierIconMargins, combatIconSize, roleIconSize, tierIconSize, buffWidth, buffHeight, timerFontSize, stackFontSize, labelFontSize, levelFontSize
    local sizeHeader, fontSizesHeader, marginsHeader, iconSizeHeader, buffSizeHeader
    local introText

    function frame:build()

        sizeHeader = settingsUI.header(name .. ".sizeHeader", frame, langTexts.settings.unitFrameSize)
        sizeHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)

        widthSlider = settingsUI.slider(name .. ".widthSlider", frame, langTexts.settings.width, true, function(newValue)
            thisSettings.width = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        widthSlider:SetPoint("TOPLEFT", sizeHeader, "BOTTOMLEFT", 0, 15)
        widthSlider:SetRange(100, 400)
        widthSlider:SetMidValue(250)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(thisSettings.width)

        heightSlider = settingsUI.slider(name .. ".heightSlider", frame, langTexts.settings.height, true, function(newValue)
            thisSettings.height = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "TOPRIGHT", 30, 0)
        heightSlider:SetRange(10, 50)
        heightSlider:SetMidValue(30)
        heightSlider:SetPrecision(1)
        heightSlider:AdjustValue(thisSettings.height)

        if unitType ~= "raid" and unitType ~= "target.target" and unitType ~= "group" then
            reverseCheckbox = settingsUI.checkbox(name .. ".reverseCheckbox", frame, langTexts.settings.reverseDisplay, true, function(newValue)
                thisSettings.reverse = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            reverseCheckbox:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, 5)
            reverseCheckbox:SetChecked(thisSettings.reverse, true)
        end

        -- font sizes

        fontSizesHeader = settingsUI.header(name .. ".fontSizesHeader", frame, langTexts.settings.textSizeHeaders)

        if unitType ~= "raid" and unitType ~= "target.target" and unitType ~= "group" then
            fontSizesHeader:SetPoint("TOPLEFT", reverseCheckbox, "BOTTOMLEFT", 0, 15)
        else
            fontSizesHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, 15)
        end

        nameFontSize = settingsUI.slider(name .. ".nameFontSize", frame, langTexts.settings.unitName, true, function(newValue)
            thisSettings.fontSizes.name = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        nameFontSize:SetPoint("TOPLEFT", fontSizesHeader, "BOTTOMLEFT", 0, 10)
        nameFontSize:SetRange(10, 40)
        nameFontSize:SetMidValue(25)
        nameFontSize:SetPrecision(1)
        nameFontSize:AdjustValue(thisSettings.fontSizes.name)

        if unitType ~= "raid" and unitType ~= "target.target" then
            healthFontSize = settingsUI.slider(name .. ".healthFontSize", frame, langTexts.settings.healthText, true, function(newValue)
                thisSettings.fontSizes.health = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            healthFontSize:SetPoint("TOPLEFT", nameFontSize, "TOPRIGHT", 30, 0)
            healthFontSize:SetRange(10, 40)
            healthFontSize:SetMidValue(25)
            healthFontSize:SetPrecision(1)
            healthFontSize:AdjustValue(thisSettings.fontSizes.health)

            energyFontSize = settingsUI.slider(name .. ".energyFontSize", frame, langTexts.settings.energyText, true, function(newValue)
                thisSettings.fontSizes.energy = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            energyFontSize:SetPoint("TOPLEFT", nameFontSize, "BOTTOMLEFT", 0, 5)
            energyFontSize:SetRange(10, 40)
            energyFontSize:SetMidValue(25)
            energyFontSize:SetPrecision(1)
            energyFontSize:AdjustValue(thisSettings.fontSizes.energy)

            planarFontSize = settingsUI.slider(name .. ".planarFontSize", frame, langTexts.settings.planarText, true, function(newValue)
                thisSettings.fontSizes.planar = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            planarFontSize:SetPoint("TOPLEFT", energyFontSize, "TOPRIGHT", 30, 0)
            planarFontSize:SetRange(10, 40)
            planarFontSize:SetMidValue(25)
            planarFontSize:SetPrecision(1)
            planarFontSize:AdjustValue(thisSettings.fontSizes.planar)
        end

        levelFontSize = settingsUI.slider(name .. ".levelFontSize", frame, langTexts.settings.levelText, true, function(newValue)
            thisSettings.fontSizes.level = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        if unitType ~= "raid" and unitType ~= "target.target" then
            levelFontSize:SetPoint("TOPLEFT", energyFontSize, "BOTTOMLEFT", 0, 5)
        else
            levelFontSize:SetPoint("TOPLEFT", nameFontSize, "BOTTOMLEFT", 0, 5)
        end

        levelFontSize:SetRange(10, 40)
        levelFontSize:SetMidValue(25)
        levelFontSize:SetPrecision(1)
        levelFontSize:AdjustValue(thisSettings.fontSizes.level)

        -- icon sizes

        if unitType ~= "player.pet" then

            iconSizeHeader = settingsUI.header(name .. ".iconSizeHeader", frame, langTexts.settings.iconSizes)
            iconSizeHeader:SetPoint("TOPLEFT", levelFontSize, "BOTTOMLEFT", 0, 15)

            roleIconSize = settingsUI.slider(name .. ".roleIconSize", frame, langTexts.settings.roleIcon, true, function(newValue)
                thisSettings.iconSizes.role = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            roleIconSize:SetPoint("TOPLEFT", iconSizeHeader, "BOTTOMLEFT", 0, 15)
            roleIconSize:SetRange(10, 40)
            roleIconSize:SetMidValue(25)
            roleIconSize:SetPrecision(1)
            roleIconSize:AdjustValue(thisSettings.iconSizes.role)
        end

        if unitType ~= "raid" and unitType ~= "target.target" and unitType ~= "player.pet" then
            combatIconSize = settingsUI.slider(name .. ".combatIconSize", frame, langTexts.settings.combatMarkIcon, true, function(newValue)
                thisSettings.iconSizes.combat = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            combatIconSize:SetPoint("TOPLEFT", roleIconSize, "BOTTOMLEFT", 0, 5)
            combatIconSize:SetRange(10, 40)
            combatIconSize:SetMidValue(25)
            combatIconSize:SetPrecision(1)
            combatIconSize:AdjustValue(thisSettings.iconSizes.combat)

            if unitType ~= "group" then

                tierIconSize = settingsUI.slider(name .. ".tierIconSize", frame, langTexts.settings.tierIcon, true, function(newValue)
                    thisSettings.iconSizes.tier = newValue
                    internalFunc.uiFrameRedraw(unitType)
                end)

                tierIconSize:SetPoint("TOPLEFT", combatIconSize, "TOPRIGHT", 30, 0)
                tierIconSize:SetRange(10, 40)
                tierIconSize:SetMidValue(25)
                tierIconSize:SetPrecision(1)
                tierIconSize:AdjustValue(thisSettings.iconSizes.tier)
            end
        end

        if thisSettings.buffs ~= nil then

            -- buff sizes

            buffSizeHeader = settingsUI.header(name .. ".buffSizeHeader", frame, langTexts.settings.buffDisplaySetup)

            if unitType ~= "raid" and unitType ~= "target.target" and unitType ~= "player.pet" then
                buffSizeHeader:SetPoint("TOPLEFT", combatIconSize, "BOTTOMLEFT", 0, 15)
            elseif unitType ~= "player.pet" then
                buffSizeHeader:SetPoint("TOPLEFT", roleIconSize, "BOTTOMLEFT", 0, 15)
            else
                buffSizeHeader:SetPoint("TOPLEFT", levelFontSize, "BOTTOMLEFT", 0, 15)
            end

            buffWidth = settingsUI.slider(name .. ".buffWidth", frame, langTexts.settings.buffIconSize, true, function(newValue)
                thisSettings.buffs.width = newValue
                thisSettings.buffs.height = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            buffWidth:SetPoint("TOPLEFT", buffSizeHeader, "BOTTOMLEFT", 0, 15)
            buffWidth:SetRange(10, 40)
            buffWidth:SetMidValue(25)
            buffWidth:SetPrecision(1)
            buffWidth:AdjustValue(thisSettings.buffs.width)

            timerFontSize = settingsUI.slider(name .. ".timerFontSize", frame, langTexts.settings.timerSize, true, function(newValue)
                thisSettings.buffs.timer = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            timerFontSize:SetPoint("TOPLEFT", buffWidth, "BOTTOMLEFT", 0, 20)
            timerFontSize:SetRange(10, 30)
            timerFontSize:SetMidValue(20)
            timerFontSize:SetPrecision(1)
            timerFontSize:AdjustValue(thisSettings.buffs.timer)

            stackFontSize = settingsUI.slider(name .. ".stackFontSize", frame, langTexts.settings.stackSize, true, function(newValue)
                thisSettings.buffs.stack = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            stackFontSize:SetPoint("TOPLEFT", timerFontSize, "TOPRIGHT", 30, 0)
            stackFontSize:SetRange(10, 30)
            stackFontSize:SetMidValue(20)
            stackFontSize:SetPrecision(1)
            stackFontSize:AdjustValue(thisSettings.buffs.stack)
        end

    end

    return frame

end