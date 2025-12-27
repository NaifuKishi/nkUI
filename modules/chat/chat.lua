local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local internalFunc = privateVars.internalFunc
local events      = privateVars.events

local mathpi        = math.pi

local NAME = "nkUI.chat"

function internalFunc.chat ()    

    -- Create a canvas behind the chat

    local canvas = LibEKL.uiCreateFrame("nkCanvas", NAME, uiElements.contextLowest)
    canvas:SetPoint("TOPLEFT", UI.Native.Console1, "TOPLEFT", 0, 30)
    canvas:SetPoint("BOTTOMRIGHT", UI.Native.Console1, "BOTTOMRIGHT")

    local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1 }

    local path = {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }

    local fill = {
        type = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), -- Rotate by 30 degrees
        color = {
            { r = 0, g = 0, b = 0, a = .6, position = 0 },
            { r = 0, g = 0, b = 0, a = .4, position = 50 },
            { r = 0, g = 0, b = 0, a = .2, position = 100 }
        }
    }

    canvas:SetShape (path, fill, nil)

end