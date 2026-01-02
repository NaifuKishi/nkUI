local addonInfo, privateVars = ...

---------- init namespace ----------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local _events       = privateVars.events

---------- init local variables ----------

-- Cache frequently used functions and values
local InspectUnitDetail     = Inspect.Unit.Detail
local InspectBuffDetail     = Inspect.Buff.Detail
local InspectUnitLookup     = Inspect.Unit.Lookup

local mathFloor     = math.floor
local stringFormat  = string.format

local LibEKLToolsUUID = LibEKL.Tools.UUID


local context = UI.CreateContext("nkUI.buffIcons")
context:SetStrata('hud')
context:SetLayer(2)

---------- init global variables ----------

-- Icon management function

-- Create an icon manager
local iconManager = {
    activeIcons = {},
    iconPool = {}
}

function iconManager.get(unitType, iconType)

    local activeIcons = iconManager.activeIcons[unitType]

    -- Check if icon already exists
    if activeIcons and activeIcons[iconType] then
        return activeIcons[iconType]
    end

    -- Check pool for available icons
    if #iconManager.iconPool > 0 then
        local icon = table.remove(iconManager.iconPool)
        icon:SetVisible(true)
        icon:ClearAll()

        if not activeIcons then activeIcons = {} end
        activeIcons[iconType] = icon
        return icon
    end

    -- Create new icon if none available
    local thisName = LibEKLToolsUUID()
    local thisIcon = uiElements.icon(thisName .. ".icon", context)
    thisIcon:SetVisible(false)

    if not activeIcons then activeIcons = {} end
    activeIcons[iconType] = thisIcon
    return thisIcon
end

--[[
   _iconManager.release
    Description:
        Releases an icon back to the pool for potential reuse. This function is used to manage the lifecycle of icons.
    Parameters:
        unitType (string): The type of unit associated with the icon
        iconType (string): The type of icon (e.g., "buff", "debuff")
    Process:
        1. Checks if the icon exists in the active icons collection
        2. If found, hides the icon and adds it to the icon pool
        3. Removes the icon from the active icons collection
    Notes:
        - This function is useful for managing the lifecycle of icons
        - Icons are returned to the pool for potential reuse
        - The active icons collection is updated after processing
]]
function iconManager.release(unitType, iconType)
    local activeIcons = iconManager.activeIcons[unitType]

    if activeIcons and activeIcons[iconType] then
        activeIcons[iconType]:SetVisible(false)
        table.insert(iconManager.iconPool, activeIcons[iconType])
        activeIcons[iconType] = nil
    end
end

--[[
   _iconManager.clearAll
    Description:
        Clears all active icons and returns them to the pool. This function is used to reset the icon manager.
    Process:
        1. Iterates through all active icons
        2. Hides each icon and adds it to the icon pool
        3. Clears the active icons collection
    Notes:
        - This function is useful for resetting the UI state
        - All icons are returned to the pool for potential reuse
        - The active icons collection is emptied after processing
]]
function iconManager.clearAll()

    for unitType, icons in pairs(iconManager.activeIcons) do
        for iconType, icon in pairs(icons) do
            icon:SetVisible(false)
            table.insert(iconManager.iconPool, icon)
        end
    end
    
    iconManager.activeIcons = {}
end

--[[
   _iconManager.clearUnitType
    Description:
        Clears all icons associated with a specific unit type. This function is used to reset the UI state for a particular unit.
    Parameters:
        unitType (string): The type of unit for which to clear all icons
    Process:
        1. Checks if the unit type exists in the active icons collection
        2. If found, iterates through all icons for that unit type
        3. Hides each icon and adds it to the icon pool
        4. Removes the unit type entry from the active icons collection
    Notes:
        - This function is useful for resetting the UI state for a specific unit
        - All icons for the specified unit type are returned to the pool for potential reuse
        - The active icons collection is updated after processing
]]
function iconManager.clearUnitType(unitType)
    if iconManager.activeIcons[unitType] then
        for iconType, icon in pairs(iconManager.activeIcons[unitType]) do
            icon:SetVisible(false)
            table.insert(iconManager.iconPool, icon)
        end
        iconManager.activeIcons[unitType] = nil
    end
end

-- Expose the icon manager to the internal namespace
internalFunc.iconManager = iconManager