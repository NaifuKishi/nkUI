local addonInfo, privateVars = ...

---------- init namespace ---------

if not nkQuestTracker then nkQuestTracker = {} else return end

privateVars.internal	= {}
privateVars.uiElements	= {}
privateVars.data		= {}
privateVars.events		= {}

local internal		= privateVars.internal
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local events		= privateVars.events

local oInspectQuestDetail	= Inspect.Quest.Detail
local oInspectItemDetail	= Inspect.Item.Detail
local oInspectUnitDetail	= Inspect.Unit.Detail
local oInspectQuestList		= Inspect.Quest.List
local oInspectZoneDetail	= Inspect.Zone.Detail
local oInspectMouse			= Inspect.Mouse

local stringFormat			= string.format
local stringLen				= string.len
local stringSub				= string.sub
local stringSplit			= string.split

---------- init local variables ---------

local colorR, colorG, colorB, colorA = 0.9, 0.74, 0, 1

local _craftingItems = {
	"I4CD48A0656A66436,41331FF662BDB8ED,,,,,,",
	"I21D9052625C52295,709CF1BA97DA8BF9,,,,,,",
	"I2D199E412D5BD46E,DEFE32C2157DE5B1,,,,,,",
	"I5B81BB103E80D890,110D59F273118747,,,,,,"
}

local _zoneInfo			= {}
local _playerZoneID		= nil

---------- init variables ---------

data.zoneFilter			= false
data.playerAvailable	= false
data.playerLevel		= nil
data.playerUNID			= nil
data.addQuestList		= {}
data.removeQuestList	= {}
data.areaQuestDomain	= {"ia", "world", "zone", "area", "raid"}

---------- generate ui context ---------

uiElements.context = UI.CreateContext("nkQuestTracker")
uiElements.context:SetStrata ('dialog')
uiElements.context:SetLayer(2)

uiElements.secureContext = UI.CreateContext("nkQuestTracker.Secure")
uiElements.secureContext:SetSecureMode('restricted')
uiElements.secureContext:SetStrata ('layout')
uiElements.secureContext:SetLayer(3)

uiElements.configContext = UI.CreateContext ("internal.Config")
uiElements.configContext:SetStrata ('dialog')
uiElements.configContext:SetLayer(2)

uiElements.tooltipContext = UI.CreateContext("nkQuestTrackerTooltip")
uiElements.tooltipContext:SetStrata ('topmost')
uiElements.tooltipContext:SetLayer(999)

---------- local function block ---------

local function _fctCommandHandler(commandline)

	internal.ShowConfig()
	
end

local function _fctUnitAvailable (_, units)

	if data.playerUNID == nil then
		local playerDetails = oInspectUnitDetail('player')
		if playerDetails ~= nil then
			data.playerUNID = playerDetails.id
			_playerZoneID = playerDetails.zone
			data.playerLevel = playerDetails.level
		end
	else
		local playerDetails = oInspectUnitDetail('player')
		if playerDetails ~= nil then 
			_playerZoneID = playerDetails.zone
			data.playerLevel = playerDetails.level
		end	
	end
	
	if data.playerUNID == nil then return end
	if units[data.playerUNID] == nil then return end
	
	data.playerAvailable = true
	
	EnKai.inventory.init()
	
	if nkQuestTrackerSetup.useareaquestui == true and uiElements.areaQuestUI == nil then
		uiElements.areaQuestUI = internal.buildAreaQuestUI()
	end

	if uiElements.questLog == nil then
		
		uiElements.questLog = internal.buildUI ()
		
		uiElements.missingList = internal.missingUI()
		
		internal.fillLog ()
		
		uiElements.progressBar = EnKai.uiCreateFrame("nkProgressBar", "nkQuestTracker.progressBar", uiElements.questLog)
		uiElements.progressBar:SetPoint("CENTERTOP", uiElements.questLog, "CENTERTOP", 0, 40)
		
		uiElements.progressBar:SetWidth(uiElements.questLog:GetWidth()-20)
		uiElements.progressBar:SetHeight(20)
		uiElements.progressBar:SetLayer(99)
		uiElements.progressBar:SetVisible(false)
		uiElements.progressBar:SetFontColor(0, 0, 0, 1)
		uiElements.progressBar:SetBorderColor(colorR, colorG, colorB, colorA)
		uiElements.progressBar:SetFillColor(colorR, colorG, colorB, colorA)
		
		
		Command.Event.Attach(Event.Quest.Accept, events.questAccept, "nkQuestTracker.Quest.Accept")
		Command.Event.Attach(Event.Quest.Abandon, events.questAbandon, "nkQuestTracker.Quest.Abandon")
		Command.Event.Attach(Event.Quest.Change, events.questChange, "nkQuestTracker.Quest.Change")
		Command.Event.Attach(Event.Quest.Complete, events.questComplete, "nkQuestTracker.Quest.Complete")
		Command.Event.Attach(Event.System.Update.Begin, events.systemUpdate, "nkQuestTracker.System.Update.Begin")
	
		Command.Event.Attach(Event.Unit.Availability.None, events.unitNotAvaiable, "nkQuestTracker.Unit.Availability.None")
		Command.Event.Attach(Event.Unit.Availability.Partial, events.unitNotAvaiable, "nkQuestTracker.Unit.Availability.None")
		
		Command.Event.Attach(Event.Unit.Detail.Level, events.unitLevel, "nkQuestTracker.Unit.Detail.Level")
		
		Command.Event.Attach(EnKai.events["EnKai.InventoryManager"].Update, events.InventoryUpdate, "nkQuestTracker.EnKai.InventoryManager.update")

	end

	--uiElements.questLog:SetTitle(addonInfo.name)
	uiElements.questLog:SetTitle(stringFormat("%d Quests", uiElements.questLog:GetQuestCount()))

end

local function _fctToggle()

  if uiElements.questLog ~= nil then
    if uiElements.questLog:GetVisible() == true then
      uiElements.questLog:getUseItemButton():SetVisible(false)
      uiElements.questLog:SetVisible(false)      
    else
      uiElements.questLog:getUseItemButton():SetVisible(true)
      uiElements.questLog:SetVisible(true)
    end    
  end

end

local function _fctMain(_, addon)

	if addon == addonInfo.identifier then
	
		table.insert(Command.Slash.Register("nkQuestTracker"), {_fctCommandHandler, "nkQuestTracker", "config"})
	
		--[[local items = {
		{ label = privateVars.langTexts.buttonMenuConfig, callBack = function () internal.ShowConfig() end},
		{  label = privateVars.langTexts.buttonMenuToggle, callBack = function () _fctToggle() end},
		}]]

		if nkPanel ~= nil and nkQuestTrackerSetup.nkPanel == true then
			uiElements.panel = internal.nkPanelPlugin(items)
			nkPanel.api.registerPlugin('nkQuestTracker', uiElements.panel)
		end
		
		--EnKai.manager.init('nkQuestTracker', items, nil)
		
		nkQuestBase.loadPackage("classic")
		nkQuestBase.loadPackage("nt")
		nkQuestBase.loadPackage("sfp")
		
		EnKai.version.init(addonInfo.toc.Identifier, addonInfo.toc.Version)

		EnKai.managerV2.RegisterButton("nkQuestTracker.minimap", addonInfo.id, "gfx/minimapIcon.png", internal.ShowConfig)
		EnKai.managerV2.RegisterButton("nkQuestTracker.minimapClose", addonInfo.id, "gfx/minimapIconClose.png", _fctToggle)

		EnKai.ui.registerFont (addonInfo.id, "Montserrat", "fonts/Montserrat-Regular.ttf")
		EnKai.ui.registerFont (addonInfo.id, "MontserratSemiBold", "fonts/Montserrat-SemiBold.ttf")
		
		Command.Event.Attach(Event.Unit.Availability.Full, _fctUnitAvailable, "nkQuestTracker.Unit.Availability.Full")
	end

end

local function _fctSettingsHandler(_, addon) 

	if addon == addonInfo.identifier then
	
		if nkQuestTrackerSetup == nil then 
			nkQuestTrackerSetup = { nkPanel = true, xpos = 0, ypos = 350, width = 300, height = 500, useXpos = 800, useYpos = 100, useUI = true,
										showLevel = true, showZone = true, sortBy = 'level', colorByLevel = true, autoHide = false,
								moveable = true, displayHeader = true,  bgAlpha = .6, categoryHeaderSize = 16,
								useareaquestui = true,
								areaquestui = {xpos = 800, ypos = 850, width = 300, moveable = true},
								categoryOrder = { "crafting", "daily", "weekly", "monthly", "guild", "ia", "pvp", "world", "zone", "area", "instant", "raid", "story", "personal", "carnage"},
								categoryColor = { 
													guild = { 0, 0.58, 1 }, ia = { 0.737, 1, 0.804 }, pvp = { 1, 0.417, 0 }, story = { 0.839, 0.498, 1},
													world = {1, 1, 1}, zone = { 0.737, 1, 0.804 }, area = { 0.655, 1, 0.357 }, instant = { 1, 0.847, 0 }, raid = { 1, 0.417, 0 },
												  crafting = { 0, 0.715, 0.875 }, daily = { 0.498, 0.788, 1 }, monthly = { 0, 0.58, 1 }, weekly = { 0, 0.58, 1 }, personal = { 0.839, 0.498, 1}, carnage = { 0.839, 0.498, 1}},
								categoryShow = {crafting = true, world = true, daily = true, guild = true, ia = true, monthly = true, weekly = true, zone = true, area = true, instant = true, raid = true, story = true, personal = true, carnage = true, pvp = true},
								categoryFontSize = { 
														ia = { header = 15, body = 13},  guild = { header = 15, body = 13},  carnage = { header = 15, body = 13}, pvp = { header = 15, body = 13},
														world = { header = 15, body = 13},  zone = { header = 15, body = 13},  area = { header = 15, body = 13}, story = { header = 15, body = 13},
													 instant = { header = 15, body = 13}, raid = { header = 15, body = 13}, personal = { header = 15, body = 13},
													 crafting = { header = 15, body = 13}, daily = { header = 15, body = 13}, monthly = { header = 15, body = 13}, weekly = { header = 15, body = 13}},
								bodyColor = {1, 1, 1},
								bodyCompleteColor = {.6, .6, .6},
								collapseState = {},
								categoryCollapseState = {}
						 } 
						 
			nkQuestTrackerSetup.xpos = EnKai.uiGetBoundRight() - 300
			nkQuestTrackerSetup.areaquestui.xpos = EnKai.uiGetBoundRight() - 300
		else
		
			if nkQuestTrackerSetup.categoryHeaderSize == nil then nkQuestTrackerSetup.categoryHeaderSize = 16 end
			
			if nkQuestTrackerSetup.categoryCollapseState == nil then nkQuestTrackerSetup.categoryCollapseState = {} end
			
			if nkQuestTrackerSetup.useXpos == nil then nkQuestTrackerSetup.useXpos = 800 end
			if nkQuestTrackerSetup.useYpos == nil then nkQuestTrackerSetup.useYpos = 100 end
			if nkQuestTrackerSetup.useUI == nil then nkQuestTrackerSetup.useUI = true end
			
			if nkQuestTrackerSetup.autoHide == nil then nkQuestTrackerSetup.autoHide = false end
			
			if nkQuestTrackerSetup.categoryColor.pvp == nil then
				table.insert(nkQuestTrackerSetup.categoryOrder, 6, "pvp")
				nkQuestTrackerSetup.categoryColor.pvp = { 0, 0.58, 1 }
				nkQuestTrackerSetup.categoryShow.pvp = true
				nkQuestTrackerSetup.categoryFontSize.pvp = { header = 15, body = 13}
			end
			
			if nkQuestTrackerSetup.categoryColor.guild == nil then
				table.insert(nkQuestTrackerSetup.categoryOrder, 4, "guild")
				table.insert(nkQuestTrackerSetup.categoryOrder, 5, "ia")
				
				nkQuestTrackerSetup.categoryColor.guild = { 0, 0.58, 1 }
				nkQuestTrackerSetup.categoryColor.ia = { 0.737, 1, 0.804 }
				
				nkQuestTrackerSetup.categoryShow.guild = true
				nkQuestTrackerSetup.categoryShow.ia = true
				
				nkQuestTrackerSetup.categoryFontSize.guild = { header = 15, body = 13}
				nkQuestTrackerSetup.categoryFontSize.ia = { header = 15, body = 13}
				
			end
			
			if nkQuestTrackerSetup.showLevel == nil then nkQuestTrackerSetup.showLevel = true end
			if nkQuestTrackerSetup.showZone == nil then nkQuestTrackerSetup.showZone = true end
			if nkQuestTrackerSetup.sortBy == nil then nkQuestTrackerSetup.sortBy = 'name' end
			if nkQuestTrackerSetup.colorByLevel == nil then nkQuestTrackerSetup.colorByLevel = true end
			
			-- V2.0.1 changes
			
			if nkQuestTrackerSetup.categoryColor["carnage"] == nil then
			   table.insert(nkQuestTrackerSetup.categoryOrder, "carnage")
			   nkQuestTrackerSetup.categoryColor["carnage"] = { 0.839, 0.498, 1}
			   nkQuestTrackerSetup.categoryShow["carnage"] = true
			   nkQuestTrackerSetup.categoryFontSize["carnage"] = { header = 15, body = 13}
			end
			
			-- V2.4.0 changes
			
			if nkQuestTrackerSetup.useareaquestui == nil then
				nkQuestTrackerSetup.useareaquestui = true
				nkQuestTrackerSetup.areaquestui = {xpos = 800, ypos = 200, width = 300, moveable = true}
			elseif nkQuestTrackerSetup.areaquestui.width == 3 then
				nkQuestTrackerSetup.areaquestui.width = 300
			end
			
			-- V2.6.1 changes
			
			if not EnKai.tools.table.isMember(nkQuestTrackerSetup.categoryOrder, "story") then
				table.insert(nkQuestTrackerSetup.categoryOrder, "story")
				nkQuestTrackerSetup.categoryColor.story = { 0.839, 0.498, 1}
				nkQuestTrackerSetup.categoryShow.story = true
				nkQuestTrackerSetup.categoryFontSize.story = { header = 15, body = 13}
			end

			-- V3.0.2 changes

			if not EnKai.tools.table.isMember(nkQuestTrackerSetup.categoryOrder, "monthly") then
				nkQuestTrackerSetup.categoryOrder = { "crafting", "daily", "weekly", "monthly", "guild", "ia", "pvp", "world", "zone", "area", "instant", "raid", "story", "personal", "carnage"}
				nkQuestTrackerSetup.categoryColor.monthly = { 0, 0.58, 1 }
				nkQuestTrackerSetup.categoryShow.monthly = true
				nkQuestTrackerSetup.categoryFontSize.monthly = { header = 15, body = 13}
			end
			
		end
	
	end
	
end

---------- addon internal function block ---------

local function _fctShortenName (name, maxLen)

    if stringLen(name) <= maxLen then
        return name
    end

    local splitName = stringSplit(name, " ") or stringSplit(name, "-")

    if #splitName == 1 then
        return stringSub(name, 1, maxLen)
    end

    local thisName = ""
    for idx = 1, #splitName - 1 do
        local tempName = stringSub(splitName[idx], 1, 1)
        if unitFrameType ~= "raid" then
            thisName = thisName .. tempName .. ". "
        end
    end

    return thisName .. splitName[#splitName]

end

function internal.fillLog ()

	local list = oInspectQuestList()
	local flag, details = pcall(oInspectQuestDetail, list)
	
	if flag == false then return end
	
	local newCollapseState = {}
	
	--local questList = { personal = {} }
	local areaQuestKey
	
	for k, v in pairs(details) do
		if v.name ~= nil and v.name ~= "" then
		
			if uiElements.areaQuestUI ~= nil and EnKai.tools.table.isMember (data.areaQuestDomain, details.domain) then areaQuestKey = k end
		
			local addQuest = true
			if data.zoneFilter == true then
				addQuest = nkQuestBase.query.IsQuestInZone (_playerZoneID, v.id)
			end
		
			if addQuest == true then
				table.insert(data.addQuestList, k)
				newCollapseState[k] = nkQuestTrackerSetup.collapseState[k]
			end
		end
	end
	
	nkQuestTrackerSetup.collapseState = newCollapseState
	
	if (#data.addQuestList == 0) then uiElements.questLog:GetContent():SetVisible(true) end
	
	if areaQuestKey ~= nil then
		flag, details = pcall(oInspectQuestDetail, areaQuestKey)
		uiElements.areaQuestUI:AddQuest(areaQuestKey, details.domain, details.name, details.objective, details.complete, details.level, details.zone)
	elseif uiElements.areaQuestUI ~= nil then
		uiElements.areaQuestUI:SetVisible(false)
	end
	 
end

function internal.clearLog(callBack)

	--uiElements.questLog:Collapse(true)
	
	local list =  oInspectQuestList()

	for key, v in pairs(list) do
		table.insert(data.removeQuestList, key)
	end
	
	if callBack ~= nil then table.insert(data.removeQuestList, callBack) end

end

function internal.processQuest(details, processTitleFlag)

	local setDomain = false

	if details.rewardChoose ~= nil then
		for k, v in pairs(details.rewardChoose) do
			if EnKai.tools.table.isMember (_craftingItems, k) == true then
				if details.tagName ~= nil then details.name = stringFormat("%s (%s)", details.name, details.tagName) end
				details.domain = "crafting"
				setDomain = true
				break
			end
		end
	end

	if setDomain == false and details.rewardGuaranteed ~= nil then
		for k, v in pairs(details.rewardGuaranteed) do
			if EnKai.tools.table.isMember (_craftingItems, k) == true then
				if details.tagName ~= nil then details.name = stringFormat("%s (%s)", details.name, details.tagName) end
				details.domain = "crafting"
				setDomain = true
				break
			end
		end
	end

	if setDomain == false then
		if EnKai.strings.find(details.tag, 'weekly') ~= nil then
			if processTitleFlag == true then details.name = stringFormat("%s (%s)", details.name, details.tagName) end
			details.domain = 'weekly'
			setDomain = true
		elseif EnKai.strings.find(details.tag, 'daily') ~= nil then
			if processTitleFlag == true then details.name = stringFormat("%s (%s)", details.name, details.tagName) end
			details.domain = 'daily'
			setDomain = true
		elseif EnKai.strings.find(details.tag, 'story') then
			details.domain = 'story'
			setDomain = true
		elseif details.domain == nil then		
			if details.tag ~= nil then
				if EnKai.strings.find(details.tag, 'dungeon') then
					details.domain = 'instant'
					setDomain = true
				elseif EnKai.strings.find(details.tag, 'monthly') then
					details.domain = 'monthly'
					setDomain = true
				else
					if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internal.processQuest", "no domain 1", details) end
					details.domain = 'personal'
				end
			elseif EnKai.strings.find(details.name, privateVars.langTexts.identifierCarnage) then
				details.domain = 'carnage'
				setDomain = true
			else
				if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internal.processQuest", "no domain 2", details) end
				details.domain = 'personal'
			end
		end
	end

	local lvl, libDetails = nkQuestBase.query.byKey(details.id, nkQuestTrackerSetup.showZone)

	if libDetails ~= nil then

		if libDetails.domain ~= nil then 
			details.domain = libDetails.domain
		elseif libDetails.type ~= nil then
			if EnKai.tools.table.isMember(libDetails.type, 9) then details.domain = "carnage" end
		end

		details.grp = libDetails.grp
		if nkQuestTrackerSetup.showLevel == true then details.level = lvl end
		details.use = libDetails.use
		
		if nkQuestTrackerSetup.showZone == true and libDetails.zoneId ~= nil and libDetails.zoneId ~= "UKNOWN_ZONE" then
			if _zoneInfo[libDetails.zoneId] == nil then
				local zoneInfo = oInspectZoneDetail(libDetails.zoneId)
				if zoneInfo ~= nil then _zoneInfo[libDetails.zoneId] = zoneInfo.name end
			end

			if _zoneInfo[libDetails.zoneId] ~= nil then 
				details.zone = _zoneInfo[libDetails.zoneId]
			end 
		end
	end

	-- categoryName includes the zone name for dungeon quests
	
	if details.zone == nil and details.domain == 'instant' then
		details.zone = details.categoryName
	end
	
	if EnKai.strings.find(details.tag, 'story') ~= nil and details.zone == nil and details.categoryName ~= nil then
		--local shortenedCategory = _fctShortenName (details.categoryName, 10)
		details.name = stringFormat("%s:\n%s", details.categoryName, details.name)
	end	

	if processTitleFlag == true then

		--if nkQuestTrackerSetup.colorByLevel == true then
		local color = "#009900"

		if lvl == nil then
			color = "#009900"
		elseif lvl < data.playerLevel -7 then
			color = "#8E8E8E"
		elseif lvl > data.playerLevel +5 then
			color = "#FF3333"
		elseif lvl > data.playerLevel + 2 then
			color = "#FF8000"
		end

		if color ~= nil and details.level ~= nil then
			details.level = stringFormat("<font color='%s'>%s</font>", color, details.level)
		end

		if details.complete == true then details.name = stringFormat(privateVars.langTexts.completeInfo, details.name) end

		details.subName = details.zone

		if details.tag == "raid story" then
			details.name = stringFormat("%s (Raid)", details.name)
		end

		--[[
		if details.zone ~= nil and details.level ~= nil then
			if nkQuestTrackerSetup.sortBy == 'name' then
				details.name = details.name
				details.subName = stringFormat("%s %s", details.level, details.zone)
			elseif nkQuestTrackerSetup.sortBy == 'zone' then
				details.name = details.zone
				details.subName = stringFormat("%s %s", details.level, details.name)
			else
				details.name = stringFormat("%s %s", details.level, details.name)
				details.subName = details.zone
			end
		elseif details.zone ~= nil then
			if nkQuestTrackerSetup.sortBy == 'name' then
				details.name = details.name
				details.subName = stringFormat("%s", details.zone)
			elseif details.zone ~= nil then
				details.name = details.zone
				details.subName = details.name
			end
		else
			if nkQuestTrackerSetup.sortBy == 'name' then
				details.name = details.name
				details.subName = stringFormat("%s", details.level)
			elseif details.level ~= nil then
				details.name = stringFormat("%s %s", details.level, details.name)
				details.subName = nil
			end
		end
		]]
		--end
	end

	return lvl
	
end

function internal.showTooltip (parent, questkey, itemkey, category, message)

	if uiElements.tooltip == nil then
		uiElements.tooltip = EnKai.uiCreateFrame("nkTooltip", 'nkQuestTracker.tooltip', uiElements.tooltipContext)
		uiElements.tooltip:SetLayer(2)
		uiElements.tooltip:SetFont (addonInfo.id, "Montserrat")
	end
	
	local tooltip = uiElements.tooltip
	local quest, flag

	tooltip:ClearAll()
	tooltip:SetTitleFontSize(15)
	
	if message ~= nil then
		tooltip:SetTitle(addonInfo.toc.Identifier)
		tooltip:SetTitleColor(1, 1, 1)
	else
	   if (questkey ~= nil) then
		   flag, quest = pcall(oInspectQuestDetail, questkey)
		   if flag == false or quest == nil then return end
		   if quest.domain == nil then quest.domain = 'personal' end
		   
		   tooltip:SetTitle(quest.name)
		elseif itemkey ~= nil then
		   
		   local details = oInspectItemDetail(itemkey)
		   if (details == nil) then return end
		   
		   local dbDetails = nkQuestBase.query.questItemByKey(details.type)
		   if dbDetails ~= nil and dbDetails['use_' .. EnKai.tools.lang.getLanguageShort()] ~= nil then
		      message = dbDetails['use_' .. EnKai.tools.lang.getLanguageShort()]
		   elseif details.flavor ~= nil then
          message = details.flavor
        else
          message = ""
        end

	      tooltip:SetTitle(details.name)
		   
		end
		
		local color = nkQuestTrackerSetup.categoryColor[category]
		if color == nil then color = {1, 1, 1} end
		tooltip:SetTitleColor(color[1], color[2], color[3])
	end
				
	local text = ""
	if message ~= nil then
		text = message
	elseif quest.summary ~= nil then
		text = quest.summary
	elseif quest.description ~= nil then
		text = quest.description
	end
	
	local lines = {{ text = text, wordwrap = true, minWidth = 200, fontsize = 13 }}
	
	local lvl, libDetails = nil, nil
	
	if (questkey ~= nil ) then
	 lvl, libDetails = nkQuestBase.query.byKey(questkey, nkQuestTrackerSetup.showZone)
	end
	
	if libDetails ~= nil then
		local scene = libDetails.scene
		local npc
		
		if libDetails.giver ~= nil then
			npc = nkQuestBase.query.NPC (libDetails.giver)
			if npc ~= nil then
				if npc.scene ~= nil then scene = npc.scene[EnKai.tools.lang.getLanguageShort()] end
				table.insert (lines, { text = "", height = 10})
				table.insert (lines, { text = stringFormat(privateVars.langTexts.questGiver, npc[EnKai.tools.lang.getLanguageShort()]), wordwrap = true, fontsize=13})
			end
		end
	
		if scene ~= nil then
			local sceneInfo = EnKai.location.getSceneInfo(scene)
			if sceneInfo ~= nil then
				if sceneInfo[EnKai.tools.lang.getLanguageShort()] ~= nil then
					scene = sceneInfo[EnKai.tools.lang.getLanguageShort()]
				end
			end
			
			if npc == nil then table.insert (lines, { text = "", height = 10}) end
			table.insert (lines, { text = stringFormat(privateVars.langTexts.scene, scene), wordwrap = true, fontsize=13})
			
		end
	end
	
	if quest ~= nil and quest.objective ~= nil then
		table.insert (lines, { text = "", height = 10})
		
		for k, v in pairs(quest.objective) do
			if v.complete ~= true then		
				table.insert(lines, {text = stringFormat("<font color='%s'>%s</font>", "#FFFFFF", v.description), wordwrap = true, fontsize = 13 })
			end
		end
	end

	if nkDebug then -- show quest key if nkDebug is enabled		
		table.insert (lines, { text = "", height = 10})
		table.insert(lines, {text = stringFormat("<font color='%s'>%s</font>", "#FF0000", questkey), wordwrap = true, fontsize = 13 })
	end
	
	tooltip:SetLines(lines)
	
	local mouse = oInspectMouse()
	
	if mouse.x + tooltip:GetWidth() > UIParent:GetWidth() then
	 tooltip:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -(UIParent:GetWidth()-mouse.x), mouse.y)
	else
	 tooltip:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x, mouse.y)
	end
		
	tooltip:SetVisible(true)

end

function internal.ShowConfig()

	if uiElements.config == nil then uiElements.config = internal.Config () end
	uiElements.config:SetVisible(true) 

end

-------------------- STARTUP EVENTS --------------------

Command.Event.Attach(Event.Addon.Load.End, _fctMain, "nkQuestTracker.Addon.Load.End")
Command.Event.Attach(Event.Addon.SavedVariables.Load.End, _fctSettingsHandler, "nkQuestTracker.SavedVariables.Load.End")