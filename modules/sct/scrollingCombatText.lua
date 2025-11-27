local addonInfo, privateVars = ...

---------- init namespace ---------

local data      = privateVars.data
local uiElements= privateVars.uiElements
local _internal = privateVars.internal
local _events   = privateVars.events

local InspectTimeFrame          = Inspect.Time.Frame
local InspectAbilityNewDetail   = Inspect.Ability.New.Detail

local stringFind        = string.find
local stringMatch       = string.match
local stringFormat      = string.format

---------- init local variables ---------

local name = "scrollingcombattext"
local framePool = {}
local activeFrames = {}
local sctInit = false

local defaultSize = 24
local critSize = 32
local petID, petName   
local lastMessage, messageY = nil, 0

local abilityCache = {}
local abilityTimer = {}

local function createTextFrame()
    local frame = EnKai.uiCreateFrame("nkText", EnKai.tools.uuid(), uiElements.context)
    frame:SetEffectGlow({ strength = 1 })
    frame:SetVisible(false)
    return frame
end

local function getFrame()
    if #framePool > 0 then
        return table.remove(framePool)
    else
        return createTextFrame()
    end
end

local function releaseFrame(frame)
    frame:SetVisible(false)
    table.insert(framePool, frame)
end

local function displayMessageAtTopCenter(message, duration)
    
    local frame = getFrame()
    frame:SetText(message)
    frame:SetTextFont(addonInfo.id, "MontserratSemiBold")
    frame:SetFontSize(28)
    frame:SetFontColor(1, 1, 1, 1) -- White color
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, (-200 * data.uiScaleY) + messageY) -- Position at top center
    frame:SetVisible(true)

    lastMessage = frame:GetName()
    messageY = messageY - 20

    local start = InspectTimeFrame()

    local animationCoroutine = coroutine.create(function()
        for idx = 1, duration * 100, 1 do
            local elapsed = InspectTimeFrame() - start
            if elapsed > duration then
                return 9999
            end
            coroutine.yield(idx)
        end
        
    end)

    local callBack = function()
        if frame:GetName() == lastMessage then
            lastMessage = nil
            messageY = 0
        end
        releaseFrame(frame)        
    end

    EnKai.coroutines.add({
        func = animationCoroutine,
        callBack = callBack,
        counter = duration * 100, -- Adjust counter based on duration
        active = true
    })
end

local function animateFrame(frame, text, x, y, inComing)

    frame:SetText(text)
    frame:SetVisible(true)

    local start = InspectTimeFrame()
    local duration = 1.5
    local startX, startY = x, y -100  -- Center of the screen
    local startAngle = math.rad(45)  -- Start at lower-left
    local endAngle = math.rad(-45)     -- End at upper-right

    if inComing == true then
        startAngle = math.rad(135)  -- Start at lower-right
        endAngle = math.rad(225)    -- End at upper-left
    end

    local radius = 200

    local animationCoroutine = coroutine.create(function ()
        for idx = 1, 200, 1 do
            local elapsed = InspectTimeFrame() - start
            if elapsed > duration then
                return 9999
            end
            local t = elapsed / duration
            -- Interpolate the angle
            local currentAngle = startAngle + (endAngle - startAngle) * t
            -- Calculate offsets using the interpolated angle
            local currentXOffset = radius * math.cos(currentAngle)
            local currentYOffset = radius * math.sin(currentAngle)
            -- Apply the arc movement relative to the center of the screen, starting at Y = 100
            frame:SetPoint("CENTER", UIParent, "CENTER", startX + currentXOffset, startY + currentYOffset + 100)
            coroutine.yield(idx)
        end
    end)
    local callBack = function ()
        releaseFrame(frame)
    end
    EnKai.coroutines.add({ func = animationCoroutine, callBack = callBack, counter = 200, active = true })
end


local function displayText(sctText, isPet, inComing, type)

    local xVariation = math.random(0, 50)
    if inComing then xVariation = math.random(0, -50) end 

    local yVariation = math.random(-50, 50)

    local text = sctText

    if isPet and not inComing then
        xVariation = xVariation + 100 
        text = stringFormat("%s: %s", petName, sctText)
    end

    local frame = getFrame()

    if stringFind (type, ".crit") then
        frame:SetTextFont(addonInfo.id, "MontserratBold")
        
        if isPet then
            frame:SetFontSize(critSize * .8)
        else
            frame:SetFontSize(critSize)
        end
    else
        frame:SetTextFont(addonInfo.id, "MontserratSemiBold")
        if isPet then
            frame:SetFontSize(defaultSize * .8)
        else
            frame:SetFontSize(defaultSize)
        end
    end

    if stringFind (type, "damage") then
        local damageType = stringMatch(type, "^damage%.crit%.([^%.]+)$")
        if not damageType then
            damageType = stringMatch(type, "^damage%.([^%.]+)$")
        end

        if inComing then 
            frame:SetFontColor(1, 0, 0, 1) -- Red
        elseif damageType == "life" then            
            frame:SetFontColor(0, .5, 0, 1) -- Green
        elseif damageType == "death" then
            frame:SetFontColor(0.5, 0, 0.5, 1) -- Purple
        elseif damageType == "air" then
            frame:SetFontColor(0.5, 0.5, 1, 1) -- Light Blue
        elseif damageType == "earth" then
            frame:SetFontColor(0.5, 0.3, 0, 1) -- Brown
        elseif damageType == "fire" then
            frame:SetFontColor(1, 0.5, 0, 1) -- Orange
        elseif damageType == "water" then
            frame:SetFontColor(0, 0.5, 1, 1) -- Blue
        else
            frame:SetFontColor(1, 1, 1, 1) -- White
        end
    else
        if type == "immune" or type == "resist" then
            frame:SetFontColor(1, 1, 0, 1) -- Yellow        
        elseif type == "heal" then
            frame:SetFontColor(0, 1, 0, 1) -- Green
        else
            frame:SetFontColor(1, 1, 1, 1) -- White
        end
    end

    animateFrame(frame, text, xVariation, yVariation, inComing)
end

local function _validEvent (info)

    --- check outgoing

    if info.caster == data.playerID then return true, false, false end    
    if petID ~= nil and info.caster == petID then 
        if info.target == data.playerID then 
            return true, true, true
        else
            return true, true, false 
        end
    end

    localUnitsTypes = EnKai.unit.getUnitTypes (info.caster) 
    
    if EnKai.tools.table.isMember (localUnitsTypes, "player.pet") then
        petID = info.caster
        petName = _internal.shortenName (info.casterName, 10)
        return true, true, false
    end

    --- check incoming

    if info.target == data.playerID then return true, false, true end
    
    return false, false, false

end

local function _fctEventCombatDamage(_, info)
    
    local valid, isPet, isIncoming = _validEvent (info)
    if valid == false then return end

    local damageText = string.format("-%d", info.damage)

    -- Check for critical hit
    if info.crit then
        damageText = damageText .. " (Crit)"
    end

    -- Check for additional damage information
    if info.damageAbsorbed then
        damageText = damageText .. string.format(" [%d Absorbed]", info.damageAbsorbed)
    end

    if info.damageBlocked then
        damageText = damageText .. string.format(" [%d Blocked]", info.damageBlocked)
    end

    if info.damageIntercepted then
        damageText = damageText .. string.format(" [%d Intercepted]", info.damageIntercepted)
    end

    if info.damageModified then
        damageText = damageText .. string.format(" [%d Modified]", info.damageModified)
    end

    if info.overkill then
        damageText = damageText .. string.format(" [%d Overkill]", info.overkill)
    end

    if isIncoming then
        damageText = stringFormat("[%s] %s", EnKai.unit.GetUnitDetail (info.caster).name, damageText)
    end

    local frame = getFrame()

    -- If it's a critical hit, make the font larger and yellow
    if info.crit then        
        displayText(damageText, isPet, isIncoming, string.format("damage.%s.crit", info.type))
    else
        displayText(damageText, isPet, isIncoming, string.format("damage.%s", info.type))
    end
    
end

local function _fctEventCombatDodge(_, info)

   local valid, isPet, isIncoming = _validEvent (info)
    if valid == false then return end

    local dodgeText = "Dodge"
    displayText(dodgeText, isPet, isIncoming, "dodge")
end

local function _fctEventCombatImmune(_, info)
    local valid, isPet, isIncoming = _validEvent (info)
    if valid == false then return end

    local immuneText = "Immune"
    displayText(immuneText, isPet, isIncoming, "immune")
end

local function _fctEventCombatMiss(_, info)
    local valid, isPet, isIncoming = _validEvent (info)
    if valid == false then return end

    local missText = "Miss"
    displayText(missText, isPet, isIncoming, "miss")
end

local function _fctEventCombatParry(_, info)
    local valid, isPet, isIncoming = _validEvent (info)
    if valid == false then return end

    local parryText = "Parry"
    displayText(parryText, isPet, isIncoming, "parry")
end

local function _fctEventCombatResist(_, info)
    local valid, isPet, isIncoming = _validEvent (info)
    if valid == false then return end

    local resistText = "Resist"
    displayText(resistText, isPet, isIncoming, "resist")
end

local function _fctEventCombatHeal(_, info)

    local valid, isPet, isIncoming = _validEvent (info)

    if valid == false then return end
    
    if info.heal == nil and info.overheal == nil then  return end

    local healText 

    if info.overheal then
        healText = string.format("Overheal: %d", info.overheal)
    else
        healText = string.format("+%d", info.heal)
    end
    
    displayText(healText, isPet, isIncoming, "heal")
end

function _fctEventCooldownStart (_, info)

    local abilities = {}
    local newAbilities = false

    for k, v in pairs (info) do
        if v >= 1 then
            if abilityCache[k] == nil then -- ignore global cooldown
                abilities[k] = true
                newAbilities = true
            end
            
            abilityTimer[k] = InspectTimeFrame()
        end
    end

    if newAbilities == false then return end

    local details = InspectAbilityNewDetail(abilities)

    for k, v in pairs (details) do
        abilityCache[k] = v
    end

end

function _fctEventCooldownEnd (_, info)

    for key, details in pairs (info) do
        if abilityCache[key] ~= nil and InspectTimeFrame() - abilityTimer[key] >= 10 then
            abilityTimer[key] = nil
            displayMessageAtTopCenter(stringFormat("%s ready", abilityCache[key].name), 1.5)
        end
    end

end

function _internal.sctInit()
    Command.Event.Attach(Event.Combat.Damage, _fctEventCombatDamage, "nkUI.SCT.Combat.Damage")
    Command.Event.Attach(Event.Combat.Dodge, _fctEventCombatDodge, "nkUI.SCT.Combat.Dodge")
    Command.Event.Attach(Event.Combat.Immune, _fctEventCombatImmune, "nkUI.SCT.Combat.Immune")
    Command.Event.Attach(Event.Combat.Miss, _fctEventCombatMiss, "nkUI.SCT.Combat.Miss")
    Command.Event.Attach(Event.Combat.Parry, _fctEventCombatParry, "nkUI.SCT.Combat.Parry")
    Command.Event.Attach(Event.Combat.Resist, _fctEventCombatResist, "nkUI.SCT.Combat.Resist")
    Command.Event.Attach(Event.Combat.Heal, _fctEventCombatHeal, "nkUI.SCT.Combat.Heal")

    Command.Event.Attach(Event.Ability.New.Cooldown.Begin, _fctEventCooldownStart, "nkUI.SCT.Ability.New.Cooldown.Begin")
    Command.Event.Attach(Event.Ability.New.Cooldown.End, _fctEventCooldownEnd, "nkUI.SCT.Ability.New.Cooldown.End")

    sctInit = true
end


function _internal.sctToggle(value)

    if value then
        if sctInit then return end
        _internal.sctInit()
    else
        if sctInit == false then return end

        Command.Event.Detach(Event.Combat.Damage, nil, "nkUI.SCT.Combat.Damage")
        Command.Event.Detach(Event.Combat.Dodge, nil, "nkUI.SCT.Combat.Dodge")
        Command.Event.Detach(Event.Combat.Immune, nil, "nkUI.SCT.Combat.Immune")
        Command.Event.Detach(Event.Combat.Miss, nil, "nkUI.SCT.Combat.Miss")
        Command.Event.Detach(Event.Combat.Parry, nil, "nkUI.SCT.Combat.Parry")
        Command.Event.Detach(Event.Combat.Resist, nil, "nkUI.SCT.Combat.Resist")
        Command.Event.Detach(Event.Combat.Heal, nil, "nkUI.SCT.Combat.Heal")

        Command.Event.Detach(Event.Ability.New.Cooldown.Begin, nil, "nkUI.SCT.Ability.New.Cooldown.Begin")
        Command.Event.Detach(Event.Ability.New.Cooldown.End, nil, "nkUI.SCT.Ability.New.Cooldown.End")

        sctInit = false

    end

end