local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local oneBag        = privateVars.oneBag

local inspectTimeFrame = Inspect.Time.Frame
local InspectItemDetail = Inspect.Item.Detail

local stringFormat  = string.format
local stringFind    = string.find

---------- local functions ---------

-- Creates an item icon UI element
function oneBag.createItemIcon(name, parent)
    local thisItemID, thisSlot, thisItemType
    local path = {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 0}, {xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 1}, {xProportional = 0, yProportional = 0}}
    local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1 }
    
    local itemFrame = LibEKL.UICreateFrame("nkCanvas", name, parent)
    itemFrame:SetWidth(40 * data.bagScale)
    itemFrame:SetHeight(40 * data.bagScale)
    
    local itemIcon = LibEKL.UICreateFrame("nkTexture", name .. ".icon", itemFrame)
    itemIcon:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 1, 1)
    itemIcon:SetPoint("BOTTOMRIGHT", itemFrame, "BOTTOMRIGHT", -1, -1)
    itemIcon:SetLayer(1)
    
    local quantityText = LibEKL.UICreateFrame("nkText", name .. ".quantityText", itemFrame)
    quantityText:SetPoint("BOTTOMRIGHT", itemIcon, "BOTTOMRIGHT", -1, 1)
    quantityText:SetFontSize(14 * data.bagScale)
    quantityText:SetFontColor(1, 1, 1, 1)
    quantityText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    quantityText:SetEffectGlow({ strength = 3})
    quantityText:SetLayer(2)
    
    local bindText = LibEKL.UICreateFrame("nkText", name .. ".bindText", itemFrame)
    bindText:SetPoint("TOPLEFT", itemIcon, "TOPLEFT", -1, 1)
    bindText:SetFontSize(10 * data.bagScale)
    bindText:SetFontColor(1, 1, 1, 1)
    bindText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    bindText:SetEffectGlow({ strength = 3})
    bindText:SetLayer(2)

    function itemFrame:SetItem(itemID)
        thisItemID = itemID
    end

    function itemFrame:SetItemType(itemType)
        thisItemType = itemType
    end
    
    function itemFrame:SetIcon(addonName, icon)
        --itemIcon:SetTextureAsync(addonName, path)

        local width = itemFrame:GetWidth()
		fill = { type = "texture", source = "Rift", texture = icon, transform = Utility.Matrix.Create(1 / width * 32, 1 / width * 34, 0, 0, 0) }
        itemFrame:SetShape(path, fill, stroke)
    end
    
    function itemFrame:SetSlot(slotID)
        thisSlot = slotID
    end

    local oSetVisible = itemFrame.SetVisible
    function itemFrame:SetVisible(flag)
        if nkDebug then nkDebug.logEntry (addonInfo.identifier, stringFormat("One Bag Set slot visibility %s", thisSlot), flag) end
        oSetVisible(self, flag)
    end
    
    function itemFrame:Clear()
        thisSlot = nil
        thisItemID = nil
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
        local color = LibEKL.Inventory.GetItemColor(rarity)
        --itemFrame:SetBackgroundColor(color.r, color.g, color.b, 1)
        stroke = color
        stroke.thickness = 1
        itemFrame:SetShape(path, fill, stroke)
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
    
    itemIcon:EventAttach(Event.UI.Input.Mouse.Cursor.In, function()        
        Command.Tooltip(thisItemID)
        oneBag.showItemTooltip (thisItemID)
    end, name .. "Event.UI.Input.Mouse.Cursor.In")
    
    itemIcon:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function()
        oneBag.hideItemTooltip()
        Command.Tooltip(nil)        
    end, name .. "Event.UI.Input.Mouse.Cursor.Out")
    
    itemIcon:EventAttach(Event.UI.Input.Mouse.Left.Down, function()
        oneBag.dragItem = {
            draggedItem = thisItemID,
            draggedItemType = thisItemType,
            draggedSlot = thisSlot
        }
        Command.Item.Standard.Left(thisItemID)
        Command.Cursor(thisItemID)
    end, name .. "Event.Left.Down")

    itemIcon:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        if not oneBag.dragItem then return end

        if thisItemType == oneBag.dragItem.draggedItemType then
            Command.Item.Move(oneBag.dragItem.draggedSlot, thisSlot)
        end

        oneBag.dragItem = nil
        Command.Cursor(nil)
    end, name .. ".Event.Mouse.Left.Up")
   
    itemIcon:EventAttach(Event.UI.Input.Mouse.Right.Down, function()
        if thisItemID then Command.Item.Standard.Right(thisItemID) end

        --[[if stringFind(thisSlot, "si") then
            if UI.Native.Bank:GetLoaded() then
                oneBag.moveToBank (thisSlot, thisItemID)                
            else
                if thisItemID then Command.Item.Standard.Right(thisItemID) end
            end
        else
            oneBag.moveToBag(thisSlot, thisItemID)
        end]]
    end, name .. "Event.Right.Down")
    
    return itemFrame
end