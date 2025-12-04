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
        local from, to, object, x, y = "BOTTOMLEFT", "TOPLEFT", frame, 0, -22 
        local lastIcon
        local firstBuffIcon = frame

        for k, v in pairs (unitBuffDisplayList) do
            local icon = unitBuffIcons[k].icon
            icon:ClearAll()
            icon:ClearPoint("BOTTOMLEFT")
            icon:SetPoint(from, object, to, x, y)
            icon:Setup(frame:GetBuffSetup())
            lastIcon = icon
            from, to, object, x, y = "TOPLEFT", "TOPRIGHT", lastIcon, 2, 0

            if idx == 1 then firstBuffIcon = icon end
        end

        from, to, object, x, y = "TOPLEFT", "BOTTOMLEFT", frame, 0, 10 
        lastIcon = nil

        for k, v in pairs (unitDebuffDisplayList) do
            local icon = unitDebuffIcons[k].icon
            icon:ClearAll()
            icon:SetPoint(from, object, to, x, y)
            icon:Setup(frame:GetBuffSetup())
            lastIcon = icon
            from, to, object, x, y = "TOPLEFT", "TOPRIGHT", lastIcon, 5 , 0
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
                        if unitDebuffDisplayList[buffIdentifier] == nil then
                            unitDebuffDisplayList[buffIdentifier] = true

                            if unitDebuffIcons[buffIdentifier] == nil then
                                -- Use the icon manager to get an icon
                                local icon = _internal.iconManager.get(unitType, "debuffIcon." .. buffIdentifier, buffSetup, 0, 0)
                                unitDebuffIcons[buffIdentifier] = {
                                    icon = icon,
                                    visible = true,
                                    details = v
                                }
                                unitDebuffIcons[buffIdentifier].icon:SetBuff(buffUnit, buffIdentifier)
                                unitDebuffIcons[buffIdentifier].icon:SetEffect(privateVars.effects.gloss)
                                unitDebuffIcons[buffIdentifier].icon:ShowBorder(true)
                            else
                                unitDebuffIcons[buffIdentifier].details = details                                
                                unitDebuffIcons[buffIdentifier].visible = true
                            end

                            unitDebuffIcons[buffIdentifier].remaining = v.remaining
                            unitDebuffIcons[buffIdentifier].duration = v.duration
                            unitDebuffIcons[buffIdentifier].start = InspectTimeReal()

                            unitDebuffIcons[buffIdentifier].icon:SetStack(v.stack)

                            if v.poison then
                                unitDebuffIcons[buffIdentifier].icon:SetBorderColor(0, 0.5, 0, 1)
                            elseif v.curse then
                                unitDebuffIcons[buffIdentifier].icon:SetBorderColor(0.5, 0.25, 0, 1)
                            elseif v.disease then
                                unitDebuffIcons[buffIdentifier].icon:SetBorderColor(0.5, 0, 0.5, 1)
                            elseif v.debuff then
                                unitDebuffIcons[buffIdentifier].icon:SetBorderColor(0.5, 0, 0, 1)
                            end

                            unitDebuffIcons[buffIdentifier].icon:SetTexture("Rift", v.icon)
                            unitDebuffIcons[buffIdentifier].icon:SetVisible(true)
                        else
                            unitDebuffIcons[buffIdentifier].remaining = v.remaining
                            unitDebuffIcons[buffIdentifier].duration = v.duration
                            unitDebuffIcons[buffIdentifier].start = InspectTimeReal()
                        end
                    end
                else
                    if (v.remaining and v.remaining < nkUISetup.modules.unitFrames.buffDuration) then
                        if (unitBuffDisplayList[buffIdentifier] == nil) then
                           unitBuffDisplayList[buffIdentifier] = true

                            if unitBuffIcons[buffIdentifier] == nil then
                                -- Use the icon manager to get an icon
                                local icon = _internal.iconManager.get(unitType, "buffIcon." .. buffIdentifier, buffSetup, 0, 0)
                                unitBuffIcons[buffIdentifier] = {
                                    icon = icon,
                                    visible = true,
                                    details = v
                                }
                                unitBuffIcons[buffIdentifier].icon:SetBuff(buffUnit, buffIdentifier)
                                unitBuffIcons[buffIdentifier].icon:SetEffect(privateVars.effects.gloss)
                                unitBuffIcons[buffIdentifier].icon:ShowBorder(true)
                            else
                                unitBuffIcons[buffIdentifier].details = details
                                unitBuffIcons[buffIdentifier].visible = true
                            end

                            unitBuffIcons[buffIdentifier].duration = v.duration
                            unitBuffIcons[buffIdentifier].remaining = v.remaining
                            unitBuffIcons[buffIdentifier].start = InspectTimeReal()

                            unitBuffIcons[buffIdentifier].icon:SetStack(v.stack)

                            if InspectSystemSecure() == false then unitBuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha) end

                            unitBuffIcons[buffIdentifier].icon:SetTexture("Rift", v.icon)
                            unitBuffIcons[buffIdentifier].icon:SetVisible(true)
                        else
                            unitBuffIcons[buffIdentifier].duration = v.duration
                            unitBuffIcons[buffIdentifier].remaining = v.remaining
                            unitBuffIcons[buffIdentifier].start = InspectTimeReal()
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
                    unitBuffIcons[buffType].icon:SetVisible(false)
                    --EnKai.tools.table.removeValue(unitBuffDisplayList, id)
                    unitBuffDisplayList[buffType] = nil
                elseif unitDebuffIcons[buffType] then
                    unitDebuffIcons[buffType].visible = false
                    unitDebuffIcons[buffType].icon:SetVisible(false)
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