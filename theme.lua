local addonInfo, privateVars = ...

-- Initialize d
local data        = privateVars.data

data.theme = {
    windowStartColor = { r = 0.25, g = 0.25, b = 0.2, a = 0.7, position = 0 }, -- yellowish dark grey
    windowEndColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.7, position = 1 },  -- Blackish gray
    labelColor = {r = 1, g = 0.8, b = 0, a = 1},
    formElementColorSub = {r = 0, g = 0, b = 0, a = 1},
    formElementColorMain = {r = 1, g = 0.8, b = 0, a = 1},

    -- Standard stroke/border styling
    STROKE_BORDER = {
        r = 0x66 / 255,
        g = 0x56 / 255,
        b = 0x2e / 255,
        a = 1,
        cap = "round",
        miter = "miter",
        thickness = 2
    },

    -- Standard color values
    COLOR_WHITE = { r = 1, g = 1, b = 1, a = 1 },
    COLOR_DEFAULT = { r = 1, g = 1, b = 1, a = 1 },

    -- Standard effect glow strengths
    GLOW_WEAK = { strength = 1 },
    GLOW_STANDARD = { strength = 3 },
    GLOW_COOLDOWN = { strength = 2 },

    -- Standard canvas paths
    CANVAS_RECT_PATH = {
        {xProportional = 0, yProportional = 0},
        {xProportional = 1, yProportional = 0},
        {xProportional = 1, yProportional = 1},
        {xProportional = 0, yProportional = 1},
        {xProportional = 0, yProportional = 0}
    }
}