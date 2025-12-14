local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internalFunc
local _events     = privateVars.events

---------- init local variables ---------

-- Cache frequently used functions and values
local InspectBuffDetail     = Inspect.Buff.Detail
local InspectBuffList       = Inspect.Buff.List
local InspectTimeReal       = Inspect.Time.Real

local mathFloor     = math.floor
local stringFormat  = string.format

local buffIcons         = {}
local buffDisplayList   = {}
local debuffIcons       = {}
local debuffDisplayList = {}
local buffId2BuffType   = {}

---------- init global variables ---------

---------- addon internal function block ---------

_internal.buffBar = {}

function _internal.buffBar.GetBuffIcons ()
    return buffIcons
end

function _internal.buffBar.GetDebuffIcons ()
    return debuffIcons
end

function _internal.buffBar.UpdateBuffDisplay()

    local x = 0

    for k, v in pairs (buffDisplayList) do        
        if buffIcons[k].lastX ~= x then
            local icon = buffIcons[k].icon
            icon:SetPoint("TOPLEFT", uiElements.frames["buffBar"], "TOPLEFT", x, 0)
        end

        buffIcons[k].lastX = x
        x = x + nkUISetup.modules.buffBar.buffs.width + 2        
    end

    x = 0

    for k, v in pairs (debuffDisplayList) do
        if debuffIcons[k].lastX ~= x then
            local icon = debuffIcons[k].icon
            icon:SetPoint("TOPLEFT", uiElements.frames["buffBar"], "TOPLEFT", x, (nkUISetup.modules.buffBar.buffs.height + 12))
        end
        
        debuffIcons[k].lastX = x
        x = x + nkUISetup.modules.buffBar.buffs.width + 2
    end
end


function _internal.buffBar.addBuff(unit, buffs)

    local details = InspectBuffDetail(unit, buffs)

    for k, v in pairs(details) do

        local buffIdentifier = v.type

        if buffIdentifier == nil then
            EnKai.tools.error.display ("nkUI", "BuffBar addBuff - no type for buff " .. details.name, 2)
        else
            buffId2BuffType[k] = buffIdentifier        

            if v.poison == true or v.curse == true or v.disease == true or v.debuff == true then
                _internal.processNewBuff ("buffbar.debuff.icon" .. buffIdentifier, data.playerID, unit, k, buffIdentifier, v, debuffDisplayList, debuffIcons)
            else
                _internal.processNewBuff ("buffbar.buff.icon" .. buffIdentifier, data.playerID, unit, k, buffIdentifier, v, buffDisplayList, buffIcons)
            end
        end
    end
end

function _internal.buffBar.removeBuff (unit, buffs)
    
    for id, v in pairs(buffs) do

        local buffType = buffId2BuffType[id]

        if buffIcons[buffType] then
            buffIcons[buffType].visible = false
            buffIcons[buffType].icon:Clear()
            buffIcons[buffType].lastX = nil
            buffDisplayList[buffType] = nil 
        elseif debuffIcons[buffType] then
            debuffIcons[buffType].visible = false
            debuffIcons[buffType].icon:Clear()
            debuffIcons[buffType].lastX = nil
            debuffDisplayList[buffType] = nil
        end

        buffId2BuffType[id] = nil
    end
end

--[[
   _internal.buffBar.clearAllBuffs
    Description:
        Clears all active buff icons. This function is used to reset the UI state for all buffs.
    Process:
        1. Iterates through all active buff icons
        2. Hides each buff icon
        3. Removes each buff icon from the display list
        4. Clears the buff icons collection
    Notes:
        - This function is useful for resetting the UI state for all buffs
        - All buff icons are hidden and removed from the display list
        - The buff icons collection is emptied after processing
]]
function _internal.buffBar.clearAllBuffs()

    local buffs = InspectBuffList(data.playerID)
   _internal.buffBar.removeBuff(data.playerID, buffs)
    
end

function _internal.buffBar.loadAllBuffs()

   local buffs = InspectBuffList(data.playerID)
   _internal.buffBar.addBuff(data.playerID, buffs)
   _internal.buffBar.UpdateBuffDisplay() 

end

function _internal.buffBar.Redraw()
   
    local newSetup = {  width   = nkUISetup.modules.buffBar.buffs.width,
                        height  = nkUISetup.modules.buffBar.buffs.height,
                        label   = nkUISetup.modules.buffBar.buffs.label,
                        timer   = nkUISetup.modules.buffBar.buffs.timer,
                        stack   = nkUISetup.modules.buffBar.buffs.stack
                    }

    local buffs = _internal.buffBar.GetBuffIcons ()
    for k, v in pairs (buffs) do
        v.icon:Setup(newSetup)
	end

    local debuffs = _internal.buffBar.GetDebuffIcons ()
    for k, v in pairs (debuffs) do
         v.icon:Setup(newSetup)
    end

    EnKai.ui.reloadDialog ("nkUI")

end