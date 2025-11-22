local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

-- Cache frequently used functions and values
local InspectBuffList     	= Inspect.Buff.List
local InspectBuffDetail	  	= Inspect.Buff.Detail
local InspectUnitLookup	  	= Inspect.Unit.Lookup
local InspectUnitDetail	  	= Inspect.Unit.Detail
local InspectUnitCastbar	= Inspect.Unit.Castbar
local InspectTimeReal		= Inspect.Time.Real
local InspectSystemWatchdog = Inspect.System.Watchdog

local stringFormat	= string.format
local stringMatch	= string.match
local stringFind	= string.find
local stringSub		= string.sub

local processBuffs	= _internal.processBuffs

------------------------------ combat functions ------------------------------

local function _fctSecureEnter()

	uiElements.frames["player"]:SetAlpha(nkUISetup.combatAlpha)
	uiElements.frames["player.pet"]:SetAlpha(nkUISetup.combatAlpha)
	uiElements.frames["player.target"]:SetAlpha(nkUISetup.combatAlpha)
	uiElements.frames["player.ressourcebar"]:SetVisible(true)

end

local function _fctSecureLeave()
	
	uiElements.frames["player"]:SetAlpha(nkUISetup.nonCombatAlpha)
	uiElements.frames["player.pet"]:SetAlpha(nkUISetup.nonCombatAlpha)
	uiElements.frames["player.target"]:SetAlpha(nkUISetup.nonCombatAlpha)
	uiElements.frames["player.ressourcebar"]:SetVisible(false)

end

------------------------------ cast bar functions ------------------------------

local function _eventCastBar(_, units) 
	for k, v in pairs (units) do			
		if k == data.playerID then
			if v then
				local details = InspectUnitCastbar(data.playerID)

				local thisFrame = uiElements.frames["player.castbar"]
				thisFrame:SetSpell (details.abilityName)
				thisFrame:SetVisible(true)

				data.playerCastbar = {
					abilityName = details.abilityName,
					duration = details.duration,
					start = InspectTimeReal()
				}
			else
				uiElements.frames["player.castbar"]:SetVisible(false)
				data.playerCastbar = nil
			end
		elseif k == data.targetID then
			if v then
				local details = InspectUnitCastbar(data.targetID)

				local thisFrame = uiElements.frames["target.castbar"]
				thisFrame:SetSpell (details.abilityName)
				thisFrame:SetVisible(true)

				data.targetCastbar = {
					abilityName = details.abilityName,
					duration = details.duration,
					start = InspectTimeReal()
				}
			else
				uiElements.frames["target.castbar"]:SetVisible(false)
				data.targetCastbar = nil
			end
		end
	end
end

local function _processCastBars () 

	local playerCastBar = data.playerCastbar

	if playerCastBar then
		local thisFrame = uiElements.frames["player.castbar"]
		local remaining = playerCastBar.duration - (InspectTimeReal() - playerCastBar.start)
		if remaining <= 0 then				
			data.playerCastbar = nil
			thisFrame:SetVisible(false)
		else				
			thisFrame:SetTimer (remaining, playerCastBar.duration)
		end
	end

	local targetCastBar = data.targetCastbar

	if targetCastBar then
		local thisFrame = uiElements.frames["target.castbar"]

		local remaining = targetCastBar.duration - (InspectTimeReal() - targetCastBar.start)
		if remaining <= 0 then				
			data.targetCastbar = nil
			thisFrame:SetVisible(false)
		else				
			thisFrame:SetTimer (remaining, targetCastBar.duration)
		end
	end
end

------------------------------ buff functions ------------------------------

local function _eventBuffAdd(_, unit, buffs)

	print ("eventBuffAdd")

	if nkUISetup.uiFrames.activate == false then return end

	-- Handle player buffs
	if unit == data.playerID and nkUISetup.buffFrame.activate then
		_internal.buffBar.addBuff(unit, buffs)
		_internal.buffBar.UpdateBuffDisplay()
	end

	-- Handle unit frame buffs
	if nkUISetup.buffUnitFrame.activate then
		--print ("_eventBuffAdd")
		--print (unit)
		local identifiers = EnKai.unit.getUnitTypes (unit)

		if #identifiers > 0 then
			for _, value in pairs(identifiers) do
				if not stringFind(value, "raid") then
					local frame = _internal.getFrameByIdentifier(value)
					if frame then frame:addBuff(unit, buffs) end
				end
			end
		end	
		
	end
end

local function _eventBuffChange (_, unit, buffs)
	if nkUISetup.buffFrame.activate == false then return end
end

local function _eventBuffRemove (_, unit, buffs)

	if nkUISetup.uiFrames.activate == false then return end

	if unit == data.playerID and nkUISetup.buffFrame.activate then 
		_internal.buffBar.removeBuff(unit, buffs) 
		_internal.buffBar.UpdateBuffDisplay()
	end

	if nkUISetup.buffUnitFrame.activate then
		local identifiers = EnKai.unit.getUnitTypes (unit)
		if #identifiers > 0 then
			for _, value in pairs(identifiers) do
				if not stringFind(value, "raid") then
					local frame = _internal.getFrameByIdentifier(value)
					if frame then frame:removeBuff(unit, buffs) end
				end
			end
		end	
	end
end

------------------------------ zone functions ------------------------------

local function _fctZoneEvent(_, thisData)

	for k, v in pairs(thisData) do
		if k == data.playerID then
			_internal.processBuffs ()
		end
	end
end

------------------------------ update handler functions ------------------------------

local function _fctUpdateHandler()
	
	-- run always

	local _curTime = InspectTimeReal()
	local _watchDog = InspectSystemWatchdog()
	
	-- run every 60 second
	
	if (_lastUpdate3 == nil or _curTime - _lastUpdate3 >= 60) then
		--_processUnits() -- hopefully this workaround is not needed anymore
		_lastUpdate3 = _curTime
	end
	
	-- run every 0.5 seconds
	
	if (_lastUpdate2 == nil or _curTime - _lastUpdate2 >= .5) then		
		_internal.processBuffs()	
		_lastUpdate2 = _curTime
	end
	
	-- run every 0.05 seconds
	
	if (_lastUpdate3 == nil or _curTime - _lastUpdate3 >= .05) then		
		_processCastBars() 
		_lastUpdate3 = _curTime
	end
	
end

------------------------------ init event system ------------------------------

function _events.uiFramesInitEvents()	

	print ('_events.uiFramesInitEvents')

	EnKai.unit.subscribe("player")
	EnKai.unit.subscribe("player.target")
	EnKai.unit.subscribe("player.pet")

	Command.Event.Attach(EnKai.events["EnKai.Unit"].PlayerAvailable, _events.playerAvailable, "nkUI.EnKai.Unit.PlayerAvailable")
	Command.Event.Attach(EnKai.events["EnKai.Unit"].GroupStatus, _events.groupStatus, "nkUI.EnKai.Unit.GroupStatus")
	Command.Event.Attach(EnKai.events["EnKai.Unit"].Available, _events.available, "nkUI.EnKai.Unit.Available")
	Command.Event.Attach(EnKai.events["EnKai.Unit"].Unavailable, _events.unavailable, "nkUI.EnKai.Unit.Unavailable")
	Command.Event.Attach(EnKai.events["EnKai.Unit"].Change, _events.change, "nkUI.EnKai.Unit.Change")

	--- in combat and out of combat alpha

	Command.Event.Attach(Event.System.Secure.Enter, _fctSecureEnter, "nkUI.Ssytem.Secure.Enter")
	Command.Event.Attach(Event.System.Secure.Leave, _fctSecureLeave, "nkUI.Ssytem.Secure.Leave")

	--- stats changes

	_events.uiFramesInitStatEvents()	

	--- cast bar

	Command.Event.Attach(Event.Unit.Castbar, _eventCastBar, "nkUI.Unit.Castbar")

	--- buf management

    Command.Event.Attach(Event.Buff.Add, _eventBuffAdd, "nkUI.Buff.Add")
	Command.Event.Attach(Event.Buff.Change, _eventBuffChange, "nkUI.Buff.Change")
	Command.Event.Attach(Event.Buff.Remove, _eventBuffRemove, "nkUI.Buff.Remove")

    Command.Event.Attach(Event.System.Update.Begin, _fctUpdateHandler, "nkUI.System.updateHandler")

	Command.Event.Attach(Event.Unit.Detail.Zone, _fctZoneEvent, "nkUI.Unit.Detail.Zone")

	----- initialize player, pet and target -----

	local playerID = EnKai.unit.GetUnitDetail ("player").id

	local playerFrame = uiElements.frames["player"]
	_internal.updateUnit (playerFrame, playerID)
	playerFrame:ContextMenu(playerID)

	uiElements.frames["player.ressourcebar"]:update(playerID)

	local petID = EnKai.unit.GetUnitByIdentifier ("player.pet")	
	if (petID) then 
		local frame = uiElements.frames["player.pet"]
		_internal.updateUnit (frame, petID) 
		frame:ContextMenu(petID)
		frame:SetVisible(true)
	end

	local targetID = EnKai.unit.GetUnitByIdentifier ("player.target")
	if (targetID) then 
		local frame = uiElements.frames["player.target"]
		_internal.updateUnit (frame, targetID) 
		--frame:ContextMenu(targetID)
		frame:SetVisible(true)
	end

end

function _events.playerAvailable (a, b, c)
	print ("_events.playerAvailable")
	dump (a)
	dump (b)
	dump (c)
end

function _events.groupStatus (a, b, c)
	print ("_events.groupStatus")
	dump (a)
	dump (b)
	dump (c)
end

function _events.available (a, b, c)
	print ("_events.available")
	dump (a)
	dump (b)
	dump (c)
end

function _events.unavailable (a, b, c)
	print ("_events.unavailable")
	dump (a)
	dump (b)
	dump (c)
end

function _events.change (_, unitID, identifier)
	
	print ("ok => _events.change")
	--print (unitID, identifier)

	local frame = uiElements.frames[identifier]

	if unitID == false then
		frame:SetVisible(false)
		frame:SetUnitID(nil)
		frame:ClearBuffs()
	else		
		if frame then
			_internal.updateUnit (frame, unitID) 
			frame:SetVisible(true)
		end
	end
	
end