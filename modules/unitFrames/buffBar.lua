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

local LibEKLGetPlayerDetails = LibEKL.unit.getPlayerDetails

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

    local sortedBuffs = {}
    for buffID, buffDetails in pairs(buffDisplayList) do
        local remaining = buffIcons[buffID].remaining or 99999999
        table.insert(sortedBuffs, {key = buffID, remaining = remaining})
    end

    table.sort(sortedBuffs, function(a, b) return a.remaining > b.remaining end)

    local x = 0
    local debuffOffset = nkUISetup.modules.buffBar.buffs.height + 12
    local buffBarWidth = nkUISetup.modules.buffBar.buffs.width + 2

    for _, details in ipairs(sortedBuffs) do
        local thisIcon = buffIcons[details.key]

        if thisIcon.lastX ~= x then
            local icon = thisIcon.icon
            icon:SetPoint("TOPLEFT", uiElements.frames["buffBar"], "TOPLEFT", x, 0)
        end

        thisIcon.lastX = x
        x = x + buffBarWidth
    end
    
    -- Sort debuffs by remaining time
    local sortedDebuffs = {}
    for debuffID, debuffDetails in pairs(debuffDisplayList) do
        local remaining = debuffIcons[debuffID].remaining or 99999999
        table.insert(sortedDebuffs, {key = debuffID, remaining = remaining})
    end
    table.sort(sortedDebuffs, function(a, b) return a.time > b.time end)

    x = 0
    for _, details in ipairs(sortedDebuffs) do
        local thisIcon = debuffIcons[details.key]

        if thisIcon.lastX ~= x then
            local icon = thisIcon.icon
            icon:SetPoint("TOPLEFT", uiElements.frames["buffBar"], "TOPLEFT", x, debuffOffset)
        end

        thisIcon.lastX = x
        x = x + buffBarWidth
    end

end

-- Adds a buff to the display
-- @param unit The unit ID
-- @param buffs The buffs to add
function internalFunc.buffBar.addBuff(unit, buffs)
    local details = InspectBuffDetail(unit, buffs)

    for buffID, buffDetails in pairs(details) do
        local buffIdentifier = buffDetails.type

        if buffIdentifier == nil then
            LibEKL.tools.error.display("nkUI", "BuffBar addBuff - no type for buff " .. details.name, 2)
        else
            buffId2BuffType[buffID] = buffIdentifier
            
            if buffDetails.poison == true or buffDetails.curse == true or buffDetails.disease == true or buffDetails.debuff == true then
                internalFunc.processNewBuff("buffbar", "buffbar.debuff.icon." .. buffIdentifier, buffID, buffIdentifier, buffDetails, debuffDisplayList, debuffIcons, uiElements.frames["buffBar"])
            else
                internalFunc.processNewBuff("buffbar", "buffbar.buff.icon." .. buffIdentifier, buffID, buffIdentifier, buffDetails, buffDisplayList, buffIcons, uiElements.frames["buffBar"])
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
    local buffs = InspectBuffList(LibEKLGetPlayerDetails().id)
    internalFunc.buffBar.removeBuff(LibEKLGetPlayerDetails().id, buffs)
end

-- Loads all buffs for the player
function internalFunc.buffBar.loadAllBuffs()
    local buffs = InspectBuffList(LibEKLGetPlayerDetails().id)
    internalFunc.buffBar.addBuff(LibEKLGetPlayerDetails().id, buffs)
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
    
    LibEKL.ui.reloadDialog("nkUI")
end