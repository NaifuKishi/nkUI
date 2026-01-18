local addonInfo, privateVars = ...

---------- init namespace ---------

local data        	= privateVars.data
local uiElements  	= privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local _events     	= privateVars.events

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

local function _eventHealth (_, info)
	for unit, thisData in pairs(info) do		
		local identifiers = LibEKL.Unit.GetUnitTypes (unit)
		if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_eventHealth", stringFormat("%s %d", unit, thisData), identifiers) end

		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local realIdentifier = identifiers[idx]
				if stringMatch(realIdentifier, "^group%d%d$") and LibEKL.Unit.GetGroupStatus () == "raid" then
					local groupID = stringMatch(realIdentifier, "^group(%d%d)$")
					realIdentifier = stringFormat("raid%02d", tonumber(groupID))
				end

				local frame = internalFunc.getFrameByIdentifier(realIdentifier)

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
		local identifiers = LibEKL.Unit.GetUnitTypes (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local realIdentifier = identifiers[idx]
				if stringMatch(realIdentifier, "^group%d%d$") and LibEKL.Unit.GetGroupStatus () == "raid" then
					local groupID = stringMatch(realIdentifier, "^group(%d%d)$")
					realIdentifier = stringFormat("raid%02d", tonumber(groupID))
				end

				local frame = internalFunc.getFrameByIdentifier(realIdentifier)

				if frame then frame:SetHealthMax(thisData) end
			end
		end
	end
end

local function _eventEnergy (_, info)
	for unit, thisData in pairs(info) do
		local identifiers = LibEKL.Unit.GetUnitTypes (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = internalFunc.getFrameByIdentifier(identifiers[idx])		

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
		local identifiers = LibEKL.Unit.GetUnitTypes (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = internalFunc.getFrameByIdentifier(identifiers[idx])		

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
		local identifiers = LibEKL.Unit.GetUnitTypes (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = internalFunc.getFrameByIdentifier(identifiers[idx])		

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
		local identifiers = LibEKL.Unit.GetUnitTypes (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				--local frame = internalFunc.getFrameByIdentifier(identifiers[idx])		

				--if frame then frame:SetCharge(thisData) end

				if identifiers[idx] == "player" then
					uiElements.frames["player.ressourcebar"]:SetCharge(thisData)
				end
			end
		end		
	end
end

local function _eventPower (_, info)
	for unit, thisData in pairs(info) do
		local identifiers = LibEKL.Unit.GetUnitTypes (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = internalFunc.getFrameByIdentifier(identifiers[idx])		

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
		local identifiers = LibEKL.Unit.GetUnitTypes (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				local frame = internalFunc.getFrameByIdentifier(identifiers[idx])		

				if frame then frame:SetPlanar(thisData) end
			end
		end	
	end
end

local function _eventCombo (_, info)
	for unit, thisData in pairs(info) do        

		local identifiers = LibEKL.Unit.GetUnitTypes (unit)
		if #identifiers > 0 then
			for idx = 1, #identifiers, 1 do
				if identifiers[idx] == "player" then
					uiElements.frames["player.ressourcebar"]:SetCombo(thisData)
				end
			end
		end	
	end
end

function _events.focus (self, focus)

	uiElements.frames["player.ressourcebar"]:SetFocus(focus)

end


function _events.uiFramesInitStatEvents()	

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_events.uiFramesInitStatEvents", "", nil) end

	--- stats changes

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

	local details = LibEKL.Unit.GetPlayerDetails()
	if details.calling == "primalist" then
		LibEKL.Stat.Init()
		LibEKL.Stat.Subscribe("focus")
		Command.Event.Attach(LibEKL.Events["LibEKL.Stat"].Focus, _events.focus, "nkUI.LibEKL.Stat.Focus")	
	end

end
