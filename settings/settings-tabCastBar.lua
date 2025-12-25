local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI     = privateVars.settingsUI

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabCastBar (name, parent, unitType, thisSettings)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local widthSlider, heightSlider, textFontSize, timerFontSize    
    local comboHeader, fontSizeHeader, sizeHeader
    local introText

    function frame:build()

        sizeHeader = settingsUI.header ( name .. ".sizeHeader", frame, "Castbar size")
        sizeHeader:SetPoint("TOPLEFT", frame, "TOPLEFT" , 0, 5)

        widthSlider = settingsUI.slider (name .. ".widthSlider", frame, "Width <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.width = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        widthSlider:SetPoint("TOPLEFT", sizeHeader, "BOTTOMLEFT", 0, 15)
        widthSlider:SetRange(100, 400)
        widthSlider:SetMidValue(250)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(thisSettings.width)
        
        heightSlider = settingsUI.slider (name .. ".heightSlider", frame, "Height <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.height = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "TOPRIGHT", 30, 0)
        heightSlider:SetRange(10, 100)
        heightSlider:SetMidValue(55)
        heightSlider:SetPrecision(1)
        heightSlider:AdjustValue(thisSettings.height)

        -- font sizes

        fontSizeHeader = settingsUI.header ( name .. ".fontSizeHeader", frame, "Text size")
        fontSizeHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT" , 0, 15)

        textFontSize = settingsUI.slider (name .. ".textFontSize", frame, "Spellname <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.text = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        textFontSize:SetPoint("TOPLEFT", fontSizeHeader, "BOTTOMLEFT", 0, 10)
        textFontSize:SetRange(10, 40)
        textFontSize:SetMidValue(25)
        textFontSize:SetPrecision(1)
        textFontSize:AdjustValue(thisSettings.fontSizes.text)
        
        timerFontSize = settingsUI.slider (name .. ".timerFontSize", frame, "Timer <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.timer = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        timerFontSize:SetPoint("TOPLEFT", textFontSize, "TOPRIGHT", 30, 0)
        timerFontSize:SetRange(10, 40)
        timerFontSize:SetMidValue(25)
        timerFontSize:SetPrecision(1)
        timerFontSize:AdjustValue(thisSettings.fontSizes.timer)
    end

    return frame

end