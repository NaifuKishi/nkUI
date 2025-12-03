local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
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

    local from, to, object, x, y = "CENTER", "CENTER", UIParent, nkUISetup.modules.buffBar.x, nkUISetup.modules.buffBar.y
    local lastIcon
    local firstBuffIcon

    local sortedBuffs = {}
    local sortedDebuffs = {}

    for k, v in pairs (buffDisplayList) do
        local icon = buffIcons[k].icon
        icon:ClearPoint("TOPLEFT")
        icon:ClearPoint("CENTER")
        icon:SetPoint(from, object, to, x, y)
        from, to, object, x, y = "TOPLEFT", "TOPRIGHT", icon, 5, 0

        if firstBuffIcon == nil then firstBuffIcon = icon end
    end

    if firstBuffIcon == nil then firstBuffIcon = UIParent end
    from, to, object, x, y = "TOPLEFT", "BOTTOMLEFT", firstBuffIcon, 0, 20

    for k, v in pairs (debuffDisplayList) do
        local icon = debuffIcons[k].icon
        icon:SetPoint(from, object, to, x, y)
        
        from, to, object, x, y = "TOPLEFT", "TOPRIGHT", icon, 5, 0
    end
end

function _internal.buffBar.addBuff(unit, buffs)

    local details = InspectBuffDetail(unit, buffs)

    for k, v in pairs(details) do

        local buffIdentifier = v.type
        buffId2BuffType[k] = buffIdentifier        

        if v.poison == true or v.curse == true or v.disease == true or v.debuff == true then
            if debuffDisplayList[buffIdentifier] == nil then

                if debuffIcons[buffIdentifier] == nil then 
                    local icon = _internal.iconManager.get(data.playerID, "buffbar.debuffIcon." .. buffIdentifier, nkUISetup.modules.buffBar.buffs, 0, 0)
                    debuffIcons[buffIdentifier] = { icon = icon, visible = true, name = v.name, duration = v.duration, remaining = v.remaining, start = InspectTimeReal() }
                    
                    debuffIcons[buffIdentifier].icon:SetBuff(unit, buffIdentifier)
                    debuffIcons[buffIdentifier].icon:SetEffect(privateVars.effects.gloss)
                    debuffIcons[buffIdentifier].icon:ShowBorder(true)
                    debuffIcons[buffIdentifier].icon:Setup(nkUISetup.modules.buffBar.buffs)
                else
                    debuffIcons[buffIdentifier].visible = true
                end

                if v.poison then
                    debuffIcons[buffIdentifier].icon:SetBorderColor(0, 0.5, 0, 1)
                elseif v.curse then
                    debuffIcons[buffIdentifier].icon:SetBorderColor(0.5, 0.25, 0, 1)
                elseif v.disease then
                    debuffIcons[buffIdentifier].icon:SetBorderColor(0.5, 0, 0.5, 1)
                elseif v.debuff then
                    debuffIcons[buffIdentifier].icon:SetBorderColor(0.5, 0, 0, 1)
                end

                debuffIcons[buffIdentifier].icon:SetStack(v.stack)
                debuffIcons[buffIdentifier].icon:SetTexture("Rift", v.icon)
                debuffIcons[buffIdentifier].icon:SetVisible(true)
                
                debuffDisplayList[buffIdentifier] = true
            else
                debuffIcons[buffIdentifier].remaining = v.remaining
                debuffIcons[buffIdentifier].start = InspectTimeReal()
            end
        else

            if buffDisplayList[buffIdentifier] == nil then

                if buffIcons[buffIdentifier] == nil then 
                    local icon = _internal.iconManager.get(data.playerID, "buffbar.buffIcon." .. buffIdentifier, nkUISetup.modules.buffBar.buffs, 0, 0)
                    buffIcons[buffIdentifier] = { icon = icon, visible = true, name = v.name, duration = v.duration, remaining = v.remaining, start = InspectTimeReal() }

                    buffIcons[buffIdentifier].icon:SetBuff(unit, k)
                    buffIcons[buffIdentifier].icon:SetEffect(privateVars.effects.gloss)
                    buffIcons[buffIdentifier].icon:ShowBorder(true)
                    buffIcons[buffIdentifier].icon:Setup(nkUISetup.modules.buffBar.buffs)
                else
                    buffIcons[buffIdentifier].visible = true
                end

                buffIcons[buffIdentifier].icon:SetStack(v.stack)
                buffIcons[buffIdentifier].icon:SetTexture("Rift", v.icon)
                buffIcons[buffIdentifier].icon:SetVisible(true)

                buffDisplayList[buffIdentifier] = true
            else
                buffIcons[buffIdentifier].remaining = v.remaining
                buffIcons[buffIdentifier].start = InspectTimeReal()
            end
        end					
    end
end

function _internal.buffBar.removeBuff (unit, buffs)
    
    for id, v in pairs(buffs) do

        local buffType = buffId2BuffType[id]

        if buffIcons[buffType] then
            buffIcons[buffType].visible = false
            buffIcons[buffType].icon:SetVisible(false)
            buffDisplayList[buffType] = nil 
        elseif debuffIcons[buffType] then
            debuffIcons[buffType].visible = false
            debuffIcons[buffType].icon:SetVisible(false)
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