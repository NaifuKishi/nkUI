local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabCastBar (name, parent, unitType, thisSettings)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local widthSlider, heightSlider, textFontSize, timerFontSize    
    local comboHeader, fontSizeHeader
    local introText

    function frame:build()

        introText = EnKai.uiCreateFrame("nkText", name .. ".introText", frame)
        introText:SetPoint("TOPLEFT", frame, "TOPLEFT" , 0, 5)
        introText:SetFontSize(14)
        introText:SetText(stringFormat("This section allows you the set up the <b><font color='#3399FF'>%s</font></b>", unitType), true)
        introText:SetTextFont(addonInfo.id, "Montserrat")

        widthSlider = _settings.slider (name .. ".widthSlider", frame, "Width <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.width = newValue
        end)

        widthSlider:SetPoint("TOPLEFT", introText, "BOTTOMLEFT", 0, 25)
        widthSlider:SetRange(0, 400)
        widthSlider:SetMidValue(20)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(thisSettings.width)
        
        heightSlider = _settings.slider (name .. ".heightSlider", frame, "Height <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.height = newValue
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "TOPRIGHT", 30, 0)
        heightSlider:SetRange(0, 100)
        heightSlider:SetMidValue(50)
        heightSlider:SetPrecision(1)
        heightSlider:AdjustValue(thisSettings.height)

        -- font sizes

        fontSizeHeader = EnKai.uiCreateFrame("nkText", name .. ".fontSizeHeader", frame)
        fontSizeHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT" , 0, 10)
        fontSizeHeader:SetFontSize(14)
        fontSizeHeader:SetText("Font sizes")
        fontSizeHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        textFontSize = _settings.slider (name .. ".textFontSize", frame, "Text <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.text = newValue
        end)

        textFontSize:SetPoint("TOPLEFT", fontSizeHeader, "BOTTOMLEFT", 0, 10)
        textFontSize:SetRange(0, 400)
        textFontSize:SetMidValue(20)
        textFontSize:SetPrecision(1)
        textFontSize:AdjustValue(thisSettings.fontSizes.text)
        
        timerFontSize = _settings.slider (name .. ".timerFontSize", frame, "Timer <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.timer = newValue
        end)

        timerFontSize:SetPoint("TOPLEFT", textFontSize, "TOPRIGHT", 30, 0)
        timerFontSize:SetRange(0, 400)
        timerFontSize:SetMidValue(20)
        timerFontSize:SetPrecision(1)
        timerFontSize:AdjustValue(thisSettings.fontSizes.timer)
    end

    return frame

end