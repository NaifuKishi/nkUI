local addonInfo, privateVars = ...

---------- init namespace ---------
local questTracker   = privateVars.questTracker
local internalFunc   = privateVars.internalFunc
local uiElements     = privateVars.uiElements
local data           = privateVars.data

local inspectItemFind        = Inspect.Item.Find
local inspectItemList        = Inspect.Item.List
local utilityItemSlotQuest   = Utility.Item.Slot.Quest
local utilityItemSlotInventory = Utility.Item.Slot.Inventory
local inspectSystemSecure    = Inspect.System.Secure
local inspectQuestDetail     = Inspect.Quest.Detail
local mathFloor              = math.floor

---------- init local variables ---------
local _useButtonQuestItemID = nil
local _itemCounter = 0
local DEFAULT_TEXTURE_SIZE = 46
local DEFAULT_ICON_SIZE = 25

local context = UI.CreateContext("nkUI.QuestTracker.UseItem")
context:SetStrata('hud')
context:SetSecureMode("restricted")
context:SetLayer(2)

---------- local function block ---------
local function createUseItem(name, parent)
    local path = {
        {xProportional = 0, yProportional = 0},
        {xProportional = 1, yProportional = 0},
        {xProportional = 1, yProportional = 1},
        {xProportional = 0, yProportional = 1},
        {xProportional = 0, yProportional = 0}
    }
    local fill
    local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1}
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

    useItem:EventAttach(Event.UI.Input.Mouse.Cursor.In, function()
        questTracker.showTooltip(useItem, questId, itemId, "personal", nil)
    end, name .. ".texture.UI.Input.Mouse.Cursor.In")

    useItem:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function()
        if uiElements.qtTooltip ~= nil then uiElements.qtTooltip:SetVisible(false) end
    end, name .. ".texture.UI.Input.Mouse.Cursor.Out")

    useItem:EventAttach(Event.UI.Input.Mouse.Right.Click, function()
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
        fill = {
            type = "texture",
            source = "Rift",
            texture = thisTexture,
            transform = Utility.Matrix.Create(DEFAULT_ICON_SIZE / DEFAULT_TEXTURE_SIZE, DEFAULT_ICON_SIZE / DEFAULT_TEXTURE_SIZE, 0, 0, 0)
        }
        useItem:SetShape(path, fill, stroke)
    end

    return useItem
end

---------- addon internalFunc function block ---------
function questTracker.buildUseUI()
    local name = "nkUI.QuestTracker.UseUI"
    local ui = LibEKL.UICreateFrame("nkFrame", name, context)
    ui:SetPoint("TOPRIGHT", uiElements.questTracker, "TOPLEFT", 20, 35)
    ui:SetWidth(30)  -- Breite für eine Spalte
    ui:SetHeight(uiElements.questTracker:GetHeight() - 20)
    ui:SetSecureMode('restricted')
    ui:SetVisible(false)

    local useItems = {}  -- Verwaltet Buttons nach key: {key = button}

    local function calculatePosition(index)
        -- Vertikale Ausrichtung: Jedes Icon wird unter dem vorherigen platziert
        return "TOPRIGHT", ui, "TOPRIGHT", -30, 30 * index
    end

    local function _resize()
        ui:SetHeight(uiElements.questTracker:GetHeight() - 25)
        -- Breite bleibt konstant (eine Spalte)
        ui:SetWidth(30)
    end

    function ui:GetUseItemByKey(key)
        return useItems[key]
    end

    function ui:AddUseItem(key, itemName, icon, questId, itemType)
        if not useItems[key] then
            local point, targetFrame, targetPoint, x, y = calculatePosition(_itemCounter)
            local thisItem = createUseItem(name .. '.useItem.' .. key, ui)
            thisItem:SetPoint(point, targetFrame, targetPoint, x, y)
            thisItem:SetTexture(icon)
            thisItem:SetVisible(true)
            thisItem:SetQuestID(questId)
            thisItem:SetItemID(key)
            thisItem:SetItemName(itemName)
            thisItem:SetItemType(itemType)

            thisItem:EventAttach(Event.UI.Input.Mouse.Left.Down, function()
                if inspectSystemSecure() then return end
            end, thisItem:GetName() .. ".Mouse.Left.Down")

            useItems[key] = thisItem
            _itemCounter = _itemCounter + 1
            _resize()
        end
    end

    function ui:RemoveUseItem(key)
        if useItems[key] then
            useItems[key]:SetVisible(false)
            useItems[key]:EventDetach(Event.UI.Input.Mouse.Left.Down, nil, useItems[key]:GetName() .. ".Mouse.Left.Down")
            useItems[key] = nil
            _itemCounter = _itemCounter - 1
            _resize()
        end
    end

    function ui:Update()
        if inspectSystemSecure() then
            data.useUpdate = true
            return
        end

        Command.System.Watchdog.Quiet()

        local itemList = LibEKL.Inventory.getQuestItems()
        local bagItemList = LibEKL.Inventory.queryByCategory('misc quest')
        local completeList = LibEKL.Tools.Table.Copy(itemList)

        if bagItemList and itemList then
            for key, v in pairs(bagItemList) do
                local found = false
                for slot, details in pairs(itemList) do
                    if details.id == key then found = true end
                end
                if not found then completeList[key] = v end
            end
        end

        local tempList = {}
        for slot, v in pairs(completeList) do
            local questInfo = LibQB.query.questItemByKey(v.type)
            local addItem = true

            if questInfo then
                v.qKey = questInfo.qKey
                local qDetails = inspectQuestDetail(v.qKey)
                if qDetails then addItem = not qDetails.complete end
            end

            if addItem then table.insert(tempList, v) end
        end

        uiElements.useUI:SetBackgroundColor(0, 0, 0, 0)

        -- Add quest items
        for idx = 1, #tempList do
            local thisItem = tempList[idx]
            if not useItems[thisItem.id] and (thisItem.stack == nil or thisItem.stack == 1) then
                ui:AddUseItem(thisItem.id, thisItem.name, thisItem.icon, thisItem.qKey, thisItem.type)
            end
        end

        -- Remove invalid quest items
        for key in pairs(useItems) do
            local found = false
            for idx = 1, #tempList do
                if tempList[idx].id == key then found = true end
            end
            if not found then
                ui:RemoveUseItem(key)
                if _useButtonQuestItemID == key then
                    local button = uiElements.questTracker:getUseItemButton()
                    if button then button:SetVisible(false) end
                end
            end
        end
    end

    function ui:Toggle()
        LibEKL.Events.AddInsecure(function() ui:SetVisible(not ui:GetVisible()) end)
    end

    return ui
end
