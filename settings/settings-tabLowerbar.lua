local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabLowerBar (name, parent)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local fontSizeSlider, timeSizeSlider, dateSizeSlider, barHeightSlider, barWidthSlider, barTextSlider
    local fontHeader, barHeader
    local activateCheckbox

    function frame:build()

        activateCheckbox = _settings.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.lowerBar.activate = newValue

            if fontSizeSlider then fontSizeSlider:SetActive(newValue) end
            if timeSizeSlider then timeSizeSlider:SetActive(newValue) end
            if dateSizeSlider then dateSizeSlider:SetActive(newValue) end
            if barHeightSlider then barHeightSlider:SetActive(newValue) end
            if barWidthSlider then barWidthSlider:SetActive(newValue) end
            if barTextSlider then barTextSlider:SetActive(newValue) end

            _internal.lowerBarInit (newValue)
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.lowerBar.activate)

        local moduleActive = nkUISetup.modules.lowerBar.activate

        fontHeader = EnKai.uiCreateFrame("nkText", name .. ".fontHeader", frame)
        fontHeader:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT" , 0, 15)
        fontHeader:SetFontSize(14)
        fontHeader:SetText("Font sizes")
        fontHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        fontSizeSlider = _settings.slider (name .. ".fontSizeSlider", frame, "Font size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.fontSize = newValue
        end)
        
        fontSizeSlider:SetPoint("TOPLEFT", fontHeader, "BOTTOMLEFT", 0, 15)
        fontSizeSlider:SetRange(0, 40)
        fontSizeSlider:SetMidValue(20)
        fontSizeSlider:SetPrecision(1)
        fontSizeSlider:AdjustValue(nkUISetup.modules.lowerBar.fontSize)

        timeSizeSlider = _settings.slider (name .. ".timeSizeSlider", frame, "Time size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.timeSize = newValue
        end)
        
        timeSizeSlider:SetPoint("TOPLEFT", fontSizeSlider, "BOTTOMLEFT", 0, 5)
        timeSizeSlider:SetRange(0, 60)
        timeSizeSlider:SetMidValue(30)
        timeSizeSlider:SetPrecision(1)
        timeSizeSlider:AdjustValue(nkUISetup.modules.lowerBar.timeSize)

        dateSizeSlider = _settings.slider (name .. ".dateSizeSlider", frame, "Date size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.dateSize = newValue
        end)
        
        dateSizeSlider:SetPoint("TOPLEFT", timeSizeSlider, "TOPRIGHT", 30, 0)
        dateSizeSlider:SetRange(0, 40)
        dateSizeSlider:SetMidValue(20)
        dateSizeSlider:SetPrecision(1)
        dateSizeSlider:AdjustValue(nkUISetup.modules.lowerBar.dateSize)

        barHeader = EnKai.uiCreateFrame("nkText", name .. ".fontHeabarHeaderder", frame)
        barHeader:SetPoint("TOPLEFT", timeSizeSlider, "BOTTOMLEFT" , 0, 15)
        barHeader:SetFontSize(14)
        barHeader:SetText("Bar setup")
        barHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        barHeightSlider = _settings.slider (name .. ".barHeightSlider", frame, "Bar height <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.barHeight = newValue
        end)
        
        barHeightSlider:SetPoint("TOPLEFT", barHeader, "BOTTOMLEFT", 0, 15)
        barHeightSlider:SetRange(0, 40)
        barHeightSlider:SetMidValue(20)
        barHeightSlider:SetPrecision(1)
        barHeightSlider:AdjustValue(nkUISetup.modules.lowerBar.barHeight)

        barWidthSlider = _settings.slider (name .. ".barWidthSlider", frame, "Bar width <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.barWidth = newValue
        end)
        
        barWidthSlider:SetPoint("TOPLEFT", barHeightSlider, "BOTTOMRIGHT", 30, 0)
        barWidthSlider:SetRange(0, 600)
        barWidthSlider:SetMidValue(300)
        barWidthSlider:SetPrecision(1)
        barWidthSlider:AdjustValue(nkUISetup.modules.lowerBar.barWidth)

        barTextSlider = _settings.slider (name .. ".barTextSlider", frame, "Font size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.barText = newValue
        end)
        
        barTextSlider:SetPoint("TOPLEFT", barHeightSlider, "BOTTOMLEFT", 0, 5)
        barTextSlider:SetRange(0, 40)
        barTextSlider:SetMidValue(20)
        barTextSlider:SetPrecision(1)
        barTextSlider:AdjustValue(nkUISetup.modules.lowerBar.barText)

    end

    return frame

end

