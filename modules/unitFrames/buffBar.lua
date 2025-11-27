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

    local from, to, object, x, y = "TOPLEFT", "TOPLEFT", UIParent, 10, 10
    local lastIcon
    local firstBuffIcon = UIParent

    local sortedBuffs = {}
    local sortedDebuffs = {}

    for k, v in pairs (buffDisplayList) do
        local icon = buffIcons[k].icon
        icon:SetPoint(from, object, to, x, y)
        from, to, object, x, y = "TOPLEFT", "TOPRIGHT", icon, 5, 0

        if firstBuffIcon == nil then firstBuffIcon = icon end
    end

    from, to, object, x, y = "TOPLEFT", "BOTTOMLEFT", firstBuffIcon, 0, 10

    for k, v in pairs (debuffDisplayList) do
        local icon = debuffIcons[k].icon
        icon:SetPoint(from, object, to, x, y)
        from, to, object, x, y = "TOPLEFT", "TOPRIGHT", icon, 5, 0
    end
end

function _internal.buffBar.addBuff(unit, buffs)

    local details = InspectBuffDetail(unit, buffs)            

    for k, v in pairs(details) do

        if v.poison == true or v.curse == true or v.disease == true or v.debuff == true then
            if debuffDisplayList[k] == nil then
                if debuffIcons[k] == nil then 
                    local icon = _internal.iconManager.get(data.playerID, "buffbar.debuffIcon." .. k, 1 * data.uiScaleX, 0, 0)
                    debuffIcons[k] = { icon = icon, visible = true, name = v.name, duration = v.duration, remaining = v.remaining, start = InspectTimeReal() }
                    
                    debuffIcons[k].icon:SetBuff(unit, k)
                    debuffIcons[k].icon:SetEffect(privateVars.effects.gloss)
                    debuffIcons[k].icon:ShowBorder(true)
                    debuffIcons[k].icon:SetScale(data.uiScaleX)
                else
                    --debuffIcons[k].details = details
                    debuffIcons[k].visible = true
                end

                if v.poison then
                    debuffIcons[k].icon:SetBorderColor(0, 0.5, 0, 1)
                elseif v.curse then
                    debuffIcons[k].icon:SetBorderColor(0.5, 0.25, 0, 1)
                elseif v.disease then
                    debuffIcons[k].icon:SetBorderColor(0.5, 0, 0.5, 1)
                elseif v.debuff then
                    debuffIcons[k].icon:SetBorderColor(0.5, 0, 0, 1)
                end

                debuffIcons[k].icon:SetStack(v.stack)
                debuffIcons[k].icon:SetTexture("Rift", v.icon)
                debuffIcons[k].icon:SetVisible(true)		
                
                debuffDisplayList[k] = true
            end
        else

            if buffDisplayList[k] == nil then

                if buffIcons[k] == nil then 
                    local icon = _internal.iconManager.get(data.playerID, "buffbar.buffIcon." .. k, 1 * data.uiScaleX, 0, 0)
                    buffIcons[k] = { icon = icon, visible = true, name = v.name, duration = v.duration, remaining = v.remaining, start = InspectTimeReal() }

                    --buffIcons[k] = { icon = uiElements.icon ("nkUI.buffIcon." .. k, uiElements.context), visible = true, details = v }
                    buffIcons[k].icon:SetBuff(unit, k)
                    buffIcons[k].icon:SetEffect(privateVars.effects.gloss)
                    buffIcons[k].icon:ShowBorder(true)
                    buffIcons[k].icon:SetScale(data.uiScaleX)
                else
                    --buffIcons[k].details = details
                    buffIcons[k].visible = true
                end

                buffIcons[k].icon:SetStack(v.stack)
                buffIcons[k].icon:SetTexture("Rift", v.icon)
                buffIcons[k].icon:SetVisible(true)

                buffDisplayList[k] = true
            end
        end					
    end
end

function _internal.buffBar.removeBuff (unit, buffs)

    for id, v in pairs(buffs) do
        if buffIcons[id] then
            buffIcons[id].visible = false
            buffIcons[id].icon:SetVisible(false)
            buffDisplayList[id] = nil 
        elseif debuffIcons[id] then
            debuffIcons[id].visible = false
            debuffIcons[id].icon:SetVisible(false)
            debuffDisplayList[id] = nil
        end
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