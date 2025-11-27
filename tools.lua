local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

---------- init local variables ---------

-- Cache frequently used functions and values

local stringLen     = string.len
local stringSub     = string.sub

function _internal.shortenName (name, maxLen)

    local thisName

    if stringLen (name) > maxLen then
        local splitName = EnKai.strings.split(name, " ")

        if #splitName == 1 then
            splitName = EnKai.strings.split(name, "-")
        end

        if #splitName == 1 then
            thisName = stringSub(name, 1, maxLen)
        else
            thisName = ""
            for idx = 1, #splitName -1, 1 do                    
                local tempName = stringSub(splitName[idx], 1, 1)                    
                
                if unitFrameType ~= "raid" then
                    thisName = thisName .. tempName .. ". "                    
                end
            end

            thisName = thisName .. splitName[#splitName]
        end
    else
        thisName = name
    end
   
   return thisName

end