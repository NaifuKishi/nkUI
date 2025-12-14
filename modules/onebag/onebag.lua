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

---------- init variables ---------

local name = "onebag"
local itemIcons = {}
local categoryLabels = {}
local draggedItem, draggedSlot
local movedItem
local cachedItems
local lastCacheUpdate

---------- local functions ---------

-- Initializes the onebag and loads all modules
function internalFunc.oneBagInit()

    if uiElements.oneBag then
        if uiElements.oneBag:GetVisible() then
            uiElements.oneBag:SetVisible(false)
        else
            uiElements.oneBag:SetVisible(true)
        end
    else
        EnKai.inventory.updateDB()
        uiElements.oneBag = oneBag.createBagUI()
        uiElements.oneBagBagSlots = oneBag.createBagSlots()

        Command.Event.Attach(Event.Item.Slot, oneBag.itemSlot, "nkUI.OneBag.Item.Slot")
        Command.Event.Attach(Event.Item.Update, oneBag.itemUpdate, "nkUI.OneBag.Item.Update")

        Command.Event.Attach(EnKai.events["EnKai.InventoryManager"].SlotUpdate, function(_, slots)
            if cachedItems then
                for k, v in pairs(slots) do
                    if stringMatch(k, "^si%d%d%.%d%d%d$") then
                        if v == false then
                            cachedItems[k] = nil
                        else
                            cachedItems[k] = EnKai.inventory.GetItemByKey(v)
                        end
                    end
                end
            end
            oneBag.populateBag()
        end, "nkUI.OneBag.EnKai.InventoryManager.SlotUpdate")

        --[[Command.Event.Attach(EnKai.events["EnKai.InventoryManager"].Update, function(_, items)
            -- Handle inventory updates
        end, "nkUI.OneBag.EnKai.InventoryManager.Update")]]
    end

    oneBag.populateBag()
    oneBag.getBagSlots()
end

function oneBag.populateBag(forceCacheUpdate)

    local counter = 1
    local firstIcon = nil
    local lastIcon = nil

    if forceCacheUpdate == true or cachedItems == nil or InspectTimeReal() - lastCacheUpdate > 5 then
        cachedItems = EnKai.inventory.getBagItems()
        lastCacheUpdate = InspectTimeReal()
    end

    local categories = {}

    for k, v in pairs(cachedItems) do
        local realCategory = oneBag.getRealCategory(v.category, v.rarity)

        if categories[realCategory] == nil then
            categories[realCategory] = {}
        end
        
        categories[realCategory][k] = v
    end

    local sortedCategories = EnKai.tools.table.getSortedKeys (categories)

    for k, v in pairs(categoryLabels) do
        if EnKai.tools.table.isMember(sortedCategories, k) == false then
            v:SetVisible(false)
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

        local category = sortedCategories[idx]
        local content = categories[category]
        local thisCategory = categoryLabels[category]

        if thisCategory == nil then
            thisCategory = oneBag.createItemCategory("nkUI.onebagCategory." .. category, uiElements.oneBag:GetContent())
            thisCategory:SetText(category)
            categoryLabels[category] = thisCategory
        end

        thisCategory:SetVisible(true)

        counter = 1
        local contentCounter = 0
        firstIcon = thisCategory
        local cols, rows = 0, 1

        for slot, itemDetails in pairs(content) do
            local thisIcon = itemIcons[slot]

            if itemIcons[slot] == nil then
                thisIcon = oneBag.createItemIcon("nkUI.onebagItem." .. slot, thisCategory)
                itemIcons[slot] = thisIcon
            end

            itemIcons[slot]:SetSlot(slot)
            itemIcons[slot]:SetIcon("Rift", itemDetails.icon)
            itemIcons[slot]:SetRarity(itemDetails.rarity)
            itemIcons[slot]:SetQuantity(stringFormat("%d", itemDetails.stack))
            itemIcons[slot]:SetBound(itemDetails.bind, itemDetails.bound)
            itemIcons[slot]:SetItem(itemDetails.id)
            itemIcons[slot]:SetVisible(true)

            if counter == 1 then
                if rows == 1 then
                    itemIcons[slot]:SetPoint("TOPLEFT", firstIcon, "TOPLEFT", 0, 20* data.uiScale)
                else
                    itemIcons[slot]:SetPoint("TOPLEFT", firstIcon, "BOTTOMLEFT", 0, 2)
                end
                firstIcon = thisIcon
            else
                itemIcons[slot]:SetPoint("TOPLEFT", lastIcon, "TOPRIGHT", 5* data.uiScale, 0)
            end

            if rows == 1 then cols = cols + 1 end

            if counter == 15 then
                counter = 0
                rows = rows + 1
            end

            lastIcon = thisIcon
            counter = counter + 1
        end

        if rows > 1 and counter == 1 then rows = rows - 1 end -- preventing an extra line if a item line is exactly 15 items

        local checkTitleWidth = math.floor(thisCategory:GetTextWidth() / 42) + 1
        if checkTitleWidth > cols then cols = checkTitleWidth end

        thisCategory:SetHeight(((20* data.uiScale) + (rows * (40* data.uiScale)) + ((rows-1) * (5* data.uiScale))))
        thisCategory:SetWidth(((cols * (40* data.uiScale)) + ((cols-1) * (5* data.uiScale))))

        if firstCategory then
            firstCategory = false
            thisCategory:SetPoint("TOPLEFT", uiElements.oneBag:GetContent(), "TOPLEFT", 5* data.uiScale, 5* data.uiScale)
            iconsPerLine = iconsPerLine + cols
            startCategory = thisCategory
            currentYOffset = (thisCategory:GetHeight() + (10 * data.uiScale))  -- Increased vertical spacing
        else
            -- Check if we need to start a new line
            if iconsPerLine + cols >= 15 then
                thisCategory:SetPoint("TOPLEFT", uiElements.oneBag:GetContent(), "TOPLEFT", 5* data.uiScale, currentYOffset)
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

    local doInventoryUpdate = false
    local doBatSlotsUpdate = false

    for thisSlot, state in pairs (slots) do
        
        if stringFind(thisSlot, "sibg.") then
            doBatSlotsUpdate = true
        elseif string.find(thisSlot, "si") then
            doInventoryUpdate = true
        end

        if doBatSlotsUpdate and doInventoryUpdate then break end
    end

    --print (doInventoryUpdate)

    if doInventoryUpdate then 
        EnKai.inventory.updateDB()
        oneBag.populateBag(true) 
    end

    if doBatSlotsUpdate then  oneBag.getBagSlots() end

end

function oneBag.itemUpdate (_, a, b)
    --print "Hossa"
end