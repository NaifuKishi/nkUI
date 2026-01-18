local addonInfo, privateVars = ...

---------- init namespace ---------

local data                  = privateVars.data
local uiElements            = privateVars.uiElements
local internalFunc          = privateVars.internalFunc
local events               = privateVars.events
local lang        			= privateVars.langTexts

---------- init local variables ---------

local _zoneDetails          = nil
local _rareData             = {}

---------- make global functions local ---------

local inspectUnitDetail 	= Inspect.Unit.Detail
local inspectZoneDetail 	= Inspect.Zone.Detail
local inspectSystemSecure 	= Inspect.System.Secure
local inspectSystemWatchdog = Inspect.System.Watchdog
local inspectItemDetail 	= Inspect.Item.Detail
local inspectMouse 			= Inspect.Mouse
local inspectTimeReal 		= Inspect.Time.Real

local LibEKLGetLanguage			= LibEKL.Tools.Lang.GetLanguage
local LibEKLGetLanguageShort	= LibEKL.Tools.Lang.GetLanguageShort
local LibEKLTableCopy			= LibEKL.Tools.Table.copy
local LibEKLUUID				= LibEKL.Tools.UUID

local stringFind			= string.find
local stringMatch			= string.match
local stringFormat			= string.format
local stringUpper			= string.upper

local mathDeg				= math.deg
local mathAtan2				= math.atan2

data.borderDesign = {DE = "Schwarz dünn", EN = "Black simple", RU = "Black simple", addon = "nkUI", path = "gfx/bgBlack.png", offset = 2}

---------- local function block ---------

local function _processRareData(id, counter, name, x, z, comment)
  
  local thisId = "rare-" .. id .. "-" .. counter
          
  local thisData = { id = thisId, type = "UNIT.RARE", descList = {name }, coordX = x, coordZ = z }
  table.insert(thisData.descList, "Rare Mob")
  
  if comment ~= "" then table.insert(thisData.descList, comment) end      
  
  uiElements.mapUI:AddElement(thisData)
  _rareData[thisId] = thisData
end

local function _getRareDarData ()
  
  if _zoneDetails == nil then return end
  
  _rareData = {}
  
  for idx = 1, #RareDar.data, 1 do
    if RareDar.data[idx].zone[LibEKLGetLanguage()] == _zoneDetails.name then
      local mobs = RareDar.data[idx].mobs
      
      for idx2 = 1, #mobs, 1 do
        if data.rareMobKilled[mobs[idx2].achv[LibEKLGetLanguage()]] ~= true then      
          local posList = mobs[idx2].pos
          
          for idx3 = 1, #posList, 1 do
            _processRareData(mobs[idx2].id, idx3, mobs[idx2].targ[LibEKLGetLanguage()], posList[idx3][1], posList[idx3][2], mobs[idx2].comment[LibEKLGetLanguage()])
          end
        end
      end
      
    end 
  end

end

local function _getRareTrackerData ()

  local zoneData = Inspect.Addon.Detail('RareTracker').data.moblocs[data.lastZone]
  
  if zoneData == nil then return end

  local mobs = zoneData.mobs
  
  _rareData = {}
  
  for idx = 1, #mobs, 1 do
    
    if data.rareMobKilled[mobs[idx].n[LibEKLGetLanguageShort()]] ~= true then      
  
      local posList = mobs[idx].loc
      
      for idx2 = 1, #posList, 1 do
        _processRareData(mobs[idx].n[LibEKLGetLanguageShort()], idx2, mobs[idx].n[LibEKLGetLanguageShort()], posList[idx2].x, posList[idx2].z, "")
      end
    end
  end
  
end

local function _trackGathering (details)

	if nkUIMapGathering.gatheringData[data.lastZone] == nil then nkUIMapGathering.gatheringData[data.lastZone] = {} end
	if nkUIMapGathering.artifactsData[data.lastZone] == nil then nkUIMapGathering.artifactsData[data.lastZone] = {} end

	for key, data in pairs (nkUIMapGathering.gatheringData[data.lastZone]) do
		if data.coordX == details.coordX and data.coordZ == details.coordZ then return end
	end

	local thisData = LibEKLTableCopy(details)
	thisData.type = "TRACK" .. stringMatch (thisData.type, "RESOURCE(.+)")

	local thisType = stringMatch(details.type, "RESOURCE%.(.+)") or stringMatch(details.type, "RESOURCE%.(.+)%.")
	thisData.id = thisType .. "-" .. LibEKLUUID()

	if thisType == "ARTIFACT" then
		nkUIMapGathering.artifactsData[data.lastZone][thisData.id] = thisData
	else  
		nkUIMapGathering.gatheringData[data.lastZone][thisData.id] = thisData
	end

end

local function _fctMapUI ()

	local mapUI = LibEKL.UICreateFrame("nkMap", "nkUI.map", uiElements.contextMap)

	local locked
	if nkUISetup.modules.map.locked == true then locked = false else locked = true end
	
	--mapUI:SetResizable(locked)
	--mapUI:SetDragable(locked)
	mapUI:SetLayer(2)

	mapUI:ShowHeader(false)
	mapUI:ShowCoords(false)	

	local texture = LibEKL.UICreateFrame("nkTexture", "nkUI.map.texture", uiElements.contextMap)
	texture:SetLayer(1)

	function mapUI:SetBackground(newBG)
		if nkUISetup.modules.map.background == nil then return end

		if data.borderDesign.addon == nil then
			texture:SetVisible(false)
		else
			texture:SetVisible(true)    
			texture:SetPoint("TOPLEFT", mapUI, "TOPLEFT", -data.borderDesign.offset, -data.borderDesign.offset)
			texture:SetPoint("BOTTOMRIGHT", mapUI, "BOTTOMRIGHT", data.borderDesign.offset, data.borderDesign.offset)
			texture:SetTextureAsync(data.borderDesign.addon, data.borderDesign.path)
		end
	end

	local oSetVisible = mapUI.SetVisible

	function mapUI:SetVisible(flag)
		oSetVisible(self, flag)
		texture:SetVisible(flag)
	end

	mapUI:SetBackground(nkUISetup.modules.map.background)

	local zoneTitle = LibEKL.UICreateFrame("nkText", "nkUI.map.zoneTitle", mapUI:GetMask())
	zoneTitle:SetPoint("CENTERTOP", mapUI:GetContent(), "CENTERTOP")
	zoneTitle:SetLayer(9999)
	
	LibEKL.UI.SetFont (zoneTitle, addonInfo.id, "MontserratSemiBold")

	zoneTitle:SetEffectGlow({ colorB = 0, colorA = 1, colorG = 0, colorR = 0, strength = 3, blurX = 3, blurY = 3 })

	local coords = LibEKL.UICreateFrame("nkText", "nkUI.map.coords", mapUI)
	coords:SetPoint("CENTERBOTTOM", mapUI:GetContent(), "CENTERBOTTOM", 0, 15)
	coords:SetLayer(9999)
	coords:SetFontSize(20)
	coords:SetEffectGlow({ strength = 3})
	
	LibEKL.UI.SetFont (coords, addonInfo.id, "MontserratBold")

	local mouseCoords = LibEKL.UICreateFrame("nkText", "nkUI.map.mouseCoords", mapUI)
	mouseCoords:SetPoint("CENTERBOTTOM", coords, "CENTERTOP", 0, 5)
	mouseCoords:SetLayer(9999)
	mouseCoords:SetFontSize(18)
	mouseCoords:SetFontColor(1, 0.8, 0, 1)
	mouseCoords:SetEffectGlow({ strength = 3})
	
	LibEKL.UI.SetFont (mouseCoords, addonInfo.id, "MontserratBold")

	function mapUI:SetCoordsLabel(x, y)
		coords:SetText(stringFormat("%d / %d", x, y))
	end

	function mapUI:SetZoneTitle(flag)

		if flag == false then
			zoneTitle:SetVisible(false)
		else
			zoneTitle:SetVisible(true)
			local scale = 1 / 300 * mapUI:GetWidth()
			local fontsize = 20 * scale
			if fontsize > 30 then fontsize = 30 end
			zoneTitle:SetFontSize(fontsize)
			zoneTitle:SetText(data.locationName)
		end
	end

	--[[local setupIcon = LibEKL.UICreateFrame("nkTexture", "nkUI.map.setupIcon",  mapUI:GetHeader())
	setupIcon:SetPoint("CENTERLEFT", mapUI:GetHeader(), "CENTERLEFT", 5, 0)
	setupIcon:SetHeight(16)
	setupIcon:SetWidth(16)
	setupIcon:SetTextureAsync("LibEKL", "gfx/icons/config.png")

	setupIcon:EventAttach(Event.UI.Input.Mouse.Left.Down, function () internalFunc.ShowConfig() end, setupIcon:GetName() .. ".Mouse.Left.Down")

	local waypointIcon = LibEKL.UICreateFrame("nkTexture", "nkUI.map.waypointIcon",  mapUI:GetHeader())
	waypointIcon:SetPoint("CENTERLEFT", setupIcon, "CENTERRIGHT", 5, 0)
	waypointIcon:SetHeight(16)
	waypointIcon:SetWidth(16)
	waypointIcon:SetTextureAsync("LibEKL", "gfx/icons/pin.png")

	waypointIcon:EventAttach(Event.UI.Input.Mouse.Left.Down, function () internalFunc.WaypointDialog() end, waypointIcon:GetName() .. ".Mouse.Left.Down")]]

	Command.Event.Attach(LibEKL.Events["nkUI.map"].MouseMoved, function (_, text)
		mouseCoords:SetText(text)
	end, "nkUI.map.MouseMoved")  

	Command.Event.Attach(LibEKL.Events["nkUI.map"].Moved, function (_, x, y, maximized)

		if maximized == true then
			nkUISetup.modules.map.maximizedX, nkUISetup.modules.map.maximizedY = x, y 
		else
			nkUISetup.modules.map.x, nkUISetup.modules.map.y = x, y
		end

	end, "nkUI.map.Moved")    

	Command.Event.Attach(LibEKL.Events["nkUI.map"].Resized, function (_, newWidth, newHeight, maximized)

		if maximized == true then
			nkUISetup.modules.map.maximizedWidth, nkUISetup.modules.map.maximizedHeight = newWidth, newHeight 
		else
			nkUISetup.modules.map.width, nkUISetup.modules.map.height = newWidth, newHeight
		end

	end, "nkUI.map.Moved")

	Command.Event.Attach(LibEKL.Events["nkUI.map"].Zoomed, function (_, newScale, maximized)
		if maximized == true then
			nkUISetup.modules.map.maximizedScale = newScale
		else
			nkUISetup.modules.map.scale = newScale
		end

	internalFunc.UpdateWaypointArrows ()

	end, "nkUI.map.Zoomed")

	Command.Event.Attach(LibEKL.Events["nkUI.map"].Toggled, function (_, newScale, maximized)
		internalFunc.UpdateWaypointArrows ()
		mapUI:SetZoneTitle(nkUISetup.modules.map.showZoneTitle)
	end, "nkUI.map.Toggled")

	return mapUI
	
end

---------- addon internal function block ---------

function internalFunc.initMap ()

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "internalFunc.initMap") end

	if uiElements.mapUI == nil then uiElements.mapUI = _fctMapUI() end

	uiElements.mapUI:SetAnimated(nkUISetup.modules.map.animations, nkUISetup.modules.map.animationSpeed)
	uiElements.mapUI:SetSmoothScroll(nkUISetup.modules.map.smoothScroll)

	uiElements.mapUI:SetWidth(nkUISetup.modules.map.width)
	uiElements.mapUI:SetHeight(nkUISetup.modules.map.height)

	local details = inspectUnitDetail(data.playerUID)
	internalFunc.SetZone (details.zone)

	uiElements.mapUI:SetPointMaximized(nkUISetup.modules.map.maximizedX, nkUISetup.modules.map.maximizedY)  
	uiElements.mapUI:SetWidthMaximized(nkUISetup.modules.map.maximizedWidth)
	uiElements.mapUI:SetHeightMaximized(nkUISetup.modules.map.maximizedHeight)

	uiElements.mapUI:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.map.x, nkUISetup.modules.map.y)
	uiElements.mapUI:SetZoom(nkUISetup.modules.map.scale, false)
	uiElements.mapUI:SetZoom(nkUISetup.modules.map.maximizedScale, true)

	local points, units = LibEKL.Map.getAll()
	internalFunc.UpdateMap(points, "add", "internalFunc.initMap")
	internalFunc.UpdateUnit (units, "add")

	if nkDebug and uiElements.debugPanel then
		local mapInfo = uiElements.mapUI:GetMapInfo()
		uiElements.debugPanel:SetCoord(mapInfo.x1, mapInfo.x2, mapInfo.y1, mapInfo.y2)
	end

	Command.Event.Attach(Event.System.Update.Begin, function ()
      
      if data.delayStart ~= nil then
          local tmpTime = inspectTimeReal()
          if LibEKL.Tools.Math.Round((tmpTime - data.delayStart), 1) > 1 then 
            uiElements.mapUI:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.map.x, nkUISetup.modules.map.y)
            Command.Event.Detach(Event.System.Update.Begin, nil, "nkUI.resetPosition")	
          end
      else
        data.delayStart = inspectTimeReal()
      end
      
    end, "nkUI.resetPosition")		

	local function _toggleMinMax()
		uiElements.mapUI:ToggleMinMax()
	end

    --LibEKL.manager.RegisterButton('nkUI.config', addonInfo.id, "gfx/minimapIcon.png", internalFunc.ShowConfig)
	--LibEKL.manager.RegisterButton('nkUI.toggle', addonInfo.id, "gfx/minimapIconCloseMap.png", internalFunc.mapShowHide)
	--LibEKL.manager.RegisterButton('nkUI.minmax', addonInfo.id, "gfx/minimapIconResize.png", _toggleMinMax)
    
    --local minimapFrame = LibEKL.manager.GetFrame()
    --if minimapFrame then      
--      minimapFrame:SetPoint("TOPLEFT", uiElements.mapUI, "BOTTOMLEFT")
--	  minimapFrame:SetWidth(uiElements.mapUI:GetWidth())
    --end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "internalFunc.initMap", debugId) end
  
end

function internalFunc.UpdateWaypointArrows ()

  if uiElements.mapUI == nil or data.centerElement == nil then return end
  
  local map = uiElements.mapUI:GetMap()
  local mapInfo = uiElements.mapUI:GetMapInfo()

  for key, details in pairs (data.waypoints) do
  
--	dump (details)
--	dump (mapInfo)
    if details.coordX >= mapInfo.x1 and details.coordX <= mapInfo.x2 and details.coordZ >= mapInfo.y1 and details.coordZ <= mapInfo.y2 then 
  
      if details.gfx == nil then
        details.gfx = LibEKL.UICreateFrame("nkCanvas", "nkUI.waypointarrow." .. LibEKLUUID(), uiElements.mapUI:GetMask())
        details.gfx:SetLayer(999)      
      end
      
      local canvas, width, height, xmod, zmod
      local coordX, coordZ = uiElements.mapUI:GetElement(data.centerElement):GetCoord()    
      local stroke = { thickness = 3, r = 1, g = 0.8, b = 0.4, a = 1}
      local headX, headY = 0, 0
          
      if details.player == true then stroke = { thickness = 3, r = 0.463, g = 0.741, b = 0.722, a = 1} end
      
      if details.coordX <= coordX then
      
        width, xmod = coordX - details.coordX, -1
      
        if details.coordZ <= coordZ then
          canvas = {{xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 0}}
          height, zmod = coordZ - details.coordZ, -1
        else
          canvas = {{xProportional = 1, yProportional = 0}, {xProportional = 0, yProportional = 1}}
          height, zmod, headY = details.coordZ - coordZ, 0, 1
        end
      else
        width, xmod, headX = details.coordX - coordX, 0, 1
      
        if details.coordZ <= coordZ then
          canvas = {{xProportional = 0, yProportional = 1}, {xProportional = 1, yProportional = 0}}
          height, zmod = coordZ - details.coordZ, -1
        else
          canvas = {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 1}}
          height, zmod, headY = details.coordZ - coordZ, 0, 1
        end
      end
          
      local newWidth = map:GetWidth() / (mapInfo.x2 - mapInfo.x1) * width
      local newHeight = map:GetHeight() / (mapInfo.y2 - mapInfo.y1) * height
      
      local xP = 1 / (mapInfo.x2 - mapInfo.x1) * (coordX - mapInfo.x1)
      local yP = 1 /  (mapInfo.y2 - mapInfo.y1) * (coordZ - mapInfo.y1) 
      
      local thisX = (map:GetWidth() * xP) 
      local thisY = (map:GetHeight() * yP)
  
      details.gfx:ClearAll()    
      details.gfx:SetWidth(newWidth)
      details.gfx:SetHeight(newHeight)
      details.gfx:SetShape(canvas, nil, stroke)
      details.gfx:SetPoint("TOPLEFT", map, "TOPLEFT", thisX + (newWidth * xmod), thisY + (newHeight * zmod))
    end
      
  end  

end

function internalFunc.SetZone (newZoneID)

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "internalFunc.SetZone") end

	local newWorld = LibEKL.Map.getZoneWorld(newZoneID)
	local isNewWorld = false

	if newWorld ~= data.currentWorld then isNewWorld = true end

	if data.lastZone ~= nil then 
		internalFunc.ShowPOI(false)
		internalFunc.ShowRareMobs(false)
		if isNewWorld then internalFunc.ShowQuest(false) end
		if nkUISetup.modules.map.trackGathering == true then internalFunc.ShowGathering(false) end
		if nkUISetup.modules.map.trackArtifacts == true then internalFunc.ShowArtifacts(false) end
	end

	data.currentWorld = newWorld

	if data.currentWorld == nil then
		LibEKL.Tools.Error.Display ("nkUI", "zone " .. newZoneID .. " not found", 2)
		data.currentWorld = "unknown"
		--return
	end

	uiElements.mapUI:SetMap("world", data.currentWorld)

	local details = inspectUnitDetail(data.playerUID)
	data.locationName = details.locationName
	uiElements.mapUI:SetCoord(details.coordX, details.coordZ)	
	uiElements.mapUI:SetCoordsLabel(details.coordX, details.coordZ)	

	_zoneDetails = inspectZoneDetail(newZoneID)
	uiElements.mapUI:SetZoneTitle(nkUISetup.modules.map.showZoneTitle)

	if inspectSystemSecure() == false then Command.System.Watchdog.Quiet() end

	data.lastZone = newZoneID
	internalFunc.ShowPOI(true)  
	internalFunc.ShowCustomPoints()
	internalFunc.ShowRareMobs(true)
	internalFunc.FindMissing()

	if isNewWorld then internalFunc.ShowQuest(true) end

	if nkUISetup.modules.map.trackGathering == true then internalFunc.ShowGathering(true) end
	if nkUISetup.modules.map.trackArtifacts == true then internalFunc.ShowArtifacts(true) end

	if nkDebug and uiElements.debugPane then
		local mapInfo = uiElements.mapUI:GetMapInfo()
		uiElements.debugPanel:SetCoord(mapInfo.x1, mapInfo.x2, mapInfo.y1, mapInfo.y2)
	end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "internalFunc.SetZone", debugId) end

end

function internalFunc.UpdateMap (mapInfo, action, debugSource, checkForMinimapQuest)

	if uiElements.mapUI == nil then 
		if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateMap", "No mapUI", mapInfo) end
		return 
	end

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "internalFunc.UpdateMap") end
	
	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateMap", stringFormat("%s - %s", action, debugSource), mapInfo) end
	
	for key, details in pairs (mapInfo) do
		if action == "remove" then
			--dump (mapInfo)

			if checkForMinimapQuest == true or checkForMinimapQuest == nil then
				if internalFunc.IsKnownMinimapQuest (key) == false then uiElements.mapUI:RemoveElement(key) end
			else
				uiElements.mapUI:RemoveElement(key)
			end
		elseif action == "add" then
			if details["type"] == nil then
				if nkDebug then
					nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateMap add", "details.type == nil", details)
				end
			elseif details.type ~= "UNKNOWN" and details.type ~= "PORTAL" then -- filter minimap portal and use poi portal instead
				--if debugSource == "processQuests" then dump (details) end
				uiElements.mapUI:AddElement(details)
				if stringFind(details.type, "RESOURCE") == 1 and nkUISetup.modules.map.trackGathering == true then _trackGathering(details) end
			elseif details.type == "UNKNOWN" then
				if data.postponedAdds == nil then data.postponedAdds = {} end
				if LibQB.query.isInit() == false or LibQB.query.isPackageLoaded('poa') == false or LibQB.query.isPackageLoaded('nt') == false or LibQB.query.isPackageLoaded('classic') == false then
					data.postponedAdds[key] = details
				else
					if inspectSystemWatchdog() < 0.1 then
						data.postponedAdds[key] = details
					else
						if internalFunc.IsKnownMinimapQuest (details.id) == false then
							if nkUISetup.modules.map.showUnknown == true then
								err, retValue = pcall(internalFunc.CheckUnknownForQuest, details)
								if err and not retValue then uiElements.mapUI:AddElement(details) end
							end
						else
							uiElements.mapUI:AddElement(data.minimapIdToQuest[details.id])
						end
					end
				end
			end
		elseif action == "change" then
			if uiElements.mapUI:ChangeElement(details) == false then
				if nkDebug then
					nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateMap change", "failed " .. debugSource, details)
					--print ("debugSource: " .. debugSource)
					--dump (details)
					 internalFunc.UpdateMap ({[key] = mapInfo}, "add", debugSource)
				end
			end
		elseif action == "coord" then
			if uiElements.mapUI:ChangeElement(details) == false then
				 
				 internalFunc.UpdateMap ({[key] = mapInfo}, "add", debugSource)
				
				if nkDebug then 
					nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateMap coord", "failed " .. debugSource, details)
					--print ("debugSource: " .. debugSource)
					--dump (details) 
				end
			end
		elseif action == "waypoint-add" then
			local unitDetails = inspectUnitDetail(key)
			uiElements.mapUI:AddElement({ id = "wp-" .. key, type = "WAYPOINT", descList = { unitDetails.name }, coordX = details.coordX, coordZ = details.coordZ })
			data.waypoints[key] = { coordX = details.coordX, coordZ = details.coordZ }
			if key == data.playerUID then data.waypoints[key].player = true end      
			internalFunc.UpdateWaypointArrows ()      
		elseif action == "waypoint-remove" then
			uiElements.mapUI:RemoveElement( "wp-" .. key)
			if data.waypoints[key] ~= nil and data.waypoints[key].gfx ~= nil then 
				data.waypoints[key].gfx:destroy()
				--data.waypoints[key].gfxArrow:destroy() 
			end
			data.waypoints[key] = nil
			internalFunc.UpdateWaypointArrows ()
		elseif action == "waypoint-change" then
			if uiElements.mapUI:ChangeElement({ id =  "wp-" .. key, coordX = details.coordX, coordZ = details.coordZ }) == false then
				if nkDebug then
					nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateMap waypoint-change", "failed " .. debugSource, { id =  "wp-" .. key, coordX = details.coordX, coordZ = details.coordZ })
					--print ("debugSource: " .. debugSource)
					--dump({ id =  "wp-" .. key, coordX = details.coordX, coordZ = details.coordZ })
				end
			end
			data.waypoints[key].coordX = details.coordX
			data.waypoints[key].coordZ = details.coordZ
			internalFunc.UpdateWaypointArrows ()
		end
	end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "internalFunc.UpdateMap", debugId) end

end

function internalFunc.UpdateUnit (mapInfo, action)

	if uiElements.mapUI == nil then return end

	local debugId  
	if nkDebug then 
		debugId = nkDebug.traceStart (addonInfo.identifier, "internalFunc.UpdateUnit") 
	end

	for key, details in pairs (mapInfo) do
	
		if action == "add" then

			if details.type == "player" then
				local unitDetails = inspectUnitDetail("player")
				details.type = "UNIT.PLAYER"
				details.title = unitDetails.name
				details.angle = 0         
				data.centerElement = key
				uiElements.mapUI:AddElement(details)
			elseif details.type == "player.pet" then
				local unitDetails = inspectUnitDetail("player.pet")
				details.type = "UNIT.PLAYERPET"
				details.title = unitDetails.name         
				uiElements.mapUI:AddElement(details)
			elseif stringFind(details.type, "group") ~= nil and stringFind(details.type, "group..%.") == nil then				
			
				local unitDetails = inspectUnitDetail(details.type)
				details.type = "UNIT.GROUPMEMBER"        
				details.title = unitDetails.name
				details.smoothCoords = true
				uiElements.mapUI:AddElement(details)
				
				if nkDebug and details.type == "UNIT.GROUPMEMBER" then 
					nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateUnit", action .. ": " .. (details.type or '?'), details)
				end
			else
				if nkDebug and stringFind(details.type, "mouseover") == nil then 
					nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateUnit", "not adding " .. (details.type or '?'), details)
				end
				--dump (details)
			end

		elseif action == "change" then

			if key == data.playerUID then
			
				-- get player angle to show direction on map

				local coordX, coordZ = uiElements.mapUI:GetCoords()         
				local deltaZ = details.coordZ - coordZ
				local deltaX = details.coordX - coordX

				local angle = mathDeg(mathAtan2(deltaZ, deltaX))								
				details.angle = -angle
			end

			if key == data.playerTargetUID then
				details.id = "npc" .. key
				if uiElements.mapUI:ChangeElement(details) == false then
					if nkDebug then
						nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateUnit", "could not change element", details)
					end
				end

				details.id = "t" .. key
				if uiElements.mapUI:ChangeElement(details) == false then
					if nkDebug then
						nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateUnit", "could not change element", details)
					end
				end

			elseif stringFind(details.type, "mouseover") == nil and stringFind(details.type, ".pet") == nil and stringFind(details.type, "player.target.target.target") == nil then
				
				-- if nkDebug and details.type ~= "UNIT.PLAYER" then 
					-- nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateUnit", "changing " .. (details.type or '?'), details)
				-- end
				
				if uiElements.mapUI:ChangeElement(details) == false then
					if details.type == 'player.target' then
						internalFunc.UpdateUnit ({[key] = details}, "add")
					else
						if nkDebug then
							nkDebug.logEntry (addonInfo.identifier, "internalFunc.UpdateUnit", "could not change element", details)
							--print (' internalFunc.UpdateUnit', details.type)
							--dump(details)
						end
					end
				end
			end

			if key == data.playerUID then
				uiElements.mapUI:SetCoord(details.coordX, details.coordZ)
				uiElements.mapUI:SetCoordsLabel(details.coordX, details.coordZ)	
				internalFunc.UpdateWaypointArrows ()
			end

			if key == data.playerHostileTargetUID then
				details.id = "e" .. key
				local bData = {change = {["e" .. key] = details}}
				events.broadcastTarget(bData)
			end

		elseif action == "remove" then
			uiElements.mapUI:RemoveElement(key)
			if key == data.centerElement then data.centerElement = nil end
		end
	end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "internalFunc.UpdateUnit", debugId) end

end

function internalFunc.ShowQuest(flag)
  
  if flag == true and nkUISetup.modules.map.showQuest == true then
    internalFunc.GetQuests();
  else
    if data.currentQuestList ~= nil then
      for questId, mappoints in pairs(data.currentQuestList) do 
        internalFunc.UpdateMap (mappoints, "remove")
      end       
    end
    
    internalFunc.UpdateMap (data.minimapQuestList, "remove")
    
    if data.missingQuestList ~= nil then
      for questId, mappoints in pairs(data.missingQuestList) do 
        internalFunc.UpdateMap (mappoints, "remove")
      end       
    end

    data.currentQuestList = {}
    data.minimapQuestList = {}
    data.minimapIdToQuest = {}    
    data.missingQuestList = {}
    
  end
  
end

function internalFunc.ShowPOI(flag)

  local lastPoi = LibEKL.Map.GetZonePOI (data.lastZone)
  
  if flag == true and nkAM_Loot ~= nil and LibEKL.unit.getGroupStatus () ~= 'single' then
	local bossInfo = nkAM_Loot.getPOI(data.lastZone)
	if bossInfo ~= nil then
		if data.customPOIs[data.lastZone] == nil then data.customPOIs[data.lastZone] = {} end
		for k, v in pairs(bossInfo) do			
			data.customPOIs[data.lastZone][k] = v
		end
	end	
  end
  
  local customPoi = data.customPOIs[data.lastZone]
  
  if customPoi ~= nil then
    if lastPoi == nil then lastPoi = {} end
    for k, v in pairs(customPoi) do 
      lastPoi[k] = v
      lastPoi[k].id = k
      
      if lastPoi[k].type == "POI.ACHIEVEMENT" then
        lastPoi[k].title = lang.poiAchievement
      elseif lastPoi[k].type == "POI.PUZZLE" then
        lastPoi[k].title = lang.poiPuzzle
      end

      lastPoi[k].descList = { v[LibEKLGetLanguageShort ()] }
    end
  end  
  
  if lastPoi == nil then return end
  
  if flag == true and nkUISetup.modules.map.showPOI == true then
    internalFunc.UpdateMap (lastPoi, "add", "internalFunc.ShowPOI")
  else
    internalFunc.UpdateMap (lastPoi, "remove")
  end

end

function internalFunc.ShowRareMobs(flag)

  if flag == true then
    if Inspect.Addon.Detail('RareDar') ~= nil then
      _getRareDarData ()
    elseif Inspect.Addon.Detail('RareTracker') ~= nil then
      _getRareTrackerData ()
    end
  else
    internalFunc.UpdateMap (_rareData, "remove")
  end

end

function internalFunc.ShowGathering(flag)

	if nkUIMapGathering.gatheringData[data.lastZone] == nil then return end

	local action = "add"
	if flag == false then action = "remove" end
	
	local temp = {}
	
	for k, v in pairs(nkUIMapGathering.gatheringData[data.lastZone]) do
		table.insert(temp, {[k] = v})
	end
	
	local gridCoRoutine = coroutine.create(
		function ()
			for idx = 1, #temp, 1 do
				internalFunc.UpdateMap (temp[idx], action, "internalFunc.ShowGathering")
				coroutine.yield(idx)
			end
		end
	)

	LibEKL.coroutines.add ({ func = gridCoRoutine, counter = #temp, active = true })

end

function internalFunc.ShowArtifacts(flag)

  if nkUIMapGathering.artifactsData[data.lastZone] == nil then return end

  if flag == true then
     internalFunc.UpdateMap (nkUIMapGathering.artifactsData[data.lastZone], "add")
  else
    internalFunc.UpdateMap (nkUIMapGathering.artifactsData[data.lastZone], "remove")
  end

end

function internalFunc.CollectArtifact(itemData)

  if nkUIMapGathering.artifactsData[data.lastZone] == nil then nkUIMapGathering.artifactsData[data.lastZone] = {} end

  local unitDetails = inspectUnitDetail('player') 
  local coordRangeX = {unitDetails.coordX-2, unitDetails.coordX+2}
  local coordRangeZ = {unitDetails.coordZ-2, unitDetails.coordZ+2}      

  for key, _ in pairs (itemData) do
    local details = inspectItemDetail(key)
	
	--dump(details)
    
    if details and stringFind(details.category, "artifact") == 1 then
    
      local artifactType = stringUpper(stringMatch(details.category, "artifact (.+)"))
      if artifactType == "FAE YULE" then artifactType = "FAEYULE" end
      local type = "TRACK.ARTIFACT." .. artifactType
      
      local knownPos = false
      
      for _, info in pairs(nkUIMapGathering.artifactsData[data.lastZone]) do
        if info.coordX >= coordRangeX[1] and info.coordX <= coordRangeX[2] and
           info.coordZ >= coordRangeZ[1] and info.coordZ <= coordRangeZ[2] then
           knownPos = true
           break;
        end
      end
      
      if knownPos == false then
        local thisData = { id = stringMatch(type, "TRACK.(.+)") .. LibEKLUUID(), type = type, descList = {}, coordX = unitDetails.coordX, coordY = unitDetails.coordY, coordZ = unitDetails.coordZ }
        nkUIMapGathering.artifactsData[data.lastZone][thisData.id] = thisData
      end
    end
  end

end

function internalFunc.WaypointDialog()

	local xpos, ypos
	
	if inspectSystemSecure() == true then return end

	if uiElements.waypointDialog == nil then
		local name = "nkUI.waypointDialog"
		local coordLabel, xposEdit, yposEdit, sepLabel, setButton		
	
		uiElements.waypointDialog = LibEKL.UICreateFrame("nkWindowElement", name, uiElements.contextMapSecure)
		uiElements.waypointDialog:SetLayer(3)
		uiElements.waypointDialog:SetWidth(200)
		uiElements.waypointDialog:SetHeight(140)	
		uiElements.waypointDialog:SetTitle(lang.waypointDialogTitle)
		uiElements.waypointDialog:SetSecureMode('restricted')
		uiElements.waypointDialog:SetTitleFont(addonInfo.id, "MontserratSemiBold")
		
		Command.Event.Attach(LibEKL.Events[name].Closed, function () 
			xposEdit:Leave()
			yposEdit:Leave()
		end, name .. ".Closed")
		
		coordLabel = LibEKL.UICreateFrame("nkText", name .. ".coordLabel", uiElements.waypointDialog:GetContent())
		coordLabel:SetPoint("CENTERTOP", uiElements.waypointDialog:GetContent(), "CENTERTOP", 0, 10)
		coordLabel:SetFontColor(1, 1, 1, 1)
		coordLabel:SetFontSize(12)
		coordLabel:SetText(lang.coordLabel)

		LibEKL.UI.SetFont(coordLabel, addonInfo.id, "Montserrat")
		
		sepLabel = LibEKL.UICreateFrame("nkText", name .. ".sepLabel", uiElements.waypointDialog:GetContent())
		sepLabel:SetPoint("CENTERTOP", coordLabel, "CENTERBOTTOM", 0, 10)
		sepLabel:SetFontColor(1, 1, 1, 1)
		sepLabel:SetFontSize(12)
		sepLabel:SetText("/")

		LibEKL.UI.SetFont(sepLabel, addonInfo.id, "Montserrat")
				
		xposEdit = LibEKL.UICreateFrame("nkTextField", name .. ".xposEdit", uiElements.waypointDialog:GetContent())
		yposEdit = LibEKL.UICreateFrame("nkTextField", name .. ".yposEdit", uiElements.waypointDialog:GetContent())
				
		xposEdit:SetPoint("CENTERRIGHT", sepLabel, "CENTERLEFT", -5, 0)
		xposEdit:SetWidth(50)
		xposEdit:SetTabTarget(yposEdit)
		
		local function _setMacro()
			if xpos == nil or ypos == nil or tonumber(xpos) == nil or tonumber(ypos) == nil then return end
			
			LibEKL.Events.addInsecure(function() setButton:SetMacro(stringFormat("setwaypoint %d %d", xpos, ypos)) end)
		end
		
		Command.Event.Attach(LibEKL.Events[name .. ".xposEdit"].TextfieldChanged, function (_, newValue) 
			xpos = newValue
			_setMacro()
		end, name .. ".xposEdit.TextfieldChanged")
				
		yposEdit:SetPoint("CENTERLEFT", sepLabel, "CENTERRIGHT", 5, 0)
		yposEdit:SetWidth(50)
		yposEdit:SetTabTarget(xposEdit)
		
		Command.Event.Attach(LibEKL.Events[name .. ".yposEdit"].TextfieldChanged, function (_, newValue) 
			ypos = newValue
			_setMacro()
		end, name .. ".yposEdit.TextfieldChanged")
		
		setButton = LibEKL.UICreateFrame("nkButtonMetro", name .. ".setButton", uiElements.waypointDialog:GetContent())
		setButton:SetPoint("CENTERTOP", sepLabel, "CENTERBOTTOM", 0, 20)
		setButton:SetText(lang.btSet)
		setButton:SetIcon("LibEKL", "gfx/icons/ok.png")
		setButton:SetScale(.8)
		setButton:SetLayer(9)
		setButton:SetFont(addonInfo.id, "MontserratSemiBold")

		Command.Event.Attach(LibEKL.Events[name .. ".setButton"].Clicked, function () 
			xposEdit:Leave()
			yposEdit:Leave()
			
			LibEKL.Events.addInsecure(function() uiElements.waypointDialog:SetVisible(false) end)			
			
		end, name .. ".setButton.Clicked")

	else
		if uiElements.waypointDialog:GetVisible() == true then
			uiElements.waypointDialog:SetVisible(false)
		else
			uiElements.waypointDialog:SetVisible(true)
		end		
	end
	
	local mouseData = inspectMouse()
	uiElements.waypointDialog:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouseData.x - uiElements.waypointDialog:GetWidth(), mouseData.y - uiElements.waypointDialog:GetHeight())

end

function internalFunc.ShowCustomPoints()

	if nkUISetup.modules.map.userPOI[data.currentWorld] ~= nil then internalFunc.UpdateMap (nkUISetup.modules.map.userPOI[data.currentWorld], "add") end

end

function internalFunc.mapAddCustomPoint(x, y, title)

	if nkUISetup.modules.map.userPOI[data.currentWorld] == nil then nkUISetup.modules.map.userPOI[data.currentWorld] = {} end
	
	local thisID = "CUSTOMPOI" .. LibEKLUUID ()
	local thisEntry = {
		[thisID] = {
			coordX = x,
			coordY = y,
			descList = { title },
			description = title,
			id = thisID,
			type = "CUSTOMPOI"			
		}
	}
	
	nkUISetup.modules.map.userPOI[data.currentWorld][thisID] = thisEntry[thisID]	
	internalFunc.UpdateMap (thisEntry, "add")
	
end

function internalFunc.mapClearCustomPoints()

	if nkUISetup.modules.map.userPOI[data.currentWorld] ~= nil then 
		internalFunc.UpdateMap (nkUISetup.modules.map.userPOI[data.currentWorld], "remove")
		nkUISetup.modules.map.userPOI[data.currentWorld] = {}
	end

end

function internalFunc.debugPanel()

	local name = "nkUI.debugPanel"

	local debugPanel, x1label, x2label, y1label, y2label, x1, x2, y1, y2

	debugPanel = LibEKL.UICreateFrame("nkFrame", name, uiElements.contextMap)
	debugPanel:SetWidth(200)
	debugPanel:SetHeight(100)
	debugPanel:SetPoint("TOPRIGHT", uiElements.mapUI, "TOPLEFT")
	debugPanel:SetBackgroundColor(0,0,0,.5)

	x1label = LibEKL.UICreateFrame("nkText", name .. ".x1label", debugPanel)
	x2label = LibEKL.UICreateFrame("nkText", name .. ".x2label", debugPanel)
	y1label = LibEKL.UICreateFrame("nkText", name .. ".y1label", debugPanel)
	y2label = LibEKL.UICreateFrame("nkText", name .. ".y2label", debugPanel)

	x1 = LibEKL.UICreateFrame("nkTextfield", name .. ".x1", debugPanel)
	x2 = LibEKL.UICreateFrame("nkTextfield", name .. ".x2", debugPanel)
	y1 = LibEKL.UICreateFrame("nkTextfield", name .. ".y1", debugPanel)
	y2 = LibEKL.UICreateFrame("nkTextfield", name .. ".y2", debugPanel)

	x1label:SetPoint("TOPLEFT", debugPanel, "TOPLEFT", 10, 10)
	x1label:SetText("x1: ")

	y1label:SetPoint("TOPLEFT", debugPanel, "TOPLEFT", 10, 30)
	y1label:SetText("y1: ")

	x1:SetPoint("CENTERLEFT", x1label, "CENTERRIGHT", 5, 0)
	y1:SetPoint("CENTERLEFT", y1label, "CENTERRIGHT", 5, 0)

	x2:SetPoint("BOTTOMRIGHT", debugPanel, "BOTTOMRIGHT", -10, -30)
	y2:SetPoint("BOTTOMRIGHT", debugPanel, "BOTTOMRIGHT", -10, -10)

	x2label:SetPoint("CENTERRIGHT", x2, "CENTERLEFT", 5, 0)
	y2label:SetPoint("CENTERRIGHT", y2, "CENTERLEFT", 5, 0)
	x2label:SetText("x2: ")
	y2label:SetText("y2: ")

	Command.Event.Attach(LibEKL.Events[name .. ".x1"].TextfieldChanged, function ()

		local mapInfo = uiElements.mapUI:GetMapInfo()
		mapInfo.x1 = tonumber(x1:GetText())
		uiElements.mapUI:UpdateMapInfo(mapInfo)

	end, name .. ".x1.TextfieldChanged")

	Command.Event.Attach(LibEKL.Events[name .. ".x2"].TextfieldChanged, function ()

		local mapInfo = uiElements.mapUI:GetMapInfo()
		mapInfo.x2 = tonumber(x2:GetText())
		uiElements.mapUI:UpdateMapInfo(mapInfo)

	end, name .. ".x2.TextfieldChanged")

	Command.Event.Attach(LibEKL.Events[name .. ".y1"].TextfieldChanged, function ()

		local mapInfo = uiElements.mapUI:GetMapInfo()
		mapInfo.y1 = tonumber(y1:GetText())
		uiElements.mapUI:UpdateMapInfo(mapInfo)

	end, name .. ".y1.TextfieldChanged")

	Command.Event.Attach(LibEKL.Events[name .. ".y2"].TextfieldChanged, function ()

		local mapInfo = uiElements.mapUI:GetMapInfo()
		mapInfo.y2 = tonumber(y2:GetText())
		uiElements.mapUI:UpdateMapInfo(mapInfo)

	end, name .. ".y2.TextfieldChanged")

	function debugPanel:SetCoord(newX1, newX2, newY1, newY2)
		x1:SetText(newX1)
		x2:SetText(newX2)
		y1:SetText(newY1)
		y2:SetText(newY2)
	end
	
	return debugPanel
  
end