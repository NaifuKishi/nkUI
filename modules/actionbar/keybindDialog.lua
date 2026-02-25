local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local internalFunc = privateVars.internalFunc

local inspectTEMPORARYRole = Inspect.TEMPORARY.Role

---------- local variables ---------

local keybindDialog = nil
local captureFrame = nil
local capturedKey = nil
local pendingSlot = nil  -- Store {barIndex, buttonIndex} for the slot being edited

---------- local functions ---------

local function createCaptureFrame()
	-- Create an invisible frame that captures key input
	local context = UI.CreateContext("nkUI.keybindCapture")
	context:SetStrata('tooltip')
	context:SetLayer(100)

	local frame = LibEKL.UICreateFrame("nkFrame", "nkUI.keybindCapture", context)
	frame:SetWidth(1)
	frame:SetHeight(1)
	frame:SetBackgroundColor(0, 0, 0, 0)  -- Fully transparent
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetVisible(false)

	return frame
end

local function closeKeybindDialog()
	if keybindDialog then
		keybindDialog:SetVisible(false)
	end

	-- Release key focus from capture frame
	if captureFrame then
		captureFrame:SetKeyFocus(false)
		captureFrame:SetVisible(false)
	end

	capturedKey = nil
	pendingSlot = nil
end

local function saveKeybind()
	if not pendingSlot or not capturedKey then
		closeKeybindDialog()
		return
	end

	local barIndex = pendingSlot.barIndex
	local buttonIndex = pendingSlot.buttonIndex
	local role = inspectTEMPORARYRole()

	-- Save keybind to SavedVars
	if data.actionBarSetup and data.actionBarSetup.roles[role] then
		local slot = data.actionBarSetup.roles[role].bars[barIndex].slots[buttonIndex]
		if slot then
			slot.keyBind = capturedKey
			Command.Console.Display("general", true,
				string.format("<font color='#00FF00'>[nkUI]</font> Keybind set to: <font color='#FFFF00'>%s</font>", capturedKey),
				true)
		end
	end

	-- Repopulate the bar to show the new label
	if uiElements.actionBars then
		for barIdx, bar in ipairs(uiElements.actionBars) do
			if barIdx == barIndex and bar.Populate then
				bar:Populate()
				break
			end
		end
	end

	closeKeybindDialog()
end

local function createKeybindDialog()
	-- Create main dialog window
	local dialog = LibEKL.UICreateFrame("nkWindow", "nkUI.keybindDialog", UIParent)
	dialog:SetWidth(350)
	dialog:SetHeight(180)
	dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	dialog:SetTitle("Set Keybind")
	dialog:SetVisible(false)
	dialog:SetLayer(99)

	-- Instructions text
	local instructionsText = LibEKL.UICreateFrame("nkText", "nkUI.keybindDialog.instructions", dialog)
	instructionsText:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, 30)
	instructionsText:SetWidth(320)
	instructionsText:SetText("Press any key to assign as the keybind for this action.\n\nThe key will be captured and displayed on the icon.")
	instructionsText:SetFontColor(1, 1, 1, 0.8)
	instructionsText:SetFontSize(11)
	LibEKL.UI.SetFont(instructionsText, addonInfo.id, "Montserrat")

	-- Captured key display
	local capturedText = LibEKL.UICreateFrame("nkText", "nkUI.keybindDialog.captured", dialog)
	capturedText:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, 100)
	capturedText:SetWidth(320)
	capturedText:SetText("Waiting for key input...")
	capturedText:SetFontColor(0.5, 1, 0.5, 1)
	capturedText:SetFontSize(12)
	LibEKL.UI.SetFont(capturedText, addonInfo.id, "MontserratBold")

	-- Clear button
	local clearButton = LibEKL.UICreateFrame("nkButton", "nkUI.keybindDialog.clear", dialog)
	clearButton:SetWidth(100)
	clearButton:SetHeight(25)
	clearButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 10, 10)
	clearButton:SetText("Clear")
	clearButton:SetFont(addonInfo.id, "MontserratSemiBold")
	clearButton:SetScale(0.9)
	clearButton:SetLabelColor(data.theme.labelColor)
	clearButton:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
	clearButton:SetBorderColor({ r = 0, g = 0, b = 0, a = .7, thickness = 1})
	clearButton:EventAttach(Event.UI.Input.Mouse.Left.Down, function(self)
		capturedKey = nil
		capturedText:SetText("(cleared)")
		capturedText:SetFontColor(1, 0.5, 0.5, 1)
	end, "nkUI.keybindDialog.clear.click")

	-- Save button
	local saveButton = LibEKL.UICreateFrame("nkButton", "nkUI.keybindDialog.save", dialog)
	saveButton:SetWidth(100)
	saveButton:SetHeight(25)
	saveButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -10, 10)
	saveButton:SetText("Save")
	saveButton:SetFont(addonInfo.id, "MontserratSemiBold")
	saveButton:SetScale(0.9)
	saveButton:SetLabelColor(data.theme.labelColor)
	saveButton:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
	saveButton:SetBorderColor({ r = 0, g = 0, b = 0, a = .7, thickness = 1})
	saveButton:EventAttach(Event.UI.Input.Mouse.Left.Down, function(self)
		saveKeybind()
	end, "nkUI.keybindDialog.save.click")

	-- Cancel button
	local cancelButton = LibEKL.UICreateFrame("nkButton", "nkUI.keybindDialog.cancel", dialog)
	cancelButton:SetWidth(100)
	cancelButton:SetHeight(25)
	cancelButton:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 10)
	cancelButton:SetText("Cancel")
	cancelButton:SetFont(addonInfo.id, "MontserratSemiBold")
	cancelButton:SetScale(0.9)
	cancelButton:SetLabelColor(data.theme.labelColor)
	cancelButton:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
	cancelButton:SetBorderColor({ r = 0, g = 0, b = 0, a = .7, thickness = 1})
	cancelButton:EventAttach(Event.UI.Input.Mouse.Left.Down, function(self)
		closeKeybindDialog()
	end, "nkUI.keybindDialog.cancel.click")

	-- Store reference to captured text for updating
	dialog.capturedText = capturedText

	return dialog
end

local function setupKeyCapture()
	if not captureFrame then
		captureFrame = createCaptureFrame()
	end

	captureFrame:SetVisible(true)
	captureFrame:SetKeyFocus(true)

	-- Attach key handler for capturing
	captureFrame:EventAttach(Event.UI.Input.Key.Down, function(self, key)
		if key and key ~= "" then
			capturedKey = key

			-- Update dialog display
			if keybindDialog and keybindDialog.capturedText then
				keybindDialog.capturedText:SetText("Captured: " .. key)
				keybindDialog.capturedText:SetFontColor(0.5, 1, 0.5, 1)
			end

			-- Auto-save after capture (optional: comment out if you want manual save)
			-- saveKeybind()
		end
	end, "nkUI.keybindCapture.KeyDown")

	-- Also attach on Key.Focus.Loss to know when to stop
	captureFrame:EventAttach(Event.UI.Input.Key.Focus.Loss, function(self)
		-- Focus was lost, stop capturing
	end, "nkUI.keybindCapture.FocusLoss")
end

---------- addon functions ---------

function internalFunc.openKeybindDialog(barIndex, buttonIndex)
	-- Create dialog if needed
	if not keybindDialog then
		keybindDialog = createKeybindDialog()
	end

	-- Store which slot is being edited
	pendingSlot = { barIndex = barIndex, buttonIndex = buttonIndex }
	capturedKey = nil

	-- Reset display
	if keybindDialog.capturedText then
		keybindDialog.capturedText:SetText("Waiting for key input...")
		keybindDialog.capturedText:SetFontColor(0.5, 1, 0.5, 1)
	end

	-- Show dialog
	keybindDialog:SetVisible(true)

	-- Start capturing keys
	setupKeyCapture()
end

