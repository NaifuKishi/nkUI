local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc

---------- init local variables ---------

-- Cache frequently used functions and values
local inspectUnitDetail     = Inspect.Unit.Detail

local mathFloor     = math.floor
local stringFormat  = string.format

---------- init global variables ---------

local markIcons = { mark1 = "markIcon1.png", mark2 = "markIcon2.png", mark3 = "markIcon3.png", mark4 = "markIcon4.png", mark5 = "markIcon5.png", mark6 = "markIcon6.png", mark7 = "markIcon7.png", mark8 = "markIcon8.png",
                    mark9 = "markIconTank1.png", mark10 = "markIconHeal1.png", mark11 = "markIconDPS.png", mark12 = "markIconSupport.png",
                    mark13 = "markIconArrow.png", mark14 = "markIconSkull.png", mark15 = "markIconAvoid.png", mark16 = "markIconSmile.png", mark17 = "markIconSquirrel.png", mark18 = "markIconCrown.png",
                    mark19 = "markIconHeal2.png", mark20 = "markIconHeal3.png", mark21 = "markIconHeal4.png",
                    mark22 = "markIconHeart.png", mark23 = "markIconHeartLeftSide.png", mark24 = "markIconHeartRightSide.png", mark25 = "markIconRadioactive.png", mark26 = "markIconSad.png", 
                    mark27 = "markIconTank2.png", mark28 = "markIconTank3.png", mark29 = "markIconTank4.png", mark30 = "markIconLuck.png"
                }

uiElements.unitFramesContext = UI.CreateContext("nkUI.unitFrames")
uiElements.unitFramesContext:SetStrata('hud')
uiElements.unitFramesContext:SetLayer(1)

uiElements.unitFramesContextSecure = UI.CreateContext("nkUI.unitFrames.secure")
uiElements.unitFramesContextSecure:SetStrata('hud')
uiElements.unitFramesContextSecure:SetSecureMode("restricted")
uiElements.unitFramesContextSecure:SetLayer(99)

---------- init local variables ---------

local name = "uiFrames"

---------- local function block ---------

-- Create a frame manager
local frameManager = {
    activeFrames = {},
    framePool = {}
}

function internalFunc.FrameManagerGet(unitType, unitFrameType, setup)

    local unitFrameWidth
    local frameWidth, frameHeight = setup.width, setup.height

    -- Check if frame already exists

    if frameManager.activeFrames[unitType] then
        return frameManager.activeFrames[unitType]
    end

    -- Check pool for available frames
    if #frameManager.framePool > 0 then
        local frame = table.remove(frameManager.framePool)
        frame:SetVisible(true)
        frame:ClearAll()
        frame:SetPoint("CENTER", UIParent, "CENTER", setup.x, setup.y)
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
    local thisName = LibEKL.Tools.UUID()
    local thisUnitID = nil

    local unitBuffIcons = {}
    local unitDebuffIcons = {}
    local unitBuffDisplayList = {}
    local unitDebuffDisplayList = {}
    local unitBuffId2BuffType = {}

    local unitFrame = LibEKL.UICreateFrame("nkFrame", thisName .. ".unitFrame", uiElements.unitFramesContext)
    unitFrame:SetPoint("CENTER", UIParent, "CENTER", setup.x, setup.y)
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
    
    local secureFrame = LibEKL.UICreateFrame("nkFrame", thisName .. ".unitFrame.secure", uiElements.unitFramesContextSecure)
    secureFrame:SetPoint("CENTER", UIParent, "CENTER", setup.x, setup.y)
    secureFrame:SetWidth(frameWidth)
    secureFrame:SetHeight(frameHeight)
    --secureFrame:SetBackgroundColor(1, 0, 0, 1)
    secureFrame:SetSecureMode("restricted")
    secureFrame:SetVisible(false)

    function unitFrame:SetMacro (newMacro)
        LibEKL.Events.AddInsecure(function ()
            secureFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, newMacro)
        end)
    end

    function unitFrame:ContextMenu(unitID)
        LibEKL.Events.AddInsecure(function ()
            secureFrame.Event.RightClick =
                function()
                    if unitID then Command.Unit.Menu(unitID) end
                end
            end)
    end

    function unitFrame:MouseOverUnit(unitID)
        LibEKL.Events.AddInsecure(function ()
            secureFrame:SetMouseoverUnit(unitID)
        end)        
    end

    local healthFrame = LibEKL.UICreateFrame("nkCanvas", thisName .. ".healthFrame", unitFrame)
    healthFrame:SetLayer(1)

    if setup.reverse then
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
  
    local nameText = LibEKL.UICreateFrame("nkText", thisName .. ".nameText", healthFrame)

    if unitFrameType == "raid" then
        nameText:SetPoint("CENTER", unitFrame, "CENTER", 2, 0)
    elseif setup.reverse then
        nameText:SetPoint("BOTTOMRIGHT", unitFrame, "TOPRIGHT", -2, 0)
    else
        nameText:SetPoint("BOTTOMLEFT", unitFrame, "TOPLEFT", 2, 0)
    end

    nameText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    nameText:SetFontSize(setup.fontSizes.name)
    nameText:SetFontColor(1, 1, 1, 1)
    nameText:SetEffectGlow({ strength = 5})    
    nameText:SetLayer(2)

    local healthText = LibEKL.UICreateFrame("nkText", thisName .. ".healthText", healthFrame)

    if setup.reverse then
        healthText:SetPoint("BOTTOMLEFT", unitFrame, "TOPLEFT", 2, setup.margins.health)
    else
        healthText:SetPoint("BOTTOMRIGHT", unitFrame, "TOPRIGHT", -2, setup.margins.health)
    end

    healthText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    healthText:SetFontSize(setup.fontSizes.health)
    healthText:SetFontColor(1, 1, 1, 1)
    healthText:SetEffectGlow({ strength = 5})      

    if unitFrameType == "raid" then healthText:SetVisible(false) end

    local energyText = LibEKL.UICreateFrame("nkText", thisName .. ".energyText", healthFrame)

    if setup.reverse then
        energyText:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 2, -setup.margins.energy)
    else
        energyText:SetPoint("TOPRIGHT", unitFrame, "BOTTOMRIGHT", -2, -setup.margins.energy)
    end

    energyText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    energyText:SetFontSize(setup.fontSizes.energy)
    energyText:SetFontColor(1, 1, 1, 1)
    energyText:SetEffectGlow({ strength = 5})  
    energyText:SetLayer(2)

    if unitFrameType == "raid" then energyText:SetVisible(false) end

    local planarText = LibEKL.UICreateFrame("nkText", thisName .. ".planarText", healthFrame)

    if setup.reverse then
        planarText:SetPoint("CENTERRIGHT", unitFrame, "CENTERRIGHT", -setup.margins.planar, 0)
    else
        planarText:SetPoint("CENTERLEFT", unitFrame, "CENTERLEFT", setup.margins.planar, 0)
    end

    planarText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    planarText:SetFontSize(setup.fontSizes.planar)
    planarText:SetFontColor(1, 1, 1, 1)
    planarText:SetEffectGlow({ strength = 5})  
    planarText:SetLayer(2)

    local levelText = LibEKL.UICreateFrame("nkText", thisName .. ".levelText", healthFrame)

    if setup.reverse then
        levelText:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -setup.margins.level, 10)
    else
        levelText:SetPoint("BOTTOMLEFT", unitFrame, "BOTTOMLEFT", setup.margins.level, 10)
    end

    levelText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    levelText:SetFontSize(setup.fontSizes.level)
    levelText:SetFontColor(1, 1, 1, 1)
    levelText:SetEffectGlow({ strength = 5})  
    levelText:SetLayer(2)

    if unitFrameType == "raid" then levelText:SetVisible(false) end

    local combatIcon = LibEKL.UICreateFrame("nkTexture", thisName .. ".combatIcon", unitFrame)
    combatIcon:SetLayer(99)
    combatIcon:SetPoint("CENTERRIGHT", unitFrame, "CENTERLEFT", -5, 0)
    combatIcon:SetHeight(setup.iconSizes.combat)
    combatIcon:SetWidth(setup.iconSizes.combat)
    combatIcon:SetVisible(false)
    combatIcon:SetTextureAsync(addonInfo.identifier, "gfx/iconCombat.png")

    local markIcon = LibEKL.UICreateFrame("nkTexture", thisName .. ".markIcon", unitFrame)
    markIcon:SetLayer(99)
    markIcon:SetPoint("CENTERLEFT", unitFrame, "CENTERRIGHT",5, 0)
    markIcon:SetHeight(setup.iconSizes.combat)
    markIcon:SetWidth(setup.iconSizes.combat * 2)
    markIcon:SetVisible(false)
    markIcon:SetTextureAsync(addonInfo.identifier, "gfx/markIcon1.png")

    local roleIcon = LibEKL.UICreateFrame("nkTexture", thisName .. ".roleIcon", unitFrame)
    roleIcon:SetLayer(99)
    roleIcon:SetHeight(setup.iconSizes.role)
    roleIcon:SetWidth(setup.iconSizes.role)
    roleIcon:SetVisible(false)

    if setup.reverse then
        roleIcon:SetPoint("CENTERRIGHT", nameText, "CENTERLEFT", -setup.margins.roleIcon, 0)
    else
        roleIcon:SetPoint("CENTERLEFT", nameText, "CENTERRIGHT", setup.margins.roleIcon, 0)
    end

    local tierIcon = LibEKL.UICreateFrame("nkTexture", thisName .. ".tierIcon", unitFrame)
    tierIcon:SetLayer(99)
    tierIcon:SetHeight(setup.iconSizes.tier)
    tierIcon:SetWidth(setup.iconSizes.tier)
    tierIcon:SetVisible(false) 
    tierIcon:SetPoint("CENTERRIGHT", nameText, "CENTERLEFT", -setup.margins.tierIcon, 0)

    local rareIcon = LibEKL.UICreateFrame("nkTexture", thisName .. ".rareIcon", unitFrame)
    rareIcon:SetLayer(99)
    rareIcon:SetHeight(setup.iconSizes.tier)
    rareIcon:SetWidth(setup.iconSizes.tier)
    rareIcon:SetVisible(false) 
    rareIcon:SetTextureAsync(addonInfo.identifier, "gfx/iconRare2.png")
    rareIcon:SetPoint("CENTERRIGHT", tierIcon, "CENTERLEFT", -setup.margins.tierIcon, 0)

    local iconHeight = unitFrame:GetHeight() - 2

    local stateIcon = LibEKL.UICreateFrame("nkTexture", thisName .. ".stateIcon", unitFrame)
    stateIcon:SetLayer(99)
    stateIcon:SetHeight(iconHeight)
    stateIcon:SetWidth(iconHeight)
    stateIcon:SetVisible(false) 
    stateIcon:SetTextureAsync(addonInfo.identifier, "gfx/iconAFK.png")
    stateIcon:SetPoint("CENTER", unitFrame, "CENTER")
    
    function unitFrame:Redraw()        
        unitFrame:SetWidth(setup.width)
        unitFrame:SetHeight(setup.height) 
        secureFrame:SetWidth(setup.width)
        secureFrame:SetHeight(setup.height)
        
        healthFrame:ClearAll()
        healthFrame:SetWidth((setup.width -2))
        healthFrame:SetHeight((setup.height -2))

        nameText:ClearAll()
        nameText:SetFontSize(setup.fontSizes.name)

        healthText:ClearAll()
        healthText:SetFontSize(setup.fontSizes.health)

        energyText:ClearAll()
        energyText:SetFontSize(setup.fontSizes.energy)

        levelText:ClearAll()
        levelText:SetFontSize(setup.fontSizes.level)
        
        planarText:ClearAll()
        planarText:SetFontSize(setup.fontSizes.planar)

        roleIcon:ClearAll()
        roleIcon:SetHeight(setup.iconSizes.role)
        roleIcon:SetWidth(setup.iconSizes.role)

        combatIcon:SetHeight(setup.iconSizes.combat)
        combatIcon:SetWidth(setup.iconSizes.combat)
        
        tierIcon:SetHeight(setup.iconSizes.tier)
        tierIcon:SetWidth(setup.iconSizes.tier)

        if setup.reverse then            
            healthFrame:SetPoint("TOPRIGHT", unitFrame, "TOPRIGHT", -1, 1)
            healthText:SetPoint("BOTTOMLEFT", unitFrame, "TOPLEFT", 2, setup.margins.health)
            energyText:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 2, -setup.margins.energy)
            planarText:SetPoint("CENTERRIGHT", unitFrame, "CENTERRIGHT", -setup.margins.planar, 0)
            roleIcon:SetPoint("CENTERRIGHT", nameText, "CENTERLEFT", -setup.margins.roleIcon, 0)
            
            if string.find(unitType, "raid") then
                nameText:SetPoint("CENTER", unitFrame, "CENTER", 2, 0)
            else            
                nameText:SetPoint("BOTTOMRIGHT", unitFrame, "TOPRIGHT", -2, 0)
            end
        else
            healthFrame:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, 1)
            healthText:SetPoint("BOTTOMRIGHT", unitFrame, "TOPRIGHT", -2, setup.margins.health)
            energyText:SetPoint("TOPRIGHT", unitFrame, "BOTTOMRIGHT", -2, -setup.margins.energy)
            planarText:SetPoint("CENTERLEFT", unitFrame, "CENTERLEFT", setup.margins.planar, 0)
            roleIcon:SetPoint("CENTERLEFT", nameText, "CENTERRIGHT", setup.margins.roleIcon, 0)

            if string.find(unitType, "raid") then
                nameText:SetPoint("CENTER", unitFrame, "CENTER", 2, 0)
            else
                nameText:SetPoint("BOTTOMLEFT", unitFrame, "TOPLEFT", 2, 0)
            end
        end
        
        if string.find(unitType, "raid") == nil then
            local buffIcons = unitFrame:GetBuffIcons()
            local debuffIcons = unitFrame:GetDebuffIcons()

            for k, v in pairs (buffIcons) do
                v.icon:Setup(setup.buffs)
            end

            for k, v in pairs (debuffIcons) do
                v.icon:Setup(setup.buffs)
            end
        end

        if unitType == "player" then
            combatIcon:SetVisible(true)
        end

        if unitType == "player" or unitType == "playstateIcer.target" then
            unitFrame:SetTier("raid")
        end

        nameText:ClearAll()
        nameText:SetFontSize(setup.fontSizes.name)

        healthText:ClearAll()
        healthText:SetFontSize(setup.fontSizes.health)

        energyText:ClearAll()
        energyText:SetFontSize(setup.fontSizes.energy)

        levelText:ClearAll()
        levelText:SetFontSize(setup.fontSizes.level)
        
        planarText:ClearAll()
        planarText:SetFontSize(setup.fontSizes.planar)
        unitFrame:ProcessUnitDetails (LibEKL.Unit.getPlayerDetails().id)
        unitFrame:SetRole("dps")
        
    end

    -- buff management

    function unitFrame:GetBuffIcons() return unitBuffIcons end
    function unitFrame:GetDebuffIcons() return unitDebuffIcons end
    function unitFrame:GetBuffDisplayList() return unitBuffDisplayList end
    function unitFrame:GetDebuffDisplayList() return unitDebuffDisplayList end
    function unitFrame:GetBuffId2BuffTypeList() return unitBuffId2BuffType end
    function unitFrame:SetBuffIcons(icons) unitBuffIcons = icons end
    function unitFrame:SetDebuffIcons(icons) unitDebuffIcons = icons end
    function unitFrame:SetBuffDisplayList(list) unitBuffDisplayList = list end
    function unitFrame:SetDebuffDisplayList(list) unitDebuffDisplayList = list end
    function unitFrame:SetBuffId2BuffTypeList(list) unitBuffId2BuffType = list end    

    function unitFrame:addBuff(buffUnit, buffs) 
        if unitFrameType ~= "raid" then
            internalFunc.manageBuffs(self, unitType, thisUnitID, buffUnit, buffs, "add") 
        end
    end

    function unitFrame:changeBuff(unit, buffs) 
        if unitFrameType ~= "raid" then
            internalFunc.manageBuffs(self, unitType, thisUnitID, unit, buffs, "change") 
        end
    end
    
    function unitFrame:ClearBuffs() 
        if unitFrameType ~= "raid" then
            internalFunc.manageBuffs(self, unitType, thisUnitID, nil, nil, "clear") 
        end
    end
    
    function unitFrame:removeBuff(buffUnit, buffs) 
        if unitFrameType ~= "raid" then
            internalFunc.manageBuffs(self, unitType, thisUnitID, buffUnit, buffs, "remove") 
        end
    end

    function unitFrame:SetUnitID (newId) thisUnitID = newId end
    function unitFrame:GetUnitID () return thisUnitID end

    function unitFrame:GetScale() return scale end
    function unitFrame:GetBuffSetup() return setup.buffs end

    local function hideSecureFrame()
        secureFrame:SetVisible(false)
        secureFrame:SetMouseoverUnit(nil)
    end

    local function showSecureFrame()
        secureFrame:SetVisible(true)
    end

    local oSetVisible = unitFrame.SetVisible
    function unitFrame:SetVisible (flag)    
        oSetVisible(self, flag)
        if flag == false then
            LibEKL.Events.AddInsecure(hideSecureFrame)
        else
            LibEKL.Events.AddInsecure(showSecureFrame)
        end
    end

    local oClearPoint = unitFrame.ClearPoint
    function unitFrame:ClearPoint(point)
        oClearPoint(self, point)
        secureFrame:ClearPoint(point)
    end

    local oSetPoint = unitFrame.SetPoint
    function unitFrame:SetPoint(from, object, to, x, y)
        if x and y then
            oSetPoint(self, from, object, to, x, y)
            secureFrame:SetPoint(from, object, to, x, y)
        else
            oSetPoint(self, from, object, to)
            secureFrame:SetPoint(from, object, to)
        end        
    end
    
    function unitFrame:SetTier(newTier)

        if newTier == "group" then
            tierIcon:SetVisible(true)
            tierIcon:SetTextureAsync(addonInfo.identifier, "gfx/iconElite.png")
        elseif newTier == "raid" then
            tierIcon:SetVisible(true)
            tierIcon:SetTextureAsync(addonInfo.identifier, "gfx/iconBoss.png")
        else
            tierIcon:SetVisible(false)
        end
    end

    function unitFrame:SetRare(flag)        
        if flag == nil then            
            rareIcon:SetVisible(false)
        else
            rareIcon:SetVisible(flag)        
        end
    end

    function unitFrame:SetAFK(flag)
        if flag == nil then            
            stateIcon:SetVisible(false)
        else
            stateIcon:SetTextureAsync(addonInfo.identifier, "gfx/iconAFK.png")
            stateIcon:SetVisible(flag)        
        end
    end

    function unitFrame:SetOffline(flag)
        if flag == nil then            
            stateIcon:SetVisible(false)
        else
            stateIcon:SetTextureAsync(addonInfo.identifier, "gfx/iconOffline.png")
            stateIcon:SetVisible(flag)
        end
    end

    function unitFrame:SetReadyCheck(response)
        if response == "nil" then
            stateIcon:SetVisible(false)
        elseif response == false then
            stateIcon:SetTextureAsync("Rift", "raid_icon_notready.png.dds")
            stateIcon:SetVisible(true)
        else
            stateIcon:SetTextureAsync("Rift", "raid_icon_ready.png.dds")
            stateIcon:SetVisible(true)
        end
    end

    function unitFrame:SetMark(newMark)        
        if newMark == nil or newMark == false then
            markIcon:SetVisible(false)
        else
            local thisMark = stringFormat("gfx/%s", markIcons[stringFormat("mark%s", newMark)])
            markIcon:SetTextureAsync(addonInfo.identifier, thisMark)
            markIcon:SetVisible(true)
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
        elseif newRole == "support" then
            roleIcon:SetVisible(true)
            roleIcon:SetTextureAsync(addonInfo.identifier, "gfx/roleSupport.png")
        else
            roleIcon:SetVisible(false)
        end
    end

    function unitFrame:SetCombat(state)
        combatIcon:SetVisible(state)
    end

    function unitFrame:SetCalling (calling)
        if calling == "primalist" then energyText:SetVisible(false) end

        local fill = data.callingColor[calling or "default"]
        healthFrame:SetShape (path, fill, nil)            
    end

    function unitFrame:SetName (name) 
        local maxLen = 10
        if unitFrameType == "raid" then maxLen = 5 end

        thisName = internalFunc.shortenName (name, maxLen)

        nameText:SetText(thisName)
    end

    function unitFrame:SetLevel (newLevel)
        
        local playerLevel = LibEKL.Unit.getPlayerDetails().level
        
        if newLevel == "??" then
            color = "#FF3333"
            levelText:SetText(stringFormat("Lvl <font color='%s'>??</font>", color), true) 
            levelText:SetVisible(true)
        elseif newLevel and unitFrame:GetUnitFrameType() ~= "raid" and newLevel ~= playerLevel then            
            local color = "#009900"
            if newLevel > playerLevel + 10 then
                color = "#FF3333"
            elseif newLevel > playerLevel + 5 then
                color = "#FF8000"
            elseif newLevel < playerLevel -10 then
                color = "#DDDDDD"
            end

            levelText:SetText(stringFormat("Lvl <font color='%s'>%d</font>", color, newLevel), true) 
            levelText:SetVisible(true)
        else
            levelText:SetVisible(false)
        end
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
        if newHealthMax == nil then return end
        healthMax = newHealthMax
        if health == nil or health < healthMax then
            unitFrame:SetHealth(healthMax)
        end
    end

    function unitFrame:SetHealth (health) 
        if health == nil then return end
        if healthMax == nil then healthMax = health end

        if health > healthMax then health = healthMax end -- if this works we need to add some code for it

        if unitFrameWidth == nil then unitFrameWidth = (unitFrame:GetWidth() -2) end
        
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
        local details = inspectUnitDetail(newUnitID)
        if (details) then

            unitFrame:MouseOverUnit(unitID)

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

function internalFunc.FrameManagerRelease(unitType)
    if frameManager.activeFrames[unitType] then
        frameManager.activeFrames[unitType]:SetVisible(false)
        table.insert(frameManager.framePool, frameManager.activeFrames[unitType])
        frameManager.activeFrames[unitType] = nil
    end
end

function internalFunc.FrameManagerClearAll()
    for k, v in pairs(frameManager.activeFrames) do
        v:SetVisible(false)
        table.insert(frameManager.framePool, v)
    end
    frameManager.activeFrames = {}
end