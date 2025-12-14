local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.lowerBar    = {}

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local internalFunc = privateVars.internalFunc
local lowerBar      = privateVars.lowerBar

---------- init variables ---------

uiElements.lowerBarModules = {}

---------- local functions ---------

-- Initializes the lower bar and loads all modules
function lowerBar.build()

    local parentWidth = UIParent:GetWidth()
    local halfWidth = parentWidth / 2
    data.aThird = halfWidth / 3
    data.aFourth = halfWidth / 4

    -- Load all modules
    lowerBar.timeDate()
    lowerBar.currency()
    lowerBar.fps()
    lowerBar.location()
    lowerBar.experience()
    lowerBar.faction()
    lowerBar.social()
    lowerBar.lowerBarRoles()
end

-- Initializes the lower bar
function internalFunc.lowerBarInit(value)
    if #uiElements.lowerBarModules == 0 then
        EnKai.events.addInsecure(function()
            lowerBar.build()
        end, nil, nil)
    else
        EnKai.events.addInsecure(function()
            for k, v in pairs(uiElements.lowerBarModules) do
                v:SetVisible(value)
            end
        end, nil, nil)
    end
end

-- Redraws all lower bar modules
function internalFunc.lowerBarRedraw()
    for idx = 1, #uiElements.lowerBarModules, 1 do
        uiElements.lowerBarModules[idx]:Redraw()
    end
    
    EnKai.ui.reloadDialog("nkUI")
end
