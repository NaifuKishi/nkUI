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

local name = "tutorial"

---------- init local function ---------

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
            description = "Welcome to nkUI and thank you for trying out my addon.\n\nThis tutorial will guide you through the basic features of nkUI. Please be aware that this is a work in progress and not all features are fully implemented yet.\n\nWhat's new:\n- settings\n- New one bag module",
            image = "gfx/EnKaiLogo.png",
            width = 300,
            height = 79,
            position = "bottom",
        },
        {
            title = "nkUI Settings",
            description = "There's a configuration to change aspects of nkUI.\n\nYou can access the configuration either by typing /nkui or by clicking the minimap button.",
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
            position = "bottom"
        },        
        {
            title = "Lower bar module",
            description = "This nkUI module displays a bar at the bottom of your screen. That bar provides various important informations like date & time, currency, location, fps and more in a way fitting with the design of nkUI.",
            image = "gfx/tutorialLowerBar.png",
            width = 560,
            height = 22,
            position = "bottom",
        },        
        {
            title = "Action bar module (1/2)",
            description = "This nkUI module provides action bars fitting with the theme of nkUI.\n\nYou can drag and drop skills and items to the action bar. You can clear a slot by right-clicking it. Cooldowns and Out-Of-Range indicator will help you visually with the abilites.\n\nDue to restrictions of the RIFT API it is NOT possible to do key bindings. You'll have to set up the normal Rift action bars with your abilities and then hide them. Sorry no other way to do this :(",            
            image = "gfx/tutorialActionBar.png",
            width = 560,
            height = 93,
            position = "bottom",
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
            title = "Scrolling combat text module",
            description = "This nkUI module replaces the in-game scrolling combat text. You will have to manually deactivate the ingame one in the settings (Setting / Interface / Screen Messages).",
            image = "gfx/tutorialSCT.png",
            width = 429,
            height = 250,
            position = "bottom",
        },            
        {
            title = "Tooltip module",
            description = "This nkUI module shows a tooltip for units which does look a lot better than the standard tooltip. Unfortunately due to API restrictions it's not possible to display quest information for NPC. There fore sometimes the tooltip will be bigger than neccessary. I'll try to figure out something here in the upcoming weeks.",
            image = "gfx/tutorialTooltip.png",
            width = 182,
            height = 103,
            position = "bottom",
        },
        {
            title = "You are done - for now :)",
            description = "That's all so far. Make sure to regularly check Cursegorge or the Discord for update.\n\nYou can reopen this window from the settings."
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


