local addonInfo, privateVars = ...

-- Initialize namespace
local internalFunc  = privateVars.internalFunc
local uiElements    = privateVars.uiElements
local data        	= privateVars.data

-- Cache frequently used functions and values
local stringLen     = string.len
local stringSub     = string.sub
local stringSplit   = LibEKL.strings.split

function internalFunc.shortenName (name, maxLen)

    if stringLen(name) <= maxLen then
        return name
    end

    local splitName = stringSplit(name, " ") or stringSplit(name, "-")

    if #splitName == 1 then
        return stringSub(name, 1, maxLen)
    end

    local thisName = ""
    for idx = 1, #splitName - 1 do
        local tempName = stringSub(splitName[idx], 1, 1)
        if unitFrameType ~= "raid" then
            thisName = thisName .. tempName .. ". "
        end
    end

    return thisName .. splitName[#splitName]

end

-- Helper function to check if the unit is the player
function internalFunc.isPlayerUnit(unit)
    return unit == LibEKL.unit.getPlayerDetails().id
end


function internalFunc.traceStart(eventName)
    if nkDebug then
        return nkDebug.traceStart(addonInfo.identifier, "events." .. eventName)
    end
    return nil
end

function internalFunc.traceEnd(eventName, debugId)
    if nkDebug then
        nkDebug.traceEnd(addonInfo.identifier, "events." .. eventName, debugId)
    end
end
