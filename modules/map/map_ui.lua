local addonInfo, privateVars = ...

---------- init namespace ---------

local map					= privateVars.map
local mapEvents				= privateVars.mapEvents
local data                  = privateVars.data
local uiElements            = privateVars.uiElements
local events               	= privateVars.events
local lang        			= privateVars.langTexts

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

data.borderDesigns = {
  blackSmall  = {DE = "Schwarz dünn", EN = "Black simple", RU = "Black simple", addon = "nkUI", path = "gfx/bgBlack.png", offset = 2},  
} -- list of border designs for the map

---------- local function block ---------

function map.createMapUI ()

	local mapUI = LibMap.uiCreateFrame("nkMap", "nkUI.map.map", uiElements.mapContext)

	local locked
	if nkUISetup.modules.map.locked == true then locked = false else locked = true end
	
	mapUI:SetResizable(locked)
	mapUI:SetDragable(locked)
	mapUI:SetLayer(2)

	mapUI:ShowHeader(false)
	mapUI:ShowCoords(false)	

	local texture = LibEKL.UICreateFrame("nkTexture", "nkUI.map.map.texture", uiElements.mapContext)
	texture:SetLayer(1)

	function mapUI:SetBackground(newBG)
		if nkUISetup.modules.map.background == nil then return end

		if data.borderDesigns.blackSmall.addon == nil then
			texture:SetVisible(false)
		else
			texture:SetVisible(true)    
			texture:SetPoint("TOPLEFT", mapUI, "TOPLEFT", -data.borderDesigns.blackSmall.offset, -data.borderDesigns.blackSmall.offset)
			texture:SetPoint("BOTTOMRIGHT", mapUI, "BOTTOMRIGHT", data.borderDesigns.blackSmall.offset, data.borderDesigns.blackSmall.offset)
			texture:SetTextureAsync(data.borderDesigns.blackSmall.addon, data.borderDesigns.blackSmall.path)
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
			zoneTitle:SetText(data.locationName)
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

	Command.Event.Attach(LibMap.events["nkUI.map.map"].Zoomed, function (_, newScale, maximized)
		if maximized == true then
			nkUISetup.modules.map.maximizedScale = newScale
		else
			nkUISetup.modules.map.scale = newScale
		end

	map.UpdateWaypointArrows ()

	end, "nkUI.map.map.Zoomed")

	Command.Event.Attach(LibMap.events["nkUI.map.map"].Toggled, function (_, newScale, maximized)
		map.UpdateWaypointArrows ()
		mapUI:SetZoneTitle(nkUISetup.modules.map.showZoneTitle)
	end, "nkUI.map.map.Toggled")

	return mapUI
	
end
