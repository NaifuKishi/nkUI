--[[
    settings/settings.lua
    Author: NaifuKishi
    Date of Creation: 22.11.2025
    Date of Last Modification: 22.11.2025
    Description: This file contains the settings module for the nkUI addon, which handles various UI configurations and tutorial functionality.
    Public Functions:
        - _internal.tutorial(): Creates and displays the tutorial window for nkUI settings
    Version History:
        - [Version 1.0] - Initial release
]]
        
local addonInfo, privateVars = ...

---------- init namespace ---------

local data      = privateVars.data
local uiElements= privateVars.uiElements
local _internal = privateVars.internal
local _events   = privateVars.events
local oFuncs    = privateVars.oFuncs

---------- init local variables ---------

local name = "settings"

---------- init local function ---------

--[[
    toggleAlpha
    Description:
        Adjusts the alpha (transparency) of player-related UI elements based on combat status.
    Parameters:
        None
    Returns:
        None
    Notes:
        - This function is called when the non-combat alpha setting is changed
        - It affects the transparency of player, pet, and target frames
    Available Methods:
        - None (local function)
]]
local function toggleAlpha()
    
    uiElements.frames["player"]:SetAlpha(nkUISetup.nonCombatAlpha)    
    uiElements.frames["player.pet"]:SetAlpha(nkUISetup.nonCombatAlpha)
    uiElements.frames["player.target"]:SetAlpha(nkUISetup.nonCombatAlpha)
    uiElements.frames["focus"]:SetAlpha(nkUISetup.nonCombatAlpha)

end

local function actionBarToggleAlpha()
    
    for k, v in pairs (uiElements.actionbars) do
        v:SetAlpha(nkUISetup.actionBarNonCombatAlpha)
    end

end


--[[
    _subTutorialUnitframes
    Description:
        Creates and configures the unit frames tutorial sub-section.
    Parameters:
        parent (table): The parent frame to which this sub-section will be attached
    Returns:
        table: The created frame containing unit frames configuration options
    Notes:
        - This function creates checkboxes and sliders for unit frames configuration
        - It includes options for activating the module, buff/debuff bars, and alpha settings
        - The function handles event attachments for configuration changes
    Available Methods:
        - None (local function)
]]
local function _subTutorialUnitframes(parent)

    local buffsCheckbox, buffsUnitBarCheckbox, combatAlphaSlider

    local name = "nkUI.tutorialWindow.unitframes"

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    frame:SetVisible(false)

    local activateCheckbox = EnKai.uiCreateFrame("nkCheckbox", name .. ".activateCheckbox", frame)
    activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
    activateCheckbox:SetText("Activate this module")
    activateCheckbox:SetChecked(nkUISetup.uiFrames.activate)
    activateCheckbox:SetLabelWidth(250)
    activateCheckbox:SetFontSize(16)
    activateCheckbox:SetTextFont(addonInfo.id, "Montserrat")

    Command.Event.Attach(EnKai.events[name .. '.activateCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.uiFrames.activate = newValue
        buffsCheckbox:SetActive(newValue)
        buffsUnitBarCheckbox:SetActive(newValue)
        combatAlphaSlider:SetActive(newValue)
        nonCombatAlphaSlider:SetActive(newValue)

        _internal.uiFramesToggle(newValue)

        if newValue == false then 
            _internal.buffBar.clearAllBuffs() 
            _internal.uiFramesRemoveBuffs()
        else
            _internal.uiFramesLoadAllBuffs()
            _internal.buffBar.loadAllBuffs()
        end

    end, name .. '.activateCheckbox.CheckboxChanged')

    buffsCheckbox = EnKai.uiCreateFrame("nkCheckbox", name .. ".buffsCheckbox", frame)
    buffsCheckbox:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, 20)
    buffsCheckbox:SetText("Main buff/debuff bar")
    buffsCheckbox:SetChecked(nkUISetup.buffFrame.activate)
    buffsCheckbox:SetLabelWidth(250)
    buffsCheckbox:SetFontSize(16)
    buffsCheckbox:SetTextFont(addonInfo.id, "Montserrat")
    buffsCheckbox:SetActive(nkUISetup.uiFrames.activate)

    Command.Event.Attach(EnKai.events[name .. '.buffsCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.buffFrame.activate = newValue
        if newValue == false then 
            _internal.buffBar.clearAllBuffs()             
        else
            _internal.buffBar.loadAllBuffs()
        end
    end, name .. '.buffsCheckbox.CheckboxChanged')

    buffsUnitBarCheckbox = EnKai.uiCreateFrame("nkCheckbox", name .. ".buffsUnitBarCheckbox", frame)
    buffsUnitBarCheckbox:SetPoint("TOPLEFT", buffsCheckbox, "BOTTOMLEFT", 0, 5)
    buffsUnitBarCheckbox:SetText("Buffs/debuffs on unit frames")
    buffsUnitBarCheckbox:SetChecked(nkUISetup.buffUnitFrame.activate)
    buffsUnitBarCheckbox:SetLabelWidth(250)
    buffsUnitBarCheckbox:SetFontSize(16)
    buffsUnitBarCheckbox:SetTextFont(addonInfo.id, "Montserrat")
    buffsUnitBarCheckbox:SetActive(nkUISetup.uiFrames.activate)

    Command.Event.Attach(EnKai.events[name .. '.buffsUnitBarCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.buffUnitFrame.activate = newValue
        if newValue == false then 
            _internal.uiFramesRemoveBuffs()
        else
            _internal.uiFramesLoadAllBuffs()
        end
    end, name .. '.buffsUnitBarCheckbox.CheckboxChanged')

    combatAlphaSlider = EnKai.uiCreateFrame("nkSlider", name .. ".combatAlphaSlider", frame)
    combatAlphaSlider:SetPoint("TOPLEFT", buffsUnitBarCheckbox, "BOTTOMLEFT", 0, 5)
    combatAlphaSlider:SetText("Combat alpha %d%%" )
    combatAlphaSlider:SetWidth(400)
    combatAlphaSlider:SetRange(0, 100)
    combatAlphaSlider:SetMidValue(50)
    combatAlphaSlider:SetPrecision(5)
    combatAlphaSlider:SetLabelWidth(250)
    combatAlphaSlider:SetFontSize(16)
    combatAlphaSlider:SetActive(nkUISetup.uiFrames.activate)
    combatAlphaSlider:SetFont(addonInfo.id, "Montserrat")
    combatAlphaSlider:AdjustValue(nkUISetup.combatAlpha * 100)
    
    Command.Event.Attach(EnKai.events[name .. '.combatAlphaSlider'].SliderChanged, function (_, newValue)
        nkUISetup.combatAlpha = newValue / 100
    end, name .. ".combatAlphaSlider.SliderChanged")

    nonCombatAlphaSlider = EnKai.uiCreateFrame("nkSlider", name .. ".nonCombatAlphaSlider", frame)
    nonCombatAlphaSlider:SetPoint("TOPLEFT", combatAlphaSlider, "BOTTOMLEFT", 0, 5)
    nonCombatAlphaSlider:SetText("Combat alpha %d%%" )
    nonCombatAlphaSlider:SetWidth(400)
    nonCombatAlphaSlider:SetRange(0, 100)
    nonCombatAlphaSlider:SetMidValue(50)
    nonCombatAlphaSlider:SetPrecision(5)    
    nonCombatAlphaSlider:SetLabelWidth(250)
    nonCombatAlphaSlider:SetFontSize(16)
    nonCombatAlphaSlider:SetActive(nkUISetup.uiFrames.activate)
    nonCombatAlphaSlider:SetFont(addonInfo.id, "Montserrat")
    nonCombatAlphaSlider:AdjustValue(nkUISetup.nonCombatAlpha * 100)
    
    Command.Event.Attach(EnKai.events[name .. '.nonCombatAlphaSlider'].SliderChanged, function (_, newValue)
        nkUISetup.nonCombatAlpha = newValue / 100
        toggleAlpha()
    end, name .. ".nonCombatAlphaSlider.SliderChanged")

    return frame

end

--[[
    _subTutorialLowerBar
    Description:
        Creates and configures the lower bar tutorial sub-section.
    Parameters:
        parent (table): The parent frame to which this sub-section will be attached
    Returns:
        table: The created frame containing lower bar configuration options
    Notes:
        - This function creates a checkbox for activating the lower bar module
        - It handles the event attachment for configuration changes
    Available Methods:
        - None (local function)
]]
local function _subTutorialLowerBar(parent)

    local name = "nkUI.tutorialWindow.lowerBar"

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    frame:SetVisible(false)

    local activateCheckbox = EnKai.uiCreateFrame("nkCheckbox", name .. ".activateCheckbox", frame)
    activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
    activateCheckbox:SetText("Activate this module")
    activateCheckbox:SetChecked(nkUISetup.lowerBar.activate)
    activateCheckbox:SetLabelWidth(200)
    activateCheckbox:SetFontSize(16)
    activateCheckbox:SetTextFont(addonInfo.id, "Montserrat")

    Command.Event.Attach(EnKai.events[name .. '.activateCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.lowerBar.activate = newValue
        _internal.lowerBarInit (newValue)
    end, name .. '.activateCheckbox.CheckboxChanged')

    return frame

end

local function _subTutorialActionBar(parent)

    local name = "nkUI.tutorialWindow.actionbar"

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    frame:SetVisible(false)

    local activateCheckbox = EnKai.uiCreateFrame("nkCheckbox", name .. ".activateCheckbox", frame)
    activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
    activateCheckbox:SetText("Activate this module")
    activateCheckbox:SetChecked(nkUISetup.moduleActionBars.activate)
    activateCheckbox:SetLabelWidth(200)
    activateCheckbox:SetFontSize(16)
    activateCheckbox:SetTextFont(addonInfo.id, "Montserrat")

    Command.Event.Attach(EnKai.events[name .. '.activateCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.moduleActionBars.activate = newValue
        _internal.uiActionBarInit (newValue)
    end, name .. '.activateCheckbox.CheckboxChanged')

    combatAlphaSlider = EnKai.uiCreateFrame("nkSlider", name .. ".combatAlphaSlider", frame)
    combatAlphaSlider:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, 5)
    combatAlphaSlider:SetText("Combat alpha %d%%" )
    combatAlphaSlider:SetWidth(400)
    combatAlphaSlider:SetRange(0, 100)
    combatAlphaSlider:SetMidValue(50)
    combatAlphaSlider:SetPrecision(5)
    combatAlphaSlider:SetLabelWidth(250)
    combatAlphaSlider:SetFontSize(16)
    combatAlphaSlider:SetActive(nkUISetup.uiFrames.activate)
    combatAlphaSlider:SetFont(addonInfo.id, "Montserrat")
    combatAlphaSlider:AdjustValue(nkUISetup.actionBarCombatAlpha * 100)
    
    Command.Event.Attach(EnKai.events[name .. '.combatAlphaSlider'].SliderChanged, function (_, newValue)
        nkUISetup.actionBarCombatAlpha = newValue / 100
    end, name .. ".combatAlphaSlider.SliderChanged")

    nonCombatAlphaSlider = EnKai.uiCreateFrame("nkSlider", name .. ".nonCombatAlphaSlider", frame)
    nonCombatAlphaSlider:SetPoint("TOPLEFT", combatAlphaSlider, "BOTTOMLEFT", 0, 5)
    nonCombatAlphaSlider:SetText("Combat alpha %d%%" )
    nonCombatAlphaSlider:SetWidth(400)
    nonCombatAlphaSlider:SetRange(0, 100)
    nonCombatAlphaSlider:SetMidValue(50)
    nonCombatAlphaSlider:SetPrecision(5)    
    nonCombatAlphaSlider:SetLabelWidth(250)
    nonCombatAlphaSlider:SetFontSize(16)
    nonCombatAlphaSlider:SetActive(nkUISetup.uiFrames.activate)
    nonCombatAlphaSlider:SetFont(addonInfo.id, "Montserrat")
    nonCombatAlphaSlider:AdjustValue(nkUISetup.actionBarNonCombatAlpha * 100)
    
    Command.Event.Attach(EnKai.events[name .. '.nonCombatAlphaSlider'].SliderChanged, function (_, newValue)
        nkUISetup.actionBarNonCombatAlpha = newValue / 100
        actionBarToggleAlpha()
    end, name .. ".nonCombatAlphaSlider.SliderChanged")    

    return frame

end

--[[
    _subTutorialTooltip
    Description:
        Creates and configures the tooltip tutorial sub-section.
    Parameters:
        parent (table): The parent frame to which this sub-section will be attached
    Returns:
        table: The created frame containing tooltip configuration options
    Notes:
        - This function creates a checkbox for activating the tooltip module
        - It handles the event attachment for configuration changes
    Available Methods:
        - None (local function)
]]
local function _subTutorialTooltip(parent)

    local name = "nkUI.tutorialWindow.tooltip"

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    frame:SetVisible(false)

    local activateCheckbox = EnKai.uiCreateFrame("nkCheckbox", name .. ".activateCheckbox", frame)
    activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
    activateCheckbox:SetText("Activate this module")
    activateCheckbox:SetChecked(nkUISetup.tooltip.activate)
    activateCheckbox:SetLabelWidth(200)
    activateCheckbox:SetFontSize(16)
    activateCheckbox:SetTextFont(addonInfo.id, "Montserrat")

    Command.Event.Attach(EnKai.events[name .. '.activateCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.tooltip.activate = newValue
        if (newValue == true) then _internal.tooltip() end
    end, name .. '.activateCheckbox.CheckboxChanged')

    return frame
end

local function _subTutorialSCT(parent)

    local name = "nkUI.tutorialWindow.sct"

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    frame:SetVisible(false)

    local activateCheckbox = EnKai.uiCreateFrame("nkCheckbox", name .. ".activateCheckbox", frame)
    activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
    activateCheckbox:SetText("Activate this module")
    activateCheckbox:SetChecked(nkUISetup.sct.activate)
    activateCheckbox:SetLabelWidth(200)
    activateCheckbox:SetFontSize(16)
    activateCheckbox:SetTextFont(addonInfo.id, "Montserrat")

    Command.Event.Attach(EnKai.events[name .. '.activateCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.sct.activate = newValue
        _internal.sctToggle(newValue)
    end, name .. '.activateCheckbox.CheckboxChanged')

    return frame

end

--[[
    _createTutorialWindow
    Description:
        Creates the main tutorial window for nkUI settings.
    Parameters:
        None
    Returns:
        table: The created tutorial window frame
    Notes:
        - This function creates the main tutorial window with navigation buttons
        - It initializes all tutorial steps and their content
        - The function handles navigation between different tutorial steps
    Available Methods:
        - reset(): Resets the tutorial to the first step and makes the window visible
]]
local function _createTutorialWindow()

    local name = "nkUI.tutorialWindow"

    -- Create the main tutorial window
    local tutorialWindow = EnKai.uiCreateFrame("nkWindowMetro", "nkUI.tutorialWindow", uiElements.contextTop)
    tutorialWindow:SetTitle("nkUI Tutorial and setup")
    tutorialWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    tutorialWindow:SetWidth(600)
    tutorialWindow:SetHeight(600)
    tutorialWindow:SetPoint("CENTER", UIParent, "CENTER")
    tutorialWindow:SetShadow(true)

    -- Create content frame
    local content = tutorialWindow:GetContent()

    -- Current step tracker
    local currentStep = 1

    -- Create UI elements for the tutorial
    local titleText = EnKai.uiCreateFrame("nkText", "tutorialTitle", content)
    titleText:SetPoint("TOPLEFT", content, "TOPLEFT", 20, 20)
    titleText:SetFontSize(20)
    titleText:SetTextFont(addonInfo.id, "MontserratSemiBold")

    local descriptionText = EnKai.uiCreateFrame("nkText", "tutorialDescription", content)
    descriptionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, 20)
    descriptionText:SetWordwrap(true)
    descriptionText:SetWidth(560)
    descriptionText:SetFontSize(16)
    descriptionText:SetTextFont(addonInfo.id, "Montserrat")

    -- Create a frame for displaying subframes
    local subFrameContainer = EnKai.uiCreateFrame("nkFrame", "nkUI.tutorialWindow.subFrameContainer", content)
    subFrameContainer:SetPoint("TOPLEFT", descriptionText, "BOTTOMLEFT", 0, 10)
    subFrameContainer:SetWidth(560)
    subFrameContainer:SetHeight(500)
    subFrameContainer:SetVisible(false)

    local imageFrame = EnKai.uiCreateFrame("nkTexture", "tutorialImage", content)

    -- Navigation buttons
    local prevButton = EnKai.uiCreateFrame("nkButtonMetro", "prevButton", content)
    prevButton:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 20, -20)
    prevButton:SetText("Previous")
    prevButton:SetFont(addonInfo.id, "MontserratSemiBold")
    prevButton:SetWidth(100)

    local nextButton = EnKai.uiCreateFrame("nkButtonMetro", "nextButton", content)
    nextButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, -20)
    nextButton:SetText("Next")
    nextButton:SetFont(addonInfo.id, "MontserratSemiBold")
    nextButton:SetWidth(100)

    -- Create tutorial steps
    local steps = {
        {
            title = "Welcome to nkUI",
            description = "Welcome to nkUI and thank you for trying out my addon.\n\nThis tutorial will guide you through the basic features of nkUI. Please be aware that this is a work in progress and not all features are fully implemented yet.\n\nWhat's new:\n- New one bag module",
            image = "gfx/EnKaiLogo.png",
            width = 300,
            height = 79,
            position = "bottom",
        },
        {
            title = "Default UI elements",
            description = "This addon provides a lot of replacements for the standard UI elements. Unfortunately due to a lot of limitations in the RIFT API the default elements cannot be deactivated by addons.\n\nInstead you have to do so manually once. You can do so by hitting Escape and use the option [Edit Layout]. Using that option you can hide default ui elements.",
            image = "gfx/tutorialDefaultUI.png",
            width = 170,
            height = 240,
            position = "right",
        },
        {
            title = "One bag module (1/2)",
            description = "This nkUI module is a replacement for the ingame bags and shows everything in one tiday frame.",
            image = "gfx/tutorialOneBag.png",
            width = 405,
            height = 350,
            position = "bottom",
        },
        {
            title = "One bag module (2/2)",
            description = "You can load the bag ui by typing '/nkui bag' in the chat.\n\nIn order to have the bag ui open when hitting the 'B' key I suggest to do the following:\n\nCreate a macro with the command '/nkui bag', place it on any default action bar (which you afterwards hide) and ind the key 'B' to that action bar slot.\n\nAlso I suggest that you scale your default bags to the lowest setting possible which is 50%.",
            image = "gfx/tutorialOneBagScale.png",
            width = 525,
            height = 115,
            position = "bottom",
        },
        {
            title = "Unit Frame module",
            description = "This nkUI module will display player, target and pet frames along with castbar and ressource bar. The design is much more modern than the standard ui.\n\nIf you activate the unit frame module you can individually decide to use the buff / debuff frame which is part of the unit frame module.",
            image = "gfx/tutorialUnitFrames.png",
            width = 400,
            height = 46,
            settings = _subTutorialUnitframes(subFrameContainer),
            position = "bottom"
        },        
        {
            title = "Lower bar module",
            description = "This nkUI module displays a bar at the bottom of your screen. That bar provides various important informations like date & time, currency, location, fps and more in a way fitting with the design of nkUI.",
            image = "gfx/tutorialLowerBar.png",
            width = 560,
            height = 22,
            position = "bottom",
            settings = _subTutorialLowerBar(subFrameContainer)
        },        
        {
            title = "Action bar module (1/2)",
            description = "This nkUI module provides action bars fitting with the theme of nkUI.\n\nYou can drag and drop skills and items to the action bar. You can clear a slot by right-clicking it. Cooldowns and Out-Of-Range indicator will help you visually with the abilites.\n\nDue to restrictions of the RIFT API it is NOT possible to do key bindings. You'll have to set up the normal Rift action bars with your abilities and then hide them. Sorry no other way to do this :(",            
            image = "gfx/tutorialActionBar.png",
            width = 560,
            height = 93,
            position = "bottom",
            settings = _subTutorialActionBar(subFrameContainer)
        },
        {
            title = "Action bar module (2/2)",
            description = "The buttons left and right to the main bar as weel as the bar to the right of the screen are interactive. That means you can click on them to activate abilities and items.\n\nOn top of that you can add macros by middle clicking an action bar slot with your mouse. In the appearing dialog you can configure your macro. You can drop any ability or item in the icon frame.",            
            image = "gfx/tutorialMacro.png",
            width = 252,
            height = 180,
            position = "bottom",
        },        
        {
            title = "Scrolling combat text Module",
            description = "This nkUI module replaces the in-game scrolling combat text. You will have to manually deactivate the ingame one in the settings (Setting / Interface / Screen Messages).",
            image = "gfx/tutorialSCT.png",
            width = 429,
            height = 250,
            position = "bottom",
            settings = _subTutorialSCT(subFrameContainer)
        },            
        {
            title = "Tooltip module",
            description = "This nkUI module shows a tooltip for units which does look a lot better than the standard tooltip. Unfortunately due to API restrictions it's not possible to display quest information for NPC. There fore sometimes the tooltip will be bigger than neccessary. I'll try to figure out something here in the upcoming weeks.",
            image = "gfx/tutorialTooltip.png",
            width = 182,
            height = 103,
            position = "bottom",
            settings = _subTutorialTooltip(subFrameContainer)            
        },
        {
            title = "You are done - for now :)",
            description = "That's all so far. Make sure to regularly check Cursegorge or the Discord for update.\n\nYou can reopen this window by using the chat command /nkui"
        }
    }

    -- Function to update the tutorial content
    local function updateTutorial()
        local step = steps[currentStep]

        titleText:SetText(step.title)
        descriptionText:SetText(step.description)
        descriptionText:SetWidth (560)
        
        if step.settings then
            subFrameContainer:SetVisible(true)            
            step.settings:SetVisible(true)
        else
            subFrameContainer:SetVisible(false)
        end

        if step.image then
            imageFrame:ClearAll()
            imageFrame:SetTextureAsync(addonInfo.identifier, step.image)
            imageFrame:SetWidth(step.width or 560)
            imageFrame:SetHeight(step.height or 200)

            if step.position == "bottom" then
                imageFrame:SetPoint("BOTTOMCENTER", content, "BOTTOMCENTER", 0, -75)                
            elseif step.position == "right" then
                imageFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, -75)
                descriptionText:SetWidth (550 - step.width)
            end


            imageFrame:SetVisible(true)
        else
            imageFrame:SetVisible(false)
        end

        prevButton:SetVisible(currentStep > 1)

        if currentStep == #steps then
            nextButton:SetText("Finish")
        else
            nextButton:SetText("Next")
        end

    end

    function tutorialWindow:reset()
        currentStep = 1
        updateTutorial()
        tutorialWindow:SetVisible(true)
    end

    -- Button event handlers
    prevButton:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        local step = steps[currentStep]
        if step.settings then
            step.settings:SetVisible(false)
        end

        if currentStep > 1 then
            currentStep = currentStep - 1
            updateTutorial()
        end
    end, "prevButtonClick")

    nextButton:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        local step = steps[currentStep]
        if step.settings then
            step.settings:SetVisible(false)
        end

        if currentStep < #steps then
            currentStep = currentStep + 1
            updateTutorial()
        else
            tutorialWindow:SetVisible(false)
        end
    end, "nextButtonClick")

    updateTutorial()

    return tutorialWindow
end

--[[
    _internal.tutorial
    Description:
        Creates and displays the tutorial window for nkUI settings. This function initializes the tutorial interface
        and handles navigation between different tutorial steps.
    Parameters:
        None
    Returns:
        None
    Notes:
        - This function creates a comprehensive tutorial window that guides users through nkUI's features
        - The tutorial includes steps for unit frames, lower bar, and tooltip modules
        - Each step provides descriptions and configuration options for the respective modules
    Available Methods:
        - None (standalone function)
]]
function _internal.tutorial()

   if uiElements.tutorialWindow == nil then
        uiElements.tutorialWindow = _createTutorialWindow()
    else
        uiElements.tutorialWindow:reset()
    end
    
end


