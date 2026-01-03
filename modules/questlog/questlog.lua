local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.questLog = {}

local internalFunc	= privateVars.internalFunc
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local questLog		= privateVars.questLog

local inspectQuestList 		= Inspect.Quest.List
local inspectQuestDetail 	= Inspect.Quest.Detail

local stringFind	= string.find

local _questCache = {}

function questLog.getAllQuests()

	local list = inspectQuestList()
	local flag, details = pcall(inspectQuestDetail, list)
	
	if flag == false then return end
	
	for key, questDetail in pairs(details) do
		if v.name ~= nil and v.name ~= "" then					
			--questTracker.processQuest(details, true)
			_questCache[key] = questDetail
			--uiElements.questTracker:AddQuest(key, questDetail.domain, questDetail.name, questDetail.subName, questDetail.objective, questDetail.complete, questDetail.level, questDetail.zone)
		end
	end

end

function internalFunc.questLog()

	if not uiElements.questLog then
		uiElements.questLog = questLog.buildUI()

		Command.Event.Attach(Event.Quest.Accept, questLog.eventQuestAccept, "nkUI.questLog.Quest.Accept")
		Command.Event.Attach(Event.Quest.Abandon, questLog.eventQuestAbandon, "nkUI.questLog.Quest.Abandon")
		Command.Event.Attach(Event.Quest.Change, questLog.eventQuestChange, "nkUI.questLog.Quest.Change")
		Command.Event.Attach(Event.Quest.Complete, questLog.eventQuestComplete, "nkUI.questLog.Quest.Complete")
	else
		uiElements.questLog:SetVisible(true)
	end

end