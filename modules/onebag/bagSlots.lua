local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local oneBag        = privateVars.oneBag

---------- local functions ---------

local stringFormat  = string.format

local ICONSIZE = 30
local ICONPADDING = 5

local function bagSlot(name, parent, riftSlot)

    local isLocked = false
    local thisItemID

    local thisSlot = EnKai.uiCreateFrame("nkCanvas", name, parent)
    thisSlot:SetWidth(ICONSIZE * data.uiScale)
    thisSlot:SetHeight(ICONSIZE * data.uiScale)    
    
    local stroke = {r = 0.5, g = 0.5, b = 0.5, a = 1, thickness = 1}
    local path = {
        {xProportional = 0, yProportional = 0},
        {xProportional = 1, yProportional = 0},
        {xProportional = 1, yProportional = 1},
        {xProportional = 0, yProportional = 1},
        {xProportional = 0, yProportional = 0}
    }
    
    thisSlot:SetShape(path, nil, stroke)
    
    local icon = EnKai.uiCreateFrame("nkTexture", name .. ".icon", parent)
    icon:SetWidth((ICONSIZE-2) * data.uiScale)
    icon:SetHeight((ICONSIZE-2) * data.uiScale)
    icon:SetPoint("CENTER", thisSlot, "CENTER")
    icon:SetTextureAsync(addonInfo.identifier, "gfx/iconLockedBagSlot.png")
    icon:SetLayer(1)
            
    thisSlot.icon = icon
    
    local tint = EnKai.uiCreateFrame("nkFrame", name .. ".tint", parent)
    tint:SetWidth((ICONSIZE-2) * data.uiScale)
    tint:SetHeight((ICONSIZE-2) * data.uiScale)
    tint:SetPoint("CENTER", thisSlot, "CENTER")
    tint:SetBackgroundColor(1, 0, 0, 0.5)
    tint:SetLayer(2)
    tint:SetVisible(false)
    
    thisSlot.tint = tint

    function thisSlot:SetLocked(newValue)
        isLocked = newValue
    end

    function thisSlot:SetItemID(itemID)
        thisItemID = itemID
    end
    
    icon:EventAttach(Event.UI.Input.Mouse.Cursor.In, function()
        Command.Tooltip(thisItemID)
    end, name .. ".Event.UI.Input.Mouse.Cursor.In")
    
    icon:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function()
        Command.Tooltip(nil)
    end, name .. ".Event.UI.Input.Mouse.Cursor.Out")

    icon:EventAttach(Event.UI.Input.Mouse.Left.Down, function()
        oneBag.dragItem = {
            draggedItem = thisItemID,
            draggedSlot = riftSlot
        }
        Command.Item.Standard.Left(thisItemID)
        Command.Cursor(thisItemID)
    end, name .. "Event.Left.Down")

    icon:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        if not oneBag.dragItem then return end
        --if isLocked then return end
        
        local sourceSlot = oneBag.dragItem.draggedSlot
        if sourceSlot == nil then return end
        
        local type, held = Inspect.Cursor()
        --local target = stringFormat("sibg.%03d", idx)
        
        Command.Item.Move(sourceSlot, riftSlot)
        Command.Cursor(nil)

        oneBag.dragItem = nil
    end, name .. ".Event.Mouse.Left.Up")

    icon:EventAttach(Event.UI.Input.Mouse.Right.Click, function()
        if not isLocked then return end        
        internalFunc.dialog ("Please use the standard UI to purchase additional bag slots.\n\nThis is a RIFT limitiation.")
    end, name .. ".Event.Mouse.Right.Click")
    
    return thisSlot

end


-- Creates the bag slots UI
function oneBag.createBagSlots()
    
    local bagSlots = {}
    local thisItemID

    local width = (10 + (8 * ICONSIZE) + (7 * ICONPADDING)) * data.uiScale
    local height = (10 + ICONSIZE) * data.uiScale
    
    local bagSlotsFrame = EnKai.uiCreateFrame("nkFrame", "nkUIBagSlotFrame", uiElements.oneBag)
    bagSlotsFrame:SetWidth(width)
    bagSlotsFrame:SetHeight(height)
    bagSlotsFrame:SetPoint("TOPLEFT", uiElements.oneBag, "BOTTOMLEFT", 0, 5 * data.uiScale)
    bagSlotsFrame:SetBackgroundColor(data.theme.windowStartColor.r, data.theme.windowStartColor.g, data.theme.windowStartColor.b, data.theme.windowStartColor.a)
    bagSlotsFrame:SetLayer(2)
    
    for idx = 1, 8, 1 do
        local riftSlot = stringFormat("sibg.%03d", idx)
        local thisSlot = bagSlot("nkUIBagSlot" .. idx, bagSlotsFrame, riftSlot)
        thisSlot:SetPoint("TOPLEFT", bagSlotsFrame, "TOPLEFT", (5 + ((idx - 1) * (ICONSIZE + ICONPADDING))) * data.uiScale, 5 * data.uiScale)
        bagSlots[riftSlot] = thisSlot
    end
    
    function bagSlotsFrame:SetItem(index, itemID)
        local thisSlot = bagSlots[stringFormat("sibg.%03d", index)]
        thisSlot:SetItemID(itemID)
    end
    
    function bagSlotsFrame:SetIcon(index, addonID, icon)
        local thisSlot = bagSlots[stringFormat("sibg.%03d", index)]
        thisSlot.icon:SetTextureAsync(addonID, icon)
    end
    
    function bagSlotsFrame:SetTint(index, newValue)
        local thisSlot = bagSlots[stringFormat("sibg.%03d", index)]
        thisSlot.tint:SetVisible(newValue)
        thisSlot:SetLocked(newValue)
    end
    
    return bagSlotsFrame
end

function oneBag.getBagSlots ()

    local slots = EnKai.inventory.getBagSlots()

    for idx = 1, 8, 1 do

        local bagSlot = slots[stringFormat("sibg.%03d", idx)]

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