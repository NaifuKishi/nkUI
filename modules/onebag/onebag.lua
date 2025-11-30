
local addonInfo, privateVars = ...

---------- init namespace ---------

local data      = privateVars.data
local uiElements= privateVars.uiElements
local _internal = privateVars.internal
local _events   = privateVars.events

local stringFormat      = string.format
local stringFind        = string.find

---------- init local variables ---------

local name = "onebag"
local itemIcons = {}
local categoryLabels = {}
local draggedItem, draggedSlot

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
    itemFrame:SetWidth(40 * data.uiScaleX)
    itemFrame:SetHeight(40 * data.uiScaleX)
    
    local itemIcon = EnKai.uiCreateFrame("nkTexture", name .. ".icon", itemFrame)
    itemIcon:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 2, 2)
    itemIcon:SetPoint("BOTTOMRIGHT", itemFrame, "BOTTOMRIGHT", -2, -2)
    itemIcon:SetLayer(1)

    local quantityText = EnKai.uiCreateFrame("nkText", name .. ".quantityText", itemFrame)
    quantityText:SetPoint("BOTTOMRIGHT", itemIcon, "BOTTOMRIGHT", -1, 1)
    quantityText:SetFontSize(14 * data.uiScaleX)
    quantityText:SetFontColor(1, 1, 1, 1)
    quantityText:SetTextFont (addonInfo.id, "MontserratSemiBold")
    quantityText:SetEffectGlow({ strength = 3})
    quantityText:SetLayer(2)

    local bindText = EnKai.uiCreateFrame("nkText", name .. ".bindText", itemFrame)
    bindText:SetPoint("TOPLEFT", itemIcon, "TOPLEFT", -1, 1)
    bindText:SetFontSize(10 * data.uiScaleX)
    bindText:SetFontColor(1, 1, 1, 1)
    bindText:SetTextFont (addonInfo.id, "MontserratSemiBold")
    bindText:SetEffectGlow({ strength = 3})
    bindText:SetLayer(2)

    function itemFrame:SetItem (itemID)
        thisItemID = itemID        
        EnKai.ui.attachItemTooltip (itemIcon, itemID)        
    end

    function itemFrame:SetIcon (addonName, path)
        itemIcon:SetTextureAsync(addonName, path)
    end

    function itemFrame:SetSlot(slotID)
        thisSlot = slotID
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

    itemFrame:EventAttach( Event.UI.Input.Mouse.Left.Down, function (self)	
        draggedItem = thisItemID
        draggedSlot = thisSlot
        Command.Item.Standard.Left(thisItemID)
	    Command.Cursor(thisItemID)
	end, name .. "Event.Left.Down")

    itemFrame:EventAttach( Event.UI.Input.Mouse.Right.Down, function (self)	
        Command.Item.Standard.Right(thisItemID)
	end, name .. "Event.Right.Down")	

    return itemFrame

end

local function _fctItemCategory (name, parent)
    
    local categoryFrame = EnKai.uiCreateFrame("nkFrame",  name .. ".categoryFrame", parent)    
    categoryFrame:SetHeight(60 * data.uiScaleX)

    local categoryText = EnKai.uiCreateFrame("nkText", name .. ".categoryText", categoryFrame)
    categoryText:SetFontSize(14 * data.uiScaleX)
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

    local bagWindow = EnKai.uiCreateFrame("nkWindowMetro", "nkUI.bagWindow", uiElements.context)
    bagWindow:SetTitle("nkUI Inventory")
    bagWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    bagWindow:SetWidth(680 * data.uiScaleX)
    bagWindow:SetHeight(600 * data.uiScaleX)
    bagWindow:SetPoint("BOTTOMRIGHT", UI.Native.BagInventory1, "BOTTOMRIGHT")
    bagWindow:SetShadow(true)
    bagWindow:SetLayer(1)

    return bagWindow

end

local function _fctBagSlots ()

    local bagSlots = {}

    local bagSlotsFrame = EnKai.uiCreateFrame("nkFrame", "nkUIBagSlotFrame", uiElements.oneBag)
    bagSlotsFrame:SetWidth(365 * data.uiScaleX)
    bagSlotsFrame:SetHeight(50 * data.uiScaleX)
    bagSlotsFrame:SetPoint("TOPLEFT", uiElements.oneBag, "BOTTOMLEFT", -5 * data.uiScaleX, 8 * data.uiScaleX)
    bagSlotsFrame:SetBackgroundColor(0,0,0,0.5)
    bagSlotsFrame:SetLayer(2)

    for idx = 1, 8, 1 do
        local thisSlot = EnKai.uiCreateFrame("nkCanvas", "nkUIBagSlot"..idx, bagSlotsFrame)
        thisSlot:SetWidth(40 * data.uiScaleX)
        thisSlot:SetHeight(40 * data.uiScaleX)
        thisSlot:SetPoint("TOPLEFT", bagSlotsFrame, "TOPLEFT", ((idx-1)*45 + 5)* data.uiScaleX, 5* data.uiScaleX)
        
        local stroke = {r = 0.5, g = 0.5, b = 0.5, a = 1, thickness = 1 }
        local path = {  {xProportional = 0, yProportional = 0},
                        {xProportional = 1, yProportional = 0},
                        {xProportional = 1, yProportional = 1},
                        {xProportional = 0, yProportional = 1},
                        {xProportional = 0, yProportional = 0}
                        }  

        thisSlot:SetShape (path, nil, stroke)

        local icon = EnKai.uiCreateFrame("nkTexture", "nkUIBagSlotIcon"..idx, bagSlotsFrame)
        icon:SetWidth(38 * data.uiScaleX)
        icon:SetHeight(38 * data.uiScaleX)
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
        tint:SetWidth(38 * data.uiScaleX)
        tint:SetHeight(38 * data.uiScaleX)
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

local function _getRealCategory (category)

    if stringFind(category, "consumable") then
        return "Consumable"
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
        return "Various"
    elseif stringFind(category, "crafting ingredient") then
        return "Crafting material"
    elseif stringFind(category, "crafting recipe") then
        return "Crafting recipe"
    elseif stringFind(category, "container") then
        return "Container"
    end

    return category

end

local function _populateBag()
    local counter = 1
    local firstIcon = nil
    local lastIcon = nil

    local items = EnKai.inventory.getBagItems()
    local categories = {}

    for k, v in pairs(items) do
        local realCategory = _getRealCategory(v.category)

        if categories[realCategory] == nil then
            categories[realCategory] = {}
        end

        categories[realCategory][k] = v
    end

    local iconsPerLine = 0
    local firstCategory = true
    local lastCategory
    local startCategory
    local currentYOffset = 0  -- Track vertical position for new categories

    for category, content in pairs(categories) do
        local thisCategory = categoryLabels[category]

        if thisCategory == nil then
            thisCategory = _fctItemCategory("nkUI.onebagCategory." .. category, uiElements.oneBag:GetContent())
            thisCategory:SetText(category)
            categoryLabels[category] = thisCategory
        end

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

            if counter == 1 then
                if rows == 1 then
                    itemIcons[slot]:SetPoint("TOPLEFT", firstIcon, "TOPLEFT", 0, 20* data.uiScaleX)
                else
                    itemIcons[slot]:SetPoint("TOPLEFT", firstIcon, "BOTTOMLEFT", 0, 2)
                end
                firstIcon = thisIcon
            else
                itemIcons[slot]:SetPoint("TOPLEFT", lastIcon, "TOPRIGHT", 5* data.uiScaleX, 0)
            end

            if rows == 1 then cols = cols + 1 end

            if counter == 15 then
                counter = 0
                rows = rows + 1
            end

            lastIcon = thisIcon
            counter = counter + 1
        end

        local checkTitleWidth = math.floor(thisCategory:GetTextWidth() / 44) + 1
        if checkTitleWidth > cols then cols = checkTitleWidth end

        thisCategory:SetHeight(((20* data.uiScaleX) + (rows * (40* data.uiScaleX)) + ((rows-1) * (5* data.uiScaleX))))
        thisCategory:SetWidth(((cols * (40* data.uiScaleX)) + ((cols-1) * (5* data.uiScaleX))))

        if firstCategory then
            firstCategory = false
            thisCategory:SetPoint("TOPLEFT", uiElements.oneBag:GetContent(), "TOPLEFT", 5* data.uiScaleX, 5* data.uiScaleX)
            iconsPerLine = iconsPerLine + cols
            startCategory = thisCategory
            currentYOffset = (thisCategory:GetHeight() + (10 * data.uiScaleX))  -- Increased vertical spacing
        else
            -- Check if we need to start a new line
            if iconsPerLine + cols > 15 then
                thisCategory:SetPoint("TOPLEFT", uiElements.oneBag:GetContent(), "TOPLEFT", 5* data.uiScaleX, currentYOffset)
                currentYOffset = currentYOffset + ((thisCategory:GetHeight() + (10* data.uiScaleX)))  -- Increased vertical spacing
                iconsPerLine = cols
            else
                thisCategory:SetPoint("TOPLEFT", lastCategory, "TOPRIGHT", 50* data.uiScaleX, 0)
                iconsPerLine = iconsPerLine + cols + 1
            end
        end

        lastCategory = thisCategory
    end
end

local function _fctItemSlot (_, slots)
    
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

    if doInventoryUpdate then _populateBag() end
    if doBatSlotsUpdate then  _fctGetBagSlots() end

end

local function _fctItemUpdate (_, a, b)

end

function _internal.oneBagInit()

    if uiElements.oneBag then 
        if uiElements.oneBag:GetVisible() then
            uiElements.oneBag:SetVisible(false)
        else
            uiElements.oneBag:SetVisible(true)
        end
    else
        EnKai.inventory.updateDB()
        uiElements.oneBag = _fctBagUI()
        uiElements.oneBagBagSlots = _fctBagSlots ()

        Command.Event.Attach(Event.Item.Slot, _fctItemSlot, "EnKai.inventory.Item.Slot")
        Command.Event.Attach(Event.Item.Update, _fctItemUpdate, "EnKai.inventory.Item.Update")

        Command.Event.Attach(EnKai.events["EnKai.InventoryManager"].Update, function (_, items)
        end, "nkUI.OneBag.EnKai.InventoryManager.Update")
    end

    _populateBag()
    _fctGetBagSlots()

end