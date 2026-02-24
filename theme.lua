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
    }
}