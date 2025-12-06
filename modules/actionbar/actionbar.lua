local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

local InspectRoleList = Inspect.Role.List

---------- init global variables ---------

data.actionBarsBuild = false
uiElements.actionbars = {}
data.abilityMap = {}
data.abilityList = {}
data.gcdActive = false

local stringFormat				= string.format

---------- init local variables ---------

local name = "uiActionBar"

data.actionBarDesigns = {
	default     = { "", "", 40, {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 0}, {xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 1}, {xProportional = 0, yProportional = 0}}, {type = 'solid', r = 0, g = 0, b = 0, a = 1}, {r = 0.153, g = 0.314, b = 0.490, a = 1, thickness = 2 }, false, 0}
}

data.actionBarColors = { mainColor = {r = 0, g = 0, b = 0, a = 1 }, subColor = {r = 0, g = 0, b = 0, a = .5} }

local function _actionBar (thisName, rows, cols, scale, barIndex)

    local actionButtons = {}
    local buttonSize = data.actionBarDesigns.default[3]
    local spacing = 5
    local width = (cols * buttonSize * scale ) + ((cols -1) * spacing)
    local height = (rows * buttonSize * scale ) + ((rows - 1) * spacing)

    local actionBar = EnKai.uiCreateFrame("nkFrame", thisName, uiElements.contextLowest)
    
    actionBar:SetWidth (width)
    actionBar:SetHeight (height)
    actionBar:SetBackgroundColor(0,0,0,0)
    actionBar:SetLayer(1)
    actionBar:SetVisible(true)

    local from, object, to, x, y = "TOPLEFT", actionBar, "TOPLEFT", 0, 0

    for rowIndex = 1, rows, 1 do
        local thisRow = {}
        local firstIcon

        for colIndex = 1, cols, 1 do

            local buttonIndex = ((rowIndex -1) * cols + colIndex)

            local actionButton =  uiElements.actionIcon(stringFormat("%s.%d.%d", thisName, rowIndex, colIndex), actionBar, barIndex, buttonIndex)

            if colIndex == 1 then firstIcon = actionButton end

            actionButton:SetPoint(from, object, to, x, y)
            actionButton:SetUsable(true)
			actionButton:SetCooldown()
          	actionButton:SetInteractive(interactive, false)
            actionButton:SetDesign("default")
            actionButton:Scale(scale)
            actionButton:SetVisible(true)

            table.insert (thisRow, actionButton)

            to, object, x, y = "TOPRIGHT", actionButton, spacing, 0
        end

        to, object, x, y = "BOTTOMLEFT", firstIcon, 0, spacing

        table.insert (actionButtons, thisRow)
    end

    function actionBar:Populate()
        local barSetup = data.actionBarSetup.roles[Inspect.TEMPORARY.Role()].bars[barIndex]
        
        if barSetup ~= nil then
            local slots = barSetup.slots

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
                    else
                        thisRow[colIndex]:ClearItem()
                    end
                end
            end
        end
    end

    function actionBar:SetInteractive(flag, doUpdate)

        interactive = flag

        for rowIndex = 1, #actionButtons, 1 do
            local thisRow = actionButtons[rowIndex]

            for colIndex = 1, #thisRow, 1 do
                thisRow[colIndex]:SetInteractive(flag, doUpdate)
            end
        end
	end

    return actionBar

end

function _internal.stanceActive (flag)

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_internal.stanceActive") end

	if flag then
        uiElements.actionbars.main:SetVisible(false)
        uiElements.actionbars.stance:SetVisible(true)
    else
        uiElements.actionbars.main:SetVisible(true)
        uiElements.actionbars.stance:SetVisible(false)
    end

	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_internal.stanceActive", debugId) end
	
end

function _internal.uiActionBarInit(flag)

    if flag then
        if data.unitFramesBuild then
            for k, v in pairs (uiElements.actionbars) do
                v:SetVisible(true)
            end
        else
            _internal.uiActionBars()
        end
    else
        if data.unitFramesBuild then
            for k, v in pairs (uiElements.actionbars) do
                v:SetVisible(false)
            end
        end
    end    

end

function _internal.uiActionBars()

    if data.unitFramesBuild then return end
    if nkUISetup.modules.actionBars.activate == false then return end

    EnKai.cdManager.init()

    data.actionBarSetup = nkUISetup.modules.actionBars.bars[EnKai.unit.getPlayerDetails().name]

    data.defaultBar = { name = stringFormat("bar %d", 1), layer = 1, show = true, interactive = false, vertical = false, trigger = "none", triggerTarget = nil, cols = 12, rows = 1, scale = 100, x = 300, y = 800, outOfCombatAlpha = 100, inCombatAlpha = 100, slots = {}, padding = 0 }
    local _roleDesign = { design = 'default', mainColor = {r = 0, g = 0, b = 0, a = 1 }, subColor = {r = 0, g = 0, b = 0, a = 0.5}, hideempty = false, bars = {  } }

    local count = 0
	
	for k, v in pairs(InspectRoleList()) do
		count = count + 1
	end

	if count > #data.actionBarSetup.roles then
		for idx = #data.actionBarSetup.roles + 1, count, 1 do
			local temp = EnKai.tools.table.copy(_roleDesign)
			table.insert(temp.bars, EnKai.tools.table.copy(data.defaultBar)) -- main bar
            table.insert(temp.bars, EnKai.tools.table.copy(data.defaultBar)) -- stance bar
            table.insert(temp.bars, EnKai.tools.table.copy(data.defaultBar)) -- left bar
            table.insert(temp.bars, EnKai.tools.table.copy(data.defaultBar)) -- right bar
            table.insert(temp.bars, EnKai.tools.table.copy(data.defaultBar)) -- right screen bar

			table.insert(data.actionBarSetup.roles, temp)
		end
	end
	
	if data.actionBarSetup.roles[Inspect.TEMPORARY.Role()] == nil then return end    

    local mainActionBar = _actionBar("nkUI.mainActionBar", 2, 12, 1, 1)
    mainActionBar:SetPoint ("CENTER", UIParent, "CENTER", nkUISetup.modules.actionBars.x, nkUISetup.modules.actionBars.y)
    mainActionBar:Populate()
    uiElements.actionbars.main = mainActionBar
    
    local stanceActionBar = _actionBar("nkUI.mainActionBarStance", 2, 12, 1, 2)
    stanceActionBar:SetPoint ("CENTER", UIParent, "CENTER", nkUISetup.modules.actionBars.x, nkUISetup.modules.actionBars.y)
    stanceActionBar:Populate()
    stanceActionBar:SetVisible(false)
    uiElements.actionbars.stance = stanceActionBar    

    local leftActionBar = _actionBar("nkUI.leftActionBar", 2, 3, .8, 3)
    leftActionBar:SetPoint ("CENTERRIGHT", mainActionBar, "CENTERLEFT", -nkUISetup.modules.actionBars.spacing, 0)
    leftActionBar:SetInteractive(true)
    leftActionBar:Populate()
    uiElements.actionbars.left = leftActionBar

    local rightActionBar = _actionBar("nkUI.rightActionBar", 2, 3, .8, 4)
    rightActionBar:SetPoint ("CENTERLEFT", mainActionBar, "CENTERRIGHT", nkUISetup.modules.actionBars.spacing, 0)
    rightActionBar:SetInteractive(true)
    rightActionBar:Populate()
    uiElements.actionbars.right = rightActionBar

    local rightScreenBar = _actionBar("nkUI.rightScreenBar", 12, 1, 1, 5)
    rightScreenBar:SetPoint ("CENTER", UIParent, "CENTER", nkUISetup.modules.actionBars.rightBarX, nkUISetup.modules.actionBars.rightBarY)
    rightScreenBar:SetInteractive(true)
    rightScreenBar:Populate()
    uiElements.actionbars.rightScreen = rightScreenBar

    local bars = data.actionBarSetup.roles[Inspect.TEMPORARY.Role()].bars
		
	_internal.stanceActive (false)
	
    Command.Event.Attach(Event.TEMPORARY.Role, function ()
        mainActionBar:Populate()
        stanceActionBar:Populate()
        leftActionBar:Populate()
        rightActionBar:Populate()
        rightScreenBar:Populate()
    end, "nkUI.TEMPORARY.Role")

    for k, v in pairs (uiElements.actionbars) do
        v:SetAlpha(nkUISetup.modules.actionBars.nonCombatAlpha)
    end

    Command.Event.Attach(EnKai.events["EnKai.CDManager"].Start, _events.abCooldownProcess, "nkUI.EnKai.CDManager.Start")
    Command.Event.Attach(EnKai.events["EnKai.CDManager"].Update, _events.abCooldownProcess, "nkUI.EnKai.CDManager.Update")
    Command.Event.Attach(EnKai.events["EnKai.CDManager"].Stop, _events.abCooldownProcess, "nkUI.EnKai.CDManager.Stop")

    Command.Event.Attach(Event.Buff.Add, _events.abBuffAdd, "nkUI.Buff.Add")
	Command.Event.Attach(Event.Buff.Remove, _events.abBuffRemove, "nkUI.Buff.Remove")

    Command.Event.Attach(Event.Ability.New.Usable.False, _events.abAbilityUnusable, "nkUI.Ability.New.Usable.False")
    Command.Event.Attach(Event.Ability.New.Usable.True, _events.abAbilityUsable, "nkUI.Ability.New.Usable.True")

    Command.Event.Attach(Event.Ability.New.Range.False, _events.abAbilityOutOfRange, "nkUI.Ability.New.Range.False")
    Command.Event.Attach(Event.Ability.New.Range.True, _events.abAbilityInRange, "nkUI.Ability.New.Range.True")

    Command.Event.Attach(Event.Ability.New.Cooldown.Begin , _events.abGcdStart, "nkUI.Ability.New.Cooldown.Begin")

    Command.Event.Attach(Event.System.Secure.Enter, _events.abSecureEnter, "nkUI.System.Secure.Enter")
    Command.Event.Attach(Event.System.Secure.Leave, _events.abSecureLeave, "nkUI.System.Secure.Leave")

    data.unitFramesBuild = true

end