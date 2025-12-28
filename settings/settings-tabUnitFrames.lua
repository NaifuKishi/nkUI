local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI     = privateVars.settingsUI
local data          = privateVars.data

local stringFormat = string.format

---------- init local variables ---------

function settingsUI.uiConfigTabUnitFrames (name, parent)

    local paneTabUFPlayer, paneTabUFTarget, paneTabUFPlayerPet, paneTabUFFocus, paneTabUFGroup, paneTabUFRaid

    local tabPane = LibEKL.uiCreateFrame("nkTabPane", name .. ".tabPane", parent:GetBodyFrame())
    tabPane:SetColor(
        {   thickness = 1, 
            r = data.theme.windowEndColor.r, g = data.theme.windowEndColor.g, b = data.theme.windowEndColor.b, a = 0
        }, 
        {   type = 'solid', 
            r = data.theme.windowEndColor.r, g = data.theme.windowEndColor.g, b = data.theme.windowEndColor.b, a = 0},
     data.theme.labelColor, data.theme.labelColor)
    tabPane:SetBorder(false)
    tabPane:SetFont(addonInfo.id, "MontserratSemiBold")

    function tabPane:build()
        paneTabUFPlayer = settingsUI.uiConfigTabUF(name .. ".tab.UnitFrames.Player", tabPane, "player", nkUISetup.modules.unitFrames.frames.player)
        paneTabUFTarget = settingsUI.uiConfigTabUF(name .. ".tab.UnitFrames.Target", tabPane, "player.target", nkUISetup.modules.unitFrames.frames.target)
        paneTabUFPlayerPet = settingsUI.uiConfigTabUF(name .. ".tab.UnitFrames.PlayerPet", tabPane, "player.pet", nkUISetup.modules.unitFrames.frames.playerPet)
        paneTabUFFocus = settingsUI.uiConfigTabUF(name .. ".tab.UnitFrames.Focus", tabPane, "focus", nkUISetup.modules.unitFrames.frames.focus)
        paneTabUFGroup = settingsUI.uiConfigTabUF(name .. ".tab.UnitFrames.Group", tabPane, "group", nkUISetup.modules.unitFrames.frames.group)
        paneTabUFRaid = settingsUI.uiConfigTabUF(name .. ".tab.UnitFrames.Raid", tabPane, "raid", nkUISetup.modules.unitFrames.frames.raid)        

        tabPane:SetPoint("TOPLEFT", parent:GetBodyFrame(), "TOPLEFT", 10, 10)
        tabPane:SetPoint("BOTTOMRIGHT", parent:GetBodyFrame(), "BOTTOMRIGHT", -10, -50)
        tabPane:SetLayer(1)

        tabPane:AddPane( { label = "Player", effect = { strength = 3 }, frame = paneTabUFPlayer, initFunc = function() paneTabUFPlayer:build() end}, false)
        tabPane:AddPane( { label = "Target", effect = { strength = 3 }, frame = paneTabUFTarget, initFunc = function() paneTabUFTarget:build() end}, false)
        tabPane:AddPane( { label = "Player Pet", effect = { strength = 3 }, frame = paneTabUFPlayerPet, initFunc = function() paneTabUFPlayerPet:build() end}, false)
        tabPane:AddPane( { label = "Focus", effect = { strength = 3 }, frame = paneTabUFFocus, initFunc = function() paneTabUFFocus:build() end}, false)
        tabPane:AddPane( { label = "Group", effect = { strength = 3 }, frame = paneTabUFGroup, initFunc = function() paneTabUFGroup:build() end}, false)
        tabPane:AddPane( { label = "Raid", effect = { strength = 3 }, frame = paneTabUFRaid, initFunc = function() paneTabUFRaid:build() end}, true)

    end

    return tabPane

end