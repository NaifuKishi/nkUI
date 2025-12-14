local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local internalFunc = privateVars.internalFunc
local oneBag        = privateVars.oneBag

---------- local functions ---------

local stringFormat  = string.format

-- Creates the bag slots UI
function oneBag.createBagSlots()
    
    local bagSlots = {}
    local thisItemID
    
    local bagSlotsFrame = EnKai.uiCreateFrame("nkFrame", "nkUIBagSlotFrame", uiElements.oneBag)
    bagSlotsFrame:SetWidth(365 * data.uiScale)
    bagSlotsFrame:SetHeight(50 * data.uiScale)
    bagSlotsFrame:SetPoint("TOPLEFT", uiElements.oneBag, "BOTTOMLEFT", -5 * data.uiScale, 8 * data.uiScale)
    bagSlotsFrame:SetBackgroundColor(0, 0, 0, 0.5)
    bagSlotsFrame:SetLayer(2)
    
    for idx = 1, 8, 1 do
        local thisSlot = EnKai.uiCreateFrame("nkCanvas", "nkUIBagSlot" .. idx, bagSlotsFrame)
        thisSlot:SetWidth(40 * data.uiScale)
        thisSlot:SetHeight(40 * data.uiScale)
        thisSlot:SetPoint("TOPLEFT", bagSlotsFrame, "TOPLEFT", ((idx - 1) * 45 + 5) * data.uiScale, 5 * data.uiScale)
        
        local stroke = {r = 0.5, g = 0.5, b = 0.5, a = 1, thickness = 1}
        local path = {
            {xProportional = 0, yProportional = 0},
            {xProportional = 1, yProportional = 0},
            {xProportional = 1, yProportional = 1},
            {xProportional = 0, yProportional = 1},
            {xProportional = 0, yProportional = 0}
        }
        
        thisSlot:SetShape(path, nil, stroke)
        
        local icon = EnKai.uiCreateFrame("nkTexture", "nkUIBagSlotIcon" .. idx, bagSlotsFrame)
        icon:SetWidth(38 * data.uiScale)
        icon:SetHeight(38 * data.uiScale)
        icon:SetPoint("CENTER", thisSlot, "CENTER")
        icon:SetTextureAsync(addonInfo.identifier, "gfx/iconLockedBagSlot.png")
        icon:SetLayer(1)
        
        icon:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
            if draggedItem == nil or draggedSlot == nil then return end
            
            local type, held = Inspect.Cursor()
            local target = stringFormat("sibg.%03d", idx)
            local source = draggedSlot
            Command.Item.Move(target, source)
            Command.Cursor(nil)
        end, "nkUIBagSlotIcon" .. idx .. ".Left.Up")
        
        thisSlot.icon = icon
        
        local tint = EnKai.uiCreateFrame("nkFrame", "nkUIBagSlotTint" .. idx, bagSlotsFrame)
        tint:SetWidth(38 * data.uiScale)
        tint:SetHeight(38 * data.uiScale)
        tint:SetPoint("CENTER", thisSlot, "CENTER")
        tint:SetBackgroundColor(1, 0, 0, 0.5)
        tint:SetLayer(2)
        tint:SetVisible(false)
        
        thisSlot.tint = tint
        
        icon:EventAttach(Event.UI.Input.Mouse.Cursor.In, function()
            Command.Tooltip(thisSlot.itemID)
        end, "nkUIBagSlotIcon" .. idx .. "Event.UI.Input.Mouse.Cursor.In")
        
        icon:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function()
            Command.Tooltip(nil)
        end, "nkUIBagSlotIcon" .. idx .. "Event.UI.Input.Mouse.Cursor.Out")
        
        bagSlots[stringFormat("sibg.%03d", idx)] = thisSlot
    end
    
    function bagSlotsFrame:SetItem(index, itemID)
        local thisSlot = bagSlots[stringFormat("sibg.%03d", index)]
        thisSlot.itemID = itemID
    end
    
    function bagSlotsFrame:SetIcon(index, addonID, icon)
        local thisSlot = bagSlots[stringFormat("sibg.%03d", index)]
        thisSlot.icon:SetTextureAsync(addonID, icon)
    end
    
    function bagSlotsFrame:SetTint(index, newValue)
        local thisSlot = bagSlots[stringFormat("sibg.%03d", index)]
        thisSlot.tint:SetVisible(newValue)
    end
    
    return bagSlotsFrame
end

function oneBag.getBagSlots ()

    local slots = EnKai.inventory.getBagSlots()

    for idx = 1, 8, 1 do

        local bagSlot = slots[stringFormat("sibg.%03d", idx)]

        --dump (bagSlot)

        if bagSlot.icon == nil then
            uiElements.oneBagBagSlots:SetIcon(idx, addonInfo.identifier, "gfx/iconLockedBagSlot.png")
            uiElements.oneBagBagSlots:SetTint (idx, true)
            uiElements.oneBagBagSlots:SetItem(idx, nil)
        else
            uiElements.oneBagBagSlots:SetIcon(idx, "Rift", bagSlot.icon)
            uiElements.oneBagBagSlots:SetTint (idx, false)
            uiElements.oneBagBagSlots:SetItem(idx, bagSlot.id)
        end
    end    

end