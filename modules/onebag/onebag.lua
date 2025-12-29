local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.oneBag = {}

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events
local oneBag        = privateVars.oneBag

local InspectTimeReal = Inspect.Time.Real

local stringFormat      = string.format
local stringFind        = string.find
local stringMatch       = string.match

local mathFloor         = math.floor

---------- init variables ---------

local name = "onebag"
local itemIcons = {}
local bagCategories = {}
local movedItem
local cachedItems
local lastCacheUpdate

oneBag.dragItem = {
    draggedItem = nil,
    draggedSlot = nil
}

---------- local functions ---------

local function sortItems (items)

    local sortedItems = {}
    for slot, itemDetails in pairs(items) do
        table.insert(sortedItems, {slot = slot, details = itemDetails})
    end

    table.sort(sortedItems, function(a, b)
        return a.details.name < b.details.name
    end)

    return sortedItems

end

-- Initializes the onebag and loads all modules
function internalFunc.oneBagInit()

    if uiElements.oneBag then
        if uiElements.oneBag:GetVisible() then
            uiElements.oneBag:SetVisible(false)
            oneBag.hideItemTooltip()
        else
            uiElements.oneBag:SetVisible(true)
        end
    else
        LibEKL.Inventory.updateDB()
        uiElements.oneBag = oneBag.createBagUI()
        uiElements.oneBagBagSlots = oneBag.createBagSlots()

        Command.Event.Attach(Event.Item.Slot, oneBag.itemSlot, "nkUI.OneBag.Item.Slot")
        Command.Event.Attach(Event.Item.Update, oneBag.itemUpdate, "nkUI.OneBag.Item.Update")

        Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].SlotUpdate, function(_, slots)
            if cachedItems then
                for k, v in pairs(slots) do
                    if stringMatch(k, "^si%d%d%.%d%d%d$") then
                        if v == false then
                            cachedItems[k] = nil -- hier scheint es das problem zu geben bei item use
                        else
                            cachedItems[k] = LibEKL.Inventory.GetItemByKey(v)
                        end
                    end
                end
            end
            oneBag.populateBag()
        end, "nkUI.OneBag.LibEKL.InventoryManager.SlotUpdate")

        --[[Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].Update, function(_, items)
            -- Handle inventory updates
        end, "nkUI.OneBag.LibEKL.InventoryManager.Update")]]
    end

    oneBag.populateBag()
    oneBag.getBagSlots()
end

function oneBag.populateBag(forceCacheUpdate)

    local counter = 1
    local firstIcon = nil
    local lastIcon = nil

    if forceCacheUpdate == true or cachedItems == nil or InspectTimeReal() - lastCacheUpdate > 5 then
        cachedItems = LibEKL.Inventory.getBagItems()
        lastCacheUpdate = InspectTimeReal()
    end

    --dump (cachedItems)

    local categories = {}
    local hasTrash = false
    local trashItems = {}

    for k, v in pairs(cachedItems) do
        local realCategory = oneBag.getRealCategory(v.category, v.rarity)

        if realCategory == "Trash" then
            hasTrash = true
            trashItems[k] = v
        else
            if categories[realCategory] == nil then
                categories[realCategory] = {}
            end
            
            categories[realCategory][k] = v
        end
    end

    -- Sort items within each category by item name
    for category, items in pairs(categories) do
        categories[category] = {
            original = items,
            sorted = sortItems (items)
        }
    end

    local sortedCategories = LibEKL.Tools.Table.GetSortedKeys (categories)

    if hasTrash then
        table.insert(sortedCategories, "Trash")
        categories["Trash"] = {
            original = trashItems,
            sorted = sortItems (trashItems)
        }
    end

    for k, v in pairs(bagCategories) do
        if LibEKL.Tools.Table.IsMember(sortedCategories, k) == false then
            v:SetVisible(false)

            for slot, icon in pairs (v.items) do
                icon:SetVisible(false)
            end
        end
    end

    local iconsPerLine = 0
    local firstCategory = true
    local lastCategory
    local startCategory
    local currentYOffset = 0  -- Track vertical position for new categories

    for k, v in pairs(itemIcons) do
        if cachedItems[k] == nil then
            v:Clear()
        end
    end

    for idx = 1, #sortedCategories, 1 do

    --    for category, content in pairs(categories) do

        local categoryLabel = sortedCategories[idx]

        local content = categories[categoryLabel].sorted        
        local thisCategory = bagCategories[categoryLabel]

        if thisCategory == nil then
            thisCategory = oneBag.createItemCategory("nkUI.onebagCategory." .. categoryLabel, uiElements.oneBag:GetContent())
            thisCategory:SetText(categoryLabel)
            bagCategories[categoryLabel] = thisCategory
        else
            for slot, icon in pairs (thisCategory.items) do
                icon:SetVisible(false)
            end            
        end        

        thisCategory:SetVisible(true)

        counter = 1
        local contentCounter = 0
        firstIcon = thisCategory
        local cols, rows = 0, 1
        thisCategory.items = {}

        for idx =1, #content, 1 do
            local slot = content[idx].slot
            local itemDetails = content[idx].details

            local thisIcon = itemIcons[slot]

            if thisIcon == nil then
                if nkDebug then nkDebug.logEntry (addonInfo.identifier, stringFormat("One Bag create slot icon %s", slot)) end
                thisIcon = oneBag.createItemIcon("nkUI.onebagItem." .. slot, thisCategory)
                thisIcon:SetSlot(slot)
                itemIcons[slot] = thisIcon
            end            
            
            thisIcon:SetParent(thisCategory)
            thisIcon:SetIcon("Rift", itemDetails.icon)
            thisIcon:SetRarity(itemDetails.rarity)
            thisIcon:SetQuantity(stringFormat("%d", itemDetails.stack))
            thisIcon:SetBound(itemDetails.bind, itemDetails.bound)
            thisIcon:SetItem(itemDetails.id)
            thisIcon:SetVisible(true)

            thisCategory.items[slot] = thisIcon

            -- position icons within category

            if counter == 1 then -- first icon on row
                if rows == 1 then
                    thisIcon:SetPoint("TOPLEFT", firstIcon, "TOPLEFT", 0, 20 * data.uiScale) -- first row
                else
                    thisIcon:SetPoint("TOPLEFT", firstIcon, "BOTTOMLEFT", 0, 2) -- nth row
                end
                firstIcon = thisIcon
            else
                thisIcon:SetPoint("TOPLEFT", lastIcon, "TOPRIGHT", 5 * data.uiScale, 0) -- not first icon
            end

            -- increase col count if still one line otherwise max icons are reached

            if rows == 1 then cols = cols + 1 end

            -- Check max icons per line is reached

            if counter == 15 then
                counter = 0
                rows = rows + 1
            end

            lastIcon = thisIcon
            counter = counter + 1
        end

        if rows > 1 and counter == 1 then rows = rows - 1 end -- preventing an extra line if an item line is exactly 15 items

        local checkTitleWidth = mathFloor(thisCategory:GetTextWidth() / 45)
        if checkTitleWidth > cols then cols = checkTitleWidth end

        thisCategory:SetHeight(((20* data.uiScale) + (rows * (40* data.uiScale)) + ((rows-1) * (5* data.uiScale))))
        thisCategory:SetWidth(((cols * (40* data.uiScale)) + ((cols-1) * (5* data.uiScale))))

        if firstCategory then
            firstCategory = false
            thisCategory:SetPoint("TOPLEFT", uiElements.oneBag:GetContent(), "TOPLEFT", 10* data.uiScale, 5* data.uiScale)
            iconsPerLine = iconsPerLine + cols
            startCategory = thisCategory
            currentYOffset = (thisCategory:GetHeight() + (10 * data.uiScale))  -- Increased vertical spacing
        else
            -- Check if we need to start a new line
            if iconsPerLine + cols >= 15 then
                thisCategory:SetPoint("TOPLEFT", uiElements.oneBag:GetContent(), "TOPLEFT", 10* data.uiScale, currentYOffset)
                currentYOffset = currentYOffset + ((thisCategory:GetHeight() + (10* data.uiScale)))  -- Increased vertical spacing
                iconsPerLine = cols
            else
                thisCategory:SetPoint("TOPLEFT", lastCategory, "TOPRIGHT", 50* data.uiScale, 0)
                iconsPerLine = iconsPerLine + cols + 1
            end
        end

        lastCategory = thisCategory
    end    

    if lastCategory then
        local bottom = lastCategory:GetBottom()
        local top = uiElements.oneBag:GetTop()
        uiElements.oneBag:SetHeight(bottom - top + 10)        
    end

end

function oneBag.itemSlot (_, slots)

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "itemSlot", "", slots) end

    if not uiElements.oneBag or not uiElements.oneBag:GetVisible() then return end

    local doInventoryUpdate = false
    local doBatSlotsUpdate = false

    for thisSlot, state in pairs (slots) do
        
        if stringFind(thisSlot, "sibg.") then
            doBatSlotsUpdate = true
        elseif stringFind(thisSlot, "si") then
            doInventoryUpdate = true
        end

        if doBatSlotsUpdate and doInventoryUpdate then break end
    end

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "itemSlot", doInventoryUpdate) end

    if doInventoryUpdate then 
        LibEKL.Inventory.updateDB()
        oneBag.populateBag(true) 
    end

    if doBatSlotsUpdate then  oneBag.getBagSlots() end

end

function oneBag.itemUpdate (_, slots)

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "itemUpdate", "", slots) end

    if not uiElements.oneBag or not uiElements.oneBag:GetVisible() then return end
    
    local doInventoryUpdate = false
    local doBatSlotsUpdate = false

    for thisSlot, state in pairs (slots) do
        
        if stringFind(thisSlot, "sibg.") then
            doBatSlotsUpdate = true
        elseif stringFind(thisSlot, "si") then
            doInventoryUpdate = true
        end

        if doBatSlotsUpdate and doInventoryUpdate then break end
    end

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "itemSlot", doInventoryUpdate) end

    if doInventoryUpdate then 
        LibEKL.Inventory.updateDB()
        oneBag.populateBag(true) 
    end

    if doBatSlotsUpdate then oneBag.getBagSlots() end

end