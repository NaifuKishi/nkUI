local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

---------- init local variables ---------

local InspectAbilityNewList     = Inspect.Ability.New.List
local InspectAbilityNewDetail   = Inspect.Ability.New.Detail
local InspectTimeFrame          = Inspect.Time.Frame

local mathFloor                 = math.floor

local cdInit = false
local activeCooldowns = {}

local function createCooldownElement(abilityId)
    local cooldown = {
        abilityId = abilityId,
        frame = nil,
        element = nil,
        bar = nil,
        timer = nil
    }

    cooldown.frame = EnKai.uiCreateFrame("nkTexture", "nkUI.cooldown." .. abilityId, uiElements.context)
    cooldown.frame:SetWidth(40)
    cooldown.frame:SetHeight(40)

    cooldown.element = EnKai.uiCreateFrame("nkTexture", "nkUI.cooldown.element." .. abilityId, cooldown.frame)
    cooldown.element:SetPoint("CENTER", cooldown.frame, "CENTER")
    cooldown.element:SetWidth(40)
    cooldown.element:SetHeight(40)
    cooldown.element:SetLayer(1)
    --cooldown.element:SetBackgroundTexture(EnKai.tools.getIcon(abilityId))

    cooldown.bar = EnKai.uiCreateFrame("nkFrame", "nkUI.cooldown.bar." .. abilityId, cooldown.frame)
    cooldown.bar:SetWidth(100)
    cooldown.bar:SetHeight(5)
    cooldown.bar:SetPoint("TOPLEFT", cooldown.frame, "BOTTOMLEFT", 0, 0)
    cooldown.bar:SetBackgroundColor(1, 0, 0, 1)
    cooldown.bar:SetLayer(2)

    cooldown.timer = EnKai.uiCreateFrame("nkText", "nkUI.cooldown.timer." .. abilityId, cooldown.frame)
    cooldown.timer:SetPoint("CENTER", cooldown.frame, "CENTER", 0, 0)
    cooldown.timer:SetFontSize(16)
    cooldown.timer:SetTextFont(addonInfo.id, "MontserratSemiBold")
    cooldown.timer:SetEffectGlow({strength = 2})
    cooldown.timer:SetLayer(3)

    function cooldown:SetIcon(icon)
        cooldown.element:SetTextureAsync("Rift", icon)
    end

    return cooldown
end

local function sortCooldownsByRemainingTime()
    
    local sortedCooldowns = {}

    for _, cooldown in pairs(activeCooldowns) do
        table.insert(sortedCooldowns, cooldown)
    end

    table.sort(sortedCooldowns, function(a, b)
        local aRemaining = a.duration
        local bRemaining = b.duration
        return aRemaining > bRemaining
    end)

    return sortedCooldowns
end

local function updateCooldownBar(cooldown)

    local cooldownTime = cooldown.duration
    local remainingTime = cooldown.duration - (InspectTimeFrame() - cooldown.start)

    if remainingTime <= 0 then
        --removeCooldown(_, { cooldown)
        return
    end

    local progress = remainingTime / cooldownTime
    cooldown.display.bar:SetWidth(100 * progress)

    if progress < 0.5 then
        cooldown.display.bar:SetBackgroundColor(1, 0, 0, 1)
    elseif progress < 0.8 then
        cooldown.display.bar:SetBackgroundColor(1, 0.65, 0, 1)
    else
        cooldown.display.bar:SetBackgroundColor(0, 1, 0, 1)
    end

    local minutes = mathFloor(remainingTime / 60)    
    cooldown.display.timer:SetText(string.format("%d", minutes))
end


local function updateCooldownDisplay()
    local sortedCooldowns = sortCooldownsByRemainingTime()
    local yOffset = 1150

    for i, cooldown in ipairs(sortedCooldowns) do
        cooldown.display.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 1000, yOffset)
        yOffset = yOffset + 45  -- 40 (height) + 5 (spacing)
        updateCooldownBar(cooldown)
    end
end


local function updateAllCooldowns()
    for _, cooldown in pairs(cooldowns) do
        updateCooldownBar(cooldown)
    end
end

local function addCooldown(_, newCooldowns)

    for k, v in pairs(newCooldowns) do
        if v > 600 then
            local display = createCooldownElement(k)            
            local details = InspectAbilityNewDetail(k)
            display:SetIcon(details.icon)
            activeCooldowns[k] = { display = display, start = InspectTimeFrame(), duration = v }
        end
    end

    updateCooldownDisplay()
end

local function removeCooldown(_, cooldowns)
    for k, v in pairs(cooldowns) do
        if activeCooldowns[k] then
            table.insert(freeCooldownDisplayes, cooldowns[k].display)
            activeCooldowns[k] = nil
        end
    end
end

local function clearAllCooldowns()
    for _, cooldown in ipairs(activeCooldowns) do
        cooldown.timer:Destroy()
        cooldown.bar:Destroy()
        cooldown.element:Destroy()
        cooldown.frame:Destroy()
    end
    activeCooldowns = {}
end

function _internal.cooldownInit()

    local abilities = InspectAbilityNewList()
    local details = InspectAbilityNewDetail(abilities)

    local checkCooldowns = {}

    for k, v in pairs(details) do
        if v.currentCooldownRemaining and v.cooldown then
            if v.currentCooldownRemaining > 0 and v.cooldown > 600 then
                
                local display = createCooldownElement(k)            
                display:SetIcon(v.icon)
                activeCooldowns[k] = { display = display, start = v.currentCooldownBegin, duration = v.currentCooldownDuration }

            end
        end
    end

    updateCooldownDisplay()

    Command.Event.Attach(Event.Ability.New.Cooldown.Begin, addCooldown, "nkUI.cooldowns.Ability.New.Cooldown.Begin")
    Command.Event.Attach(Event.Ability.New.Cooldown.End, removeCooldown, "nkUI.cooldowns.Ability.New.Cooldown.End")

    cdInit = true

end