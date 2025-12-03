local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabUnitFrames (name, parent)

    local paneTabUFPlayer, paneTabUFTarget, paneTabUFPlayerPet, paneTabUFFocus, paneTabUFGroup, paneTabUFRaid

    local tabPane = EnKai.uiCreateFrame("nkTabPaneMetro", name .. ".tabPane", parent:GetBodyFrame())
    --tabPane:SetColor({ thickness = 1, r = 0.078, g = 0.188, b = 0.306, a = 1}, { type = 'solid', r = 0.051, g = 0.118, b = 0.192, a = 1}, nil, { r = 1, g = 1, b = 1, a = 1})
    tabPane:SetColor({ thickness = 1, r = 0, g = 0, b = 0, a = 1}, { type = 'solid', r = 0, g = 0, b = 0, a = .6}, nil, { r = 1, g = 1, b = 1, a = 1})
    tabPane:SetBorder(false)
    tabPane:SetFont(addonInfo.id, "MontserratSemiBold")

    function tabPane:build()
        paneTabUFPlayer = _settings.uiConfigTabUF(name .. ".tab.UnitFrames.Player", tabPane, "player", nkUISetup.modules.unitFrames.frames.player)
        paneTabUFTarget = _settings.uiConfigTabUF(name .. ".tab.UnitFrames.Target", tabPane, "player.target", nkUISetup.modules.unitFrames.frames.target)
        paneTabUFPlayerPet = _settings.uiConfigTabUF(name .. ".tab.UnitFrames.PlayerPet", tabPane, "player.pet", nkUISetup.modules.unitFrames.frames.playerPet)
        paneTabUFFocus = _settings.uiConfigTabUF(name .. ".tab.UnitFrames.Focus", tabPane, "focus", nkUISetup.modules.unitFrames.frames.focus)
        paneTabUFGroup = _settings.uiConfigTabUF(name .. ".tab.UnitFrames.Group", tabPane, "group", nkUISetup.modules.unitFrames.frames.group)
        paneTabUFRaid = _settings.uiConfigTabUF(name .. ".tab.UnitFrames.Raid", tabPane, "raid", nkUISetup.modules.unitFrames.frames.raid)        

        tabPane:SetPoint("TOPLEFT", parent:GetBodyFrame(), "TOPLEFT", 10, 10)
        tabPane:SetPoint("BOTTOMRIGHT", parent:GetBodyFrame(), "BOTTOMRIGHT", -10, -50)
        tabPane:SetLayer(1)

        tabPane:AddPane( { label = "Player", frame = paneTabUFPlayer, initFunc = function() paneTabUFPlayer:build() end}, false)
        tabPane:AddPane( { label = "Target", frame = paneTabUFTarget, initFunc = function() paneTabUFTarget:build() end}, false)
        tabPane:AddPane( { label = "Player Pet", frame = paneTabUFPlayerPet, initFunc = function() paneTabUFPlayerPet:build() end}, false)
        tabPane:AddPane( { label = "Focus", frame = paneTabUFFocus, initFunc = function() paneTabUFFocus:build() end}, false)
        tabPane:AddPane( { label = "Group", frame = paneTabUFGroup, initFunc = function() paneTabUFGroup:build() end}, false)
        tabPane:AddPane( { label = "Raid", frame = paneTabUFRaid, initFunc = function() paneTabUFRaid:build() end}, true)

    end

    return tabPane

end