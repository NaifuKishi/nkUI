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
local inspectAddonCurrent   = Inspect.Addon.Current

local mathFloor             = math.floor
local stringFormat          = string.format
local stringFind            = string.find

local LibEKLUnitGetPlayerDetails    = LibEKL.Unit.getPlayerDetails
local LibEKLUnitGetUnitByIdentifier = LibEKL.Unit.GetUnitByIdentifier

local frameCache = {}

-- Buff management function

local function processIconTimers (icons)

    local curTime = InspectTimeReal()

    for _, thisIcon in pairs (icons) do
        if thisIcon.remaining then
            local timer = thisIcon.duration - (curTime - thisIcon.start)
            if timer > 0 then
                thisIcon.icon:SetTimer(timer)
            else
                thisIcon.icon:Clear()
                thisIcon.remaining = nil
            end
        end
    end

end

local function updateBuffDisplay(frame, unitBuffDisplayList, unitDebuffDisplayList, unitBuffIcons, unitDebuffIcons)

    local buffSetup = frame:GetBuffSetup()    
    local x = 0
    local y = - (buffSetup.height + (30 * data.uiScale))

    -- Sort buffs by remaining time (ascending order)
    local sortedBuffs = {}
    for buffID, buffDetails in pairs(unitBuffDisplayList) do
        local remaining = unitBuffIcons[buffID].remaining or 999999
        table.insert(sortedBuffs, {key = buffID, remaining = remaining})
    end

    table.sort(sortedBuffs, function(a, b) return a.remaining < b.remaining end)

    -- Limit to 9 buffs if it's a unit frame (not buffbar)
    local maxBuffs = (unitType == "buffbar") and #sortedBuffs or math.min(nkUISetup.modules.unitFrames.maxBuffCount, #sortedBuffs)

    for i = 1, maxBuffs do
        local details = sortedBuffs[i]
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

function internalFunc.manageBuffs(frame, unitType, unitID, buffUnit, buffs, action)

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internalFunc.manageBuffs - " .. unitType .. " " .. action, frame:GetName(), { unitType = unitType, unitID = unitID, buffUnit = buffUnit, buffs = buffs, action = action}) end

    -- Buff management variables
    local unitBuffIcons = frame:GetBuffIcons() or {}
    local unitDebuffIcons = frame:GetDebuffIcons() or {}
    local unitBuffDisplayList = frame:GetBuffDisplayList() or {}
    local unitDebuffDisplayList = frame:GetDebuffDisplayList() or {}
    local unitBuffId2BuffType = frame:GetBuffId2BuffTypeList() or {}

    if action == "add" then
        if buffUnit == unitID then

            local details = InspectBuffDetail(buffUnit, buffs)

            if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internalFunc.manageBuffs", "details", details) end

            local targetID = LibEKLUnitGetUnitByIdentifier ("player.target")
            local playerID = LibEKLUnitGetPlayerDetails().id
            local isSecure = InspectSystemSecure()
            local isGroup = stringFind(unitType, "group")

            for buffID, buffDetails in pairs(details) do

                local buffIdentifier = buffDetails.type
                unitBuffId2BuffType[buffID] = buffIdentifier

                if buffDetails.poison == true or buffDetails.curse == true or buffDetails.disease == true or buffDetails.debuff == true then

                    if unitID ~= targetID or (unitID == targetID and buffDetails.caster == playerID ) then                    

                        internalFunc.processNewBuff (unitType, "unit." .. unitType .. ".debuff.icon." .. buffIdentifier, buffID, buffIdentifier, buffDetails, unitDebuffDisplayList, unitDebuffIcons, frame)

                        if not isSecure and not isGroup then
                            unitDebuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha) 
                        else
                            unitDebuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.combatAlpha)  
                        end
                    end
                else
                    if (buffDetails.remaining and buffDetails.remaining < nkUISetup.modules.unitFrames.buffDuration) then

                        if not nkUISetup.modules.unitFrames.showOnlyOwnBuffs or buffDetails.caster == playerID or unitType == "target" then

                            internalFunc.processNewBuff (unitType, "unit." .. unitType .. ".buff.icon." .. buffIdentifier, buffID, buffIdentifier, buffDetails, unitBuffDisplayList, unitBuffIcons, frame)
                            
                            if not isSecure and not isGroup then
                                unitBuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha) 
                            else
                                unitBuffIcons[buffIdentifier].icon:SetAlpha(nkUISetup.modules.unitFrames.combatAlpha)  
                            end
                        end

                    end
                end
                
            end
        end

        updateBuffDisplay(frame, unitBuffDisplayList, unitDebuffDisplayList, unitBuffIcons, unitDebuffIcons)
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
                local thisBuffIcon = unitBuffIcons[buffType]
                local thisDebuffIcon = unitDebuffIcons[buffType]

                if thisBuffIcon then
                    thisBuffIcon.visible = false
                    thisBuffIcon.icon:Clear()
                    thisBuffIcon.lastX = nil
                    unitBuffDisplayList[buffType] = nil
                elseif thisDebuffIcon then
                    thisDebuffIcon.visible = false
                    thisDebuffIcon.icon:Clear()
                    thisDebuffIcon.lastX = nil
                    unitDebuffDisplayList[buffType] = nil
                end

                internalFunc.iconManager.release(unitType, buffType)
            end
        end

        updateBuffDisplay(frame, unitBuffDisplayList, unitDebuffDisplayList, unitBuffIcons, unitDebuffIcons)
    end    

    -- Update frame's buff management data
    frame:SetBuffIcons(unitBuffIcons)
    frame:SetDebuffIcons(unitDebuffIcons)
    frame:SetBuffDisplayList(unitBuffDisplayList)
    frame:SetDebuffDisplayList(unitDebuffDisplayList)
    frame:SetBuffId2BuffTypeList(unitBuffId2BuffType)

end

function internalFunc.processBuffs()

	--- process buffs and debuffs

    processIconTimers (internalFunc.buffBar:GetBuffIcons())
    processIconTimers (internalFunc.buffBar:GetDebuffIcons())

    --- process player

    local playerFrame = uiElements.frames["player"]

    processIconTimers (playerFrame:GetBuffIcons())
    processIconTimers (playerFrame:GetDebuffIcons())

	--- process pet

	if LibEKL.Unit.GetUnitIDByType ("player.pet")  then
        local playerPetFrame = uiElements.frames["player.pet"]
        processIconTimers (playerPetFrame:GetBuffIcons())
        processIconTimers (playerPetFrame:GetDebuffIcons())
    end

	--- process target

    if LibEKLUnitGetUnitByIdentifier("player.target") then
        local playerTarget = uiElements.frames["player.target"]
        processIconTimers (playerTarget:GetBuffIcons())
        processIconTimers (playerTarget:GetDebuffIcons())
	end

    --- process groups

    local groupStatus, groupSize = LibEKL.Unit.getGroupStatus()

    if groupStatus == "group" then

        for idx = 1, 5, 1 do
            local groupName = stringFormat("group%02d", idx)
            local id = LibEKL.Unit.GetUnitIDByType(groupName)

            --if LibEKLUnitGetUnitByIdentifier(groupName) then
            if id and #id >0 then
                local groupFrame = uiElements.frames[groupName]
                processIconTimers (groupFrame:GetBuffIcons())
                processIconTimers (groupFrame:GetDebuffIcons())
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

    local debugId  
	if nkDebug then debugId = nkDebug.traceStart (inspectAddonCurrent(), "nkUI internalFunc.processNewBuff") end

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internalFunc.processNewBuff - " .. unitType, "parameters", { unitType = unitType, iconName = iconName, buffID = buffID, buffIdentifier = buffIdentifier, displayList = displayList}) end
    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internalFunc.processNewBuff - " .. unitType, "buffDetails", buffDetails) end

    local thisIcon

    if displayList[buffIdentifier] == nil then

        thisIcon = icons[buffIdentifier]
        local icon

        if thisIcon == nil then 
            --local icon = internalFunc.iconManager.get(unitID, iconName, nkUISetup.modules.buffBar.buffs, 0, 0)
            icon = internalFunc.iconManager.get(unitType, iconName)
            icons[buffIdentifier] = { icon = icon, visible = true, name = buffDetails.name }

            thisIcon = icons[buffIdentifier]

            if unitType == "buffbar" then
                icon:ShowBorder(true)
            else
                icon:ShowBorder(false)
            end
            icon:Setup(nkUISetup.modules.buffBar.buffs)
            icon:SetTexture("Rift", buffDetails.icon)
            icon:SetParent(parent)

            if buffDetails.poison then
                icon:SetBorderColor(0, 0.5, 0, 1)
            elseif buffDetails.curse then
                icon:SetBorderColor(0.5, 0.25, 0, 1)
            elseif buffDetails.disease then
                icon:SetBorderColor(0.5, 0, 0.5, 1)
            elseif buffDetails.debuff then
                icon:SetBorderColor(0.5, 0, 0, 1)
            end
        else
            thisIcon.visible = true
            icon = thisIcon.icon
        end
        
        icon:SetStack(buffDetails.stack)        
        icon:SetVisible(true)
        
        displayList[buffIdentifier] = true
    else
        thisIcon = icons[buffIdentifier]
    end

    thisIcon.remaining = buffDetails.remaining
    thisIcon.duration = buffDetails.duration
    thisIcon.icon:SetBuff(buffID)
    thisIcon.icon:SetTooltip(buffDetails.name, buffDetails.description)

    if buffDetails.remaining == nil or buffDetails.duration == nil then
        thisIcon.start = InspectTimeReal()
    else
        thisIcon.start = InspectTimeReal() - (buffDetails.duration - buffDetails.remaining)
    end

    if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "nkUI internalFunc.processNewBuff", debugId) end

end