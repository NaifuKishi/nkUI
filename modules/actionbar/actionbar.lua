-- @module ActionBar
--
-- This module handles the creation and management of action bars in the UI.
-- It provides functionality for creating different types of action bars, managing their visibility,
-- and handling various events related to abilities and buffs.

local addonInfo, privateVars = ...

-- init namespace

local data = privateVars.data
local uiElements = privateVars.uiElements
local internalFunc = privateVars.internalFunc
local events = privateVars.events

-- Cache frequently used functions and values

local inspectRoleList = Inspect.Role.List
local inspectTimeFrame = Inspect.Time.Frame

local stringFormat = string.format

-- init global variables

data.actionBarsBuild = false
data.abilityMap = {}
data.abilityList = {}
data.gcdActive = false

data.actionBarDesigns = {
    default = { "", "", 40, {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 0}, {xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 1}, {xProportional = 0, yProportional = 0}}, {type = 'solid', r = 0, g = 0, b = 0, a = 1}, {r = 0.153, g = 0.314, b = 0.490, a = 1, thickness = 2 }, false, 0}
}

data.actionBarColors = { mainColor = {r = 0, g = 0, b = 0, a = 1 }, subColor = {r = 0, g = 0, b = 0, a = .5} }

uiElements.actionbars = {}

local context = UI.CreateContext("nkUI.actionbar")
context:SetStrata('hud')
context:SetLayer(2)

-- init local variables

local name = "uiActionBar"

-- @function createActionBar
-- @desc Creates a new action bar with the specified parameters
-- @param thisName (string) The name of the action bar
-- @param rows (number) Number of rows in the action bar
-- @param cols (number) Number of columns in the action bar
-- @param scale (number) Scale factor for the action bar
-- @param barIndex (number) Index of the action bar
-- @return (table) The created action bar object
local function createActionBar(thisName, rows, cols, scale, barIndex)

    local actionButtons = {}
    local buttonSize = data.actionBarDesigns.default[3]
    local spacing = 5
    local width = (cols * buttonSize * scale ) + ((cols -1) * spacing)
    local height = (rows * buttonSize * scale ) + ((rows - 1) * spacing)

    local actionBar = LibEKL.uiCreateFrame("nkFrame", thisName, context)
    
    actionBar:SetWidth(width)
    actionBar:SetHeight(height)
    actionBar:SetBackgroundColor(0,0,0,0)
    actionBar:SetLayer(1)
    actionBar:SetVisible(true)

    local from, object, to, x, y = "TOPLEFT", actionBar, "TOPLEFT", 0, 0

    -- Create action buttons in a grid layout
    for rowIndex = 1, rows, 1 do
        local thisRow = {}
        local firstIcon

        for colIndex = 1, cols, 1 do

            local buttonIndex = ((rowIndex -1) * cols + colIndex)

            local actionButton = uiElements.actionIcon(stringFormat("%s.%d.%d", thisName, rowIndex, colIndex), actionBar, barIndex, buttonIndex)

            if colIndex == 1 then firstIcon = actionButton end

            actionButton:SetPoint(from, object, to, x, y)
            actionButton:SetUsable(true)
            actionButton:SetCooldown()
            actionButton:SetInteractive(interactive, false)
            actionButton:SetDesign("default")
            actionButton:Scale(scale)
            actionButton:SetVisible(true)

            table.insert(thisRow, actionButton)

            to, object, x, y = "TOPRIGHT", actionButton, spacing, 0
        end

        to, object, x, y = "BOTTOMLEFT", firstIcon, 0, spacing

        table.insert(actionButtons, thisRow)
    end

    -- @function actionBar:Populate
    -- @desc Populates the action bar with abilities from the setup
    function actionBar:Populate()
        local barSetup = data.actionBarSetup.roles[Inspect.TEMPORARY.Role()].bars[barIndex]
        
        if barSetup ~= nil then
            local slots = barSetup.slots

            -- Iterate through each button and set its item based on the setup
            for rowIndex = 1, rows, 1 do
                local thisRow = actionButtons[rowIndex]

                for colIndex = 1, cols, 1 do
                    local buttonIndex = ((rowIndex -1) * cols + colIndex)
                    local slotInfo = slots[buttonIndex]
                    
           			if slotInfo ~= nil then
                        if slotInfo.macroCD ~= nil then
                            thisRow[colIndex]:SetItem(slotInfo.itemType, slotInfo.itemKey, slotInfo.macroIcon, slotInfo.macroCD[1], slotInfo.macroCD[2])
                        else
                            thisRow[colIndex]:SetItem(slotInfo.itemType, slotInfo.itemKey, nil)
                        end

                        thisRow[colIndex]:SetUsable(true)
                    else
                        thisRow[colIndex]:ClearItem()
                    end
                end
            end
        end
    end

    -- @function actionBar:Clear
    -- @desc Clears all items from the action bar
    function actionBar:Clear()
        for rowIndex = 1, rows, 1 do
            local thisRow = actionButtons[rowIndex]

            for colIndex = 1, cols, 1 do                
                thisRow[colIndex]:ClearItem()
                thisRow[colIndex]:SetCooldown()
            end
        end
    end

    -- @function actionBar:SetInteractive
    -- @desc Sets the interactive state of the action bar
    -- @param flag (boolean) Whether the action bar should be interactive
    -- @param doUpdate (boolean) Whether to update the UI immediately
    function actionBar:SetInteractive(flag, doUpdate)

        interactive = flag

        for rowIndex = 1, #actionButtons, 1 do
            local thisRow = actionButtons[rowIndex]

            for colIndex = 1, #thisRow, 1 do
                thisRow[colIndex]:SetInteractive(flag, doUpdate)
            end
        end
	end

    function actionBar:ResetStates()

        local barSetup = data.actionBarSetup.roles[Inspect.TEMPORARY.Role()].bars[barIndex]
        
        if barSetup ~= nil then
            local slots = barSetup.slots

            -- Iterate through each button and set its item based on the setup
            for rowIndex = 1, rows, 1 do
                local thisRow = actionButtons[rowIndex]

                for colIndex = 1, cols, 1 do
                    thisRow[colIndex]:CheckState()
                end
            end
        end
    end

    return actionBar

end

-- @function internalFunc.stanceActive
-- @desc Handles the visibility of action bars based on stance
-- @param flag (boolean) Whether to show the stance action bar
function internalFunc.stanceActive(flag)

    local debugId
    if nkDebug then debugId = nkDebug.traceStart(addonInfo.identifier, "internalFunc.stanceActive") end

	if flag then
        uiElements.actionbars.main:SetVisible(false)
        uiElements.actionbars.stance:SetVisible(true)
    else
        uiElements.actionbars.main:SetVisible(true)
        uiElements.actionbars.stance:SetVisible(false)
    end

    if nkDebug then nkDebug.traceEnd(addonInfo.identifier, "internalFunc.stanceActive", debugId) end

end

-- @function internalFunc.uiActionBarInit
-- @desc Initializes the action bars
-- @param flag (boolean) Whether to initialize the action bars
function internalFunc.uiActionBarInit(flag)

    if flag then
        if data.unitFramesBuild then
            for _, v in pairs(uiElements.actionbars) do
                v:SetVisible(true)
            end
        else
            internalFunc.uiActionBars()
        end
    else
        if data.unitFramesBuild then
            for _, v in pairs(uiElements.actionbars) do
                v:SetVisible(false)
            end
        end
    end    

end

-- @function internalFunc.uiActionBars
-- @desc Creates and initializes all action bars
function internalFunc.uiActionBars()

    if data.unitFramesBuild then return end
    if nkUISetup.modules.actionBars.activate == false then return end

    LibEKL.Cooldowns.Init()

    data.actionBarSetup = nkUISetup.modules.actionBars.bars[LibEKL.Unit.getPlayerDetails().name]

    data.defaultBar = { name = stringFormat("bar %d", 1), layer = 1, show = true, interactive = false, vertical = false, trigger = "none", triggerTarget = nil, cols = 12, rows = 1, scale = 100, x = 300, y = 800, outOfCombatAlpha = 100, inCombatAlpha = 100, slots = {}, padding = 0 }
    local roleDesign = { design = 'default', mainColor = {r = 0, g = 0, b = 0, a = 1 }, subColor = {r = 0, g = 0, b = 0, a = 0.5}, hideempty = false, bars = {  } }

    -- Ensure we have enough role designs for all roles
    local count = 0
    
    for _ in pairs(inspectRoleList()) do
        count = count + 1
    end

    if count > #data.actionBarSetup.roles then
        for idx = #data.actionBarSetup.roles + 1, count, 1 do
            local temp = LibEKL.Tools.Table.Copy(roleDesign)
            table.insert(temp.bars, LibEKL.Tools.Table.Copy(data.defaultBar)) -- main bar
            table.insert(temp.bars, LibEKL.Tools.Table.Copy(data.defaultBar)) -- stance bar
            table.insert(temp.bars, LibEKL.Tools.Table.Copy(data.defaultBar)) -- left bar
            table.insert(temp.bars, LibEKL.Tools.Table.Copy(data.defaultBar)) -- right bar
            table.insert(temp.bars, LibEKL.Tools.Table.Copy(data.defaultBar)) -- right screen bar

            table.insert(data.actionBarSetup.roles, temp)
        end
    end
    
    if data.actionBarSetup.roles[Inspect.TEMPORARY.Role()] == nil then return end

    -- Create and position all action bars
    local mainActionBar = createActionBar("nkUI.mainActionBar", nkUISetup.modules.actionBars.mainbars, 12, 1, 1)
    mainActionBar:SetPoint("CENTER", UIParent, "CENTER", nkUISetup.modules.actionBars.x, nkUISetup.modules.actionBars.y)
    mainActionBar:Populate()
    uiElements.actionbars.main = mainActionBar

    local stanceActionBar = createActionBar("nkUI.mainActionBarStance", 2, 12, 1, 2)
    stanceActionBar:SetPoint("CENTER", UIParent, "CENTER", nkUISetup.modules.actionBars.x, nkUISetup.modules.actionBars.y)
    stanceActionBar:Populate()
    stanceActionBar:SetVisible(false)
    uiElements.actionbars.stance = stanceActionBar    

    local leftActionBar = createActionBar("nkUI.leftActionBar", 2, 3, .8, 3)
    leftActionBar:SetPoint("CENTERRIGHT", mainActionBar, "CENTERLEFT", -nkUISetup.modules.actionBars.spacing, 0)
    leftActionBar:SetInteractive(true)
    leftActionBar:Populate()
    uiElements.actionbars.left = leftActionBar

    local rightActionBar = createActionBar("nkUI.rightActionBar", 2, 3, .8, 4)
    rightActionBar:SetPoint("CENTERLEFT", mainActionBar, "CENTERRIGHT", nkUISetup.modules.actionBars.spacing, 0)
    rightActionBar:SetInteractive(true)
    rightActionBar:Populate()
    uiElements.actionbars.right = rightActionBar

    local rightScreenBar = createActionBar("nkUI.rightScreenBar", 12, 1, 1, 5)
    rightScreenBar:SetPoint("CENTER", UIParent, "CENTER", nkUISetup.modules.actionBars.rightBarX, nkUISetup.modules.actionBars.rightBarY)
    rightScreenBar:SetInteractive(true)
    rightScreenBar:Populate()

    rightScreenBar:SetVisible(nkUISetup.modules.actionBars.rightbar)

    uiElements.actionbars.rightScreen = rightScreenBar

    local bars = data.actionBarSetup.roles[Inspect.TEMPORARY.Role()].bars
    
    internalFunc.stanceActive(false)
    
    -- Attach event handlers for role changes
    Command.Event.Attach(Event.TEMPORARY.Role, function()

        -- add a 1 second delay cause of a RIFT bug not providing Ability details properly
        data.abilityMap = {}
        data.abilityList = {}

        mainActionBar:Clear()
        stanceActionBar:Clear()
        leftActionBar:Clear()
        rightActionBar:Clear()
        rightScreenBar:Clear()

        local function populateActionBars()
            mainActionBar:Populate()
            stanceActionBar:Populate()
            leftActionBar:Populate()
            rightActionBar:Populate()
            rightScreenBar:Populate()
        end

        LibEKL.Events.AddInsecure(populateActionBars, inspectTimeFrame(), 2)
    end, "nkUI.TEMPORARY.Role")

    -- Set initial alpha for all action bars
    for _, v in pairs(uiElements.actionbars) do
        v:SetAlpha(nkUISetup.modules.actionBars.nonCombatAlpha)
    end

    -- Attach event handlers for various game events
    Command.Event.Attach(LibEKL.Events["LibEKL.CDManager"].Start, events.abCooldownProcess, "nkUI.LibEKL.CDManager.Start")
    Command.Event.Attach(LibEKL.Events["LibEKL.CDManager"].Update, events.abCooldownProcess, "nkUI.LibEKL.CDManager.Update")
    Command.Event.Attach(LibEKL.Events["LibEKL.CDManager"].Stop, events.abCooldownProcess, "nkUI.LibEKL.CDManager.Stop")

    Command.Event.Attach(Event.Buff.Add, events.abBuffAdd, "nkUI.Buff.Add")
    Command.Event.Attach(Event.Buff.Remove, events.abBuffRemove, "nkUI.Buff.Remove")

    Command.Event.Attach(Event.Ability.New.Usable.False, events.abAbilityUnusable, "nkUI.Ability.New.Usable.False")
    Command.Event.Attach(Event.Ability.New.Usable.True, events.abAbilityUsable, "nkUI.Ability.New.Usable.True")

    Command.Event.Attach(Event.Ability.New.Range.False, events.abAbilityOutOfRange, "nkUI.Ability.New.Range.False")
    Command.Event.Attach(Event.Ability.New.Range.True, events.abAbilityInRange, "nkUI.Ability.New.Range.True")

    Command.Event.Attach(Event.Ability.New.Cooldown.Begin, events.abGcdStart, "nkUI.Ability.New.Cooldown.Begin")

    Command.Event.Attach(Event.System.Secure.Enter, events.abSecureEnter, "nkUI.System.Secure.Enter")
    Command.Event.Attach(Event.System.Secure.Leave, events.abSecureLeave, "nkUI.System.Secure.Leave")

    data.unitFramesBuild = true

end