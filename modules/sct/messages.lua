local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events
local sct           = privateVars.sct

---------- init local variables ---------

local inspectTimeFrame          = Inspect.Time.Frame

local stringFormat      = string.format

local mathRandom        = math.random

---------- init variables ---------

local DEFAULT_FONTSIZE = 20
local DEFAULT_CRIT_FONTSIZE = 30

local PET_FONTSIZE = 14
local PET_CRIT_FONTSIZE = 24

local lastMessage, messageY = nil, 0

data.petName = nil

function sct.displayShakingMessage(message, type)

    -- Display the achievement message with a larger font size and different color
    local frame = sct.GetFrame()
    frame:SetText(message, true)
    frame:SetTextFont(addonInfo.id, "MontserratBold")
    frame:SetFontSize(36) -- Larger font size        
    
    if type == "achievement" then
        frame:SetFontColor(0, 0.5, 0, 1) -- Dark green color for achievements
    else
        frame:SetFontColor(1, 0.84, 0, 1) -- Gold color
    end

    -- Add a glow effect to the text
    frame:SetEffectGlow({ strength = 3 })

    local y = -((LibEKL.UI.getBoundBottom() / 2) - 250)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, y)
    frame:SetVisible(true)

    -- Animate the text to make it more noticeable with a shaking effect
    local start = inspectTimeFrame()
    local lastShakeTime = inspectTimeFrame()
    local duration = 4
    local shakeIntensity = 2 -- Intensity of the shake effect
    local shakeInterval = 0.1 -- Time between each shake (in seconds)

    local animationCoroutine = coroutine.create(function()
        for idx = 1, duration * 100, 1 do
            local elapsed = inspectTimeFrame() - start
            if elapsed > duration then
                return 9999
            end            
            
            -- Check if it's time to apply the shake effect
            if inspectTimeFrame() - lastShakeTime >= shakeInterval then
                -- Add a shaking effect by randomly varying the X position
                local shakeX = mathRandom(-shakeIntensity, shakeIntensity)
                local shakeY = mathRandom(-shakeIntensity, shakeIntensity)
                frame:SetPoint("CENTER", UIParent, "CENTER", shakeX, y + shakeY)
                lastShakeTime = inspectTimeFrame()
            end
            coroutine.yield(idx)
        end
    end)

    local callBack = function()
        sct.ReleaseFrame(frame)
    end

    LibEKL.Coroutines.Add({
        func = animationCoroutine,
        callBack = callBack,
        counter = duration * 100,
        active = true
    })
end

-- Displays a message at the top center of the screen
-- @param message The message to display
-- @param duration How long to display the message
function internalFunc.displayMessageAtTopCenter(message, duration)

    local debugId = internalFunc.traceStart("sct.displayMessageAtTopCenter")

    local frame = sct.GetFrame()
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
        sct.ReleaseFrame(frame)
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
function sct.DisplayMovingMessage(addonId, icon, message, duration, startY, endY, fontSize)
    local debugId = internalFunc.traceStart("sct.displayMovingMessage")

    local frame = sct.GetFrame()
    frame:SetText(message, true)
    frame:SetTextFont(addonInfo.id, "MontserratSemiBold")
    frame:SetFontSize(fontSize)
    frame:SetFontColor(0.678, 0.847, 0.902, 1)
    frame:SetVisible(true)
    frame:SetAlpha(1) -- Alpha-Wert auf 1 setzen

    frame:SetTextureAsync(addonId, icon)

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

            -- Fade-Effekt im oberen 25%-Segment
            if t > 0.5 then
                local alpha = 1 - (t - 0.5) / 0.5
                frame:SetAlpha(alpha)
            end

            internalFunc.traceEnd("sct.cr.displayMovingMessage", coRoutineDebugID)
            coroutine.yield(idx)
        end
    end)

    local callBack = function()
        sct.ReleaseFrame(frame)
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

local yVariation = 0
local lastYReset = inspectTimeFrame()

-- Displays combat text on the screen
-- @param sctText The text to display
-- @param icon The icon to display
-- @param isPet Whether the damage is from a pet
-- @param inComing Whether the damage is incoming
-- @param crit Whether the damage is a critical hit or heal or overheal
function sct.DisplayText(sctText, icon, isPet, inComing, crit)
    
    local xVariation = 200
    if inComing then xVariation = - 200 end

    --local xVariation = mathRandom(0, 50) + 100
    --if inComing then xVariation = mathRandom(0, -50) - 100 end
    
    --local yVariation = mathRandom(-50, 50)

    local text = sctText

    if isPet and not inComing then
        xVariation = xVariation + 100 
        text = stringFormat("%s: %s", data.petName, sctText)
    end

    local frame = sct.GetFrame()

    if crit == true then
        frame:SetTextFont(addonInfo.id, "MontserratBold")
        
        if isPet then
            frame:SetFontSize(PET_CRIT_FONTSIZE)
        else
            frame:SetFontSize(DEFAULT_CRIT_FONTSIZE)
        end
    elseif crit == "overheal" then
        frame:SetTextFont(addonInfo.id, "MontserratSemiBold")
        frame:SetFontSize(PET_FONTSIZE)
    else
        frame:SetTextFont(addonInfo.id, "MontserratSemiBold")
        
        if isPet then
            frame:SetFontSize(PET_FONTSIZE)
        else
            frame:SetFontSize(DEFAULT_FONTSIZE)
        end
    end

    --print (yVariation)

    sct.AnimateFrame(frame, text, icon, xVariation, yVariation, inComing)

    yVariation = yVariation - 20
    if inspectTimeFrame() - lastYReset > 1 then
        yVariation = 0
        lastYReset = inspectTimeFrame()
    end

end