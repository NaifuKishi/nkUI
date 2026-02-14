local addonInfo, privateVars = ...

---------- init namespace ---------

local data        	= privateVars.data
local uiElements  	= privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events     	= privateVars.events

-- Cache frequently used functions and values
local inspectBuffList     	= Inspect.Buff.List
local inspectBuffDetail	  	= Inspect.Buff.Detail
local inspectUnitLookup	  	= Inspect.Unit.Lookup
local inspectUnitDetail	  	= Inspect.Unit.Detail
local inspectUnitCastbar	= Inspect.Unit.Castbar
local inspectTimeReal		= Inspect.Time.Real
local inspectSystemWatchdog = Inspect.System.Watchdog

local stringFormat	= string.format
local stringMatch	= string.match
local stringFind	= string.find
local stringSub		= string.sub

local LibEKLGetUnitTypes			= LibEKL.Unit.GetUnitTypes
local LibEKLUnitGetPlayerDetails	= LibEKL.Unit.GetPlayerDetails
local LibEKLUnitGetUnitDetail		= LibEKL.Unit.GetUnitDetail
local LibEKLUnitGetUnitIDByType		= LibEKL.Unit.GetUnitIDByType
local LibEKLUnitGetGroupStatus		= LibEKL.Unit.GetGroupStatus

local lastGroupType

------------------------------ combat functions ------------------------------

local function secureEnter()

	uiElements.frames["player"]:SetAlpha(nkUISetup.modules.unitFrames.combatAlpha)
	uiElements.frames["player"]:SetCombat(true)

	uiElements.frames["player.pet"]:SetAlpha(nkUISetup.modules.unitFrames.combatAlpha)
	uiElements.frames["player.target"]:SetAlpha(nkUISetup.modules.unitFrames.combatAlpha)
	uiElements.frames["player.target.target"]:SetAlpha(nkUISetup.modules.unitFrames.combatAlpha)
	uiElements.frames["player.ressourcebar"]:SetVisible(true)

	uiElements.frames["focus"]:SetAlpha(nkUISetup.modules.unitFrames.combatAlpha)

end

local function secureLeave()
	
	uiElements.frames["player"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
	uiElements.frames["player"]:SetCombat(false)

	uiElements.frames["player.pet"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
	uiElements.frames["player.target"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
	uiElements.frames["player.target.target"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
	
	if not nkUISetup.modules.unitFrames.alwaysShowRessourceBar then
		uiElements.frames["player.ressourcebar"]:SetVisible(false)
	end

	uiElements.frames["focus"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)

end

------------------------------ cast bar functions ------------------------------

local function eventCastBar(_, units) 

	for unitID, state in pairs (units) do			

		local unitTypes = LibEKLGetUnitTypes(unitID)

		for _, identifier in pairs (unitTypes) do

			local castBarName = stringFormat("%s.castbar", identifier)
			local thisFrame = uiElements.frames[castBarName]

			if thisFrame then
				if state == true then					
					local details = inspectUnitCastbar(unitID)

					thisFrame:SetSpell (details.abilityName)
					thisFrame:SetTimer (details.duration, details.duration)
					thisFrame:SetInterruptible (not details.uninterruptible)
					thisFrame:SetVisible(true)					

					data[castBarName] = {
						abilityName = details.abilityName,
						duration = details.duration,
						uninterruptible = details.uninterruptible,
						start = inspectTimeReal()
					}
				else
					if data[castBarName] and not data[castBarName].uninterruptible then 
						if unitID ~= LibEKLUnitGetPlayerDetails().id and inspectTimeReal() - data[castBarName].start < data[castBarName].duration then
							local unitDetails = LibEKLUnitGetUnitDetail (unitID, true)
							if unitDetails.health > 0 then
								internalFunc.displayMessageAtTopCenter(stringFormat("%s interrupted", data[castBarName].abilityName), 1.5)
							end
						end
					end

					thisFrame:SetVisible(false)
					data[castBarName] = nil
				end
			end
		end
	end

end

local function processCastBars () 

	local playerCastBar = data["player.castbar"]

	if playerCastBar then
		local thisFrame = uiElements.frames["player.castbar"]
		local remaining = playerCastBar.duration - (inspectTimeReal() - playerCastBar.start)
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

		local remaining = targetCastBar.duration - (inspectTimeReal() - targetCastBar.start)
		if remaining <= 0 then				
			data["player.target.castbar"] = nil
			thisFrame:SetVisible(false)
		else				
			thisFrame:SetTimer (remaining, targetCastBar.duration)
		end
	end
end

------------------------------ buff functions ------------------------------

local function eventBuffAdd(_, unit, buffs)
	
	local groupStatus, groupSize = LibEKLUnitGetGroupStatus()

	if nkUISetup.modules.unitFrames.activate == false then return end

	-- Handle player buffs
	if unit == LibEKLUnitGetPlayerDetails().id and nkUISetup.modules.buffBar.activate then
		internalFunc.buffBar.addBuff(unit, buffs)
		internalFunc.buffBar.UpdateBuffDisplay()
	end

	-- Handle unit frame buffs
	if nkUISetup.modules.unitFrames.showBuffs then

		local identifiers = LibEKLGetUnitTypes (unit)

		if #identifiers > 0 then
			for _, value in pairs(identifiers) do
				if not stringFind(value, "group") or groupStatus ~= "raid" then
					local frame = internalFunc.getFrameByIdentifier(value)
					if frame then frame:addBuff(unit, buffs) end
				end
			end
		end			
	end
end

--[[local function eventBuffChange (_, unit, buffs)
	if nkUISetup.modules.buffBar.activate == false then return end
end]]

local function eventBuffRemove (_, unit, buffs)

	--if nkUISetup.modules.unitFrames.activate == false then return end

	if unit == LibEKLUnitGetPlayerDetails().id and nkUISetup.modules.buffBar.activate then 
		internalFunc.buffBar.removeBuff(unit, buffs) 
		internalFunc.buffBar.UpdateBuffDisplay()
	end

	if nkUISetup.modules.unitFrames.showBuffs then
		local identifiers = LibEKLGetUnitTypes (unit)
		if #identifiers > 0 then
			for _, value in pairs(identifiers) do
				if not stringFind(value, "group") or groupStatus ~= "raid" then
					local frame = internalFunc.getFrameByIdentifier(value)
					if frame then frame:removeBuff(unit, buffs) end
				end
			end
		end	
	end
end

------------------------------ zone functions ------------------------------

local function zoneEvent(_, thisData)

	local playerID = LibEKLUnitGetPlayerDetails().id

	for k, v in pairs(thisData) do
		if k == playerID then
			internalFunc.updateUnit (playerFrame, playerID, "player")
			internalFunc.processBuffs ()
			break
		end
	end
end

local function unitDetailsEvent (_, thisData)

	for unitID, v in pairs(thisData) do
		local unitTypes = LibEKLGetUnitTypes (unitID)
		for _, thisType in pairs (unitTypes) do
			local frame = internalFunc.getFrameByIdentifier(thisType)
			--LibEKLUnitGetUnitDetail(unitID, true)
			internalFunc.updateUnit (frame, unitID, thisType)
		end
	end	
end

local function readyCheckEvent (_, thisData)

	local groupStatus, groupSize = LibEKLUnitGetGroupStatus()

	for unitID, response in pairs(thisData) do
		local unitTypes = LibEKLGetUnitTypes (unitID)

		for _, thisType in pairs (unitTypes) do
			local frame
			
			if stringFind(thisType, "group") and groupStatus == "raid" then
				local groupIndex = stringMatch(thisType, "^group(%d+)$")
				frame = internalFunc.getFrameByIdentifier(stringFormat("raid%s", groupIndex))
			else				
				frame = internalFunc.getFrameByIdentifier(thisType)
			end

			if frame then frame:SetReadyCheck(response) end
		end

	end	

end

------------------------------ group and raid events ------------------------------

local function showHideGroupRaidFrames(framePrefix, unitPrefix, count, flag)
	for idx = 1, count, 1 do
		local frameType = stringFormat("%s%02d", framePrefix, idx)
		local frame = uiElements.frames[frameType]

		if flag then
			local unitType = stringFormat("%s%02d", unitPrefix, idx)
			local unitDetails = LibEKLUnitGetUnitIDByType (unitType)
			if unitDetails then
				frame:SetVisible(true)
				internalFunc.updateUnit (frame, unitDetails[1], unitType)
			else
				frame:SetVisible(false)
			end
		else
			frame:SetVisible(false)
		end
	end
end

local function processGroupStatus (_, groupType)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "processGroupStatus", groupType, {}) end

	if groupType == lastGroupType then return end
	
	if groupType == "group" then
		showHideGroupRaidFrames("raid", "group", 20, false)
		showHideGroupRaidFrames("group", "group", 5, true)
	elseif groupType == "raid" then
		showHideGroupRaidFrames("raid", "group", 20, true)
		showHideGroupRaidFrames("group", "group", 5, false)
	else
		showHideGroupRaidFrames("raid", "group", 20, false)
		showHideGroupRaidFrames("group", "group", 5, false)
	end

	lastGroupType =groupType

end

------------------------------ unit events ------------------------------

function unitChange (_, unitID, identifier)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitChange", "------------------------", nil) end
	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitChange", stringFormat("%s %s", unitID, identifier), nil) end
	
	local frame

	if stringMatch(identifier, "^group(%d+)$") then
		-- only process group if group status matches

		local groupStatus, groupSize = LibEKLUnitGetGroupStatus()

		if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitChange - group status", stringFormat("%s %d", groupStatus, groupSize), {}) end

		if groupStatus == 'group' then 
			frame = uiElements.frames[identifier] 
		else
			local groupIndex = stringMatch(identifier, "^group(%d+)$")
			frame = uiElements.frames[stringFormat("raid%s", groupIndex)] 
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
			internalFunc.updateUnit (frame, unitID, identifier) 
			frame:SetVisible(true)
		end
	else
		if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitChange", stringFormat("no frame %s", identifier), nil) end
	end
	
end

--[[function playerAvailable (_, thisInfo, plusInfo)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "playerAvailable", "", thisInfo) end
	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "playerAvailable", "", plusInfo) end

end]]

function unitAvailable (_, units)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitAvailable", "", units) end

	if units == nil then return end

	local groupStatus, groupSize = LibEKLUnitGetGroupStatus()

	for unitID, identifier in pairs (units) do
		local frame
		
		if stringMatch(identifier, "^group(%d+)$") then			

			if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitAvailable", stringFormat("%s %d", groupStatus, groupSize), units) end

			if groupStatus == 'group' then 
				frame = uiElements.frames[identifier] 
			else
				local groupIndex = stringMatch(identifier, "^group(%d+)$")
				frame = uiElements.frames[stringFormat("raid%s", groupIndex )] 
			end
		else
			frame = uiElements.frames[identifier]
		end		

		if frame then
			internalFunc.updateUnit (frame, unitID, identifier) 
			frame:SetVisible(true)
		end
	end
	
end

function unitUnavailable (_, units)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitUnavailable", "units", units) end

	for unitId, _ in pairs (units) do
	
		local unitTypes = LibEKLGetUnitTypes (unitId)
		for _, thisType in pairs (unitTypes) do
			local frame = internalFunc.getFrameByIdentifier(thisType)
			if frame then frame:SetVisible(false) end
		end
	end

end


------------------------------ update handler functions ------------------------------

local function updateHandler()
	
	-- run always

	local _curTime = inspectTimeReal()
	local _watchDog = inspectSystemWatchdog()
	
	-- run every 60 second
	
	if (_lastUpdate3 == nil or _curTime - _lastUpdate3 >= 60) then
		--_processUnits() -- hopefully this workaround is not needed anymore
		_lastUpdate3 = _curTime
	end
	
	-- run every 0.5 seconds	
	
	if (_lastUpdate2 == nil or _curTime - _lastUpdate2 >= .5) then		
		internalFunc.processBuffs()
		_lastUpdate2 = _curTime
	end
	
	-- run every 0.05 seconds
	
	if (_lastUpdate3 == nil or _curTime - _lastUpdate3 >= .05) then		
		processCastBars() 
		_lastUpdate3 = _curTime
	end
	
end

------------------------------ init event system ------------------------------

function events.uiFramesInitEvents()	

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "events.uiFramesInitEvents", "Startup", nil) end

	LibEKL.Unit.Subscribe("player")
	LibEKL.Unit.Subscribe("player.target")
	LibEKL.Unit.Subscribe("player.target.target")
	LibEKL.Unit.Subscribe("player.pet")
	LibEKL.Unit.Subscribe("focus")

	for idx = 1, 20, 1 do
		LibEKL.Unit.Subscribe(stringFormat("group%02d", idx))
	end

	--Command.Event.Attach(LibEKL.Events["LibEKL.Unit"].PlayerAvailable, playerAvailable, "nkUI.LibEKL.Unit.PlayerAvailable")
	Command.Event.Attach(LibEKL.Events["LibEKL.Unit"].GroupStatus, processGroupStatus, "nkUI.LibEKL.Unit.GroupStatus")
	Command.Event.Attach(LibEKL.Events["LibEKL.Unit"].Available, unitAvailable, "nkUI.LibEKL.Unit.Available")
	Command.Event.Attach(LibEKL.Events["LibEKL.Unit"].Unavailable, unitUnavailable, "nkUI.LibEKL.Unit.Unavailable")
	Command.Event.Attach(LibEKL.Events["LibEKL.Unit"].Change, unitChange, "nkUI.LibEKL.Unit.Change")	

	--- in combat and out of combat alpha

	Command.Event.Attach(Event.System.Secure.Enter, secureEnter, "nkUI.System.Secure.Enter")
	Command.Event.Attach(Event.System.Secure.Leave, secureLeave, "nkUI.System.Secure.Leave")

	--- stats changes

	events.uiFramesInitStatEvents()	

	--- cast bar

	Command.Event.Attach(Event.Unit.Castbar, eventCastBar, "nkUI.Unit.Castbar")

	--- buf management

    Command.Event.Attach(Event.Buff.Add, eventBuffAdd, "nkUI.Buff.Add")
	--Command.Event.Attach(Event.Buff.Change, eventBuffChange, "nkUI.Buff.Change")
	Command.Event.Attach(Event.Buff.Remove, eventBuffRemove, "nkUI.Buff.Remove")

    Command.Event.Attach(Event.System.Update.Begin, updateHandler, "nkUI.System.updateHandler")

	Command.Event.Attach(Event.Unit.Detail.Zone, unitDetailsEvent, "nkUI.Unit.Detail.Zone")
	Command.Event.Attach(Event.Unit.Detail.Role, unitDetailsEvent, "nkUI.Unit.Detail.Role")
	Command.Event.Attach(Event.Unit.Detail.Afk, unitDetailsEvent, "nkUI.Unit.Detail.Afk")
	Command.Event.Attach(Event.Unit.Detail.Offline, unitDetailsEvent, "nkUI.Unit.Detail.Offline")
	Command.Event.Attach(Event.Unit.Detail.Mark, unitDetailsEvent, "nkUI.Unit.Detail.Mark")
	Command.Event.Attach(Event.Unit.Detail.Ready, readyCheckEvent, "nkUI.Unit.Detail.Ready")
	Command.Event.Attach(Event.Unit.Detail.Mark, unitDetailsEvent, "nkUI.Unit.Detail.Mark")

	----- initialize player, pet and target -----

	local playerID = LibEKLUnitGetUnitDetail ("player").id

	local playerFrame = uiElements.frames["player"]
	internalFunc.updateUnit (playerFrame, playerID, "player")
	playerFrame:ContextMenu(playerID)

	uiElements.frames["player.ressourcebar"]:update(playerID)

	local petID = LibEKL.Unit.GetUnitByIdentifier ("player.pet")	
	if (petID) then 
		local frame = uiElements.frames["player.pet"]
		internalFunc.updateUnit (frame, petID, "player.pet") 
		frame:ContextMenu(petID)
		frame:SetVisible(true)
	end

	local targetID = LibEKL.Unit.GetUnitByIdentifier ("player.target")
	if (targetID) then 
		local frame = uiElements.frames["player.target"]
		internalFunc.updateUnit (frame, targetID, "player.target") 
		--frame:ContextMenu(targetID)
		frame:SetVisible(true)
	end

	local focusID = LibEKL.Unit.GetUnitByIdentifier ("focus")
	if (focusID) then 
		local frame = uiElements.frames["focus"]
		internalFunc.updateUnit (frame, focusID, "focus") 
		frame:SetVisible(true)
	end

	LibEKL.Unit.UpdateGroupUnit()

end