local addonInfo, privateVars = ...

-- Initialize namespace
local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events

-- Cache frequently used functions and values
local InspectAbilityNewList     = Inspect.Ability.New.List
local InspectAbilityNewDetail   = Inspect.Ability.New.Detail
local InspectTimeFrame          = Inspect.Time.Frame

local mathFloor                 = math.floor

-- init local variables
local cdInit = false
local activeCooldowns = {}

-- Creates a visual element for displaying a cooldown
-- @param abilityId The ID of the ability this cooldown represents
-- @return Table containing the cooldown display elements
local function createCooldownElement(abilityId)
    local cooldown = {
        abilityId = abilityId,
        frame = nil,
        element = nil,
        bar = nil,
        timer = nil
    }

    -- Create main frame for the cooldown display
    cooldown.frame = EnKai.uiCreateFrame("nkTexture", "nkUI.cooldown." .. abilityId, uiElements.contextDialog)
    cooldown.frame:SetWidth(40)
    cooldown.frame:SetHeight(40)

    -- Create element to display the ability icon
    cooldown.element = EnKai.uiCreateFrame("nkTexture", "nkUI.cooldown.element." .. abilityId, cooldown.frame)
    cooldown.element:SetPoint("CENTER", cooldown.frame, "CENTER")
    cooldown.element:SetWidth(40)
    cooldown.element:SetHeight(40)
    cooldown.element:SetLayer(1)

    -- Create progress bar for the cooldown
    cooldown.bar = EnKai.uiCreateFrame("nkFrame", "nkUI.cooldown.bar." .. abilityId, cooldown.frame)
    cooldown.bar:SetWidth(100)
    cooldown.bar:SetHeight(5)
    cooldown.bar:SetPoint("TOPLEFT", cooldown.frame, "BOTTOMLEFT", 0, 0)
    cooldown.bar:SetBackgroundColor(1, 0, 0, 1)
    cooldown.bar:SetLayer(2)

    -- Create timer text for the cooldown
    cooldown.timer = EnKai.uiCreateFrame("nkText", "nkUI.cooldown.timer." .. abilityId, cooldown.frame)
    cooldown.timer:SetPoint("CENTER", cooldown.frame, "CENTER", 0, 0)
    cooldown.timer:SetFontSize(16)
    cooldown.timer:SetTextFont(addonInfo.id, "MontserratSemiBold")
    cooldown.timer:SetEffectGlow({strength = 2})
    cooldown.timer:SetLayer(3)

    -- Sets the icon for the cooldown display
    -- @param icon The icon to display
    function cooldown:SetIcon(icon)
        cooldown.element:SetTextureAsync("Rift", icon)
    end

    return cooldown
end

-- Sorts active cooldowns by remaining time
-- @return Table of sorted cooldowns
local function sortCooldownsByRemainingTime()
    local sortedCooldowns = {}

    for _, cooldown in pairs(activeCooldowns) do
        table.insert(sortedCooldowns, cooldown)
    end

    table.sort(sortedCooldowns, function(a, b)
        local aRemaining = a.duration - (InspectTimeFrame() - a.start)
        local bRemaining = b.duration - (InspectTimeFrame() - b.start)
        return aRemaining > bRemaining
    end)

    return sortedCooldowns
end

-- Updates the visual display of a cooldown
-- @param cooldown The cooldown to update
local function updateCooldownBar(cooldown)
    local remainingTime = cooldown.duration - (InspectTimeFrame() - cooldown.start)

    if remainingTime <= 0 then
        return
    end
    
    local progress = remainingTime / cooldown.duration
    cooldown.display.bar:SetWidth(100 * progress)

    -- Change color based on remaining time
    if progress < 0.5 then
        cooldown.display.bar:SetBackgroundColor(1, 0, 0, 1) -- Red
    elseif progress < 0.8 then
        cooldown.display.bar:SetBackgroundColor(1, 0.65, 0, 1) -- Orange
    else
        cooldown.display.bar:SetBackgroundColor(0, 1, 0, 1) -- Green
    end
    
    -- Display remaining time in minutes
    local minutes = mathFloor(remainingTime / 60)
    cooldown.display.timer:SetText(string.format("%d", minutes))
end

-- Updates the display of all active cooldowns
local function updateCooldownDisplay()
    local sortedCooldowns = sortCooldownsByRemainingTime()
    local yOffset = 1150

    for i, cooldown in ipairs(sortedCooldowns) do
        cooldown.display.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 1000, yOffset)
        yOffset = yOffset + 45  -- 40 (height) + 5 (spacing)
        updateCooldownBar(cooldown)
    end
end

-- Updates all cooldown displays
local function updateAllCooldowns()
    for _, cooldown in pairs(activeCooldowns) do
        updateCooldownBar(cooldown)
    end
end

-- Adds new cooldowns to the active cooldowns list
-- @param newCooldowns Table of new cooldowns to add
local function addCooldown(_, newCooldowns)
    for k, v in pairs(newCooldowns) do
        if v > 600 then  -- Only show cooldowns longer than 10 minutes
            local display = createCooldownElement(k)
            local details = InspectAbilityNewDetail(k)
            display:SetIcon(details.icon)
            activeCooldowns[k] = {
                display = display,
                start = InspectTimeFrame(),
                duration = v
            }
        end
    end

    updateCooldownDisplay()
end

-- Removes cooldowns from the active cooldowns list
-- @param cooldowns Table of cooldowns to remove
local function removeCooldown(_, cooldowns)
    for k, v in pairs(cooldowns) do
        if activeCooldowns[k] then
            activeCooldowns[k].display.frame:Destroy()
            activeCooldowns[k] = nil
        end
    end
end

-- Clears all active cooldowns
local function clearAllCooldowns()
    for _, cooldown in pairs(activeCooldowns) do
        cooldown.display.frame:Destroy()
    end
    activeCooldowns = {}
end

-- Initializes the cooldown system
function internalFunc.cooldownInit()
    local abilities = InspectAbilityNewList()
    local details = InspectAbilityNewDetail(abilities)

    for k, v in pairs(details) do
        if v.currentCooldownRemaining and v.cooldown then
            if v.currentCooldownRemaining > 0 and v.cooldown > 600 then
                local display = createCooldownElement(k)            
                display:SetIcon(v.icon)
                activeCooldowns[k] = {
                    display = display,
                    start = v.currentCooldownBegin,
                    duration = v.currentCooldownDuration
                }
            end
        end
    end

    updateCooldownDisplay()

    -- Register event handlers
    Command.Event.Attach(Event.Ability.New.Cooldown.Begin, addCooldown, "nkUI.cooldowns.Ability.New.Cooldown.Begin")
    Command.Event.Attach(Event.Ability.New.Cooldown.End, removeCooldown, "nkUI.cooldowns.Ability.New.Cooldown.End")

    cdInit = true
end