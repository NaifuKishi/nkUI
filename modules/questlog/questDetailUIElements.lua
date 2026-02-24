local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local langTexts		= privateVars.langTexts

local DEFAULT_PADDING = 10
local DEFAULT_HEADER_FONTSIZE = 14
local DEFAULT_HEADER_COLOR = { r = .91, g = .71, b = .19}

function questLog.uiBox (name, parent)

    local ui = LibEKL.UICreateFrame("nkCanvas", name, parent)
	    
    -- Create a square path
    local path = {
        {xProportional = 0, yProportional = 0},
        {xProportional = 1, yProportional = 0},
        {xProportional = 1, yProportional = 1},
        {xProportional = 0, yProportional = 1},
        {xProportional = 0, yProportional = 0}
    }

    -- Set stroke color
    local stroke = data.theme.STROKE_BORDER

    ui:SetShape(path, nil, stroke)
    ui:SetWidth(parent:GetWidth()-40)

	local title = LibEKL.UICreateFrame("nkText", name .. ".header", ui)

	title:SetPoint("TOPLEFT", ui, "TOPLEFT", DEFAULT_PADDING, DEFAULT_PADDING)
	title:SetFontSize(DEFAULT_HEADER_FONTSIZE)
	title:SetFontColor(DEFAULT_HEADER_COLOR.r, DEFAULT_HEADER_COLOR.g, DEFAULT_HEADER_COLOR.b, 1)
	title:SetEffectGlow({ strength = 3 })

    LibEKL.UI.SetFont(title, addonInfo.id, "MontserratSemiBold")

    function ui:SetTitle(newTitle)
        title:SetText(newTitle)
    end

    function ui:GetTitle()
        return title
    end

    return ui


end

