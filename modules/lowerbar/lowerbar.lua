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

    --local height = 35
    local height = nkUISetup.modules.lowerBar.barHeight + 18

    -- Create a canvas behind the lower bar

    
    if not uiElements.lowerBarCanvas then
        uiElements.lowerBarCanvas = LibEKL.UICreateFrame("nkCanvas", "nkUI.lowerBarCanvas", lowerBar.contextRestricted)
        uiElements.lowerBarCanvas:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, -height)
        uiElements.lowerBarCanvas:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
        uiElements.lowerBarCanvas:SetLayer(1)

        local stroke = data.theme.STROKE_BORDER

        local path = {  {xProportional = 0, yProportional = 0},
                        {xProportional = 1, yProportional = 0},
                        {xProportional = 1, yProportional = 1},
                        {xProportional = 0, yProportional = 1},
                        {xProportional = 0, yProportional = 0}}

        local ratio = height / parentWidth

        local fill = {  type = "gradientLinear",
                        transform = Utility.Matrix.Create(2, 2, math.pi, 0, 0), -- 180 degree angle
                        color = {
                            {r = 0.13, g = 0.15, b = 0.20, a = 1, position = 0}, -- Start color
                            {r = 0.10, g = 0.11, b = 0.15, a = 1, position = 1}  -- End color
                        }}

        if nkUISetup.modules.lowerBar.transparent then
            stroke.a = 0
            uiElements.lowerBarCanvas:SetShape (path, nil, stroke)
        else
            uiElements.lowerBarCanvas:SetShape (path, fill, stroke)
        end

        uiElements.lowerBarCanvas:SetVisible(true)
    end

    -- Load all modules
    uiElements.lowerBarTimeDate = lowerBar.timeDate()
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

    if uiElements.lowerBarCanvas then
        local height = nkUISetup.modules.lowerBar.barHeight + 18
        uiElements.lowerBarCanvas:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, -height)
    end
    
    LibEKL.UI.reloadDialog("nkUI")
end
