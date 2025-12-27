local addonInfo, privateVars = ...

---------- init namespace ---------

local uiElements	= privateVars.uiElements
local data			= privateVars.data
local questTracker	= privateVars.questTracker

local inspectSystemSecure	= Inspect.System.Secure
local inspectTimeReal		= Inspect.Time.Real
local inspectQuestDetail	= Inspect.Quest.Detail
local inspectItemDetail	= Inspect.Item.Detail

---------- init local variables ---------

local forceUpdate		= nil
local lastQuestUpdate	= nil
local _addonInit		= false
local _update			= false
local updateQuestList	= {}
local _questCache		= {}

---------- local function block ---------

local function isUpdate(cached, details)
        
	local isUpdate = false
	
	--print ('is update ' .. details.name)
        
	if details.name ~= cached.name or details.complete ~= cached.complete or #details.objective ~= #cached.objective then
		isUpdate = true
   elseif details.objective == nil or cached.objective == nil then
     	isUpdate = true
	else
   	for idx = 1, #details.objective, 1 do
   		if details.objective[idx] ~= nil and cached.objective[idx] ~= nil then
	      	if details.objective[idx].complete ~= cached.objective[idx].complete then
	      		isUpdate = true
	      	elseif details.objective[idx].count ~= cached.objective[idx].count then
	      		isUpdate = true
	      	elseif details.objective[idx].description ~= cached.objective[idx].description then
	      		isUpdate = true
	      	elseif details.objective[idx].countDone ~= cached.objective[idx].countDone then
	            isUpdate = true
				end
			end
		end
	end
	
	return isUpdate

end

local function questAdd(list)
	
	local addCoRoutine = coroutine.create(
		function ()
			for idx = 1, #list, 1 do
				uiElements.progressBar:SetValue(idx)
				local key = list[idx]
				
				if key ~= nil then
				
					local flag, details = pcall(inspectQuestDetail, key)
					if flag then

						if details.categoryName ~= "Battle Pass" then

							questTracker.processQuest(details, true)
							_questCache[key] = details
							
							if uiElements.areaQuestUI ~= nil and LibEKL.tools.table.isMember (data.areaQuestDomain, details.domain) and details.tag ~= nil and string.find(details.tag, "weekly") == nil then
								uiElements.areaQuestUI:AddQuest(key, details.domain, details.name, details.objective, details.complete, details.level, details.zone)
							end

							--if string.find(details.name, "Das goldene Ticket") ~= nil then dump(details) end
							
							uiElements.questTracker:AddQuest(key, details.domain, details.name, details.subName, details.objective, details.complete, details.level, details.zone)
						end

						coroutine.yield(idx)
					end
				end
			end
		end
	)
	
	local callBack = function ()
		_update = false
		if (_addonInit == false) then
		   uiElements.questTracker:SetVisible(true)
		   _addonInit = true
		end
		uiElements.progressBar:SetVisible(false)
		if uiElements.panel ~= nil then uiElements.panel:UpdateTitle() end
	end
	
	uiElements.progressBar:SetRange(1, #list)
	uiElements.progressBar:SetValue(1)
	if #list > 3 and uiElements.questTracker:GetVisible() == true then uiElements.progressBar:SetVisible(true) end
	LibEKL.coroutines.add ({ func = addCoRoutine, counter = #list, active = true, callBack = callBack })
	_update = true

end

local function questChange(list)

	local changeCoRoutine = coroutine.create(
		function ()
			for idx = 1, #list, 1 do
				uiElements.progressBar:SetValue(idx)
				local key = list[idx]
				local flag, details = pcall( inspectQuestDetail, key)
				if flag then 
					questTracker.processQuest(details, true)

					if _questCache[key] ~= nil and details.name ~= "" then
						local err, isUpdate = pcall(isUpdate, _questCache[key], details)

						if err == false then
							if nkQuestTrackerSetup.debug == true then
								print('---------------------------------')
								dump(_questCache[key])
								dump(details)
							end	

							list[key] = nil
						elseif err == true and isUpdate == true then

							if uiElements.areaQuestUI ~= nil and LibEKL.tools.table.isMember (data.areaQuestDomain, details.domain) then
								uiElements.areaQuestUI:UpdateQuest(key, details.domain, details.name, details.objective, details.complete, details.level, details.zone)
							end

							uiElements.questTracker:UpdateQuest(key, details.domain, details.name, details.subName, details.objective, details.complete, details.level)
						end
					end

					_questCache[key] = details

					coroutine.yield(idx)
				end
			end
		end
	)
	
	local callBack = function ()
		_update = false
		uiElements.progressBar:SetVisible(false)
		if uiElements.panel ~= nil then uiElements.panel:UpdateTitle() end
	end
	
	uiElements.progressBar:SetRange(1, #list)
	uiElements.progressBar:SetValue(1)
	if #list > 3 and uiElements.questTracker:GetVisible() == true then uiElements.progressBar:SetVisible(true) end
	LibEKL.coroutines.add ({ func = changeCoRoutine, counter = #list, active = true, callBack = callBack })
	_update = true
	
end

local function questRemove(list)
	
	local removeCoRoutine = coroutine.create(
		function ()

			for idx = 1, #list, 1 do
				uiElements.progressBar:SetValue(idx)
				
				if type(list[idx]) == 'function' then
					list[idx]()
				else
					local key = list[idx]
					
					if uiElements.areaQuestUI ~= nil then
						uiElements.areaQuestUI:RemoveQuest(key)
					end
					
					uiElements.questTracker:RemoveQuest(key)
					_questCache[key] = nil
				end
				
		  		coroutine.yield(idx)
		  	end
		end
	)
	
	local callBack = function ()
		_update = false
		uiElements.progressBar:SetVisible(false)
		if uiElements.panel ~= nil then uiElements.panel:UpdateTitle() end
		uiElements.useUI:Update()
	end
	
	uiElements.progressBar:SetRange(1, #list)
	uiElements.progressBar:SetValue(1)
	if #list > 3 and uiElements.questTracker:GetVisible() == true then uiElements.progressBar:SetVisible(true) end
	LibEKL.coroutines.add ({ func = removeCoRoutine, counter = #list, active = true, callBack = callBack })
	_update = true

end

---------- addon internal functions ---------

function questTracker.eventInventoryUpdate(_, items)

	for k, v in pairs(items) do
		if k ~= useItemKey then
			if thisItem ~=  nil and thisItem.category == 'misc quest' then
				uiElements.useUI:Update()
				return
			end
		end
	end
end

function questTracker.eventUnitLevel(_, units)

	local playerID = LibEKL.unit.getPlayerDetails().id

	if units[playerID] == nil or units[playerID] == false then return end
	
	LibEKL.unit.setPlayerDetails("level", units[playerID])
	
	questTracker.clearLog(questTracker.fillLog)

end

function questTracker.eventQuestAccept (_, quests)

	for k, v in pairs (quests) do
		table.insert(data.addQuestList, k)
	end
	
end

function questTracker.eventQuestAbandon (_, quests)

	for k, v in pairs (quests) do
		table.insert(data.removeQuestList, k)
	end

end

function questTracker.eventQuestChange (_, quests)

	for k, v in pairs (quests) do
		table.insert(updateQuestList, k)
	end

end

function questTracker.eventQuestComplete (_, quests)

	for k, v in pairs (quests) do
      table.insert(data.removeQuestList, k)
	end

end

function questTracker.eventSystemUpdate()

	if nkQuestBase.query.isInit() == false then return end

	if uiElements.useUI == nil and inspectSystemSecure() == false then
		if LibEKL.inventory.getAvailableSlots() ~= false then
			uiElements.useUI = questTracker.buildUseUI ()
			uiElements.useUI:Update()
		end
	elseif inspectSystemSecure() == false and data.useUpdate == true then
		uiElements.useUI:Update()
		data.useUpdate = false
	end

	if _update == true then return end

	if forceUpdate ~= true then
		if lastQuestUpdate == nil then
			lastQuestUpdate = inspectTimeReal()
			forceUpdate = true
		else
			local tmpTime = inspectTimeReal()
			if LibEKL.tools.math.round((tmpTime - lastQuestUpdate), 1) > 1 then forceUpdate = true end
		end
	end

	if forceUpdate == true then

		if #data.addQuestList > 0 then
		
			questAdd(data.addQuestList)
			data.addQuestList = {}

		elseif #updateQuestList > 0 then

			questChange(updateQuestList)
			updateQuestList = {}

		elseif #data.removeQuestList > 0 then

			questRemove(data.removeQuestList)
			data.removeQuestList = {}

		end

		lastQuestUpdate = inspectTimeReal()
		forceUpdate = false

		uiElements.questTracker:SetTitle(string.format("Quests (%d)", uiElements.questTracker:GetQuestCount()))
	end
end