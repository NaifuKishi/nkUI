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
data.lowerBarLayout = {
    left = {},               -- modules on far left (away from time)
    right = {}               -- modules on far right (away from time)
}

lowerBar.contextRestricted = UI.CreateContext("nkUI.lowerbar.restricted")
lowerBar.contextRestricted :SetStrata('hud')
lowerBar.contextRestricted :SetSecureMode("restricted")
lowerBar.contextRestricted :SetLayer(2)

---------- local functions ---------

-- Helper: Position a module on left side (away from time)
function lowerBar.positionLeft(frame)
    local left = data.lowerBarLayout.left
    table.insert(left, frame)
end

-- Helper: Position a module on right side (away from time)
function lowerBar.positionRight(frame)
    local right = data.lowerBarLayout.right
    table.insert(right, frame)
end

-- Redistribute all modules evenly on their respective sides
function lowerBar.redistributeLayout()
    local left = data.lowerBarLayout.left
    local right = data.lowerBarLayout.right

    -- Position left modules (far left, away from time)
    local leftModuleWidth = #left > 0 and (data.lowerBar.availablePerSide / #left) or 0
    for idx, frame in ipairs(left) do

        frame:SetWidth(leftModuleWidth)
        local xOffset = (idx - 1) * leftModuleWidth + leftModuleWidth / 2
        
        if idx == 1 then
            frame:SetPoint("CENTERLEFT", uiElements.lowerBarCanvas, "CENTERLEFT", 0, 0)
        else
            frame:SetPoint("CENTER", uiElements.lowerBarCanvas, "CENTERLEFT", xOffset, 0)
        end
    end

    -- Position right modules (far right, away from time)
    local rightModuleWidth = #right > 0 and (data.lowerBar.availablePerSide / #right) or 0

    for idx, frame in ipairs(right) do

        frame:SetWidth(rightModuleWidth)
        local xOffset = -((idx - 1) * rightModuleWidth + rightModuleWidth / 2)

        if idx == 1 then
            frame:SetPoint("CENTERRIGHT", uiElements.lowerBarCanvas, "CENTERRIGHT", 0, 0)
        else
            frame:SetPoint("CENTER", uiElements.lowerBarCanvas, "CENTERRIGHT", xOffset, 0)
        end
        
    end
end

-- Initializes the lower bar and loads all modules
function lowerBar.build()

    local parentWidth = UIParent:GetWidth()
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

    -- Layout structure:
    -- [LEFT ANCHORED MODULES] [CENTER TIME] [RIGHT ANCHORED MODULES]
    -- Left and right have equal space, modules distribute evenly within their sections

    -- Calculate available width for left/right sections
    local canvasWidth = uiElements.lowerBarCanvas:GetWidth()
    local timeWidth = 120  -- estimated width of time display
    local availablePerSide = (canvasWidth - timeWidth) / 2

    -- Store layout info for modules to use
    data.lowerBar = data.lowerBar or {}
    data.lowerBar.availablePerSide = availablePerSide
    data.lowerBar.canvasWidth = canvasWidth

    -- Load all modules in order
    -- Left side (towards time): social, wardrobe, roles, experience

    local thisDataSet = lowerBar.fps()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionLeft(thisDataSet)

    local thisDataSet = lowerBar.lowerBarWardrobe()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionLeft(thisDataSet)

    local thisDataSet = lowerBar.lowerBarRoles()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionLeft(thisDataSet)

    local thisDataSet = lowerBar.experience()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionLeft(thisDataSet)
    
    -- Center: time/date
    uiElements.lowerBarTimeDate = lowerBar.timeDate()

    -- Right side (towards time): faction, vitality, location, currency

    local thisDataSet = lowerBar.location()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionRight(thisDataSet)

    local thisDataSet = lowerBar.currency()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionRight(thisDataSet)

    local thisDataSet = lowerBar.vitality()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionRight(thisDataSet)

    local thisDataSet = lowerBar.social()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionRight(thisDataSet)

    local thisDataSet = lowerBar.faction()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionRight(thisDataSet)

    -- Redistribute all modules evenly on their sides
    lowerBar.redistributeLayout()
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
