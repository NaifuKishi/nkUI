local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local internalFunc = privateVars.internalFunc

local inspectTEMPORARYRole = Inspect.TEMPORARY.Role

---------- local variables ---------

local keybindDialog = nil
local captureFrame = nil
local dialogContext = nil
local captureContext = nil
local capturedKey = nil
local pendingSlot = nil  -- Store {barIndex, buttonIndex} for the slot being edited
local mathFloor = math.floor

---------- local functions ---------

local function createCaptureFrame()
	-- Create an invisible frame that captures key input
	if not captureContext then
		captureContext = UI.CreateContext("nkUI.keybindCapture")
		captureContext:SetStrata('tooltip')
		captureContext:SetLayer(100)
	end

	local frame = LibEKL.UICreateFrame("nkFrame", "nkUI.keybindCapture", captureContext)
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
		local roleSetup = data.actionBarSetup.roles[role]

		-- First, remove this keybind from any other slots that have it
		for barIdx = 1, #roleSetup.bars do
			local bar = roleSetup.bars[barIdx]
			if bar and bar.slots then
				for slotIdx = 1, #bar.slots do
					local otherSlot = bar.slots[slotIdx]
					if otherSlot and otherSlot.keyBind == capturedKey then
						-- Don't clear if it's the same slot we're setting
						if not (barIdx == barIndex and slotIdx == buttonIndex) then
							otherSlot.keyBind = nil
						end
					end
				end
			end
		end

		-- Now set the keybind on the target slot
		local slot = roleSetup.bars[barIndex].slots[buttonIndex]
		if slot then
			slot.keyBind = capturedKey
			Command.Console.Display("general", true,
				string.format("<font color='#00FF00'>[nkUI]</font> Keybind set to: <font color='#FFFF00'>%s</font>", capturedKey),
				true)
		end
	end

	-- Update all affected icons: the newly set one and any that had the keybind removed
	if uiElements.actionBars then
		for barIdx, bar in ipairs(uiElements.actionBars) do
			if bar.Populate then
				bar:Populate()
			end
		end
	end

	closeKeybindDialog()
end

local function createKeybindDialog(iconFrame)
	-- Create context for dialog if needed
	if not dialogContext then
		dialogContext = UI.CreateContext("nkUI.keybindDialog")
		dialogContext:SetStrata('hud')
		dialogContext:SetLayer(99)
	end

	-- Create main dialog window
	local dialog = LibEKL.UICreateFrame("nkWindow", "nkUI.keybindDialog", dialogContext)
	dialog:SetWidth(450)
	dialog:SetHeight(180)
	dialog:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, 100)
	dialog:SetTitle("Set Keybind")
	dialog:SetTitleFont(addonInfo.id, "MontserratSemiBold")
	dialog:SetTitleEffect({ strength = 3 })
	dialog:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
	dialog:SetColor({
		type = "gradientLinear",
		transform = Utility.Matrix.Create(12, 12, math.pi / 4, 0, 0),
		color = {
			{ r = 0.1294, g = 0.1533, b = 0.2157, a = 1, position = 0 },
			{ r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1 }
		}
	}, data.theme.STROKE_BORDER)
	dialog:SetVisible(false)

	-- Instructions text
	local instructionsText = LibEKL.UICreateFrame("nkText", "nkUI.keybindDialog.instructions", dialog)
	instructionsText:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, 30)
	instructionsText:SetWidth(420)
	instructionsText:SetText("Press any key to assign as the keybind for this action.\n\nThe key will be captured and displayed on the icon.")
	instructionsText:SetFontColor(1, 1, 1, 0.8)
	instructionsText:SetFontSize(11)
	LibEKL.UI.SetFont(instructionsText, addonInfo.id, "Montserrat")

	-- Captured key display
	local capturedText = LibEKL.UICreateFrame("nkText", "nkUI.keybindDialog.captured", dialog)
	capturedText:SetPoint("TOPLEFT", dialog, "TOPLEFT", 15, 100)
	capturedText:SetWidth(420)
	capturedText:SetText("Waiting for key input...")
	capturedText:SetFontColor(0.5, 1, 0.5, 1)
	capturedText:SetFontSize(12)
	LibEKL.UI.SetFont(capturedText, addonInfo.id, "MontserratBold")

	-- Clear button
	local clearButton = LibEKL.UICreateFrame("nkButton", "nkUI.keybindDialog.clear", dialog)
	clearButton:SetWidth(100)
	clearButton:SetHeight(25)
	clearButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 20, -10)
	clearButton:SetText("Clear key")
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

	-- Clear Slot button
	local clearSlotButton = LibEKL.UICreateFrame("nkButton", "nkUI.keybindDialog.clearSlot", dialog)
	clearSlotButton:SetWidth(100)
	clearSlotButton:SetHeight(25)
	clearSlotButton:SetPoint("CENTERLEFT", clearButton, "CENTERRIGHT", 20, 0)
	clearSlotButton:SetText("Clear Slot")
	clearSlotButton:SetFont(addonInfo.id, "MontserratSemiBold")
	clearSlotButton:SetScale(0.9)
	clearSlotButton:SetLabelColor(data.theme.labelColor)
	clearSlotButton:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
	clearSlotButton:SetBorderColor({ r = 0, g = 0, b = 0, a = .7, thickness = 1})
	clearSlotButton:EventAttach(Event.UI.Input.Mouse.Left.Down, function(self)	
		iconFrame:ClearItem()
		closeKeybindDialog()
	end, "nkUI.keybindDialog.clearSlot.click")

	-- Save button
	local saveButton = LibEKL.UICreateFrame("nkButton", "nkUI.keybindDialog.save", dialog)
	saveButton:SetWidth(100)
	saveButton:SetHeight(25)
	saveButton:SetPoint("CENTERLEFT", clearSlotButton, "CENTERRIGHT", 20, 0)
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
	cancelButton:SetPoint("CENTERLEFT", saveButton, "CENTERRIGHT", 20, 0)
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
	captureFrame:EventAttach(Event.UI.Input.Key.Down, function(self, _, key)
		if key then
			local keyStr = tostring(key)
			if keyStr ~= "" then
				capturedKey = keyStr

				-- Update dialog display
				if keybindDialog and keybindDialog.capturedText then
					keybindDialog.capturedText:SetText("Captured: " .. keyStr)
					keybindDialog.capturedText:SetFontColor(0.5, 1, 0.5, 1)
				end

				-- Auto-save after capture (optional: comment out if you want manual save)
				-- saveKeybind()
			end
		end
	end, "nkUI.keybindCapture.KeyDown")

	-- Also attach on Key.Focus.Loss to know when to stop
	captureFrame:EventAttach(Event.UI.Input.Key.Focus.Loss, function(self)
		-- Focus was lost, stop capturing
	end, "nkUI.keybindCapture.FocusLoss")
end

---------- addon functions ---------

function internalFunc.openKeybindDialog(barIndex, buttonIndex, iconFrame)
	-- Create dialog if needed
	if not keybindDialog then
		keybindDialog = createKeybindDialog(iconFrame)
	end

	-- Store which slot is being edited
	pendingSlot = { barIndex = barIndex, buttonIndex = buttonIndex }
	capturedKey = nil

	-- Position dialog: TOPLEFT positioned so dialog's bottom-right is near icon's top-left
	if iconFrame then
		local iconLeft = iconFrame:GetLeft()
		local iconTop = iconFrame:GetTop()

		if iconLeft and iconTop then
			local dialogWidth = keybindDialog:GetWidth()
			local dialogHeight = keybindDialog:GetHeight()

			-- Calculate TOPLEFT position so dialog's BOTTOMRIGHT ends up at icon's TOPLEFT with -50, -50 offset
			-- TOPLEFT = icon's TOPLEFT - (dialogWidth + offset_x, dialogHeight + offset_y)
			local dialogLeft = iconLeft - dialogWidth - 50
			local dialogTop = iconTop - dialogHeight - 50

			keybindDialog:SetPoint("TOPLEFT", UIParent, "TOPLEFT", dialogLeft, dialogTop)
		end
	end

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

