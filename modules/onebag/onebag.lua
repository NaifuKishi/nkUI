local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.oneBag = {}

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events
local oneBag        = privateVars.oneBag
local langTexts     = privateVars.langTexts

local InspectTimeReal = Inspect.Time.Real

local stringFormat      = string.format
local stringFind        = string.find
local stringMatch       = string.match

local mathFloor         = math.floor

---------- init variables ---------

local name = "onebag"
local bagItemIcons = {}
local bankItemIcons = {}
local bagCategories = {}
local bankCategories = {}
local movedItem
local cachedBagItems
local cachedBankItems
local lastBagCacheUpdate
local lastBankCacheUpdate

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
        local parentHeight = UIParent:GetHeight()
        data.bagScale = parentHeight / 1440

        LibEKL.Inventory.updateDB()
        uiElements.oneBag = oneBag.createBagUI("nkUI.oneBag", langTexts.oneBag.bagTitle, true)
        uiElements.oneBagBagSlots = oneBag.createBagSlots(uiElements.oneBag)

        uiElements.oneBank = oneBag.createBagUI("nkUI.oneBank", langTexts.oneBag.bankTitle, false)
        uiElements.oneBank:SetVisible(UI.Native.Bank:GetLoaded())

        Command.Event.Attach(Event.Item.Slot, oneBag.itemSlot, "nkUI.OneBag.Item.Slot")
        Command.Event.Attach(Event.Item.Update, oneBag.itemUpdate, "nkUI.OneBag.Item.Update")

        Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].SlotUpdate, function(_, slots)
            if cachedBagItems then
                for k, v in pairs(slots) do
                    if stringMatch(k, "^si%d%d%.%d%d%d$") then
                        if v == false then
                            cachedBagItems[k] = nil -- hier scheint es das problem zu geben bei item use
                        else
                            cachedBagItems[k] = LibEKL.Inventory.GetItemByKey(v)
                        end
                    end
                end
            end

            oneBag.populateBag()

            if UI.Native.Bank:GetLoaded() then
                oneBag.populateBank()
            end
            
        end, "nkUI.OneBag.LibEKL.InventoryManager.SlotUpdate")
    end
    
    oneBag.populateBag()
    oneBag.getBagSlots()
end

function oneBag.populateBag(forceCacheUpdate, searchPattern)

    if forceCacheUpdate == true or cachedBagItems == nil or InspectTimeReal() - lastBagCacheUpdate > 5 then
        cachedBagItems = LibEKL.Inventory.getBagItems()
        lastBagCacheUpdate = InspectTimeReal()
    end

    local items

    -- Filter items based on search pattern if provided
    if searchPattern and searchPattern ~= "" then
        local filteredItems = {}
        for _, item in pairs(cachedBagItems) do
            if string.find(string.lower(item.name), searchPattern, 1, true) then                
                table.insert(filteredItems, item)
            end
        end
        items = filteredItems
    else
        items = cachedBagItems
    end

    oneBag.bagContent(uiElements.oneBag, "nkUI.oneBag", items, bagCategories, bagItemIcons)

end

function oneBag.populateBank(forceCacheUpdate, searchPattern)

    if forceCacheUpdate == true or cachedBankItems == nil or InspectTimeReal() - lastBagCacheUpdate > 5 then
        cachedBankItems = LibEKL.Inventory.getBankItems()
        lastBagCacheUpdate = InspectTimeReal()
    end

    local items

    -- Filter items based on search pattern if provided
    if searchPattern and searchPattern ~= "" then
        local filteredItems = {}
        for _, item in pairs(cachedBankItems) do
            if string.find(string.lower(item.name), searchPattern, 1, true) then
                table.insert(filteredItems, item)
            end
        end
        items = filteredItems
    else
        items = cachedBagItems
    end

    oneBag.bagContent(uiElements.oneBank, "nkUI.oneBank", items, bankCategories, bankItemIcons)

end

function oneBag.bagContent(bagUI, name, cachedItems, uiCategories, itemIcons)

    local counter = 1
    local firstIcon = nil
    local lastIcon = nil
    local categories = {}
    local hasTrash = false
    local trashItems = {}

    for k, v in pairs(cachedItems) do
        local realCategory = oneBag.getRealCategory(v.category, v.rarity)

        if realCategory == langTexts.itemCategories.trash then
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
        table.insert(sortedCategories, langTexts.itemCategories.trash)
        categories[langTexts.itemCategories.trash] = {
            original = trashItems,
            sorted = sortItems (trashItems)
        }
    end

    for k, v in pairs(uiCategories) do
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
        local thisCategory = uiCategories[categoryLabel]

        if thisCategory == nil then
            thisCategory = oneBag.createItemCategory(name .. ".Category." .. categoryLabel, bagUI:GetContent())
            thisCategory:SetText(categoryLabel)
            uiCategories[categoryLabel] = thisCategory
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
                thisIcon = oneBag.createItemIcon(name .. ".item." .. slot, thisCategory)                
                itemIcons[slot] = thisIcon
            end            

            thisIcon:SetSlot(slot)            
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
                    thisIcon:SetPoint("TOPLEFT", firstIcon, "TOPLEFT", 0, 20 * data.bagScale) -- first row
                else
                    thisIcon:SetPoint("TOPLEFT", firstIcon, "BOTTOMLEFT", 0, 2) -- nth row
                end
                firstIcon = thisIcon
            else
                thisIcon:SetPoint("TOPLEFT", lastIcon, "TOPRIGHT", 5 * data.bagScale, 0) -- not first icon
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

        thisCategory:SetHeight(((20* data.bagScale) + (rows * (40* data.bagScale)) + ((rows-1) * (5* data.bagScale))))
        thisCategory:SetWidth(((cols * (40* data.bagScale)) + ((cols-1) * (5* data.bagScale))))

        if firstCategory then
            firstCategory = false
            thisCategory:SetPoint("TOPLEFT", bagUI:GetContent(), "TOPLEFT", 10* data.bagScale, 5* data.bagScale)
            iconsPerLine = iconsPerLine + cols
            startCategory = thisCategory
            currentYOffset = (thisCategory:GetHeight() + (10 * data.bagScale))  -- Increased vertical spacing
        else
            -- Check if we need to start a new line
            if iconsPerLine + cols >= 15 then
                thisCategory:SetPoint("TOPLEFT", bagUI:GetContent(), "TOPLEFT", 10* data.bagScale, currentYOffset)
                currentYOffset = currentYOffset + ((thisCategory:GetHeight() + (10* data.bagScale)))  -- Increased vertical spacing
                iconsPerLine = cols
            else
                thisCategory:SetPoint("TOPLEFT", lastCategory, "TOPRIGHT", 50* data.bagScale, 0)
                iconsPerLine = iconsPerLine + cols + 1
            end
        end

        lastCategory = thisCategory
    end    

    if lastCategory then
        local bottom = lastCategory:GetBottom()
        local top = bagUI:GetTop()
        bagUI:SetHeight(bottom - top + 10)        
    end

end

function oneBag.itemSlot (_, slots)

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "itemSlot", "", slots) end

    if not uiElements.oneBag or not uiElements.oneBag:GetVisible() then return end

    local doBagInventoryUpdate = false
    local doBankInventoryUpdate = false
    local doBagSlotsUpdate = false

    for thisSlot, state in pairs (slots) do
        
        if stringFind(thisSlot, "sibg.") then
            doBagSlotsUpdate = true
        elseif stringFind(thisSlot, "si") then
            doBagInventoryUpdate = true
        elseif stringFind(thisSlot, "sb") then
            doBankInventoryUpdate = true
        elseif stringFind(thisSlot, "sv") then
            doBankInventoryUpdate = true
        end

        if doBagSlotsUpdate and doBagInventoryUpdate and doBankInventoryUpdate then break end
    end

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "itemSlot", doBagInventoryUpdate) end

    if doBagInventoryUpdate then 
        LibEKL.Inventory.updateDB()
        oneBag.populateBag(true) 
    end

    if doBankInventoryUpdate then 
        if not doBagInventoryUpdate then LibEKL.Inventory.updateDB() end
        oneBag.populateBank(true) 
    end

    if doBagSlotsUpdate then oneBag.getBagSlots() end

end

function oneBag.itemUpdate (_, slots)

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "itemUpdate", "", slots) end

    if not uiElements.oneBag or not uiElements.oneBag:GetVisible() then return end
    
    local doBagInventoryUpdate = false
    local doBagSlotsUpdate = false

    for thisSlot, state in pairs (slots) do
        
        if stringFind(thisSlot, "sibg.") then
            doBagSlotsUpdate = true
        elseif stringFind(thisSlot, "si") then
            doBagInventoryUpdate = true
        end

        if doBagSlotsUpdate and doBagInventoryUpdate then break end
    end

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "itemSlot", doBagInventoryUpdate) end

    if doBagInventoryUpdate then 
        LibEKL.Inventory.updateDB()
        oneBag.populateBag(true) 
    end

    if doBagSlotsUpdate then oneBag.getBagSlots() end

end