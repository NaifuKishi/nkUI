-- @module events
-- @description Event handlers for the action bar module
-- @version 1.0

--[[
  This module handles various game events related to the action bar.
  It manages buffs, ability states, cooldowns, and secure mode changes.
]]

local addonInfo, privateVars = ...

-- Initialize namespace

local data         	= privateVars.data
local uiElements   	= privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events      	= privateVars.events

-- Cache frequently used functions and values

local inspectAbilityNewDetail  = Inspect.Ability.New.Detail

local mathFloor                = math.floor

-- init local variables

local stanceBuff = nil

-- init global variables

data.activeCooldowns = {}


-- Helper function to update ability states
-- @param abilityId The ID of the ability to update
-- @param updateFunc Function to apply to each ability frame
local function updateAbilityStates(abilityId, updateFunc)
    
    local debugId = internalFunc.traceStart("actionbar.updateAbilityStates")

    if data.abilityMap and data.abilityMap[abilityId] then
        for _, frame in pairs(data.abilityMap[abilityId]) do
            updateFunc(frame)
        end
    end

    internalFunc.traceEnd("actionbar.updateAbilityStates", debugId)
end

-- Event handler for when a buff is added to a unit
-- @param unit The unit that gained the buff
-- @param info Table containing buff information
function events.abBuffAdd(_, unit, info)
    if not internalFunc.isPlayerUnit(unit) then return end
    
    local debugId = internalFunc.traceStart("actionbar.buffAdd")
    
    for key, v in pairs(info) do
        if v == 'B109B81E0E0F231CF' or v == 'B55F770C673BE8384' then
            stanceBuff = key
            internalFunc.stanceActive(true)
            internalFunc.traceEnd("buffAdd", debugId)
            return
        end
    end
    
    internalFunc.traceEnd("actionbar.buffAdd", debugId)
end

-- Event handler for when a buff is removed from a unit
-- @param unit The unit that lost the buff
-- @param info Table containing buff information
function events.abBuffRemove(_, unit, info)
    if not internalFunc.isPlayerUnit(unit) then return end
    
    local debugId = internalFunc.traceStart("actionbar.buffRemove")
    
    for key, v in pairs(info) do
        if key == stanceBuff then
            stanceBuff = nil
            internalFunc.stanceActive(false)
            internalFunc.traceEnd("buffRemove", debugId)
            return
        end
    end
    
    internalFunc.traceEnd("actionbar.buffRemove", debugId)
end

-- Event handler for abilities becoming unusable
-- @param info Table containing ability information
function events.abAbilityUnusable(_, info)
    if not data.abilityMap then return end
    
    local debugId = internalFunc.traceStart("actionbar.abilityUnusable")
    
    for key, v in pairs(info) do
        updateAbilityStates(key, function(frame) frame:SetUsable(false) end)
    end
    
    internalFunc.traceEnd("actionbar.abilityUnusable", debugId)
end

-- Event handler for abilities becoming usable
-- @param info Table containing ability information
function events.abAbilityUsable(_, info)
    if not data.abilityMap then return end
    
    local debugId = internalFunc.traceStart("actionbar.abilityUsable")
    
    for key in pairs(info) do
        updateAbilityStates(key, function(frame) frame:SetUsable(true) end)
    end
    
    internalFunc.traceEnd("actionbar.abilityUsable", debugId)
end

-- Event handler for abilities going out of range
-- @param info Table containing ability information
function events.abAbilityOutOfRange(_, info)
    if not data.abilityMap then return end

    local debugId = internalFunc.traceStart("actionbar.abilityOutOfRange")

    for key in pairs(info) do
        updateAbilityStates(key, function(frame) frame:SetOOR(true) end)
    end

    internalFunc.traceEnd("actionbar.abilityOutOfRange", debugId)
end

-- Event handler for abilities coming into range
-- @param info Table containing ability information
function events.abAbilityInRange(_, info)
    if not data.abilityMap then return end
    
    local debugId = internalFunc.traceStart("actionbar.abilityInRange")

    for key in pairs(info) do
        updateAbilityStates(key, function(frame) frame:SetOOR(false) end)
    end

    internalFunc.traceEnd("actionbar.abilityInRange", debugId)
end

-- Event handler for ability cooldown progress
-- @param addon The addon triggering the event
-- @param info Table containing cooldown information
function events.abCooldownProcess(_, addon, info)
    local debugId = internalFunc.traceStart("actionbar.cooldownProcess")

    if addon ~= addonInfo.id then
        internalFunc.traceEnd("actionbar.cooldownProcess", debugId)
        return -- the event is fired for every addon which subscribed
    end

    local abilityMap = data.abilityMap
    
    if abilityMap then
        for key, details in pairs(info) do
            if abilityMap[key] then

                local duration, remaining = details.duration, details.remaining
                local percent = duration and remaining and (1 / duration * remaining) or nil

                if not remaining or remaining < 0 then
                    updateAbilityStates(key, function(frame) frame:SetCooldown() end)
                elseif remaining <= 1 then
                    updateAbilityStates(key, function(frame) frame:SetCooldown(tostring(mathFloor(remaining)), percent) end)
                elseif remaining > 14400 then
                    updateAbilityStates(key, function(frame) frame:SetCooldown() end)
                elseif remaining > 3600 then
                    updateAbilityStates(key, function(frame) frame:SetCooldown(tostring(mathFloor(remaining / 3600)) .. "h", percent) end)
                elseif remaining > 60 then
                    updateAbilityStates(key, function(frame) frame:SetCooldown(tostring(mathFloor(remaining / 60)) .. "m", percent) end)
                else
                    updateAbilityStates(key, function(frame) frame:SetCooldown(tostring(mathFloor(remaining)), percent) end)
                end
            end
        end
    end

    internalFunc.traceEnd("actionbar.cooldownProcess", debugId)
end

-- Event handler for entering secure mode
-- @param info Table containing secure mode information
function events.abSecureEnter(_, info)
    local debugId = internalFunc.traceStart("actionbar.secureEnter")

    for _, actionBar in pairs(uiElements.actionbars) do
        actionBar:SetAlpha(nkUISetup.modules.actionBars.combatAlpha)
        actionBar:ResetStates()
    end

    internalFunc.traceEnd("actionbar.secureEnter", debugId)
end

-- Event handler for leaving secure mode
-- @param info Table containing secure mode information
function events.abSecureLeave(_, info)
    
    local debugId = internalFunc.traceStart("actionbar.secureLeave")

    for _, actionBar in pairs(uiElements.actionbars) do
        actionBar:SetAlpha(nkUISetup.modules.actionBars.nonCombatAlpha)
    end

    internalFunc.traceEnd("actionbar.secureLeave", debugId)
end

-- Event handler for GCD (Global Cooldown) start
-- @param info Table containing GCD information
function events.abGcdStart(_, info)

    local debugId = internalFunc.traceStart("actionbar.abGcdStart")

    for key, remaining in pairs(info) do
        if data.abilityMap and data.abilityMap[key] and remaining <= 1.5 then
            data.gcdActive = { flag = true, key = key }
            updateAbilityStates(key, function(frame) frame:SetGCD(remaining) end)
        end
    end

    internalFunc.traceEnd("actionbar.abGcdStart", debugId)
end

--[[
-- Adjusts action bar transparency when entering secure mode
function events.abSecureEnter()
    for _, actionBar in pairs(uiElements.actionbars) do
        actionBar:SetAlpha(nkUISetup.modules.actionBars.combatAlpha)
    end
end

-- Adjusts action bar transparency when leaving secure mode
function events.abSecureLeave()
    for _, actionBar in pairs(uiElements.actionbars) do
        actionBar:SetAlpha(nkUISetup.modules.actionBars.nonCombatAlpha)
    end
end
]]
