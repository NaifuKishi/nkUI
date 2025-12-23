local addonInfo, privateVars = ...

---------- init namespace ---------

local internal		= privateVars.internal
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local events		= privateVars.events

local oInspectSystemSecure	= Inspect.System.Secure
local oInspectTimeReal		= Inspect.Time.Real
local oInspectQuestDetail	= Inspect.Quest.Detail
local oInspectItemDetail	= Inspect.Item.Detail

---------- init local variables ---------

local forceUpdate		= nil
local lastQuestUpdate	= nil
local _addonInit		= false
local _update			= false
local updateQuestList	= {}
--local _useItemUpdates	= {}
local _questCache		= {}
local _internalMove		= {}

---------- init variables ---------

---------- local function block ---------

local function _fctIsUpdate(cached, details)
        
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

local function _fctQuestAdd(list)
	
	local addCoRoutine = coroutine.create(
		function ()
			for idx = 1, #list, 1 do
				uiElements.progressBar:SetValue(idx)
				local key = list[idx]
				
				if key ~= nil then
				
					local flag, details = pcall(oInspectQuestDetail, key)
					if flag then

						if details.categoryName ~= "Battle Pass" then

							internal.processQuest(details, true)
							_questCache[key] = details
							
							if uiElements.areaQuestUI ~= nil and EnKai.tools.table.isMember (data.areaQuestDomain, details.domain) and details.tag ~= nil and string.find(details.tag, "weekly") == nil then
								uiElements.areaQuestUI:AddQuest(key, details.domain, details.name, details.objective, details.complete, details.level, details.zone)
							end

							--if string.find(details.name, "Das goldene Ticket") ~= nil then dump(details) end
							
							uiElements.questLog:AddQuest(key, details.domain, details.name, details.subName, details.objective, details.complete, details.level, details.zone)
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
		   uiElements.questLog:GetContent():SetVisible(true)
		   _addonInit = true
		end
		uiElements.progressBar:SetVisible(false)
		if uiElements.panel ~= nil then uiElements.panel:UpdateTitle() end
	end
	
	uiElements.progressBar:SetRange(1, #list)
	uiElements.progressBar:SetValue(1)
	if #list > 3 and uiElements.questLog:GetContent():GetVisible() == true then uiElements.progressBar:SetVisible(true) end
	EnKai.coroutines.add ({ func = addCoRoutine, counter = #list, active = true, callBack = callBack })
	_update = true

end

local function _fctQuestChange(list)

	local changeCoRoutine = coroutine.create(
		function ()
			for idx = 1, #list, 1 do
				uiElements.progressBar:SetValue(idx)
				local key = list[idx]
				local flag, details = pcall( oInspectQuestDetail, key)
				if flag then 
					internal.processQuest(details, true)

					if _questCache[key] ~= nil and details.name ~= "" then
						local err, isUpdate = pcall(_fctIsUpdate, _questCache[key], details)

						if err == false then
							if nkQuestTrackerSetup.debug == true then
								print('---------------------------------')
								dump(_questCache[key])
								dump(details)
							end	

							list[key] = nil
						elseif err == true and isUpdate == true then

							if uiElements.areaQuestUI ~= nil and EnKai.tools.table.isMember (data.areaQuestDomain, details.domain) then
								uiElements.areaQuestUI:UpdateQuest(key, details.domain, details.name, details.objective, details.complete, details.level, details.zone)
							end

							uiElements.questLog:UpdateQuest(key, details.domain, details.name, details.subName, details.objective, details.complete, details.level)
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
	if #list > 3 and uiElements.questLog:GetContent():GetVisible() == true then uiElements.progressBar:SetVisible(true) end
	EnKai.coroutines.add ({ func = changeCoRoutine, counter = #list, active = true, callBack = callBack })
	_update = true
	
end

local function _fctQuestRemove(list)
	
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
					
					uiElements.questLog:RemoveQuest(key)
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
	if #list > 3 and uiElements.questLog:GetContent():GetVisible() == true then uiElements.progressBar:SetVisible(true) end
	EnKai.coroutines.add ({ func = removeCoRoutine, counter = #list, active = true, callBack = callBack })
	_update = true

end

---------- addon internal functions ---------

function events.InventoryUpdate(_, items)

	for k, v in pairs(items) do
		if k ~= useItemKey then
			if thisItem ~=  nil and thisItem.category == 'misc quest' then
				uiElements.useUI:Update()
				return
			end
		end
	end
end

function events.unitNotAvaiable(_, units)

	if data.playerUNID == nil then return end
	if units[data.playerUNID] == nil then return end
	
	data.playerAvailable = false
	
	if uiElements.questLog ~= nil then
		--uiElements.questLog:SetTitle(addonInfo.name .. " (PAUSED)")
		uiElements.questLog:SetTitle("Quests (PAUSED)")
	end

end

function events.unitLevel(_, units)

	if data.playerAvailable == false then return end
	if units[data.playerUNID] == nil then return end
	if units[data.playerUNID] == false then return end
	
	data.playerLevel = units[data.playerUNID]
	if nkQuestTrackerSetup.colorByLevel == true then
		internal.clearLog(internal.fillLog)
	end

end

function events.questAccept (_, quests)

	for k, v in pairs (quests) do
		table.insert(data.addQuestList, k)
	end
	
end

function events.questAbandon (_, quests)

	for k, v in pairs (quests) do
		table.insert(data.removeQuestList, k)
	end

end

function events.questChange (_, quests)

	for k, v in pairs (quests) do
		table.insert(updateQuestList, k)
	end

end

function events.questComplete (_, quests)

	for k, v in pairs (quests) do
      table.insert(data.removeQuestList, k)
	end

end

function events.systemUpdate()

	if data.playerAvailable == false then return end
	if nkQuestBase.query.isInit() == false then return end

	if uiElements.useUI == nil and oInspectSystemSecure() == false then
		if EnKai.inventory.getAvailableSlots() ~= false then
			uiElements.useUI = internal.buildUseUI ()
			uiElements.useUI:Update()
		end
	elseif oInspectSystemSecure() == false and data.useUpdate == true then
		uiElements.useUI:Update()
		data.useUpdate = false
	end

	--if oInspectSystemSecure() == false and #_useItemUpdates > 0 then
	--	for k, v in pairs(_useItemUpdates) do
	--		if v.type == 'add' then
	--			uiElements.useUI:AddUseItem(v.key, v.name, v.icon)
	--		else
	--			uiElements.useUI:RemoveUseItem(v.key)
	--		end
	--	end
	--	_useItemUpdates = {}
	--end
	
	if _update == true then return end

	if forceUpdate ~= true then
		if lastQuestUpdate == nil then
			lastQuestUpdate = oInspectTimeReal()
			forceUpdate = true
		else
			local tmpTime = oInspectTimeReal()
			if EnKai.tools.math.round((tmpTime - lastQuestUpdate), 1) > 1 then forceUpdate = true end
		end
	end

	if forceUpdate == true then

		if #data.addQuestList > 0 then
		
			_fctQuestAdd(data.addQuestList)
			data.addQuestList = {}

		elseif #updateQuestList > 0 then

			_fctQuestChange(updateQuestList)
			updateQuestList = {}

		elseif #data.removeQuestList > 0 then

			_fctQuestRemove(data.removeQuestList)
			data.removeQuestList = {}

		end

		lastQuestUpdate = oInspectTimeReal()
		forceUpdate = false

		uiElements.questLog:SetTitle(string.format("%d Quests", uiElements.questLog:GetQuestCount()))
	end
end
