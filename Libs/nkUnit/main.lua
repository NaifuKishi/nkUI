local nkUnitInfo, nkUnit = ...

nkUnit.privateVars = {}

nkUnit.privateVars.addonName = "nkUnit"
nkUnit.privateVars.addonVersion = "1.0.0"

nkUnit.privateVars.unitTable = {}
nkUnit.privateVars.isRaid = false
nkUnit.privateVars.isGroup = false

nkUnit.privateVars.groupMembers = 0
nkUnit.privateVars.raidMembers = 0

nkUnit.privateVars.registeredEvents = {}
nkUnit.privateVars.lookupEvents = {}

nkUnit.privateVars.watchUnits = {'player', 'player.pet', 'player.target', 'player.target.target', 'focus', 'focus.target'}

nkUnitLib = {}

--[[local _InspectUnitDetail = Inspect.Unit.Detail

Inspect.Unit.Detail = function(unitInfo)
	
	print ('--- Inspect.Unit.Detail ---')	
	local retVal = _InspectUnitDetail(unitInfo)
	if retVal ~= nil then print (retVal.name) end
	return retVal
  
end]]

function nkUnit.main(addon)

	if (addon == nkUnit.privateVars.addonName) then
	
		--table.insert(Event.Unit.Available, { nkUnit.events.unitAvailable, "nkUnit", "unitAvailable"})
		--table.insert(Event.Unit.Unavailable, { nkUnit.events.unitUnavailable, "nkUnit", "unitUnavailable"})
		
		--table.insert(Event.Ability.Range.False, { function (abilities) nkUnit.events.rangeHandler(abilities, false) end, "nkUnit", "unitRangeFalse" })
		--table.insert(Event.Ability.Range.True, { function (abilities) nkUnit.events.rangeHandler(abilities, true) end, "nkUnit", "unitRangeTrue" })

		for idx = 1, #nkUnit.privateVars.watchUnits, 1 do
			local unitEvent = Library.LibUnitChange.Register(nkUnit.privateVars.watchUnits[idx])
			table.insert(unitEvent, {function (unitData) nkUnit.events.unitChange(unitData, nkUnit.privateVars.watchUnits[idx]) end, "nkUnit", 'unitChange' .. nkUnit.privateVars.watchUnits[idx]})
		end
		
		for idx = 1, 20, 1 do
			local unitEvent = Library.LibUnitChange.Register(string.format('group%02d', idx))
			table.insert(unitEvent, {function (unitData) nkUnit.events.unitChange(unitData, string.format('group%02d', idx)) end, "nkUnit", 'unitChange' .. string.format('group%02d', idx)})

			if idx <= 5 then		
				local unitEvent = Library.LibUnitChange.Register(string.format('group%02d', idx) .. '.target')
				table.insert(unitEvent, {function (unitData) nkUnit.events.unitChange(unitData, string.format('group%02d', idx) .. '.target') end, "nkUnit", 'unitChange' .. string.format('group%02d', idx) .. '.target'})
				
				local unitEvent = Library.LibUnitChange.Register(string.format('group%02d', idx) .. '.pet')
				table.insert(unitEvent, {function (unitData) nkUnit.events.unitChange(unitData, string.format('group%02d', idx) .. '.pet') end, "nkUnit", 'unitChange' .. string.format('group%02d', idx) .. '.pet'})
			end
		end
		
	end
	
end

function nkUnit.getUnitTypes (unitID)

	local retValues = {}

	for k, v in pairs (nkUnit.privateVars.unitTable) do
		if v == unitID then table.insert(retValues, k) end
	end
	
	return retValues

end

table.insert(Event.Addon.Load.End, {nkUnit.main, "nkUnit", "addonLoaded"})

function nkUnitLib.registerEvent (identifier)

	--print ('register event: ' .. identifier)

	if nkUnit.privateVars.lookupEvents[identifier] then return nkUnit.privateVars.lookupEvents[identifier] end
	nkUnit.privateVars.registeredEvents[identifier], nkUnit.privateVars.lookupEvents[identifier] = Utility.Event.Create("nkUnit", identifier)
	return nkUnit.privateVars.lookupEvents[identifier]
	
end

function nkUnitLib.getGroupStatus ()

	if nkUnit.privateVars.isRaid == true then
		return 'raid', nkUnit.privateVars.raidMembers
	elseif nkUnit.privateVars.isGroup == true then
		return 'group', nkUnit.privateVars.groupMembers
	else
		return 'single', nil
	end

end

function nkUnitLib.getUnitTypes (unitID) return nkUnit.getUnitTypes(unitID) end

function nkUnitLib.displayUnitTypes ()

	dump (nkUnit.privateVars.unitTable)
	
end

function nkUnitLib.simulateUnit (event, unitType)

	local unitId = Inspect.Unit.Lookup('mouseover')
	if unitId == nil then return end

	if event == 'LibUnitChange' then
		nkUnit.events.unitChange(unitId, unitType)
	elseif event == 'UnitAvailable' then
		local unitData = {}
		unitData[unitId] = unitType
		nkUnit.events.unitAvailable(unitData)
	end
	
end

function nkUnitLib.testEvent (event, arg1, arg2)

	if event == 'LibUnitChange' then
		nkUnit.events.unitChange(arg1, arg2)
	elseif event == 'UnitAvailable' then
		nkUnit.events.unitAvailable(arg1)
	end

end
