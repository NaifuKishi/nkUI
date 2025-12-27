local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI     = privateVars.settingsUI
local uiElements	= privateVars.uiElements

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabTheme (name, parent)

    local frame = LibEKL.uiCreateFrame("nkFrame", name, parent)
    local themeComboBox, oneBagColor, oneBagAlphaSlider

    function frame:build()

        local themeList = {{ label = "Rift", value = "rift"}, { label = "WoW", value = "wow" }}
    
        themeComboBox = settingsUI.combobox(name .. ".theme", frame, "Select coloring mode", true, function(newValue)        
            nkUISetup.modules.unitFrames.colorScheme = newValue
            LibEKL.ui.reloadDialog ("nkUI")
        end)

        local currentTheme = nkUISetup.modules.unitFrames.colorScheme

        themeComboBox:SetSelection(themeList)     
        themeComboBox:SetSelectedValue(currentTheme, false)
        themeComboBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)

        --[[oneBagColor = LibEKL.uiCreateFrame("nkColorPicker", name .. '.oneBagColor', frame)
		oneBagColor:SetPoint("TOPLEFT", themeComboBox, "BOTTOMLEFT", 0, 10)
		oneBagColor:SetText("Bag window color")
		oneBagColor:SetFont(addonInfo.id, "Montserrat")
		oneBagColor:SetWidth(205)
		oneBagColor:SetHeight(15)
		oneBagColor:SetColor(nkUISetup.modules.oneBag.windowColor.r, nkUISetup.modules.oneBag.windowColor.g, nkUISetup.modules.oneBag.windowColor.b, nkUISetup.modules.oneBag.windowColor.a)
		
		Command.Event.Attach(LibEKL.events[name .. '.oneBagColor'].ColorChanged, function (_, r, g, b, a)
            nkUISetup.modules.oneBag.windowColor = { r = r, g = g, b = b, a = nkUISetup.modules.oneBag.windowColor.a}
		end, name .. ".oneBagColor.ColorChanged")

        oneBagAlphaSlider = settingsUI.slider (name .. ".oneBagAlphaSlider", frame, "Alpha <font color='#3399FF'>%d%%</font>", true, function (newValue)
            nkUISetup.modules.oneBag.windowColor.a = newValue / 100
        end)

        oneBagAlphaSlider:SetPoint("TOPLEFT", oneBagColor, "BOTTOMLEFT", 0, 10)
        oneBagAlphaSlider:SetRange(0, 100)
        oneBagAlphaSlider:SetMidValue(50)
        oneBagAlphaSlider:SetPrecision(1)
        oneBagAlphaSlider:AdjustValue(nkUISetup.modules.oneBag.windowColor.a * 100 )
]]
    end

    return frame

end