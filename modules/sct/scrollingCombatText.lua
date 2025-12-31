local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events

---------- init local variables ---------

local inspectTimeFrame          = Inspect.Time.Frame
local inspectAbilityNewDetail   = Inspect.Ability.New.Detail
local inspectAbilityDetail      = Inspect.Ability.Detail
local inspectExperience         = Inspect.Experience

local LibEKLUnitGetUnitDetail    = LibEKL.Unit.GetUnitDetail

local stringFind        = string.find
local stringMatch       = string.match
local stringFormat      = string.format

local mathRandom        = math.random
local mathCos           = math.cos
local mathSin           = math.sin
local mathRad           = math.rad

---------- init variables ---------

local name = "scrollingcombattext"

local DEFAULT_FONTSIZE = 20
local DEFAULT_CRIT_FONTSIZE = 30

local PET_FONTSIZE = 14
local PET_CRIT_FONTSIZE = 24

local TEXT_RESIST = "<font color='#ffffff'>Resist</font>"
local TEXT_PARRY = "<font color='#ffffff'>Parry</font>"
local TEXT_MISS = "<font color='#ffffff'>Miss</font>"
local TEXT_IMMUNE = "<font color='#ffffff'>Immune</font>"
local TEXT_DODGE = "<font color='#ffffff'>Dodge</font>"
local TEXT_OVERHEAL = "[%s] <font color='#00FF00'>%d OVERHEAL</font>"
local TEXT_HEAL = "[%s] <font color='#00FF00'>%d</font>"
local TEXT_DAMAGE = "<font color='%s'>%d</font>"
local TEXT_INCOMING = "<font color='#FF0000'>[%s]</font> %s"

local COLOR_CRIT = "#FFA500"
local COLOR_LIFE = "#4CAF50"
local COLOR_DEATH = "#9C27B0"
local COLOR_AIR = "#B0BEC5"
local COLOR_EARTH = "#795548"
local COLOR_FIRE = "#FF5722"
local COLOR_WATER = "#1976D2"    

local framePool = {}
local activeFrames = {}
local sctInit = false

local lastMessage, messageY = nil, 0
local petID, petName   
local lastAccumulated = 0

local abilityCache = {}
local iconCache = {}
local abilityTimer = {}

local context = UI.CreateContext("nkUI.SCT")
context:SetStrata('hud')
context:SetLayer(2)


---------- local functions ---------

-- Gets the ability icon for a given ability
-- @param info Table containing ability information
-- @return The ability icon path
local function getAbilityIcon(info)
    local icon
    local abilityNew = info.abilityNew
    local ability = info.ability

    if abilityNew == nil and ability == nil then return end

    if abilityNew ~= nil then
        if iconCache[abilityNew] == nil then
            local details = inspectAbilityNewDetail(abilityNew)
            if details then
                iconCache[abilityNew] = details.icon
                icon = details.icon
            end
        else
            icon = iconCache[abilityNew]
        end
    else
        if iconCache[ability] == nil then
            local details = inspectAbilityDetail(ability)
            if details then
                iconCache[ability] = details.icon
                icon = details.icon
            end
        else
            icon = iconCache[ability]
        end
    end

    return icon
end

-- Creates a new text frame for displaying combat text
-- @return The created text frame
local function createTextFrame()
    local name = LibEKL.Tools.UUID()
    local thisAddonID, thisFontName, thisFontSize, thisFontColor
    local thisTextureSource, thisTexture

    local frame = LibEKL.UICreateFrame("nkText", name, context)
    frame:SetEffectGlow({ strength = 3 })
    frame:SetVisible(false)

    -- Create an icon frame for the text frame
    local icon = LibEKL.UICreateFrame("nkTexture", name .. "." .. LibEKL.Tools.UUID(), frame)
    icon:SetPoint("CENTERRIGHT", frame, "CENTERLEFT", -5, 0)
    icon:SetVisible(false)
    icon:SetWidth(24)
    icon:SetHeight(24)

    local oSetTextFont = frame.SetTextFont
    function frame:SetTextFont(addonID, fontName)
        if addonID ~= thisAddonID or fontName ~= thisFontName then
            oSetTextFont(self, addonID, fontName)
            thisAddonID = addonID
            thisFontName = fontName
        end
    end

    local oSetFontSize = frame.SetFontSize
    function frame:SetFontSize(fontSize)
        if fontSize ~= thisFontSize then
            oSetFontSize(self, fontSize)
            thisFontSize = fontSize
        end
    end

    local oSetFontColor = frame.SetFontColor
    function frame:SetFontColor(r, g, b, a)
        if not thisFontColor or r ~= thisFontColor or g ~= thisFontColor.g or b ~= thisFontColor.b or a ~= thisFontColor.a then
            oSetFontColor(self, r, g, b, a)
            thisFontColor = { r = r, g = g, b = b, a = a }
        end
    end

    local oSetTextureAsync = frame.SetTextureAsync
    function frame:SetTextureAsync(source, texture)
        if source ~= thisTextureSource or texture ~= thisTexture then
            oSetTextureAsync(self, source, texture)
            thisTextureSource = source
            thisTexture = texture
        end
    end

    -- Store the icon frame in the text frame for later access
    frame.icon = icon

    return frame
end

-- Gets a frame from the pool or creates a new one
-- @return A text frame for displaying combat text
local function getFrame()
    if #framePool > 0 then
        return table.remove(framePool)        
    else
        return createTextFrame()        
    end
end

-- Releases a frame back to the pool
-- @param frame The frame to release
local function releaseFrame(frame)
    frame:SetVisible(false)
    frame.icon:SetVisible(false)
    table.insert(framePool, frame)
end

-- Displays a message at the top center of the screen
-- @param message The message to display
-- @param duration How long to display the message
function internalFunc.displayMessageAtTopCenter(message, duration)

    local debugId = internalFunc.traceStart("sct.displayMessageAtTopCenter")

    local frame = getFrame()
    frame:SetText(message, true)
    frame:SetTextFont(addonInfo.id, "MontserratSemiBold")
    frame:SetFontSize(28)
    frame:SetFontColor(1, 1, 1, 1)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, (nkUISetup.modules.sct.messageOffset) + messageY)
    frame:SetVisible(true)

    lastMessage = frame:GetName()
    messageY = messageY - 20
    local coRoutineDebugID

    local start = inspectTimeFrame()

    local animationCoroutine = coroutine.create(function()      
        for idx = 1, duration * 100, 1 do
            coRoutineDebugID = internalFunc.traceStart("sct.cr.displayMessageAtTopCenter")
            local elapsed = inspectTimeFrame() - start
            if elapsed > duration then
                internalFunc.traceEnd("sct.cr.displayMessageAtTopCenter", coRoutineDebugID)
                return 9999
            end
            internalFunc.traceEnd("sct.cr.displayMessageAtTopCenter", coRoutineDebugID)
            coroutine.yield(idx)
        end
    end)

    local callBack = function()
        if frame:GetName() == lastMessage then
            lastMessage = nil
            messageY = 0
        end
        releaseFrame(frame)
        internalFunc.traceEnd("sct.cr.displayMessageAtTopCenter", coRoutineDebugID)
    end

    LibEKL.Coroutines.Add({
        func = animationCoroutine,
        callBack = callBack,
        counter = duration * 100,
        active = true
    })

    internalFunc.traceEnd("sct.displayMessageAtTopCenter", debugId)
end

-- Displays a moving message on the screen
-- @param message The message to display
-- @param duration How long to display the message
local function displayMovingMessage(message, duration, startY, endY, fontSize)

    local debugId = internalFunc.traceStart("sct.displayMovingMessage")

    local frame = getFrame()
    frame:SetText(message, true)
    frame:SetTextFont(addonInfo.id, "MontserratSemiBold")
    frame:SetFontSize(fontSize)
    frame:SetFontColor(0.678, 0.847, 0.902, 1)
    frame:SetVisible(true)

    local start = inspectTimeFrame()
    local coRoutineDebugID
    
    local animationCoroutine = coroutine.create(function()        

        for idx = 1, duration * 100, 1 do
            coRoutineDebugID = internalFunc.traceStart("sct.cr.displayMovingMessage")
            local elapsed = inspectTimeFrame() - start
            if elapsed > duration then
                internalFunc.traceEnd("sct.cr.displayMovingMessage", coRoutineDebugID)
                return 9999
            end
            local t = elapsed / duration
            local currentY = startY + (endY - startY) * t
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, currentY)
            internalFunc.traceEnd("sct.cr.displayMovingMessage", coRoutineDebugID)
            coroutine.yield(idx)
        end
    end)

    local callBack = function()
        releaseFrame(frame)
        internalFunc.traceEnd("sct.cr.displayMovingMessage", coRoutineDebugID)
    end

    LibEKL.Coroutines.Add({
        func = animationCoroutine,
        callBack = callBack,
        counter = duration * 100,
        active = true
    })

    internalFunc.traceEnd("sct.displayMovingMessage", debugId)
end

-- Animates a frame with combat text
-- @param frame The frame to animate
-- @param text The text to display
-- @param icon The icon to display
-- @param x The x position
-- @param y The y position
-- @param inComing Whether the damage is incoming
local function animateFrame(frame, text, icon, x, y, inComing)

    local debugId = internalFunc.traceStart("sct.animateFrame")

    frame:SetText(text, true)
    frame:SetVisible(true)

    if icon then
        frame.icon:SetTextureAsync("Rift", icon)
        frame.icon:SetVisible(true)
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
            coRoutineDebugID = internalFunc.traceStart("sct.cr.animateFrame")

            local elapsed = inspectTimeFrame() - start
            if elapsed > duration then
                internalFunc.traceEnd("sct.cr.animateFrame", coRoutineDebugID)
                return 9999
            end
            local t = elapsed / duration
            local currentAngle = startAngle + (endAngle - startAngle) * t
            local currentXOffset = radius * mathCos(currentAngle)
            local currentYOffset = radius * mathSin(currentAngle)

            frame:SetPoint("CENTER", UIParent, "CENTER", startX + currentXOffset, startY + currentYOffset + 100)
            internalFunc.traceEnd("sct.cr.animateFrame", coRoutineDebugID)

            coroutine.yield(idx)
        end
    end)
    
    local callBack = function()
        releaseFrame(frame)
        internalFunc.traceEnd("sct.cr.animateFrame", coRoutineDebugID)
    end
    
    LibEKL.Coroutines.Add({
        func = animationCoroutine,
        callBack = callBack,
        counter = 200,
        active = true
    })

    internalFunc.traceEnd("sct.animateFrame", debugId)
end

-- Displays combat text on the screen
-- @param sctText The text to display
-- @param icon The icon to displayinternalFunc.traceEnd("sct.cr.displayMovingMessage", coRoutineDebugID)
-- @param isPet Whether the damage is from a pet
-- @param inComing Whether the damage is incoming
-- @param crit Whether the damage is a critical hit
local function displayText(sctText, icon, isPet, inComing, crit)
    local xVariation = mathRandom(0, 50)
    if inComing then xVariation = mathRandom(0, -50) end
    
    local yVariation = mathRandom(-50, 50)

    local text = sctText

    if isPet and not inComing then
        xVariation = xVariation + 100 
        text = stringFormat("%s: %s", petName, sctText)
    end

    local frame = getFrame()

    if crit == true then
        frame:SetTextFont(addonInfo.id, "MontserratBold")
        
        if isPet then
            frame:SetFontSize(PET_CRIT_FONTSIZE)
        else
            frame:SetFontSize(DEFAULT_CRIT_FONTSIZE)
        end
    else
        frame:SetTextFont(addonInfo.id, "MontserratSemiBold")
        
        if isPet then
            frame:SetFontSize(PET_FONTSIZE)
        else
            frame:SetFontSize(DEFAULT_FONTSIZE)
        end
    end

    animateFrame(frame, text, icon, xVariation, yVariation, inComing)
end

-- Validates combat events
-- @param info The combat event information
-- @return Whether the event is valid, whether it's from a pet, and whether it's incoming
local function validEvent(info)
    if info.caster == LibEKL.Unit.getPlayerDetails().id then return true, false, false end

    if petID ~= nil and info.caster == petID then
        if info.target == LibEKL.Unit.getPlayerDetails().id then
            return true, true, true
        else
            return true, true, false 
        end
    end
    
    local localUnitsTypes = LibEKL.Unit.getUnitTypes(info.caster)
    
    if LibEKL.Tools.Table.IsMember(localUnitsTypes, "player.pet") then
        petID = info.caster
        if info.casterName then
            petName = internalFunc.shortenName(info.casterName, 10)
        end
        return true, true, false
    end

    if info.target == LibEKL.Unit.getPlayerDetails().id then return true, false, true end
    
    return false, false, false
end

-- Handles combat damage events
-- @param info The combat damage information
local function handleCombatDamage(self, info)
    if info.damage == nil then return end
    
    local valid, isPet, isIncoming = validEvent(info)
    if valid == false then return end

    local icon = getAbilityIcon(info)

    local damageText = ""

    if info.crit then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_CRIT, info.damage)
    elseif info.type == "life" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_LIFE, info.damage)
    elseif info.type == "death" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_DEATH, info.damage)
    elseif info.type == "air" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_AIR, info.damage)
    elseif info.type == "earth" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_EARTH, info.damage)
    elseif info.type == "fire" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_FIRE, info.damage)
    elseif info.type == "water" then
        damageText = stringFormat(TEXT_DAMAGE, COLOR_WATER, info.damage)
    elseif info.damage ~= nil then
        damageText = stringFormat("%d", info.damage)
    end
    
    --if info.crit then
    --    damageText = stringFormat("%s (CRIT)", damageText)
    --end
    
    if info.damageAbsorbed then
        damageText = stringFormat("%s [%d Absorbed]",damageText, info.damageAbsorbed)
    end

    if info.damageBlocked then
        damageText = stringFormat("%s [%d Blocked]", damageText, info.damageBlocked)
    end

    if info.damageIntercepted then
        damageText = stringFormat("%s [%d Intercepted]", damageText, info.damageIntercepted)
    end

    --if info.damageModified then
    --    damageText = stringFormat("%s [%d Modified]", damageText, info.damageModified)
    --end

    if info.overkill then
        damageText = stringFormat("%s [%d Overkill]", damageText, info.overkill)
    end

    if isIncoming == true then
        damageText = stringFormat(TEXT_INCOMING, internalFunc.shortenName(LibEKLUnitGetUnitDetail(info.caster).name, 10), damageText)
    end
    
    --if info.crit then
    --    displayText(stringFormat("%s (CRIT)", damageText), icon, isPet, isIncoming, true)
    --else
        displayText(damageText, icon, isPet, isIncoming, info.crit)
    --end
end

-- Handles combat events
-- @param info The combat information
-- @param text The text to display
local function handleCombatEvent(info, text)
    local valid, isPet, isIncoming = validEvent(info)
    if valid == false then return end
    displayText(text, nil, isPet, isIncoming)
end

-- Handles combat heal events
-- @param info The combat heal information
local function handleCombatHeal(self, info)

    local valid, isPet, isIncoming = validEvent(info)
    if valid == false then return end
    
    if info.heal == nil and info.overheal == nil then return end
    
    local icon = getAbilityIcon(info)
    local healText

    --dump (info)

    if info.overheal then
        healText = string.format(TEXT_OVERHEAL, internalFunc.shortenName(info.casterName, 10), info.overheal)
    else
        healText = string.format(TEXT_HEAL, internalFunc.shortenName(info.casterName, 10), info.heal)
    end
    
    displayText(healText, icon, isPet, true, "heal")
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

function internalFunc.sctInit()
    
    local experience = inspectExperience()
    lastAccumulated = experience.accumulated    

    Command.Event.Attach(Event.Combat.Damage, handleCombatDamage, "nkUI.SCT.Combat.Damage")
    Command.Event.Attach(Event.Combat.Dodge, function( _, info ) handleCombatEvent(info, TEXT_DODGE) end, "nkUI.SCT.Combat.Dodge")
    Command.Event.Attach(Event.Combat.Immune, function( _, info ) handleCombatEvent(info, TEXT_IMMUNE) end, "nkUI.SCT.Combat.Immune")
    Command.Event.Attach(Event.Combat.Miss, function( _, info ) handleCombatEvent(info, TEXT_MISS) end, "nkUI.SCT.Combat.Miss")
    Command.Event.Attach(Event.Combat.Parry, function( _, info ) handleCombatEvent(info, TEXT_PARRY) end, "nkUI.SCT.Combat.Parry")
    Command.Event.Attach(Event.Combat.Resist, function( _, info ) handleCombatEvent(info, TEXT_RESIST) end, "nkUI.SCT.Combat.Resist")
    Command.Event.Attach(Event.Combat.Heal, handleCombatHeal, "nkUI.SCT.Combat.Heal")

    Command.Event.Attach(Event.Ability.New.Cooldown.Begin, handleCooldownStart, "nkUI.SCT.Ability.New.Cooldown.Begin")
    Command.Event.Attach(Event.Ability.New.Cooldown.End, handleCooldownEnd, "nkUI.SCT.Ability.New.Cooldown.End")

    if nkUISetup.modules.sct.showExpGains then
        Command.Event.Attach(Event.TEMPORARY.Experience, function(_, accumulated, rested, needed)
            if lastAccumulated == nil then lastAccumulated = accumulated end
            local gain = accumulated - lastAccumulated
            if gain <= 0 then return end
            displayMovingMessage(stringFormat("%d exp", gain), 2, -200, -400, 28)
            lastAccumulated = accumulated
        end, "nkui.SCT.TEMPORARY.Experience")
    end

    if nkUISetup.modules.sct.showLoot then
        Command.Event.Attach(LibEKL.Events["LibEKL.InventoryManager"].Update, function(_, items)

            local modY = 0

            for item, qty in pairs (items) do
                local itemDetails = LibEKL.Inventory.GetItemByKey (item)
                if itemDetails then
                    local color = LibEKL.Inventory.GetItemColor(itemDetails.rarity)
                    local hexColor = LibEKL.Tools.Color.RGBToHexColor(color.r, color.g, color.b)
                    displayMovingMessage(stringFormat('+%d <font color="#%s">%s</font>', qty, hexColor, itemDetails.name), 2, 300 + modY, 100 + modY, 20)
                    modY = modY + 20
                end
            end
        end, "nkUI.SCT.LibEKL.InventoryManager.SlotUpdate")
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
