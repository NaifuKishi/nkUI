local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local langTexts		= privateVars.langTexts

function questLog.questDetailTag (name, parent)

    local ui = LibEKL.UICreateFrame("nkCanvas", name, parent)

    local path = {
        -- Top-left corner
        {xProportional = 0.2, yProportional = 0},
        {xProportional = 0, yProportional = 0.5,
         xControlProportional = 0, yControlProportional = 0},

        -- Bottom-left corner
        {xProportional = 0.2, yProportional = 1,
         xControlProportional = 0, yControlProportional = 1},

        -- Bottom edge
        {xProportional = 0.8, yProportional = 1},

        -- Bottom-right corner
        {xProportional = 1, yProportional = 0.5,
         xControlProportional = 1, yControlProportional = 1},

        -- Top-right corner
        {xProportional = 0.8, yProportional = 0,
         xControlProportional = 1, yControlProportional = 0},

        -- Top edge
        {xProportional = 0.2, yProportional = 0}
    }

    -- Set fill color as solid
    local fill = {
        type = "solid",
        r = 0x28 / 255,
        g = 0x2f / 255,
        b = 0x3b / 255,
        a = 1
    }

    -- Set stroke color
    local stroke = {
        r = 0x66 / 255,
        g = 0x56 / 255,
        b = 0x2e / 255,
        a = 1,
        cap = "round",
        miter = "miter",
        thickness = 2
    }

    -- Set the shape of the UI element with fill and stroke
    --ui:SetShape(path, fill, stroke)
    --ui:SetHeight(30)

    local text = LibEKL.UICreateFrame("nkText", name .. ".label", ui)
    text:SetPoint("CENTER", ui, "CENTER")
    text:SetFontSize(12)
    --text:SetEffectGlow({strength = 3})
    LibEKL.UI.SetFont(text, addonInfo.id, "Montserrat")

    function ui:SetText(newText)
        text:ClearWidth()
        text:SetText(newText)

        ui:SetWidth(text:GetWidth() + 20)
        ui:SetHeight(20)
        ui:SetShape(path, fill, stroke)
    end

    return ui


end