local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events

---------- init local variables ---------

-- Cache frequently used functions and values
local inspectBuffList       = Inspect.Buff.List

local stringFormat  = string.format
local stringFind    = string.find

local LibEKLGetUnitDetail  = LibEKL.Unit.GetUnitDetail

---------- local function block ---------

function internalFunc.updateUnit (frame, unitID, identifier)

    if frame == nil then return end

    local details = LibEKLGetUnitDetail(unitID)

    if details == nil then return end

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "internalFunc.updateUnit " .. identifier, stringFormat("%s - %s", details.name, details.calling), details) end

    frame:SetUnitID(unitID)
    frame:ContextMenu(unitID)
    frame:MouseOverUnit(unitID)

    --print (identifier, details.name)

    frame:SetMacro(stringFormat("/target %s", details.name))
    frame:SetName(details.name)
    frame:SetCalling(details.calling)

    if details.healthMax then 
        frame:SetHealthMax(details.healthMax) 
    else
        frame:SetHealthMax(details.health) 
    end
    
    frame:SetHealth(details.health)

    if (details.energy) then
        frame:SetEnergyMax(details.energyMax or details.energy)
        frame:SetEnergy(details.energy)        
    elseif (details.power) then
        frame:SetEnergy(details.power)
    elseif (details.mana) then
        frame:SetEnergy(details.mana)
    elseif (details.focus) then
        frame:SetEnergy(details.focus - 100)
    end

    frame:SetPlanar(details.planar)
    frame:SetLevel(details.level)

    frame:SetRole(details.role)
    frame:SetTier(details.tier)
    frame:SetRare(details.guaranteedLoot)

    if details.afk then
        frame:SetAFK(details.afk)
    elseif details.offline then
        frame:SetOffline(details.offline)
    else
        frame:SetAFK()
    end

    frame:SetMark(details.mark)

    frame:ClearBuffs()

    local groupStatus, groupSize = LibEKL.Unit.GetGroupStatus()

    if stringFind (identifier, "group") and groupStatus ~= 'raid' then
        local buffs = inspectBuffList(unitID)
        if (buffs) then frame:addBuff(unitID, buffs) end
    elseif identifier == "player.target" then
        local buffs = inspectBuffList(unitID)
        if (buffs) then frame:addBuff(unitID, buffs) end
    end

end

function internalFunc.uiFrames()

    data.callingColor = data.colors.callings[nkUISetup.modules.unitFrames.colorScheme]

    uiElements.frames = {}

    local buffBarHolder = LibEKL.UICreateFrame("nkFrame", "nkUI.buffBar.holder", uiElements.unitFramesContext)
    buffBarHolder:SetPoint("CENTER", UIParent, "CENTER", nkUISetup.modules.buffBar.x, nkUISetup.modules.buffBar.y)
    uiElements.frames["buffBar"] = buffBarHolder

        -- Use the frame manager to get frames
    local player = internalFunc.FrameManagerGet("player", false, nkUISetup.modules.unitFrames.frames.player)
    player:SetUnitID(Inspect.Unit.Lookup('player'))
    player:SetVisible(true)
    player:SetMacro("/target @self")

    uiElements.frames["player"] = player

    local playerRessourceBar = internalFunc.ressourcBar("player", nkUISetup.modules.unitFrames.frames.ressourceBar)
    local playerCastbar = internalFunc.createCastBar("player", nkUISetup.modules.unitFrames.frames.playerCastBar)

    uiElements.frames["player.castbar"] = playerCastbar
    uiElements.frames["player.ressourcebar"] = playerRessourceBar  

    local playerPet = internalFunc.FrameManagerGet("player.pet", false, nkUISetup.modules.unitFrames.frames.playerPet)
    playerPet:SetMacro("/target @pet")

    uiElements.frames["player.pet"] = playerPet

    local target = internalFunc.FrameManagerGet("target", false, nkUISetup.modules.unitFrames.frames.target)
    local targetCastbar = internalFunc.createCastBar("player.target", nkUISetup.modules.unitFrames.frames.targetCastBar)

    uiElements.frames["player.target.castbar"] = targetCastbar
    uiElements.frames["player.target"] = target

    local targetOfTarget = internalFunc.FrameManagerGet("target.target", "raid", nkUISetup.modules.unitFrames.frames.targetOfTarget)
    uiElements.frames["player.target.target"] = targetOfTarget

    local focus = internalFunc.FrameManagerGet("focus", false, nkUISetup.modules.unitFrames.frames.focus)
    focus:SetMacro("/target @focus")
    uiElements.frames["focus"] = focus

    local setup = nkUISetup.modules.unitFrames.frames.group

    local from, object, to, x, y = "CENTER", UIParent, "CENTER", setup.x, setup.y

    for idx = 1, 5, 1 do
        local group = internalFunc.FrameManagerGet(stringFormat("group%02d", idx), "group", setup)
        group:ClearPoint("CENTER")
        group:SetPoint(from, object, to, x, y)
        group:SetMacro(stringFormat("/target @group%02d", idx))

        uiElements.frames[stringFormat("group%02d", idx)] = group

        from, to, object, x, y = "TOPLEFT", "BOTTOMLEFT", group, 0, 100 * data.uiScale
    end

    setup = nkUISetup.modules.unitFrames.frames.raid

    local from, object, to, x, y = "CENTER", UIParent, "CENTER", setup.x, setup.y
    local firstRaid

    for idx1 = 0, 3, 1 do
        for idx2 = 1, 5, 1 do
            local index = idx1 * 5 + idx2

            local raid = internalFunc.FrameManagerGet(stringFormat("raid%02d", index), "raid", setup)
            raid:ClearPoint("CENTER")
            raid:SetPoint(from, object, to, x, y)
            raid:SetMacro(stringFormat("/target @group%02d", index))
            uiElements.frames[stringFormat("raid%02d", index)] = raid

            from, to, object, x, y = "TOPLEFT", "TOPRIGHT", raid, 2, 0

            if idx2 == 1 then firstRaid = raid end
        end

        to, object, x, y = "BOTTOMLEFT", firstRaid, 0, 2
    end

    function playerRessourceBar:update (unitID)
        if (unitID == LibEKL.Unit.GetPlayerDetails().id) then
            local details = LibEKLGetUnitDetail(unitID)

            if details.combo then playerRessourceBar:SetCombo(details.combo) end

            if details.focus then
                playerRessourceBar:SetRessourceType("focus")
                playerRessourceBar:SetRessourceMax(200)
            end

            if details.charge then
                playerRessourceBar:SetCharge(details.charge)
            end

            if details.energy then
                playerRessourceBar:SetRessourceType("energy")
                playerRessourceBar:SetRessourceMax(details.energyMax)
                playerRessourceBar:SetRessource(details.energy)
            elseif details.power then
                playerRessourceBar:SetRessourceType("power")
                playerRessourceBar:SetRessourceMax(details.power)
                playerRessourceBar:SetRessource(details.power)
            elseif details.mana then
                playerRessourceBar:SetRessourceType("mana")
                playerRessourceBar:SetRessourceMax(details.mana)
                playerRessourceBar:SetRessource(details.mana)
            end
        end
    end    

    uiElements.frames["player"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
    uiElements.frames["focus"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
    uiElements.frames["player.pet"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
    uiElements.frames["player.target"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
    uiElements.frames["player.target.target"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)

   events.uiFramesInitEvents()
	
end

function internalFunc.uiFramesToggle(value)

    if value == true and not uiElements.frames["player"] then
        internalFunc.uiFrames ()
        internalFunc.updateUnit (uiElements.frames["player"], LibEKL.Unit.GetPlayerDetails().id, "player")
        uiElements.frames["player.ressourcebar"]:update (LibEKL.Unit.GetPlayerDetails().id)
    end

    if uiElements.frames then        
        for k, v in pairs (uiElements.frames) do
            v:SetVisible(false)
        end
    end

    uiElements.frames["player"]:SetVisible(value)
    uiElements.frames["player.target"]:SetVisible(value)

end

function internalFunc.uiFramesRemoveBuffs()

    local buffs = inspectBuffList(LibEKL.Unit.GetPlayerDetails().id)
    if (buffs) then uiElements.frames["player"]:removeBuff(LibEKL.Unit.GetPlayerDetails().id, buffs) end

    local targetFrame = uiElements.frames["player.target"]
    local targetID = LibEKL.Unit.GetUnitByIdentifier("player.target")

    if targetFrame:GetVisible() and targetID ~= nil then        
        local buffs = inspectBuffList(targetID)
        if (buffs) then targetFrame:removeBuff(targetID, buffs) end
    end

    local playerPetFrame = uiElements.frames["player.pet"]
    local playerPetID = LibEKL.Unit.GetUnitByIdentifier("player.pet")

    if playerPetFrame:GetVisible() and playerPetID ~= nil then        
        local buffs = inspectBuffList(playerPetID)
        if (buffs) then playerPetFrame:removeBuff(playerPetID, buffs) end
    end

end

function internalFunc.uiFramesLoadAllBuffs()

    local buffs = inspectBuffList(LibEKL.Unit.GetPlayerDetails().id)
    if (buffs) then uiElements.frames["player"]:addBuff(LibEKL.Unit.GetPlayerDetails().id, buffs) end

    local targetFrame = uiElements.frames["player.target"]

    local targetID = LibEKL.Unit.GetUnitByIdentifier("player.target")

    if targetFrame:GetVisible() and targetID ~= nil then        
        local buffs = inspectBuffList(targetID)
        if (buffs) then targetFrame:addBuff(targetID, buffs) end
    end

    local playerPetFrame = uiElements.frames["player.pet"]
    local playerPetID = LibEKL.Unit.GetUnitByIdentifier("player.pet")

    if playerPetFrame:GetVisible() and playerPetID ~= nil then        
        local buffs = inspectBuffList(playerPetID)
        if (buffs) then playerPetFrame:addBuff(playerPetID, buffs) end
    end
end

function internalFunc.getFrameByIdentifier(identifier)
    return uiElements.frames[identifier]
end

function internalFunc.uiFrameRedraw(bar)

    if bar == "group" then
        for idx = 1, 5, 1 do
            uiElements.frames[stringFormat("group%02d", idx)]:SetVisible(true)
            uiElements.frames[stringFormat("group%02d", idx)]:Redraw()
        end
    elseif bar == "raid" then
        for idx = 1, 20, 1 do
            uiElements.frames[stringFormat("raid%02d", idx)]:SetVisible(true)
            uiElements.frames[stringFormat("raid%02d", idx)]:Redraw()
        end
    else
        uiElements.frames[bar]:SetVisible(true) 
        uiElements.frames[bar]:Redraw() 
    end

    LibEKL.UI.reloadDialog ("nkUI")

end