local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internalFunc
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabCastBar (name, parent, unitType, thisSettings)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local widthSlider, heightSlider, textFontSize, timerFontSize    
    local comboHeader, fontSizeHeader, sizeHeader
    local introText

    function frame:build()

        sizeHeader = _settings.header ( name .. ".sizeHeader", frame, "Castbar size")
        sizeHeader:SetPoint("TOPLEFT", frame, "TOPLEFT" , 0, 5)

        widthSlider = _settings.slider (name .. ".widthSlider", frame, "Width <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.width = newValue
            _internal.uiFrameRedraw(unitType)
        end)

        widthSlider:SetPoint("TOPLEFT", sizeHeader, "BOTTOMLEFT", 0, 15)
        widthSlider:SetRange(100, 400)
        widthSlider:SetMidValue(250)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(thisSettings.width)
        
        heightSlider = _settings.slider (name .. ".heightSlider", frame, "Height <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.height = newValue
            _internal.uiFrameRedraw(unitType)
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "TOPRIGHT", 30, 0)
        heightSlider:SetRange(10, 100)
        heightSlider:SetMidValue(55)
        heightSlider:SetPrecision(1)
        heightSlider:AdjustValue(thisSettings.height)

        -- font sizes

        fontSizeHeader = _settings.header ( name .. ".fontSizeHeader", frame, "Text size")
        fontSizeHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT" , 0, 15)

        textFontSize = _settings.slider (name .. ".textFontSize", frame, "Spellname <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.text = newValue
            _internal.uiFrameRedraw(unitType)
        end)

        textFontSize:SetPoint("TOPLEFT", fontSizeHeader, "BOTTOMLEFT", 0, 10)
        textFontSize:SetRange(10, 40)
        textFontSize:SetMidValue(25)
        textFontSize:SetPrecision(1)
        textFontSize:AdjustValue(thisSettings.fontSizes.text)
        
        timerFontSize = _settings.slider (name .. ".timerFontSize", frame, "Timer <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.timer = newValue
            _internal.uiFrameRedraw(unitType)
        end)

        timerFontSize:SetPoint("TOPLEFT", textFontSize, "TOPRIGHT", 30, 0)
        timerFontSize:SetRange(10, 40)
        timerFontSize:SetMidValue(25)
        timerFontSize:SetPrecision(1)
        timerFontSize:AdjustValue(thisSettings.fontSizes.timer)
    end

    return frame

end