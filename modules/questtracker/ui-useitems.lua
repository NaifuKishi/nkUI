local addonInfo, privateVars = ...

---------- init namespace ---------

local questTracker	= privateVars.questTracker
local internalFunc	= privateVars.internalFunc
local uiElements	= privateVars.uiElements
local data			= privateVars.data

local inspectItemFind			= Inspect.Item.Find
local inspectItemList			= Inspect.Item.List
local utilityItemSlotQuest		= Utility.Item.Slot.Quest
local utilityItemSlotInventory	= Utility.Item.Slot.Inventory
local inspectSystemSecure		= Inspect.System.Secure
local inspectQuestDetail		= Inspect.Quest.Detail

local mathFloor					= math.floor

---------- init local variables ---------

local _useButtonQuestItemID = nil
local _itemCounter = 0
local DEFAULT_TEXTURE_SIZE = 46
local DEFAULT_ICON_SIZE = 25

local context = UI.CreateContext("nkUI.QuestTracker.UseItem")
context:SetStrata('hud')
context:SetSecureMode("restricted")
context:SetLayer(2)

---------- init variables ---------

---------- local function block ---------

local function useItem(name, parent)

	local path = {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 0}, {xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 1}, {xProportional = 0, yProportional = 0}}
	local fill
	local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1 }
	local thisTexture

	local useItem = LibEKL.UICreateFrame('nkCanvas', name, parent)
	useItem:SetWidth(DEFAULT_ICON_SIZE)
	useItem:SetHeight(DEFAULT_ICON_SIZE)
	useItem:SetSecureMode("restricted")	
	useItem:SetVisible(false)

	local questId = nil
	local itemId = nil
	local itemName = nil
	local itemType = nil
	
	useItem:EventAttach( Event.UI.Input.Mouse.Cursor.In, function ()
		questTracker.showTooltip (useItem, questId, itemId, "personal", nil)
	end, name .. ".texture.UI.Input.Mouse.Cursor.In")
	
	useItem:EventAttach( Event.UI.Input.Mouse.Cursor.Out, function ()
		if uiElements.qtTooltip ~= nil then uiElements.qtTooltip:SetVisible(false) end
	end, name .. ".texture.UI.Input.Mouse.Cursor.Out")

	useItem:EventAttach( Event.UI.Input.Mouse.Right.Click, function ()
		Command.Item.Standard.Right(itemId)
	end, name .. ".texture.UI.Input.Mouse.Right.Click")
	
	function useItem:SetQuestID(newQuestId) questId = newQuestId end
	function useItem:GetQuestID() return questId end
	function useItem:SetItemID(newItemId) itemId = newItemId end
	function useItem:GetItemID() return itemId end
	function useItem:SetItemName(newItemName) itemName = newItemName end
	function useItem:GetItemName() return itemName end
	function useItem:SetItemType(newItemType) itemType = newItemType end
	function useItem:GetItemType() return itemType end

	function useItem:SetTexture(texturePath) 
		thisTexture = texturePath
		local width = useItem:GetWidth()
		fill = { type = "texture", source = "Rift", texture = thisTexture, transform = Utility.Matrix.Create(DEFAULT_ICON_SIZE / DEFAULT_TEXTURE_SIZE, DEFAULT_ICON_SIZE / DEFAULT_TEXTURE_SIZE, 0, 0, 0) }		
        useItem:SetShape(path, fill, stroke)
	end

	return useItem

end
---------- addon internalFunc function block ---------

function questTracker.buildUseUI ()

	local name = "nkUI.QuestTracker.UseUI"

	local ui = LibEKL.UICreateFrame("nkFrame", name, context)
	ui:SetPoint("TOPRIGHT", uiElements.questTracker, "TOPLEFT", 20, 35)
	ui:SetWidth(50)
	ui:SetHeight(uiElements.questTracker:GetHeight()-20)
	ui:SetSecureMode('restricted')
	ui:SetVisible(false)

	local useItems = {}
	local useState = {}

	local from, to, object, x, y = "TOPRIGHT", "TOPLEFT", ui, 0, 0
	local lastUseItem = nil

	local maxIcons = mathFloor((uiElements.questTracker:GetHeight()-20) / 30)

	for idx1 = 1, 2, 1 do
		if idx1 ~= 1 then from, to, object, x, y = "TOPRIGHT", "TOPLEFT", lastUseItem, -5, 0 end
		
		for idx = 1, maxIcons, 1 do			
			local thisItem = useItem(name .. '.useItem.' .. idx1 .. "." .. idx, ui)
			thisItem:SetPoint(from, object, to, x, y)
			to, object, x, y = "BOTTOMRIGHT", thisItem, 0, 5

			if idx == 1 then lastUseItem = thisItem end
			
			table.insert(useItems, thisItem)
			table.insert(useState, false)
		end
	end

	local function _resize() 
		ui:SetHeight(uiElements.questTracker:GetHeight()-25)
		
		local maxIcons = mathFloor((uiElements.questTracker:GetHeight()-25) / 30)
		if _itemCounter <= maxIcons then
			cols = 1
		else
			cols = mathFloor(_itemCounter / maxIcons) + 1
		end

		ui:SetWidth(30 * cols)
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

				useItems[idx]:SetTexture(icon)
				useItems[idx]:SetVisible(true)
				useItems[idx]:SetQuestID(questId)
				useItems[idx]:SetItemID(key)
				useItems[idx]:SetItemName(name)
				useItems[idx]:SetItemType(itemType)
				
				useItems[idx]:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
					if inspectSystemSecure() == true then return end
					--setUseButton(useItems[idx])
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
					hasItems = useItems[idx]:SetVisible(true)
					_itemCounter = 0
					_resize()
				end
			end
		end
		
	end
	
	function ui:Update()

		if inspectSystemSecure() == true then
			data.useUpdate = true 
			return
		end
		
		Command.System.Watchdog.Quiet()
	
		-- go through quest item space, identify usable quest items and move them to the bag 
	
		local itemList = LibEKL.Inventory.getQuestItems()

		if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_questTracker.buildUseUI", "quest items", itemList) end
	
		local bagItemList = LibEKL.Inventory.queryByCategory ('misc quest')
		local completeList = LibEKL.Tools.Table.Copy (itemList)

		if bagItemList and itemList then			

			for key, v in pairs (bagItemList) do
				local found = false

				for slot, details in pairs(itemList) do
					if details.id == key then found = true end
				end
				
				if found == false then completeList.key = v end
			end
		end

		local tempList = {}
		
		for slot, v in pairs (completeList) do
			local questInfo = LibQB.query.questItemByKey (v.type)			

			local addItem = true

			if questInfo ~= nil then 
				v.qKey = questInfo.qKey 
				local qDetails = inspectQuestDetail(v.qKey)				
				if qDetails then 
					addItem = not qDetails.complete 
				end
			end

			if addItem then table.insert(tempList, v) end
		end

   		uiElements.useUI:SetBackgroundColor(0, 0, 0, 0)

		-- ***** add quest items *****
				
		for idx = 1, #tempList, 1 do
			local thisItem = tempList[idx]
			local useItem = ui:GetUseItemByKey(thisItem.id)

			--
			--dump (thisItem.stack)

			if useItem == nil and (thisItem.stack == nil or thisItem.stack == 1) then
				ui:AddUseItem(thisItem.id, thisItem.name, thisItem.icon, thisItem.qKey, thisItem.type)
			end
		end

		--- ***** remove invalid quest items *****

		local useState = ui:GetUseState()
		for idx = 1, #useState, 1 do
			local key = useState[idx]
			if key ~= false then
				local found = false
				for idx2 = 1, #tempList, 1 do
					if tempList[idx2].id == key then found = true end
				end
				if found == false then 
					ui:RemoveUseItem(key)
					if _useButtonQuestItemID == key then 
						local button = uiElements.questTracker:getUseItemButton()
						if button ~= nil then button:SetVisible(false) end
					end
				end
			end	
		end

	end

	function ui:Toggle()
		LibEKL.Events.AddInsecure(function () ui:SetVisible(not ui:GetVisible()) end)
	end	
	
	return ui

end
