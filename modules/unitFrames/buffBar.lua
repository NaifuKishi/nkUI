local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

---------- init local variables ---------

-- Cache frequently used functions and values
local InspectBuffDetail     = Inspect.Buff.Detail

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

function _internal.buffBar.GetBuffDisplayList ()
    return buffDisplayList
end

function _internal.buffBar.GetDebuffDisplayList ()
    return debuffDisplayList
end

function _internal.buffBar.UpdateBuffDisplay()

    local from, to, object, x, y = "TOPLEFT", "TOPLEFT", UIParent, 10, 10
    local lastIcon
    local firstBuffIcon = UIParent

    for idx = 1, #buffDisplayList do
        local icon = buffIcons[buffDisplayList[idx]].icon
        icon:SetPoint(from, object, to, x, y)
        lastIcon = icon
        from, to, object, x, y = "TOPLEFT", "TOPRIGHT", lastIcon, 5, 0

        if idx == 1 then firstBuffIcon = icon end
    end

    from, to, object, x, y = "TOPLEFT", "BOTTOMLEFT", firstBuffIcon, 0, 10
    lastIcon = nil

    for idx = 1, #debuffDisplayList do
        local icon = debuffIcons[debuffDisplayList[idx]].icon
        icon:SetPoint(from, object, to, x, y)
        lastIcon = icon
        from, to, object, x, y = "TOPLEFT", "TOPRIGHT", lastIcon, 5, 0
    end
end

function _internal.buffBar.addBuff(unit, buffs)

    local details = InspectBuffDetail(unit, buffs)            

    for k, v in pairs(details) do

        if v.poison == true or v.curse == true or v.disease == true or v.debuff == true then
            --print ("debuff")
            table.insert (debuffDisplayList, k)

            if debuffIcons[k] == nil then 
                debuffIcons[k] = { icon = uiElements.icon ("nkUI.debuffIcon." .. k, uiElements.context), visible = true, details = v }
                debuffIcons[k].icon:SetBuff(unit, k)
                debuffIcons[k].icon:SetEffect(privateVars.effects.gloss)
                debuffIcons[k].icon:ShowBorder(true)
                debuffIcons[k].icon:SetScale(data.uiScaleX)
            else
                debuffIcons[k].details = details
                debuffIcons[k].visible = true
            end

            if v.poison then
                debuffIcons[k].icon:SetBorderColor(0, 1, 0, 1)
            elseif v.curse then
                debuffIcons[k].icon:SetBorderColor(0, 1, 0, 1)
            elseif v.disease then
                debuffIcons[k].icon:SetBorderColor(0.85, 0.85, 0, 1)
            elseif v.debuff then
                debuffIcons[k].icon:SetBorderColor(0, 1, 0, 1)
            end

            debuffIcons[k].icon:SetTexture("Rift", v.icon)
            debuffIcons[k].icon:SetVisible(true)					
        else
            table.insert (buffDisplayList, k)

            if buffIcons[k] == nil then 
                buffIcons[k] = { icon = uiElements.icon ("nkUI.buffIcon." .. k, uiElements.context), visible = true, details = v }
                buffIcons[k].icon:SetBuff(unit, k)
                buffIcons[k].icon:SetEffect(privateVars.effects.gloss)
                buffIcons[k].icon:ShowBorder(true)
                buffIcons[k].icon:SetScale(data.uiScaleX)
            else
                buffIcons[k].details = details
                buffIcons[k].visible = true
            end

            buffIcons[k].icon:SetTexture("Rift", v.icon)
            buffIcons[k].icon:SetVisible(true)
        end					
    end
end

function _internal.buffBar.removeBuff (unit, buffs)

    for id, v in pairs(buffs) do
        if buffIcons[id] then
            buffIcons[id].visible = false
            buffIcons[id].icon:SetVisible(false)
            EnKai.tools.table.removeValue (buffDisplayList, id)
        elseif debuffIcons[id] then
            debuffIcons[id].visible = false
            debuffIcons[id].icon:SetVisible(false)
            EnKai.tools.table.removeValue (debuffDisplayList, id)
        end
    end
end