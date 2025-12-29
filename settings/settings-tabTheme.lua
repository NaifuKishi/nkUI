local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI     = privateVars.settingsUI
local uiElements	= privateVars.uiElements

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabTheme (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local logoComboBox, themeComboBox

    function frame:build()

        logoComboBox = settingsUI.checkbox(name .. ".logoComboBox", frame, "Show nkUI logo", true, function(newValue)        
            nkUISetup.showLogo = newValue
        end)

        logoComboBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        logoComboBox:SetChecked(nkUISetup.showLogo, true)

        local themeList = {{ label = "Rift", value = "rift"}, { label = "WoW", value = "wow" }}        
    
        themeComboBox = settingsUI.combobox(name .. ".theme", frame, "Select coloring mode", true, function(newValue)        
            nkUISetup.modules.unitFrames.colorScheme = newValue
            LibEKL.UI.reloadDialog ("nkUI")
        end)

        local currentTheme = nkUISetup.modules.unitFrames.colorScheme

        themeComboBox:SetSelection(themeList)     
        themeComboBox:SetSelectedValue(currentTheme, false)
        themeComboBox:SetPoint("TOPLEFT", logoComboBox, "BOTTOMLEFT", 0, 10)

       
    end

    return frame

end