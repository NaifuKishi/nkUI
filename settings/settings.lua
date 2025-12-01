local addonInfo, privateVars = ...

---------- init namespace ---------

local data      = privateVars.data
local uiElements= privateVars.uiElements
local _internal = privateVars.internal
local _events   = privateVars.events

privateVars.settings		= {}
local _settings = privateVars.settings

---------- init local variables ---------

local _defaults = {
    modules = {
        unitFrames  = { activate = true, 
                        combatAlpha = 1, 
                        nonCombatAlpha = .2, 
                        showBuffs = true,
                        frames = {  player          = { x = 1320, y = 1000, width = 250, height = 35, 
                                                        reverse = false,
                                                        fontSizes = {name = 16, health = 28, energy = 14, planar = 12}, 
                                                        margins = { name = 15, health = 15, energy = 12, planar = 4, combatIcon = 5, roleIcon = 5, tierIcon = 5 },
                                                        iconSizes = {combat = 30, role = 20, tier = 20 },
                                                        buffs = { width = 35, height = 35, timer = 12, stack = 10, label = 10}                                                        
                                                    },
                                    playerPet       = { x = 1000, y = 1050, width = 185, height = 25,
                                                        reverse = false,
                                                        fontSizes = {name = 12, health = 20, energy = 10, planar = 10}, 
                                                        margins = { name = 10, health = 10, energy = 10, planar = 3, combatIcon = 5, roleIcon = 5, tierIcon = 5 },
                                                        iconSizes = {combat = 0, role = 0, tier = 0 },
                                                        buffs = { width = 26, height = 26, timer = 10, stack = 8, label = 8}                                                        
                                                    },
                                    target          = { x = 1870, y = 1000, width = 250, height = 35,
                                                        reverse = true,
                                                        fontSizes = {name = 16, health = 28, energy = 14, planar = 12}, 
                                                        margins = { name = 15, health = 15, energy = 12, planar = 4, combatIcon = 5, roleIcon = 5, tierIcon = 5 },
                                                        iconSizes = {combat = 30, role = 20, tier = 20 },
                                                        buffs = { width = 35, height = 35, timer = 12, stack = 10, label = 10}                      
                                                    },
                                    focus           = { x = 600, y = 1000, width = 185, height = 25,
                                                        reverse = false,
                                                        fontSizes = {name = 12, health = 20, energy = 10, planar = 10},                     
                                                        margins = { name = 10, health = 10, energy = 10, planar = 3, combatIcon = 5, roleIcon = 5, tierIcon = 5 },
                                                        iconSizes = {combat = 22, role = 15, tier = 15 },
                                                        buffs = { width = 26, height = 26, timer = 10, stack = 8, label = 8}                                                                                                                
                                                    },
                                    group           = { x = 600, y = 500, width = 250, height = 35,
                                                        reverse = false,
                                                        fontSizes = {name = 12, health = 20, energy = 10, planar = 10},
                                                        margins = { name = 10, health = 10, energy = 10, planar = 3, combatIcon = 5, roleIcon = 5, tierIcon = 5, group = 80 },
                                                        iconSizes = {combat = 0, role = 0, tier = 0 },
                                                        buffs = { width = 26, height = 26, timer = 10, stack = 8, label = 8}
                                                    },
                                    raid            = { x = 100, y = 500, width = 100, height = 45,
                                                        reverse = false,
                                                        fontSizes = {name = 16, health = 28, energy = 14, planar = 12}, 
                                                        margins = { name = 0, health = 0, energy = 0, planar = 0, combatIcon = 5, roleIcon = 2, tierIcon = 5 },
                                                        iconSizes = {combat = 22, role = 15, tier = 15 },
                                                    },
                                    ressourceBar    = { x = 1620, y = 1020, width = 200, height = 17,
                                                        combo = { width = 30, height = 12},
                                                        charge = { width = 160, height = 12},
                                                        margins = { ressource = 10 },
                                                        fontSizes = {charge = 16, ressource = 20}
                                                     },
                                    playerCastBar   = { x = 1595, y = 1100, width = 250, height = 24,
                                                        fontSizes = {text = 16, timer = 14}
                                                    },
                                    targetCastBar   = { x = 1595, y = 900, width = 250, height = 24,
                                                        fontSizes = {text = 16, timer = 14}
                                                    },
                                }
                    },
        actionBars  = { activate = true, 
                        combatAlpha = 1, 
                        nonCombatAlpha = .2,
                    },
        lowerBar    = { activate = true },
        oneBag      = { activate = true },
        buffBar     = { activate = true,
                        buffs = { width = 40, height = 40, timer = 14, stack = 12, label = 10}            
                    },
        sct         = { activate = true },
        tooltip     = { activate = true }
    }
}

--[[
   _setupDefaults
    Description:
        Initializes default configuration values for the nkUI addon if they don't exist.
    Parameters:
        None
    Returns:
        None
    Notes:
        - Creates default configuration table if it doesn't exist
        - Updates tutorial version and adds new configuration options
        - Sets default values for buffUnitFrame, combatAlpha, and nonCombatAlpha
]]
function _internal.setupDefaults()

    if nkUISetup == nil or nkUISetup.tutorialVersion == nil then
        nkUISetup = _defaults
        nkUISetup.modules.actionBars.bars = {}
        nkUISetup.modules.actionBars.bars[EnKai.unit.getPlayerDetails().name] = { roles = {} }
    end

end

function _internal.toggleAlpha()
    
    uiElements.frames["player"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)    
    uiElements.frames["player.pet"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
    uiElements.frames["player.target"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
    uiElements.frames["focus"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)

end

function _internal.actionBarToggleAlpha()
    
    for k, v in pairs (uiElements.actionbars) do
        v:SetAlpha(nkUISetup.modules.actionBars.nonCombatAlpha)
    end

end

function _settings.checkbox (name, parent, text, active, callBack)

    local thisCheckbox = EnKai.uiCreateFrame("nkCheckbox", name, parent)
    
    thisCheckbox:SetText(text, true)
    thisCheckbox:SetActive(active)
    thisCheckbox:SetLabelWidth(200)
    thisCheckbox:SetFontSize(14)
    thisCheckbox:SetTextFont(addonInfo.id, "Montserrat")

    Command.Event.Attach(EnKai.events[name].CheckboxChanged, function (_, newValue)		
        callBack(newValue)
    end, name .. ".CheckboxChanged")

    return thisCheckbox

end

function _settings.slider (name, parent, text, active, callBack)

    local thisSlider = EnKai.uiCreateFrame("nkSlider", name, parent)

    thisSlider:SetText(text, true)
    thisSlider:SetWidth(350)
    thisSlider:SetLabelWidth(200)
    thisSlider:SetFontSize(14)
    thisSlider:SetActive(active)
    thisSlider:SetFont(addonInfo.id, "Montserrat")

    Command.Event.Attach(EnKai.events[name].SliderChanged, function (_, newValue)
        callBack(newValue)
    end, name .. ".SliderChanged")

    return thisSlider

end

function _internal.setupUI ()
    
    local name = "nkUI.config"

    local config = EnKai.uiCreateFrame("nkWindowMetro", name, uiElements.context)

    config:SetPoint("CENTER", UIParent, "CENTER")
    config:SetWidth(900)
    config:SetHeight(650)
    config:SetTitle(addonInfo.toc.Identifier .. " ".. addonInfo.toc.Version)
    config:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    config:SetCloseable(true)
    --config:SetColor({ r = 00, g = 0, b = 0, a = 1, thickness=1}, {type = "solid", r = 0.051, g = 0, b = 0.0, a = .7})
    config:SetTitleFontColor(1, 1, 1, 1)
    config:SetShadow(true)

    local tabPane = EnKai.uiCreateFrame("nkTabPaneMetro", name .. ".tabPane", config:GetContent())
    --tabPane:SetColor({ thickness = 1, r = 0.078, g = 0.188, b = 0.306, a = 1}, { type = 'solid', r = 0.051, g = 0.118, b = 0.192, a = 1}, nil, { r = 1, g = 1, b = 1, a = 1})
    tabPane:SetColor({ thickness = 1, r = 0, g = 0, b = 0, a = 1}, { type = 'solid', r = 0, g = 0, b = 0, a = .6}, nil, { r = 1, g = 1, b = 1, a = 1})
    tabPane:SetBorder(false)
    tabPane:SetVertical(true)
    tabPane:SetFont(addonInfo.id, "MontserratSemiBold")

    local paneTabActionBar = _settings.uiConfigTabActionBar(name .. ".tab.ActionBar", tabPane)
    local paneTabLowerBar = _settings.uiConfigTabLowerBar(name .. ".tab.LowerBar", tabPane)
    local paneTabSCT = _settings.uiConfigTabSCT(name .. ".tab.SCT", tabPane)
    local paneTabTooltip = _settings.uiConfigTabTooltip(name .. ".tab.Tooltip", tabPane)
    local paneTabBuffBar = _settings.uiConfigTabBuffBar(name .. ".tab.BuffBar", tabPane)

    local paneTabRessourceBar = _settings.uiConfigTabRessourceBar(name .. ".tab.RessourceBar", tabPane, nkUISetup.modules.unitFrames.frames.ressourceBar)

    local paneTabPlayerCastbar = _settings.uiConfigTabCastBar(name .. ".tab.PlayerCastbar", tabPane, "PLAYER CASTBAR", nkUISetup.modules.unitFrames.frames.playerCastBar)
    local paneTabTargetCastbar = _settings.uiConfigTabCastBar(name .. ".tab.TargetCastbar", tabPane, "TARGET CASTBAR", nkUISetup.modules.unitFrames.frames.targetCastBar)

    local paneTabUnitFrames = _settings.uiConfigTabUnitFrames(name .. ".tab.UnitFrames", tabPane)

    local EnKaiLogo = EnKai.uiCreateFrame("nkTexture", name .. ".EnKaiLogo", config)
    EnKaiLogo:SetTextureAsync(EnKai.art.GetThemeLogo()[1],EnKai.art.GetThemeLogo()[2])
    EnKaiLogo:SetPoint("BOTTOMLEFT", config:GetContent(), "BOTTOMLEFT", 10, -5)
    EnKaiLogo:SetWidth(125)
    EnKaiLogo:SetHeight(33)

    local versionText = UI.CreateFrame("Text", name .. ".versionText", config)
    versionText:SetFontSize(11)
    versionText:SetText(string.format("Version %s", addonInfo.toc.Version))
    versionText:SetFontColor(236, 228, 189, 1)
    versionText:SetPoint("BOTTOMRIGHT", tabPane, "BOTTOMRIGHT", -5, -5)
    versionText:SetLayer(99)

    local closeButton = EnKai.uiCreateFrame("nkButtonMetro", name .. ".closeButton", config:GetContent())

    closeButton:SetPoint("BOTTOMRIGHT", config:GetContent(), "BOTTOMRIGHT", -10, -10)
    closeButton:SetText("Close")
    closeButton:SetFontColor(1, 1, 1)
    --closeButton:SetColor(_mainColor.r, _mainColor.g, _mainColor.b)
    closeButton:SetIcon("EnKai", "gfx/icons/close.png")
    closeButton:SetScale(.8)
    closeButton:SetLayer(9)

    Command.Event.Attach(EnKai.events[name .. ".closeButton"].Clicked, function (_, newValue)
        uiElements.settings:SetVisible(false)   
    end, name .. ".closeButton.Clicked")

    local tutorialButton = EnKai.uiCreateFrame("nkButtonMetro", name .. ".tutorialButton", config:GetContent())

    tutorialButton:SetPoint("CENTERRIGHT", closeButton, "CENTERLEFT", -10, 0)
    tutorialButton:SetText("Tutorial")
    tutorialButton:SetFontColor(1, 1, 1)
    --tutorialButton:SetColor(_mainColor.r, _mainColor.g, _mainColor.b)
    tutorialButton:SetIcon("EnKai", "gfx/icons/info.png")
    tutorialButton:SetScale(.8)
    tutorialButton:SetLayer(9)

    Command.Event.Attach(EnKai.events[name .. ".tutorialButton"].Clicked, function (_, newValue)
        _internal.tutorial()
    end, name .. ".tutorialButton.Clicked")

    local oSetVisible = config.SetVisible

    function config:SetVisible(flag)   
        oSetVisible(self, flag)
    end

    tabPane:SetPoint("TOPLEFT", config:GetContent(), "TOPLEFT", 10, 10)
    tabPane:SetPoint("BOTTOMRIGHT", config:GetContent(), "BOTTOMRIGHT", -10, -50)
    tabPane:SetLayer(1)

    tabPane:AddPane( { label = "Action bar", frame = paneTabActionBar, initFunc = function() paneTabActionBar:build() end}, false)
    tabPane:AddPane( { label = "Lower bar", frame = paneTabLowerBar, initFunc = function() paneTabLowerBar:build() end}, false)
    tabPane:AddPane( { label = "SCT", frame = paneTabSCT, initFunc = function() paneTabSCT:build() end}, false)
    tabPane:AddPane( { label = "Tooltip", frame = paneTabTooltip, initFunc = function() paneTabTooltip:build() end}, false)
    tabPane:AddPane( { label = "Buff bar", frame = paneTabBuffBar, initFunc = function() paneTabBuffBar:build() end}, false)

    tabPane:AddPane( { label = "Ressource bar", frame = paneTabRessourceBar, initFunc = function() paneTabRessourceBar:build() end}, false)

    tabPane:AddPane( { label = "Player castbar", frame = paneTabPlayerCastbar, initFunc = function() paneTabPlayerCastbar:build() end}, false)
    tabPane:AddPane( { label = "Target castbar", frame = paneTabTargetCastbar, initFunc = function() paneTabTargetCastbar:build() end}, false)

    tabPane:AddPane( { label = "Unit frames", frame = paneTabUnitFrames, initFunc = function() paneTabUnitFrames:build() end}, true)

    --if EnKai.internal.checkEvents ("nkRadial", true) == false then return nil end

    config:SetVisible(true)

    return config

end

function _internal.setupInit ()
    if uiElements.settings == nil then
        uiElements.settings = _internal.setupUI ()
    else
        uiElements.settings:SetVisible(true)
    end
end
