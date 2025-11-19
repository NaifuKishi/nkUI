local addonInfo, privateVars = ...

---------- init namespace ---------

local data      = privateVars.data
local uiElements= privateVars.uiElements
local _internal = privateVars.internal
local _events   = privateVars.events
local oFuncs    = privateVars.oFuncs

---------- init local variables ---------

local name = "settings"

---------- init variables ---------

---------- init local function ---------

local function _subTutorialUnitframes(parent)

    local buffsCheckbox, buffsUnitBarCheckbox

    local name = "nkUI.tutorialWindow.unitframes"

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    frame:SetVisible(false)

    local activateCheckbox = EnKai.uiCreateFrame("nkCheckbox", name .. ".activateCheckbox", frame)
    activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 5)
    activateCheckbox:SetText("Activate this module")
    activateCheckbox:SetChecked(nkUISetup.uiFrames.activate)
    activateCheckbox:SetLabelWidth(250)
    activateCheckbox:SetFontSize(16)
    activateCheckbox:SetColor (1,1,1,1)

    Command.Event.Attach(EnKai.events[name .. '.activateCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.uiFrames.activate = newValue
        buffsCheckbox:SetActive(newValue)
        buffsUnitBarCheckbox:SetActive(newValue)

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
    buffsCheckbox:SetColor (1,1,1,1)
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
    buffsUnitBarCheckbox:SetColor (1,1,1,1)
    buffsUnitBarCheckbox:SetActive(nkUISetup.uiFrames.activate)

    Command.Event.Attach(EnKai.events[name .. '.buffsUnitBarCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.buffUnitFrame.activate = newValue
        if newValue == false then 
            _internal.uiFramesRemoveBuffs()
        else
            _internal.uiFramesLoadAllBuffs()
        end
    end, name .. '.buffsUnitBarCheckbox.CheckboxChanged')

    return frame

end

local function _subTutorialLowerBar(parent)

    local name = "nkUI.tutorialWindow.lowerBar"

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    frame:SetVisible(false)

    local activateCheckbox = EnKai.uiCreateFrame("nkCheckbox", name .. ".activateCheckbox", frame)
    activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 5)
    activateCheckbox:SetText("Activate this module")
    activateCheckbox:SetChecked(nkUISetup.lowerBar.activate)
    activateCheckbox:SetLabelWidth(200)
    activateCheckbox:SetFontSize(16)

    Command.Event.Attach(EnKai.events[name .. '.activateCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.lowerBar.activate = newValue
        _internal.lowerBarInit (newValue)
    end, name .. '.activateCheckbox.CheckboxChanged')

    return frame

end

local function _subTutorialTooltip(parent)

    local name = "nkUI.tutorialWindow.tooltip"

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    frame:SetVisible(false)

    local activateCheckbox = EnKai.uiCreateFrame("nkCheckbox", name .. ".activateCheckbox", frame)
    activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 5)
    activateCheckbox:SetText("Activate this module")
    activateCheckbox:SetChecked(nkUISetup.tooltip.activate)
    activateCheckbox:SetLabelWidth(200)
    activateCheckbox:SetFontSize(16)

    Command.Event.Attach(EnKai.events[name .. '.activateCheckbox'].CheckboxChanged, function (_, newValue)		
        nkUISetup.tooltip.activate = newValue
        if (newValue == true) then _internal.tooltip() end
    end, name .. '.activateCheckbox.CheckboxChanged')

    return frame

end

local function _createTutorialWindow()

    local name = "nkUI.tutorialWindow"

    -- Create the main tutorial window
    local tutorialWindow = EnKai.uiCreateFrame("nkWindowMetro", "nkUI.tutorialWindow", uiElements.contextTop)
    tutorialWindow:SetTitle("nkUI Setup")
    tutorialWindow:SetWidth(600)
    tutorialWindow:SetHeight(600)
    tutorialWindow:SetPoint("CENTER", UIParent, "CENTER")
    tutorialWindow:SetShadow(true)
    tutorialWindow:SetWindowColor(0, 0, 0, .6)


    -- Create content frame
    local content = tutorialWindow:GetContent()

    -- Current step tracker
    local currentStep = 1

    -- Create UI elements for the tutorial
    local titleText = EnKai.uiCreateFrame("nkText", "tutorialTitle", content)
    titleText:SetPoint("TOPLEFT", content, "TOPLEFT", 20, 20)
    titleText:SetFontSize(20)
    titleText:SetFontColor(1, 1, 1, 1)

    local descriptionText = EnKai.uiCreateFrame("nkText", "tutorialDescription", content)
    descriptionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, 20)
    descriptionText:SetWordwrap(true)
    descriptionText:SetWidth(560)
    descriptionText:SetFontSize(16)
    descriptionText:SetFontColor(0.8, 0.8, 0.8, 1)

    -- Create a frame for displaying subframes
    local subFrameContainer = EnKai.uiCreateFrame("nkFrame", "nkUI.tutorialWindow.subFrameContainer", content)
    subFrameContainer:SetPoint("TOPLEFT", descriptionText, "BOTTOMLEFT", 0, 10)
    subFrameContainer:SetHeight(560)
    subFrameContainer:SetHeight(500)
    subFrameContainer:SetVisible(false)

    local imageFrame = EnKai.uiCreateFrame("nkTexture", "tutorialImage", content)
    --imageFrame:SetPoint("BOTTOMCENTER", content, "BOTTOMCENTER", 0, -75)

    -- Navigation buttons
    local prevButton = EnKai.uiCreateFrame("nkButtonMetro", "prevButton", content)
    prevButton:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 20, -20)
    prevButton:SetText("Previous")
    prevButton:SetWidth(100)

    local nextButton = EnKai.uiCreateFrame("nkButtonMetro", "nextButton", content)
    nextButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, -20)
    nextButton:SetText("Next")
    nextButton:SetWidth(100)

-- Create tutorial steps
    local steps = {
        {
            title = "Welcome to nkUI",
            description = "Welcome to nkUI and thank you for trying out my addon.\n\nThis tutorial will guide you through the basic features of nkUI. Please be aware that this is a work in progress and not all features are fully implemented yet.",
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
            title = "Tooltip module",
            description = "This nkUI module shows a tooltip for units which does look a lot better than the standard tooltip. Unfortunately due to API restrictions it's not possible to display quest information for NPC. There fore sometimes the tooltip will be bigger than neccessary. I'll try to figure out something here in the upcoming weeks.",
            image = "gfx/tutorialTooltip.png",
            width = 182,
            height = 103,
            position = "right",
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

    -- Initialize the tutorial
    updateTutorial()

    return tutorialWindow
end

function _internal.tutorial()

    -- Add the tutorial to the UI elements
    if uiElements.tutorialWindow == nil then
        uiElements.tutorialWindow = _createTutorialWindow()
    else
        uiElements.tutorialWindow:reset()
    end
    
end
