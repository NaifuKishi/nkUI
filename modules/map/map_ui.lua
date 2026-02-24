local addonInfo, privateVars = ...

---------- init namespace ---------

local map			= privateVars.map
local mapEvents		= privateVars.mapEvents
local mapData       = privateVars.mapData
local uiElements    = privateVars.uiElements
local events        = privateVars.events
local lang        	= privateVars.langTexts

---------- make global functions local ---------

local InspectUnitDetail 	= Inspect.Unit.Detail
local InspectZoneDetail 	= Inspect.Zone.Detail
local InspectSystemSecure 	= Inspect.System.Secure
local InspectSystemWatchdog = Inspect.System.Watchdog
local InspectItemDetail 	= Inspect.Item.Detail
local InspectMouse 			= Inspect.Mouse
local InspectTimeReal 		= Inspect.Time.Real

local LibEKLGetLanguage			= LibEKL.Tools.Lang.GetLanguage
local mathRad				= math.rad
local mathMax				= math.max
local mathMin				= math.min
local LibEKLGetLanguageShort	= LibEKL.Tools.Lang.GetLanguageShort
local LibEKLTableCopy			= LibEKL.Tools.Table.Copy
local LibEKLUUID				= LibEKL.Tools.UUID

local stringFind			= string.find
local stringMatch			= string.match
local stringFormat			= string.format
local stringUpper			= string.upper

local mathDeg				= math.deg
local mathAtan2				= math.atan2

mapData.borderDesigns = {
  blackSmall  = {DE = "Schwarz dünn", EN = "Black simple", RU = "Black simple", addon = "nkUI", path = "gfx/bgBlack.png", offset = 2},  
} -- list of border designs for the map

---------- local function block ---------

function map.createMapUI ()

	local mapUI = LibMap.uiCreateFrame("nkMap", "nkUI.map.map", uiElements.mapContext)

	local locked
	if nkUISetup.modules.map.locked == true then locked = false else locked = true end
	
	mapUI:SetResizable(locked)
	mapUI:SetLayer(2)

	mapUI:ShowHeader(false)
	mapUI:ShowCoords(false)	

	local texture = LibEKL.UICreateFrame("nkTexture", "nkUI.map.map.texture", uiElements.mapContext)
	texture:SetLayer(1)

	function mapUI:SetBackground(newBG)
		if nkUISetup.modules.map.background == nil then return end

		if mapData.borderDesigns.blackSmall.addon == nil then
			texture:SetVisible(false)
		else			
			texture:SetVisible(true)
			texture:SetPoint("TOPLEFT", mapUI, "TOPLEFT", -mapData.borderDesigns.blackSmall.offset, -mapData.borderDesigns.blackSmall.offset)
			texture:SetPoint("BOTTOMRIGHT", mapUI, "BOTTOMRIGHT", mapData.borderDesigns.blackSmall.offset, mapData.borderDesigns.blackSmall.offset)
			texture:SetTextureAsync(mapData.borderDesigns.blackSmall.addon, mapData.borderDesigns.blackSmall.path)
		end
	end

	local oSetVisible = mapUI.SetVisible

	function mapUI:SetVisible(flag)
		oSetVisible(self, flag)
		texture:SetVisible(flag)
	end

	mapUI:SetBackground(nkUISetup.modules.map.background)

	local zoneTitle = LibEKL.UICreateFrame("nkText", "nkUI.map.map.zoneTitle", mapUI:GetMask())
	zoneTitle:SetPoint("CENTERTOP", mapUI:GetContent(), "CENTERTOP")
	zoneTitle:SetLayer(9999)
	
	LibEKL.UI.SetFont (zoneTitle, addonInfo.id, "MontserratSemiBold")

	zoneTitle:SetEffectGlow({ colorB = 0, colorA = 1, colorG = 0, colorR = 0, strength = 3, blurX = 3, blurY = 3 })

	local coords = LibEKL.UICreateFrame("nkText", "nkUI.map.map.coords", mapUI)
	coords:SetPoint("CENTERBOTTOM", mapUI:GetContent(), "CENTERBOTTOM", 0, 15)
	coords:SetLayer(9999)
	coords:SetFontSize(20)
	coords:SetEffectGlow({ strength = 3})
	
	LibEKL.UI.SetFont (coords, addonInfo.id, "MontserratBold")

	local mouseCoords = LibEKL.UICreateFrame("nkText", "nkUI.map.map.mouseCoords", mapUI)
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
			zoneTitle:SetText(mapData.locationName)
		end
	end

	Command.Event.Attach(LibMap.events["nkUI.map.map"].MouseMoved, function (_, text)
		mouseCoords:SetText(text)
	end, "nkUI.map.map.MouseMoved")  

	Command.Event.Attach(LibMap.events["nkUI.map.map"].Moved, function (_, x, y, maximized)

		if maximized == true then
			nkUISetup.modules.map.maximizedX, nkUISetup.modules.map.maximizedY = x, y 
		else
			nkUISetup.modules.map.x, nkUISetup.modules.map.y = x, y
		end

	end, "nkUI.map.map.Moved")    

	Command.Event.Attach(LibMap.events["nkUI.map.map"].Resized, function (_, newWidth, newHeight, maximized)

		if maximized == true then
			nkUISetup.modules.map.maximizedWidth, nkUISetup.modules.map.maximizedHeight = newWidth, newHeight 
		else
			nkUISetup.modules.map.width, nkUISetup.modules.map.height = newWidth, newHeight
		end

	end, "nkUI.map.map.Moved")

	Command.Event.Attach(LibMap.events["nkUI.map.map"].Toggled, function (_, newScale, maximized)
		map.UpdateWaypointArrows ()
		mapUI:SetZoneTitle(nkUISetup.modules.map.showZoneTitle)
	end, "nkUI.map.map.Toggled")

	return mapUI

end

function map.createTiledMapUI ()

	local tiledMapUI = LibMap.uiCreateFrame("nkMiniMap", "nkUI.map.tiled", uiElements.mapContext)
	tiledMapUI:SetWidth(425)
	tiledMapUI:SetHeight(370)
	tiledMapUI:SetVisible(true)

	-- Hide the header to match the original map look
	if tiledMapUI.DisplayHeader then
		tiledMapUI:DisplayHeader(false)
	end

	-- Add element management to tiled map
	tiledMapUI.elements = {}
	tiledMapUI.elementCount = 0

	-- Element type configurations (simplified versions of main map elements)
	tiledMapUI.elementConfigs = {
		["UNIT.PLAYER"] = {width = 32, height = 32, texture = "gfx/mapIcons/iconPlayerPosition.png", addon = "LibMap", layer = 99, gfxType = "canvas", angleCorr = 280},
		["UNIT.PLAYERPET"] = {width = 24, height = 24, texture = "MainMap_I345.dds", addon = "Rift", layer = 98},
		["UNIT.GROUPMEMBER"] = {width = 32, height = 32, texture = "indicator_group.png.dds", addon = "Rift", layer = 98},
		["UNIT.RARE"] = {width = 32, height = 32, texture = "target_portrait_LootPinata.png.dds", addon = "Rift", layer = 98},
		["WAYPOINT"] = {width = 16, height = 16, texture = "gfx/mapIcons/iconWaypoint.png", addon = "LibMap", layer = 100},
		["UNKNOWN"] = {width = 32, height = 32, texture = "gfx/mapIcons/iconUnknown.png", addon = "LibMap", layer = 70},
		["TRACK.MINE"] = {width = 24, height = 24, texture = "gfx/mapIcons/iconMine.png", addon = "LibMap", layer = 50},
		["TRACK.HERB"] = {width = 24, height = 24, texture = "gfx/mapIcons/iconHerb.png", addon = "LibMap", layer = 50},
		["TRACK.WOOD"] = {width = 24, height = 24, texture = "gfx/mapIcons/iconWood.png", addon = "LibMap", layer = 50},
		["TRACK.FISH"] = {width = 24, height = 24, texture = "gfx/mapIcons/iconFish.png", addon = "LibMap", layer = 50},
		["TRACK.ARTIFACT"] = {width = 24, height = 24, texture = "gfx/mapIcons/iconArtifact.png", addon = "LibMap", layer = 50},
		["VENDOR.OTHER"] = {width = 20, height = 20, texture = "gfx/mapIcons/iconVendor.png", addon = "LibMap", layer = 60},
		["VENDOR.MOUNTS"] = {width = 20, height = 20, texture = "gfx/mapIcons/iconVendor.png", addon = "LibMap", layer = 60},
		["VENDOR.DIMENSIONS"] = {width = 20, height = 20, texture = "gfx/mapIcons/iconVendor.png", addon = "LibMap", layer = 60},
		["VENDOR.PLANES"] = {width = 20, height = 20, texture = "gfx/mapIcons/iconVendor.png", addon = "LibMap", layer = 60},
		["VENDOR.MINIONS"] = {width = 20, height = 20, texture = "gfx/mapIcons/iconVendor.png", addon = "LibMap", layer = 60},
		["VENDOR.HUNT"] = {width = 20, height = 20, texture = "gfx/mapIcons/iconVendor.png", addon = "LibMap", layer = 60},
		["VENDOR.PROFESSION"] = {width = 20, height = 20, texture = "gfx/mapIcons/iconVendor.png", addon = "LibMap", layer = 60},
		["VENDOR.DYES"] = {width = 20, height = 20, texture = "gfx/mapIcons/iconVendor.png", addon = "LibMap", layer = 60},
		["VARIA.BANK"] = {width = 20, height = 20, texture = "gfx/mapIcons/iconBank.png", addon = "LibMap", layer = 61},
		["VARIA.AUCTIONHOUSE"] = {width = 20, height = 20, texture = "gfx/mapIcons/iconAuctionHouse.png", addon = "LibMap", layer = 61},
		["VARIA.GUILDBANK"] = {width = 20, height = 20, texture = "indicator_banker.png.dds", addon = "Rift", layer = 61}
	}

	-- Store map info for coordinate conversion
	tiledMapUI.mapInfo = LibMap.map.getMapData("world1_tiles")

	-- Add zone name display
	tiledMapUI.zoneTitle = LibEKL.UICreateFrame("nkText", "nkUI.map.tiled.zoneTitle", tiledMapUI:GetContent())
	tiledMapUI.zoneTitle:SetPoint("CENTERTOP", tiledMapUI:GetContent(), "CENTERTOP", 0, 10)
	tiledMapUI.zoneTitle:SetLayer(9999)
	tiledMapUI.zoneTitle:SetFontSize(20)
	tiledMapUI.zoneTitle:SetEffectGlow({ colorB = 0, colorA = 1, colorG = 0, colorR = 0, strength = 3, blurX = 3, blurY = 3 })
	LibEKL.UI.SetFont (tiledMapUI.zoneTitle, addonInfo.id, "MontserratSemiBold")

	function tiledMapUI:SetZoneTitle(text)
		if tiledMapUI.zoneTitle then
			tiledMapUI.zoneTitle:SetText(text or "")
		end
	end

	-- Add player coordinates display
	tiledMapUI.coordsDisplay = LibEKL.UICreateFrame("nkText", "nkUI.map.tiled.coords", tiledMapUI)
	tiledMapUI.coordsDisplay:SetPoint("CENTERBOTTOM", tiledMapUI:GetContent(), "CENTERBOTTOM", 0, -15)
	tiledMapUI.coordsDisplay:SetLayer(9999)
	tiledMapUI.coordsDisplay:SetFontSize(20)
	tiledMapUI.coordsDisplay:SetEffectGlow({ strength = 3})
	LibEKL.UI.SetFont (tiledMapUI.coordsDisplay, addonInfo.id, "MontserratBold")

	function tiledMapUI:SetCoordsLabel(x, y)
		if tiledMapUI.coordsDisplay then
			tiledMapUI.coordsDisplay:SetText(stringFormat("%d / %d", x, y))
		end
	end

	function tiledMapUI:SetWorld(newWorld)
		-- Call original SetWorld method
		local success, errorMsg = pcall(function()
			-- The minimap frame might have its own SetWorld method
			if self._SetWorld then
				self:_SetWorld(newWorld)
			end
		end)

		-- Update our stored map info
		if newWorld and newWorld.path then
			self.mapInfo = newWorld
		elseif newWorld then
			self.mapInfo = LibMap.map.getMapData(newWorld)
		end
	end

	function tiledMapUI:AddElement(details)

		if self.elements[details.id] then
			-- Element already exists, update it
			return self:UpdateElement(details)
		end

		-- Get configuration for this element type
		local config = self.elementConfigs[details.type] or self.elementConfigs["UNKNOWN"]
		if not config then
			return false  -- Unknown element type
		end

		-- Create canvas element with appropriate size
		local element = LibEKL.UICreateFrame("nkCanvas", "nkUI.map.tiled.element." .. self.elementCount, self:GetContent())
		element:SetWidth(config.width or 32)
		element:SetHeight(config.height or 32)
		element:SetLayer(config.layer or 10)

		-- Use the same default square path as the standard map elements
		local path = {
			{xProportional = 0, yProportional = 0},
			{xProportional = 0, yProportional = 1},
			{xProportional = 1, yProportional = 1},
			{xProportional = 1, yProportional = 0},
			{xProportional = 0, yProportional = 0}
		}

		local fill = {
			type = "texture",
			source = config.addon or "LibMap",
			texture = config.texture or "gfx/mapIcons/iconUnknown.png"
		}

		-- Rotation will be handled in UpdateElement to ensure we have the correct angle
		-- Initialize without rotation, it will be applied when we get the first angle update

		element:SetShape(path, fill, nil)

		-- Store element data
		details.element = element
		details.config = config
		details.coordX = details.coordX or 0
		details.coordZ = details.coordZ or 0

		self.elements[details.id] = details
		self.elementCount = self.elementCount + 1

		-- Convert game coordinates to map coordinates for other elements
		local mapInfo = self.mapInfo
		if mapInfo and mapInfo.x1 and mapInfo.x2 and mapInfo.y1 and mapInfo.y2 then
			-- Ensure coordinates are within map bounds
			local normalizedX = (details.coordX - mapInfo.x1) / (mapInfo.x2 - mapInfo.x1)
			local normalizedY = (details.coordZ - mapInfo.y1) / (mapInfo.y2 - mapInfo.y1)

			-- Clamp to valid range
			normalizedX = mathMax(0, mathMin(1, normalizedX))
			normalizedY = mathMax(0, mathMin(1, normalizedY))

			local mapX = normalizedX * self:GetWidth()
			local mapY = normalizedY * self:GetHeight()

			-- Position the element at its correct location
			element:SetPoint("CENTER", self:GetContent(), "TOPLEFT", mapX, mapY)
		else
			-- Fallback: center the element if map info is not available
			element:SetPoint("CENTER", self:GetContent(), "CENTER")
		end

		return true
	end

	function tiledMapUI:UpdateElement(details)

		local existing = self.elements[details.id]
		if not existing then return false end

		if details.coordX and details.coordZ then
			existing.coordX = details.coordX
			existing.coordZ = details.coordZ

			-- Special handling for player: always center (tiles move to center player)
			-- Other elements: position at their actual coordinates
			if existing.type == "UNIT.PLAYER" then
				-- Player stays centered, tiles move around them
				existing.element:SetPoint("CENTER", self:GetContent(), "CENTER")
			end
		end

		-- Handle rotation for canvas elements
		if details.angle and existing.element and existing.element.SetShape then
			-- Adjust angle correction for tiled map (standard map uses 280, but tiled map needs adjustment)
			local angleCorrection = (existing.angleCorr or 0) - 90  -- Subtract 90 degrees to fix orientation
			local radian = mathRad(details.angle + angleCorrection)
			local path = {
				{xProportional = 0, yProportional = 0},
				{xProportional = 0, yProportional = 1},
				{xProportional = 1, yProportional = 1},
				{xProportional = 1, yProportional = 0},
				{xProportional = 0, yProportional = 0}
			}
			local fill = {
				type = "texture",
				source = "LibMap",
				texture = "gfx/mapIcons/iconPlayerPosition.png",
				transform = LibEKL.Tools.Gfx.Rotate(existing.element, radian, 1)
			}
			existing.element:SetShape(path, fill, nil)
		end

		return true
	end

	function tiledMapUI:RemoveElement(id)
		local existing = self.elements[id]
		if existing and existing.element then
			existing.element:SetVisible(false)
			existing.element = nil
		end
		self.elements[id] = nil
	end

	function tiledMapUI:ClearElements()
		for id, elementData in pairs(self.elements) do
			if elementData.element then
				elementData.element:SetVisible(false)
				elementData.element = nil
			end
		end
		self.elements = {}
	end

	return tiledMapUI

end