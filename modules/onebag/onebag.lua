
local addonInfo, privateVars = ...

---------- init namespace ---------

local data      = privateVars.data
local uiElements= privateVars.uiElements
local _internal = privateVars.internal
local _events   = privateVars.events

local InspectTimeReal   = Inspect.Time.Real

local stringFormat      = string.format
local stringFind        = string.find
local stringMatch       = string.match

---------- init local variables ---------

local name = "onebag"
local itemIcons = {}
local categoryLabels = {}
local draggedItem, draggedSlot
local movedItem
local cachedItems
local lastCacheUpdate

---------- make global functions local ---------

local function _fctGetBagSlots ()

    local slots = EnKai.inventory.getBagSlots()

    for idx = 1, 8, 1 do

        local bagSlot = slots[stringFormat("sibg.%03d", idx)]

        if bagSlot.icon == nil then
            uiElements.oneBagBagSlots:SetIcon(idx, addonInfo.identifier, "gfx/iconLockedBagSlot.png")
            uiElements.oneBagBagSlots:SetTint (idx, true)
        else
            uiElements.oneBagBagSlots:SetIcon(idx, "Rift", bagSlot.icon)
            uiElements.oneBagBagSlots:SetTint (idx, false)
        end
    end    

end

local function _fctItemIcon (name, parent)

    local thisItemID, thisSlot

    local itemFrame = EnKai.uiCreateFrame("nKFrame", name, parent) 
    itemFrame:SetWidth(40 * data.uiScale)
    itemFrame:SetHeight(40 * data.uiScale)
    
    local itemIcon = EnKai.uiCreateFrame("nkTexture", name .. ".icon", itemFrame)
    itemIcon:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 2, 2)
    itemIcon:SetPoint("BOTTOMRIGHT", itemFrame, "BOTTOMRIGHT", -2, -2)
    itemIcon:SetLayer(1)

    local quantityText = EnKai.uiCreateFrame("nkText", name .. ".quantityText", itemFrame)
    quantityText:SetPoint("BOTTOMRIGHT", itemIcon, "BOTTOMRIGHT", -1, 1)
    quantityText:SetFontSize(14 * data.uiScale)
    quantityText:SetFontColor(1, 1, 1, 1)
    quantityText:SetTextFont (addonInfo.id, "MontserratSemiBold")
    quantityText:SetEffectGlow({ strength = 3})
    quantityText:SetLayer(2)

    local bindText = EnKai.uiCreateFrame("nkText", name .. ".bindText", itemFrame)
    bindText:SetPoint("TOPLEFT", itemIcon, "TOPLEFT", -1, 1)
    bindText:SetFontSize(10 * data.uiScale)
    bindText:SetFontColor(1, 1, 1, 1)
    bindText:SetTextFont (addonInfo.id, "MontserratSemiBold")
    bindText:SetEffectGlow({ strength = 3})
    bindText:SetLayer(2)

    function itemFrame:SetItem (itemID)
        thisItemID = itemID        
        --EnKai.ui.attachItemTooltip (itemIcon, itemID)
    end

    function itemFrame:SetIcon (addonName, path)
        itemIcon:SetTextureAsync(addonName, path)
    end

    function itemFrame:SetSlot(slotID)
        thisSlot = slotID
    end

    function itemFrame:Clear()
        thisSlot = nil
        thisItemDI = nil
        itemFrame:SetVisible(false)
    end 

    function itemFrame:SetQuantity(quantity)
        if quantity then
            quantityText:SetText(quantity)
            quantityText:SetVisible(true)
        else
            quantityText:SetVisible(false)
        end
    end

    function itemFrame:SetRarity(rarity)
        if rarity == "sellable" then
            itemFrame:SetBackgroundColor(0.5, 0.5, 0.5, 1)
        elseif rarity == "uncommon" then
            itemFrame:SetBackgroundColor(0, 1, 0, 1)
        elseif rarity == "rare" then
            itemFrame:SetBackgroundColor(0, 0, 1, 1)
        elseif rarity == "epic" then
            itemFrame:SetBackgroundColor(0.5, 0, 0.5, 1)
        elseif rarity == "relic" then
            itemFrame:SetBackgroundColor(0.5, 0.5, 0, 1)
        elseif rarity == "transcendent" then
            itemFrame:SetBackgroundColor(1, 0.5, 0, 1)
        elseif rarity == "quest" then
            itemFrame:SetBackgroundColor(0.8, 0.6, 0.2, 1)  -- Darkish yellow color
        else
            itemFrame:SetBackgroundColor(1, 1, 1, 1)
        end
    end

    function itemFrame:SetBound(bind, bound)
        if bind == "equip" then
            bindText:SetVisible(true)
            bindText:SetText("BOE")
        elseif bind == "use" then
            bindText:SetVisible(true)
            bindText:SetText("BOU")
        elseif bind == "pickup" then
            bindText:SetVisible(true)
            bindText:SetText("BOP")
        elseif bind == "account" then
            bindText:SetVisible(true)
            bindText:SetText("BOA")
        else
            bindText:SetVisible(false)
        end
    end

    itemIcon:EventAttach( Event.UI.Input.Mouse.Cursor.In, function (self)	
        Command.Tooltip(thisItemID)
    end, name .. "Event.UI.Input.Mouse.Cursor.In")

    itemIcon:EventAttach( Event.UI.Input.Mouse.Cursor.Out, function (self)	
        Command.Tooltip(nil)
    end, name .. "Event.UI.Input.Mouse.Cursor.Out")

    itemIcon:EventAttach( Event.UI.Input.Mouse.Left.Down, function (self)	
        draggedItem = thisItemID
        draggedSlot = thisSlot
        Command.Item.Standard.Left(thisItemID)
	    Command.Cursor(thisItemID)
	end, name .. "Event.Left.Down")

    itemIcon:EventAttach( Event.UI.Input.Mouse.Right.Down, function (self)	
        if UI.Native.Bank:GetLoaded() then
            local vaultSlot = EnKai.inventory.findFreeVaultSlot()
            if vaultSlot then
                Command.Item.Move(thisSlot, vaultSlot)
                movedItem = thisItemID
             end
        else
            Command.Item.Standard.Right(thisItemID)           
        end
	end, name .. "Event.Right.Down")	

    return itemFrame

end

local function _fctItemCategory (name, parent)
    
    local categoryFrame = EnKai.uiCreateFrame("nkFrame",  name .. ".categoryFrame", parent)    
    categoryFrame:SetHeight(60 * data.uiScale)

    local categoryText = EnKai.uiCreateFrame("nkText", name .. ".categoryText", categoryFrame)
    categoryText:SetFontSize(14 * data.uiScale)
    categoryText:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT")
    categoryText:SetFontColor(1, 1, 1, 1)
    categoryText:SetTextFont (addonInfo.id, "MontserratSemiBold")
    categoryText:SetEffectGlow({ strength = 3})
    categoryText:SetLayer(1)

    function categoryFrame:SetText(newText)
        categoryText:ClearWidth()
        categoryText:SetText(newText)
    end

    function categoryFrame:GetTextWidth()
        return categoryText:GetWidth()
    end

    return categoryFrame

end

local function _fctBagUI()

    local bagWindow = EnKai.uiCreateFrame("nkWindowMetro", "nkUI.bagWindow", uiElements.contextDialog)
    bagWindow:SetTitle("nkUI Inventory")
    bagWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    bagWindow:SetWidth(680 * data.uiScale)
    bagWindow:SetHeight(600 * data.uiScale)
    bagWindow:SetShadow(true)
    bagWindow:SetLayer(1)

    bagWindow:SetPoint("CENTER", UIParent, "CENTER", 1000 * data.uiScale, 000 * data.uiScale)

    bagWindow:EventAttach( Event.UI.Input.Mouse.Left.Up, function (self)	
        Command.Cursor(nil)
	end, "nkUI.bagWindow" .. ".Event.Left.Up")	

    return bagWindow

end

local function _fctBagSlots ()

    local bagSlots = {}

    local bagSlotsFrame = EnKai.uiCreateFrame("nkFrame", "nkUIBagSlotFrame", uiElements.oneBag)
    bagSlotsFrame:SetWidth(365 * data.uiScale)
    bagSlotsFrame:SetHeight(50 * data.uiScale)
    bagSlotsFrame:SetPoint("TOPLEFT", uiElements.oneBag, "BOTTOMLEFT", -5 * data.uiScale, 8 * data.uiScale)
    bagSlotsFrame:SetBackgroundColor(0,0,0,0.5)
    bagSlotsFrame:SetLayer(2)

    for idx = 1, 8, 1 do
        local thisSlot = EnKai.uiCreateFrame("nkCanvas", "nkUIBagSlot"..idx, bagSlotsFrame)
        thisSlot:SetWidth(40 * data.uiScale)
        thisSlot:SetHeight(40 * data.uiScale)
        thisSlot:SetPoint("TOPLEFT", bagSlotsFrame, "TOPLEFT", ((idx-1)*45 + 5)* data.uiScale, 5* data.uiScale)
        
        local stroke = {r = 0.5, g = 0.5, b = 0.5, a = 1, thickness = 1 }
        local path = {  {xProportional = 0, yProportional = 0},
                        {xProportional = 1, yProportional = 0},
                        {xProportional = 1, yProportional = 1},
                        {xProportional = 0, yProportional = 1},
                        {xProportional = 0, yProportional = 0}
                        }  

        thisSlot:SetShape (path, nil, stroke)

        local icon = EnKai.uiCreateFrame("nkTexture", "nkUIBagSlotIcon"..idx, bagSlotsFrame)
        icon:SetWidth(38 * data.uiScale)
        icon:SetHeight(38 * data.uiScale)
        icon:SetPoint("CENTER", thisSlot, "CENTER")
        icon:SetTextureAsync(addonInfo.identifier, "gfx/iconLockedBagSlot.png")
        icon:SetLayer(1)

        icon:EventAttach(Event.UI.Input.Mouse.Left.Up, function(self, _)
            if draggedItem == nil or draggedSlot == nil then return end

            local type, held = Inspect.Cursor()
            local target = stringFormat("sibg.%03d", idx)
            local source = draggedSlot
            Command.Item.Move(target, source)
            Command.Cursor(nil)

        end, "nkUIBagSlotIcon"..idx .. ".Left.Up")  
                

        thisSlot.icon = icon                

        local tint = EnKai.uiCreateFrame("nkFrame", "nkUIBagSlotTint"..idx, bagSlotsFrame)
        tint:SetWidth(38 * data.uiScale)
        tint:SetHeight(38 * data.uiScale)
        tint:SetPoint("CENTER", thisSlot, "CENTER")
        tint:SetBackgroundColor(1, 0, 0, 0.5)
        tint:SetLayer(2)
        tint:SetVisible(false)

        thisSlot.tint = tint
    
        bagSlots[stringFormat("sibg.%03d", idx)] = thisSlot        
    end

    function bagSlotsFrame:SetIcon (index, addonID, icon)
        local thisSlot = bagSlots[stringFormat("sibg.%03d", index)]
        thisSlot.icon:SetTextureAsync(addonID, icon)
    end

    function bagSlotsFrame:SetTint (index, newValue)
        local thisSlot = bagSlots[stringFormat("sibg.%03d", index)]
        thisSlot.tint:SetVisible(newValue)
    end

    return bagSlotsFrame

end

local function _getRealCategory (category, rarity)

    if stringFind(category, "consumable") then
        return "Consumable"
    elseif stringFind(category, "armor") then
        return "Armor"        
    elseif stringFind(category, "artifact") then
        return "Artifact"
    elseif stringFind(category, "quest") then
        return "Quest"
    elseif stringFind(category, "fish") then
        return "Fishing"
    elseif stringFind(category, "meat") then
        return "Meat"    
    elseif stringFind(category, "butchering") then
        return "Butchering"          
    elseif stringFind(category, "cloth") then
        return "Cloth"                
    elseif stringFind(category, "weapon") then
        return "Weapon"
    elseif stringFind(category, "misc") then
        if rarity == "sellable" then 
            return "Trash"
        else
            return "Various"
        end
    elseif stringFind(category, "crafting ingredient") then
        return "Crafting material"
    elseif stringFind(category, "crafting recipe") then
        return "Crafting recipe"
    elseif stringFind(category, "crafting material") or stringFind(category, "crafting augment") then
        return "Crafting material"        
    elseif stringFind(category, "container") then
        return "Container"
    elseif stringFind(category, "armor costume") then
        return "Costume"
    elseif stringFind(category, "dimension") then
        return "Dimension"
    elseif stringFind(category, "planar vessel") then
        return "Planar Fokus"
    end

    return category

end

function _internal.populateBag(forceCacheUpdate)

    local counter = 1
    local firstIcon = nil
    local lastIcon = nil

    if forceCacheUpdate == true or cachedItems == nil or InspectTimeReal() - lastCacheUpdate > 5 then
        cachedItems = EnKai.inventory.getBagItems()
        lastCacheUpdate = InspectTimeReal()
    end

    local categories = {}

    for k, v in pairs(cachedItems) do
        local realCategory = _getRealCategory(v.category, v.rarity)

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
            thisCategory = _fctItemCategory("nkUI.onebagCategory." .. category, uiElements.oneBag:GetContent())
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
                thisIcon = _fctItemIcon("nkUI.onebagItem." .. slot, thisCategory)
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

local function _fctItemSlot (_, slots)

    --print ("_fctItemSlot")
    --dump (slots)
    
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
        _internal.populateBag(true) 
    end

    if doBatSlotsUpdate then  _fctGetBagSlots() end

end

local function _fctItemUpdate (_, a, b)
    --print "Hossa"
end

function _internal.oneBagInit()

    if uiElements.oneBag then 
        if uiElements.oneBag:GetVisible() then
            --EnKai.ui.getItemTooltip():SetVisible(false)
            uiElements.oneBag:SetVisible(false)
        else
            uiElements.oneBag:SetVisible(true)
        end
    else
        EnKai.inventory.updateDB()
        uiElements.oneBag = _fctBagUI()
        uiElements.oneBagBagSlots = _fctBagSlots ()

        Command.Event.Attach(Event.Item.Slot, _fctItemSlot, "nkUI.OneBag.Item.Slot")
        Command.Event.Attach(Event.Item.Update, _fctItemUpdate, "nkUI.OneBag.Item.Update")

        Command.Event.Attach(EnKai.events["EnKai.InventoryManager"].SlotUpdate, function (_, slots)
            if cachedItems then
                for k, v in pairs(slots) do
                    if stringMatch(k,"^si%d%d%.%d%d%d$") then
                        if v == false then
                            cachedItems[k] = nil
                        else
                            cachedItems[k] = EnKai.inventory.GetItemByKey (v)
                        end
                    end
                end                
            end

            _internal.populateBag()

        end, "nkUI.OneBag.EnKai.InventoryManager.SlotUpdate")

        Command.Event.Attach(EnKai.events["EnKai.InventoryManager"].Update, function (_, items)
            --dump (items)
--[[            
            for k, v in pairs(items) do
                if movedItem == k and v > 0 then
                    movedItem = nil
                    EnKai.inventory.updateDB()
                    _internal.populateBag()
                end
            end
]]
        end, "nkUI.OneBag.EnKai.InventoryManager.Update")
    end

    _internal.populateBag()
    _fctGetBagSlots()

end