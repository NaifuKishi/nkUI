local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.lowerBar    = {}

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local lowerBar      = privateVars.lowerBar

local mathpi        = math.pi

---------- init variables ---------

uiElements.lowerBarModules = {}

lowerBar.contextRestricted = UI.CreateContext("nkUI.lowerbar.restricted")
lowerBar.contextRestricted :SetStrata('hud')
lowerBar.contextRestricted :SetSecureMode("restricted")
lowerBar.contextRestricted :SetLayer(2)

---------- local functions ---------

-- Initializes the lower bar and loads all modules
function lowerBar.build()

    local parentWidth = UIParent:GetWidth()
    local halfWidth = parentWidth / 2
    data.aThird = halfWidth / 3
    data.aFourth = halfWidth / 4

    local height = 80

    -- Create a canvas behind the lower bar

    if not uiElements.lowerBarCanvas then
        uiElements.lowerBarCanvas = LibEKL.UICreateFrame("nkCanvas", "nkUI.lowerBarCanvas", lowerBar.contextRestricted)
        uiElements.lowerBarCanvas:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, -height)
        uiElements.lowerBarCanvas:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)        

        local stroke = {r = 1, g = 0, b = 0, a = 1, thickness = 1 }

        local path = {  {xProportional = 0, yProportional = 0},
                        {xProportional = 1, yProportional = 0},
                        {xProportional = 1, yProportional = 1},
                        {xProportional = 0, yProportional = 1},
                        {xProportional = 0, yProportional = 0}}

        local ratio = height / parentWidth

        local fill = {  type = "gradientLinear", 
                        transform = Utility.Matrix.Create(1, ratio, math.pi/2, 0, 0),
                        color = {   { r = 0.1, g = 0.2, b = 0.4, a = 0.0, position = 0 },
                                    { r = 0.1, g = 0.2, b = 0.4, a = 0.35, position = .5 },
                                    { r = 0.1, g = 0.2, b = 0.4, a = 0.7, position = 1 }
                                }
                    }

        uiElements.lowerBarCanvas:SetShape (path, fill, nil)
        uiElements.lowerBarCanvas:SetVisible(true)
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
    lowerBar.vitality()
end

-- Initializes the lower bar
function internalFunc.lowerBarInit(value)

    if #uiElements.lowerBarModules == 0 then
        LibEKL.Events.AddInsecure(function()
            lowerBar.build()
        end, nil, nil)
    else
        --LibEKL.Events.AddInsecure(function()
            for k, v in pairs(uiElements.lowerBarModules) do
                v:SetVisible(value)
            end
        --end, nil, nil)

        uiElements.lowerBarCanvas:SetVisible(value)
    end

end

-- Redraws all lower bar modules
function internalFunc.lowerBarRedraw()
    for idx = 1, #uiElements.lowerBarModules, 1 do
        uiElements.lowerBarModules[idx]:Redraw()
    end
    
    LibEKL.UI.reloadDialog("nkUI")
end
