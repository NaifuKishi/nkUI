local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internalFunc
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------



function _settings.uiConfigTabBuffBar (name, parent)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local activateCheckBox, widthSlider, heightSlider, timerFontSizeSlider, stackFontSizeSlider, labelFontSizeSlider
    local sizeHeader, fontHeader

    function frame:build()

        activateCheckbox = _settings.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.buffBar.activate = newValue

            if newValue then
                _internal.buffBar.loadAllBuffs()
            else
                _internal.buffBar.clearAllBuffs() 
            end

            if widthSlider then widthSlider:SetActive(newValue) end
            --if heightSlider then heightSlider:SetActive(newValue) end
            if timerFontSizeSlider then timerFontSizeSlider:SetActive(newValue) end
            if stackFontSizeSlider then stackFontSizeSlider:SetActive(newValue) end
            --if labelFontSizeSlider then labelFontSizeSlider:SetActive(newValue) end
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.buffBar.activate, true)

        local moduleActive = nkUISetup.modules.buffBar.activate

        sizeHeader = EnKai.uiCreateFrame("nkText", name .. ".sizeHeader", frame)
        sizeHeader:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT" , 0, 15)
        sizeHeader:SetFontSize(14)
        sizeHeader:SetText("Size setup")
        sizeHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        widthSlider = _settings.slider (name .. ".widthSlider", frame, "Buff size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.width = newValue
            nkUISetup.modules.buffBar.buffs.height = newValue

            _internal.buffBar.Redraw()
        end)

        widthSlider:SetPoint("TOPLEFT", sizeHeader, "BOTTOMLEFT", 0, 15)
        widthSlider:SetRange(10, 100)
        widthSlider:SetMidValue(55)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.width)
        
        --[[heightSlider = _settings.slider (name .. ".heightSlider", frame, "Height <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.height = newValue
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "TOPRIGHT", 30, 0)
        heightSlider:SetRange(0, 100)
        heightSlider:SetMidValue(50)
        heightSlider:SetPrecision(1)
        heightSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.height)]]

        fontHeader = EnKai.uiCreateFrame("nkText", name .. ".fontHeader", frame)
        fontHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT" , 0, 15)
        fontHeader:SetFontSize(14)
        fontHeader:SetText("Combo point setup")
        fontHeader:SetTextFont(addonInfo.id, "MontserratSemiBold")

        timerFontSizeSlider = _settings.slider (name .. ".timerFontSizeSlider", frame, "Timer size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.timer = newValue
            _internal.buffBar.Redraw()
        end)
        
        timerFontSizeSlider:SetPoint("TOPLEFT", fontHeader, "BOTTOMLEFT", 0, 15)
        timerFontSizeSlider:SetRange(10, 40)
        timerFontSizeSlider:SetMidValue(25)
        timerFontSizeSlider:SetPrecision(1)
        timerFontSizeSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.timer)
        
        stackFontSizeSlider = _settings.slider (name .. ".stackFontSizeSlider", frame, "Stack size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.stack = newValue
            _internal.buffBar.Redraw()
        end)
       
        stackFontSizeSlider:SetPoint("TOPLEFT", timerFontSizeSlider, "TOPRIGHT", 30, 0)
        stackFontSizeSlider:SetRange(10, 40)
        stackFontSizeSlider:SetMidValue(25)
        stackFontSizeSlider:SetPrecision(1)
        stackFontSizeSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.stack)
        
        --[[labelFontSizeSlider = _settings.slider (name .. ".labelFontSizeSlider", frame, "label font size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.label = newValue
        end)

        labelFontSizeSlider:SetPoint("TOPLEFT", timerFontSizeSlider, "BOTTOMLEFT", 0, 5)
        labelFontSizeSlider:SetRange(0, 40)
        labelFontSizeSlider:SetMidValue(20)
        labelFontSizeSlider:SetPrecision(1)
        labelFontSizeSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.label)]]
        
    end

    return frame

end
