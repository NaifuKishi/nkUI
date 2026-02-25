local addonInfo, privateVars = ...

---------- init namespace ---------

local data        	= privateVars.data
local uiElements  	= privateVars.uiElements
local internalFunc   = privateVars.internalFunc

local inspectSystemSecure		= Inspect.System.Secure
local inspectTEMPORARYRole		= Inspect.TEMPORARY.Role

local context = UI.CreateContext("nkUI.actionbar.keybindEdit")
context:SetStrata('hud')
context:SetLayer(2)

---------- local function block ---------

-- Helper function to create and configure a UI button
local function createButton(parent, name, width, height, x, y, text, iconPath)
    local button = LibEKL.UICreateFrame("nkButton", name, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(text)
    button:SetFont(addonInfo.id, "MontserratSemiBold")
	button:SetEffectGlow ({ strength = 3 })
    button:SetScale(0.7)
	button:SetLabelColor(data.theme.labelColor)
	button:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
    button:SetBorderColor({ r = 0, g = 0, b = 0, a = .7, thickness = 1})
    return button
end

-- Helper function to create and configure a text field
local function createTextField(parent, name, width, height, x, y)
    local textField = LibEKL.UICreateFrame("nkTextField", name, parent)
    textField:SetWidth(width)
    textField:SetHeight(height)
    textField:SetMultiLine(false)
    textField:SetRestoreOnExit(false)
    textField:SetInnerColor({r = 0, g = 0, b = 0, a = 1})
	textField:SetFocusColor (data.theme.labelColor)
	textField:SetBorderColor({r = 0, g = 0, b = 0, a = 1})
    textField:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    return textField
end

---------- addon internalFunc function block ---------

-- Creates and manages the keybind edit dialog for action bars
-- @param editBar The action bar being edited
-- @return The created UI frame for the keybind edit dialog
function internalFunc.keybindDialog (editBar)

	local name = "nkui.ui.keybindDialog"

	-- Variables to store keybind information
	local barIndex, buttonIndex

	-- Create the main dialog window
	local ui = LibEKL.UICreateFrame("nkWindow", name, context)
	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", UIParent:GetWidth() / 2 - 150, 350)
	ui:SetWidth(300)
	ui:SetHeight(150)
	ui:SetTitle("Keybind Label")
    ui:SetTitleFont (addonInfo.id, "MontserratSemiBold")
	ui:SetTitleEffect ({strength = 3})
	ui:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
	ui:SetColor({	type = "gradientLinear",
					transform = Utility.Matrix.Create(12, 12, math.pi / 4, 0, 0),
					color = {
						{r = 0.1294, g = 0.1533, b = 0.2157, a = 1, position = 0},
						{r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1}
					}
				}, data.theme.STROKE_BORDER)

	-- Label for the keybind input
	local keybindLabel = LibEKL.UICreateFrame("nkText", name .. ".keybindLabel", ui:GetContent())
	keybindLabel:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT", 10, 10)
	keybindLabel:SetWidth(100)
	keybindLabel:SetFontColor(1, 1, 1, 1)
	keybindLabel:SetFontSize(12)
    keybindLabel:SetTextFont(addonInfo.id, "Montserrat")
	keybindLabel:SetText("Keybind:")

	-- Text field for keybind label input
    local keybindInput = createTextField(ui:GetContent(), name .. ".keybindInput", ui:GetWidth() - 20, 25, 10, 25)

	-- Clear button for the dialog
    local clearButton = createButton(ui:GetContent(), name .. ".clearButton", 135, 30, 10, ui:GetContent():GetHeight() - 35, "Clear keybind")

	-- Event handler for clear button
	Command.Event.Attach(LibEKL.Events[name .. ".clearButton"].Clicked, function (_, newValue)
		keybindInput:SetText("")
	end, name .. ".clearButton.Clicked")

	-- Cancel button for the dialog
    local cancelButton = createButton(ui:GetContent(), name .. ".cancelButton", 135, 30, clearButton:GetWidth() + 20, ui:GetContent():GetHeight() - 35, "Cancel")

	-- Event handler for cancel button
	Command.Event.Attach(LibEKL.Events[name .. ".cancelButton"].Clicked, function (_, newValue)
		keybindInput:Leave(true)
		ui:SetVisible(false)
	end, name .. ".cancelButton.Clicked")

	-- Save button for the dialog
    local saveButton = createButton(ui:GetContent(), name .. ".saveButton", 135, 30, clearButton:GetWidth() + 20 + cancelButton:GetWidth() + 5, ui:GetContent():GetHeight() - 35, "Save")

	-- Event handler for save button
	Command.Event.Attach(LibEKL.Events[name .. ".saveButton"].Clicked, function (_, newValue)
		if inspectSystemSecure() then return end

		local keybindText = keybindInput:GetText()
		-- Allow clearing the keybind (empty string becomes nil in SavedVar)
		if keybindText == "" then
			keybindText = nil
		end

		data.actionBarSetup.roles[inspectTEMPORARYRole()].bars[barIndex].slots[buttonIndex].keyBind = keybindText
		keybindInput:Leave(true)
		ui:SetVisible(false)
		editBar:Populate()
	end, name .. ".saveButton.Clicked")

	-- Sets the button to edit in the dialog
    -- @param thisBarIndex Index of the bar containing the button
    -- @param thisButtonIndex Index of the button to edit
	function ui:SetButton (thisBarIndex, thisButtonIndex)
		barIndex, buttonIndex = thisBarIndex, thisButtonIndex

		local role = inspectTEMPORARYRole()
        if not data.actionBarSetup.roles[role] then
            data.actionBarSetup.roles[role] = { bars = {} }
        end

 		if not data.actionBarSetup.roles[role].bars[barIndex] then
            data.actionBarSetup.roles[role].bars[barIndex] = { slots = {} }
        end

		local button = data.actionBarSetup.roles[role].bars[barIndex].slots[buttonIndex]
        if not button then
            button = {}
            data.actionBarSetup.roles[role].bars[barIndex].slots[buttonIndex] = button
        end

		-- Load existing keybind label
		local currentKeybind = button.keyBind or ""
		keybindInput:SetText(currentKeybind)

	end

	return ui

end
