local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events
local langTexts     = privateVars.langTexts

privateVars.settingsUI = {}

local settingsUI = privateVars.settingsUI

local stringFind    = string.find
local stringFormat  = string.format

uiElements.settingsContext = UI.CreateContext("nkUI.Settings")
uiElements.settingsContext:SetStrata('dialog')
uiElements.settingsContext:SetLayer(10)

settingsUI.PADDING = {
    ACTIVE = 5,
    HEADING = 15,
    AFTERHEADING = 15,
    REGULAR = 10,
}

---------- init local variables ---------

local _defaults = {
    modules = {
        chat = {activate = true },
        questtracker = {activate = true,
                        x = 2800,
                        y = 500,
                        width = 300, 
                        height = 500, 
                        useXpos = 800, 
                        useYpos = 100, 
                        useUI = true,
                        categoryHeaderSize = 16,																
						categoryShow = {battlepass = true, crafting = true, world = true, daily = true, guild = true, ia = true, monthly = true, weekly = true, zone = true, area = true, instant = true, raid = true, story = true, personal = true, carnage = true, pvp = true},
						categoryFontSize = { header = 15, subHeader = 14, body = 13 },
						collapseState = {},
						categoryCollapseState = {}
        },
        questLog = {activate = true,
                        x = 2800,
                        y = 500,
                        width = 300, 
                        height = 500, 
                        useXpos = 800, 
                        useYpos = 100, 
                        useUI = true,
                        categoryHeaderSize = 16,																
						categoryShow = {battlepass = true, crafting = true, world = true, daily = true, guild = true, ia = true, monthly = true, weekly = true, zone = true, area = true, instant = true, raid = true, story = true, personal = true, carnage = true, pvp = true},
						categoryFontSize = { header = 15, subHeader = 14, body = 13 },
						collapseState = {},
						categoryCollapseState = {}
        },        
        unitFrames  = { activate = true, 
                        combatAlpha = 1, 
                        nonCombatAlpha = .2, 
                        showBuffs = true,
                        showOnlyOwnBuffs = false,
                        buffDuration = 60,
                        smoothAnimation = true,
                        colorScheme = "wow",
                        alwaysShowRessourceBar = false,
                        maxBuffCount = 9,
                        frames = {  player          = { x = -300, y = 300, width = 250, height = 35, 
                                                        reverse = false,
                                                        fontSizes = {name = 16, health = 28, energy = 14, planar = 12, level = 12}, 
                                                        margins = { name = 15, health = 15, energy = 12, planar = 4, combatIcon = 5, roleIcon = 5, tierIcon = 5, level = 4},
                                                        iconSizes = {combat = 30, role = 20, tier = 20 },
                                                        buffs = { width = 35, height = 35, timer = 12, stack = 10, label = 10 }
                                                    },
                                    playerPet       = { x = -675, y = 400, width = 185, height = 25,
                                                        reverse = false,
                                                        fontSizes = {name = 12, health = 20, energy = 10, planar = 10, level = 10}, 
                                                        margins = { name = 10, health = 10, energy = 10, planar = 3, combatIcon = 5, roleIcon = 5, tierIcon = 5, level = 3},
                                                        iconSizes = {combat = 0, role = 0, tier = 0 },
                                                        buffs = { width = 26, height = 26, timer = 10, stack = 8, label = 8 }
                                                    },
                                    target          = { x = 300, y = 300, width = 250, height = 35,
                                                        reverse = true,
                                                        fontSizes = {name = 16, health = 28, energy = 14, planar = 12, level = 12}, 
                                                        margins = { name = 15, health = 15, energy = 12, planar = 4, combatIcon = 5, roleIcon = 5, tierIcon = 5, level = 4 },
                                                        iconSizes = {combat = 30, role = 20, tier = 20 },
                                                        buffs = { width = 35, height = 35, timer = 12, stack = 10, label = 10 }
                                                    },
                                    targetOfTarget= { x = 700, y = 305, width = 150, height = 25,
                                                        reverse = true,
                                                        fontSizes = {name = 10, health = 16, energy = 8, planar = 7, level = 7}, 
                                                        margins = { name = 9, health = 9, energy = 7, planar = 2, combatIcon = 3, roleIcon = 3, tierIcon = 3, level = 2 },
                                                        iconSizes = {combat = 18, role = 12, tier = 12 },
                                                    },
                                    focus           = { x = -900, y = 250, width = 185, height = 25,
                                                        reverse = false,
                                                        fontSizes = {name = 12, health = 20, energy = 10, planar = 10, level = 10},                     
                                                        margins = { name = 10, health = 10, energy = 10, planar = 3, combatIcon = 5, roleIcon = 5, tierIcon = 5, level = 3 },
                                                        iconSizes = {combat = 22, role = 15, tier = 15 },
                                                        buffs = { width = 26, height = 26, timer = 10, stack = 8, label = 8 }
                                                    },
                                    group           = { x = -900, y = -300, width = 250, height = 35,
                                                        reverse = false,
                                                        fontSizes = {name = 12, health = 20, energy = 10, planar = 10, level = 10},
                                                        margins = { name = 10, health = 10, energy = 10, planar = 3, combatIcon = 5, roleIcon = 5, tierIcon = 5, group = 80, level = 3 },
                                                        iconSizes = {combat = 30, role = 15, tier = 0 },
                                                        buffs = { width = 26, height = 26, timer = 10, stack = 8, label = 8 }
                                                    },
                                    raid            = { x = -1590, y = -500, width = 100, height = 45,
                                                        reverse = false,
                                                        fontSizes = {name = 16, health = 28, energy = 14, planar = 12, level = 12}, 
                                                        margins = { name = 0, health = 0, energy = 0, planar = 0, combatIcon = 5, roleIcon = 2, tierIcon = 5, level = 0 },
                                                        iconSizes = {combat = 0, role = 15, tier = 0 },
                                                    },
                                    ressourceBar    = { x = 0, y = 290, width = 200, height = 17,
                                                        combo = { width = 30, height = 12},
                                                        charge = { width = 160, height = 12},
                                                        margins = { ressource = 10 },
                                                        fontSizes = {charge = 16, ressource = 20},
                                                     },
                                    playerCastBar   = { x = 0, y = 400, width = 250, height = 24,
                                                        fontSizes = {text = 16, timer = 14}
                                                    },
                                    targetCastBar   = { x = 0, y = 200, width = 250, height = 24,
                                                        fontSizes = {text = 16, timer = 14}
                                                    },
                                }
                    },
        actionBars  = { activate = true, 
                        combatAlpha = 1, 
                        nonCombatAlpha = .8,                        
                        x = 0,
                        y = 550,
                        rightBarX = 1695,
                        rightBarY = 0,
                        offset = 550,
                        spacing = 15,
                        mainbars = 2,
                        rightbar = true,
                        iconSize = 40,
                    },
        lowerBar    = { activate = true,                         
                        transparent = false,
                        fontSize = 15,
                        barHeight = 17,
                        barWidth = 300,
                        barText = 13,
                        timeSize = 28,
                        dateSize = 15
		            },
        oneBag      = { activate = true,
                        bankActivate = true,
                        x = 2000,
                        y = 600,
                        bankX = 1200,
                        bankY = 600
                    },
        buffBar     = { activate = true,
                        x = -1690, y = -690,
                        buffs = { width = 40, height = 40, timer = 14, stack = 12, label = 10}            
                    },
        sct         = { activate = true,
                        messageOffset = -200,
                        showExpGains = true,
                        showLoot = true,
                        showCombat = true,
                        showCooldowns = true,                        
                    },
        tooltip     = { activate = true,
                        fontSizes = {header = 14, body = 12 } },
        map         = { activate = true,
                        x = 3133, 
                        y = 7, 
                        maximizedX = 100, 
                        maximizedY = 100, 
                        scale = 2.5,
                        width = 300, 
                        height = 300, 
                        locked = false, 
                        syncTarget = false,
                        maximizedWidth = 1000, 
                        maximizedHeight = 800, 
                        maximizedScale = 1,
                        background = "default",
                        showPOI = true, 
                        showZoneTitle = true, 
                        animations = true, 
                        animationSpeed = 0.05, 
                        rareMobs = true, 
                        showQuest = true,
                        trackArtifacts = true, 
                        trackGathering = true, 
                        smoothScroll = true, 
                        showUnknown = true,
                        zones = {},
                        userPOI = {} }
                },
    showLogo = true,
    useManager = true
}

local function scaleUI ()
       
    local parentWidth = UIParent:GetWidth()

    if parentWidth == 3440 then return end

    nkUISetup.modules.oneBag.x = nkUISetup.modules.oneBag.x * data.uiScale
    nkUISetup.modules.oneBag.y = nkUISetup.modules.oneBag.y * data.uiScale

    nkUISetup.modules.map.x = nkUISetup.modules.map.x * data.uiScale
    nkUISetup.modules.map.y = nkUISetup.modules.map.y * data.uiScale

    nkUISetup.modules.questtracker.x = nkUISetup.modules.questtracker.x * data.uiScale
    nkUISetup.modules.questtracker.y = nkUISetup.modules.questtracker.y * data.uiScale

    nkUISetup.modules.actionBars.x = nkUISetup.modules.actionBars.x * data.uiScale
    nkUISetup.modules.actionBars.y = nkUISetup.modules.actionBars.y * data.uiScale

    nkUISetup.modules.actionBars.rightBarX = nkUISetup.modules.actionBars.rightBarX * data.uiScale
    nkUISetup.modules.actionBars.rightBarY = nkUISetup.modules.actionBars.rightBarY * data.uiScale

    nkUISetup.modules.buffBar.x = nkUISetup.modules.buffBar.x * data.uiScale
    nkUISetup.modules.buffBar.y = nkUISetup.modules.buffBar.y * data.uiScale

    nkUISetup.modules.unitFrames.frames.player.x = nkUISetup.modules.unitFrames.frames.player.x * data.uiScale
    nkUISetup.modules.unitFrames.frames.player.y = nkUISetup.modules.unitFrames.frames.player.y * data.uiScale

    nkUISetup.modules.unitFrames.frames.target.x = nkUISetup.modules.unitFrames.frames.target.x * data.uiScale
    nkUISetup.modules.unitFrames.frames.target.y = nkUISetup.modules.unitFrames.frames.target.y * data.uiScale

    nkUISetup.modules.unitFrames.frames.targetOfTarget.x = nkUISetup.modules.unitFrames.frames.targetOfTarget.x * data.uiScale
    nkUISetup.modules.unitFrames.frames.targetOfTarget.y = nkUISetup.modules.unitFrames.frames.targetOfTarget.y * data.uiScale

    nkUISetup.modules.unitFrames.frames.playerPet.x = nkUISetup.modules.unitFrames.frames.playerPet.x * data.uiScale
    nkUISetup.modules.unitFrames.frames.playerPet.y = nkUISetup.modules.unitFrames.frames.playerPet.y * data.uiScale

    nkUISetup.modules.unitFrames.frames.focus.x = nkUISetup.modules.unitFrames.frames.focus.x * data.uiScale
    nkUISetup.modules.unitFrames.frames.focus.y = nkUISetup.modules.unitFrames.frames.focus.y * data.uiScale

    nkUISetup.modules.unitFrames.frames.ressourceBar.x = nkUISetup.modules.unitFrames.frames.ressourceBar.x * data.uiScale
    nkUISetup.modules.unitFrames.frames.ressourceBar.y = nkUISetup.modules.unitFrames.frames.ressourceBar.y * data.uiScale

    nkUISetup.modules.unitFrames.frames.group.x = nkUISetup.modules.unitFrames.frames.group.x * data.uiScale
    nkUISetup.modules.unitFrames.frames.group.y = nkUISetup.modules.unitFrames.frames.group.y * data.uiScale

    nkUISetup.modules.unitFrames.frames.raid.x = nkUISetup.modules.unitFrames.frames.raid.x * data.uiScale
    nkUISetup.modules.unitFrames.frames.raid.y = nkUISetup.modules.unitFrames.frames.raid.y * data.uiScale

    nkUISetup.modules.unitFrames.frames.playerCastBar.x = nkUISetup.modules.unitFrames.frames.playerCastBar.x * data.uiScale
    nkUISetup.modules.unitFrames.frames.playerCastBar.y = nkUISetup.modules.unitFrames.frames.playerCastBar.y * data.uiScale  

    nkUISetup.modules.unitFrames.frames.targetCastBar.x = nkUISetup.modules.unitFrames.frames.targetCastBar.x * data.uiScale
    nkUISetup.modules.unitFrames.frames.targetCastBar.x = nkUISetup.modules.unitFrames.frames.targetCastBar.x * data.uiScale

end

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
function internalFunc.setupDefaults()

    local parentWidth = UIParent:GetWidth()
    data.uiScale = parentWidth / 3440

    if nkUISetup == nil or nkUISetup.tutorialVersion == nil or nkUISetup.tutorialVersion < 40 then
        nkUISetup = _defaults
        nkUISetup.modules.actionBars.bars = {}
        nkUISetup.modules.actionBars.bars[LibEKL.Unit.GetPlayerDetails().name] = { roles = {} }

        scaleUI ()
    else
        nkUISetup = LibEKL.Tools.Settings.UpdateSettings (_defaults, nkUISetup)
    end

   
    -- check for new char

    if nkUISetup.modules.actionBars.bars[LibEKL.Unit.GetPlayerDetails().name] == nil then
        nkUISetup.modules.actionBars.bars[LibEKL.Unit.GetPlayerDetails().name] = { roles = {} }
    end

    -- mpa updates

    if nkUIMapGathering == nil then
        nkUIMapGathering = { gatheringData = {}, artifactsData = {}}
    end

end

function internalFunc.toggleAlpha()
    
    uiElements.frames["player"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)    
    uiElements.frames["player.pet"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
    uiElements.frames["player.target"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)
    uiElements.frames["focus"]:SetAlpha(nkUISetup.modules.unitFrames.nonCombatAlpha)

end

function internalFunc.actionBarToggleAlpha()
    
    for k, v in pairs (uiElements.actionbars) do
        v:SetAlpha(nkUISetup.modules.actionBars.nonCombatAlpha)
    end

end

function settingsUI.checkbox (name, parent, text, active, callBack)

    local thisCheckbox = LibEKL.UICreateFrame("nkCheckbox", name, parent)
    
    thisCheckbox:SetText(text, true)
    thisCheckbox:SetActive(active)
    thisCheckbox:SetLabelWidth(200)
    thisCheckbox:SetFontSize(14)
    thisCheckbox:SetTextFont(addonInfo.id, "MontserratSemiBold")
    thisCheckbox:SetLabelColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    thisCheckbox:SetColor(data.theme.formElementColorMain)
    thisCheckbox:SetColorInner(data.theme.formElementColorSub)
    thisCheckbox:SetEffectGlow({strength = 3})
    
    Command.Event.Attach(LibEKL.Events[name].CheckboxChanged, function (_, newValue)		
        callBack(newValue)
    end, name .. ".CheckboxChanged")

    return thisCheckbox

end

function settingsUI.combobox (name, parent, text, active, callBack)

    local thisCombobox = LibEKL.UICreateFrame("nkCombobox", name, parent)
    
    thisCombobox:SetText(text, true)
    thisCombobox:SetActive(active)
    thisCombobox:SetLabelWidth(200)
	thisCombobox:SetWidth(300)    
    thisCombobox:SetFont(addonInfo.id, "MontserratSemiBold")
    thisCombobox:SetLabelColor(data.theme.labelColor)
    thisCombobox:SetColorInner(0, 0, 0, .2)
    thisCombobox:SetColor(1, 1, 1, 1)
	thisCombobox:SetColorBorder(0, 0, 0, .2) 
    thisCombobox:SetColorSelected(data.theme.labelColor)
    thisCombobox:SetEffectGlow({strength = 3})

    Command.Event.Attach(LibEKL.Events[name].ComboChanged, function (_, newValue)		
        callBack(newValue.value)
    end, name .. ".CheckboxChanged")

    return thisCombobox

end

function settingsUI.slider (name, parent, text, active, callBack)

    local thisSlider = LibEKL.UICreateFrame("nkSlider", name, parent)

    thisSlider:SetText(text, true)
    thisSlider:SetWidth(350)
    thisSlider:SetLabelWidth(200)
    thisSlider:SetLabelColor(data.theme.labelColor)
    thisSlider:SetFontSize(14)
    thisSlider:SetActive(active)
    thisSlider:SetFont(addonInfo.id, "MontserratSemiBold")
    thisSlider:SetColor(0, 0, 0, .2)
    thisSlider:SetColorInner({ r = 0, g = 0, b = 0, a = .4})
    thisSlider:SetColorHighlight(data.theme.formElementColorMain)    
    thisSlider:SetEffectGlow({strength = 3})

    Command.Event.Attach(LibEKL.Events[name].SliderChanged, function (_, newValue)
        callBack(newValue)
    end, name .. ".SliderChanged")

    return thisSlider

end


function settingsUI.label (name, parent, text)

    local thisText = LibEKL.UICreateFrame("nkText", name, parent)

    thisText:SetText(text, true)
    thisText:SetWidth(350)
    thisText:SetFontSize(14)
    thisText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    thisText:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    thisText:SetEffectGlow({strength = 3})

    return thisText

end

function settingsUI.header (name, parent, text)

    local thisHeader = LibEKL.UICreateFrame("nkText", name, parent)
    thisHeader:SetFontSize(18)
    thisHeader:SetText(text)
    thisHeader:SetTextFont(addonInfo.id, "MontserratBold")
    thisHeader:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    thisHeader:SetEffectGlow({strength = 3})

    return thisHeader

end

function internalFunc.setupUI ()
    
    local name = "nkUI.config"

    local config = LibEKL.UICreateFrame("nkWindow", name, uiElements.settingsContext)
    config:SetLayer(1)
    config:SetWidth(950)
    config:SetHeight(650)
    config:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (LibEKL.UI.getBoundRight() / 2) - (config:GetWidth()/2), 200)
    config:SetTitle(addonInfo.toc.Identifier .. " Version ".. addonInfo.toc.Version)
    config:SetTitleFont(addonInfo.id, "MontserratBold")
    config:SetTitleFontSize(16)
    config:SetTitleEffect ( {strength = 3})
    config:SetCloseable(true)
    config:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

    config:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(12, 12, math.pi / 4, 0, 0),  -- 45° rotation
        color = {
            {r = 0.1294, g = 0.1533, b = 0.2157, a = 1, position = 0}, -- Start color
            {r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1}  -- End color
        }
    },  {
        r = 0x66 / 255,
        g = 0x56 / 255,
        b = 0x2e / 255,
        a = 1,
        cap = "round",
        miter = "miter",
        thickness = 2
    })

    local nkUILogo = LibEKL.UICreateFrame("nkTexture", name .. ".logo", config)
    nkUILogo:SetPoint("BOTTOMLEFT", config, "BOTTOMLEFT", 10, -10)
    nkUILogo:SetWidth(90)
    nkUILogo:SetHeight(89)
    nkUILogo:SetTextureAsync("nkUI", "gfx/nkUILogo.png")

    local tabPane = LibEKL.UICreateFrame("nkTabPane", name .. ".tabPane", config:GetContent())
    tabPane:SetBorder(false)
    tabPane:SetVertical(true)
    tabPane:SetFont(addonInfo.id, "MontserratSemiBold")
    tabPane:SetColor(
        {   thickness = 1, 
            r = data.theme.windowEndColor.r, g = data.theme.windowEndColor.g, b = data.theme.windowEndColor.b, a = 0
        }, 
        {   type = 'solid', 
            r = data.theme.windowEndColor.r, g = data.theme.windowEndColor.g, b = data.theme.windowEndColor.b, a = .3},
        data.theme.labelColor, data.theme.labelColor)

    local paneTabTheme = settingsUI.uiConfigTabTheme(name .. ".tab.Theme", tabPane)
    local paneTabMap = settingsUI.uiConfigTabMap(name .. ".tab.Map", tabPane)
    local paneTabQuestTracker = settingsUI.uiConfigTabQuestTracker (name .. ".tab.QuestTracker", tabPane)
    local paneTabActionBar = settingsUI.uiConfigTabActionBar(name .. ".tab.ActionBar", tabPane)
    local paneTabLowerBar = settingsUI.uiConfigTabLowerBar(name .. ".tab.LowerBar", tabPane)
    local paneTabSCT = settingsUI.uiConfigTabSCT(name .. ".tab.SCT", tabPane)
    local paneTabTooltip = settingsUI.uiConfigTabTooltip(name .. ".tab.Tooltip", tabPane)
    local paneTabBuffBar = settingsUI.uiConfigTabBuffBar(name .. ".tab.BuffBar", tabPane)

    local paneTabRessourceBar = settingsUI.uiConfigTabRessourceBar(name .. ".tab.RessourceBar", tabPane, nkUISetup.modules.unitFrames.frames.ressourceBar)

    local paneTabPlayerCastbar = settingsUI.uiConfigTabCastBar(name .. ".tab.PlayerCastbar", tabPane, "player.castbar", nkUISetup.modules.unitFrames.frames.playerCastBar)
    local paneTabTargetCastbar = settingsUI.uiConfigTabCastBar(name .. ".tab.TargetCastbar", tabPane, "player.target.castbar", nkUISetup.modules.unitFrames.frames.targetCastBar)

    local paneTabUnitFrameBasic = settingsUI.uiConfigTabUFBasic(name .. ".tab.UnitFrameBasic", tabPane)

    local paneTabUnitFrames = settingsUI.uiConfigTabUnitFrames(name .. ".tab.UnitFrames", tabPane)

    local versionText = LibEKL.UICreateFrame("nkText", name .. ".versionText", config)
    versionText:SetFontSize(11)
    versionText:SetText(stringFormat("Version %s", addonInfo.toc.Version))
    versionText:SetFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    versionText:SetPoint("BOTTOMRIGHT", tabPane, "BOTTOMRIGHT", -5, -5)
    versionText:SetLayer(99)

    LibEKL.UI.SetFont(versionText, addonInfo.id, "Montserrat")

    local closeButton = LibEKL.UICreateFrame("nkButton", name .. ".closeButton", config:GetContent())

    closeButton:SetPoint("BOTTOMRIGHT", config:GetContent(), "BOTTOMRIGHT", -10, -10)
    closeButton:SetText(langTexts.settings.close)
    closeButton:SetScale(.8)
    closeButton:SetLayer(9)
    closeButton:SetFont(addonInfo.id, "MontserratSemiBold")
    closeButton:SetLabelColor(data.theme.labelColor)
    closeButton:SetEffectGlow ({ strength = 3 })
    closeButton:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
    closeButton:SetBorderColor({ r = 0, g = 0, b = 0, a = .7, thickness = 1})

    Command.Event.Attach(LibEKL.Events[name .. ".closeButton"].Clicked, function (_, newValue)
        uiElements.settings:SetVisible(false)   
    end, name .. ".closeButton.Clicked")

    local tutorialButton = LibEKL.UICreateFrame("nkButton", name .. ".tutorialButton", config:GetContent())

    tutorialButton:SetPoint("CENTERRIGHT", closeButton, "CENTERLEFT", -10, 0)
    tutorialButton:SetText(langTexts.settings.tutorial)
    tutorialButton:SetScale(.8)
    tutorialButton:SetLayer(9)
    tutorialButton:SetFont(addonInfo.id, "MontserratSemiBold")
    tutorialButton:SetLabelColor(data.theme.labelColor)
    tutorialButton:SetEffectGlow ({ strength = 3 })
    tutorialButton:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
    tutorialButton:SetBorderColor({ r = 0, g = 0, b = 0, a = .7, thickness = 1})

    Command.Event.Attach(LibEKL.Events[name .. ".tutorialButton"].Clicked, function (_, newValue)
        internalFunc.tutorial()
    end, name .. ".tutorialButton.Clicked")

    local moveButton = LibEKL.UICreateFrame("nkButton", name .. ".moveButton", config:GetContent())

    moveButton:SetPoint("CENTERRIGHT", tutorialButton, "CENTERLEFT", -10, 0)
    moveButton:SetText(langTexts.settings.moveUI)
    moveButton:SetScale(.8)
    moveButton:SetLayer(9)
    moveButton:SetFont(addonInfo.id, "MontserratSemiBold")
    moveButton:SetLabelColor(data.theme.labelColor)
    moveButton:SetEffectGlow ({ strength = 3 })
    moveButton:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
    moveButton:SetBorderColor({ r = 0, g = 0, b = 0, a = .7, thickness = 1})

    Command.Event.Attach(LibEKL.Events[name .. ".moveButton"].Clicked, function (_, newValue)
        internalFunc.initMove()
        config:SetVisible(false)
    end, name .. ".moveButton.Clicked")

    local oSetVisible = config.SetVisible

    function config:SetVisible(flag)   
        oSetVisible(self, flag)
    end

    tabPane:SetPoint("TOPLEFT", config:GetContent(), "TOPLEFT", 10, 10)
    tabPane:SetPoint("BOTTOMRIGHT", config:GetContent(), "BOTTOMRIGHT", -10, -50)
    tabPane:SetLayer(1)

    tabPane:AddPane( { label = langTexts.settings.theme, effect = { strength = 3 }, frame = paneTabTheme, initFunc = function() paneTabTheme:build() end}, false)
    tabPane:AddPane( { label = langTexts.settings.map, effect = { strength = 3 }, frame = paneTabMap, initFunc = function() paneTabMap:build() end}, false)
    tabPane:AddPane( { label = langTexts.settings.questTracker, effect = { strength = 3 }, frame = paneTabQuestTracker, initFunc = function() paneTabQuestTracker:build() end}, false)

    tabPane:AddPane( { label = langTexts.settings.actionBar, effect = { strength = 3 }, frame = paneTabActionBar, initFunc = function() paneTabActionBar:build() end}, false)
    tabPane:AddPane( { label = langTexts.settings.lowerBar, effect = { strength = 3 }, frame = paneTabLowerBar, initFunc = function() paneTabLowerBar:build() end}, false)
    tabPane:AddPane( { label = langTexts.settings.sct, effect = { strength = 3 }, frame = paneTabSCT, initFunc = function() paneTabSCT:build() end}, false)
    tabPane:AddPane( { label = langTexts.settings.tooltip, effect = { strength = 3 }, frame = paneTabTooltip, initFunc = function() paneTabTooltip:build() end}, false)
    tabPane:AddPane( { label = langTexts.settings.buffBar, effect = { strength = 3 }, frame = paneTabBuffBar, initFunc = function() paneTabBuffBar:build() end}, false)

    tabPane:AddPane( { label = langTexts.settings.ressourceBar, effect = { strength = 3 }, frame = paneTabRessourceBar, initFunc = function() paneTabRessourceBar:build() end}, false)

    tabPane:AddPane( { label = langTexts.settings.playerCastbar, effect = { strength = 3 }, frame = paneTabPlayerCastbar, initFunc = function() paneTabPlayerCastbar:build() end}, false)
    tabPane:AddPane( { label = langTexts.settings.targetCastbar, effect = { strength = 3 }, frame = paneTabTargetCastbar, initFunc = function() paneTabTargetCastbar:build() end}, false)

    tabPane:AddPane( { label = langTexts.settings.unitframes, effect = { strength = 3 }, frame = paneTabUnitFrameBasic, initFunc = function() paneTabUnitFrameBasic:build() end}, false)

    tabPane:AddPane( { label = langTexts.settings.units, effect = { strength = 3 }, frame = paneTabUnitFrames, initFunc = function() paneTabUnitFrames:build() end}, true)

    --if LibEKL.Events.CheckEvents ("nkRadial", true) == false then return nil end

    config:SetVisible(true)

    return config

end

function internalFunc.setupInit ()
    if uiElements.settings == nil then
        uiElements.settings = internalFunc.setupUI ()
    else
        uiElements.settings:SetVisible(true)
    end
end


