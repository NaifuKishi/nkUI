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

---------- init local variables ---------

local _lastUpdate1, _lastUpdate2, _lastUpdate3
local _eventsP1Index = 1
local _eventsS1Index = 1
local _eventsRemIndex = 1

local _isRaid = false
local _isGroup = false
local _groupMembers = 0
local _raidMembers = 0

---------- init variables ---------

data.playerCastbar = nil
data.targetCastbar = nil
data.groupIDs = {}
data.groupPetIDs = {}

data.identifierToUnit = {}
data.mouseoverID = nil

---------- local function block ---------

local function _getIdentifier (unit)
	local returnValue = {}

	for identifier, thisUnit in pairs (data.identifierToUnit) do
		if thisUnit == unit then
			table.insert(returnValue, identifier)
		end
	end

	return returnValue
end

local function _trackUnit (identifier, unit)	

	if stringMatch(identifier, "^group%d%d%.pet$") then return end

	if stringFind(identifier, 'group') and isRaid then
		local groupId = stringSub(identifier, 6, 7)
		identifier = stringFormat("raid%02d", groupId)
	end

	--print ("track unit " .. identifier)
	local frame = uiElements.frames[identifier]

	if frame then

		data.identifierToUnit[identifier] = unit

		local playerUnit = data.identifierToUnit["player"]
		local petUnit = data.identifierToUnit["player.pet"]

		frame:SetUnitID (unit)
		frame:ProcessUnitDetails(unit)
		frame:SetVisible(true)
		frame:ContextMenu(unit)
	else
		--print ("_trackUnit: frame not found")
		--print (identifier)
	end
end

local function _untrackUnit (identifier, unit)

	--print ("untrackUnit")
	--print (identifier)

	if stringMatch(identifier, "^group%d%d%.pet$") then return end

	if stringFind(identifier, 'group') and isRaid then
		local groupId = stringSub(identifier, 6, 7)
		identifier = stringFormat("raid%02d", groupId)
	end

	local frame = uiElements.frames[identifier]

	if frame then		

		frame:SetUnitID (nil)
		frame:SetVisible(false)
		frame:ContextMenu(nil)
		frame:ClearBuffs()

		local playerUnit = data.identifierToUnit["player"]
		local petUnit = data.identifierToUnit["player.pet"]

		data.identifierToUnit[identifier] = nil
	else
		--print ("_untrackUnit: frame not found")
		--print (identifier)
	end
end

local function _eventUnitAdd(_, info)

	--dump (info)
	
	for unit, thisData in pairs(info) do		
		if type(thisData) ~= "string" then
			-- Ignore events like mouseover where there is no identifier (thisData == false)
		elseif thisData == "mouseover" then
			data.mouseoverID = unit
		else
			--print ( unit, thisData)
			_trackUnit (thisData, unit)
		end
	end
end

local function _getUnitFrame(identifier)
	--print ("_getUntiFrame", identifier)
	return uiElements.frames[identifier]
end

local function _eventUnitRemove(_, info)

	--print ("_eventUnitRemove")
	--dump (info)
	
	for unit, thisData in pairs(info) do		
		if thisData == false then
			local identifiers = _getIdentifier (unit)
			if #identifiers > 0 then
				for idx = 1, #identifiers, 1 do
					_untrackUnit (identifiers[idx], unit)
				end
			end
		else			
			if identifier and identifier == "player.target" then
				--print "player.target"
				_untrackUnit (thisData, unit)
			end

			_trackUnit (thisData, unit)
		end
	end
end

local function _eventUnitChange (_, unit, unitType)

	--print ("_eventUnitChange")
	--print (unit, unitType)

	if unit == false then
		local unitID = data.identifierToUnit[unitType]
		--print (unitID)
		if unitID then _eventUnitRemove(_, {[unitID] = "player.target"}) end
	else
		_eventUnitAdd(_, {[unit] = unitType})
	end
end

local function checkGroupSize (unitType)

	if stringFind(unitType, 'group') == 1 and stringFind (unitType, 'group..%.') == nil then
		local indicateGroupChange = false
	
		local groupId = stringSub(unitType, 6, 7)

		if tonumber(groupId) > 5 then
			if _isRaid == false then 
				indicateGroupChange = true
				_groupMembers = 0
				_raidMembers = 0
			end
			
			_isRaid = true
			_isGroup = false
		elseif _isRaid == false then
			if _isGroup == false then 
				_groupMembers = 0
				_raidMembers = 0
				indicateGroupChange = true 
			end
			
			_isGroup = true
		end
				
		local backupGroupCount, backupRaidCount = _groupMembers, _raidMembers
		
		if _isRaid == true then
		
			_raidMembers = 0
			
			for idx = 1, 20, 1 do
				if data.identifierToUnit[stringFormat('raid%02d', idx)] ~= nil then _raidMembers = _raidMembers + 1 end
			end
			
			if _raidMembers == 0 then _isRaid = false end
			
		elseif _isGroup == true then
		
			_groupMembers = 0
			
			for idx = 1, 5, 1 do
				if data.identifierToUnit[stringFormat('group%02d', idx)] ~= nil then _groupMembers = _groupMembers + 1 end
			end
			
			if _groupMembers == 0 then _isGroup = false end
			
		end
		
		--if indicateGroupChange == true or backupGroupCount ~= _groupMembers or backupRaidCount ~= _raidMembers then	_fctGroupStatus() end
	end

end

local function _fctUnitChange (unitID, unitType)

	checkGroupSize (unitType)

	if unitID == false then
		if unitType == "player.target" then data.targetID = nil end
		_untrackUnit(unitType, unitID)
	else
		if unitType == "player.target" then data.targetID = unitID end
		_trackUnit (unitType, unitID)
	end

end

local function _unitAvailable (_, info)        
	
	--print ("_unitAvailable")

	--dump (info)

	for unit, thisData in pairs(info) do

		--print (thisData)

		if thisData == "player" or thisData == "player.pet" then
			if thisData == "player.pet" then data.playerPetID = unit end
			_trackUnit (thisData, unit)
			--print ("_unitAvailable")

			local identifiers = _getIdentifier (unit)
			if #identifiers > 0 then
				for idx = 1, #identifiers, 1 do
					local frame = _getUnitFrame(identifiers[idx])			
					if frame then
						_internal.updateUnit (frame, unit)
						if thisData == "player" then uiElements.frames["player.ressourcebar"]:update(unit) end
					end			
				end
			end
		else
			_eventUnitAdd (_, {[unit] = thisData})
		end		    
	end
end

local function _eventHealth (_, info)
	for unit, thisData in pairs(info) do
		--print ("_eventHealth")
		--print (unit, thisData)

		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = _getUnitFrame(identifiers[idx])		

				if frame then
					frame:SetHealth(thisData)
				end
			end
		end
	end
end

local function _eventHealthCap (a,b,c)
end

local function _eventHealthMax (_, info)
	for unit, thisData in pairs(info) do
		--print ("_eventHealthMax")

		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = _getUnitFrame(identifiers[idx])		

				if frame then frame:SetHealthMax(thisData) end
			end
		end
	end
end

local function _eventEnergy (_, info)
	for unit, thisData in pairs(info) do
		--print ("_eventEnergy")

		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = _getUnitFrame(identifiers[idx])		

				if frame then frame:SetEnergy(thisData) end

				if identifiers[idx] == "player" then
					uiElements.frames["player.ressourcebar"]:SetRessource(thisData)
				end
			end
		end
	end
end

local function _eventEnergyMax (_, info)
	for unit, thisData in pairs(info) do
		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = _getUnitFrame(identifiers[idx])		

				if frame then frame:SetEnergyMax(thisData) end

				if identifiers[idx] == "player" then
					uiElements.frames["player.ressourcebar"]:SetRessourceMax(thisData)
				end
			end
		end
	end
end

local function _eventMana (_, info)
	for unit, thisData in pairs(info) do
		--print ("_eventMana")
		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = _getUnitFrame(identifiers[idx])		

				if frame then frame:SetEnergy(thisData) end

				if identifiers[idx] == "player" then
					uiElements.frames["player.ressourcebar"]:SetRessource(thisData)
				end
			end
		end
	end
end

local function _eventCharge (_, info)
	for unit, thisData in pairs(info) do
		--print ("_eventCharge")
		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = _getUnitFrame(identifiers[idx])		

				if frame then frame:SetCharge(thisData) end

				if identifiers[idx] == "player" then
					uiElements.frames["player.ressourcebar"]:SetCharge(thisData)
				end
			end
		end		
	end
end

local function _eventPower (_, info)
	for unit, thisData in pairs(info) do
		--print ("_eventPower")
		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = _getUnitFrame(identifiers[idx])		

				if frame then frame:SetEnergy(thisData) end

				if identifiers[idx] == "player" then
					uiElements.frames["player.ressourcebar"]:SetRessource(thisData)
				end
			end
		end	
	end
end

local function _eventPlanar (_, info)
	for unit, thisData in pairs(info) do
		--print ("_eventPlanar")
		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = _getUnitFrame(identifiers[idx])		

				if frame then frame:SetPlanar(thisData) end
			end
		end	
	end
end

local function _eventCombo (_, info)
	for unit, thisData in pairs(info) do        

		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				if identifiers[idx] == "player" then
					uiElements.frames["player.ressourcebar"]:SetCombo(thisData)
				end
			end
		end	
	end
end


local function _eventBuffAdd(_, unit, buffs)
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
		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				if identifiers[idx] and stringFind(identifiers[idx], "raid") == false then
					local frame = _getUnitFrame(identifiers[idx])
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
		--print ("_eventBuffRemove")
		local identifiers = _getIdentifier (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				if identifiers[idx] and stringFind(identifiers[idx], "raid") == false then
					local frame = _getUnitFrame(identifiers[idx])
					if frame then frame:removeBuff(unit, buffs) end
				end
			end
		end	
	end
end

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

local function _fctZoneEvent(_, thisData)

	for k, v in pairs(thisData) do
		if k == data.playerID then
			_internal.processBuffs ()
		end
	end
end

local function _fctUpdateHandler()
	
	-- run always

	local _curTime = InspectTimeReal()
	local _watchDog = InspectSystemWatchdog()
	
	-- run every 1 second
	
	--if (_lastUpdate3 == nil or _curTime - _lastUpdate3 >= 1) then
	--	
	--	_lastUpdate3 = _curTime
	--end
	
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

function _events.uiFramesInitEvents()	

	--EnKai.unit.subscribe("player.target")
	--EnKai.unit.subscribe("player")
	--EnKai.unit.subscribe("player.pet")

	--Command.Event.Attach(EnKai.events["EnKai.Unit"].Change,  _eventUnitChange, "nkUI.EnKai.Unit.Change")

	Command.Event.Attach(Library.LibUnitChange.Register("player"), function (_, unitData) _fctUnitChange(unitData, "player") end, "nkUI.Unit.unitChange.player")
	Command.Event.Attach(Library.LibUnitChange.Register("player.target"), function (_, unitData) _fctUnitChange(unitData, "player.target") end, "nkUI.Unit.unitChange.player")
	Command.Event.Attach(Library.LibUnitChange.Register("player.pet"), function (_, unitData) _fctUnitChange(unitData, "player.pet") end, "nkUI.Unit.unitChange.player")

	for idx = 1, 20, 1 do
		local groupText = stringFormat ("group%02d", idx)		

		Command.Event.Attach(Library.LibUnitChange.Register(groupText), function (_, unitData) _fctUnitChange(unitData, groupText) end, "nkUI.Unit.unitChange." .. groupText)		

		if idx <= 5 then
			-- here we need to add group.pet

			--local groupPetText = stringFormat ("group%02d.pet", idx)
			--Command.Event.Attach(Library.LibUnitChange.Register(groupPetText), function (_, unitData) _fctUnitChange(unitData, groupPetText) end, "nkUI.Unit.unitChange." .. groupPetText)
		end
		
	end

	Command.Event.Attach(Event.System.Secure.Enter, _fctSecureEnter, "nkUI.Ssytem.Secure.Enter")
	Command.Event.Attach(Event.System.Secure.Leave, _fctSecureLeave, "nkUI.Ssytem.Secure.Leave")

    Command.Event.Attach(Event.Unit.Availability.Full, _unitAvailable, "nkUI.playerFrame.Unit.Availability.Full")    
	Command.Event.Attach(Event.Unit.Availability.Partial, _unitAvailable, "nkUI.playerFrame.Unit.Availability.Partial") 
	--Command.Event.Attach(Event.Unit.Availability.None, _eventUnitRemove, "nkUI.playerFrame.Unit.Availability.None")    
	

    Command.Event.Attach(Event.Unit.Detail.Health, _eventHealth, "nkUI.playerFrame.Unit.Detail.Health")
    Command.Event.Attach(Event.Unit.Detail.HealthCap, _eventHealthCap, "nkUI.playerFrame.Unit.Detail.HealthCap")
    Command.Event.Attach(Event.Unit.Detail.HealthMax, _eventHealthMax, "nkUI.playerFrame.Unit.Detail.HealthMax")
    Command.Event.Attach(Event.Unit.Detail.Energy, _eventEnergy, "nkUI.playerFrame.Unit.Detail.Energy")
    Command.Event.Attach(Event.Unit.Detail.EnergyMax, _eventEnergyMax, "nkUI.playerFrame.Unit.Detail.EnergyMax")
	Command.Event.Attach(Event.Unit.Detail.Power, _eventPower, "nkUI.playerFrame.Unit.Detail.Power")    
	Command.Event.Attach(Event.Unit.Detail.Mana, _eventMana, "nkUI.playerFrame.Unit.Detail.Mana")    
	Command.Event.Attach(Event.Unit.Detail.Charge, _eventCharge, "nkUI.playerFrame.Unit.Detail.Charge")    
    Command.Event.Attach(Event.Unit.Detail.Planar, _eventPlanar, "nkUI.playerFrame.Unit.Detail.Planar")
	Command.Event.Attach(Event.Unit.Detail.Combo, _eventCombo, "nkUI.playerFrame.Unit.Detail.Combo")

	Command.Event.Attach(Event.Unit.Castbar, _eventCastBar, "nkUI.Unit.Castbar")

    Command.Event.Attach(Event.Buff.Add, _eventBuffAdd, "nkUI.Buff.Add")
	Command.Event.Attach(Event.Buff.Change, _eventBuffChange, "nkUI.Buff.Change")
	Command.Event.Attach(Event.Buff.Remove, _eventBuffRemove, "nkUI.Buff.Remove")

    --Command.Event.Attach(Event.Unit.Add, _eventUnitAdd , "nkUI.playerFrame.Unit.Add")
    --Command.Event.Attach(Event.Unit.Remove, _eventUnitRemove , "nkUI.playerFrame.Unit.Remove")

    Command.Event.Attach(Event.System.Update.Begin, _fctUpdateHandler, "nkUI.System.updateHandler")

	Command.Event.Attach(Event.Unit.Detail.Zone, _fctZoneEvent, "nkUI.Unit.Detail.Zone")

end