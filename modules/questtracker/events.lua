local addonInfo, privateVars = ...

---------- init namespace ---------

local uiElements	= privateVars.uiElements
local data			= privateVars.data
local questTracker	= privateVars.questTracker
local internalFunc	= privateVars.internalFunc

local inspectSystemSecure	= Inspect.System.Secure
local inspectTimeReal		= Inspect.Time.Real
local inspectQuestDetail	= Inspect.Quest.Detail
local inspectItemDetail		= Inspect.Item.Detail

local stringFind			= string.find
local stringFormat			= string.format
local stringMatch			= string.match
local stringSub				= string.sub

local LibEKLUnitGetPlayerDetails	= LibEKL.Unit.getPlayerDetails
local LibEKLUnitSetPlayerDetails	= LibEKL.Unit.setPlayerDetails

local LibEKLToolsMathRound			= LibEKL.Tools.Math.Round

---------- init local variables ---------

local forceUpdate		= nil
local lastQuestUpdate	= nil
local _addonInit		= false
local runQuestUpdate	= true
local updateQuestList	= {}
local _questCache		= {}

questTracker.carnageMobs = {}

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
		local thisObjective = details.objective[idx]
		local cachedObjective = cached.objective[idx]

   		if thisObjective ~= nil and cachedObjective ~= nil then
	      	if dthisObjective.complete ~= cachedObjective.complete then
	      		isUpdate = true
	      	elseif thisObjective.count ~= cachedObjective.count then
	      		isUpdate = true
	      	elseif thisObjective.description ~= cachedObjective.description then
	      		isUpdate = true
	      	elseif thisObjective.countDone ~= cachedObjective.countDone then
	            isUpdate = true
				end
			end
		end
	end
	
	return isUpdate

end

local function getCarnageNPC (objectiveText)

	local lang = LibEKL.Tools.Lang.GetLanguageShort()

    local pattern = "^%w+%s+(.-)%s+%d+/"	
    local fullName = stringMatch(objectiveText, pattern)
	
    if not fullName then 
		pattern = "^%w+:%s+([%w%s%-]+)%s+%d+/"
		fullName = stringMatch(objectiveText, pattern)

		if not fullName then
			return nil 
		end
	end

	--print (fullName)

   -- Handle German pluralization
    if lang == "DE" then
        -- Remove common German plural endings
        if stringSub(fullName, -3) == "nen" then
            fullName = stringSub(fullName, 1, -4)
        elseif stringSub(fullName, -1) == "e" then
            fullName = stringSub(fullName, 1, -2)
        elseif stringSub(fullName, -1) == "s" then
            fullName = stringSub(fullName, 1, -2)
        end
    elseif lang == "EN" then
        -- Handle English pluralization
        if stringSub(fullName, -1) == "s" then
            fullName = stringSub(fullName, 1, -2)
        end
	else
		return nil
    end

    return fullName

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

						--if details.categoryName ~= "Battle Pass" then

							questTracker.processQuest(details, true)							

							if details.domain == "carnage" then
								for k, v in pairs(details.objective) do
									--if not v.complete then
										local carnageNPC = getCarnageNPC(v.description)

										if carnageNPC then

											--print ("carnageNPC: " .. carnageNPC)

											questTracker.carnageMobs[carnageNPC] = {
												level = details.level,
												name = details.name, 
												desc = v.description, 
												count = v.count, 
												countDone = v.countDone 
											}

											if stringFind(carnageNPC, "-") then
												local temp = LibEKL.strings.split(carnageNPC, "-")
												for idx = 1, #temp, 1 do
													questTracker.carnageMobs[temp[idx]] = {
														level = details.level,
														name = details.name, 
														desc = v.description, 
														count = v.count, 
														countDone = v.countDone 
													}
												end
											end

											if stringFind(carnageNPC, " ") then
												local temp = LibEKL.strings.split(carnageNPC, " ")
												for idx = 1, #temp, 1 do
													questTracker.carnageMobs[temp[idx]] = {
														level = details.level,
														name = details.name, 
														desc = v.description, 
														count = v.count, 
														countDone = v.countDone 
													}
												end
											end
										end
										--dump (details)
									--end
								end
							end

							uiElements.questTracker:AddQuest(key, details.domain, details.name, details.subName, details.objective, details.complete, details.level, details.zone)
						--end

						coroutine.yield(idx)
					end
				end
			end
		end
	)
	
	local callBack = function ()
		runQuestUpdate = true
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
	LibEKL.Coroutines.Add ({ func = addCoRoutine, counter = #list, active = true, callBack = callBack })
	runQuestUpdate = false

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
							list[key] = nil
						elseif err == true and isUpdate == true then
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
		runQuestUpdate = true
		uiElements.progressBar:SetVisible(false)
		if uiElements.panel ~= nil then uiElements.panel:UpdateTitle() end
	end
	
	uiElements.progressBar:SetRange(1, #list)
	uiElements.progressBar:SetValue(1)
	if #list > 3 and uiElements.questTracker:GetVisible() == true then uiElements.progressBar:SetVisible(true) end
	LibEKL.Coroutines.Add ({ func = changeCoRoutine, counter = #list, active = true, callBack = callBack })
	runQuestUpdate = false
	
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
					
					uiElements.questTracker:RemoveQuest(key)
					_questCache[key] = nil
				end
				
		  		coroutine.yield(idx)
		  	end
		end
	)
	
	local callBack = function ()
		runQuestUpdate = true
		uiElements.progressBar:SetVisible(false)
		if uiElements.panel ~= nil then uiElements.panel:UpdateTitle() end
		uiElements.useUI:Update()
	end
	
	uiElements.progressBar:SetRange(1, #list)
	uiElements.progressBar:SetValue(1)
	if #list > 3 and uiElements.questTracker:GetVisible() == true then uiElements.progressBar:SetVisible(true) end
	LibEKL.Coroutines.Add ({ func = removeCoRoutine, counter = #list, active = true, callBack = callBack })
	runQuestUpdate = false

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

	local playerID = LibEKLUnitGetPlayerDetails().id

	if units[playerID] == nil or units[playerID] == false then return end
	
	LibEKLUnitSetPlayerDetails("level", units[playerID])
	
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

	if LibQB.query.isInit() == false then return end

	local isSecure = inspectSystemSecure()

	if uiElements.useUI == nil and isSecure == false then
		if LibEKL.Inventory.getAvailableSlots() ~= false then
			uiElements.useUI = questTracker.buildUseUI ()
			uiElements.useUI:Update()
		end
	elseif isSecure == false and data.useUpdate == true then
		uiElements.useUI:Update()
		data.useUpdate = false
	end

	if not runQuestUpdate then return end

	if not forceUpdate then
		if lastQuestUpdate == nil then
			lastQuestUpdate = inspectTimeReal()
			forceUpdate = true
		else
			local tmpTime = inspectTimeReal()
			if LibEKLToolsMathRound((tmpTime - lastQuestUpdate), 1) > 1 then forceUpdate = true end
		end
	end

	if forceUpdate then

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

		uiElements.questTracker:SetTitle(stringFormat("Quests (%d)", uiElements.questTracker:GetQuestCount()))
	end
end

function internalFunc.CheckCarnageNPC(npcName)

	return questTracker.carnageMobs[npcName]

end
