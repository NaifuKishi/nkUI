local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabRessourceBar (name, parent, thisSettings)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local widthSlider, heightSlider, comboWidthSlider, comboHeightSlider, chargeWidthSlider, chargeHeightSlider, marginRessourceSlider, chargeFontSize, ressourceFontSize    
    local comboHeader, chargeHeader, marginHeader, fontSizeHeader
    local introText

    function frame:build()

        introText = EnKai.uiCreateFrame("nkText", name .. ".introText", frame)
        introText:SetPoint("TOPLEFT", frame, "TOPLEFT" , 0, 5)
        introText:SetFontSize(14)
        introText:SetText("This section allows you the set up the <b><font color='#3399FF'>RESSOURCE BAR</font></b>", true)
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

        -- combo display
        
        comboHeader = EnKai.uiCreateFrame("nkText", name .. ".comboHeader", frame)
        comboHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT" , 0, 10)
        comboHeader:SetFontSize(14)
        comboHeader:SetText("Combo point setup")
        comboHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        comboWidthSlider = _settings.slider (name .. ".comboWidthSlider", frame, "Width <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.combo.width = newValue
        end)

        comboWidthSlider:SetPoint("TOPLEFT", comboHeader, "BOTTOMLEFT", 0, 10)
        comboWidthSlider:SetRange(0, 400)
        comboWidthSlider:SetMidValue(20)
        comboWidthSlider:SetPrecision(1)
        comboWidthSlider:AdjustValue(thisSettings.combo.width)
        
        comboHeightSlider = _settings.slider (name .. ".comboHeightSlider", frame, "Height <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.combo.height = newValue
        end)

        comboHeightSlider:SetPoint("TOPLEFT", comboWidthSlider, "TOPRIGHT", 30, 0)
        comboHeightSlider:SetRange(0, 100)
        comboHeightSlider:SetMidValue(50)
        comboHeightSlider:SetPrecision(1)
        comboHeightSlider:AdjustValue(thisSettings.combo.height)

        -- charge display
        
        chargeHeader = EnKai.uiCreateFrame("nkText", name .. ".chargeHeader", frame)
        chargeHeader:SetPoint("TOPLEFT", comboWidthSlider, "BOTTOMLEFT" , 0, 10)
        chargeHeader:SetFontSize(14)
        chargeHeader:SetText("Charge display setup")
        chargeHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        chargeWidthSlider = _settings.slider (name .. ".chargeWidthSlider", frame, "Width <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.charge.width = newValue
        end)

        chargeWidthSlider:SetPoint("TOPLEFT", chargeHeader, "BOTTOMLEFT", 0, 10)
        chargeWidthSlider:SetRange(0, 400)
        chargeWidthSlider:SetMidValue(20)
        chargeWidthSlider:SetPrecision(1)
        chargeWidthSlider:AdjustValue(thisSettings.charge.width)
        
        chargeHeightSlider = _settings.slider (name .. ".chargeHeightSlider", frame, "Height <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.charge.height = newValue
        end)

        chargeHeightSlider:SetPoint("TOPLEFT", chargeWidthSlider, "TOPRIGHT", 30, 0)
        chargeHeightSlider:SetRange(0, 100)
        chargeHeightSlider:SetMidValue(50)
        chargeHeightSlider:SetPrecision(1)
        chargeHeightSlider:AdjustValue(thisSettings.charge.height)

        -- offset display
        
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

        -- font sizes

        fontSizeHeader = EnKai.uiCreateFrame("nkText", name .. ".fontSizeHeader", frame)
        fontSizeHeader:SetPoint("TOPLEFT", marginRessourceSlider, "BOTTOMLEFT" , 0, 10)
        fontSizeHeader:SetFontSize(14)
        fontSizeHeader:SetText("Font sizes")
        fontSizeHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        chargeFontSize = _settings.slider (name .. ".chargeFontSize", frame, "Charge <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.charge = newValue
        end)

        chargeFontSize:SetPoint("TOPLEFT", fontSizeHeader, "BOTTOMLEFT", 0, 10)
        chargeFontSize:SetRange(0, 400)
        chargeFontSize:SetMidValue(20)
        chargeFontSize:SetPrecision(1)
        chargeFontSize:AdjustValue(thisSettings.fontSizes.charge)
        
        ressourceFontSize = _settings.slider (name .. ".ressourceFontSize", frame, "Ressource <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.ressource = newValue
        end)

        ressourceFontSize:SetPoint("TOPLEFT", chargeFontSize, "TOPRIGHT", 30, 0)
        ressourceFontSize:SetRange(0, 400)
        ressourceFontSize:SetMidValue(20)
        ressourceFontSize:SetPrecision(1)
        ressourceFontSize:AdjustValue(thisSettings.fontSizes.ressource)
    end

    return frame

end