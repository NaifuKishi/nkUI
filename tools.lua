local addonInfo, privateVars = ...

-- Initialize namespace
local internalFunc  = privateVars.internalFunc
local uiElements    = privateVars.uiElements
local data        	= privateVars.data

-- Cache frequently used functions and values
local stringLen     = string.len
local stringSub     = string.sub
local stringFind    = string.find
local stringSplit   = LibEKL.strings.split

function internalFunc.shortenName (name, maxLen)

    if stringLen(name) <= maxLen then
        return name
    end

    local splitName    
    if stringFind(name,"-") then
        splitName = stringSplit(name, "-")
    else
        splitName = stringSplit(name, " ")
    end

    if #splitName == 1 then
        return stringSub(name, 1, maxLen)
    end

    local thisName = ""
    for idx = 1, #splitName - 1 do
        local tempName = stringSub(splitName[idx], 1, 1)
        thisName = thisName .. tempName .. ". "
    end

    return thisName .. splitName[#splitName]

end

-- Helper function to check if the unit is the player
function internalFunc.isPlayerUnit(unit)
    return unit == LibEKL.Unit.GetPlayerDetails().id
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


function internalFunc.formatCoins(amount)

    local platin = math.floor(amount / 10000)
    local gold = math.floor((amount - (platin * 10000)) / 100)
    local silver = amount - (platin * 10000) - (gold * 100)

    -- Build the coin string with only non-zero values
    local coinParts = {}
    
    if platin > 0 then
        table.insert(coinParts, string.format("<font color=\"#efebff\">%dp</font>", platin))
    end

    if gold > 0 or platin > 0 then
        table.insert(coinParts, string.format("<font color=\"#eed234\">%dg</font>", gold))
    end

    if silver > 0 or (platin > 0 or gold > 0) then
        table.insert(coinParts, string.format("<font color=\"#a7aba7\">%ds</font>", silver))
    end

    -- Combine the parts with spaces
    return table.concat(coinParts, " ")

end