local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc	= privateVars.internalFunc
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local questLog		= privateVars.questLog

local name = "nkUI.questlog"

questLog.context = UI.CreateContext("nkUI.QuestLog")
questLog.context:SetStrata('hud')
questLog.context:SetLayer(2)

function questLog.buildUI()

	local ui = LibEKL.UICreateFrame("nkWindow", name, questLog.context)
	
	ui:SetLayer(1)
    ui:SetWidth(950)
    ui:SetHeight(650)
    ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (LibEKL.UI.getBoundRight() / 2) - (ui:GetWidth()/2), 200)
    ui:SetTitle(addonInfo.toc.Identifier .. " version ".. addonInfo.toc.Version)
    ui:SetTitleFont(addonInfo.id, "MontserratBold")
    ui:SetTitleFontSize(16)
    ui:SetTitleEffect ( {strength = 3})
    ui:SetCloseable(true)
    ui:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

    ui:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, -(math.pi / 6), 0, 0), -- Negative angle for opposite direction
        color = {
            data.theme.windowStartColor,
            data.theme.windowEndColor
            }
    },  { r = 0, g = 0, b = 0, a = 1, thickness = 1})

	-- Create left panel for quest list
    local leftPanel = LibEKL.UICreateFrame("nkFrame", name .. ".leftPanel", ui)
    leftPanel:SetWidth(300)
    leftPanel:SetHeight(ui:GetHeight() - 40)
    leftPanel:SetPoint("TOPLEFT", ui, "TOPLEFT", 10, 30)
    leftPanel:SetBackgroundColor(0.1, 0.1, 0.1, 0.8)

	-- Create scroll pane for quest list
    local scrollPane = LibEKL.UICreateFrame("nkScrollPane", name .. ".scrollPane", leftPanel)
    scrollPane:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 5, 5)
    scrollPane:SetWidth(leftPanel:GetWidth() - 10)
    scrollPane:SetHeight(leftPanel:GetHeight() - 10)
    scrollPane:SetColor({r = 0.153, g = 0.314, b = 0.490, a = 0})
    scrollPane:SetColorInner({r = 0, g = 0, b = 0, a = 0})
    scrollPane:SetColorHighlight({r = 0.153, g = 0.314, b = 0.490, a = 0})

    -- Create content frame for quest list
    local content = UI.CreateFrame("Frame", name .. ".content", scrollPane)
    content:SetWidth(leftPanel:GetWidth() - 20)

    -- Create right panel for quest details
    local rightPanel = LibEKL.UICreateFrame("nkFrame", name .. ".rightPanel", ui)
    rightPanel:SetWidth(ui:GetWidth() - leftPanel:GetWidth() - 30)
    rightPanel:SetHeight(ui:GetHeight() - 40)
    rightPanel:SetPoint("TOPRIGHT", ui, "TOPRIGHT", -10, 30)
    rightPanel:SetBackgroundColor(0.1, 0.1, 0.1, 0.8)

    -- Store UI elements
    uiElements.questLogLeftPanel = leftPanel
    uiElements.questLogScrollPane = scrollPane
    uiElements.questLogContent = content
    uiElements.questLogRightPanel = rightPanel


	return ui

end