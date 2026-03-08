local addonInfo, privateVars = ...

---------- init namespace ---------

local map			= privateVars.map
local mapEvents		= privateVars.mapEvents
local mapData       = privateVars.mapData
local uiElements    = privateVars.uiElements
local events        = privateVars.events
local lang        	= privateVars.langTexts
local internalFunc	= privateVars.internalFunc

---------- init local variables ---------

local _zoneDetails          = nil
local _rareData             = {}
local mapInit				= false

local RESOURCE_TYPE_MAP = {
    ["RESOURCE.MINE"]             = "MINE",
    ["RESOURCE.HERB"]             = "HERB",
    ["RESOURCE.WOOD"]             = "WOOD",
    ["RESOURCE.FISH"]             = "FISH",
    ["RESOURCE.ARTIFACT"]         = "ARTIFACT",
    ["RESOURCE.ARTIFACT.FAEYULE"] = "FAEYULE",
}

---------- make global functions local ---------

local InspectUnitDetail 	= Inspect.Unit.Detail
local InspectZoneDetail 	= Inspect.Zone.Detail
local InspectSystemSecure 	= Inspect.System.Secure
local InspectSystemWatchdog = Inspect.System.Watchdog
local InspectItemDetail 	= Inspect.Item.Detail
local InspectMouse 			= Inspect.Mouse
local InspectTimeReal 		= Inspect.Time.Real

local LibEKLGetLanguage			= LibEKL.Tools.Lang.GetLanguage
local LibEKLGetLanguageShort	= LibEKL.Tools.Lang.GetLanguageShort
local LibEKLTableCopy			= LibEKL.Tools.Table.Copy
local LibEKLUUID				= LibEKL.Tools.UUID

local stringFind			= string.find
local stringMatch			= string.match
local stringFormat			= string.format
local stringUpper			= string.upper

local mathDeg				= math.deg
local mathAtan2				= math.atan2

---------- addon internal function block ---------

function map.DebugLogUnknown (details, source, extraInfo)

	if not nkDebug then return end

	local logData = {
		source    = source,
		zone      = mapData.lastZone,
		world     = mapData.currentWorld,
		details   = details,
	}

	if details ~= nil and details.id ~= nil then
		local ok, unitInfo = pcall(InspectUnitDetail, details.id)
		if ok and unitInfo ~= nil then
			logData.unitDetail = {
				name        = unitInfo.name,
				level       = unitInfo.level,
				relation    = unitInfo.relation,
				type        = unitInfo.type,
				taggedBy    = unitInfo.taggedBy,
				health      = unitInfo.health,
				healthMax   = unitInfo.healthMax,
				mana        = unitInfo.mana,
				manaMax     = unitInfo.manaMax,
				role        = unitInfo.role,
				ready       = unitInfo.ready,
				guild       = unitInfo.guild,
				zone        = unitInfo.zone,
				coordX      = unitInfo.coordX,
				coordY      = unitInfo.coordY,
				coordZ      = unitInfo.coordZ,
			}
		end
	end

	if extraInfo ~= nil then
		logData.extra = extraInfo
	end

	if mapData.unknownLog == nil then mapData.unknownLog = {} end
	local logKey = (details and details.id) or (details and details.name) or "nil"
	if mapData.unknownLog[logKey] then return end
	mapData.unknownLog[logKey] = true

	nkDebug.debugLog(addonInfo.identifier, logData)

end

function map.initMap ()

	if mapInit then return end

	local debugId 
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "map.initMap") end

	if uiElements.mapUI == nil then uiElements.mapUI = map.createMapUI() end

	uiElements.mapUI:SetAnimated(nkUISetup.modules.map.animations, nkUISetup.modules.map.animationSpeed)
	uiElements.mapUI:SetSmoothScroll(nkUISetup.modules.map.smoothScroll)

	uiElements.mapUI:SetWidth(nkUISetup.modules.map.width)
	uiElements.mapUI:SetHeight(nkUISetup.modules.map.height)

	--[[
	-- Create tiled map UI for world 1-4
	if uiElements.tiledMapUI == nil then uiElements.tiledMapUI = map.createTiledMapUI() end
	]]

	local details = LibEKL.Unit.GetPlayerDetails()		
	map.SetZone (details.zone)

	uiElements.mapUI:SetPointMaximized(nkUISetup.modules.map.maximizedX, nkUISetup.modules.map.maximizedY)  
	uiElements.mapUI:SetWidthMaximized(nkUISetup.modules.map.maximizedWidth)
	uiElements.mapUI:SetHeightMaximized(nkUISetup.modules.map.maximizedHeight)

	uiElements.mapUI:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.map.x, nkUISetup.modules.map.y)

	local points, units = LibMap.map.getAll()
	map.UpdateMap(points, "add", "map.initMap")
	map.UpdateUnit (units, "add")

	if nkDebug and uiElements.debugPanel then
		local mapInfo = uiElements.mapUI:GetMapInfo()
		uiElements.debugPanel:SetCoord(mapInfo.x1, mapInfo.x2, mapInfo.y1, mapInfo.y2)
	end

	Command.Event.Attach(Event.System.Update.Begin, function ()
      
      if mapData.delayStart ~= nil then
          local tmpTime = InspectTimeReal()
          if LibEKL.Tools.Math.Round((tmpTime - mapData.delayStart), 1) > 1 then 
            uiElements.mapUI:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.map.x, nkUISetup.modules.map.y)
            Command.Event.Detach(Event.System.Update.Begin, nil, "nkUI.map.resetPosition")	
          end
      else
        mapData.delayStart = InspectTimeReal()
      end
      
    end, "nkUI.map.resetPosition")			

	mapInit = true

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "map.initMap", debugId) end
  
end

function internalFunc.mapToggleMinMax()
	uiElements.mapUI:ToggleMinMax()
end

function map.SetZone (newZoneID)

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "map.SetZone") end

	local newWorld = LibMap.map.getZoneWorld(newZoneID)
	local isNewWorld = false

	if newWorld ~= mapData.currentWorld then isNewWorld = true end

	if mapData.lastZone ~= nil then
		map.ShowPOI(false)
		map.ShowRareMobs(false)
		if isNewWorld then map.ShowQuest(false) end
		if nkUISetup.modules.map.trackGathering == true then map.ShowGathering(false) end
		if nkUISetup.modules.map.trackArtifacts == true then map.ShowArtifacts(false) end

		-- Clear tiled map elements when changing zones
		if uiElements.tiledMapUI then
			uiElements.tiledMapUI:ClearElements()
		end
	end

	mapData.currentWorld = newWorld

	if mapData.currentWorld == nil then
		LibEKL.Tools.Error.Display ("nkUI.map", "zone " .. newZoneID .. " not found", 2)
		mapData.currentWorld = "unknown"
		--return
	end

	uiElements.mapUI:SetMap("world", mapData.currentWorld)
--[[
	-- Update tiled map world if it's world1-4
	if uiElements.tiledMapUI then
		if mapData.currentWorld == "world1" then
			uiElements.tiledMapUI:SetWorld(LibMap.map.getMapData("world1_tiles"))
		elseif mapData.currentWorld == "world2" then
			uiElements.tiledMapUI:SetWorld(LibMap.map.getMapData("world2_tiles"))
		elseif mapData.currentWorld == "world3" then
			uiElements.tiledMapUI:SetWorld(LibMap.map.getMapData("world3_tiles"))
		elseif mapData.currentWorld == "world4" then
			uiElements.tiledMapUI:SetWorld(LibMap.map.getMapData("world4_tiles"))
		end
	end
]]

	local details = LibEKL.Unit.GetPlayerDetails()
	mapData.locationName = details.locationName
	uiElements.mapUI:SetCoord(details.coordX, details.coordZ)
	uiElements.mapUI:SetCoordsLabel(details.coordX, details.coordZ)


	_zoneDetails = InspectZoneDetail(newZoneID)
	uiElements.mapUI:SetZoneTitle(nkUISetup.modules.map.showZoneTitle)

	--[[
	-- Update tiled map zone title
	if uiElements.tiledMapUI then
		uiElements.tiledMapUI:SetZoneTitle(mapData.locationName)
	end
	]]

	if InspectSystemSecure() == false then Command.System.Watchdog.Quiet() end

	mapData.lastZone = newZoneID
	map.ShowPOI(true)  
	map.ShowCustomPoints()
	map.ShowRareMobs(true)
	map.FindMissing()

	if isNewWorld then map.ShowQuest(true) end

	if nkUISetup.modules.map.trackGathering == true then map.ShowGathering(true) end
	if nkUISetup.modules.map.trackArtifacts == true then map.ShowArtifacts(true) end

	if nkDebug and uiElements.debugPane then
		local mapInfo = uiElements.mapUI:GetMapInfo()
		uiElements.debugPanel:SetCoord(mapInfo.x1, mapInfo.x2, mapInfo.y1, mapInfo.y2)
	end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "map.SetZone", debugId) end

end

local function mapRemove (key, checkForMinimapQuest)

	if checkForMinimapQuest == true or checkForMinimapQuest == nil then
		if map.IsKnownMinimapQuest (key) == false then uiElements.mapUI:RemoveElement(key) end
	else
		uiElements.mapUI:RemoveElement(key)
	end

end

local function _trackGathering(details)

    if nkUIMapGathering.gatheringData[mapData.lastZone] == nil then nkUIMapGathering.gatheringData[mapData.lastZone] = {} end
    if nkUIMapGathering.artifactsData[mapData.lastZone] == nil then nkUIMapGathering.artifactsData[mapData.lastZone] = {} end

    for key, data in pairs(nkUIMapGathering.gatheringData[mapData.lastZone]) do
        if mapData.coordX == details.coordX and mapData.coordZ == details.coordZ then return end
    end

    local thisData = LibEKLTableCopy(details)
    thisData.type = "TRACK" .. string.match(thisData.type, "RESOURCE(.+)")
    local thisType = string.match(details.type, "RESOURCE%.(.+)") or string.match(details.type, "RESOURCE%.(.+)%.")
    thisData.id = thisType .. "-" .. LibEKLUUID()
    thisData.alpha = 0.5  -- stored gathering locations at 50% opacity to distinguish from live resources

    if thisType == "ARTIFACT" then
        nkUIMapGathering.artifactsData[mapData.lastZone][thisData.id] = thisData
    else
        nkUIMapGathering.gatheringData[mapData.lastZone][thisData.id] = thisData
    end
end

local function mapAdd (key, details)

	if details["type"] == nil then
		if nkDebug then
			nkDebug.logEntry (addonInfo.identifier, "map.UpdateMap add", "details.type == nil", details)
		end
	elseif details.type ~= "UNKNOWN" and details.type ~= "PORTAL" then
		uiElements.mapUI:AddElement(details)

		--[[
		-- Also add to tiled map if it exists
		if uiElements.tiledMapUI then
			uiElements.tiledMapUI:AddElement(details)
		end
		]]

		local thisType = RESOURCE_TYPE_MAP[details.type] or stringMatch(details.type, "RESOURCE%.(.+)")
		if thisType and nkUISetup.modules.map.trackGathering == true then _trackGathering(details, thisType) end
	elseif details.type == "UNKNOWN" then
		if mapData.postponedAdds == nil then mapData.postponedAdds = {} end
		if LibQB.query.isInit() == false or LibQB.query.isPackageLoaded('poa') == false or LibQB.query.isPackageLoaded('nt') == false or LibQB.query.isPackageLoaded('classic') == false then
			mapData.postponedAdds[key] = details
		else
			if InspectSystemWatchdog() < 0.1 then
				mapData.postponedAdds[key] = details
			else
				map.DebugLogUnknown(details, "mapAdd.initial")
				if map.IsKnownMinimapQuest (details.id) == false then
					if nkUISetup.modules.map.showUnknown == true then
						local retValue = map.CheckUnknownForQuest(details)
						if not retValue then
							map.DebugLogUnknown(details, "mapAdd.unidentified", { questCheckResult = false })
							uiElements.mapUI:AddElement(details)
							--[[if uiElements.tiledMapUI then
								uiElements.tiledMapUI:AddElement(details)
							end]]
						end
					end
				else
					uiElements.mapUI:AddElement(mapData.minimapIdToQuest[details.id])
					--[[if uiElements.tiledMapUI then
						uiElements.tiledMapUI:AddElement(mapData.minimapIdToQuest[details.id])
					end]]
				end
			end
		end
	end

end

local function mapChange (key, details, debugSource)

	if uiElements.mapUI:ChangeElement(details) == false then
		if nkDebug then
			nkDebug.logEntry (addonInfo.identifier, "map.UpdateMap change", "failed " .. debugSource, details)
			map.UpdateMap ({[key] = details}, "add", debugSource)
		end
	end

	--[[
	-- Also update tiled map if it exists
	if uiElements.tiledMapUI then
		uiElements.tiledMapUI:UpdateElement(details)
	end
	]]

end

local function mapCoord (key, details, debugSource)

	if uiElements.mapUI:ChangeElement(details) == false then
		map.UpdateMap ({[key] = details}, "add", debugSource)
		if nkDebug then 
			nkDebug.logEntry (addonInfo.identifier, "map.UpdateMap coord", "failed " .. debugSource, details)
		end
	end

end

local function mapWaypointAdd (key, details)

	local unitDetails = InspectUnitDetail(key)
	uiElements.mapUI:AddElement({ id = "wp-" .. key, type = "WAYPOINT", descList = { unitDetails.name }, coordX = details.coordX, coordZ = details.coordZ })
	mapData.waypoints[key] = { coordX = details.coordX, coordZ = details.coordZ }
	if key == LibEKL.Unit.GetPlayerID() then mapData.waypoints[key].player = true end
	map.UpdateWaypointArrows ()  

end

local function mapWaypointRemove (key)

	uiElements.mapUI:RemoveElement( "wp-" .. key)

	local thisWayPoint = mapData.waypoints[key]

	if thisWayPoint ~= nil and thisWayPoint.gfx ~= nil then
		thisWayPoint.gfx:SetVisible(false)
		if not uiElements.mapWaypoints then uiElements.mapWaypoints = {} end		
    	table.insert(uiElements.mapWaypoints, thisWayPoint.gfx)
	end

	mapData.waypoints[key] = nil
	map.UpdateWaypointArrows()

end

local function mapWaypointChange(key, details, debugSource)

	if uiElements.mapUI:ChangeElement({ id =  "wp-" .. key, coordX = details.coordX, coordZ = details.coordZ }) == false then
		if nkDebug then
			nkDebug.logEntry (addonInfo.identifier, "map.UpdateMap waypoint-change", "failed " .. debugSource, { id =  "wp-" .. key, coordX = details.coordX, coordZ = details.coordZ })
		end
	end
	mapData.waypoints[key].coordX = details.coordX
	mapData.waypoints[key].coordZ = details.coordZ
	map.UpdateWaypointArrows ()

end

function map.UpdateMap (mapInfo, action, debugSource, checkForMinimapQuest)

	if uiElements.mapUI == nil then 
		if nkDebug then nkDebug.logEntry (addonInfo.identifier, "map.UpdateMap", "No mapUI", mapInfo) end
		return 
	end

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "map.UpdateMap") end
	
	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "map.UpdateMap", stringFormat("%s - %s", action, debugSource), mapInfo) end	

	for key, details in pairs (mapInfo) do
		if action == "remove" then
			mapRemove (key, checkForMinimapQuest)
		elseif action == "add" then
			mapAdd (key, details)
		elseif action == "change" then
			mapChange (key, details, debugSource)
		elseif action == "coord" then
			mapCoord (key, details, debugSource)
		elseif action == "waypoint-add" then
			mapWaypointAdd (key, details)
		elseif action == "waypoint-remove" then
			mapWaypointRemove (key)
		elseif action == "waypoint-change" then
			mapWaypointChange(key, details, debugSource)
		end
	end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "map.UpdateMap", debugId) end

end

local function unitAdd (key, details)

	if details.type == "player" then
		local unitDetails = InspectUnitDetail("player")
		details.type = "UNIT.PLAYER"
		details.title = unitDetails.name
		details.angle = 0
		mapData.centerElement = key
		uiElements.mapUI:AddElement(details)

		--[[
		-- Also add to tiled map if it exists
		if uiElements.tiledMapUI then
			uiElements.tiledMapUI:AddElement(details)
		end
		]]

	elseif details.type == "player.pet" then
		local unitDetails = InspectUnitDetail("player.pet")
		details.type = "UNIT.PLAYERPET"
		details.title = unitDetails.name
		uiElements.mapUI:AddElement(details)

		--[[
		-- Also add to tiled map if it exists
		if uiElements.tiledMapUI then
			uiElements.tiledMapUI:AddElement(details)
		end
		]]

	elseif stringFind(details.type, "group") ~= nil and stringFind(details.type, "group..%.") == nil then
		local unitDetails = InspectUnitDetail(details.type)
		details.type = "UNIT.GROUPMEMBER"
		details.title = unitDetails.name
		details.smoothCoords = true
		uiElements.mapUI:AddElement(details)

	end

end

local function unitChange(key, details)

	if key == LibEKL.Unit.GetPlayerID() then
		local coordX, coordZ = uiElements.mapUI:GetCoords()         
		local deltaZ = details.coordZ - coordZ
		local deltaX = details.coordX - coordX

		local angle = mathDeg(mathAtan2(deltaZ, deltaX))								
		details.angle = -angle
	end

	if key == mapData.playerTargetUID then
		details.id = "npc" .. key
		if uiElements.mapUI:ChangeElement(details) == false then
			if nkDebug then
				nkDebug.logEntry (addonInfo.identifier, "map.UpdateUnit", "could not change element", details)
			end
		end

		details.id = "t" .. key
		if uiElements.mapUI:ChangeElement(details) == false then
			if nkDebug then
				nkDebug.logEntry (addonInfo.identifier, "map.UpdateUnit", "could not change element", details)
			end
		end

	elseif stringFind(details.type, "mouseover") == nil and stringFind(details.type, ".pet") == nil and stringFind(details.type, "player.target.target.target") == nil then
		if uiElements.mapUI:ChangeElement(details) == false then
			if details.type == 'player.target' then
				map.UpdateUnit ({[key] = details}, "add")
			else
				if nkDebug then
					nkDebug.logEntry (addonInfo.identifier, "map.UpdateUnit", "could not change element", details)
				end
			end
		end
	end

	if key == LibEKL.Unit.GetPlayerID() then
		uiElements.mapUI:SetCoord(details.coordX, details.coordZ)
		uiElements.mapUI:SetCoordsLabel(details.coordX, details.coordZ)		

		map.UpdateWaypointArrows ()
	end

end

local function unitRemove (key)

	uiElements.mapUI:RemoveElement(key)

	--[[
	-- Also remove from tiled map if it exists
	if uiElements.tiledMapUI then
		uiElements.tiledMapUI:RemoveElement(key)
	end
	]]

	if key == mapData.centerElement then mapData.centerElement = nil end

end

function map.UpdateUnit (mapInfo, action)

	if uiElements.mapUI == nil then return end

	local debugId 
	if nkDebug then 
		debugId = nkDebug.traceStart (addonInfo.identifier, "map.UpdateUnit") 
	end

	for key, details in pairs (mapInfo) do
	
		if action == "add" then
			unitAdd (key, details)
		elseif action == "change" then
			unitChange(key, details)
		elseif action == "remove" then
			unitRemove (key)
		end
	end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "map.UpdateUnit", debugId) end

end