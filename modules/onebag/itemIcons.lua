local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local oneBag        = privateVars.oneBag

local stringFormat  = string.format

---------- local functions ---------

-- Creates an item icon UI element
function oneBag.createItemIcon(name, parent)
    local thisItemID, thisSlot
    
    local itemFrame = EnKai.uiCreateFrame("nKFrame", name, parent)
    itemFrame:SetWidth(40 * data.uiScale)
    itemFrame:SetHeight(40 * data.uiScale)
    
    local itemIcon = EnKai.uiCreateFrame("nkTexture", name .. ".icon", itemFrame)
    itemIcon:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 1, 1)
    itemIcon:SetPoint("BOTTOMRIGHT", itemFrame, "BOTTOMRIGHT", -1, -1)
    itemIcon:SetLayer(1)
    
    local quantityText = EnKai.uiCreateFrame("nkText", name .. ".quantityText", itemFrame)
    quantityText:SetPoint("BOTTOMRIGHT", itemIcon, "BOTTOMRIGHT", -1, 1)
    quantityText:SetFontSize(14 * data.uiScale)
    quantityText:SetFontColor(1, 1, 1, 1)
    quantityText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    quantityText:SetEffectGlow({ strength = 3})
    quantityText:SetLayer(2)
    
    local bindText = EnKai.uiCreateFrame("nkText", name .. ".bindText", itemFrame)
    bindText:SetPoint("TOPLEFT", itemIcon, "TOPLEFT", -1, 1)
    bindText:SetFontSize(10 * data.uiScale)
    bindText:SetFontColor(1, 1, 1, 1)
    bindText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    bindText:SetEffectGlow({ strength = 3})
    bindText:SetLayer(2)

    function itemFrame:SetItem(itemID)
        thisItemID = itemID
    end
    
    function itemFrame:SetIcon(addonName, path)
        itemIcon:SetTextureAsync(addonName, path)
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
            itemFrame:SetBackgroundColor(0.8, 0.6, 0.2, 1)
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
    
    itemIcon:EventAttach(Event.UI.Input.Mouse.Cursor.In, function()
        Command.Tooltip(thisItemID)
    end, name .. "Event.UI.Input.Mouse.Cursor.In")
    
    itemIcon:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function()
        Command.Tooltip(nil)
    end, name .. "Event.UI.Input.Mouse.Cursor.Out")
    
    itemIcon:EventAttach(Event.UI.Input.Mouse.Left.Down, function()
        oneBag.dragItem = {
            draggedItem = thisItemID,
            draggedSlot = thisSlot
        }
        Command.Item.Standard.Left(thisItemID)
        Command.Cursor(thisItemID)
    end, name .. "Event.Left.Down")
   
    itemIcon:EventAttach(Event.UI.Input.Mouse.Right.Down, function()
        if UI.Native.Bank:GetLoaded() then
            local vaultSlot = EnKai.inventory.findFreeVaultSlot()
            if vaultSlot then
                Command.Item.Move(thisSlot, vaultSlot)
                movedItem = thisItemID
            else
                local bankSlot = EnKai.inventory.findFreeBankSlot()
                if bankSlot then
                    Command.Item.Move(thisSlot, bankSlot)
                    movedItem = thisItemID
                end
            end
        else
            if thisItemID then Command.Item.Standard.Right(thisItemID) end
        end
    end, name .. "Event.Right.Down")
    
    return itemFrame
end