local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI     = privateVars.settingsUI
local uiElements	= privateVars.uiElements

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabQuestTracker (name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckbox, trackerSizeHeader, yPosSlider, widthSlider, heightSlider, useXPosSlider, useYPosSlider, useUICheckbox, categoryHeaderSizeSlider, categoryShowCheckboxes, categoryFontSizeSliders, bodyColorPicker, bodyCompleteColorPicker

    function frame:build()

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
            nkUISetup.modules.questtracker.activate = newValue

            if widthSlider then widthSlider:SetActive(newValue) end
            if heightSlider then heightSlider:SetActive(newValue) end
            if categoryHeaderSizeSlider then categoryHeaderSizeSlider:SetActive(newValue) end
            if headerFontSizeSlider then headerFontSizeSlider:SetActive(newValue) end
            if subHeaderFontSizeSlider then subHeaderFontSizeSlider:SetActive(newValue) end
            if bodyFontSizeSlider then bodyFontSizeSlider:SetActive(newValue) end

            internalFunc.questTrackerInit(newValue)
        end)

        local moduleActive = nkUISetup.modules.questtracker.activate

        activateCheckbox:SetChecked(nkUISetup.modules.questtracker.activate, true)
        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)

        trackerSizeHeader = settingsUI.header ( name .. ".trackerSizeHeader", frame, "Tracker size")
        trackerSizeHeader:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT" , 0, 15)

        widthSlider = settingsUI.slider(name .. ".widthSlider", frame, "Width <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.questtracker.width = newValue
        end)
               
        widthSlider:SetPoint("TOPLEFT", trackerSizeHeader, "BOTTOMLEFT", 0, 15)
        widthSlider:SetRange(100, 1000)
        widthSlider:SetMidValue(500)
        widthSlider:AdjustValue(nkUISetup.modules.questtracker.width)

        heightSlider = settingsUI.slider(name .. ".heightSlider", frame, "Height <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.questtracker.height = newValue
        end)

        heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, 10)
        heightSlider:SetRange(100, 1000)
        heightSlider:SetMidValue(500)
        heightSlider:AdjustValue(nkUISetup.modules.questtracker.height)

        fontSizeHeader = settingsUI.header ( name .. ".fontSizeHeader", frame, "Font sizes")
        fontSizeHeader:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT" , 0, 15)        

        headerFontSizeSlider = settingsUI.slider(name .. ".headerFontSizeSlider", frame, "Header Font Size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.questtracker.categoryFontSize.header = newValue
        end)

        headerFontSizeSlider:SetPoint("TOPLEFT", fontSizeHeader, "BOTTOMLEFT", 0, 15)
        headerFontSizeSlider:SetRange(8, 24)
        headerFontSizeSlider:SetMidValue(15)
        headerFontSizeSlider:AdjustValue(nkUISetup.modules.questtracker.categoryFontSize.header)


        categoryHeaderSizeSlider = settingsUI.slider(name .. ".categoryHeaderSizeSlider", frame, "Category Header Size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.questtracker.categoryHeaderSize = newValue
        end)

        categoryHeaderSizeSlider:SetPoint("TOPLEFT", headerFontSizeSlider, "BOTTOMLEFT", 0, 10)
        categoryHeaderSizeSlider:SetRange(8, 24)
        categoryHeaderSizeSlider:SetMidValue(16)
        categoryHeaderSizeSlider:AdjustValue(nkUISetup.modules.questtracker.categoryHeaderSize)        
        
        subHeaderFontSizeSlider = settingsUI.slider(name .. ".subHeaderFontSizeSlider", frame, "SubHeader Font Size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.questtracker.categoryFontSize.subHeader = newValue
        end)

        subHeaderFontSizeSlider:SetPoint("TOPLEFT", categoryHeaderSizeSlider, "BOTTOMLEFT", 0, 10)
        subHeaderFontSizeSlider:SetRange(8, 24)
        subHeaderFontSizeSlider:SetMidValue(14)
        subHeaderFontSizeSlider:AdjustValue(nkUISetup.modules.questtracker.categoryFontSize.subHeader)

        bodyFontSizeSlider = settingsUI.slider(name .. ".bodyFontSizeSlider", frame, "Body Font Size <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.questtracker.categoryFontSize.body = newValue
        end)

        bodyFontSizeSlider:SetPoint("TOPLEFT", subHeaderFontSizeSlider, "BOTTOMLEFT", 0, 10)
        bodyFontSizeSlider:SetRange(8, 24)
        bodyFontSizeSlider:SetMidValue(13)
        bodyFontSizeSlider:AdjustValue(nkUISetup.modules.questtracker.categoryFontSize.body)
    end

    return frame

end

