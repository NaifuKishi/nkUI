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

        fontHeader = _settings.header ( name .. ".fontHeader", frame, "Font sizes")
        fontHeader:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT" , 0, 15)

        fontSizeSlider = _settings.slider (name .. ".fontSizeSlider", frame, "Text display <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.fontSize = newValue
            _internal.lowerBarRedraw()
        end)
        
        fontSizeSlider:SetPoint("TOPLEFT", fontHeader, "BOTTOMLEFT", 0, 15)
        fontSizeSlider:SetRange(8, 40)
        fontSizeSlider:SetMidValue(24)
        fontSizeSlider:SetPrecision(1)
        fontSizeSlider:AdjustValue(nkUISetup.modules.lowerBar.fontSize)

        timeSizeSlider = _settings.slider (name .. ".timeSizeSlider", frame, "Time display <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.timeSize = newValue
            _internal.lowerBarRedraw()
        end)
        
        timeSizeSlider:SetPoint("TOPLEFT", fontSizeSlider, "BOTTOMLEFT", 0, 10)
        timeSizeSlider:SetRange(10, 60)
        timeSizeSlider:SetMidValue(35)
        timeSizeSlider:SetPrecision(1)
        timeSizeSlider:AdjustValue(nkUISetup.modules.lowerBar.timeSize)

        dateSizeSlider = _settings.slider (name .. ".dateSizeSlider", frame, "Date display <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.dateSize = newValue
            _internal.lowerBarRedraw()
        end)
        
        dateSizeSlider:SetPoint("TOPLEFT", timeSizeSlider, "TOPRIGHT", 30, 0)
        dateSizeSlider:SetRange(10, 40)
        dateSizeSlider:SetMidValue(25)
        dateSizeSlider:SetPrecision(1)
        dateSizeSlider:AdjustValue(nkUISetup.modules.lowerBar.dateSize)

        barHeader = _settings.header ( name .. ".barHeader", frame, "Experience and notority datasets")
        barHeader:SetPoint("TOPLEFT", timeSizeSlider, "BOTTOMLEFT" , 0, 15)

        barTextSlider = _settings.slider (name .. ".barTextSlider", frame, "Text size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.barText = newValue
            _internal.lowerBarRedraw()
        end)
        
        barTextSlider:SetPoint("TOPLEFT", barHeader, "BOTTOMLEFT", 0, 15)
        barTextSlider:SetRange(10, 40)
        barTextSlider:SetMidValue(25)
        barTextSlider:SetPrecision(1)
        barTextSlider:AdjustValue(nkUISetup.modules.lowerBar.barText)        

        barHeightSlider = _settings.slider (name .. ".barHeightSlider", frame, "Bar height <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.barHeight = newValue
            _internal.lowerBarRedraw()
        end)
        
        barHeightSlider:SetPoint("TOPLEFT", barTextSlider, "BOTTOMLEFT", 0, 10)
        barHeightSlider:SetRange(10, 40)
        barHeightSlider:SetMidValue(25)
        barHeightSlider:SetPrecision(1)
        barHeightSlider:AdjustValue(nkUISetup.modules.lowerBar.barHeight)

        barWidthSlider = _settings.slider (name .. ".barWidthSlider", frame, "Bar width <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.lowerBar.barWidth = newValue
            _internal.lowerBarRedraw()
        end)
        
        barWidthSlider:SetPoint("TOPLEFT", barHeightSlider, "TOPRIGHT", 30, 0)
        barWidthSlider:SetRange(100, 400)
        barWidthSlider:SetMidValue(250)
        barWidthSlider:SetPrecision(1)
        barWidthSlider:AdjustValue(nkUISetup.modules.lowerBar.barWidth)
    end

    return frame

end

