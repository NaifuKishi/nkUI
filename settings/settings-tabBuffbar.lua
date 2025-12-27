local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI     = privateVars.settingsUI

local stringFormat = string.format

---------- init local variables ---------



function settingsUI.uiConfigTabBuffBar (name, parent)

    local frame = LibEKL.uiCreateFrame("nkFrame", name, parent)
    local activateCheckBox, widthSlider, heightSlider, timerFontSizeSlider, stackFontSizeSlider, labelFontSizeSlider
    local sizeHeader, fontHeader

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.buffBar.activate = newValue

            if newValue then
                internalFunc.buffBar.loadAllBuffs()
            else
                internalFunc.buffBar.clearAllBuffs() 
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

        sizeHeader = settingsUI.header ( name .. ".sizeHeader", frame, "Size setup")
        sizeHeader:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT" , 0, 15)

        widthSlider = settingsUI.slider (name .. ".widthSlider", frame, "Buff size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.width = newValue
            nkUISetup.modules.buffBar.buffs.height = newValue

            internalFunc.buffBar.Redraw()
        end)

        widthSlider:SetPoint("TOPLEFT", sizeHeader, "BOTTOMLEFT", 0, 15)
        widthSlider:SetRange(10, 100)
        widthSlider:SetMidValue(55)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.width)
        
        --[[heightSlider = settingsUI.slider (name .. ".heightSlider", frame, "Height <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.height = newValue
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "TOPRIGHT", 30, 0)
        heightSlider:SetRange(0, 100)
        heightSlider:SetMidValue(50)
        heightSlider:SetPrecision(1)
        heightSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.height)]]

        fontHeader = settingsUI.header ( name .. "..fontHeader", frame, "Combo point setup")
        fontHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT" , 0, 15)

        timerFontSizeSlider = settingsUI.slider (name .. ".timerFontSizeSlider", frame, "Timer size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.timer = newValue
            internalFunc.buffBar.Redraw()
        end)
        
        timerFontSizeSlider:SetPoint("TOPLEFT", fontHeader, "BOTTOMLEFT", 0, 15)
        timerFontSizeSlider:SetRange(10, 40)
        timerFontSizeSlider:SetMidValue(25)
        timerFontSizeSlider:SetPrecision(1)
        timerFontSizeSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.timer)
        
        stackFontSizeSlider = settingsUI.slider (name .. ".stackFontSizeSlider", frame, "Stack size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.buffBar.buffs.stack = newValue
            internalFunc.buffBar.Redraw()
        end)
       
        stackFontSizeSlider:SetPoint("TOPLEFT", timerFontSizeSlider, "TOPRIGHT", 30, 0)
        stackFontSizeSlider:SetRange(10, 40)
        stackFontSizeSlider:SetMidValue(25)
        stackFontSizeSlider:SetPrecision(1)
        stackFontSizeSlider:AdjustValue(nkUISetup.modules.buffBar.buffs.stack)
        
        --[[labelFontSizeSlider = settingsUI.slider (name .. ".labelFontSizeSlider", frame, "label font size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
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
