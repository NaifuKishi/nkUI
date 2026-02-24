local addonInfo, privateVars = ...

---------- init namespace ---------

if not privateVars.map then privateVars.map = {} end
if not privateVars.mapEvents then privateVars.mapEvents = {} end
if not privateVars.mapData then privateVars.mapData = {} end

local map           = privateVars.map
local mapEvents     = privateVars.mapEvents
local internalFunc  = privateVars.internalFunc
local mapData       = privateVars.mapData
local uiElements    = privateVars.uiElements
local events        = privateVars.events

local stringFind    = string.find
local stringMatch   = string.match
local stringFormat  = string.format

local _oInspectTimeReal = Inspect.Time.Real

---------- init variables ---------

mapData.playerTargetUID      = nil -- id of the player's target
mapData.lastZone             = nil -- id of the current zone e.g. the last zone entered
mapData.currentWorld         = nil -- id of the current map world
mapData.centerElement        = nil -- id of the element which is the center of the map (normally the player icon)
mapData.waypoints            = {}  -- list of the currently known and displayed waypoints
mapData.collectStart         = nil -- time the last time the player started interacting with a world element (mostly collecting something)
mapData.rareMobKilled        = {}  -- list of killed raremobs

mapData.rareMobAchievements  =  { "c5C766AF68015CB70", -- classic
                                  "c5057BAEBDEA774CE", -- ember isle
                                  "c128FB25EE807902B", -- storm legion
                                  "c7443CBB86FC99D5E"  -- nightmare tidde
                                }

uiElements.mapContext = UI.CreateContext("nkUI.map")
uiElements.mapContext:SetStrata ('dialog')

uiElements.mapContextSecure = UI.CreateContext("nkUI.map.secure")
uiElements.mapContextSecure:SetStrata ('topmost')
uiElements.mapContextSecure:SetSecureMode ('restricted')

function internalFunc.mapShowHide()

	if uiElements.mapUI:GetVisible() == true then
      uiElements.mapUI:SetVisible(false)
      if uiElements.tiledMapUI then
		    uiElements.tiledMapUI:SetVisible(false)
	    end
    else
      uiElements.mapUI:SetVisible(true)
      if uiElements.tiledMapUI then
		    uiElements.tiledMapUI:SetVisible(true)
	    end
    end

end

function internalFunc.mapInit()

  LibMap.defaultIconSize = nkUISetup.modules.map.iconSize

  local syslang = Inspect.System.Language()

  if syslang == "French" then return end

  --RESOURCE.ARTIFACT
  
  for key, design in pairs(mapData.resourceData) do
    local ressourceEntries = LibMap.map.GetMapElementbyType (key)
    for key2, details in pairs (ressourceEntries) do
      LibMap.map.replaceMapElement ("TRACK" .. stringMatch (key2, "RESOURCE(.+)"), design)
    end		
  end
	
  LibMap.map.replaceMapElement ("TRACK.ARTIFACT.NORMAL", mapData.resourceData['RESOURCE.ARTIFACT'])
  LibMap.map.replaceMapElement ("TRACK.ARTIFACT.TWISTED", mapData.resourceData['RESOURCE.ARTIFACT'])
  LibMap.map.replaceMapElement ("TRACK.ARTIFACT.UNSTABLE", mapData.resourceData['RESOURCE.ARTIFACT'])
  LibMap.map.replaceMapElement ("TRACK.ARTIFACT.FAEYULE", mapData.resourceData['RESOURCE.ARTIFACT'])
  LibMap.map.replaceMapElement ("TRACK.ARTIFACT.OTHER", mapData.resourceData['RESOURCE.ARTIFACT'])
  LibMap.map.replaceMapElement ("TRACK.BOAT", mapData.resourceData['RESOURCE.ARTIFACT'])
  LibMap.map.replaceMapElement ("TRACK.ARTIFACT.POISON", mapData.resourceData['RESOURCE.ARTIFACT'])
  LibMap.map.replaceMapElement ("TRACK.ARTIFACT.BURNING", mapData.resourceData['RESOURCE.ARTIFACT'])
  LibMap.map.replaceMapElement ("TRACK.ARTIFACT.NIGHTMARE", mapData.resourceData['RESOURCE.ARTIFACT'])
    
  -- add custom elements
    
  for key, data in pairs (mapData.customElements) do
    LibMap.map.addMapElement (key, data)
  end
    
  LibQB.loadPackage("classic")
  LibQB.loadPackage("nt")
  LibQB.loadPackage("sfp")
  LibQB.loadPackage("poa")

  LibMap.map.init(true)
  LibMap.map.zoneInit(true)
  
  for idx = 1, #mapData.rareMobAchievements, 1 do
    mapEvents.achievementUpdate (_, { [mapData.rareMobAchievements[idx]] = true })
  end
  
	Command.Event.Attach(Event.System.Update.Begin, mapEvents.SystemUpdate, "nkUI.System.Update.Begin")	

  Command.Event.Attach(LibMap.events["LibMap.map"].add, function (a, mapInfo) map.UpdateMap(mapInfo, "add", "LibEKL.map.add") end, "nkUI.LibMap.map.add")
  Command.Event.Attach(LibMap.events["LibMap.map"].change, function (_, mapInfo)  map.UpdateMap(mapInfo, "change", "LibMap.map.change Event") end, "nkUI.LibMap.map.change")
  Command.Event.Attach(LibMap.events["LibMap.map"].remove, function (_, mapInfo) map.UpdateMap(mapInfo, "remove") end, "nkUI.LibMap.map.remove")
  Command.Event.Attach(LibMap.events["LibMap.map"].coord, function (_, mapInfo) map.UpdateMap(mapInfo, "coord", "LibMap.map.coord Event") end, "nkUI.LibMap.map.coord")
  Command.Event.Attach(LibMap.events["LibMap.waypoint"].add, function (_, mapInfo) map.UpdateMap(mapInfo, "waypoint-add") end, "nkUI.LibMap.waypoint.add")
  Command.Event.Attach(LibMap.events["LibMap.waypoint"].change, function (_, mapInfo) map.UpdateMap(mapInfo, "waypoint-change") end, "nkUI.LibMap.waypoint.change")
  Command.Event.Attach(LibMap.events["LibMap.waypoint"].remove, function (_, mapInfo) map.UpdateMap(mapInfo, "waypoint-remove") end, "nkUI.LibMap.waypoint.remove")
  Command.Event.Attach(LibMap.events["LibMap.map"].unitAdd, function (_, mapInfo) map.UpdateUnit(mapInfo, "add") end, "nkUI.LibMap.map.unitAdd")
  Command.Event.Attach(LibMap.events["LibMap.map"].unitRemove, function (_, mapInfo) map.UpdateUnit(mapInfo, "remove") end, "nkUI.LibMap.map.unitRemove")
  Command.Event.Attach(LibMap.events["LibMap.map"].unitChange, function (_, mapInfo) map.UpdateUnit(mapInfo, "change") end, "nkUI.LibMap.map.unitChange")

  Command.Event.Attach(LibMap.events["LibMap.map"].zone, function (_, mapInfo) mapEvents.ZoneChange (_, mapInfo) end, "nkUI.LibMap.map.zone")
  Command.Event.Attach(LibMap.events["LibMap.map"].shard, function (_, mapInfo) mapEvents.ShardChange (_, mapInfo) end, "nkUI.LibMap.map.shard")
    
  Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].Update, function (_, thisData)
    if mapData.collectStart and Inspect.Time.Real() - mapData.collectStart < 2 then        
      map.CollectArtifact(thisData)
      mapData.collectStart = nil
    end      
  end, "nkUI.LibEKL.InventoryManager.Update")
       
  Command.Event.Attach(LibEKL.Events["LibEKL.Unit"].GroupStatus, mapEvents.GroupStatus, "nkUI.LibEKL.Unit.GroupStatuss")
  Command.Event.Attach(LibEKL.Events["LibEKL.Unit"].Change, mapEvents.UnitChange, "nkUI.LibEKL.Unit.Change")

  Command.Event.Attach(Event.Unit.Availability.None, mapEvents.UnitUnavailable, "nkUI.Unit.Availability.None")

  Command.Event.Attach(Event.Quest.Accept, mapEvents.QuestAccept, "nkUI.Quest.Accept")
  Command.Event.Attach(Event.Quest.Abandon, mapEvents.QuestAbandon, "nkUI.Quest.Abandon")
  Command.Event.Attach(Event.Quest.Change, mapEvents.QuestChange, "nkUI.Quest.Change")
  Command.Event.Attach(Event.Quest.Complete, mapEvents.QuestComplete, "nkUI.Quest.Complete")
  
  Command.Event.Attach(Event.Unit.Castbar, mapEvents.UnitCastBar, "nkUI.Unit.Castbar")
  Command.Event.Attach(Event.Unit.Detail.LocationName, mapEvents.UpdateLocation, "nkUI.Unit.Detail.LocationName")
  
  Command.Event.Attach(Event.Achievement.Update, mapEvents.achievementUpdate, "nkUI.Achievement.Update")

  LibEKL.Events.AddInsecure(function()    
    map.initMap()

    local details = LibEKL.Unit.GetUnitDetail('player.target')
    if details ~= nil then mapEvents.processPlayerTarget(details.id, details) end    
	
	  map.UpdateWaypointArrows()

    map.mapLegendInit()
  end, Inspect.Time.Frame(), 2)  

end