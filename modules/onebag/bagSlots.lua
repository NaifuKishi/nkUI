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

    local thisSlot = LibEKL.UICreateFrame("nkCanvas", name, parent)
    thisSlot:SetWidth(ICONSIZE * data.bagScale)
    thisSlot:SetHeight(ICONSIZE * data.bagScale)    
    
    local stroke = {r = 0.5, g = 0.5, b = 0.5, a = 1, thickness = 1}
    local path = {
        {xProportional = 0, yProportional = 0},
        {xProportional = 1, yProportional = 0},
        {xProportional = 1, yProportional = 1},
        {xProportional = 0, yProportional = 1},
        {xProportional = 0, yProportional = 0}
    }
    
    thisSlot:SetShape(path, nil, stroke)
    
    local icon = LibEKL.UICreateFrame("nkTexture", name .. ".icon", parent)
    icon:SetWidth((ICONSIZE-2) * data.bagScale)
    icon:SetHeight((ICONSIZE-2) * data.bagScale)
    icon:SetPoint("CENTER", thisSlot, "CENTER")
    icon:SetTextureAsync(addonInfo.identifier, "gfx/iconLockedBagSlot.png")
    icon:SetLayer(1)
            
    thisSlot.icon = icon
    
    local tint = LibEKL.UICreateFrame("nkFrame", name .. ".tint", parent)
    tint:SetWidth((ICONSIZE-2) * data.bagScale)
    tint:SetHeight((ICONSIZE-2) * data.bagScale)
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
        local dialog = LibEKL.UI.messageDialog ("Please use the standard UI\nto purchase additional bag slots.\n\nThis is a RIFT limitiation.")
        dialog:SetTitle("nkUI")
        dialog:SetTitleFont(addonInfo.id, "MontserratSemiBold")
        dialog:SetTitleFontSize (20)
        dialog:SetHeight(250)
        dialog:SetTitleAlign("center")
        dialog:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

        dialog:SetFont(addonInfo.id, "MontserratSemiBold")
        dialog:SetEffectGlow({ strength = 3 })
        dialog:SetButtonFont(addonInfo.id, "MontserratSemiBold")
        dialog:SetButtonFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
        dialog:SetButtonLabelColor (data.theme.labelColor)
        dialog:SetButtonBorderColor ({ r = 0, g = 0, b = 0, a = .7, thickness = 1})
        dialog:SetButtonEffect({ strength = 3 })

        dialog:SetColor({   type = "gradientLinear",
                            transform = Utility.Matrix.Create(2, 2, -(math.pi / 6), 0, 0), -- Negative angle for opposite direction
                            color = {
                                data.theme.windowStartColor,
                                data.theme.windowEndColor
                                }
                        },  { r = 0, g = 0, b = 0, a = 1, thickness = 1})

    end, name .. ".Event.Mouse.Right.Click")
    
    return thisSlot

end


-- Creates the bag slots UI
function oneBag.createBagSlots()
    
    local bagSlots = {}
    local thisItemID

    local width = (10 + (8 * ICONSIZE) + (7 * ICONPADDING)) * data.bagScale
    local height = (10 + ICONSIZE) * data.bagScale
    
    local bagSlotsFrame = LibEKL.UICreateFrame("nkFrame", "nkUIBagSlotFrame", uiElements.oneBag)
    bagSlotsFrame:SetWidth(width)
    bagSlotsFrame:SetHeight(height)
    bagSlotsFrame:SetPoint("TOPLEFT", uiElements.oneBag, "BOTTOMLEFT", 0, 5 * data.bagScale)
    bagSlotsFrame:SetBackgroundColor(data.theme.windowStartColor.r, data.theme.windowStartColor.g, data.theme.windowStartColor.b, data.theme.windowStartColor.a)
    bagSlotsFrame:SetLayer(2)
    
    for idx = 1, 8, 1 do
        local riftSlot = stringFormat("sibg.%03d", idx)
        local thisSlot = bagSlot("nkUIBagSlot" .. idx, bagSlotsFrame, riftSlot)
        thisSlot:SetPoint("TOPLEFT", bagSlotsFrame, "TOPLEFT", (5 + ((idx - 1) * (ICONSIZE + ICONPADDING))) * data.bagScale, 5 * data.bagScale)
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

    local slots = LibEKL.Inventory.getBagSlots()

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