local addonInfo, privateVars = ...

---------- init namespace ---------

--if not nkUI then nkUI = {} end

--privateVars.data          = {}
--privateVars.internalFunc  = {}
--privateVars.uiElements    = {}
--privateVars.events        = {}

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events

local stringFind    = string.find
local stringMatch   = string.match
local stringFormat  = string.format

---------- init local variables ---------

---------- make global functions local ---------

local _oInspectTimeReal = Inspect.Time.Real

---------- init variables ---------

data.playerUID            = nil -- id of the current player
data.playerTargetUID      = nil -- id of the player's target
data.lastZone             = nil -- id of the current zone e.g. the last zone entered
data.currentWorld         = nil -- id of the current map world
data.centerElement        = nil -- id of the element which is the center of the map (normally the player icon)
data.waypoints            = {}  -- list of the currently known and displayed waypoints
data.collectStart         = nil -- time the last time the player started interacting with a world element (mostly collecting something)
data.rareMobKilled        = {}  -- list of killed raremobs

data.rareMobAchievements  =  {"c5C766AF68015CB70", -- classic
                              "c5057BAEBDEA774CE", -- ember isle
                              "c128FB25EE807902B", -- storm legion
                              "c7443CBB86FC99D5E"  -- nightmare tidde
                              }

---------- generate ui context ---------

uiElements.contextMap = UI.CreateContext("nkUI.map")
uiElements.contextMap:SetStrata ('dialog')

uiElements.contextMapSecure = UI.CreateContext("nkUI.mapSecure")
uiElements.contextMapSecure:SetStrata ('topmost')
uiElements.contextMapSecure:SetSecureMode ('restricted')

---------- local function block ---------

function internalFunc.mapShowHide()

	if uiElements.mapUI:GetVisible() == true then
      uiElements.mapUI:SetVisible(false)
    else
      uiElements.mapUI:SetVisible(true)
    end 

end

local function _languageNotSupported () 

  uiElements.nsDialog = LibEKL.uiCreateFrame("nkDialog", "nkUI.map.dialog.notsupported", uiElements.contextMapMap)
  uiElements.nsDialog:SetPoint("CENTER", UIParent, "CENTER")
  uiElements.nsDialog:SetType("OK")
  uiElements.nsDialog:SetMessage("The map module relies on pattern recognition of texts provided by the RIFT API.\n\nUnfortunately your client's language is not supported yet.")
  
end

function internalFunc.mapInit()

    local syslang = Inspect.System.Language()

    if syslang == "French" or syslang == "Russian" then
      _languageNotSupported()
      nkUISetup.modules.map.activate = false
      return
    end

    --RESOURCE.ARTIFACT
    
    for key, design in pairs(data.resourceData) do
      local ressourceEntries = LibEKL.Map.GetMapElementbyType (key)
      for key2, details in pairs (ressourceEntries) do
        LibEKL.Map.replaceMapElement ("TRACK" .. stringMatch (key2, "RESOURCE(.+)"), design)
      end		
    end
	
    LibEKL.Map.replaceMapElement ("TRACK.ARTIFACT.NORMAL", data.resourceData['RESOURCE.ARTIFACT'])
    LibEKL.Map.replaceMapElement ("TRACK.ARTIFACT.TWISTED", data.resourceData['RESOURCE.ARTIFACT'])
    LibEKL.Map.replaceMapElement ("TRACK.ARTIFACT.UNSTABLE", data.resourceData['RESOURCE.ARTIFACT'])
    LibEKL.Map.replaceMapElement ("TRACK.ARTIFACT.FAEYULE", data.resourceData['RESOURCE.ARTIFACT'])
    LibEKL.Map.replaceMapElement ("TRACK.ARTIFACT.OTHER", data.resourceData['RESOURCE.ARTIFACT'])
    LibEKL.Map.replaceMapElement ("TRACK.BOAT", data.resourceData['RESOURCE.ARTIFACT'])
    LibEKL.Map.replaceMapElement ("TRACK.ARTIFACT.POISON", data.resourceData['RESOURCE.ARTIFACT'])
    LibEKL.Map.replaceMapElement ("TRACK.ARTIFACT.BURNING", data.resourceData['RESOURCE.ARTIFACT'])
    LibEKL.Map.replaceMapElement ("TRACK.ARTIFACT.NIGHTMARE", data.resourceData['RESOURCE.ARTIFACT'])
    
    -- add custom elements
      
    for key, data in pairs (data.customElements) do
      LibEKL.Map.addMapElement (key, data)
    end
      
    LibQB.loadPackage("classic")
    LibQB.loadPackage("nt")
    LibQB.loadPackage("sfp")
    LibQB.loadPackage("poa")

    LibEKL.Map.Init(true)
    LibEKL.Map.ZoneInit(true)
    LibEKL.Inventory.Init()
    LibEKL.Unit.Init()
        
    for idx = 1, #data.rareMobAchievements, 1 do
      events.achievementUpdate (_, { [data.rareMobAchievements[idx]] = true })
    end
    
	  Command.Event.Attach(Event.System.Update.Begin, events.SystemUpdate, "nkUI.System.Update.Begin")
    Command.Event.Attach(LibEKL.Events["LibEKL.Map"].add, function (a, mapInfo) internalFunc.UpdateMap(mapInfo, "add", "LibEKL.Map.add") end, "nkUI.LibEKL.Map.add")
    Command.Event.Attach(LibEKL.Events["LibEKL.Map"].change, function (_, mapInfo)  internalFunc.UpdateMap(mapInfo, "change", "LibEKL.Map.change Event") end, "nkUI.LibEKL.Map.change")
    Command.Event.Attach(LibEKL.Events["LibEKL.Map"].remove, function (_, mapInfo) internalFunc.UpdateMap(mapInfo, "remove") end, "nkUI.LibEKL.Map.remove")
    Command.Event.Attach(LibEKL.Events["LibEKL.Map"].coord, function (_, mapInfo) internalFunc.UpdateMap(mapInfo, "coord", "LibEKL.Map.coord Event") end, "nkUI.LibEKL.Map.coord")
    Command.Event.Attach(LibEKL.Events["LibEKL.Map"].zone, function (_, mapInfo) events.ZoneChange (_, mapInfo) end, "nkUI.LibEKL.Map.zone")
    Command.Event.Attach(LibEKL.Events["LibEKL.Map"].shard, function (_, mapInfo) events.ShardChange (_, mapInfo) end, "nkUI.LibEKL.Map.shard")
    Command.Event.Attach(LibEKL.Events["LibEKL.waypoint"].add, function (_, mapInfo) internalFunc.UpdateMap(mapInfo, "waypoint-add") end, "nkUI.LibEKL.waypoint.add")
    Command.Event.Attach(LibEKL.Events["LibEKL.waypoint"].change, function (_, mapInfo) internalFunc.UpdateMap(mapInfo, "waypoint-change") end, "nkUI.LibEKL.waypoint.change")
    Command.Event.Attach(LibEKL.Events["LibEKL.waypoint"].remove, function (_, mapInfo) internalFunc.UpdateMap(mapInfo, "waypoint-remove") end, "nkUI.LibEKL.waypoint.remove")
    Command.Event.Attach(LibEKL.Events["LibEKL.Map"].unitAdd, function (_, mapInfo) internalFunc.UpdateUnit(mapInfo, "add") end, "nkUI.LibEKL.Map.unitAdd")
    Command.Event.Attach(LibEKL.Events["LibEKL.Map"].unitRemove, function (_, mapInfo) internalFunc.UpdateUnit(mapInfo, "remove") end, "nkUI.LibEKL.Map.unitRemove")
    Command.Event.Attach(LibEKL.Events["LibEKL.Map"].unitChange, function (_, mapInfo) internalFunc.UpdateUnit(mapInfo, "change") end, "nkUI.LibEKL.Map.unitChange")
    
    Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].Update, function (_, thisData)
      if data.collectStart and Inspect.Time.Real() - data.collectStart < 2 then        
		    internalFunc.CollectArtifact(thisData)
		    data.collectStart = nil
      end      
    end, "nkUI.LibEKL.InventoryManager.Update")
       
    Command.Event.Attach(LibEKL.Events["LibEKL.Unit"].GroupStatus, events.GroupStatus, "nkUI.LibEKL.Unit.GroupStatuss")
    Command.Event.Attach(LibEKL.Events["LibEKL.Unit"].Change, events.UnitChange, "nkUI.LibEKL.Unit.Change")
    
    --Command.Event.Attach(LibEKL.Events["LibEKL.Unit"].PlayerAvailable, events.playerAvailable, "nkUI.LibEKL.Unit.PlayerAvailable")
	
    Command.Event.Attach(Event.Unit.Availability.None, events.UnitUnavailable, "nkUI.Unit.Availability.None")
    
    Command.Event.Attach(Event.Quest.Accept, events.QuestAccept, "nkUI.Quest.Accept")
    Command.Event.Attach(Event.Quest.Abandon, events.QuestAbandon, "nkUI.Quest.Abandon")
    Command.Event.Attach(Event.Quest.Change, events.QuestChange, "nkUI.Quest.Change")
    Command.Event.Attach(Event.Quest.Complete, events.QuestComplete, "nkUI.Quest.Complete")
    
    Command.Event.Attach(Event.Unit.Castbar, events.UnitCastBar, "nkUI.Unit.Castbar")
    Command.Event.Attach(Event.Unit.Detail.LocationName, events.UpdateLocation, "nkUI.Unit.Detail.LocationName")
    
    Command.Event.Attach(Event.Achievement.Update, events.achievementUpdate, "nkUI.Achievement.Update")

    if nkUISetup.modules.map.syncTarget == true then
      Command.Message.Accept("raid", "nkUI.target")
      Command.Message.Accept("party", "nkUI.target")
      
      Command.Event.Attach(Event.Message.Receive, events.messageReceive, "nkUI.Message.Receive")
    end

    events.playerAvailable()
    
end