local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local langTexts     = privateVars.langTexts

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabBuffBar (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckBox, widthSlider, heightSlider, timerFontSizeSlider, stackFontSizeSlider, labelFontSizeSlider
    local sizeHeader, fontHeader, growRightCheckbox

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, langTexts.settings.activateModule, true, function(newValue)
            nkUISetup.modules.buffBar.activate = newValue
--[[
            if newValue then
                internalFunc.buffBar.loadAllBuffs()
            else
                internalFunc.buffBar.clearAllBuffs()
            end
]]
            if widthSlider then widthSlider:SetActive(newValue) end
            if timerFontSizeSlider then timerFontSizeSlider:SetActive(newValue) end
            if stackFontSizeSlider then stackFontSizeSlider:SetActive(newValue) end
            if growRightCheckbox then growRightCheckbox:SetActive(newValue) end

            LibEKL.UI.reloadDialog ("nkUI")
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, settingsUI.PADDING.ACTIVE)
        activateCheckbox:SetChecked(nkUISetup.modules.buffBar.activate, true)

        local moduleActive = nkUISetup.modules.buffBar.activate

        growRightCheckbox = settingsUI.checkbox(name .. ".growRightCheckbox", frame, langTexts.settings.buffBarGrowRight, moduleActive, function(newValue)
            nkUISetup.modules.unitFrames.buffBarGrowRight = newValue            
            LibEKL.UI.reloadDialog ("nkUI")
        end)

        growRightCheckbox:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        growRightCheckbox:SetChecked(nkUISetup.modules.unitFrames.buffBarGrowRight, true)

        sizeHeader = settingsUI.header(name .. ".sizeHeader", frame, langTexts.settings.sizeSetup)
        sizeHeader:SetPoint("TOPLEFT", growRightCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)

        widthSlider = settingsUI.slider(name .. ".widthSlider", frame, langTexts.settings.buffSize, moduleActive, function(newValue)
            nkUISetup.modules.buffBar.buffs.width = newValue
            nkUISetup.modules.buffBar.buffs.height = newValue

            internalFunc.buffBar.Redraw()
        end)

        widthSlider:SetPoint("TOPLEFT", sizeHeader, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        widthSlider:SetRange(10, 100)
        widthSlider:SetMidValue(55)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.width)

        fontHeader = settingsUI.header(name .. ".fontHeader", frame, langTexts.settings.comboPointSetup)
        fontHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)

        timerFontSizeSlider = settingsUI.slider(name .. ".timerFontSizeSlider", frame, langTexts.settings.timerSize, moduleActive, function(newValue)
            nkUISetup.modules.buffBar.buffs.timer = newValue
            internalFunc.buffBar.Redraw()
        end)

        timerFontSizeSlider:SetPoint("TOPLEFT", fontHeader, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        timerFontSizeSlider:SetRange(10, 40)
        timerFontSizeSlider:SetMidValue(25)
        timerFontSizeSlider:SetPrecision(1)
        timerFontSizeSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.timer)

        stackFontSizeSlider = settingsUI.slider(name .. ".stackFontSizeSlider", frame, langTexts.settings.stackSize, moduleActive, function(newValue)
            nkUISetup.modules.buffBar.buffs.stack = newValue
            internalFunc.buffBar.Redraw()
        end)

        stackFontSizeSlider:SetPoint("TOPLEFT", timerFontSizeSlider, "TOPRIGHT", 30, 0)
        stackFontSizeSlider:SetRange(10, 40)
        stackFontSizeSlider:SetMidValue(25)
        stackFontSizeSlider:SetPrecision(1)
        stackFontSizeSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.stack)

    end

    return frame

end