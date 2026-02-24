local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events

local mathpi        = math.pi

local NAME = "nkUI.chat"

local contextLowest = UI.CreateContext("nkUI.Layout.grid")
contextLowest:SetStrata('hud')
contextLowest:SetLayer(2)

function internalFunc.chat ()    

    -- Create a canvas behind the chat

    UI.Native.Console1:SetLayer(2)

    local canvas = LibEKL.UICreateFrame("nkCanvas", NAME, contextLowest)
    canvas:SetPoint("TOPLEFT", UI.Native.Console1, "TOPLEFT", 0, 30)
    canvas:SetPoint("BOTTOMRIGHT", UI.Native.Console1, "BOTTOMRIGHT")
    canvas:SetLayer(1)

    local stroke = data.theme.STROKE_BORDER

    local path = {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }

    local fill = {
        type = "gradientLinear",
        transform = Utility.Matrix.Create(6, 0.5, math.pi / 4, 0, 0),  -- 45° rotation
        color = {
            {r = 0.08, g = 0.10, b = 0.15, a = 1, position = 0}, -- Start color
            {r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1}  -- End color
        }
    }

    canvas:SetShape (path, fill, stroke)

end