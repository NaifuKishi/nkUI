local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local langTexts     = privateVars.langTexts
local uiElements    = privateVars.uiElements

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabRessourceBar (name, parent, thisSettings)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local widthSlider, heightSlider, comboWidthSlider, comboHeightSlider, chargeWidthSlider, chargeHeightSlider, marginRessourceSlider, chargeFontSize, ressourceFontSize
    local sizeHeader, comboHeader, chargeHeader, marginHeader, fontSizeHeader
    local introText, alwaysShowRessourceBarCheckbox

    function frame:build()

        alwaysShowRessourceBarCheckbox = settingsUI.checkbox(name .. ".alwaysShowRessourceBarCheckbox", frame, langTexts.settings.alwaysShowRessourceBar, true, function(newValue)
            nkUISetup.modules.unitFrames.alwaysShowRessourceBar = newValue
            uiElements.frames["player.ressourcebar"]:SetVisible(newValue)
        end)

        alwaysShowRessourceBarCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, settingsUI.PADDING.ACTIVE)
        alwaysShowRessourceBarCheckbox:SetChecked(nkUISetup.modules.unitFrames.alwaysShowRessourceBar, true)

        sizeHeader = settingsUI.header(name .. ".sizeHeader", frame, langTexts.settings.ressourceBarSize)
        sizeHeader:SetPoint("TOPLEFT", alwaysShowRessourceBarCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)

        widthSlider = settingsUI.slider(name .. ".widthSlider", frame, langTexts.settings.width, true, function(newValue)
            thisSettings.width = newValue
            internalFunc.uiFrameRedraw("player.ressourcebar")
        end)

        widthSlider:SetPoint("TOPLEFT", sizeHeader, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        widthSlider:SetRange(100, 400)
        widthSlider:SetMidValue(250)
        widthSlider:SetPrecision(1)
        widthSlider:AdjustValue(thisSettings.width)

        heightSlider = settingsUI.slider(name .. ".heightSlider", frame, langTexts.settings.height, true, function(newValue)
            thisSettings.height = newValue
            internalFunc.uiFrameRedraw("player.ressourcebar")
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "TOPRIGHT", 30, 0)
        heightSlider:SetRange(10, 50)
        heightSlider:SetMidValue(30)
        heightSlider:SetPrecision(1)
        heightSlider:AdjustValue(thisSettings.height)

        -- combo display

        comboHeader = settingsUI.header(name .. ".comboHeader", frame, langTexts.settings.comboPointSize)
        comboHeader:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)

        comboWidthSlider = settingsUI.slider(name .. ".comboWidthSlider", frame, langTexts.settings.width, true, function(newValue)
            thisSettings.combo.width = newValue
            internalFunc.uiFrameRedraw("player.ressourcebar")
        end)

        comboWidthSlider:SetPoint("TOPLEFT", comboHeader, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        comboWidthSlider:SetRange(10, 30)
        comboWidthSlider:SetMidValue(20)
        comboWidthSlider:SetPrecision(1)
        comboWidthSlider:AdjustValue(thisSettings.combo.width)

        comboHeightSlider = settingsUI.slider(name .. ".comboHeightSlider", frame, langTexts.settings.height, true, function(newValue)
            thisSettings.combo.height = newValue
            internalFunc.uiFrameRedraw("player.ressourcebar")
        end)

        comboHeightSlider:SetPoint("TOPLEFT", comboWidthSlider, "TOPRIGHT", 30, 0)
        comboHeightSlider:SetRange(10, 30)
        comboHeightSlider:SetMidValue(20)
        comboHeightSlider:SetPrecision(1)
        comboHeightSlider:AdjustValue(thisSettings.combo.height)

        -- charge display

        chargeHeader = settingsUI.header(name .. ".chargeHeader", frame, langTexts.settings.chargeDisplaySize)
        chargeHeader:SetPoint("TOPLEFT", comboWidthSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)

        chargeWidthSlider = settingsUI.slider(name .. ".chargeWidthSlider", frame, langTexts.settings.width, true, function(newValue)
            thisSettings.charge.width = newValue
            internalFunc.uiFrameRedraw("player.ressourcebar")
        end)

        chargeWidthSlider:SetPoint("TOPLEFT", chargeHeader, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        chargeWidthSlider:SetRange(100, 400)
        chargeWidthSlider:SetMidValue(250)
        chargeWidthSlider:SetPrecision(1)
        chargeWidthSlider:AdjustValue(thisSettings.charge.width)

        chargeHeightSlider = settingsUI.slider(name .. ".chargeHeightSlider", frame, langTexts.settings.height, true, function(newValue)
            thisSettings.charge.height = newValue
            internalFunc.uiFrameRedraw("player.ressourcebar")
        end)

        chargeHeightSlider:SetPoint("TOPLEFT", chargeWidthSlider, "TOPRIGHT", 30, 0)
        chargeHeightSlider:SetRange(10, 30)
        chargeHeightSlider:SetMidValue(20)
        chargeHeightSlider:SetPrecision(1)
        chargeHeightSlider:AdjustValue(thisSettings.charge.height)

        -- font sizes

        fontSizeHeader = settingsUI.header(name .. ".fontSizeHeader", frame, langTexts.settings.textSizeHeader)
        fontSizeHeader:SetPoint("TOPLEFT", chargeWidthSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)

        chargeFontSize = settingsUI.slider(name .. ".chargeFontSize", frame, langTexts.settings.charge, true, function(newValue)
            thisSettings.fontSizes.charge = newValue
            internalFunc.uiFrameRedraw("player.ressourcebar")
        end)

        chargeFontSize:SetPoint("TOPLEFT", fontSizeHeader, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        chargeFontSize:SetRange(10, 30)
        chargeFontSize:SetMidValue(20)
        chargeFontSize:SetPrecision(1)
        chargeFontSize:AdjustValue(thisSettings.fontSizes.charge)

        ressourceFontSize = settingsUI.slider(name .. ".ressourceFontSize", frame, langTexts.settings.ressource, true, function(newValue)
            thisSettings.fontSizes.ressource = newValue
            internalFunc.uiFrameRedraw("player.ressourcebar")
        end)

        ressourceFontSize:SetPoint("TOPLEFT", chargeFontSize, "TOPRIGHT", 30, 0)
        ressourceFontSize:SetRange(10, 30)
        ressourceFontSize:SetMidValue(20)
        ressourceFontSize:SetPrecision(1)
        ressourceFontSize:AdjustValue(thisSettings.fontSizes.ressource)
    end

    return frame

end