local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------



function _settings.uiConfigTabBuffBar (name, parent)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local activateCheckBox, widthSlider, heightSlider, timerFontSizeSlider, stackFontSizeSlider, labelFontSizeSlider

    function frame:build()

        activateCheckbox = _settings.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.buffBar.activate = newValue

            if newValue then
                _internal.buffBar.loadAllBuffs()
            else
                _internal.buffBar.clearAllBuffs() 
            end

            if widthSlider then widthSlider:SetActive(newValue) end
            if heightSlider then heightSlider:SetActive(newValue) end
            if timerFontSizeSlider then timerFontSizeSlider:SetActive(newValue) end
            if stackFontSizeSlider then stackFontSizeSlider:SetActive(newValue) end
            if labelFontSizeSlider then labelFontSizeSlider:SetActive(newValue) end
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.buffBar.activate)

        local moduleActive = nkUISetup.modules.buffBar.activate

        widthSlider = _settings.slider (name .. ".widthSlider", frame, "Width %d", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.width = newValue
        end)

        widthSlider:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, 15)
        widthSlider:SetRange(0, 100)
        widthSlider:SetMidValue(50)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.width)
        
        heightSlider = _settings.slider (name .. ".heightSlider", frame, "Height %d", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.height = newValue
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, 5)
        heightSlider:SetRange(0, 100)
        heightSlider:SetMidValue(50)
        heightSlider:SetPrecision(1)
        heightSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.height)

        timerFontSizeSlider = _settings.slider (name .. ".timerFontSizeSlider", frame, "Timer font size %d", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.timer = newValue
        end)
        
        timerFontSizeSlider:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", 0, 5)
        timerFontSizeSlider:SetRange(0, 40)
        timerFontSizeSlider:SetMidValue(20)
        timerFontSizeSlider:SetPrecision(1)
        timerFontSizeSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.timer)
        
        stackFontSizeSlider = _settings.slider (name .. ".stackFontSizeSlider", frame, "Stack font size %d", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.stack = newValue
        end)
       
        stackFontSizeSlider:SetPoint("TOPLEFT", timerFontSizeSlider, "BOTTOMLEFT", 0, 5)
        stackFontSizeSlider:SetRange(0, 40)
        stackFontSizeSlider:SetMidValue(20)
        stackFontSizeSlider:SetPrecision(1)
        stackFontSizeSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.stack)
        
        labelFontSizeSlider = _settings.slider (name .. ".labelFontSizeSlider", frame, "Timer font size %d", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.label = newValue
        end)

        labelFontSizeSlider:SetPoint("TOPLEFT", stackFontSizeSlider, "BOTTOMLEFT", 0, 5)
        labelFontSizeSlider:SetRange(0, 40)
        labelFontSizeSlider:SetMidValue(20)
        labelFontSizeSlider:SetPrecision(1)
        labelFontSizeSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.label)
        
    end

    return frame

end
