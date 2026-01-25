local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.sct = {}

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events
local sct           = privateVars.sct

---------- init local variables ---------

local inspectTimeFrame          = Inspect.Time.Frame
local inspectAbilityNewDetail   = Inspect.Ability.New.Detail
local inspectAbilityDetail      = Inspect.Ability.Detail
local inspectExperience         = Inspect.Experience
local inspectAttunementProgress = Inspect.Attunement.Progress

local LibEKLUnitGetUnitDetail    = LibEKL.Unit.GetUnitDetail

local stringFind        = string.find
local stringFormat      = string.format

local mathRandom        = math.random
local mathCos           = math.cos
local mathSin           = math.sin
local mathRad           = math.rad

---------- init variables ---------

local TEXT_RESIST = "<font color='#ffffff'>Resist</font>"
local TEXT_PARRY = "<font color='#ffffff'>Parry</font>"
local TEXT_MISS = "<font color='#ffffff'>Miss</font>"
local TEXT_IMMUNE = "<font color='#ffffff'>Immune</font>"
local TEXT_DODGE = "<font color='#ffffff'>Dodge</font>"
local TEXT_OVERHEAL = "[%s] <font color='#00FF00'>%d OVERHEAL</font>"
local TEXT_HEAL = "[%s] <font color='#00FF00'>%d</font>"
local TEXT_DAMAGE = "<font color='%s'>%d %s</font>"
local TEXT_INCOMING = "<font color='#FF0000'>[%s]</font> %s"

local COLOR_CRIT = "#FFA500"
local COLOR_LIFE = "#4CAF50"
local COLOR_DEATH = "#9C27B0"
local COLOR_AIR = "#B0BEC5"
local COLOR_EARTH = "#795548"
local COLOR_FIRE = "#FF5722"
local COLOR_WATER = "#1976D2"    

local sctInit = false

local lastAccumulated = 0
local lastAttunementAccumulated = 0

local lastInventoryUpdate
local inventoryUpdateModY = 0

local abilityCache = {}
local iconCache = {}
local abilityTimer = {}

local petID = nil

---------- local functions ---------

-- Gets the ability icon for a given ability
-- @param info Table containing ability information
-- @return The ability icon path
local function getAbilityIcon(info)
    local icon, name
    local abilityNew = info.abilityNew
    local ability = info.ability

    if abilityNew == nil and ability == nil then return end

    if abilityNew ~= nil then
        if iconCache[abilityNew] == nil then
            local details = inspectAbilityNewDetail(abilityNew)
            if details then
                iconCache[abilityNew] = { icon = details.icon, name = details.name }
                icon = details.icon
                name = details.name
            end
        else
            icon = iconCache[abilityNew].icon
            name = iconCache[abilityNew].name
        end
    else
        if iconCache[ability] == nil then
            local details = inspectAbilityDetail(ability)
            if details then
                iconCache[ability] = { icon = details.icon, name = details.name }
                icon = details.icon
                name = details.name
            end
        else
            icon = iconCache[ability].icon
            name = iconCache[ability].name
        end
    end

    return icon, name
end

-- Animates a frame with combat text
-- @param frame The frame to animate
-- @param text The text to display
-- @param icon The icon to display
-- @param x The x position
-- @param y The y position
-- @param inComing Whether the damage is incoming
function sct.AnimateFrame(frame, text, icon, x, y, inComing)

    local debugId = internalFunc.traceStart("sct.sct.AnimateFrame")

    frame:SetText(text, true)
    frame:SetVisible(true)

    if icon then
        frame:SetTextureAsync("Rift", icon)
    else
        frame:SetTextureAsync(nil, nil)
    end

    local start = inspectTimeFrame()
    local duration = 1.5
    local startX, startY = x, y - 100
    local startAngle = mathRad(45)
    local endAngle = mathRad(-45)
    local coRoutineDebugID
    
    if inComing == true then
        startAngle = mathRad(135)
        endAngle = mathRad(225)
    end

    local radius = 200
    
    local animationCoroutine = coroutine.create(function()        

        for idx = 1, 200, 1 do
            coRoutineDebugID = internalFunc.traceStart("sct.cr.sct.AnimateFrame")

            local elapsed = inspectTimeFrame() - start
            if elapsed > duration then
                internalFunc.traceEnd("sct.cr.sct.AnimateFrame", coRoutineDebugID)
                return 9999
            end
            local t = elapsed / duration
            local currentAngle = startAngle + (endAngle - startAngle) * t
            local currentXOffset = radius * mathCos(currentAngle)
            local currentYOffset = radius * mathSin(currentAngle)

            frame:SetPoint("CENTER", UIParent, "CENTER", startX + currentXOffset, startY + currentYOffset + 100)
            internalFunc.traceEnd("sct.cr.sct.AnimateFrame", coRoutineDebugID)

            coroutine.yield(idx)
        end
    end)
    
    local callBack = function()
        sct.ReleaseFrame(frame)
        internalFunc.traceEnd("sct.cr.sct.AnimateFrame", coRoutineDebugID)
    end
    
    LibEKL.Coroutines.Add({
        func = animationCoroutine,
        callBack = callBack,
        counter = 200,
        active = true
    })

    internalFunc.traceEnd("sct.sct.AnimateFrame", debugId)
end

-- Validates combat events
-- @param info The combat event information
-- @return Whether the event is valid, whether it's from a pet, and whether it's incoming
local function validEvent(info)
    if info.caster == LibEKL.Unit.GetPlayerDetails().id then return true, false, false end

    if petID ~= nil and info.caster == petID then
        if info.target == LibEKL.Unit.GetPlayerDetails().id then
            return true, true, true
        else
            return true, true, false 
        end
    end
    
    local localUnitsTypes = LibEKL.Unit.GetUnitTypes(info.caster)
    
    if LibEKL.Tools.Table.IsMember(localUnitsTypes, "player.pet") then
        petID = info.caster
        if info.casterName then
            data.petName = internalFunc.shortenName(info.casterName, 10)
        end
        return true, true, false
    end

    if info.target == LibEKL.Unit.GetPlayerDetails().id then return true, false, true end
    
    return false, false, false
end

local damageQueue = {}  -- Queue to store damage events for throttling
local shortNames = {}

local function getDamageText (abilityName, info, isIncoming)

    local damageText = ""
    local realText = abilityName

    if info.hitCount or info.critCount then
        if info.hitCount > 0 and info.critCount > 0 then
            realText = stringFormat("%s (%d hits, %d, crits)", realText, info.hitCount, info.critCount)
        elseif info.hitCount > 1 then
            realText = stringFormat("%s (%d hits)", realText, info.hitCount)
        elseif info.critCount > 1 then
            realText = stringFormat("%s (%d crit)", realText, info.critCount)
        end
    end

    if info.crit then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_CRIT, info.damage, realText)        
    elseif info.type == "life" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_LIFE, info.damage, realText)
    elseif info.type == "death" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_DEATH, info.damage, realText)
    elseif info.type == "air" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_AIR, info.damage, realText)
    elseif info.type == "earth" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_EARTH, info.damage, realText)
    elseif info.type == "fire" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_FIRE, info.damage, realText)
    elseif info.type == "water" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_WATER, info.damage, realText)
    elseif info.damage ~= nil then
        damageText = stringFormat("%d %s", info.damage, realText)
    end

    if info.damageAbsorbed then
        damageText = stringFormat("%s [%d Absorbed]",damageText, info.damageAbsorbed)
    elseif info.damageBlocked then
        damageText = stringFormat("%s [%d Blocked]", damageText, info.damageBlocked)
    elseif info.damageIntercepted then
        damageText = stringFormat("%s [%d Intercepted]", damageText, info.damageIntercepted)
    elseif info.overkill then
        damageText = stringFormat("%s [%d Overkill]", damageText, info.overkill)
    end

    if isIncoming == true and info.caster then
        if not shortNames[info.caster] then
            local unitDetails = LibEKLUnitGetUnitDetail(info.caster)
            local thisName = ""
            if unitDetails then thisName = internalFunc.shortenName(unitDetails.name, 10) end
            shortNames[info.caster] = thisName
        end

        damageText = stringFormat(TEXT_INCOMING, shortNames[info.caster], damageText)
    end

    return damageText

end

-- Handles combat damage events
-- @param info The combat damage information
local function handleCombatDamage(self, info)
    
    if info.damage == nil then return end
    
    local queueEvent = false

    local valid, isPet, isIncoming = validEvent(info)
    if valid == false then return end

    local icon, abilityName = getAbilityIcon(info)
    if not abilityName then abilityName = "" end

    -- Create a unique key for this ability event
    local abilityKey = info.abilityNew or info.ability or "unknown"
    local eventTime = inspectTimeFrame()

    -- Initialize the queue for this ability if it doesn't exist
    if not damageQueue[abilityKey] then
        damageQueue[abilityKey] = {
            hitCount = 0,
            critCount = 0,
            info = info,
            coroutine = nil,
            initTime = eventTime,
            abilityName = abilityName,
            icon = icon,
            isIncoming = isIncoming,
            totalDamage = 0,
            isPet = isPet,
            type = info.type
        }    
    end

    if not info.damageAbsorbed and not info.damageBlocked and not info.damageIntercepted and not info.overkill then
        damageQueue[abilityKey].totalDamage = damageQueue[abilityKey].totalDamage + info.damage

        if info.crit then
            damageQueue[abilityKey].critCount = damageQueue[abilityKey].critCount + 1
        else
            damageQueue[abilityKey].hitCount = damageQueue[abilityKey].hitCount + 1
        end        
    else
        local damageText = getDamageText (abilityName, info, isIncoming)
        sct.DisplayText(damageText, icon, isPet, isIncoming, info.crit)
    end

    for abilityKey, queueInfo in pairs(damageQueue) do
        if eventTime - queueInfo.initTime >= 5 then
            damageQueue[abilityKey] = nil
        elseif eventTime - queueInfo.initTime >= .2 then

            local isCrit = false
            if queueInfo.critCount > 0 and queueInfo.hitCount == 0 then isCrit = true end

            local damageText = getDamageText (queueInfo.abilityName, {damage = queueInfo.totalDamage, critCount = queueInfo.critCount, hitCount = queueInfo.hitCount, type = queueInfo.type}, queueInfo.isIncoming)
            sct.DisplayText(damageText, queueInfo.icon, queueInfo.isPet, queueInfo.isIncoming, isCrit)
            damageQueue[abilityKey] = nil
        end        
    end

    -- the above is a try to queue events and combine. Works but didn't have any effect on performance.    

--    local damageText = getDamageText (abilityName, info, isIncoming)
--    sct.DisplayText(damageText, icon, isPet, isIncoming, info.crit)

end

-- Handles combat events
-- @param info The combat information
-- @param text The text to display
local function handleCombatEvent(info, text)
    local valid, isPet, isIncoming = validEvent(info)
    if valid == false then return end
    sct.DisplayText(text, nil, isPet, isIncoming)
end

-- Handles combat heal events
-- @param info The combat heal information
local function handleCombatHeal(self, info)

    local valid, isPet, isIncoming = validEvent(info)
    if valid == false then return end
    
    if info.heal == nil and info.overheal == nil then return end
    
    local icon = getAbilityIcon(info)
    local healText

    local realCaster = info.targetName
    if info.target == LibEKL.Unit.GetPlayerID() then realCaster = info.casterName end

    if info.overheal then
        healText = stringFormat(TEXT_OVERHEAL, internalFunc.shortenName(realCaster, 10), info.overheal)
        sct.DisplayText(healText, icon, isPet, true, "overheal", false)
    else
        healText = stringFormat(TEXT_HEAL, internalFunc.shortenName(realCaster, 10), info.heal)
        sct.DisplayText(healText, icon, isPet, true, "heal", false)
    end    
    
end

local function handleCooldownStart (_, info)

    local abilities = {}
    local newAbilities = false

    for k, v in pairs (info) do
        if v >= 1 then
            if abilityCache[k] == nil then -- ignore global cooldown
                abilities[k] = true
                newAbilities = true
            end
            
            abilityTimer[k] = inspectTimeFrame()
        end
    end

    if newAbilities == false then return end

    local details = inspectAbilityNewDetail(abilities)

    for k, v in pairs (details) do
        abilityCache[k] = v
    end

end

local function handleCooldownEnd (_, info)

    for key, details in pairs (info) do
        if abilityCache[key] ~= nil and abilityTimer[key] ~= nil and inspectTimeFrame() - abilityTimer[key] >= 10 then
            abilityTimer[key] = nil
            internalFunc.displayMessageAtTopCenter(stringFormat("%s ready", abilityCache[key].name), 1.5)
        end
    end

end

local function handleInventoryUpdate(_, items)

    local count = 0
    local currentTime = inspectTimeFrame()

    -- Reset y-position if more than 1 second has passed since last update
    if lastInventoryUpdate ~= nil and currentTime - lastInventoryUpdate > .5 then
        inventoryUpdateModY = 0
    end

    for item, qty in pairs(items) do
        if qty > 0 then
            local itemDetails = LibEKL.Inventory.GetItemByKey(item)            

            if itemDetails then
                local slot = LibEKL.Inventory.GetSlotByItemId(item)
                if not stringFind(slot, "seqp") then
                    local color = LibEKL.Inventory.GetItemColor(itemDetails.rarity)
                    local hexColor = LibEKL.Tools.Color.RGBToHexColor(color.r, color.g, color.b)
                    local totalQty = LibEKL.Inventory.queryQtyById(item)

                    local message = '+%d <font color="#%s">%s</font>'
                    if totalQty > 0 then
                        message = '+%d <font color="#%s">%s</font> (%d)'
                    end

                    -- Display the item message with current y-position
                    sct.DisplayMovingMessage(
                        nil,
                        nil,
                        stringFormat(message, qty, hexColor, itemDetails.name, totalQty),
                        2,
                        300 + inventoryUpdateModY,
                        100 + inventoryUpdateModY,
                        20
                    )                    

                    -- Increment y-position for next item
                    inventoryUpdateModY = inventoryUpdateModY + 20
                    count = count + 1
                end
            end
        end
    end

    -- Update the last inventory update time
    lastInventoryUpdate = currentTime
end

function internalFunc.sctInit()
    
    local experience = inspectExperience()
    local attunement = inspectAttunementProgress()
    lastAccumulated = experience.accumulated    
    lastAttunementAccumulated = attunement.accumulated

    Command.Event.Attach(Event.Combat.Damage, handleCombatDamage, "nkUI.SCT.Combat.Damage")
    Command.Event.Attach(Event.Combat.Dodge, function( _, info ) handleCombatEvent(info, TEXT_DODGE) end, "nkUI.SCT.Combat.Dodge")
    Command.Event.Attach(Event.Combat.Immune, function( _, info ) handleCombatEvent(info, TEXT_IMMUNE) end, "nkUI.SCT.Combat.Immune")
    Command.Event.Attach(Event.Combat.Miss, function( _, info ) handleCombatEvent(info, TEXT_MISS) end, "nkUI.SCT.Combat.Miss")
    Command.Event.Attach(Event.Combat.Parry, function( _, info ) handleCombatEvent(info, TEXT_PARRY) end, "nkUI.SCT.Combat.Parry")
    Command.Event.Attach(Event.Combat.Resist, function( _, info ) handleCombatEvent(info, TEXT_RESIST) end, "nkUI.SCT.Combat.Resist")
    Command.Event.Attach(Event.Combat.Heal, handleCombatHeal, "nkUI.SCT.Combat.Heal")

    Command.Event.Attach(Event.Ability.New.Cooldown.Begin, handleCooldownStart, "nkUI.SCT.Ability.New.Cooldown.Begin")
    Command.Event.Attach(Event.Ability.New.Cooldown.End, handleCooldownEnd, "nkUI.SCT.Ability.New.Cooldown.End")

--    Command.Event.Attach(Event.Achievement.Complete, handleAchievement, "nkUI.SCT.Achievement.Complete")

    if nkUISetup.modules.sct.showExpGains then
        Command.Event.Attach(Event.TEMPORARY.Experience, function(_, accumulated, rested, needed)
            if lastAccumulated == nil then lastAccumulated = accumulated end
            local gain = accumulated - lastAccumulated
            if gain <= 0 then return end
            sct.DisplayMovingMessage("nkUI", "gfx/lowerbarExperience.png", stringFormat("<font color='#E8B630'>%d exp</font>", gain), 2, -200, -400, 24)
            lastAccumulated = accumulated
        end, "nkui.SCT.TEMPORARY.Experience")

        Command.Event.Attach(Event.Attunement.Progress.Accumulated, function(_, accumulated)
            if lastAttunementAccumulated == nil then lastAttunementAccumulated = accumulated end
            local gain = accumulated - lastAttunementAccumulated
            if gain <= 0 then 
                lastAttunementAccumulated = accumulated
                return 
            end
            sct.DisplayMovingMessage("nkUI", "gfx/iconPlanar.png", stringFormat("<font color='#A366CC'>%d planar exp</font>", gain), 2, -225, -425, 24)
            lastAttunementAccumulated = accumulated
        end, "nkui.SCT.Attunement.Progress.Accumulated")
    end

    if nkUISetup.modules.sct.showLoot then
        Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].Update, handleInventoryUpdate, "nkUI.SCT.LibEKL.InventoryManager.Update")
    end
        
    sctInit = true
end


function internalFunc.sctToggle(value)

    if value then
        if sctInit then return end
        internalFunc.sctInit()
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

        if nkUISetup.modules.sct.showExpGains then
            Command.Event.Detach(Event.TEMPORARY.Experience, nil, "nkui.SCT.TEMPORARY.Experience")
        end

        if nkUISetup.modules.sct.showExpGains then
            Command.Event.Detach(LibEKL.Events["LibEKL.InventoryManager"].Update, nil, "nkUI.SCT.LibEKL.InventoryManager.SlotUpdate")
        end

        sctInit = false

    end

end
