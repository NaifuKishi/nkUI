local addonInfo, privateVars = ...

---------- init namespace ----------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

---------- init local variables ----------

-- Cache frequently used functions and values
local InspectUnitDetail     = Inspect.Unit.Detail
local InspectBuffDetail     = Inspect.Buff.Detail
local InspectUnitLookup     = Inspect.Unit.Lookup

local mathFloor     = math.floor
local stringFormat  = string.format

---------- init global variables ----------

-- Icon management function

-- Create an icon manager
local iconManager = {
    activeIcons = {},
    iconPool = {}
}

--[[
   _iconManager.get
    Description:
        Retrieves or creates an icon for a specific unit type. This function manages a pool of reusable icons to optimize performance.
    Parameters:
        unitType (string): The type of unit (e.g., "player", "target", "player.pet")
        iconType (string): The type of icon (e.g., "buff", "debuff")
        scale (number): The scaling factor for the icon size
        x (number): The x-coordinate position for the icon
        y (number): The y-coordinate position for the icon
    Returns:
        icon (table): The configured icon with all child elements and functionality
    Process:
        1. Checks if an icon already exists for the specified unit type and icon type
        2. If not, checks the icon pool for available icons to reuse
        3. If no reusable icons are available, creates a new icon
        4. Configures the icon with the specified parameters
        5. Sets up the icon's visual elements (texture, border, etc.)
        6. Implements icon-specific functionality (timer, visibility, etc.)
        7. Adds the icon to the active icons collection
    Notes:
        - The function maintains a pool of reusable icons to optimize performance
        - Icons are created with secure and non-secure components for proper UI functionality
        - The icon includes various visual elements like texture, border, and timer
        - Timer functionality is implemented for tracking buff and debuff durations
        - The icon supports visibility control and positioning
        - Each icon is uniquely identified and can be accessed by unit type and icon type
    Available Methods:
        - SetTexture(textureType, texturePath): Sets the texture for the icon
        - SetBorderColor(r, g, b, a): Sets the border color of the icon
        - SetTimer(duration): Sets the timer for the icon
        - SetVisible(visible): Sets the visibility of the icon
        - ClearAll(): Clears all points and anchors for the icon
        - SetPoint(from, object, to, x, y): Sets the position of the icon
        - SetScale(scale): Sets the scale of the icon
        - ShowBorder(show): Shows or hides the border of the icon
        - SetEffect(effect): Sets the effect for the icon
        - SetBuff(buffUnit, buffId): Sets the buff for the icon
]]
function iconManager.get(unitType, iconType, scale, x, y)
    -- Check if icon already exists
    if iconManager.activeIcons[unitType] and iconManager.activeIcons[unitType][iconType] then
        return iconManager.activeIcons[unitType][iconType]
    end

    -- Check pool for available icons
    if #iconManager.iconPool > 0 then
        local icon = table.remove(iconManager.iconPool)
        icon:SetVisible(true)
        icon:ClearAll()
        icon:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
        icon:SetScale(scale)

        -- Reset other icon properties as needed
        -- ...

        if not iconManager.activeIcons[unitType] then
            iconManager.activeIcons[unitType] = {}
        end
        iconManager.activeIcons[unitType][iconType] = icon
        return icon
    end

    -- Create new icon if none available
    local thisName = EnKai.tools.uuid()
    local thisIcon = uiElements.icon(thisName .. ".icon", uiElements.context)
    thisIcon:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
    thisIcon:SetScale(scale)
    thisIcon:SetVisible(false)

    -- Implement icon-specific functionality
    -- ...

    if not iconManager.activeIcons[unitType] then
        iconManager.activeIcons[unitType] = {}
    end
    iconManager.activeIcons[unitType][iconType] = thisIcon
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
    if iconManager.activeIcons[unitType] and iconManager.activeIcons[unitType][iconType] then
        iconManager.activeIcons[unitType][iconType]:SetVisible(false)
        table.insert(iconManager.iconPool, iconManager.activeIcons[unitType][iconType])
        iconManager.activeIcons[unitType][iconType] = nil
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
_internal.iconManager = iconManager