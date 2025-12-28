local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.questTracker = {}

local internalFunc	= privateVars.internalFunc
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local questTracker	= privateVars.questTracker

local inspectQuestDetail	= Inspect.Quest.Detail
local inspectItemDetail		= Inspect.Item.Detail
local inspectQuestList		= Inspect.Quest.List
local inspectZoneDetail		= Inspect.Zone.Detail
local inspectMouse			= Inspect.Mouse

local stringFormat			= string.format
local stringLen				= string.len
local stringSub				= string.sub
local stringSplit			= string.split

local LibEKLGetLanguageShort	= LibEKL.Tools.Lang.GetLanguageShort

---------- init local variables ---------

local colorR, colorG, colorB, colorA = 0.9, 0.74, 0, 1

local _craftingItems = {
	"I4CD48A0656A66436,41331FF662BDB8ED,,,,,,",
	"I21D9052625C52295,709CF1BA97DA8BF9,,,,,,",
	"I2D199E412D5BD46E,DEFE32C2157DE5B1,,,,,,",
	"I5B81BB103E80D890,110D59F273118747,,,,,,"
}

local _zoneInfo			= {}
local isInit			= false

---------- init variables ---------

data.zoneFilter			= false
data.addQuestList		= {}
data.removeQuestList	= {}
data.areaQuestDomain	= {"ia", "world", "zone", "area", "raid"}
data.categoryColor 		= { guild = { 0, 0.58, 1 }, 
							ia = { 0.737, 1, 0.804 }, 
							pvp = { 1, 0.417, 0 }, 
							story = { 0.839, 0.498, 1},
							world = {1, 1, 1}, 
							zone = { 0.737, 1, 0.804 }, 
							area = { 0.655, 1, 0.357 }, 
							instant = { 1, 0.847, 0 }, 
							raid = { 1, 0.417, 0 },
							crafting = { 0, 0.715, 0.875 }, 
							daily = { 0.498, 0.788, 1 }, 
							monthly = { 0, 0.58, 1 }, 
							weekly = { 0, 0.58, 1 }, 
							personal = { 0.839, 0.498, 1}, 
							carnage = { 0.839, 0.498, 1}
						}

---------- local function block ---------

function internalFunc.questTrackerInit(flag)

	 if flag then
        if isInit then
            --uiElements.questTracker:SetVisible(true)
			--uiElements.useUI:Toggle()
        else
            internalFunc.uiQuestTracker()
        end
    else
        --if uiElements.questTracker then
        --    uiElements.questTracker:SetVisible(false)
		--	uiElements.useUI:Toggle()
        --end
    end    
end

function internalFunc.uiQuestTracker()

	if isInit then return end

	LibQB.loadPackage("classic")
	LibQB.loadPackage("nt")
	LibQB.loadPackage("sfp")
		
	LibEKL.inventory.init()
	
	if uiElements.questTracker == nil then
		
		uiElements.questTracker = questTracker.buildUI ()
		
		questTracker.fillLog ()
		
		uiElements.progressBar = LibEKL.uiCreateFrame("nkProgressBar", "nkUI.questTracker.progressBar", uiElements.questTracker)
		uiElements.progressBar:SetPoint("CENTERTOP", uiElements.questTracker, "CENTERTOP", 0, 40)
		
		uiElements.progressBar:SetWidth(uiElements.questTracker:GetWidth()-20)
		uiElements.progressBar:SetHeight(20)
		uiElements.progressBar:SetLayer(99)
		uiElements.progressBar:SetVisible(false)
		uiElements.progressBar:SetFontColor(0, 0, 0, 1)
		uiElements.progressBar:SetBorderColor(colorR, colorG, colorB, colorA)
		uiElements.progressBar:SetFillColor(colorR, colorG, colorB, colorA)
				
		Command.Event.Attach(Event.Quest.Accept, questTracker.eventQuestAccept, "nkUI.questtracker.Quest.Accept")
		Command.Event.Attach(Event.Quest.Abandon, questTracker.eventQuestAbandon, "nkUI.questtracker.Quest.Abandon")
		Command.Event.Attach(Event.Quest.Change, questTracker.eventQuestChange, "nkUI.questtracker.Quest.Change")
		Command.Event.Attach(Event.Quest.Complete, questTracker.eventQuestComplete, "nkUI.questtracker.Quest.Complete")
		Command.Event.Attach(Event.System.Update.Begin, questTracker.eventSystemUpdate, "nkUI.questtracker.System.Update.Begin")
			
		Command.Event.Attach(Event.Unit.Detail.Level, questTracker.eventUnitLevel, "nkUI.questtracker.Unit.Detail.Level")
		
		Command.Event.Attach(LibEKL.events["LibEKL.InventoryManager"].Update, questTracker.eventInventoryUpdate, "nkUI.questtracker.LibEKL.InventoryManager.update")

	end

	uiElements.questTracker:SetTitle(stringFormat("Quests (%d)", uiElements.questTracker:GetQuestCount()))

	isInit = true

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

function questTracker.fillLog ()
	
	local list = inspectQuestList()
	local flag, details = pcall(inspectQuestDetail, list)
	
	if flag == false then return end
	
	local newCollapseState = {}
	
	local areaQuestKey
	
	for k, v in pairs(details) do
		if v.name ~= nil and v.name ~= "" then
		
			local addQuest = true
			if data.zoneFilter == true then
				addQuest = LibQB.query.IsQuestInZone (LibEKL.Unit.getPlayerDetails().zone, v.id)
			end
		
			if addQuest == true then
				table.insert(data.addQuestList, k)
				newCollapseState[k] = nkUISetup.modules.questtracker.collapseState[k]
			end
		end
	end
	
	nkUISetup.modules.questtracker.collapseState = newCollapseState
	
	if (#data.addQuestList == 0) then uiElements.questTracker:GetContent():SetVisible(true) end
		 
end

function questTracker.clearLog(callBack)

	--uiElements.questTracker:Collapse(true)
	
	local list = inspectQuestList()

	for key, v in pairs(list) do
		table.insert(data.removeQuestList, key)
	end
	
	if callBack ~= nil then table.insert(data.removeQuestList, callBack) end

end

function questTracker.processQuest(details, processTitleFlag)

	local setDomain = false

	if details.rewardChoose ~= nil then
		for k, v in pairs(details.rewardChoose) do
			if LibEKL.Tools.Table.IsMember (_craftingItems, k) == true then
				if details.tagName ~= nil then details.name = stringFormat("%s (%s)", details.name, details.tagName) end
				details.domain = "crafting"
				setDomain = true
				break
			end
		end
	end

	if setDomain == false and details.rewardGuaranteed ~= nil then
		for k, v in pairs(details.rewardGuaranteed) do
			if LibEKL.Tools.Table.IsMember (_craftingItems, k) == true then
				if details.tagName ~= nil then details.name = stringFormat("%s (%s)", details.name, details.tagName) end
				details.domain = "crafting"
				setDomain = true
				break
			end
		end
	end

	if setDomain == false then
		if LibEKL.strings.find(details.tag, 'weekly') ~= nil then
			if processTitleFlag == true then details.name = stringFormat("%s (%s)", details.name, details.tagName) end
			details.domain = 'weekly'
			setDomain = true
		elseif LibEKL.strings.find(details.tag, 'daily') ~= nil then
			if processTitleFlag == true then details.name = stringFormat("%s (%s)", details.name, details.tagName) end
			details.domain = 'daily'
			setDomain = true
		elseif LibEKL.strings.find(details.tag, 'story') then
			details.domain = 'story'
			setDomain = true
				elseif details.domain == nil then		
			if details.tag ~= nil then
				if LibEKL.strings.find(details.tag, 'dungeon') then
					details.domain = 'instant'
					setDomain = true
				elseif LibEKL.strings.find(details.tag, 'monthly') then
					details.domain = 'monthly'
					setDomain = true
				else
					if nkDebug then nkDebug.logEntry (addonInfo.identifier, "questTracker.processQuest", "no domain 1", details) end
					details.domain = 'personal'
				end
			elseif LibEKL.strings.find(details.name, privateVars.langTexts.identifierCarnage) then
				details.domain = 'carnage'
				setDomain = true
			else
				if nkDebug then nkDebug.logEntry (addonInfo.identifier, "questTracker.processQuest", "no domain 2", details) end
				details.domain = 'personal'
			end
		end
	end

	local lvl, libDetails = LibQB.query.byKey(details.id, true)

	if libDetails ~= nil then

		if libDetails.domain ~= nil then 
			details.domain = libDetails.domain
		elseif libDetails.type ~= nil then
			if LibEKL.Tools.Table.IsMember(libDetails.type, 9) then details.domain = "carnage" end
		end

		details.grp = libDetails.grp
		details.level = lvl
		details.use = libDetails.use
		
		if libDetails.zoneId ~= nil and libDetails.zoneId ~= "UNKNOWN_ZONE" then
			if _zoneInfo[libDetails.zoneId] == nil then
				local zoneInfo = inspectZoneDetail(libDetails.zoneId)
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
	
	if LibEKL.strings.find(details.tag, 'story') ~= nil and details.zone == nil and details.categoryName ~= nil then
		details.name = stringFormat("%s:\n%s", details.categoryName, details.name)
	end	

	if processTitleFlag == true then

		local color = "#009900"
		local playerLevel = LibEKL.Unit.getPlayerDetails().level

		if lvl == nil then
			color = "#009900"
		elseif lvl < playerLevel -7 then
			color = "#8E8E8E"
		elseif lvl > playerLevel +5 then
			color = "#FF3333"
		elseif lvl > playerLevel + 2 then
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
	end

	return lvl
	
end

function questTracker.showTooltip (parent, questkey, itemkey, category, message)

	if uiElements.qtTooltip == nil then
		uiElements.qtTooltip = LibEKL.uiCreateFrame("nkTooltip", 'nkUI.questtracker.tooltip', uiElements.contextTooltip)
		uiElements.qtTooltip:SetLayer(2)
		uiElements.qtTooltip:SetFont (addonInfo.id, "MontserratSemiBold")
	end
	
	local tooltip = uiElements.qtTooltip
	local quest, flag

	tooltip:ClearAll()
	tooltip:SetTitleFontSize(15)
	
	if message ~= nil then
		tooltip:SetTitle(addonInfo.toc.Identifier)
		tooltip:SetTitleColor(1, 1, 1)
	else
	   if (questkey ~= nil) then
		   flag, quest = pcall(inspectQuestDetail, questkey)
		   if flag == false or quest == nil then return end
	
		   if quest.domain == nil then quest.domain = 'personal' end
		   
		   tooltip:SetTitle(quest.name)
		elseif itemkey ~= nil then
		   
		   local details = inspectItemDetail(itemkey)
		   if (details == nil) then return end
		   
		   local dbDetails = LibQB.query.questItemByKey(details.type)
		   if dbDetails ~= nil and dbDetails['use_' .. LibEKLGetLanguageShort()] ~= nil then
		      message = dbDetails['use_' .. LibEKLGetLanguageShort()]
		   elseif details.flavor ~= nil then
          message = details.flavor
        else
          message = ""
        end

	      tooltip:SetTitle(details.name)
		   
		end
		
		local color = data.categoryColor[category]
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
		lvl, libDetails = LibQB.query.byKey(questkey, true)
	end
	
	if libDetails ~= nil then
		local scene = libDetails.scene
		local npc
		
		if libDetails.giver ~= nil then
			npc = LibQB.query.NPC (libDetails.giver)
			if npc ~= nil then
				if npc.scene ~= nil then scene = npc.scene[LibEKLGetLanguageShort()] end
				table.insert (lines, { text = "", height = 10})
				table.insert (lines, { text = stringFormat(privateVars.langTexts.questGiver, npc[LibEKLGetLanguageShort()]), wordwrap = true, fontsize=13})
			end
		end
	
		if scene ~= nil then
			local sceneInfo = LibEKL.location.getSceneInfo(scene)
			if sceneInfo ~= nil then
				if sceneInfo[LibEKLGetLanguageShort()] ~= nil then
					scene = sceneInfo[LibEKLGetLanguageShort()]
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
				table.insert(lines, {text = stringFormat("<font color='%s'>%s</font>", "#cccccc", v.description), wordwrap = true, fontsize = 13 })
			end
		end
	end

	if nkDebug then -- show quest key if nkDebug is enabled		
		table.insert (lines, { text = "", height = 10})
		table.insert(lines, {text = stringFormat("<font color='%s'>%s</font>", "#FF0000", questkey), wordwrap = true, fontsize = 13 })
	end
	
	tooltip:SetLines(lines)
	
	LibEKL.ui.showWithinBound (tooltip, parent)
--[[
	local mouse = inspectMouse()
	
	if mouse.x + tooltip:GetWidth() > UIParent:GetWidth() then
		tooltip:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -(UIParent:GetWidth()-mouse.x), mouse.y)
	else
		tooltip:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x, mouse.y)
	end
]]		
	tooltip:SetVisible(true)

end