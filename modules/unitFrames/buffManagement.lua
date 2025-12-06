local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

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

---------- init global variables ---------

-- Buff management function

function _internal.manageBuffs(frame, unitType, unitId, buffUnit, buffs, action)

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_internal.manageBuffs", frame:GetName(), { unitId = unitId, buffUnit = buffUnit, buffs = buffs, action = action}) end

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
        local y = - (buffSetup.height+30)
        

        for k, v in pairs (unitBuffDisplayList) do            
            if unitBuffIcons[k].lastX ~= x then
                local icon = unitBuffIcons[k].icon
                icon:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
                icon:Setup(buffSetup)
            end
            
            unitBuffIcons[k].lastX = x            
            x = x + buffSetup.width + 2            
        end

        x, y = 0, frame:GetHeight() + 20

        for k, v in pairs (unitDebuffDisplayList) do

            if unitDebuffIcons[k].lastX ~= x then
                local icon = unitDebuffIcons[k].icon
                icon:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
                icon:Setup(buffSetup)
            end
            
            unitDebuffIcons[k].lastX = x
            x = x + buffSetup.width + 2
        end
    end

    if action == "add" then
        if buffUnit == unitId then

            local details = InspectBuffDetail(buffUnit, buffs)

            if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_internal.manageBuffs", "details", details) end

            for k, v in pairs(details) do

                local buffIdentifier = v.type
                unitBuffId2BuffType[k] = buffIdentifier

                if v.poison == true or v.curse == true or v.disease == true or v.debuff == true then

                    local targetID = EnKai.unit.GetUnitByIdentifier ("player.target")

                    if unitId ~= targetID or (unitId == EnKai.unit.GetUnitByIdentifier ("player.target") and v.caster == data.playerID) then
                        
                        _internal.processNewBuff ("unit." .. unitId .. ".debuff.icon" .. buffIdentifier, unitId, buffUnit, k, buffIdentifier, v, unitDebuffDisplayList, unitDebuffIcons)                        

                        if InspectSystemSecure() == false then unitDebuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha) end

                    end
                else
                    if (v.remaining and v.remaining < nkUISetup.modules.unitFrames.buffDuration) then

                        _internal.processNewBuff ("unit." .. unitId .. ".buff.icon" .. buffIdentifier, unitId, buffUnit, k, buffIdentifier, v, unitBuffDisplayList, unitBuffIcons)                        
                        
                        if InspectSystemSecure() == false then unitBuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha) end
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

            _internal.iconManager.release(unitType, k)
        end

        for k, v in pairs(unitDebuffIcons) do
            v.visible = false
            v.icon:SetVisible(false)

            _internal.iconManager.release(unitType, k)
        end

        unitBuffDisplayList = {}
        unitDebuffDisplayList = {}
    elseif action == "remove" then
        if buffUnit == unitId then
            for id, v in pairs(buffs) do

                local buffType = unitBuffId2BuffType[id]

                if unitBuffIcons[buffType] then
                    unitBuffIcons[buffType].visible = false
                    unitBuffIcons[buffType].icon:Clear()
                    --EnKai.tools.table.removeValue(unitBuffDisplayList, id)
                    unitBuffDisplayList[buffType] = nil
                elseif unitDebuffIcons[buffType] then
                    unitDebuffIcons[buffType].visible = false
                    unitDebuffIcons[buffType].icon:Clear()
                    --EnKai.tools.table.removeValue(unitDebuffDisplayList, id)
                    unitDebuffDisplayList[buffType] = nil
                end

                _internal.iconManager.release(unitType, buffType)
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


function _internal.processBuffs ()

	--- process buffs and debuffs

    local buffIcons = _internal.buffBar:GetBuffIcons()
    local debuffIcons = _internal.buffBar:GetDebuffIcons()

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

	if EnKai.unit.GetUnitByIdentifier("player.target") then

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
end

function _internal.processNewBuff (iconName, unitID, unit, buffID, buffIdentifier, buffDetails, displayList, icons)

    if displayList[buffIdentifier] == nil then

        if icons[buffIdentifier] == nil then 
            local icon = _internal.iconManager.get(unitID, iconName, nkUISetup.modules.buffBar.buffs, 0, 0)
            icons[buffIdentifier] = { icon = icon, visible = true, name = buffDetails.name }
            
            icons[buffIdentifier].icon:SetBuff(unit, buffID)
            icons[buffIdentifier].icon:SetEffect(privateVars.effects.gloss)
            icons[buffIdentifier].icon:ShowBorder(true)
            icons[buffIdentifier].icon:Setup(nkUISetup.modules.buffBar.buffs)
            icons[buffIdentifier].icon:SetTexture("Rift", buffDetails.icon)

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

    if buffDetails.remaining == nil or buffDetails.duration == nil then
        icons[buffIdentifier].start = InspectTimeReal()
    else
        icons[buffIdentifier].start = InspectTimeReal() - (buffDetails.duration - buffDetails.remaining)
    end

end