local addonInfo, privateVars = ...

if not privateVars.mapEvents then privateVars.mapEvents = {} end

---------- init namespace ---------

local map           = privateVars.map
local mapEvents     = privateVars.mapEvents
local mapData       = privateVars.mapData
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events

---------- init local variables ---------

local _units = {}
local _enemyUnits = {}
local _foreignUnits = {}
local _foreignUnitsFrom = {}
local _unitsMapping = {}

---------- make global functions local ---------

local InspectUnitDetail         = Inspect.Unit.Detail
local InspectTimeReal           = Inspect.Time.Real
local InspectUnitCastbar        = Inspect.Unit.Castbar
local InspectAchievementDetail  = Inspect.Achievement.Detail

local LibEKLGetPlayerDetails    = LibEKL.Unit.GetPlayerDetails
local LibEKLGetGroupStatus      = LibEKL.Unit.GetGroupStatus
local LibEKLMathRound           = LibEKL.Tools.Math.Round
local LibEKLTableCopy           = LibEKL.Tools.Table.Copy
local LibEKLTableIsMember       = LibEKL.Tools.Table.IsMember
local LibEKLTableSerialize      = LibEKL.Tools.Table.Serialize
local LibEKLStringsRight        = LibEKL.strings.right
local LibMapMapGetAll           = LibMap.map.getAll

local stringFind               = string.find

---------- local function block ---------

function mapEvents.processPlayerTarget(unitID, unitDetails)

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "mapEvents.processPlayerTarget") end

	mapData.playerTargetUID = unitID  

	local rel = "FRIENDLY"

	if unitDetails.relation == "hostile" then
		rel = "HOSTILE"  
	elseif unitDetails.relation == "neutral" then
		rel = "NEUTRAL"
	end

	local thisData = {	["t" .. unitID] = {id = "t" .. unitID, type = "UNIT.TARGET." .. rel, coordX = unitDetails.coordX, coordY = unitDetails.coordY, coordZ = unitDetails.coordZ, title = unitDetails.name},
						["npc" .. unitID] = {id = "npc" .. unitID, type = "VARIA.NPC." .. rel, coordX = unitDetails.coordX, coordY = unitDetails.coordY, coordZ = unitDetails.coordZ, title = unitDetails.name}}

	map.UpdateMap (thisData, "add", "mapEvents.processPlayerTarget")

	if rel == "HOSTILE" then
		local bData = {add = {["e" .. unitID] = {id = "e" .. unitID, type = "UNIT.ENEMY", coordX = unitDetails.coordX, coordY = unitDetails.coordY, coordZ = unitDetails.coordZ, title = unitDetails.name }}}
		mapData.playerHostileTargetUID = unitID
	else
		mapData.playerHostileTargetUID = nil
	end
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "mapEvents.processPlayerTarget", debugId) end

end

---------- addon internal function block ---------

function mapEvents.SystemUpdate ()

  local now = InspectTimeReal()

	if mapData.forceUpdate ~= true then
		if mapData.lastUpdate == nil then
			mapData.lastUpdate = now
			privateVars.forceUpdate = true
		else
			local tmpTime = now
      if now - mapData.lastUpdate > .5 then mapData.forceUpdate = true end
		end
	end

	if mapData.forceUpdate == true then
		
		if mapData.postponedAdds ~= nil then
			if LibQB.query.isInit() == true and LibQB.query.isPackageLoaded('poa') == true and LibQB.query.isPackageLoaded('nt') == true and LibQB.query.isPackageLoaded('classic') == true then
				local temp = LibEKLTableCopy(mapData.postponedAdds)
				mapData.postponedAdds = nil
				map.UpdateMap(temp, "add", "events.SystemUpdate")
				mapData.lastUpdate = now -- diese Abfrage direkt nach mapData.forceUpdate platzieren wenn andere Funktionen aufgerufen werden
			end
		end		
	end

end

function mapEvents.ZoneChange (_, info) 

	for unit, zoneId in pairs (info) do
		if unit == LibEKL.Unit.GetPlayerID() then
			if uiElements.mapUI == nil then 
				map.initMap ()
			else
				map.SetZone (zoneId) 
			end

			return
		end
	end

end

function mapEvents.ShardChange (_, info)

  if mapData.lastShard == nil then mapData.lastShard = info end

  if uiElements.mapUI == nil then return end
  if mapData.lastShard == info then return end
  
  mapData.lastShard = info

  local points, units = LibMapMapGetAll()
  map.UpdateMap(points, "remove")
  
  map.SetZone (mapData.lastZone)  
  
  local details = InspectUnitDetail('player')

  map.UpdateUnit ({[details.id] = {id = details.id, type = "player", coordX = details.coordX, coordY = details.coordY, coordZ = details.coordZ}}, "add")
  
  local petDetails = InspectUnitDetail('player.pet')
  if petDetails ~= nil then
    map.UpdateUnit ({[petDetails.id] = {id = petDetails.id, type = "player.pet", coordX = petDetails.coordX, coordY = petDetails.coordY, coordZ = petDetails.coordZ}}, "add")
  end

end

function mapEvents.UnitUnavailable (_, info)

  for unitId, _ in pairs (info) do _units[unitId] = nil end

end

function mapEvents.UnitCoordChange (_, x, y, z)

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "events.UnitCoordChange") end

	local updates, adds = {}, {}
	local hasUpdates, hasAdds = false, false

	for unit, _ in pairs (x) do
		if unit == LibEKL.Unit.GetPlayerID() then
			updates[unit] = {id = unit, center = true, coordX = x[unit], coordY = y[unit], coordZ = z[unit]}
			hasUpdates = true
		elseif _units[unit] == nil then
			adds[unit] = {id = unit, type = "UNKNOWN", coordX = x[unit], coordY = y[unit], coordZ = z[unit]}
			_units[unit] = true
			hasAdds = true
		else    
			updates[unit] = {id = unit, coordX = x[unit], coordY = y[unit], coordZ = z[unit]}
			hasUpdates = true
		end
	end

	if hasUpdates == true then map.UpdateMap (updates, "coord", "events.UnitCoordChange") end
	if hasAdds == true then map.UpdateMap (adds, "add") end

	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "events.UnitCoordChange", debugId) end

end

function mapEvents.UnitCastBar (_, info)
  
  if info[LibEKL.Unit.GetPlayerID()] then
    local details = InspectUnitCastbar(LibEKL.Unit.GetPlayerID())
    if details and details.abilityNew == "A0000002B72E024A4" then
      mapData.collectStart = InspectTimeReal()
    end
  end

end

function mapEvents.UnitChange (_, unitID, unitType)

  local debugId
  if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "events.UnitChange") end

  -- check for player target change and check if group status changes and process their targets
  
  if unitType == "player.target" then
  
    if mapData.playerTargetUID ~= nil then map.UpdateMap ({["t" .. mapData.playerTargetUID] = false, ["npc" .. mapData.playerTargetUID] = false}, "remove") end        
  
    if unitID == false then
      mapData.playerHostileTargetUID = nil
      mapData.playerTargetUID = nil
    else
      local unitDetails = InspectUnitDetail(unitID)
      mapEvents.processPlayerTarget(unitID, unitDetails)
    end
  elseif stringFind(unitType, "player.target") == nil and stringFind(unitType, "group") == 1 and stringFind(unitType, "group..%.target") == nil then
  
    if unitID == false then
      local removes, hasRemoves = {}, false
    
      if _foreignUnitsFrom[_unitsMapping[unitType]] ~= nil then
        for id, _ in pairs(_foreignUnitsFrom[_unitsMapping[unitType]]) do
          removes[id] = true
          hasRemoves = true
        end
        
        _foreignUnitsFrom[_unitsMapping[unitType]] = {}
        
      end

      _unitsMapping[unitType] = nil      
      
      if hasRemoves then map.UpdateMap (removes, "remove") end
    else
      local details = InspectUnitDetail(unitID)
      if details ~= nil then _unitsMapping[unitType] = details.name end
    end
  end
  
  if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "events.UnitChange", debugId) end

end

function mapEvents.GroupStatus (_, status)
	
	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "events.GroupStatus") end

	if mapData.lastGroupStatus ~= status then

		local removes = {}
		local hasRemoves = false

		if status ~= "group" and status ~= "raid" then
			for k, v in pairs(mapData.waypoints) do
				if v.player ~= true then
					removes[k] = v
					hasRemoves = true
				end
			end
		end

		if hasRemoves then map.UpdateMap(removes, "waypoint-remove") end
		mapData.lastGroupStatus = status
	end

	if nkUISetup.modules.map.syncTarget ~= true then 
		if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "events.GroupStatus", debugId) end
		return 
	end
	
	if mapData.playerHostileTargetUID == nil then
		if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "events.GroupStatus", debugId) end
		return
	end
	
	if status ~= "group" and status ~= "raid" then
		if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "events.GroupStatus", debugId) end
		return
	end

	local details = InspectUnitDetail(mapData.playerHostileTargetUID)
	if details == nil then 
		if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "events.GroupStatus", debugId) end
		return 
	end
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "events.GroupStatus", debugId) end

end

function mapEvents.achievementUpdate (_, info)

  local achievement = nil
  local refreshNeeded = false
  
  for id, _ in pairs(info) do
    if LibEKLTableIsMember(mapData.rareMobAchievements, id) == true then
      
      for idx = 1, #mapData.rareMobAchievements, 1 do
        achievement = InspectAchievementDetail(mapData.rareMobAchievements[idx])
        
        if achievement ~= nil then
        
          for requirement, details in pairs(achievement.requirement) do
            if details.complete == true then
              if mapData.rareMobKilled[details.name] == false then
                mapData.rareMobKilled[details.name] = true
                refreshNeeded = true
              else
                mapData.rareMobKilled[details.name] = true
              end
            else
              mapData.rareMobKilled[details.name] = false
            end
          end
        end
        
      end
  
    end
  end
  
  if nkUISetup.modules.map.rareMobs == true and refreshNeeded == true then
    map.ShowRareMobs(false)
    map.ShowRareMobs(true)
  end
  
end

function mapEvents.UpdateLocation (_, info)

  local playerID = LibEKL.Unit.GetPlayerID()

  if playerID == nil then return end
    
  if info[playerID] == nil or info[playerID] == false then return end   
    
  mapData.locationName = info[playerID]
  if uiElements.mapUI == nil then return end
  uiElements.mapUI:SetZoneTitle(nkUISetup.modules.map.showZoneTitle)
    
end