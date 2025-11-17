local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

---------- init local variables ---------

local oInspectSystemSecure = Inspect.System.Secure

local _roleDesign = { design = 'default', mainColor = {r = 0.153, g = 0.314, b = 0.490, a = 1 }, subColor = {r = 0, g = 0, b = 0}, hideempty = false, bars = {  } }

---------- init variables ---------

data.moveableBars = false
data.insecure = {}

data.designs = {
	default     = { "", "", 50, {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 0}, {xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 1}, {xProportional = 0, yProportional = 0}}, {type = 'solid', r = 0, g = 0, b = 0, a = 1}, {r = 0.153, g = 0.314, b = 0.490, a = 1, thickness = 2 }, false, 0},
	round		= { "", "", 50, {{xProportional = 0.5, yProportional = 0}, 
                  {xProportional = 1, yProportional = 0.5, xControlProportional = (61/64), yControlProportional = (3/64)},
                  {xProportional = 0.5, yProportional = 1, xControlProportional = (61/64), yControlProportional = (61/64)},
                  {xProportional = 0, yProportional = 0.5, xControlProportional = (3/64), yControlProportional = (61/64)},
                  {xProportional = 0.5, yProportional = 0, xControlProportional = (3/64), yControlProportional = (3/64)}}, 
				  {type = 'solid', r = 0, g = 0, b = 0, a = 1}, {r = 0.153, g = 0.314, b = 0.490, a = 1, thickness = 3 }, true, 5},
	circleYellow= { "nkHelios", "gfx/circleCenterYellow.png", 50, {{xProportional = 0.5, yProportional = 0}, 
                  {xProportional = 1, yProportional = 0.5, xControlProportional = (61/64), yControlProportional = (3/64)},
                  {xProportional = 0.5, yProportional = 1, xControlProportional = (61/64), yControlProportional = (61/64)},
                  {xProportional = 0, yProportional = 0.5, xControlProportional = (3/64), yControlProportional = (61/64)},
                  {xProportional = 0.5, yProportional = 0, xControlProportional = (3/64), yControlProportional = (3/64)}}, 
				  {type = 'solid', r = 0, g = 0, b = 0, a = 1}, {r = 0, g = 0, b = 0, a = 0, thickness = 5 }, true, 5},
	circleBlue	= { "nkHelios", "gfx/circleCenterBlue.png", 50, {{xProportional = 0.5, yProportional = 0}, 
                  {xProportional = 1, yProportional = 0.5, xControlProportional = (61/64), yControlProportional = (3/64)},
                  {xProportional = 0.5, yProportional = 1, xControlProportional = (61/64), yControlProportional = (61/64)},
                  {xProportional = 0, yProportional = 0.5, xControlProportional = (3/64), yControlProportional = (61/64)},
                  {xProportional = 0.5, yProportional = 0, xControlProportional = (3/64), yControlProportional = (3/64)}}, 
				  {type = 'solid', r = 0, g = 0, b = 0, a = 1}, {r = 0, g = 0, b = 0, a = 0, thickness = 5 }, true, 5},
	circleRed	= { "nkHelios", "gfx/circleCenterRed.png", 50, {{xProportional = 0.5, yProportional = 0}, 
                  {xProportional = 1, yProportional = 0.5, xControlProportional = (61/64), yControlProportional = (3/64)},
                  {xProportional = 0.5, yProportional = 1, xControlProportional = (61/64), yControlProportional = (61/64)},
                  {xProportional = 0, yProportional = 0.5, xControlProportional = (3/64), yControlProportional = (61/64)},
                  {xProportional = 0.5, yProportional = 0, xControlProportional = (3/64), yControlProportional = (3/64)}}, 
				  {type = 'solid', r = 0, g = 0, b = 0, a = 1}, {r = 0, g = 0, b = 0, a = 0, thickness = 5 }, true, 5},
	circleGreen	= { "nkHelios", "gfx/circleCenterGreen.png", 50, {{xProportional = 0.5, yProportional = 0}, 
                  {xProportional = 1, yProportional = 0.5, xControlProportional = (61/64), yControlProportional = (3/64)},
                  {xProportional = 0.5, yProportional = 1, xControlProportional = (61/64), yControlProportional = (61/64)},
                  {xProportional = 0, yProportional = 0.5, xControlProportional = (3/64), yControlProportional = (61/64)},
                  {xProportional = 0.5, yProportional = 0, xControlProportional = (3/64), yControlProportional = (3/64)}}, 
				  {type = 'solid', r = 0, g = 0, b = 0, a = 1}, {r = 0, g = 0, b = 0, a = 0, thickness = 5 }, true, 5},
	circleCyan	= { "nkHelios", "gfx/circleCenterCyan.png", 50, {{xProportional = 0.5, yProportional = 0}, 
                  {xProportional = 1, yProportional = 0.5, xControlProportional = (61/64), yControlProportional = (3/64)},
                  {xProportional = 0.5, yProportional = 1, xControlProportional = (61/64), yControlProportional = (61/64)},
                  {xProportional = 0, yProportional = 0.5, xControlProportional = (3/64), yControlProportional = (61/64)},
                  {xProportional = 0.5, yProportional = 0, xControlProportional = (3/64), yControlProportional = (3/64)}}, 
				  {type = 'solid', r = 0, g = 0, b = 0, a = 1}, {r = 0, g = 0, b = 0, a = 0, thickness = 5 }, true, 5}
}

---------- local function block ---------

local function _showUI()

	EnKai.inventory.updateDB ()

	local bars = data.setup.roles[Inspect.TEMPORARY.Role()].bars
	for idx = 1, #bars, 1 do
		if uiElements.bars[idx] ~= nil then 
			uiElements.bars[idx]:SetVisible(true) 
			uiElements.bars[idx]:SetAlpha(1)
		end
	end

end

function _internal.actionbars()

	EnKai.inventory.init ()
	EnKai.cdManager.init()
	EnKai.unit.init()

	_internal.buildActionBars()

	Command.Event.Attach(Event.TEMPORARY.Role, _internal.buildActionBars, "nkUI.actionbar.TEMPORARY.Role")
	
	Command.Event.Attach(Event.TEMPORARY.Role, _internal.buildActionBars, "nkUI.actionbar.TEMPORARY.Role")

	Command.Event.Attach(EnKai.events["EnKai.CDManager"].Start, _events.cooldownProcess, "nkUI.actionbar.EnKai.CDManager.Start")
	Command.Event.Attach(EnKai.events["EnKai.CDManager"].Update, _events.cooldownProcess, "nkUI.actionbar.EnKai.CDManager.Update")
	Command.Event.Attach(EnKai.events["EnKai.CDManager"].Stop, _events.cooldownProcess, "nkUI.actionbar.EnKai.CDManager.Stop")

	--Command.Event.Attach(EnKai.events["EnKai.Unit"].PlayerAvailable, _internal.buildActionBars, "nkUI.actionbar.EnKai.Unit.PlayerAvailable")

	Command.Event.Attach(Event.Ability.New.Usable.False, _events.abilityUnusable, "nkUI.actionbar.Ability.New.Usable.False")
	Command.Event.Attach(Event.Ability.New.Usable.True, _events.abilityUsable, "nkUI.actionbar.Ability.New.Usable.True")

	Command.Event.Attach(Event.Ability.New.Range.False, _events.abilityOutOfRange, "nkUI.actionbar.Ability.New.Range.False")
	Command.Event.Attach(Event.Ability.New.Range.True, _events.abilityInRange, "nkUI.actionbar.Ability.New.Range.True")

	Command.Event.Attach(Event.Buff.Add, _events.buffAdd, "nkUI.actionbar.Buff.Add")
	Command.Event.Attach(Event.Buff.Remove, _events.buffRemove, "nkUI.actionbar.Buff.Remove")

	Command.Event.Attach(Event.Ability.New.Cooldown.Begin , _events.gcdStart, "EnKai.cdManager.Ability.New.Cooldown.Begin")

	Command.Event.Attach(Event.System.Secure.Enter, _events.secureEnter, "nkUI.actionbar.System.Secure.Enter")
	Command.Event.Attach(Event.System.Secure.Leave, _events.secureLeave, "nkUI.actionbar.System.Secure.Leave")

end

function _internal.buildActionBars()

	if Inspect.TEMPORARY.Role() == nil then return end
	
	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_internal.buildActionBars") end

	--local count = 0
	
	--for k, v in pairs(Inspect.Role.List()) do
	--	count = count + 1
	--end

	--if count > #data.setup.roles then
	--	for idx = #data.setup.roles + 1, count, 1 do
	--		local temp = EnKai.tools.table.copy(_roleDesign)
	--		table.insert(temp.bars, EnKai.tools.table.copy(data.defaultBar))
	--		table.insert(data.setup.roles, temp)
	--	end
	--end
	
	--if data.setup.roles[Inspect.TEMPORARY.Role()] == nil then return end

	--local bars = data.setup.roles[Inspect.TEMPORARY.Role()].bars
	
	if uiElements.bars == nil then uiElements.bars = {} end
	
	data.abilityMap = {}
	data.abilityList = {}
	data.gcdActive = false
	
	for idx = 1, #bars, 1 do
	
		local thisBar
	
		if #uiElements.bars < idx then
			thisBar = _internal.uiActionBar("actionBar" .. idx, uiElements.context, idx, false)
			table.insert(uiElements.bars, thisBar)
		else
			thisBar = uiElements.bars[idx]
			thisBar:SetInteractive(bars[idx].interactive, false)
		end
		
		local _func = function()
			thisBar:SetLayer(bars[idx].layer or 1)
			thisBar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", bars[idx].x, bars[idx].y)
			thisBar:ReDraw()
			thisBar:SetMoveable(data.moveableBars)
			thisBar:SetVisible(true)
		end
		
		if oInspectSystemSecure() == true then
			table.insert(data.insecure, _func)
		else
			_func()
		end
		
	end
	
	_internal.stanceActive (false)
	
	if #bars < #uiElements.bars then
		for idx = #bars + 1, #uiElements.bars, 1 do
			uiElements.bars[idx]:SetVisible(false)
		end
	end
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_internal.buildActionBars", debugId) end
	
end

function _internal.stanceActive (flag)

	if uiElements.config ~= nil and uiElements.config:GetVisible() == true then return end
	
	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_internal.stanceActive") end

	local bars = data.setup.roles[Inspect.TEMPORARY.Role()].bars
	
	for idx = 1, #bars, 1 do
		if bars[idx].trigger == "stance" then			
			if flag == true then
				uiElements.bars[idx]:SetVisible(false)
				if uiElements.bars[bars[idx].triggerTarget] ~= nil then uiElements.bars[bars[idx].triggerTarget]:SetVisible(true) end
				
				if bars[bars[idx].triggerTarget] ~= nil and uiElements.bars[bars[idx].triggerTarget]:GetSecureMode() ~= 'restricted' then
					if not Inspect.System.Secure() then
						uiElements.bars[bars[idx].triggerTarget]:SetAlpha((bars[bars[idx].triggerTarget].outOfCombatAlpha or 100) / 100)
					else
						uiElements.bars[bars[idx].triggerTarget]:SetAlpha((bars[bars[idx].triggerTarget].inCombatAlpha or 100) / 100)
					end
				end
				
			else
				uiElements.bars[idx]:SetVisible(true)
				if uiElements.bars[bars[idx].triggerTarget] ~= nil then uiElements.bars[bars[idx].triggerTarget]:SetVisible(false) end
				
			end
		end
	end

	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_internal.stanceActive", debugId) end
	
end

function _internal.combatHandler (flag)

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_internal.combatHandler") end

	local bars = data.setup.roles[Inspect.TEMPORARY.Role()].bars
	
	for idx = 1, #bars, 1 do
		if uiElements.bars[idx]:GetSecureMode() ~= 'restricted' then
	
			if bars[idx].trigger == "hideincombat" then
				uiElements.bars[idx]:SetVisible(flag)
			end
			
			if flag then
				uiElements.bars[idx]:SetAlpha((bars[idx].outOfCombatAlpha or 100) / 100)
			else
				uiElements.bars[idx]:SetAlpha((bars[idx].inCombatAlpha or 100) / 100)
			end
		end
		
	end
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_internal.combatHandler", debugId) end

end

