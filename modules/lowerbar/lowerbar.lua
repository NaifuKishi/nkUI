local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.lowerBar    = {}

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local lowerBar      = privateVars.lowerBar

local mathpi        = math.pi
local mathRandom    = math.random
local mathFloor     = math.floor
local mathMax       = math.max
local mathMin       = math.min

---------- init variables ---------

uiElements.lowerBarModules = {}
data.lowerBarLayout = {
    left = {},               -- modules on far left (away from time)
    right = {}               -- modules on far right (away from time)    
}

lowerBar.ICON_SPACING = 5
lowerBar.BORDER_SPACING = 15

-- Icon edge length in the lower bar, in the 3440x1440 design space.
lowerBar.ICON_SIZE = 16

--[[
   iconSize
    Description:
        Icon edge length in the lower bar, scaled with the UI.
    Parameters:
        None
    Returns:
        number
    Notes:
        - Without this the icons stay at 16 px while text and bars shrink,
          which makes them look oversized.
        - Use lowerBar.setIcon() to apply a texture: SetTextureAsync resets
          the frame size on load. No transformation matrix is needed here,
          unlike the canvas fills (see modules/unitFrames/buffIcon.lua).
]]
function lowerBar.iconSize ()

    return mathMax(10, mathFloor(lowerBar.ICON_SIZE * (data.uiScale or 1) + 0.5))

end

--[[
   setIcon
    Description:
        Applies a texture to a lower bar icon and keeps the scaled size.
    Parameters:
        frame   (frame)  - nkTexture frame
        texture (string) - path inside nkUI
    Returns:
        None
    Notes:
        - SetTextureAsync resets the frame to the *native* size of the
          texture once it has loaded, so a SetWidth before it is lost.
          LibAsyncTextures calls a callback after loading, which is where
          the size gets set again.
]]
function lowerBar.setIcon (frame, texture)

    local size = lowerBar.iconSize()

    frame:SetWidth(size)
    frame:SetHeight(size)

    frame:SetTextureAsync("nkUI", texture, function (self)
        self:SetWidth(size)
        self:SetHeight(size)
    end)

end

--[[
   fittedBarWidth
    Description:
        Width of a progress bar in the lower bar, capped to the slot its
        module actually gets.
    Parameters:
        side (string) - "left" or "right", the side the module sits on
    Returns:
        number
    Notes:
        - The slots are divided up from the screen width while the
          configured bar width is independent of it. Without this cap the
          bars run out of their slot on narrow resolutions: the experience
          bar towards the right, the faction bar towards the left, both
          ending up underneath the clock in the middle.
        - Icon, icon spacing and border are subtracted.
]]
function lowerBar.fittedBarWidth (side)

    local wanted = nkUISetup.modules.lowerBar.barWidth

    if data.lowerBar == nil then return wanted end

    local slot = data.lowerBar.moduleWidthLeft

    if side == "right" then slot = data.lowerBar.moduleWidthRight end

    if type(slot) ~= "number" then return wanted end

    return mathMax(40, mathMin(wanted, slot - lowerBar.iconSize() - lowerBar.ICON_SPACING - lowerBar.BORDER_SPACING))

end

lowerBar.contextRestricted = UI.CreateContext("nkUI.lowerbar.restricted")
lowerBar.contextRestricted :SetStrata('hud')
lowerBar.contextRestricted :SetSecureMode("restricted")
lowerBar.contextRestricted :SetLayer(2)

lowerBar.contextInsecure = UI.CreateContext("nkUI.lowerbar.insecure")
lowerBar.contextInsecure:SetStrata('hud')
lowerBar.contextInsecure:SetLayer(3)

---------- local functions ---------

-- Helper: Generate a random background color
local function getRandomColor()
    return {
        r = mathRandom() * 0.5 + 0.25,  -- 0.25-0.75
        g = mathRandom() * 0.5 + 0.25,
        b = mathRandom() * 0.5 + 0.25,
        a = 0.3
    }
end

-- Helper: Position a module on left side (away from time)
function lowerBar.positionLeft(frame)
    local left = data.lowerBarLayout.left
    table.insert(left, frame)
end

-- Helper: Position a module on right side (away from time)lwoerBar.BORDER_SPACING 
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

    data.lowerBar.moduleWidthLeft = leftModuleWidth

    for idx, frame in ipairs(left) do

        frame:SetWidth(leftModuleWidth)
        local xOffset = (idx - 1) * leftModuleWidth + leftModuleWidth / 2

        -- Apply random background color
        --local color = getRandomColor()
        --frame:SetBackgroundColor(color.r, color.g, color.b, 1)

        if idx == 1 then
            frame:SetPoint("CENTERLEFT", uiElements.lowerBarCanvas, "CENTERLEFT", lowerBar.BORDER_SPACING, 0)
        else
            frame:SetPoint("CENTER", uiElements.lowerBarCanvas, "CENTERLEFT", xOffset, 0)
        end
    end

    -- Position right modules (far right, away from time)
    local rightModuleWidth = #right > 0 and (data.lowerBar.availablePerSide / #right) or 0

    data.lowerBar.moduleWidthRight = rightModuleWidth

    for idx, frame in ipairs(right) do

        frame:SetWidth(rightModuleWidth)
        local xOffset = -((idx - 1) * rightModuleWidth + rightModuleWidth / 2)

        -- Apply random background color
        --local color = getRandomColor()
        --frame:SetBackgroundColor(color.r, color.g, color.b, 1)

        if idx == 1 then
            frame:SetPoint("CENTERRIGHT", uiElements.lowerBarCanvas, "CENTERRIGHT", -lowerBar.BORDER_SPACING, 0)
        else
            frame:SetPoint("CENTER", uiElements.lowerBarCanvas, "CENTERRIGHT", xOffset, 0)
        end

    end
end

function lowerBar.dataSet(name, texture, align)

    local height = uiElements.lowerBarCanvas:GetHeight()

    local datasetFrame = LibEKL.UICreateFrame("nkFrame", name .. ".frame", lowerBar.contextRestricted)
    datasetFrame:SetHeight(height)
    datasetFrame:SetLayer(2)
    datasetFrame:SetSecureMode('restricted')

    local icon = LibEKL.UICreateFrame("nkTexture", name .. ".icon", datasetFrame)
    lowerBar.setIcon(icon, texture)

    local label = LibEKL.UICreateFrame("nkText", name .. ".text", datasetFrame)    
    label:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    label:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    label:SetTextFont(addonInfo.id, "MontserratMedium")
    label:SetEffectGlow({ strength = 1})
    label:SetLayer(10)

    if align == "left" then
        icon:SetPoint("CENTERLEFT", datasetFrame, "CENTERLEFT", 0, 0)
        label:SetPoint("CENTERLEFT", icon, "CENTERRIGHT", lowerBar.ICON_SPACING, 0)
    else
        label:SetPoint("CENTERRIGHT", datasetFrame, "CENTERRIGHT", 0, 0)
        icon:SetPoint("CENTERRIGHT", label, "CENTERLEFT", -lowerBar.ICON_SPACING, 0)
    end    

    function datasetFrame:SetText(newText)
        label:SetText(newText, true)
    end

    function datasetFrame:SetFontSize(newFontSize)
        label:SetFontSize(newFontSize)
    end

    function datasetFrame:SetTextureAsync(newTexture)
        lowerBar.setIcon(icon, newTexture)
    end

    return datasetFrame

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
    local timeWidth = 120 * data.uiScale  -- estimated width of time display
    local availablePerSide = (canvasWidth - timeWidth) / 2

    -- Store layout info for modules to use
    data.lowerBar = data.lowerBar or {}
    data.lowerBar.availablePerSide = availablePerSide
    data.lowerBar.canvasWidth = canvasWidth

    -- Slot widths. redistributeLayout() sets them exactly a moment later,
    -- but the experience and faction bars need them while being built, and
    -- that happens first. Five modules per side, see below.
    data.lowerBar.moduleWidthLeft  = availablePerSide / 5
    data.lowerBar.moduleWidthRight = availablePerSide / 5

    -- Load all modules in order
    -- Left side (towards time): social, wardrobe, roles, experience

    local thisDataSet = lowerBar.fps()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionLeft(thisDataSet)

    local thisDataSet = lowerBar.social()
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

    local thisDataSet = lowerBar.minion()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionRight(thisDataSet)    

    local thisDataSet = lowerBar.currency()
    table.insert(uiElements.lowerBarModules, thisDataSet)
    lowerBar.positionRight(thisDataSet)

    local thisDataSet = lowerBar.vitality()
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
