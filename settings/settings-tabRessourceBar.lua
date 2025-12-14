local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internalFunc
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabRessourceBar (name, parent, thisSettings)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local widthSlider, heightSlider, comboWidthSlider, comboHeightSlider, chargeWidthSlider, chargeHeightSlider, marginRessourceSlider, chargeFontSize, ressourceFontSize    
    local sizeHeader, comboHeader, chargeHeader, marginHeader, fontSizeHeader
    local introText

    function frame:build()

        sizeHeader = _settings.header ( name .. ".sizeHeader", frame, "Ressource bar size")
        sizeHeader:SetPoint("TOPLEFT", frame, "TOPLEFT" , 0, 5)

        widthSlider = _settings.slider (name .. ".widthSlider", frame, "Width <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.width = newValue
            _internal.uiFrameRedraw("player.ressourcebar")
        end)

        widthSlider:SetPoint("TOPLEFT", sizeHeader, "BOTTOMLEFT", 0, 10)
        widthSlider:SetRange(100, 400)
        widthSlider:SetMidValue(250)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(thisSettings.width)
        
        heightSlider = _settings.slider (name .. ".heightSlider", frame, "Height <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.height = newValue
            _internal.uiFrameRedraw("player.ressourcebar")
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "TOPRIGHT", 30, 0)
        heightSlider:SetRange(10, 50)
        heightSlider:SetMidValue(30)
        heightSlider:SetPrecision(1)
        heightSlider:AdjustValue(thisSettings.height)

        -- combo display
        
        comboHeader = _settings.header ( name .. ".comboHeader", frame, "Combo point size")
        comboHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT" , 0, 15)

        comboWidthSlider = _settings.slider (name .. ".comboWidthSlider", frame, "Width <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.combo.width = newValue
             _internal.uiFrameRedraw("player.ressourcebar")
        end)

        comboWidthSlider:SetPoint("TOPLEFT", comboHeader, "BOTTOMLEFT", 0, 15)
        comboWidthSlider:SetRange(10, 30)
        comboWidthSlider:SetMidValue(20)
        comboWidthSlider:SetPrecision(1)
        comboWidthSlider:AdjustValue(thisSettings.combo.width)
        
        comboHeightSlider = _settings.slider (name .. ".comboHeightSlider", frame, "Height <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.combo.height = newValue
             _internal.uiFrameRedraw("player.ressourcebar")
        end)

        comboHeightSlider:SetPoint("TOPLEFT", comboWidthSlider, "TOPRIGHT", 30, 0)
        comboHeightSlider:SetRange(10, 30)
        comboHeightSlider:SetMidValue(20)
        comboHeightSlider:SetPrecision(1)
        comboHeightSlider:AdjustValue(thisSettings.combo.height)

        -- charge display
        
        chargeHeader = _settings.header ( name .. ".chargeHeader", frame, "Charge display size")
        chargeHeader:SetPoint("TOPLEFT", comboWidthSlider, "BOTTOMLEFT" , 0, 15)
        
        chargeWidthSlider = _settings.slider (name .. ".chargeWidthSlider", frame, "Width <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.charge.width = newValue
             _internal.uiFrameRedraw("player.ressourcebar")
        end)

        chargeWidthSlider:SetPoint("TOPLEFT", chargeHeader, "BOTTOMLEFT", 0, 15)
        chargeWidthSlider:SetRange(100, 400)
        chargeWidthSlider:SetMidValue(250)
        chargeWidthSlider:SetPrecision(1)
        chargeWidthSlider:AdjustValue(thisSettings.charge.width)
        
        chargeHeightSlider = _settings.slider (name .. ".chargeHeightSlider", frame, "Height <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.charge.height = newValue
            _internal.uiFrameRedraw("player.ressourcebar")
        end)

        chargeHeightSlider:SetPoint("TOPLEFT", chargeWidthSlider, "TOPRIGHT", 30, 0)
        chargeHeightSlider:SetRange(10, 30)
        chargeHeightSlider:SetMidValue(20)
        chargeHeightSlider:SetPrecision(1)
        chargeHeightSlider:AdjustValue(thisSettings.charge.height)

        -- offset display
        --[[
        marginHeader = EnKai.uiCreateFrame("nkText", name .. ".marginHeader", frame)
        marginHeader:SetPoint("TOPLEFT", chargeWidthSlider, "BOTTOMLEFT" , 0, 10)
        marginHeader:SetFontSize(14)
        marginHeader:SetText("Offset")
        marginHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        marginRessourceSlider = _settings.slider (name .. ".marginRessourceSlider", frame, "Ressource offset <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.margins.ressource = newValue
        end)
        

        marginRessourceSlider:SetPoint("TOPLEFT", marginHeader, "BOTTOMLEFT", 0, 10)
        marginRessourceSlider:SetRange(0, 400)
        marginRessourceSlider:SetMidValue(20)
        marginRessourceSlider:SetPrecision(1)
        marginRessourceSlider:AdjustValue(thisSettings.margins.ressource)
]]
        -- font sizes

        fontSizeHeader = _settings.header ( name .. ".fontSizeHeader", frame, "Text sizes")
        fontSizeHeader:SetPoint("TOPLEFT", chargeWidthSlider, "BOTTOMLEFT" , 0, 15)

        chargeFontSize = _settings.slider (name .. ".chargeFontSize", frame, "Charge <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.charge = newValue
            _internal.uiFrameRedraw("player.ressourcebar")
        end)

        chargeFontSize:SetPoint("TOPLEFT", fontSizeHeader, "BOTTOMLEFT", 0, 10)
        chargeFontSize:SetRange(10, 30)
        chargeFontSize:SetMidValue(20)
        chargeFontSize:SetPrecision(1)
        chargeFontSize:AdjustValue(thisSettings.fontSizes.charge)
        
        ressourceFontSize = _settings.slider (name .. ".ressourceFontSize", frame, "Ressource <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.ressource = newValue
            _internal.uiFrameRedraw("player.ressourcebar")
        end)

        ressourceFontSize:SetPoint("TOPLEFT", chargeFontSize, "TOPRIGHT", 30, 0)
        ressourceFontSize:SetRange(10, 30)
        ressourceFontSize:SetMidValue(20)
        ressourceFontSize:SetPrecision(1)
        ressourceFontSize:AdjustValue(thisSettings.fontSizes.ressource)
    end

    return frame

end