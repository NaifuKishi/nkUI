local addonInfo, privateVars = ...

---------- init namespace ---------

local internal		= privateVars.internal
local uiElements	= privateVars.uiElements
local data			= privateVars.data

local oInspectItemFind			= Inspect.Item.Find
local oInspectItemList			= Inspect.Item.List
local oUtilityItemSlotQuest		= Utility.Item.Slot.Quest
local oUtilityItemSlotInventory	= Utility.Item.Slot.Inventory
local oInspectSystemSecure		= Inspect.System.Secure

---------- init local variables ---------

local _useButtonQuestItemID = nil
local _itemCounter = 0

---------- init variables ---------

---------- local function block ---------

local function _fctSetUseButton (useItem)

	-- ***** return quest item to quest inventory *****

	if _useButtonQuestItemID ~= nil and _useButtonQuestItemID ~= useItem:GetItemID() then
		
		local itemSlot = oInspectItemFind(_useButtonQuestItemID)

		if itemSlot ~= nil then
			local slots = oInspectItemList(oUtilityItemSlotQuest())

			for slot, details in pairs (slots) do
				if EnKai.strings.startsWith(slot, "sqst.") == true then
					if details == false then
						pcall (Command.Item.Move, itemSlot, slot)
						break
					end 
				end
			end
		end
	end

	-- ***** move quest item to inventory *****

	if _useButtonQuestItemID == nil or _useButtonQuestItemID ~= useItem:GetItemID() then

		local availSlots = EnKai.inventory.getAvailableSlots()
		
		if #availSlots == 0 then
			EnKai.tools.error.display (addonInfo.toc.Identifier, string.format("not enough space in bags to move quest item %s", useItem:GetName()), 3)
			return
		end 

		--local slots= oInspectItemList(oUtilityItemSlotInventory())
		local questSlot = EnKai.inventory.getQuestItemSlot (useItem:GetItemType())

		pcall (Command.Item.Move, questSlot, availSlots[1])
	end

	-- ***** move set quest item button *****

	_useButtonQuestItemID = useItem:GetItemID()

	local button = uiElements.questLog:getUseItemButton()
	local source, texture = useItem:GetTexture()

	button:SetTexture(source, texture)
	button:EventMacroSet(Event.UI.Input.Mouse.Left.Click, string.format("use %s", useItem:GetItemName()))

	button:SetVisible(true)

end

local function _fctUseItem(name, parent)

	local useItem = UI.CreateFrame("Texture", name, parent)
	useItem:SetWidth(25)
	useItem:SetHeight(25)
	useItem:SetSecureMode("restricted")
	useItem:SetVisible(false)
	
	local questId = nil
	local itemId = nil
	local itemName = nil
	local itemType = nil
	
	useItem:EventAttach( Event.UI.Input.Mouse.Cursor.In, function ()
		internal.showTooltip (useItem, questId, itemId, "personal", nil)
	end, name)
	
	useItem:EventAttach( Event.UI.Input.Mouse.Cursor.Out, function ()
		if uiElements.tooltip ~= nil then uiElements.tooltip:SetVisible(false) end
	end, name)
	
	function useItem:SetQuestID(newQuestId) questId = newQuestId end
	function useItem:GetQuestID() return questId end
	function useItem:SetItemID(newItemId) itemId = newItemId end
	function useItem:GetItemID() return itemId end
	function useItem:SetItemName(newItemName) itemName = newItemName end
	function useItem:GetItemName() return itemName end
	function useItem:SetItemType(newItemType) itemType = newItemType end
	function useItem:GetItemType() return itemType end
	
	return useItem

end
---------- addon internal function block ---------

function internal.buildUseUI ()

	local name = "nkQuestTracker.UseUI"

	local ui = EnKai.uiCreateFrame("nkFrame", name, uiElements.secureContext)
	ui:SetPoint("TOPLEFT", uiElements.questLog, "TOPRIGHT", 5, 0)
	ui:SetWidth(50)
	ui:SetHeight(300)
	ui:SetSecureMode('restricted')
	ui:SetVisible(true)

	local useItems = {}
	local useState = {}

	local from, to, object, x, y = "TOPLEFT", "TOPLEFT", ui, 0, 0
	local lastUseItem = nil

	for idx1 = 1, 4, 1 do
		if idx1 ~= 1 then from, to, object, x, y = "TOPLEFT", "TOPRIGHT", lastUseItem, 5, 0 end
		
		for idx = 1, 10, 1 do			
			local thisItem = _fctUseItem(name .. '.useItem.' .. idx, ui)
			thisItem:SetPoint(from, object, to, x, y)
			to, object, x, y = "BOTTOMLEFT", thisItem, 0, 5

			if idx == 1 then lastUseItem = thisItem end
			
			table.insert(useItems, thisItem)
			table.insert(useState, false)
		end
	end

	function ui:toggle()
		if ui:GetVisible() == true then
			ui:SetVisible(false)
		else
			ui:SetVisible(true)
		end
	end

	local function _resize() 
		local cols = math.floor(_itemCounter / 10) + 1
		local rows = 10
		if _itemCounter < 10 then rows = _itemCounter end

		ui:SetHeight(25 * rows + 5 * (rows - 1))
		ui:SetWidth(25 * cols + 5 * (cols - 1))
	end

	function ui:GetUseItemByKey(key)
		for idx = 1, #useState, 1 do
			if useState[idx] == key then return useItems[idx] end
		end

		return nil
	end

	function ui:GetUseState()
		return useState
	end

	function ui:AddUseItem(key, name, icon, questId, itemType)

		for idx = 1, #useState, 1 do
			if useState[idx] == false then
				useState[idx] = key

				useItems[idx]:SetTextureAsync("Rift", icon)
				--useItems[idx]:EventMacroSet(Event.UI.Input.Mouse.Left.Click, string.format("use %s", name))
				useItems[idx]:SetVisible(true)
				useItems[idx]:SetQuestID(questId)
				useItems[idx]:SetItemID(key)
				useItems[idx]:SetItemName(name)
				useItems[idx]:SetItemType(itemType)
				
				useItems[idx]:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
					if oInspectSystemSecure() == true then return end
					_fctSetUseButton(useItems[idx])
					--ui:SetVisible(false)
				end, useItems[idx]:GetName() .. ".Mouse.Left.Down")

				_itemCounter = _itemCounter + 1
				_resize()
				return
			end
		end
	end
	
	function ui:RemoveUseItem(key)

		local hasItems = false
		
		for idx = 1, #useState, 1 do			
			if useState[idx] ~= false then
				if useState[idx] == key then
					useState[idx] = false
					useItems[idx]:SetVisible(false)
					useItems[idx]:EventDetach(Event.UI.Input.Mouse.Left.Down, nil, useItems[idx]:GetName() .. ".Mouse.Left.Down")
					
					_itemCounter = _itemCounter - 1
					_resize()
					return
				else
					hasItems = true
					_itemCounter = 0
					_resize()
				end
			end
		end
		
	end
	
	function ui:Update()

		if oInspectSystemSecure() == true then
			data.useUpdate = true 
			return
		end
		
		Command.System.Watchdog.Quiet()
	
		-- go through quest item space, identify usable quest items and move them to the bag 
	
		local itemList = EnKai.inventory.getQuestItems()		
		local bagItemList = EnKai.inventory.queryByCategory ('misc quest')

		local completeList = EnKai.tools.table.copy (itemList)
		
		if bagItemList and itemList then
			for key, v in pairs (bagItemList) do
				local found = false

				for slot, details in pairs(itemList) do
					if details.id == key then
						found = true
					end
				end
				
				if found == false then
					completeList.key = v
				end
			end
		end

		local tempList = {}
		
		for k, v in pairs (completeList) do
			local questInfo = nkQuestBase.query.questItemByKey (v.type)
			if questInfo ~= nil then v.qKey = questInfo.qKey  end
			table.insert(tempList, v)
		end

		if #tempList == 0 then
       		uiElements.useUI:SetBackgroundColor(0, 0, 0, 0)
		else
		   uiElements.useUI:SetBackgroundColor(0, 0, 0, nkQuestTrackerSetup.bgAlpha)
		end

		-- ***** add quest items *****
				
		for idx = 1, #tempList, 1 do
			local thisItem = tempList[idx]
			local useItem = ui:GetUseItemByKey(thisItem.id)

			if useItem == nil then
				ui:AddUseItem(thisItem.id, thisItem.name, thisItem.icon, thisItem.qKey, thisItem.type)
			end
		end

		--- ***** remove invalid quest items *****

		local useState = ui:GetUseState()
		for idx = 1, #useState, 1 do
			local key  = useState[idx]
			if key ~= false then
				local found = false
				for idx2 = 1, #tempList, 1 do
					if tempList[idx2].id == key then found = true end
				end
				if found == false then 
					ui:RemoveUseItem(key)
					if _useButtonQuestItemID == key then 
						local button = uiElements.questLog:getUseItemButton()
						if button ~= nil then button:SetVisible(false) end
					end
				end
			end	
		end

	end
	
	return ui

end
