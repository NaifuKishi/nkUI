local nkUnitInfo, nkUnit = ...

nkUnit.events = {}

function nkUnit.events.unitChange (unitId, unitType)

	if string.find(unitType, 'mouseover') ~= nil then return end
	
	if unitId == false then
		nkUnit.privateVars.unitTable[unitType] = nil
		nkUnit.events.processUnitChange(unitType, nil)
	else
		nkUnit.privateVars.unitTable[unitType] = unitId
		nkUnit.events.processUnitChange (unitType, unitId)
	end
	
	if nkUnit.privateVars.registeredEvents['unitChange'] then nkUnit.privateVars.registeredEvents['unitChange'](unitId, unitType) end

end

function nkUnit.events.processUnitInfo (unitInfo)
	for k, v in pairs (unitInfo) do
		nkUnit.events.processUnitChange(v, k)
	end
end

function nkUnit.events.unitAvailable(unitInfo)

	--print ('*** nkUnit.events.unitAvailable ***')

--	dump (unitInfo)

	local tempUnitInfo = {}

	for unitId, unitType in pairs (unitInfo) do
		if string.find(unitType, 'mouseover') == nil then
			--[[if unitID ~= false then
				local temp = Inspect.Unit.Detail (unitId)	
				print (unitType, temp.name)	
			else
				print ('set ' .. unitType .. ' to false')
			end
]]
			if string.find (unitType, 'group..%.target') ~= nil and unitId == nkUnit.privateVars.unitTable.player then
				--[[unitId = Inspect.Unit.Lookup(unitType)
				unitInfo[unitId] = unitType
				local temp = Inspect.Unit.Detail (unitId)	
				print ('redirect ' .. unitType .. ' to ' .. temp.name)
				dump (unitInfo)]]
				tempUnitInfo[Inspect.Unit.Lookup(unitType)] = unitType
			else
				tempUnitInfo[unitId] = unitType
			end			
		
			--print ('*** nkUnit.events.unitAvailable ***')
			--print (unitType)
			
			--local details = Inspect.Unit.Detail(unitId)
			--print (details.name)
		
			if string.find(unitType, 'group') == 1 and string.find(unitType, 'group..%.') == nil then
				--print ('--- check group members ---')
				for idx = 1, 5, 1 do
					local tempUnitType = string.format('group%02d', idx)
					local tempUnitId = Inspect.Unit.Lookup(tempUnitType)
					nkUnit.events.processUnitChange (tempUnitType, tempUnitId, nkUnit.events.unitAvailable )
					
					local tempUnitType = string.format('group%02d.target', idx)
					local tempUnitId = Inspect.Unit.Lookup(tempUnitType)
					nkUnit.events.processUnitChange (tempUnitType, tempUnitId, nkUnit.events.unitAvailable )
					
					local tempUnitType = string.format('group%02d.pet', idx)
					local tempUnitId = Inspect.Unit.Lookup(tempUnitType)
					nkUnit.events.processUnitChange (tempUnitType, tempUnitId, nkUnit.events.unitAvailable )
				end
			end
			
			nkUnit.events.processUnitChange (unitType, unitId, nkUnit.events.unitAvailable )
		end	
	end
	
	if nkUnit.privateVars.registeredEvents['unitAvailable'] then nkUnit.privateVars.registeredEvents['unitAvailable'](tempUnitInfo) end
	
end

function nkUnit.events.processUnitChange (unitType, unitId)

	if unitId == false then
		nkUnit.privateVars.unitTable[unitType] = nil
	else
		nkUnit.privateVars.unitTable[unitType] = unitId
	end

	if string.find(unitType, 'group') == 1 and string.find (unitType, 'group..%.') == nil then		
		local indicateGroupChange = false
	
		local groupId = string.sub(unitType, 6, 7)
		--print ('groupId: ' .. groupId)

		if tonumber(groupId) > 5 then
			if nkUnit.privateVars.isRaid == false then 
				indicateGroupChange = true
				nkUnit.privateVars.groupMembers = 0
				nkUnit.privateVars.raidMembers = 0
			end
			
			nkUnit.privateVars.isRaid = true
			nkUnit.privateVars.isGroup = false
		elseif nkUnit.privateVars.isRaid == false then
			if nkUnit.privateVars.isGroup == false then 
				nkUnit.privateVars.groupMembers = 0
				nkUnit.privateVars.raidMembers = 0
				indicateGroupChange = true 
			end
			
			nkUnit.privateVars.isGroup = true
		end
		
		--print (string.format('set raid%s to %s', groupId, tostring(unitId)))
		if unitId == false then
			nkUnit.privateVars.unitTable[string.format('raid%s', groupId)] = nil
		else
			nkUnit.privateVars.unitTable[string.format('raid%s', groupId)] = unitId
		end
		
		local backupGroupCount, backupRaidCount = nkUnit.privateVars.groupMembers, nkUnit.privateVars.raidMembers
		
		if nkUnit.privateVars.isRaid == true then
		
			--print ('--- check for raid members ---')
		
			nkUnit.privateVars.raidMembers = 0
			for idx = 1, 20, 1 do					
				if nkUnit.privateVars.unitTable[string.format('raid%02d', idx)] ~= nil then
					nkUnit.privateVars.raidMembers = nkUnit.privateVars.raidMembers + 1
				end
			end
			
			if nkUnit.privateVars.raidMembers == 0 then nkUnit.privateVars.isRaid = false end
			
			--print ('raid members: ' .. tostring(nkUnit.privateVars.raidMembers))
			
		elseif nkUnit.privateVars.isGroup == true then
		
			--print ('--- check for group members ---')
		
			nkUnit.privateVars.groupMembers = 0
			for idx = 1, 5, 1 do					
				if nkUnit.privateVars.unitTable[string.format('group%02d', idx)] ~= nil then
					nkUnit.privateVars.groupMembers = nkUnit.privateVars.groupMembers + 1
				end
			end
			
			if nkUnit.privateVars.groupMembers == 0 then nkUnit.privateVars.isGroup = false end
			
			--print ('group members: ' .. tostring(nkUnit.privateVars.groupMembers))
			
		end
		
		if indicateGroupChange == true or backupGroupCount ~= nkUnit.privateVars.groupMembers or backupRaidCount ~= nkUnit.privateVars.raidMembers then	nkUnit.events.groupStatus () end
		
	elseif string.find(unitType, 'group..%.') == 1 then
		local groupId = string.sub(unitType, 6, 7)
		if nkUnit.privateVars.unitTable[string.format('group%s', groupId)] == nil then
			local luID = Inspect.Unit.Lookup(string.format('group%s', groupId))
			if luID ~= nil then 
				local unitInfoTable = {}
				unitInfoTable[luID] = string.format('group%s', groupId)
				nkUnit.events.processUnitInfo (unitInfoTable)
			end
		end
	elseif string.find(unitType, 'player') == 1 then
		
		--if nkUnit.privateVars.isRaid == true or nkUnit.privateVars.isGroup == true then
			local playerId = Inspect.Unit.Lookup('player')
			local suffix = ''
			
			if string.find(unitType, 'player.pet') == 1 then
				suffix = '.pet'
			elseif string.find(unitType, 'player.target') == 1 then				
				suffix = '.target'
			end
		
			for idx = 1, 20, 1 do
				--local luID = Inspect.Unit.Lookup(string.format('group%02d%s', idx, suffix))
				local luID = Inspect.Unit.Lookup(string.format('group%02d', idx, suffix))
				
				if luID == playerId then
					local unitInfoTable = {}
					if unitId == nil then
						unitInfoTable[false] = string.format('group%02d%s', idx, suffix)
					else
						unitInfoTable[luID] = string.format('group%02d%s', idx, suffix)
					end
					nkUnit.events.processUnitInfo (unitInfoTable)
					break
				end
			end
		--end
	end

end


function nkUnit.events.unitUnavailable(unitInfo)

	for unitId, _ in pairs (unitInfo) do
	
		local unitTypes = nkUnit.getUnitTypes (unitId)
		
		for idx = 1, #unitTypes, 1 do
			nkUnit.events.processUnitChange (unitTypes[idx], nil, nkUnit.events.unitUnavailable)
		end
	end	
	
	if nkUnit.privateVars.registeredEvents['unitUnavailable'] then nkUnit.privateVars.registeredEvents['unitUnavailable'](unitInfo) end
	
end

function nkUnit.events.groupStatus ()

	--print ('*** group status change ***')

	if nkUnit.privateVars.registeredEvents['groupStatus'] == nil then return end

	if nkUnit.privateVars.isRaid == true then
		nkUnit.privateVars.registeredEvents['groupStatus']('raid', nkUnit.privateVars.raidMembers)
	elseif nkUnit.privateVars.isGroup == true then
		nkUnit.privateVars.registeredEvents['groupStatus']('group', nkUnit.privateVars.groupMembers)
	else
		nkUnit.privateVars.registeredEvents['groupStatus']('single', nil)
	end

end
--[[
function nkUnit.events.rangeHandler(abilities, flag)

	local details = Inspect.Ability.Detail (abilities)
	
	local playerDetails = Inspect.Unit.Detail ('player')
	local targetDetails = Inspect.Unit.Detail ('player.target')
	
	if playerDetails == nil or targetDetails == nil then return end

	local diffX = math.abs(playerDetails.coordX - targetDetails.coordX)
	local diffY = math.abs(playerDetails.coordY - targetDetails.coordY)

	local diffZ = playerDetails.coordZ - targetDetails.coordZ
	
	local flatDistance = math.sqrt((diffX * diffX) + (diffY * diffY))
	local fullDistance = math.sqrt((flatDistance * flatDistance) + (diffZ * diffZ))

	print (fullDistance)	
	
	--for k, v in pairs (details) do
	--	print (v.name)
	--end
	
end

]]