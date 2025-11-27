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
local InspectBuffList       = Inspect.Buff.List
local InspectUnitLookup     = Inspect.Unit.Lookup

local mathFloor     = math.floor
local stringFormat  = string.format
local stringLen     = string.len
local stringSub     = string.sub

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

--[[
   _frameManager.get
    Description:
        Retrieves or creates a unit frame for a specific unit type. This function manages a pool of reusable frames to optimize performance.
    Parameters:
        unitType (string): The type of unit (e.g., "player", "target", "player.pet")
        scale (number): The scaling factor for the frame size
        x (number): The x-coordinate position for the frame
        y (number): The y-coordinate position for the frame
        reverse (boolean): Whether to position the frame from the right side
    Returns:
        frame (table): The configured unit frame with all child elements and functionality
    Process:
        1. Checks if a frame already exists for the specified unit type
        2. If not, checks the frame pool for available frames to reuse
        3. If no reusable frames are available, creates a new frame
        4. Configures the frame with the specified parameters
        5. Sets up the frame's visual elements (health bar, name text, etc.)
        6. Implements frame-specific functionality (buff management, unit details, etc.)
        7. Adds the frame to the active frames collection
    Notes:
        - The function maintains a pool of reusable frames to optimize performance
        - Frames are created with secure and non-secure components for proper UI functionality
        - The frame includes various visual elements like health bar, name text, and energy text
        - Buff management functionality is implemented for tracking buffs and debuffs
        - The frame supports unit details like health, energy, and planar values
        - Positioning can be reversed for right-aligned frames
        - Each frame is uniquely identified and can be accessed by unit type
    Available Methods:
        - SetMacro(newMacro): Sets the macro to be executed when the frame is clicked
        - ContextMenu(unitID): Sets up the context menu for the frame
        - SetUnitID(newId): Sets the unit ID associated with the frame
        - GetUnitID(): Returns the unit ID associated with the frame
        - GetScale(): Returns the scaling factor of the frame
        - SetCalling(calling): Sets the calling color for the frame
        - SetName(name): Sets the unit name text
        - SetPlanar(planar): Sets the planar value text
        - SetEnergy(energy): Sets the energy value text
        - SetHealthMax(newHealthMax): Sets the maximum health value
        - SetHealth(health): Updates the health bar and text
        - ProcessUnitDetails(newUnitID): Updates the frame with unit details
        - GetBuffIcons(): Returns the buff icons collection
        - GetDebuffIcons(): Returns the debuff icons collection
        - GetBuffDisplayList(): Returns the buff display list
        - GetDebuffDisplayList(): Returns the debuff display list
        - SetBuffIcons(icons): Sets the buff icons collection
        - SetDebuffIcons(icons): Sets the debuff icons collection
        - SetBuffDisplayList(list): Sets the buff display list
        - SetDebuffDisplayList(list): Sets the debuff display list
        - addBuff(buffUnit, buffs): Adds buffs to the frame
        - changeBuff(unit, buffs): Changes buffs on the frame
        - ClearBuffs(): Clears all buffs from the frame
        - removeBuff(buffUnit, buffs): Removes buffs from the frame
]]
function frameManager.get(unitType, scale, x, y, reverse, unitFrameType)
    
    local unitFrameWidth
    local frameWidth, frameHeight = 250 * scale, 35 * scale

    if unitFrameType == "raid" then
        frameWidth, frameHeight = 100 * scale, 45 * scale
    end

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
        frame:SetWidth(frameWidth)
        frame:SetHeight(frameHeight)
        frame:SetBackgroundColor(0, 0, 0, .5)

        -- Reset other frame properties as needed
        -- ...

        frameManager.activeFrames[unitType] = frame
        return frame
    end

    -- Create new frame if none available
    local healthMax
    local energyMax
    local thisName = EnKai.tools.uuid()
    local thisUnitID = nil

    local unitBuffIcons = {}
    local unitDebuffIcons = {}
    local unitBuffDisplayList = {}
    local unitDebuffDisplayList = {}


    local unitFrame = EnKai.uiCreateFrame("nkFrame", thisName .. ".unitFrame", uiElements.context)
    unitFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
    unitFrame:SetWidth(frameWidth)
    unitFrame:SetHeight(frameHeight)    
    unitFrame:SetVisible(false)

    if unitFrameType == "raid" then
        unitFrame:SetBackgroundColor(0.4, 0.4, 0.4, .5)
    else
        unitFrame:SetBackgroundColor(0, 0, 0, .5)
    end

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
    secureFrame:SetWidth(frameWidth)
    secureFrame:SetHeight(frameHeight)
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

    local healthFrame = EnKai.uiCreateFrame("nkCanvas", thisName .. ".healthFrame", unitFrame)
    healthFrame:SetLayer(1)

    if reverse then
        healthFrame:SetPoint("TOPRIGHT", unitFrame, "TOPRIGHT", -1, 1)
    else
        healthFrame:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, 1)
    end

    healthFrame:SetWidth((frameWidth -2))
    healthFrame:SetHeight((frameHeight -2))  

    local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1 }
    local path = {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }  
  
    local nameText = EnKai.uiCreateFrame("nkText", thisName .. ".nameText", healthFrame)

    if unitFrameType == "raid" then
        nameText:SetPoint("CENTER", unitFrame, "CENTER", 2 * scale, 0)
    elseif reverse then
        nameText:SetPoint("BOTTOMRIGHT", unitFrame, "TOPRIGHT", -2* scale, 0)
    else
        nameText:SetPoint("BOTTOMLEFT", unitFrame, "TOPLEFT", 2* scale, 0)
    end

    nameText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    nameText:SetFontSize(16 * scale)
    nameText:SetFontColor(1, 1, 1, 1)
    nameText:SetEffectGlow({ strength = 1})
    nameText:SetLayer(2)

    local healthText = EnKai.uiCreateFrame("nkText", thisName .. ".healthText", healthFrame)

    if reverse then
        healthText:SetPoint("BOTTOMLEFT", unitFrame, "TOPLEFT", 2* scale, 15* scale)
    else
        healthText:SetPoint("BOTTOMRIGHT", unitFrame, "TOPRIGHT", -2* scale, 15* scale)
    end

    healthText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    healthText:SetFontSize(28 * scale)
    healthText:SetFontColor(1, 1, 1, 1)
    healthText:SetEffectGlow({ offsetX = 1, offsetY = 1})
    

    if unitFrameType == "raid" then healthText:SetVisible(false) end

    local energyText = EnKai.uiCreateFrame("nkText", thisName .. ".energyText", healthFrame)

    if reverse then
        energyText:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 2 * scale, -12 * scale)
    else
        energyText:SetPoint("TOPRIGHT", unitFrame, "BOTTOMRIGHT", -2 * scale, -12 * scale)
    end

    energyText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    energyText:SetFontSize(14 * scale)
    energyText:SetFontColor(1, 1, 1, 1)
    energyText:SetEffectGlow({ offsetX = 1, offsetY = 1})
    energyText:SetLayer(2)

    if unitFrameType == "raid" then energyText:SetVisible(false) end

    local planarText = EnKai.uiCreateFrame("nkText", thisName .. ".planarText", healthFrame)

    if reverse then
        planarText:SetPoint("CENTERRIGHT", unitFrame, "CENTERRIGHT", -4* scale, 0)
    else
        planarText:SetPoint("CENTERLEFT", unitFrame, "CENTERLEFT", 4* scale, 0)
    end

    planarText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    planarText:SetFontSize(12 * scale)
    planarText:SetFontColor(1, 1, 1, 1)
    planarText:SetEffectGlow({ colorR = 0, colorG = 0, colorB = 0, strength = 3, })
    planarText:SetLayer(2)

    if unitFrameType == "raid" then planarText:SetVisible(false) end

    local combatIcon = EnKai.uiCreateFrame("nkTexture", thisName .. ".combatIcon", unitFrame)
    combatIcon:SetLayer(99)
    combatIcon:SetPoint("CENTERRIGHT", unitFrame, "CENTERLEFT", -5 * scale, 0)
    combatIcon:SetHeight(30 * scale)
    combatIcon:SetWidth(30 * scale)
    combatIcon:SetVisible(false)
    combatIcon:SetTextureAsync(addonInfo.identifier, "gfx/iconCombat.png")

    local roleIcon = EnKai.uiCreateFrame("nkTexture", thisName .. ".roleIcon", unitFrame)
    roleIcon:SetLayer(99)
    roleIcon:SetHeight(20 * scale)
    roleIcon:SetWidth(20 * scale)
    roleIcon:SetVisible(false)    

    if unitFrameType == "raid" then
        roleIcon:SetPoint("CENTERLEFT", unitFrame, "CENTERLEFT", 2, 0)
    elseif unitType == "target" then
        roleIcon:SetPoint("CENTERRIGHT", nameText, "CENTERLEFT", -5 * scale, 0)
    else
        roleIcon:SetPoint("CENTERLEFT", nameText, "CENTERRIGHT", 5 * scale, 0)
    end
    
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
    function unitFrame:GetBuffScale() 
        if unitFrameType == "group" then
            return scale *.7
        else
            return scale
        end
    end

    function unitFrame:SetRole(newRole)

        if newRole == "dps" then
            roleIcon:SetVisible(true)
            roleIcon:SetTextureAsync(addonInfo.identifier, "gfx/roleDPS.png")
        elseif newRole == "tank" then 
            roleIcon:SetVisible(true)
            roleIcon:SetTextureAsync(addonInfo.identifier, "gfx/roleTank.png")
        elseif newRole == "heal" then
            roleIcon:SetVisible(true)
            roleIcon:SetTextureAsync(addonInfo.identifier, "gfx/roleHeal.png")
        else
            roleIcon:SetVisible(false)
        end
    end

    function unitFrame:SetCombat(state)
        combatIcon:SetVisible(state)
    end

    function unitFrame:SetCalling (calling)
        local fill = callingColor[calling or "default"]
        healthFrame:SetShape (path, fill, nil)            
    end

    function unitFrame:SetName (name) 
        local maxLen = 10
        if unitFrameType == "raid" then maxLen = 5 end

        if stringLen (name) > maxLen then
            local splitName = EnKai.strings.split(name, " ")

            if #splitName == 1 then
                splitName = EnKai.strings.split(name, "-")
            end

            if #splitName == 1 then
                thisName = stringSub(name, 1, maxLen)
            else
                thisName = ""
                for idx = 1, #splitName -1, 1 do                    
                    local tempName = stringSub(splitName[idx], 1, 1)                    
                    
                    if unitFrameType ~= "raid" then
                        thisName = thisName .. tempName .. ". "                    
                    end
                end

                thisName = thisName .. splitName[#splitName]
            end
        else
            thisName = name
        end

        nameText:SetText(thisName)
    end

    function unitFrame:SetPlanar (planar) 
        if planar and unitFrame:GetUnitFrameType() ~= "raid" then
            planarText:SetText(stringFormat("%d", planar)) 
            planarText:SetVisible(true)
        else
            planarText:SetVisible(false)
        end
    end    

    function unitFrame:SetEnergyMax (newEnergyMax) 
        energyMax = newEnergyMax
    end

    function unitFrame:SetEnergy (energy)
        if energy == nil then return end
        if energyMax == nil then energyMax = energy end

        if energy > energyMax then energy = energyMax end -- if this works we need to add some code for it

        local energyPercent = energy / energyMax
        energyText:SetText(stringFormat("%d", mathFloor(energyPercent*100)))
    end

    function unitFrame:SetHealthMax (newHealthMax) 
        healthMax = newHealthMax
    end

    function unitFrame:SetHealth (health) 
        if health == nil then return end
        if healthMax == nil then healthMax = health end

        if health > healthMax then health = healthMax end -- if this works we need to add some code for it

        if unitFrameWidth == nil then unitFrameWidth = (unitFrame:GetWidth() -2) end
        
        --print (health, healthMax, unitFrameWidth)

        if health == 0 then
            healthText:SetText("0")
            healthFrame:SetWidth(1)
        else
            local playerHealthPercent = health / healthMax
            healthText:SetText(stringFormat("%d", mathFloor(playerHealthPercent*100)))
            healthFrame:SetWidth(unitFrameWidth * playerHealthPercent)
        end
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

    function unitFrame:GetUnitFrameType()
        return unitFrameType or "standard"
    end

    frameManager.activeFrames[unitType] = unitFrame
    return unitFrame
end

--[[
   _frameManager.clearAll
    Description:
        Clears all active unit frames and returns them to the pool. This function is used to reset the frame manager.
    Process:
        1. Iterates through all active frames
        2. Hides each frame and adds it to the frame pool
        3. Clears the active frames collection
    Notes:
        - This function is useful for resetting the UI state
        - All frames are returned to the pool for potential reuse
        - The active frames collection is emptied after processing
]]
function frameManager.release(unitType)
    if frameManager.activeFrames[unitType] then
        frameManager.activeFrames[unitType]:SetVisible(false)
        table.insert(frameManager.framePool, frameManager.activeFrames[unitType])
        frameManager.activeFrames[unitType] = nil
    end
end


--[[
   _frameManager.clearAll
    Description:
        Clears all active unit frames and returns them to the pool. This function is used to reset the frame manager.
    Process:
        1. Iterates through all active frames
        2. Hides each frame and adds it to the frame pool
        3. Clears the active frames collection
    Notes:
        - This function is useful for resetting the UI state
        - All frames are returned to the pool for potential reuse
        - The active frames collection is emptied after processing
]]
function frameManager.clearAll()
    for k, v in pairs(frameManager.activeFrames) do
        v:SetVisible(false)
        table.insert(frameManager.framePool, v)
    end
    frameManager.activeFrames = {}
end


function _internal.updateUnit (frame, unitID)

    if frame == nil then return end

    local details = EnKai.unit.GetUnitDetail(unitID)

    if details == nil then return end

    if nkDebug then nkDebug.logEntry (addonInfo.identifier, "_internal.updateUnit", stringFormat("%s - %s", details.name, details.calling), details) end

    frame:SetUnitID(unitID)
    frame:SetName(details.name)
    frame:SetCalling(details.calling)

    if details.heatlthMax then 
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

    if details.planar then frame:SetPlanar(details.planar) end

    frame:SetRole(details.role)

end

--[[
   _internal.uiFrames
    Description:
        Initializes and sets up the unit frames for player, player pet, and target. This function creates and configures the main UI elements.
    Process:
        1. Uses the frame manager to get frames for player, player pet, and target
        2. Configures each frame with appropriate parameters
        3. Sets up event handlers for each frame
        4. Creates and configures resource bars and cast bars
        5. Sets up update functions for each frame
        6. Stores the frames in the uiElements.frames collection
        7. Initializes events for the UI frames
    Notes:
        - This function sets up the core UI elements for the addon
        - Each frame is configured with appropriate macros and event handlers
        - Resource bars and cast bars are created and linked to the frames
        - The function ensures proper initialization of all UI components
        - Events are initialized to handle updates and interactions
]]
function _internal.uiFrames()

    uiElements.frames = {}

        -- Use the frame manager to get frames
    local player = frameManager.get("player", data.uiScaleX, 1320 * data.uiScaleX, 1000 * data.uiScaleY, false, false)
    player:SetUnitID(Inspect.Unit.Lookup('player'))
    player:SetVisible(true)
    player:SetMacro("/target @self")

    uiElements.frames["player"] = player

    local playerRessourceBar = _internal.ressourcBar("player", data.uiScaleX, 1620 * data.uiScaleX, 1020 * data.uiScaleY)
    local playerCastbar = _internal.createCastBar("player", playerRessourceBar)

    uiElements.frames["player.castbar"] = playerCastbar
    uiElements.frames["player.ressourcebar"]  = playerRessourceBar  

    local playerPet = frameManager.get("player.pet", .75 * data.uiScaleX, 1000 * data.uiScaleX, 1050 * data.uiScaleY, false, false)
    playerPet:SetMacro("/target @pet")

    uiElements.frames["player.pet"] = playerPet

    local target = frameManager.get("target", data.uiScaleX, (2120 - 250) * data.uiScaleX, 1000 * data.uiScaleY, true, false)
    local targetCastbar = _internal.createCastBar("player.target", playerRessourceBar)

    uiElements.frames["player.target.castbar"] = targetCastbar
    uiElements.frames["player.target"] = target

    local from, object, to, x, y = "TOPLEFT", UIParent, "TOPLEFT", 600 * data.uiScaleX, 500 * data.uiScaleY

    for idx = 1, 5, 1 do
        local group = frameManager.get(stringFormat("group%02d", idx), (data.uiScaleX - .1), 0, 0, false, "group")
        group:SetPoint(from, object, to, x, y)
        group:SetMacro(stringFormat("/target @group%02d", idx))
        --group:SetVisible(true)
        --_internal.updateUnit (group, data.playerID)
        uiElements.frames[stringFormat("group%02d", idx)] = group

        to, object, x, y = "BOTTOMLEFT", group, 0, 80 * data.uiScaleY
    end

    local from, object, to, x, y = "TOPLEFT", UIParent, "TOPLEFT", 100 * data.uiScaleX, 500 * data.uiScaleY
    local firstRaid

    for idx1 = 0, 3, 1 do
        for idx2 = 1, 5, 1 do
            local index = idx1 * 5 + idx2

            local raid = frameManager.get(stringFormat("raid%02d", index), (data.uiScaleX - .1), 0, 0, false, "raid")
            raid:SetPoint(from, object, to, x, y)
            raid:SetMacro(stringFormat("/target @group%02d", index))
            --raid:SetVisible(true)
            --_internal.updateUnit (raid, data.playerID)
            uiElements.frames[stringFormat("raid%02d", index)] = raid

            to, object, x, y = "TOPRIGHT", raid, 2, 0

            if idx2 == 1 then firstRaid = raid end
        end

        to, object, x, y = "BOTTOMLEFT", firstRaid, 0, 2
    end

    --[[
    for idx = 1, 5, 1 do        
        local groupPet = frameManager.get(stringFormat("group%02d.pet", idx), (data.uiScaleX-.3), 0, 0, false)
        local group = uiElements.frames[stringFormat("group%02d", idx)]
        groupPet:ClearPoint("TOPLEFT")
        groupPet:SetPoint("BOTTOMLEFT", group, "BOTTOMRIGHT", 20, 0)
        groupPet:SetMacro(stringFormat("/target @group%02d.pet", idx))
        groupPet:SetWidth (148 * data.uiScaleX)
        --groupPet:SetVisible(true)        
        --_internal.updateUnit (groupPet, data.playerID)

        uiElements.frames[stringFormat("group%02d.pet", idx)] = group
    end
    ]]

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

    uiElements.frames["player"]:SetAlpha(nkUISetup.nonCombatAlpha)
    uiElements.frames["player.pet"]:SetAlpha(nkUISetup.nonCombatAlpha)
    uiElements.frames["player.target"]:SetAlpha(nkUISetup.nonCombatAlpha)

   _events.uiFramesInitEvents()
	
end

--[[
   _internal.uiFramesToggle
    Description:
        Toggles the visibility of the unit frames. This function controls whether the UI elements are shown or hidden.
    Parameters:
        value (boolean): Whether to show or hide the frames
    Process:
        1. Checks if the frames need to be initialized
        2. If initializing, calls _internal.uiFrames() to create the frames
        3. Updates the player and resource bar with current unit details
        4. Iterates through all frames and sets their visibility based on the value parameter
        5. Ensures the player and target frames are always visible when toggled on
    Notes:
        - This function provides a simple way to show or hide the UI
        - Initialization is performed only when needed
        - The function ensures proper visibility state for all frames
        - Player and target frames are always shown when toggled on
]]
function _internal.uiFramesToggle(value)

    if value == true and not uiElements.frames["player"] then
        _internal.uiFrames ()
        _internal.updateUnit (uiElements.frames["player"], EnKai.unit.getPlayerDetails().id)
        uiElements.frames["player.ressourcebar"]:update (EnKai.unit.getPlayerDetails().id)
    end

    if uiElements.frames then        
        for k, v in pairs (uiElements.frames) do
            v:SetVisible(false)
        end
    end

    uiElements.frames["player"]:SetVisible(value)
    uiElements.frames["player.target"]:SetVisible(value)

end

function _internal.uiFramesRemoveBuffs()

    local buffs = InspectBuffList(data.playerID)
    if (buffs) then uiElements.frames["player"]:removeBuff(data.playerID, buffs) end

    local targetFrame = uiElements.frames["player.target"]
    local targetID = EnKai.unit.GetUnitByIdentifier("player.target")

    if targetFrame:GetVisible() and targetID ~= nil then        
        local buffs = InspectBuffList(targetID)
        if (buffs) then targetFrame:removeBuff(targetID, buffss) end
    end

    local playerPetFrame = uiElements.frames["player.pet"]
    local playerPetID = EnKai.unit.GetUnitByIdentifier("player.pet")

    if playerPetFrame:GetVisible() and playerPetID ~= nil then        
        local buffs = InspectBuffList(playerPetID)
        if (buffs) then playerPetFrame:removeBuff(playerPetID, buffss) end
    end

end

function _internal.uiFramesLoadAllBuffs()

    local buffs = InspectBuffList(data.playerID)
    if (buffs) then uiElements.frames["player"]:addBuff(data.playerID, buffs) end

    local targetFrame = uiElements.frames["player.target"]

    local targetID = EnKai.unit.GetUnitByIdentifier("player.target")

    if targetFrame:GetVisible() and targetID ~= nil then        
        local buffs = InspectBuffList(targetID)
        if (buffs) then targetFrame:addBuff(targetID, buffss) end
    end

    local playerPetFrame = uiElements.frames["player.pet"]
    local playerPetID = EnKai.unit.GetUnitByIdentifier("player.pet")

    if playerPetFrame:GetVisible() and playerPetID ~= nil then        
        local buffs = InspectBuffList(playerPetID)
        if (buffs) then playerPetFrame:addBuff(playerPetID, buffss) end
    end
end

function _internal.getFrameByIdentifier(identifier)
    return uiElements.frames[identifier]
end

