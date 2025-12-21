local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local _settings     = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabUF (name, parent, unitType, thisSettings)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local widthSlider, heightSlider, reverseCheckbox, nameFontSize, healthFontSize, energyFontSize, planarFontSize, nameMargins, healthMargins, energyMargins, planarMargins, combatIconMargins, roleIconMargins, tierIconMargins, combatIconSize, roleIconSize, tierIconSize, buffWidth, buffHeight, timerFontSize, stackFontSize, labelFontSize, levelFontSize
    local sizeHeader, fontSizesHeader, marginsHeader, iconSizeHeader, buffSizeHeader
    local introText

    function frame:build()

        sizeHeader = _settings.header ( name .. ".sizeHeader", frame, "Unit frame size")
        sizeHeader:SetPoint("TOPLEFT", frame, "TOPLEFT" , 0, 5)

        widthSlider = _settings.slider (name .. ".widthSlider", frame, "Width <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.width = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        widthSlider:SetPoint("TOPLEFT", sizeHeader, "BOTTOMLEFT", 0, 15)
        widthSlider:SetRange(100, 400)
        widthSlider:SetMidValue(250)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(thisSettings.width)
        
        heightSlider = _settings.slider (name .. ".heightSlider", frame, "Height <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.height = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "TOPRIGHT", 30, 0)
        heightSlider:SetRange(10, 50)
        heightSlider:SetMidValue(30)
        heightSlider:SetPrecision(1)
        heightSlider:AdjustValue(thisSettings.height)

        if unitType ~= "raid" and unitType ~= "group" then
            reverseCheckbox = _settings.checkbox(name .. ".reverseCheckbox", frame, "Reverse display", true, function(newValue)        
                thisSettings.reverse = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            reverseCheckbox:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, 5)
            reverseCheckbox:SetChecked(thisSettings.reverse, true)
        end

        -- font sizes
        
        fontSizesHeader = _settings.header ( name .. ".fontSizesHeader", frame, "Text sizes")

        if unitType ~= "raid" and unitType ~= "group" then
            fontSizesHeader:SetPoint("TOPLEFT", reverseCheckbox, "BOTTOMLEFT" , 0, 15)
        else
            fontSizesHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT" , 0, 15)
        end

        nameFontSize = _settings.slider (name .. ".nameFontSize", frame, "Unit name <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.name = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        nameFontSize:SetPoint("TOPLEFT", fontSizesHeader, "BOTTOMLEFT", 0, 10)
        nameFontSize:SetRange(10, 40)
        nameFontSize:SetMidValue(25)
        nameFontSize:SetPrecision(1)
        nameFontSize:AdjustValue(thisSettings.fontSizes.name)

        healthFontSize = _settings.slider (name .. ".healthFontSize", frame, "Health text <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.health = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        healthFontSize:SetPoint("TOPLEFT", nameFontSize, "TOPRIGHT", 30, 0)
        healthFontSize:SetRange(10, 40)
        healthFontSize:SetMidValue(25)
        healthFontSize:SetPrecision(1)
        healthFontSize:AdjustValue(thisSettings.fontSizes.health)

        energyFontSize = _settings.slider (name .. ".energyFontSize", frame, "Energy text <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.energy = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        energyFontSize:SetPoint("TOPLEFT", nameFontSize, "BOTTOMLEFT", 0, 5)
        energyFontSize:SetRange(10, 40)
        energyFontSize:SetMidValue(25)
        energyFontSize:SetPrecision(1)
        energyFontSize:AdjustValue(thisSettings.fontSizes.energy)

        planarFontSize = _settings.slider (name .. ".planarFontSize", frame, "Planar text <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.planar = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        planarFontSize:SetPoint("TOPLEFT", energyFontSize, "TOPRIGHT", 30, 0)
        planarFontSize:SetRange(10, 40)
        planarFontSize:SetMidValue(25)
        planarFontSize:SetPrecision(1)
        planarFontSize:AdjustValue(thisSettings.fontSizes.planar)

        levelFontSize = _settings.slider (name .. ".levelFontSize", frame, "Level text <font color='#3399FF'>%d</font>", true, function (newValue)
            thisSettings.fontSizes.level = newValue
            internalFunc.uiFrameRedraw(unitType)
        end)

        levelFontSize:SetPoint("TOPLEFT", energyFontSize, "BOTTOMLEFT", 0, 5)
        levelFontSize:SetRange(10, 40)
        levelFontSize:SetMidValue(25)
        levelFontSize:SetPrecision(1)
        levelFontSize:AdjustValue(thisSettings.fontSizes.level)

        --[[
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
]]

        -- icon sizes       

        if unitType ~= "player.pet" then

            iconSizeHeader = _settings.header ( name .. ".iconSizeHeader", frame, "Icon sizes")
            iconSizeHeader:SetPoint("TOPLEFT", levelFontSize, "BOTTOMLEFT" , 0, 15)

            roleIconSize = _settings.slider (name .. ".roleIconSize", frame, "Role icon <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.iconSizes.role = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

        
            roleIconSize:SetPoint("TOPLEFT", iconSizeHeader, "BOTTOMLEFT", 0, 15)
            roleIconSize:SetRange(10, 40)
            roleIconSize:SetMidValue(25)
            roleIconSize:SetPrecision(1)
            roleIconSize:AdjustValue(thisSettings.iconSizes.role)            
        end

        if unitType ~= "raid" and unitType ~= "group" and unitType ~= "player.pet" then
            combatIconSize = _settings.slider (name .. ".combatIconSize", frame, "Combat icon <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.iconSizes.combat = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            combatIconSize:SetPoint("TOPLEFT", roleIconSize, "BOTTOMLEFT", 0, 5)
            combatIconSize:SetRange(10, 40)
            combatIconSize:SetMidValue(25)
            combatIconSize:SetPrecision(1)
            combatIconSize:AdjustValue(thisSettings.iconSizes.combat)

            tierIconSize = _settings.slider (name .. ".tierIconSize", frame, "Tier icon <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.iconSizes.tier = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            tierIconSize:SetPoint("TOPLEFT", combatIconSize, "TOPRIGHT", 30, 0)
            tierIconSize:SetRange(10, 40)
            tierIconSize:SetMidValue(25)
            tierIconSize:SetPrecision(1)
            tierIconSize:AdjustValue(thisSettings.iconSizes.tier)
        end

        if  thisSettings.buffs ~= nil then

            -- buff sizes

            buffSizeHeader = _settings.header ( name .. ".buffSizeHeader", frame, "Buff display setup")

            if unitType ~= "raid" and unitType ~= "group" and unitType ~= "player.pet" then
                buffSizeHeader:SetPoint("TOPLEFT", combatIconSize, "BOTTOMLEFT" , 0, 15)
            elseif unitType ~= "player.pet" then
                buffSizeHeader:SetPoint("TOPLEFT", roleIconSize, "BOTTOMLEFT" , 0, 15)
            else
                buffSizeHeader:SetPoint("TOPLEFT", levelFontSize, "BOTTOMLEFT" , 0, 15)
            end

            buffWidth = _settings.slider (name .. ".buffWidth", frame, "Buff icon size <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.buffs.width = newValue
                thisSettings.buffs.height = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            buffWidth:SetPoint("TOPLEFT", buffSizeHeader, "BOTTOMLEFT", 0, 15)
            buffWidth:SetRange(10, 40)
            buffWidth:SetMidValue(25)
            buffWidth:SetPrecision(1)
            buffWidth:AdjustValue(thisSettings.buffs.width)

            --[[buffHeight = _settings.slider (name .. ".buffHeight", frame, "Buff icon height <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.buffs.height = newValue
            end)

            buffHeight:SetPoint("TOPLEFT", buffWidth, "TOPRIGHT", 30, 0)
            buffHeight:SetRange(0, 60)
            buffHeight:SetMidValue(30)
            buffHeight:SetPrecision(1)
            buffHeight:AdjustValue(thisSettings.buffs.height)
            ]]
            timerFontSize = _settings.slider (name .. ".timerFontSize", frame, "Timer size <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.buffs.timer = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            timerFontSize:SetPoint("TOPLEFT", buffWidth, "BOTTOMLEFT", 0, 20)
            timerFontSize:SetRange(10, 30)
            timerFontSize:SetMidValue(20)
            timerFontSize:SetPrecision(1)
            timerFontSize:AdjustValue(thisSettings.buffs.timer)

            stackFontSize = _settings.slider (name .. ".stackFontSize", frame, "Stack size <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.buffs.stack = newValue
                internalFunc.uiFrameRedraw(unitType)
            end)

            stackFontSize:SetPoint("TOPLEFT", timerFontSize, "TOPRIGHT", 30, 0)
            stackFontSize:SetRange(10, 30)
            stackFontSize:SetMidValue(20)
            stackFontSize:SetPrecision(1)
            stackFontSize:AdjustValue(thisSettings.buffs.stack)

            --[[labelFontSize = _settings.slider (name .. ".labelFontSize", frame, "Label size <font color='#3399FF'>%d</font>", true, function (newValue)
                thisSettings.buffs.label = newValue
            end)

            labelFontSize:SetPoint("TOPLEFT", timerFontSize, "BOTTOMLEFT", 0, 5)
            labelFontSize:SetRange(0, 30)
            labelFontSize:SetMidValue(15)
            labelFontSize:SetPrecision(1)
            labelFontSize:AdjustValue(thisSettings.buffs.label)]]
        end

    end

    return frame

end