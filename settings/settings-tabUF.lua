local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabUF (name, parent, unitType, thisSettings)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local widthSlider, heightSlider, reverseCheckbox, nameFontSize, healthFontSize, energyFontSize, planarFontSize, nameMargins, healthMargins, energyMargins, planarMargins, combatIconMargins, roleIconMargins, tierIconMargins, combatIconSize, roleIconSize, tierIconSize, buffWidth, buffHeight, timerFontSize, stackFontSize, labelFontSize
    local fontSizesHeader, marginsHeader, iconSizeHeader, iconSizeHeader
    local introText

    function frame:build()

        introText = EnKai.uiCreateFrame("nkText", name .. ".introText", frame)
        introText:SetPoint("TOPLEFT", frame, "TOPLEFT" , 0, 5)
        introText:SetFontSize(14)
        introText:SetText(stringFormat("This section allows you the set up the <b><font color='#3399FF'>%s</font></b> unit frame. All settings are only for that unit frame.", unitType), true)
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

        reverseCheckbox = _settings.checkbox(name .. ".reverseCheckbox", frame, "Reverse display", true, function(newValue)        
            thisSettings.reverse = newValue            
        end)

        reverseCheckbox:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, 5)
        reverseCheckbox:SetChecked(thisSettings.reverse)

        -- font sizes
        
        fontSizesHeader = EnKai.uiCreateFrame("nkText", name .. ".fontSizesHeader", frame)
        fontSizesHeader:SetPoint("TOPLEFT", reverseCheckbox, "BOTTOMLEFT" , 0, 10)
        fontSizesHeader:SetFontSize(14)
        fontSizesHeader:SetText("Font sizes")
        fontSizesHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")


        nameFontSize = _settings.slider (name .. ".nameFontSize", frame, "Name font size <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.name = newValue
        end)

        nameFontSize:SetPoint("TOPLEFT", fontSizesHeader, "BOTTOMLEFT", 0, 10)
        nameFontSize:SetRange(0, 40)
        nameFontSize:SetMidValue(20)
        nameFontSize:SetPrecision(1)
        nameFontSize:AdjustValue(thisSettings.fontSizes.name)

        healthFontSize = _settings.slider (name .. ".healthFontSize", frame, "Health font size <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.health = newValue
        end)

        healthFontSize:SetPoint("TOPLEFT", nameFontSize, "TOPRIGHT", 30, 0)
        healthFontSize:SetRange(0, 40)
        healthFontSize:SetMidValue(20)
        healthFontSize:SetPrecision(1)
        healthFontSize:AdjustValue(thisSettings.fontSizes.health)

        energyFontSize = _settings.slider (name .. ".energyFontSize", frame, "Energy font size <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.energy = newValue
        end)

        energyFontSize:SetPoint("TOPLEFT", nameFontSize, "BOTTOMLEFT", 0, 5)
        energyFontSize:SetRange(0, 40)
        energyFontSize:SetMidValue(20)
        energyFontSize:SetPrecision(1)
        energyFontSize:AdjustValue(thisSettings.fontSizes.energy)

        planarFontSize = _settings.slider (name .. ".planarFontSize", frame, "Planar font size <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.planar = newValue
        end)

        planarFontSize:SetPoint("TOPLEFT", energyFontSize, "TOPRIGHT", 30, 0)
        planarFontSize:SetRange(0, 40)
        planarFontSize:SetMidValue(20)
        planarFontSize:SetPrecision(1)
        planarFontSize:AdjustValue(thisSettings.fontSizes.planar)

        -- margins

        marginsHeader = EnKai.uiCreateFrame("nkText", name .. ".marginsHeader", frame)
        marginsHeader:SetPoint("TOPLEFT", energyFontSize, "BOTTOMLEFT" , 0, 10)
        marginsHeader:SetFontSize(14)
        marginsHeader:SetText("Offsets")
        marginsHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        nameMargins = _settings.slider (name .. ".nameMargins", frame, "Name offset <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.margins.name = newValue
        end)

        nameMargins:SetPoint("TOPLEFT", marginsHeader, "BOTTOMLEFT", 0, 10)
        nameMargins:SetRange(-40, 40)
        nameMargins:SetMidValue(0)
        nameMargins:SetPrecision(1)
        nameMargins:AdjustValue(thisSettings.margins.name)

        healthMargins = _settings.slider (name .. ".healthMargins", frame, "Health offset <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.margins.health = newValue
        end)

        healthMargins:SetPoint("TOPLEFT", nameMargins, "TOPRIGHT", 30, 0)
        healthMargins:SetRange(-40, 40)
        healthMargins:SetMidValue(0)
        healthMargins:SetPrecision(1)
        healthMargins:AdjustValue(thisSettings.margins.health)

        energyMargins = _settings.slider (name .. ".energyMargins", frame, "Energy offset <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.margins.energy = newValue
        end)

        energyMargins:SetPoint("TOPLEFT", nameMargins, "BOTTOMLEFT", 0, 5)
        energyMargins:SetRange(-40, 40)
        energyMargins:SetMidValue(0)
        energyMargins:SetPrecision(1)
        energyMargins:AdjustValue(thisSettings.margins.energy)

        planarMargins = _settings.slider (name .. ".planarMargins", frame, "Planar offset <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.margins.planar = newValue
        end)

        planarMargins:SetPoint("TOPLEFT", energyMargins, "TOPRIGHT", 30, 0)
        planarMargins:SetRange(-40, 40)
        planarMargins:SetMidValue(0)
        planarMargins:SetPrecision(1)
        planarMargins:AdjustValue(thisSettings.margins.planar)        

        combatIconMargins = _settings.slider (name .. ".combatIconMargins", frame, "Combat Icon offset <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.margins.combatIcon = newValue
        end)        

        combatIconMargins:SetPoint("TOPLEFT", energyMargins, "BOTTOMLEFT", 0, 15)
        combatIconMargins:SetRange(-40, 40)
        combatIconMargins:SetMidValue(0)
        combatIconMargins:SetPrecision(1)
        combatIconMargins:AdjustValue(thisSettings.margins.combatIcon)

        roleIconMargins = _settings.slider (name .. ".roleIconMargins", frame, "Role icon offset <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.margins.roleIcon = newValue
        end)

        roleIconMargins:SetPoint("TOPLEFT", combatIconMargins, "BOTTOMLEFT", 0, 5)
        roleIconMargins:SetRange(-40, 40)
        roleIconMargins:SetMidValue(0)
        roleIconMargins:SetPrecision(1)
        roleIconMargins:AdjustValue(thisSettings.margins.roleIcon)

        tierIconMargins = _settings.slider (name .. ".tierIconMargins", frame, "Tier icon offset <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.margins.tierIcon = newValue
        end)

        tierIconMargins:SetPoint("TOPLEFT", combatIconMargins, "TOPRIGHT", 30, 0)
        tierIconMargins:SetRange(-40, 40)
        tierIconMargins:SetMidValue(0)
        tierIconMargins:SetPrecision(1)
        tierIconMargins:AdjustValue(thisSettings.margins.tierIcon)

        -- icon sizes

        iconSizeHeader = EnKai.uiCreateFrame("nkText", name .. ".marginiconSizeHeadersHeader", frame)
        iconSizeHeader:SetPoint("TOPLEFT", roleIconMargins, "BOTTOMLEFT" , 0, 10)
        iconSizeHeader:SetFontSize(14)
        iconSizeHeader:SetText("Icon sizes")
        iconSizeHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        combatIconSize = _settings.slider (name .. ".combatIconSize", frame, "Combat icon size <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.iconSizes.combat = newValue
        end)

        combatIconSize:SetPoint("TOPLEFT", iconSizeHeader, "BOTTOMLEFT", 0, 10)
        combatIconSize:SetRange(0, 40)
        combatIconSize:SetMidValue(20)
        combatIconSize:SetPrecision(1)
        combatIconSize:AdjustValue(thisSettings.iconSizes.combat)

        roleIconSize = _settings.slider (name .. ".roleIconSize", frame, "Role icon size <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.iconSizes.role = newValue
        end)

        roleIconSize:SetPoint("TOPLEFT", combatIconSize, "BOTTOMRIGHT", 30, 0)
        roleIconSize:SetRange(0, 40)
        roleIconSize:SetMidValue(20)
        roleIconSize:SetPrecision(1)
        roleIconSize:AdjustValue(thisSettings.iconSizes.role)

        tierIconSize = _settings.slider (name .. ".tierIconSize", frame, "Tier icon size <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.iconSizes.tier = newValue
        end)

        tierIconSize:SetPoint("TOPLEFT", combatIconSize, "BOTTOMLEFT", 0, 5)
        tierIconSize:SetRange(0, 40)
        tierIconSize:SetMidValue(20)
        tierIconSize:SetPrecision(1)
        tierIconSize:AdjustValue(thisSettings.iconSizes.tier)

        if  thisSettings.buffs ~= nil then

            -- buff sizes

            iconSizeHeader = EnKai.uiCreateFrame("nkText", name .. ".iconSizeHeader", frame)
            iconSizeHeader:SetPoint("TOPLEFT", tierIconSize, "BOTTOMLEFT" , 0, 10)
            iconSizeHeader:SetFontSize(14)
            iconSizeHeader:SetText("Buff display setup")
            iconSizeHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

            buffWidth = _settings.slider (name .. ".buffWidth", frame, "Buff icon width <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.buffs.width = newValue
            end)

            buffWidth:SetPoint("TOPLEFT", iconSizeHeader, "BOTTOMLEFT", 0, 10)
            buffWidth:SetRange(0, 60)
            buffWidth:SetMidValue(30)
            buffWidth:SetPrecision(1)
            buffWidth:AdjustValue(thisSettings.buffs.width)

            buffHeight = _settings.slider (name .. ".buffHeight", frame, "Buff icon height <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.buffs.height = newValue
            end)

            buffHeight:SetPoint("TOPLEFT", buffWidth, "TOPRIGHT", 30, 0)
            buffHeight:SetRange(0, 60)
            buffHeight:SetMidValue(30)
            buffHeight:SetPrecision(1)
            buffHeight:AdjustValue(thisSettings.buffs.height)

            timerFontSize = _settings.slider (name .. ".timerFontSize", frame, "Timer font size <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.buffs.timer = newValue
            end)

            timerFontSize:SetPoint("TOPLEFT", buffWidth, "BOTTOMLEFT", 0, 20)
            timerFontSize:SetRange(0, 30)
            timerFontSize:SetMidValue(15)
            timerFontSize:SetPrecision(1)
            timerFontSize:AdjustValue(thisSettings.buffs.timer)

            stackFontSize = _settings.slider (name .. ".stackFontSize", frame, "Stack font size <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.buffs.stack = newValue
            end)

            stackFontSize:SetPoint("TOPLEFT", timerFontSize, "TOPRIGHT", 30, 0)
            stackFontSize:SetRange(0, 30)
            stackFontSize:SetMidValue(15)
            stackFontSize:SetPrecision(1)
            stackFontSize:AdjustValue(thisSettings.buffs.stack)

            labelFontSize = _settings.slider (name .. ".labelFontSize", frame, "Label font size <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.buffs.label = newValue
            end)

            labelFontSize:SetPoint("TOPLEFT", timerFontSize, "BOTTOMLEFT", 0, 5)
            labelFontSize:SetRange(0, 30)
            labelFontSize:SetMidValue(15)
            labelFontSize:SetPrecision(1)
            labelFontSize:AdjustValue(thisSettings.buffs.label)
        end

    end

    return frame

end