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

local mathFloor     = math.floor
local stringFormat  = string.format

---------- init global variables ---------

data.unitFramesBuild = false
uiElements.frames = {}

---------- init local variables ---------

local name = "uiFrames"

---------- init variables ---------

local callingColor = {
    rogue = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = 1, g = .96, b = .41, a = 1, position = 0},  { r =.5, g = .5, b = .5, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}},
    warrior = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = .79, g = .61, b = .43, a = 1, position = 0},  { r =.5, g = .5, b = .5, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}},
    cleric = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = 1, g = 1, b = 1, a = 1, position = 0},  { r =1, g = 1, b = 1, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}},
    mage = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = 0.25, g = .78, b = .92, a = 1, position = 0},  { r =.5, g = .5, b = .5, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}},
    primalist = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = 0, g = .44, b = .87, a = 1, position = 0},  { r =.5, g = .5, b = .5, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}},
    default = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = .4, g = .67, b = .05, a = 1, position = 0},  { r =.5, g = .5, b = .5, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}}
}

---------- local function block ---------

-- Create a frame manager
local frameManager = {
    activeFrames = {},
    framePool = {}
}

function frameManager.get(unitType, scale, x, y, reverse)
    
    -- Check if frame already exists

    if frameManager.activeFrames[unitType] then
        return frameManager.activeFrames[unitType]
    end

    -- Check pool for available frames
    if #frameManager.framePool > 0 then
        local frame = table.remove(frameManager.framePool)
        frame:SetVisible(true)
        frame:ClearAll()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
        frame:SetWidth(250 * scale)
        frame:SetHeight(35 * scale)
        frame:SetBackgroundColor(0, 0, 0, .5)

        -- Reset other frame properties as needed
        -- ...

        frameManager.activeFrames[unitType] = frame
        return frame
    end

    -- Create new frame if none available
    local healthMax = 0
    local thisName = EnKai.tools.uuid()
    local thisUnitID = nil

    local unitBuffIcons = {}
    local unitDebuffIcons = {}
    local unitBuffDisplayList = {}
    local unitDebuffDisplayList = {}


    local unitFrame = EnKai.uiCreateFrame("nkFrame", thisName .. ".unitFrame", uiElements.context)
    unitFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
    unitFrame:SetWidth(250 * scale)
    unitFrame:SetHeight(35 * scale)
    unitFrame:SetBackgroundColor(0, 0, 0, .5)
    unitFrame:SetVisible(false)

    local oSetAlpha = unitFrame.SetAlpha
    function unitFrame:SetAlpha(newAlpha)
        oSetAlpha(self, newAlpha)

        for k, v in pairs(unitDebuffIcons) do
            v.icon:SetAlpha(newAlpha)
        end

        for k, v in pairs(unitBuffIcons) do
            v.icon:SetAlpha(newAlpha)
        end
    end
    
    local secureFrame = EnKai.uiCreateFrame("nkFrame", thisName .. ".unitFrame.secure", uiElements.secureContext)
    secureFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
    secureFrame:SetWidth(250 * scale)
    secureFrame:SetHeight(35 * scale)
    secureFrame:SetBackgroundColor(0, 0, 0, 0)

    function unitFrame:SetMacro (newMacro)
        secureFrame:SetSecureMode("restricted")
        secureFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, newMacro)
    end

    function unitFrame:ContextMenu(unitID)
        secureFrame.Event.RightClick =
        	function()
                if thisUnitID then Command.Unit.Menu(thisUnitID) end
        	end
    end

    --data.unitFramesBuild = true

    local healthFrame = EnKai.uiCreateFrame("nkCanvas", thisName .. ".healthFrame", unitFrame)
    
    if reverse then
        healthFrame:SetPoint("TOPRIGHT", unitFrame, "TOPRIGHT", -1, 1)
    else
        healthFrame:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, 1)
    end

    healthFrame:SetWidth(248 * scale)
    healthFrame:SetHeight(33 * scale)  

    local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1 }
    local path = {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }  
  
    local nameText = EnKai.uiCreateFrame("nkText", thisName .. ".nameText", healthFrame)

    if reverse then
        nameText:SetPoint("BOTTOMRIGHT", unitFrame, "TOPRIGHT", -2, 0)
    else
        nameText:SetPoint("BOTTOMLEFT", unitFrame, "TOPLEFT", 2, 0)
    end

    nameText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    nameText:SetFontSize(16 * scale)
    nameText:SetFontColor(1, 1, 1, 1)
    nameText:SetEffectGlow({ strength = 1})

    local healthText = EnKai.uiCreateFrame("nkText", thisName .. ".healthText", healthFrame)

    if reverse then
        healthText:SetPoint("BOTTOMLEFT", unitFrame, "TOPLEFT", 2, 15)
    else
        healthText:SetPoint("BOTTOMRIGHT", unitFrame, "TOPRIGHT", -2, 15)
    end

    healthText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    healthText:SetFontSize(28 * scale)
    healthText:SetFontColor(1, 1, 1, 1)
    healthText:SetEffectGlow({ offsetX = 1, offsetY = 1})

    local energyText = EnKai.uiCreateFrame("nkText", thisName .. ".energyText", healthFrame)

    if reverse then
        energyText:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 2, -12)
    else
        energyText:SetPoint("TOPRIGHT", unitFrame, "BOTTOMRIGHT", -2, -12)
    end

    energyText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    energyText:SetFontSize(14 * scale)
    energyText:SetFontColor(1, 1, 1, 1)
    energyText:SetEffectGlow({ offsetX = 1, offsetY = 1})

    local planarText = EnKai.uiCreateFrame("nkText", thisName .. ".planarText", healthFrame)

    if reverse then
        planarText:SetPoint("CENTERRIGHT", unitFrame, "CENTERRIGHT", -4, 0)
    else
        planarText:SetPoint("CENTERLEFT", unitFrame, "CENTERLEFT", 4, 0)
    end

   
    planarText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    planarText:SetFontSize(12 * scale)
    planarText:SetFontColor(1, 1, 1, 1)
    planarText:SetEffectGlow({ colorR = 0, colorG = 0, colorB = 0, strength = 3, })

    -- buff management

    function unitFrame:GetBuffIcons() return unitBuffIcons end
    function unitFrame:GetDebuffIcons() return unitDebuffIcons end
    function unitFrame:GetBuffDisplayList() return unitBuffDisplayList end
    function unitFrame:GetDebuffDisplayList() return unitDebuffDisplayList end
    function unitFrame:SetBuffIcons(icons) unitBuffIcons = icons end
    function unitFrame:SetDebuffIcons(icons) unitDebuffIcons = icons end
    function unitFrame:SetBuffDisplayList(list) unitBuffDisplayList = list end
    function unitFrame:SetDebuffDisplayList(list) unitDebuffDisplayList = list end

    function unitFrame:addBuff(buffUnit, buffs) _internal.manageBuffs(self, thisUnitID, buffUnit, buffs, "add") end
    function unitFrame:changeBuff(unit, buffs) _internal.manageBuffs(self, thisUnitID, unit, buffs, "change") end
    function unitFrame:ClearBuffs() _internal.manageBuffs(self, thisUnitID, nil, nil, "clear") end
    function unitFrame:removeBuff(buffUnit, buffs) _internal.manageBuffs(self, thisUnitID, buffUnit, buffs, "remove") end

    function unitFrame:SetUnitID (newId) thisUnitID = newId end
    function unitFrame:GetUnitID () return thisUnitID end

    function unitFrame:GetScale() return scale end

    function unitFrame:SetCalling (calling)
        local fill = callingColor[calling or "default"]
        healthFrame:SetShape (path, fill, nil)            
    end

    function unitFrame:SetName (name) 
        if string.len (name) > 10 then
            local splitName = EnKai.strings.split(name, " ")

            if #splitName == 1 then
                splitName = EnKai.strings.split(name, "-")
            end

            if #splitName == 1 then
                thisName = string.sub(name, 1, 10)
            else
                thisName = ""
                for idx = 1, #splitName -1, 1 do                    
                    local tempName = string.sub(splitName[idx], 1, 1)                    
                    thisName = thisName .. tempName .. ". "                    
                end

                thisName = thisName .. splitName[#splitName]
            end
        else
            thisName = name
        end

        nameText:SetText(thisName)
    end

    function unitFrame:SetPlanar (planar) 
        if planar then
            planarText:SetText(stringFormat("%d", planar)) 
            planarText:SetVisible(true)
        else
            planarText:SetVisible(false)
        end
    end    

    function unitFrame:SetEnergy (energy)
        if energy then
            energyText:SetText(stringFormat("%d", energy))
        end
    end

    function unitFrame:SetHealthMax (newHealthMax) 
        healthMax = newHealthMax
    end

    function unitFrame:SetHealth (health) 
        local playerHealthPercent = health / healthMax
        healthText:SetText(stringFormat("%d", mathFloor(playerHealthPercent*100)))
        healthFrame:SetWidth(248 * scale * playerHealthPercent)
    end

    function unitFrame:ProcessUnitDetails (newUnitID)
        local details = InspectUnitDetail(newUnitID)
        if (details) then
            unitFrame:SetCalling(details.calling)
            unitFrame:SetHealthMax(details.healthMax)
            unitFrame:SetHealth(details.health)
            
            if details.energy then
                unitFrame:SetEnergy(details.energy)
            elseif details.power then
                unitFrame:SetEnergy(details.power)
            elseif details.mana then
                unitFrame:SetEnergy(details.mana)
            end

            unitFrame:SetPlanar(details.planar)        
            unitFrame:SetName(details.name)
        end
    end

    frameManager.activeFrames[unitType] = unitFrame
    return unitFrame
end

function frameManager.release(unitType)
    if frameManager.activeFrames[unitType] then
        frameManager.activeFrames[unitType]:SetVisible(false)
        table.insert(frameManager.framePool, frameManager.activeFrames[unitType])
        frameManager.activeFrames[unitType] = nil
    end
end

function frameManager.clearAll()
    for k, v in pairs(frameManager.activeFrames) do
        v:SetVisible(false)
        table.insert(frameManager.framePool, v)
    end
    frameManager.activeFrames = {}
end

function _internal.uiFrames()

        -- Use the frame manager to get frames
    local player = frameManager.get("player", data.uiScaleX, 1320 * data.uiScaleX, 1000 * data.uiScaleY, false)
    player:SetUnitID(Inspect.Unit.Lookup('player'))
    player:SetVisible(true)
    player:SetMacro("/target @self")

    local playerRessourceBar = _internal.ressourcBar("player", data.uiScaleX, 1620 * data.uiScaleX, 1020 * data.uiScaleY)
    local playerCastbar = _internal.createCastBar("player", playerRessourceBar)

    local playerPet = frameManager.get("player.pet", .75 * data.uiScaleX, 1000 * data.uiScaleX, 1050 * data.uiScaleY, false)
    playerPet:SetMacro("/target @pet")

    local target = frameManager.get("target", data.uiScaleX, (2120 - 250) * data.uiScaleX, 1000 * data.uiScaleY, true)
    local targetCastbar = _internal.createCastBar("player.target", playerRessourceBar)

    function playerRessourceBar:update (unitID)
        if (unitID == data.playerID) then
            local details = EnKai.unit.GetUnitDetail(unitID)

            if details.combo then playerRessourceBar:SetCombo(details.combo) end

            if details.focus then
                data.processPlayerFocus = true
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

    function player:update (unitID)
        local details = EnKai.unit.GetUnitDetail(unitID)

        player:SetCalling(details.calling)
        player:SetHealthMax(details.healthMax)
        player:SetName(details.name)
        player:SetHealth(details.health)

        if (details.energy) then
            player:SetEnergy(details.energy)
        elseif (details.power) then
            player:SetEnergy(details.power)
        elseif (details.mana) then
            player:SetEnergy(details.mana)
        elseif (details.focus) then
            player:SetEnergy(details.focus - 100)
        end

        player:SetPlanar(details.planar)
    end

    function target:update (frame, unitID)
        local details = EnKai.unit.GetUnitDetail(unitID)

        target:SetCalling(details.calling)
        target:SetHealthMax(details.healthMax)
        target:SetName(details.name)
        target:SetHealth(details.health)
        target:SetEnergy(details.energy)
        target:SetPlanar(details.planar)

        if (details.energy) then
            player:SetEnergy(details.energy)
        elseif (details.power) then
            player:SetEnergy(details.power)
        elseif (details.mana) then
            player:SetEnergy(details.mana)
        elseif (details.focus) then
            player:SetEnergy(details.focus - 100)
        end
    end

    function playerPet:update (unitID)
        local details = InspectUnitDetail(unitID)

        playerPet:SetCalling(details.calling)
        playerPet:SetHealthMax(details.healthMax)
        playerPet:SetName(details.name)
        playerPet:SetHealth(details.health)
    end

    uiElements.frames = {
        player = player,
        playerCastbar = playerCastbar,
        playerPet = playerPet,
        target = target,
        targetCastbar = targetCastbar,
        playerRessourceBar = playerRessourceBar
    }

    uiElements.frames.player:SetAlpha(0.2)
    uiElements.frames.playerPet:SetAlpha(0.2)
    uiElements.frames.target:SetAlpha(0.2)

    _events.uiFramesInitEvents()
	
end

function _internal.uiFramesToggle(value)

    if value == true and not uiElements.frames.player then
        _internal.uiFrames ()
        uiElements.frames.player:update(EnKai.unit.getPlayerDetails().id)
        uiElements.frames.playerRessourceBar:update (EnKai.unit.getPlayerDetails().id)
    end

    if uiElements.frames then        
        for k, v in pairs (uiElements.frames) do
            v:SetVisible(false)
        end
    end

    uiElements.frames.player:SetVisible(value)
    uiElements.frames.target:SetVisible(value)

end