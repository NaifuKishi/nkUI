local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local langTexts     = privateVars.langTexts

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabLowerBar (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local fontSizeSlider, timeSizeSlider, dateSizeSlider, barHeightSlider, barWidthSlider, barTextSlider
    local fontHeader, barHeader
    local activateCheckbox

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, langTexts.settings.activateModule, true, function(newValue)
            nkUISetup.modules.lowerBar.activate = newValue

            if fontSizeSlider then fontSizeSlider:SetActive(newValue) end
            if timeSizeSlider then timeSizeSlider:SetActive(newValue) end
            if dateSizeSlider then dateSizeSlider:SetActive(newValue) end
            if barHeightSlider then barHeightSlider:SetActive(newValue) end
            if barWidthSlider then barWidthSlider:SetActive(newValue) end
            if barTextSlider then barTextSlider:SetActive(newValue) end

            internalFunc.lowerBarInit(newValue)
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.lowerBar.activate, true)

        local moduleActive = nkUISetup.modules.lowerBar.activate

        fontHeader = settingsUI.header(name .. ".fontHeader", frame, langTexts.settings.fontSizes)
        fontHeader:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, 15)

        fontSizeSlider = settingsUI.slider(name .. ".fontSizeSlider", frame, langTexts.settings.textDisplay, moduleActive, function(newValue)
            nkUISetup.modules.lowerBar.fontSize = newValue
            internalFunc.lowerBarRedraw()
        end)

        fontSizeSlider:SetPoint("TOPLEFT", fontHeader, "BOTTOMLEFT", 0, 15)
        fontSizeSlider:SetRange(8, 40)
        fontSizeSlider:SetMidValue(24)
        fontSizeSlider:SetPrecision(1)
        fontSizeSlider:AdjustValue(nkUISetup.modules.lowerBar.fontSize)

        timeSizeSlider = settingsUI.slider(name .. ".timeSizeSlider", frame, langTexts.settings.timeDisplay, moduleActive, function(newValue)
            nkUISetup.modules.lowerBar.timeSize = newValue
            internalFunc.lowerBarRedraw()
        end)

        timeSizeSlider:SetPoint("TOPLEFT", fontSizeSlider, "BOTTOMLEFT", 0, 10)
        timeSizeSlider:SetRange(10, 60)
        timeSizeSlider:SetMidValue(35)
        timeSizeSlider:SetPrecision(1)
        timeSizeSlider:AdjustValue(nkUISetup.modules.lowerBar.timeSize)

        dateSizeSlider = settingsUI.slider(name .. ".dateSizeSlider", frame, langTexts.settings.dateDisplay, moduleActive, function(newValue)
            nkUISetup.modules.lowerBar.dateSize = newValue
            internalFunc.lowerBarRedraw()
        end)

        dateSizeSlider:SetPoint("TOPLEFT", timeSizeSlider, "TOPRIGHT", 30, 0)
        dateSizeSlider:SetRange(10, 40)
        dateSizeSlider:SetMidValue(25)
        dateSizeSlider:SetPrecision(1)
        dateSizeSlider:AdjustValue(nkUISetup.modules.lowerBar.dateSize)

        barHeader = settingsUI.header(name .. ".barHeader", frame, langTexts.settings.expNotoriety)
        barHeader:SetPoint("TOPLEFT", timeSizeSlider, "BOTTOMLEFT", 0, 15)

        barTextSlider = settingsUI.slider(name .. ".barTextSlider", frame, langTexts.settings.textSizeHeader, moduleActive, function(newValue)
            nkUISetup.modules.lowerBar.barText = newValue
            internalFunc.lowerBarRedraw()
        end)

        barTextSlider:SetPoint("TOPLEFT", barHeader, "BOTTOMLEFT", 0, 15)
        barTextSlider:SetRange(10, 40)
        barTextSlider:SetMidValue(25)
        barTextSlider:SetPrecision(1)
        barTextSlider:AdjustValue(nkUISetup.modules.lowerBar.barText)

        barHeightSlider = settingsUI.slider(name .. ".barHeightSlider", frame, langTexts.settings.barHeight, moduleActive, function(newValue)
            nkUISetup.modules.lowerBar.barHeight = newValue
            internalFunc.lowerBarRedraw()
        end)

        barHeightSlider:SetPoint("TOPLEFT", barTextSlider, "BOTTOMLEFT", 0, 10)
        barHeightSlider:SetRange(10, 40)
        barHeightSlider:SetMidValue(25)
        barHeightSlider:SetPrecision(1)
        barHeightSlider:AdjustValue(nkUISetup.modules.lowerBar.barHeight)

        barWidthSlider = settingsUI.slider(name .. ".barWidthSlider", frame, langTexts.settings.barWidth, moduleActive, function(newValue)
            nkUISetup.modules.lowerBar.barWidth = newValue
            internalFunc.lowerBarRedraw()
        end)

        barWidthSlider:SetPoint("TOPLEFT", barHeightSlider, "TOPRIGHT", 30, 0)
        barWidthSlider:SetRange(100, 400)
        barWidthSlider:SetMidValue(250)
        barWidthSlider:SetPrecision(1)
        barWidthSlider:AdjustValue(nkUISetup.modules.lowerBar.barWidth)
    end

    return frame

end