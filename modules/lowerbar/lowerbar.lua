local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local internalFunc = privateVars.internalFunc
local events      = privateVars.events

---------- init variables ---------

uiElements.lowerBarModules = {}

---------- local functions ---------

-- Initializes the lower bar and loads all modules
function internalFunc.lowerBar()

    local parentWidth = UIParent:GetWidth()
    local halfWidth = parentWidth / 2
    data.aThird = halfWidth / 3
    data.aFourth = halfWidth / 4

    -- Load all modules
    internalFunc.timeDate()
    internalFunc.currency()
    internalFunc.fps()
    internalFunc.location()
    internalFunc.experience()
    internalFunc.faction()
    internalFunc.social()
    internalFunc.lowerBarRoles()
end

-- Initializes the lower bar
function internalFunc.lowerBarInit(value)
    if #uiElements.lowerBarModules == 0 then
        EnKai.events.addInsecure(function()
            internalFunc.lowerBar()
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
