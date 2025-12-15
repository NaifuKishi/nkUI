local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.lowerBar    = {}

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local internalFunc = privateVars.internalFunc
local lowerBar      = privateVars.lowerBar

local mathpi        = math.pi

---------- init variables ---------

uiElements.lowerBarModules = {}

---------- local functions ---------

-- Initializes the lower bar and loads all modules
function lowerBar.build()

    local parentWidth = UIParent:GetWidth()
    local halfWidth = parentWidth / 2
    data.aThird = halfWidth / 3
    data.aFourth = halfWidth / 4

    -- Create a canvas behind the lower bar

    if not uiElements.lowerBarCanvas then
        uiElements.lowerBarCanvas = EnKai.uiCreateFrame("nkCanvas", "nkUI.lowerBarCanvas", uiElements.contextLowest)
        uiElements.lowerBarCanvas:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, -50)
        uiElements.lowerBarCanvas:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

        local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1 }

        local path = {  {xProportional = 0, yProportional = 0},
                    {xProportional = 1, yProportional = 0},
                    {xProportional = 1, yProportional = 1},
                    {xProportional = 0, yProportional = 1},
                    {xProportional = 0, yProportional = 0}
                    }

        local fill = {  type = "gradientLinear", 
                        transform = Utility.Matrix.Create(2, 2, (mathpi / 2), 0, 0), 
                        color = {   { r = 0.678, g = 0.847, b = 0.902, a = 0, position = 0 },
                                    { r = 0.678, g = 0.847, b = 0.902, a = .6, position = 1 }
                                }
                    }

        uiElements.lowerBarCanvas:SetShape (path, fill, nil)
    end

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

        uiElements.lowerBarCanvas:SetVisible(value)
    end
end

-- Redraws all lower bar modules
function internalFunc.lowerBarRedraw()
    for idx = 1, #uiElements.lowerBarModules, 1 do
        uiElements.lowerBarModules[idx]:Redraw()
    end
    
    EnKai.ui.reloadDialog("nkUI")
end
