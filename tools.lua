local addonInfo, privateVars = ...

-- Initialize namespace
local internalFunc  = privateVars.internalFunc
local uiElements    = privateVars.uiElements
local data        	= privateVars.data

-- Cache frequently used functions and values
local stringLen     = string.len
local stringSub     = string.sub
local stringSplit   = EnKai.strings.split

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
    return unit == EnKai.unit.getPlayerDetails().id
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

function internalFunc.dialog (messageText)

    if uiElements.dialog == nil then
        uiElements.dialog = EnKai.uiCreateFrame("nkDialogMetro", "nkUI.dialog", uiElements.contextDialog)        
        uiElements.dialog:SetType("ok")
        uiElements.dialog:SetWidth(400)
        uiElements.dialog:SetHeight(100)
        uiElements.dialog:SetFont(addonInfo.id, "MontserratSemiBold")
        uiElements.dialog:SetEffectGlow({ strength = 3 })

        uiElements.dialog:SetButtonFont(addonInfo.id, "MontserratSemiBold")
	    uiElements.dialog:SetButtonColor (0, 0, 0, .4)
	    uiElements.dialog:SetButtonFontColor (data.theme.labelColor)
	    uiElements.dialog:SetButtonBorderColor (0, 0, 0, .7)
	    uiElements.dialog:SetButtonEffect ({ strength = 3 })
    end
    
    uiElements.dialog:SetMessage(messageText)
    uiElements.dialog:SetVisible(true)

end