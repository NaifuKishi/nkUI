local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local _events       = privateVars.events

---------- init local variables ---------

-- Cache frequently used functions and values
local InspectUnitDetail     = Inspect.Unit.Detail
local InspectBuffDetail     = Inspect.Buff.Detail
local InspectUnitLookup     = Inspect.Unit.Lookup
local InspectBuffList       = Inspect.Buff.List
local InspectTimeReal       = Inspect.Time.Real
local InspectSystemSecure   = Inspect.System.Secure

local mathFloor             = math.floor
local stringFormat          = string.format
local stringFind            = string.find

---------- init global variables ---------

local EFFECT_GLOSS = { alpha = 0.6, texturePath = 'gfx/iconDesignGloss.png', replaceBorder = false }

-- Buff management function

function internalFunc.manageBuffs(frame, unitType, unitID, buffUnit, buffs, action)

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internalFunc.manageBuffs", frame:GetName(), { unitID = unitID, buffUnit = buffUnit, buffs = buffs, action = action}) end

    -- Buff management variables
    local unitBuffIcons = frame:GetBuffIcons() or {}
    local unitDebuffIcons = frame:GetDebuffIcons() or {}
    local unitBuffDisplayList = frame:GetBuffDisplayList() or {}
    local unitDebuffDisplayList = frame:GetDebuffDisplayList() or {}
    local unitBuffId2BuffType = frame:GetBuffId2BuffTypeList() or {}

    local buffSetup = frame:GetBuffSetup()

    local function updateBuffDisplay()
        
        local buffSetup = frame:GetBuffSetup()
        local x = 0
        local y = - (buffSetup.height + (30 * data.uiScale))

        -- Sort buffs by remaining time
        local sortedBuffs = {}
        for buffID, buffDetails in pairs(unitBuffDisplayList) do
            local remaining = unitBuffIcons[buffID].remaining or 999999
            table.insert(sortedBuffs, {key = buffID, remaining = remaining})
        end

        table.sort(sortedBuffs, function(a, b) return a.remaining > b.remaining end)

        for _, details in ipairs(sortedBuffs) do
            local thisIcon = unitBuffIcons[details.key]

            if thisIcon.lastX ~= x then
                local icon = thisIcon.icon
                icon:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
                icon:Setup(buffSetup)
            end

            thisIcon.lastX = x
            x = x + buffSetup.width + 2
        end

        x, y = 0, frame:GetHeight() + (10 * data.uiScale)

        -- Sort debuffs by remaining time
        local sortedDebuffs = {}
        for debuffID, debuffDetails in pairs(unitDebuffDisplayList) do
            local remaining = unitDebuffIcons[debuffID].remaining or 999999
            table.insert(sortedDebuffs, {key = debuffID, remaining = remaining})
        end
        table.sort(sortedDebuffs, function(a, b) return a.remaining > b.remaining end)

        for _, details in ipairs(sortedDebuffs) do
            local thisIcon = unitDebuffIcons[details.key]

            if thisIcon.lastX ~= x then
                local icon = thisIcon.icon
                icon:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
                icon:Setup(buffSetup)
            end

            thisIcon.lastX = x
            x = x + buffSetup.width + 2
        end
    end

    if action == "add" then
        if buffUnit == unitID then

            local details = InspectBuffDetail(buffUnit, buffs)

            if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internalFunc.manageBuffs", "details", details) end

            for buffID, buffDetails in pairs(details) do

                local buffIdentifier = buffDetails.type
                unitBuffId2BuffType[buffID] = buffIdentifier

                if buffDetails.poison == true or buffDetails.curse == true or buffDetails.disease == true or buffDetails.debuff == true then

                    local targetID = LibEKL.unit.GetUnitByIdentifier ("player.target")

                    if unitID ~= targetID or (unitID == LibEKL.unit.GetUnitByIdentifier ("player.target") and buffDetails.caster == LibEKL.unit.getPlayerDetails().id) then                    

                        internalFunc.processNewBuff (unitType, "unit." .. unitType .. ".debuff.icon." .. buffIdentifier, buffID, buffIdentifier, buffDetails, unitDebuffDisplayList, unitDebuffIcons, frame)

                        --if InspectSystemSecure() == false and stringFind(unitType, "group") == false then
                        if InspectSystemSecure() == false then
                            unitDebuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha) 
                        else
                            unitDebuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.combatAlpha)  
                        end

                    end
                else
                    if (buffDetails.remaining and buffDetails.remaining < nkUISetup.modules.unitFrames.buffDuration) then

                        internalFunc.processNewBuff (unitType, "unit." .. unitType .. ".buff.icon." .. buffIdentifier, buffID, buffIdentifier, buffDetails, unitBuffDisplayList, unitBuffIcons, frame)
                        
                        --if InspectSystemSecure() == false and stringFind(unitType, "group") == false then
                        if InspectSystemSecure() == false then
                            unitBuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha) 
                        else
                            unitBuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.combatAlpha)  
                        end

                    end
                end
                
            end
        end

        updateBuffDisplay()
    elseif action == "change" then
        -- Handle buff changes if needed
    elseif action == "clear" then
        for k, v in pairs(unitBuffIcons) do
            v.visible = false
            v.icon:SetVisible(false)
            v.lastX = nil

            internalFunc.iconManager.release(unitType, k)
        end

        for k, v in pairs(unitDebuffIcons) do
            v.visible = false
            v.icon:SetVisible(false)
             v.lastX = nil

            internalFunc.iconManager.release(unitType, k)
        end

        unitBuffDisplayList = {}
        unitDebuffDisplayList = {}
    elseif action == "remove" then
        if buffUnit == unitID then
            for id, v in pairs(buffs) do

                local buffType = unitBuffId2BuffType[id]

                if unitBuffIcons[buffType] then
                    unitBuffIcons[buffType].visible = false
                    unitBuffIcons[buffType].icon:Clear()
                    unitBuffIcons[buffType].lastX = nil
                    --LibEKL.tools.table.removeValue(unitBuffDisplayList, id)
                    unitBuffDisplayList[buffType] = nil
                elseif unitDebuffIcons[buffType] then
                    unitDebuffIcons[buffType].visible = false
                    unitDebuffIcons[buffType].icon:Clear()
                    unitDebuffIcons[buffType].lastX = nil
                    --LibEKL.tools.table.removeValue(unitDebuffDisplayList, id)
                    unitDebuffDisplayList[buffType] = nil
                end

                internalFunc.iconManager.release(unitType, buffType)
            end
        end

        updateBuffDisplay()
    end    

    -- Update frame's buff management data
    frame:SetBuffIcons(unitBuffIcons)
    frame:SetDebuffIcons(unitDebuffIcons)
    frame:SetBuffDisplayList(unitBuffDisplayList)
    frame:SetDebuffDisplayList(unitDebuffDisplayList)
    frame:SetBuffId2BuffTypeList(unitBuffId2BuffType)

end


function internalFunc.processBuffs ()

	--- process buffs and debuffs

    local buffIcons = internalFunc.buffBar:GetBuffIcons()
    local debuffIcons = internalFunc.buffBar:GetDebuffIcons()

    for k, thisIcon in pairs (buffIcons) do
        if thisIcon.remaining then
            thisIcon.icon:SetTimer(thisIcon.duration - (InspectTimeReal() - thisIcon.start))
        end
    end

    for k, thisIcon in pairs (debuffIcons) do
        if thisIcon.remaining then
            thisIcon.icon:SetTimer(thisIcon.duration - (InspectTimeReal() - thisIcon.start))
        end
    end

    --- process player

    local playerFrame = uiElements.frames["player"]
    local playerBuffIcons = playerFrame:GetBuffIcons()
    local playerDebuffIcons = playerFrame:GetDebuffIcons()

    for k, thisIcon in pairs (playerBuffIcons) do
        if thisIcon.remaining then
            thisIcon.icon:SetTimer(thisIcon.duration - (InspectTimeReal() - thisIcon.start))
        end
    end

    for k, thisIcon in pairs (playerDebuffIcons) do
        if thisIcon.remaining then
            thisIcon.icon:SetTimer(thisIcon.duration - (InspectTimeReal() - thisIcon.start))
        end
    end

	--- process pet

	if data.playerPetID then

        local playerPetFrame = uiElements.frames["player.pet"]

        local playerPetBuffIcons = playerPetFrame:GetBuffIcons()
        local playerPetDebuffIcons = playerPetFrame:GetDebuffIcons()

        for k, thisIcon in pairs (playerPetBuffIcons) do
            if thisIcon.remaining then
                thisIcon.icon:SetTimer(thisIcon.duration - (InspectTimeReal() - thisIcon.start))
            end
        end

        for k, thisIcon in pairs (playerPetDebuffIcons) do
            if thisIcon.remaining then
                thisIcon.icon:SetTimer(thisIcon.duration - (InspectTimeReal() - thisIcon.start))
            end
        end
    end

	--- process target

	if LibEKL.unit.GetUnitByIdentifier("player.target") then

        local targetFrame = uiElements.frames["player.target"]

        local targetBuffIcons = targetFrame:GetBuffIcons()

        local targetDebuffIcons = targetFrame:GetDebuffIcons()

        for k, thisIcon in pairs (targetBuffIcons) do
            if thisIcon.remaining then             
                thisIcon.icon:SetTimer(thisIcon.duration - (InspectTimeReal() - thisIcon.start))
            end
        end

        for k, thisIcon in pairs (targetDebuffIcons) do
            if thisIcon.remaining then
                thisIcon.icon:SetTimer(thisIcon.duration - (InspectTimeReal() - thisIcon.start))
            end
        end
	end

    --- process groups

    local groupStatus, groupSize = LibEKL.unit.getGroupStatus()

    if groupStatus == "group" then

        for idx = 1, 5, 1 do
            local groupName = stringFormat("group%02d", idx)

            if LibEKL.unit.GetUnitByIdentifier(groupName) then

                local targetFrame = uiElements.frames[groupName]

                local targetBuffIcons = targetFrame:GetBuffIcons()
                local targetDebuffIcons = targetFrame:GetDebuffIcons()

                for k, thisIcon in pairs (targetBuffIcons) do
                    if thisIcon.remaining then             
                        thisIcon.icon:SetTimer(thisIcon.duration - (InspectTimeReal() - thisIcon.start))
                    end
                end

                for k, thisIcon in pairs (targetDebuffIcons) do
                    if thisIcon.remaining then
                        thisIcon.icon:SetTimer(thisIcon.duration - (InspectTimeReal() - thisIcon.start))
                    end
                end
            end
        end
    end
end

--function internalFunc.processNewBuff (iconName, unitID, unit, buffID, buffIdentifier, buffDetails, displayList, icons)

-- unitType         player, player.target etc
-- iconName         Name of the icon
-- buffID           the id of that specific buff (not the type)
-- buffIdentifier   the type of buff
-- buffDetails      Details of the buff
-- displayList      displayed buffs
-- icons            icon list
-- parent           parent of the icon

function internalFunc.processNewBuff (unitType, iconName, buffID, buffIdentifier, buffDetails, displayList, icons, parent)

    if displayList[buffIdentifier] == nil then

        if icons[buffIdentifier] == nil then 
            --local icon = internalFunc.iconManager.get(unitID, iconName, nkUISetup.modules.buffBar.buffs, 0, 0)
            local icon = internalFunc.iconManager.get(unitType, iconName)
            icons[buffIdentifier] = { icon = icon, visible = true, name = buffDetails.name }
            
            icons[buffIdentifier].icon:SetEffect(EFFECT_GLOSS)
            icons[buffIdentifier].icon:ShowBorder(true)
            icons[buffIdentifier].icon:Setup(nkUISetup.modules.buffBar.buffs)
            icons[buffIdentifier].icon:SetTexture("Rift", buffDetails.icon)
            icons[buffIdentifier].icon:SetParent(parent)

            if buffDetails.poison then
                icons[buffIdentifier].icon:SetBorderColor(0, 0.5, 0, 1)
            elseif buffDetails.curse then
                icons[buffIdentifier].icon:SetBorderColor(0.5, 0.25, 0, 1)
            elseif buffDetails.disease then
                icons[buffIdentifier].icon:SetBorderColor(0.5, 0, 0.5, 1)
            elseif buffDetails.debuff then
                icons[buffIdentifier].icon:SetBorderColor(0.5, 0, 0, 1)
            end
        else
            icons[buffIdentifier].visible = true
        end
        
        icons[buffIdentifier].icon:SetStack(buffDetails.stack)        
        icons[buffIdentifier].icon:SetVisible(true)
        
        displayList[buffIdentifier] = true
    end

    icons[buffIdentifier].remaining = buffDetails.remaining
    icons[buffIdentifier].duration = buffDetails.duration
    icons[buffIdentifier].icon:SetBuff(buffID)
    icons[buffIdentifier].icon:SetTooltip(buffDetails.name, buffDetails.description)

    if buffDetails.remaining == nil or buffDetails.duration == nil then
        icons[buffIdentifier].start = InspectTimeReal()
    else
        icons[buffIdentifier].start = InspectTimeReal() - (buffDetails.duration - buffDetails.remaining)
    end

end