local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local _settings     = privateVars.settings
local uiElements	= privateVars.uiElements

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabTheme (name, parent)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local themeComboBox

    function frame:build()

        local themeList = {{ label = "Rift", value = "rift"}, { label = "WoW", value = "wow" }}
    
        themeComboBox = _settings.combobox(name .. ".theme", frame, "Select coloring mode", true, function(newValue)        
            nkUISetup.modules.unitFrames.colorScheme = newValue
            EnKai.ui.reloadDialog ("nkUI")
        end)

        local currentTheme = nkUISetup.modules.unitFrames.colorScheme

        themeComboBox:SetSelection(themeList)     
        themeComboBox:SetSelectedValue(currentTheme, false)
        themeComboBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)

    end

    return frame

end