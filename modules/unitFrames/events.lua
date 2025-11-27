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
	uiElements.frames["player"]:SetCombat(true)

	uiElements.frames["player.pet"]:SetAlpha(nkUISetup.combatAlpha)
	uiElements.frames["player.target"]:SetAlpha(nkUISetup.combatAlpha)
	uiElements.frames["player.ressourcebar"]:SetVisible(true)

	uiElements.frames["focus"]:SetAlpha(nkUISetup.combatAlpha)

end

local function _fctSecureLeave()
	
	uiElements.frames["player"]:SetAlpha(nkUISetup.nonCombatAlpha)
	uiElements.frames["player"]:SetCombat(false)

	uiElements.frames["player.pet"]:SetAlpha(nkUISetup.nonCombatAlpha)
	uiElements.frames["player.target"]:SetAlpha(nkUISetup.nonCombatAlpha)
	uiElements.frames["player.ressourcebar"]:SetVisible(false)

	uiElements.frames["focus"]:SetAlpha(nkUISetup.nonCombatAlpha)

end

------------------------------ cast bar functions ------------------------------

local function _eventCastBar(_, units) 

	for unitID, state in pairs (units) do			

		local unitTypes = EnKai.unit.getUnitTypes(unitID)

		for _, identifier in pairs (unitTypes) do

			local castBarName = stringFormat("%s.castbar", identifier)
			local thisFrame = uiElements.frames[castBarName]

			if thisFrame then
				if state == true then
					local details = InspectUnitCastbar(unitID)

					thisFrame:SetSpell (details.abilityName)
					thisFrame:SetTimer (details.duration, details.duration)
					thisFrame:SetVisible(true)					

					data[castBarName] = {
						abilityName = details.abilityName,
						duration = details.duration,
						start = InspectTimeReal()
					}
				else
					thisFrame:SetVisible(false)
					data[castBarName] = nil
				end
			end
		end
	end

end

local function _processCastBars () 

	local playerCastBar = data["player.castbar"]

	if playerCastBar then
		local thisFrame = uiElements.frames["player.castbar"]
		local remaining = playerCastBar.duration - (InspectTimeReal() - playerCastBar.start)
		if remaining <= 0 then				
			data["player.castbar"] = nil
			thisFrame:SetVisible(false)
		else				
			thisFrame:SetTimer (remaining, playerCastBar.duration)
		end
	end

	local targetCastBar = data["player.target.castbar"]

	if targetCastBar then
		local thisFrame = uiElements.frames["player.target.castbar"]

		local remaining = targetCastBar.duration - (InspectTimeReal() - targetCastBar.start)
		if remaining <= 0 then				
			data["player.target.castbar"] = nil
			thisFrame:SetVisible(false)
		else				
			thisFrame:SetTimer (remaining, targetCastBar.duration)
		end
	end
end

------------------------------ buff functions ------------------------------

local function _eventBuffAdd(_, unit, buffs)
	
	local groupStatus, groupSize = EnKai.unit.getGroupStatus()

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
				if not stringFind(value, "group") or groupStatus ~= "raid" then
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
				if not stringFind(value, "group") or groupStatus ~= "raid" then
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
			_internal.updateUnit (playerFrame, playerID)
			_internal.processBuffs ()
		end
	end
end

local function _fctRoleEvent (_, thisData)
	
	for unitID, v in pairs(thisData) do
		local unitTypes = EnKai.unit.getUnitTypes (unitID)
		for _, thisType in pairs (unitTypes) do
			local frame = _internal.getFrameByIdentifier(thisType)
			EnKai.unit.GetUnitDetail(unitID, true)
			_internal.updateUnit (frame, unitID)
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

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.uiFramesInitEvents", "Startup", nil) end

	EnKai.unit.subscribe("player")
	EnKai.unit.subscribe("player.target")
	EnKai.unit.subscribe("player.pet")
	EnKai.unit.subscribe("focus")

	for idx = 1, 20, 1 do
		EnKai.unit.subscribe(stringFormat("group%02d", idx))
	end

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
	Command.Event.Attach(Event.Unit.Detail.Role, _fctRoleEvent, "nkUI.Unit.Detail.Role")

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

	local focusID = EnKai.unit.GetUnitByIdentifier ("focus")
	if (focusID) then 
		local frame = uiElements.frames["focus"]
		_internal.updateUnit (frame, focusID) 
		frame:SetVisible(true)
	end


	EnKai.unit.UpdateGroupUnit()

end

function _events.playerAvailable (_, thisInfo, plusInfo)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.playerAvailable", "", thisInfo) end
	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.playerAvailable", "", plusInfo) end

	--print ("_events.playerAvailable")
	--dump (a)
	--dump (b)
	--dump (c)
end

function _events.groupStatus (_, groupType)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.groupStatus", thisInfo, {}) end
	
	if groupType == "group" then
		for idx = 1, 20, 1 do
			local frame = uiElements.frames[stringFormat("raid%02d", idx)]
			frame:SetVisible(false)
		end
	elseif groupType == "raid" then
		for idx = 1, 5, 1 do
			local frame = uiElements.frames[stringFormat("group%02d", idx)]
			frame:SetVisible(false)
		end
	else
		for idx = 1, 20, 1 do
			local frame = uiElements.frames[stringFormat("raid%02d", idx)]
			frame:SetVisible(false)

			if idx <= 5 then
				local frame = uiElements.frames[stringFormat("group%02d", idx)]
				frame:SetVisible(false)
			end
		end
	end
end

function _events.available (_, units)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.available", "", units) end

	if units == nil then return end

	for unitID, identifier in pairs (units) do
		local frame
		
		if stringMatch(identifier, "^group(%d+)$") then
			local groupStatus, groupSize = EnKai.unit.getGroupStatus()

			if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.available", stringFormat("%s %d", groupStatus, groupSize), units) end

			if groupStatus == 'group' then 
				frame = uiElements.frames[identifier] 
			else
				local groupIndex = stringMatch(identifier, "^group(%d+)$")
				frame = uiElements.frames[string.format("raid%s", groupIndex )] 
			end
		else
			frame = uiElements.frames[identifier]
		end		

		if frame then
			_internal.updateUnit (frame, unitID) 
			frame:SetVisible(true)
		end
	end
	
end

function _events.unavailable (_, units)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.unavailable", "units", units) end

	for unitId, _ in pairs (units) do
	
		local unitTypes = EnKai.unit.getUnitTypes (unitId)
		for _, thisType in pairs (unitTypes) do
			local frame = _internal.getFrameByIdentifier(thisType)
			if frame then frame:SetVisible(false) end
		end
	end

end

function _events.change (_, unitID, identifier)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.change", stringFormat("%s %s", unitID, identifier), nil) end
	
	local frame

	if stringMatch(identifier, "^group(%d+)$") then
		-- only process group if group status matches

		local groupStatus, groupSize = EnKai.unit.getGroupStatus()

		if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.change", stringFormat("%s %d", groupStatus, groupSize), {}) end

		if groupStatus == 'group' then 
			frame = uiElements.frames[identifier] 
		else
			local groupIndex = stringMatch(identifier, "^group(%d+)$")
			frame = uiElements.frames[string.format("raid%s", groupIndex)] 
		end
	else
		frame = uiElements.frames[identifier]
	end

	if frame then
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
	else
		if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.change", stringFormat("no frame %s", identifier), nil) end
	end
	
end