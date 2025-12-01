local addonInfo, privateVars = ...

---------- init namespace ---------

local data      = privateVars.data
local uiElements= privateVars.uiElements
local _internal = privateVars.internal
local _events   = privateVars.events

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
                                                        iconSizes = {combat = 22, role = 15, tier = 15 }
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