--[[
    settings/settings.lua
    Author: NaifuKishi
    Date of Creation: 22.11.2025
    Date of Last Modification: 22.11.2025
    Description: This file contains the settings module for the nkUI addon, which handles various UI configurations and tutorial functionality.
    Public Functions:
        - internalFunc.tutorial(): Creates and displays the tutorial window for nkUI settings
    Version History:
        - [Version 1.0] - Initial release
]]

local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local _events       = privateVars.events
local langTexts     = privateVars.langTexts

local stringFormat = string.format

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
    local tutorialWindow = LibEKL.UICreateFrame("nkwindow", "nkUI.tutorialWindow", uiElements.settingsContext)
    tutorialWindow:SetLayer(2)
    tutorialWindow:SetTitle("nkUI Tutorial and setup")
    tutorialWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    tutorialWindow:SetWidth(600)
    tutorialWindow:SetHeight(600)
    tutorialWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (LibEKL.UI.getBoundRight() / 2) - (tutorialWindow:GetWidth()/2), 200)
    tutorialWindow:SetTitleFontSize(16)
    tutorialWindow:SetTitleEffect({strength = 3})

    tutorialWindow:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

    tutorialWindow:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, math.pi, 0, 0), -- 180 degree angle
        color = {
            {r = 0.13, g = 0.15, b = 0.20, a = 1, position = 0}, -- Start color
            {r = 0.10, g = 0.11, b = 0.15, a = 1, position = 1}  -- End color
        }
    },  {
        r = 0x66 / 255,
        g = 0x56 / 255,
        b = 0x2e / 255,
        a = 1,
        cap = "round",
        miter = "miter",
        thickness = 2
    })

    -- Create content frame
    local content = tutorialWindow:GetContent()

    -- Current step tracker
    local currentStep = 1

    -- Create UI elements for the tutorial
    local titleText = LibEKL.UICreateFrame("nkText", "tutorialTitle", content)
    titleText:SetPoint("TOPLEFT", content, "TOPLEFT", 20, 20)
    titleText:SetFontSize(20)
    titleText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    titleText:SetEffectGlow({strength = 3})

    local descriptionText = LibEKL.UICreateFrame("nkText", "tutorialDescription", content)
    descriptionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, 20)
    descriptionText:SetWordwrap(true)
    descriptionText:SetWidth(560)
    descriptionText:SetFontSize(16)
    descriptionText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    descriptionText:SetEffectGlow({strength = 3})

    -- Create a frame for displaying subframes
    local subFrameContainer = LibEKL.UICreateFrame("nkFrame", "nkUI.tutorialWindow.subFrameContainer", content)
    subFrameContainer:SetPoint("TOPLEFT", descriptionText, "BOTTOMLEFT", 0, 10)
    subFrameContainer:SetWidth(560)
    subFrameContainer:SetHeight(500)
    subFrameContainer:SetVisible(false)

    local imageFrame = LibEKL.UICreateFrame("nkTexture", "tutorialImage", content)

    -- Navigation buttons
    local prevButton = LibEKL.UICreateFrame("nkButton", "prevButton", content)
    prevButton:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 20, -20)
    prevButton:SetText(langTexts.tutorial.previousButton)
    prevButton:SetFont(addonInfo.id, "MontserratSemiBold")
    prevButton:SetWidth(100)
    prevButton:SetLabelColor(data.theme.labelColor)
    prevButton:SetEffectGlow({strength = 3})
    prevButton:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = .4})
    prevButton:SetBorderColor({r = 0, g = 0, b = 0, a = .7, thickness = 1})

    local nextButton = LibEKL.UICreateFrame("nkButton", "nextButton", content)
    nextButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, -20)
    nextButton:SetText(langTexts.tutorial.nextButton)
    nextButton:SetFont(addonInfo.id, "MontserratSemiBold")
    nextButton:SetWidth(100)
    nextButton:SetLabelColor(data.theme.labelColor)
    nextButton:SetEffectGlow({strength = 3})
    nextButton:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = .4})
    nextButton:SetBorderColor({r = 0, g = 0, b = 0, a = .7, thickness = 1})

    -- Create tutorial steps
    local steps = {
        {
            title = stringFormat(langTexts.tutorial.welcomeTitle, addonInfo.toc.Version),
            description = langTexts.tutorial.welcomeDescription,
            image = "gfx/nkUILogo.png",
            width = 200,
            height = 197,
            position = "bottom",
        },
        {
            title = langTexts.tutorial.settingsTitle,
            description = langTexts.tutorial.settingsDescription,
        },
        {
            title = langTexts.tutorial.defaultUIElementsTitle,
            description = langTexts.tutorial.defaultUIElementsDescription,
            image = "gfx/tutorialDefaultUI.png",
            width = 170,
            height = 240,
            position = "right",
        },
        {
            title = langTexts.tutorial.questLogTitle,
            description = langTexts.tutorial.questLogDescription,
            image = "gfx/tutorialquestlogl.png",
            width = 405,
            height = 326,
            position = "bottom",
        },        
        {
            title = langTexts.tutorial.questTrackerTitle,
            description = langTexts.tutorial.questTrackerDescription,
            image = "gfx/tutorialQuestTracker.png",
            width = 170,
            height = 350,
            position = "right",
        },
        {
            title = langTexts.tutorial.oneBagTitle1,
            description = langTexts.tutorial.oneBagDescription1,
            image = "gfx/tutorialOneBag.png",
            width = 405,
            height = 350,
            position = "bottom",
        },
        {
            title = langTexts.tutorial.oneBagTitle2,
            description = langTexts.tutorial.oneBagDescription2,
            image = "gfx/tutorialOneBagScale.png",
            width = 525,
            height = 115,
            position = "bottom",
        },
        {
            title = langTexts.tutorial.unitFrameTitle,
            description = langTexts.tutorial.unitFrameDescription,
            image = "gfx/tutorialUnitFrames.png",
            width = 400,
            height = 46,
            position = "bottom"
        },
        {
            title = langTexts.tutorial.lowerBarTitle,
            description = langTexts.tutorial.lowerBarDescription,
            image = "gfx/tutorialLowerBar.png",
            width = 560,
            height = 22,
            position = "bottom",
        },
        {
            title = langTexts.tutorial.actionBarTitle1,
            description = langTexts.tutorial.actionBarDescription1,
            image = "gfx/tutorialActionBar.png",
            width = 560,
            height = 93,
            position = "bottom",
        },
        {
            title = langTexts.tutorial.actionBarTitle2,
            description = langTexts.tutorial.actionBarDescription2,
            image = "gfx/tutorialMacro.png",
            width = 252,
            height = 180,
            position = "bottom",
        },
        {
            title = langTexts.tutorial.sctTitle,
            description = langTexts.tutorial.sctDescription,
            image = "gfx/tutorialSCT.png",
            width = 429,
            height = 250,
            position = "bottom",
        },
        {
            title = langTexts.tutorial.tooltipTitle,
            description = langTexts.tutorial.tooltipDescription,
            image = "gfx/tutorialTooltip.png",
            width = 182,
            height = 103,
            position = "bottom",
        },
        {
            title = langTexts.tutorial.doneTitle,
            description = langTexts.tutorial.doneDescription
        }
    }

    -- Function to update the tutorial content
    local function updateTutorial()
        local step = steps[currentStep]

        titleText:SetText(step.title)
        descriptionText:SetText(step.description)
        descriptionText:SetWidth(560)

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
                descriptionText:SetWidth(550 - step.width)
            end

            imageFrame:SetVisible(true)
        else
            imageFrame:SetVisible(false)
        end

        prevButton:SetVisible(currentStep > 1)

        if currentStep == #steps then
            nextButton:SetText(langTexts.tutorial.finishButton)
        else
            nextButton:SetText(langTexts.tutorial.nextButton)
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
    internalFunc.tutorial
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
function internalFunc.tutorial()

   if uiElements.tutorialWindow == nil then
        uiElements.tutorialWindow = _createTutorialWindow()
    else
        uiElements.tutorialWindow:reset()
    end

end