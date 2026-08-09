local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local internalFunc  = privateVars.internalFunc

local mathFloor     = math.floor
local mathMax       = math.max
local mathMin       = math.min
local stringGMatch  = string.gmatch

---------- init local variables ---------

-- Resolution the _defaults in settings/settings.lua are written for.
local DESIGN_W, DESIGN_H = 3440, 1440

-- Lower bounds so that scaling down never makes text unreadable or icons
-- too small to hit.
local MIN_FONT = 9
local MIN_ICON = 8

--[[
    Positioning model

    Every entry states which screen edge an element is bound to and how far
    away it sits, measured in design pixels (3440x1440):

        a = -1   left or top edge
        a =  0   screen centre
        a =  1   right or bottom edge
        d        distance from that edge; with a = 0 the offset from centre

    The point of this: elements bound to the same edge keep their distance to
    each other, because they share one scale factor. The bottom row -- action
    bars, unit frames, cast bars -- hangs off the bottom edge, the top group
    -- buff bar, raid, group -- off the top and left. The difference in aspect
    ratio therefore ends up in the middle of the screen, where nothing sits,
    instead of pushing the groups into each other.

    Scaling every position by the width ratio instead pulls everything towards
    the centre, which is what made elements overlap on 16:9 screens.
]]

-- Anchored with SetPoint("CENTER", UIParent, "CENTER", x, y)
local CENTER_POS = {
    ["modules.unitFrames.frames.player"]         = { ax =  0, dx = -300, ay =  1, dy = 420 },
    ["modules.unitFrames.frames.target"]         = { ax =  0, dx =  300, ay =  1, dy = 420 },
    ["modules.unitFrames.frames.targetOfTarget"] = { ax =  0, dx =  700, ay =  1, dy = 415 },
    ["modules.unitFrames.frames.playerPet"]      = { ax =  0, dx = -675, ay =  1, dy = 320 },
    ["modules.unitFrames.frames.focus"]          = { ax =  0, dx = -900, ay =  1, dy = 470 },
    ["modules.unitFrames.frames.ressourceBar"]   = { ax =  0, dx =    0, ay =  1, dy = 430 },
    ["modules.unitFrames.frames.playerCastBar"]  = { ax =  0, dx =    0, ay =  1, dy = 320 },
    ["modules.unitFrames.frames.targetCastBar"]  = { ax =  0, dx =    0, ay =  1, dy = 520 },
    ["modules.unitFrames.frames.group"]          = { ax = -1, dx =  820, ay = -1, dy = 420 },
    ["modules.unitFrames.frames.raid"]           = { ax = -1, dx =  130, ay = -1, dy = 220 },
    ["modules.buffBar"]                          = { ax = -1, dx =   30, ay = -1, dy =  30 },
    ["modules.actionBars"]                       = { ax =  0, dx =    0, ay =  1, dy = 170 },
}

-- The right hand screen bar lives in the same module under its own keys.
local RIGHT_BAR_POS = { ax = 1, dx = 25, ay = 0, dy = 0 }

--[[
    Windows anchored with SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y).
    With ax = 1, dx is the distance from the right screen edge to the *left*
    edge of the window, that is margin plus window width. Only then does the
    margin on the right stay constant while the window scales with the UI.
]]
local TOPLEFT_POS = {
    ["modules.map"]           = { ax =  1, dx =  307, ay = -1, dy =    7 },
    ["modules.questtracker"]  = { ax =  1, dx =  640, ay = -1, dy =  500 },
    ["modules.questLog"]      = { ax =  0, dx = -500, ay =  0, dy = -400 },
    ["modules.oneBag"]        = { ax =  0, dx =  280, ay =  0, dy = -120 },
    ["modules.auction"]       = { ax = -1, dx =  300, ay = -1, dy =  200 },
    ["modules.minionManager"] = { ax = -1, dx =  200, ay = -1, dy =  200 },
}

-- Bank window of the bag module, a second position pair in the same module.
local BANK_POS = { ax = 0, dx = -520, ay = 0, dy = -120 }

--[[
    Sizes. Each row: path, the keys to scale, lower bound.
    A default of 0 stays 0 -- nkUI switches icons off through it.
]]
local SIZES = {
    { "modules.actionBars",                    { "iconSize", "spacing", "offset" },               1 },
    { "modules.lowerBar",                      { "barHeight", "barWidth" },                       1 },
    { "modules.lowerBar",                      { "fontSize", "barText", "timeSize", "dateSize" }, MIN_FONT },
    { "modules.map",                           { "width", "height", "maximizedWidth",
                                                 "maximizedHeight" },                             1 },
    { "modules.map",                           { "iconSize" },                                    MIN_ICON },
    { "modules.questtracker",                  { "width", "height" },                             1 },
    { "modules.questtracker",                  { "categoryHeaderSize" },                          MIN_FONT },
    { "modules.questtracker.categoryFontSize", { "header", "subHeader", "body" },                 MIN_FONT },
    { "modules.questLog",                      { "width", "height" },                             1 },
    { "modules.questLog",                      { "categoryHeaderSize" },                          MIN_FONT },
    { "modules.questLog.categoryFontSize",     { "header", "subHeader", "body" },                 MIN_FONT },
    { "modules.tooltip.fontSizes",             { "header", "body" },                              MIN_FONT },
    { "modules.buffBar.buffs",                 { "width", "height" },                             MIN_ICON },
    { "modules.buffBar.buffs",                 { "timer", "stack", "label" },                     MIN_FONT },
    { "modules.sct",                           { "messageOffset" },                               nil },
}

-- Sizes inside every unit frame.
local FRAME_SIZES = {
    { nil,          { "width", "height" },                                1 },
    { "fontSizes",  { "name", "health", "energy", "planar", "level" },    MIN_FONT },
    { "margins",    { "name", "health", "energy", "planar", "level",
                      "combatIcon", "roleIcon", "tierIcon", "group" },    1 },
    { "iconSizes",  { "combat", "role", "tier" },                         MIN_ICON },
    { "buffs",      { "width", "height" },                                MIN_ICON },
    { "buffs",      { "timer", "stack", "label" },                        MIN_FONT },
    { "combo",      { "width", "height" },                                1 },
    { "charge",     { "width", "height" },                                1 },
}

---------- local function block ---------

-- Resolves "modules.map" against a table, nil if any step is missing.
local function resolve (root, path)

    local node = root

    for part in stringGMatch(path, "[^.]+") do
        if type(node) ~= "table" then return nil end
        node = node[part]
    end

    return node

end

-- Offset from the screen centre for one axis.
local function centerOffset (anchor, distance, extent, scale)

    if anchor < 0 then return -extent / 2 + distance * scale end
    if anchor > 0 then return  extent / 2 - distance * scale end

    return distance * scale

end

-- Distance from the left or top edge for one axis.
local function edgeOffset (anchor, distance, extent, scale)

    if anchor < 0 then return distance * scale end
    if anchor > 0 then return extent - distance * scale end

    return extent / 2 + distance * scale

end

local function scaleValue (value, scale, minimum)

    if type(value) ~= "number" then return nil end
    if value == 0 then return 0 end

    local scaled = mathFloor(value * scale + 0.5)

    if minimum == nil then return scaled end
    if value < 0 then return mathMin(-minimum, scaled) end

    return mathMax(minimum, scaled)

end

local function scaleKeys (target, source, keys, scale, minimum)

    if type(target) ~= "table" or type(source) ~= "table" then return end

    for idx = 1, #keys, 1 do
        local scaled = scaleValue(source[keys[idx]], scale, minimum)
        if scaled ~= nil then target[keys[idx]] = scaled end
    end

end

---------- addon internalFunc function block ---------

--[[
   screenScale
    Description:
        Size factor for the current screen height.
    Parameters:
        height (number) - height of UIParent
    Returns:
        number
    Notes:
        - Height decides, not width: a wider screen does not make text and
          icons bigger, a taller one does.
]]
function internalFunc.screenScale (height)

    if type(height) ~= "number" or height <= 0 then return 1 end

    return height / DESIGN_H

end

--[[
   layoutForScreen
    Description:
        Recalculates positions and sizes in setup for the given screen size.
    Parameters:
        setup    (table)  - nkUISetup, modified in place
        defaults (table)  - untouched defaults in the 3440x1440 design space
        width    (number) - width of UIParent
        height   (number) - height of UIParent
    Returns:
        None
    Notes:
        - Always calculates from defaults, never from the current values, so
          calling it twice in a row yields the same result.
        - Also sets data.uiScale so that elements scaled at runtime (quest
          log, buff spacing) use the same factor.
]]
function internalFunc.layoutForScreen (setup, defaults, width, height)

    if type(setup) ~= "table" or type(defaults) ~= "table" then return end
    if type(width) ~= "number" or type(height) ~= "number" then return end
    if width <= 0 or height <= 0 then return end

    local scale = internalFunc.screenScale(height)

    data.uiScale = scale

    -- Positions: anchored at CENTER

    for path, pos in pairs(CENTER_POS) do
        local node = resolve(setup, path)

        if node then
            node.x = centerOffset(pos.ax, pos.dx, width,  scale)
            node.y = centerOffset(pos.ay, pos.dy, height, scale)
        end
    end

    local actionBars = resolve(setup, "modules.actionBars")

    if actionBars then
        actionBars.rightBarX = centerOffset(RIGHT_BAR_POS.ax, RIGHT_BAR_POS.dx, width,  scale)
        actionBars.rightBarY = centerOffset(RIGHT_BAR_POS.ay, RIGHT_BAR_POS.dy, height, scale)
    end

    -- Positions: windows anchored at TOPLEFT

    for path, pos in pairs(TOPLEFT_POS) do
        local node = resolve(setup, path)

        if node then
            node.x = edgeOffset(pos.ax, pos.dx, width,  scale)
            node.y = edgeOffset(pos.ay, pos.dy, height, scale)
        end
    end

    local oneBag = resolve(setup, "modules.oneBag")

    if oneBag then
        oneBag.bankX = edgeOffset(BANK_POS.ax, BANK_POS.dx, width,  scale)
        oneBag.bankY = edgeOffset(BANK_POS.ay, BANK_POS.dy, height, scale)
    end

    local map = resolve(setup, "modules.map")

    if map then
        map.maximizedX = edgeOffset(0, -500, width,  scale)
        map.maximizedY = edgeOffset(0, -400, height, scale)
    end

    -- Sizes

    for idx = 1, #SIZES, 1 do
        local entry = SIZES[idx]
        scaleKeys(resolve(setup, entry[1]), resolve(defaults, entry[1]), entry[2], scale, entry[3])
    end

    local frames        = resolve(setup,    "modules.unitFrames.frames")
    local defaultFrames = resolve(defaults, "modules.unitFrames.frames")

    if type(frames) == "table" and type(defaultFrames) == "table" then
        for name, defaultFrame in pairs(defaultFrames) do
            local frame = frames[name]

            if type(frame) == "table" then
                for group = 1, #FRAME_SIZES, 1 do
                    local entry = FRAME_SIZES[group]

                    if entry[1] == nil then
                        scaleKeys(frame, defaultFrame, entry[2], scale, entry[3])
                    else
                        scaleKeys(frame[entry[1]], defaultFrame[entry[1]], entry[2], scale, entry[3])
                    end
                end
            end
        end
    end

end
