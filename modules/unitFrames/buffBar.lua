local addonInfo, privateVars = ...

-- init namespace

local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc

-- Cache frequently used functions and values
local InspectBuffDetail     = Inspect.Buff.Detail
local InspectBuffList       = Inspect.Buff.List
local InspectTimeReal       = Inspect.Time.Real

local mathFloor     = math.floor
local stringFormat  = string.format

-- Buff and debuff icons and display lists
local buffIcons         = {}
local buffDisplayList   = {}
local debuffIcons       = {}
local debuffDisplayList = {}
local buffId2BuffType   = {}

internalFunc.buffBar = {}

---------- addon internal function block ---------

-- Gets the current buff icons
-- @return Table of buff icons
function internalFunc.buffBar.GetBuffIcons()
    return buffIcons
end

-- Gets the current debuff icons
-- @return Table of debuff icons
function internalFunc.buffBar.GetDebuffIcons()
    return debuffIcons
end

-- Updates the display of buff and debuff icons
function internalFunc.buffBar.UpdateBuffDisplay()
    local x = 0
    
    for k, v in pairs(buffDisplayList) do
        if buffIcons[k].lastX ~= x then
            local icon = buffIcons[k].icon
            icon:SetPoint("TOPLEFT", uiElements.frames["buffBar"], "TOPLEFT", x, 0)
        end

        buffIcons[k].lastX = x
        x = x + nkUISetup.modules.buffBar.buffs.width + 2        
    end

    x = 0
    
    for k, v in pairs(debuffDisplayList) do
        if debuffIcons[k].lastX ~= x then
            local icon = debuffIcons[k].icon
            icon:SetPoint("TOPLEFT", uiElements.frames["buffBar"], "TOPLEFT", x, (nkUISetup.modules.buffBar.buffs.height + 12))
        end
        
        debuffIcons[k].lastX = x
        x = x + nkUISetup.modules.buffBar.buffs.width + 2
    end
end

-- Adds a buff to the display
-- @param unit The unit ID
-- @param buffs The buffs to add
function internalFunc.buffBar.addBuff(unit, buffs)
    local details = InspectBuffDetail(unit, buffs)

    for k, v in pairs(details) do
        local buffIdentifier = v.type

        if buffIdentifier == nil then
            EnKai.tools.error.display("nkUI", "BuffBar addBuff - no type for buff " .. details.name, 2)
        else
            buffId2BuffType[k] = buffIdentifier
            
            if v.poison == true or v.curse == true or v.disease == true or v.debuff == true then
                internalFunc.processNewBuff("buffbar.debuff.icon" .. buffIdentifier, EnKai.unit.getPlayerDetails().id, unit, k, buffIdentifier, v, debuffDisplayList, debuffIcons)
            else
                internalFunc.processNewBuff("buffbar.buff.icon" .. buffIdentifier, EnKai.unit.getPlayerDetails().id, unit, k, buffIdentifier, v, buffDisplayList, buffIcons)
            end
        end
    end
end

-- Removes a buff from the display
-- @param unit The unit ID
-- @param buffs The buffs to remove
function internalFunc.buffBar.removeBuff(unit, buffs)
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

-- Clears all active buff icons
function internalFunc.buffBar.clearAllBuffs()
    local buffs = InspectBuffList(EnKai.unit.getPlayerDetails().id)
    internalFunc.buffBar.removeBuff(EnKai.unit.getPlayerDetails().id, buffs)
end

-- Loads all buffs for the player
function internalFunc.buffBar.loadAllBuffs()
    local buffs = InspectBuffList(EnKai.unit.getPlayerDetails().id)
    internalFunc.buffBar.addBuff(EnKai.unit.getPlayerDetails().id, buffs)
    internalFunc.buffBar.UpdateBuffDisplay()
end

-- Redraws the buff bar
function internalFunc.buffBar.Redraw()
    local newSetup = {
        width   = nkUISetup.modules.buffBar.buffs.width,
        height  = nkUISetup.modules.buffBar.buffs.height,
        label   = nkUISetup.modules.buffBar.buffs.label,
        timer   = nkUISetup.modules.buffBar.buffs.timer,
        stack   = nkUISetup.modules.buffBar.buffs.stack
    }
    
    local buffs = internalFunc.buffBar.GetBuffIcons()
    for k, v in pairs(buffs) do
        v.icon:Setup(newSetup)
    end

    local debuffs = internalFunc.buffBar.GetDebuffIcons()
    for k, v in pairs(debuffs) do
        v.icon:Setup(newSetup)
    end
    
    EnKai.ui.reloadDialog("nkUI")
end