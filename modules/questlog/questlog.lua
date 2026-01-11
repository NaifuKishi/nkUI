local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.questLog = {}

local internalFunc	= privateVars.internalFunc
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local questLog		= privateVars.questLog
local langTexts		= privateVars.langTexts

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

local PROGRESSBAR_COLOR = {0.9, 0.74, 0, 1}

questLog.bodyColor = { .827, .827, .827, 1 }
questLog.bodyCompleteColor = {.6, .6, .6, 1}

local _craftingItems = {
	"I4CD48A0656A66436,41331FF662BDB8ED,,,,,,",
	"I21D9052625C52295,709CF1BA97DA8BF9,,,,,,",
	"I2D199E412D5BD46E,DEFE32C2157DE5B1,,,,,,",
	"I5B81BB103E80D890,110D59F273118747,,,,,,"
}

local _zoneInfo			= {}
local isInit			= false

questLog.context = UI.CreateContext("nkUI.questLog")
questLog.context:SetStrata('hud')
questLog.context:SetLayer(2)

---------- init variables ---------

data.addQuestLog		= {}
data.removeQuestLog		= {}
data.areaQuestDomain	= {"ia", "world", "zone", "area", "raid"}
data.categoryColor 		= { battlepass = { 0, 0.58, 1 },
							guild = { 0, 0.58, 1 }, 
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

local function shortenName(name, maxLen)

	 if stringLen(name) <= maxLen then
        return name
    end

    return stringSub(name, 1, maxLen) .. "..."

end

function internalFunc.questLogInit()
	
	if isInit then
		uiElements.questLog:SetVisible(not uiElements.questLog:GetVisible())
	else
		internalFunc.uiQuestLog()
	end

end

function internalFunc.uiQuestLog()

	if isInit then return end

	LibQB.loadPackage("classic")
	LibQB.loadPackage("nt")
	LibQB.loadPackage("sfp")
		
	LibEKL.Inventory.Init()
	
	if uiElements.questLog == nil then
		
		uiElements.questLog = questLog.buildUI ()
		
		questLog.fillLog ()
		
		if not uiElements.qlProgressBar then
			uiElements.qlProgressBar = LibEKL.UICreateFrame("nkProgressBar", "nkUI.questLog.progressBar", uiElements.questLog)
			uiElements.qlProgressBar:SetPoint("CENTERTOP", uiElements.questLog, "CENTERTOP", 0, 40)
			
			uiElements.qlProgressBar:SetWidth(uiElements.questLog:GetWidth()-20)
			uiElements.qlProgressBar:SetHeight(20)
			uiElements.qlProgressBar:SetLayer(99)
			uiElements.qlProgressBar:SetVisible(false)
			uiElements.qlProgressBar:SetFontColor(0, 0, 0, 1)
			uiElements.qlProgressBar:SetFont(addonInfo.id, "MontserratSemiBold")
			uiElements.qlProgressBar:SetBorderColor(PROGRESSBAR_COLOR[1], PROGRESSBAR_COLOR[2], PROGRESSBAR_COLOR[3], PROGRESSBAR_COLOR[4])
			uiElements.qlProgressBar:SetFillColor(PROGRESSBAR_COLOR[1], PROGRESSBAR_COLOR[2], PROGRESSBAR_COLOR[3], PROGRESSBAR_COLOR[4])
		end
		
		Command.Event.Attach(Event.Quest.Accept, questLog.eventQuestAccept, "nkUI.questLog.Quest.Accept")
		Command.Event.Attach(Event.Quest.Abandon, questLog.eventQuestAbandon, "nkUI.questLog.Quest.Abandon")
		Command.Event.Attach(Event.Quest.Change, questLog.eventQuestChange, "nkUI.questLog.Quest.Change")
		Command.Event.Attach(Event.Quest.Complete, questLog.eventQuestComplete, "nkUI.questLog.Quest.Complete")
		Command.Event.Attach(Event.System.Update.Begin, questLog.eventSystemUpdate, "nkUI.questLog.System.Update.Begin")
			
		Command.Event.Attach(Event.Unit.Detail.Level, questLog.eventUnitLevel, "nkUI.questLog.Unit.Detail.Level")
		
		Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].Update, questLog.eventInventoryUpdate, "nkUI.questLog.LibEKL.InventoryManager.update")

	end

	uiElements.questLog:SetVisible(true)

	uiElements.questLog:SetTitle(stringFormat("Quests (%d)", uiElements.questLog:GetQuestCount()))

	isInit = true

end

---------- addon internal function block ---------

function questLog.fillLog ()
	
	local list = inspectQuestList()
	local flag, details = pcall(inspectQuestDetail, list)
	
	if flag == false then return end
	
	local isFirstQuest = true

	for k, v in pairs(details) do
		if isFirstQuest then
			uiElements.questLog:UpdateQuestDetails(k)
			isFirstQuest = false
		end

		if v.name ~= nil and v.name ~= "" then		
			local addQuest = true
		
			if addQuest == true then
				table.insert(data.addQuestLog, k)
			end
		end
	end
		
end

function questLog.clearLog(callBack)

	local list = inspectQuestList()

	for key, v in pairs(list) do
		table.insert(data.removeQuestLog, key)
	end
	
	if callBack ~= nil then table.insert(data.removeQuestLog, callBack) end

end

function questLog.processQuest(details, processTitleFlag)

	local setDomain = false

	if details.categoryName == privateVars.langTexts.battlePass then
		details.domain = "battlepass"
		setDomain = true
	end

	if details.rewardChoose ~= nil then
		for k, v in pairs(details.rewardChoose) do
			if LibEKL.Tools.Table.IsMember (_craftingItems, k) == true then
				if details.tagName ~= nil then details.name = stringFormat("%s (%s)", shortenName(details.name, 30), details.tagName) end
				details.domain = "crafting"
				setDomain = true
				break
			end
		end
	end

	if setDomain == false and details.rewardGuaranteed ~= nil then
		for k, v in pairs(details.rewardGuaranteed) do
			if LibEKL.Tools.Table.IsMember (_craftingItems, k) == true then
				if details.tagName ~= nil then details.name = stringFormat("%s (%s)", shortenName(details.name, 30), details.tagName) end
				details.domain = "crafting"
				setDomain = true
				break
			end
		end
	end	

	if setDomain == false then
		if LibEKL.strings.find(details.tag, 'weekly') ~= nil then
			if processTitleFlag == true then details.name = shortenName(details.name, 30) end
			details.domain = 'weekly'
			setDomain = true
		elseif LibEKL.strings.find(details.tag, 'daily') ~= nil then
			if processTitleFlag == true then details.name = shortenName(details.name, 30) end
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
					if nkDebug then nkDebug.logEntry (addonInfo.identifier, "questLog.processQuest", "no domain 1", details) end
					details.domain = 'personal'
				end
			elseif LibEKL.strings.find(details.name, privateVars.langTexts.identifierCarnage) then
				details.domain = 'carnage'
				setDomain = true
			else
				if nkDebug then nkDebug.logEntry (addonInfo.identifier, "questLog.processQuest", "no domain 2", details) end
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

	if details.zone then details.domain = details.zone end
	
	if LibEKL.strings.find(details.tag, 'story') ~= nil and details.zone == nil and details.categoryName ~= nil then
		details.name = shortenName(stringFormat("%s: %s", details.categoryName, details.name), 30)
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

		if details.complete == true then details.name = stringFormat(privateVars.langTexts.completeInfo, shortenName(details.name, 30)) end

		if details.domain ~= details.zone then
			details.subName = details.zone
		end

		if details.tag == "raid story" then
			details.name = stringFormat("%s (Raid)", shortenName(details.name, 30))
		end
	end

	return lvl
	
end