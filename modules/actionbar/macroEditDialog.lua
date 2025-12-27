local addonInfo, privateVars = ...

---------- init namespace ---------

local data        	= privateVars.data
local uiElements  	= privateVars.uiElements
local internalFunc   = privateVars.internalFunc

local inspectSystemSecure		= Inspect.System.Secure
local inspectCursor				= Inspect.Cursor
local inspectItemDetail			= Inspect.Item.Detail
local inspectAbilityNewDetail	= Inspect.Ability.New.Detail
local inspectTEMPORARYRole		= Inspect.TEMPORARY.Role

-- Helper function to create and configure a UI button
local function createButton(parent, name, width, height, x, y, text, iconPath)
    local button = LibEKL.uiCreateFrame("nkButtonMetro", name, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(text)
    button:SetIcon("LibEKL", iconPath)
    button:SetFont(addonInfo.id, "Montserrat")
    button:SetScale(0.7)
    return button
end

-- Helper function to create and configure a text field
local function createTextField(parent, name, width, height, x, y)
    local textField = LibEKL.uiCreateFrame("nkTextField", name, parent)
    textField:SetWidth(width)
    textField:SetHeight(height)
    textField:SetMultiLine(true)
    textField:SetRestoreOnExit(false)
    textField:SetInnerColor({r = 0, g = 0, b = 0, a = 1})
    textField:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    return textField
end

-- Creates and manages the macro edit dialog for action bars
-- @param editBar The action bar being edited
-- @return The created UI frame for the macro edit dialog
function internalFunc.macroEditDialog (editBar)

	local name = "nkui.ui.macroEditDialog"
	
	-- Variables to store macro information
	local barIndex, buttonIndex, contentType, contentKey, icon
	
	-- Create the main dialog window
	local ui = LibEKL.uiCreateFrame("nkWindowElement", name, uiElements.contextDialog)
	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", UIParent:GetWidth() / 2 - 150, 300)
	ui:SetWidth(320)
	ui:SetHeight(230)
	ui:SetTitle("Macro edit")
    ui:SetTitleFont (addonInfo.id, "Montserrat")
	
	-- Create icon edit button for macro icon selection
	local iconEdit = LibEKL.uiCreateFrame("nkActionButtonMetro", name .. ".iconEdit", ui:GetContent())
	iconEdit:SetWidth(48)
	iconEdit:SetHeight(48)
	iconEdit:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT", 85, 10)
	
	-- Event handler for icon selection
	iconEdit:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self)
		if inspectSystemSecure() == true then return end
		local cType, cHeld = inspectCursor()
		
		contentType, contentKey = cType, cHeld
		
		if cType == 'item' then
			local details = inspectItemDetail(cHeld)
			if details ~= nil then iconEdit:SetTexture("Rift", details.icon) end
			icon = details.icon
		elseif cType == 'ability' then			
			local details = inspectAbilityNewDetail(cHeld)
			if details ~= nil then iconEdit:SetTexture("Rift", details.icon) end
			icon = details.icon
		end
	end, iconEdit:GetName() .. ".UI.Input.Mouse.Left.Up")
	
	-- Label for the icon edit section
	local iconEditLabel = LibEKL.uiCreateFrame("nkText", name .. ".iconEditLabel", ui:GetContent())
	iconEditLabel:SetPoint("CENTERRIGHT", iconEdit, "CENTERLEFT")
	iconEditLabel:SetWidth(75)
	iconEditLabel:SetFontColor(1, 1, 1, 1)
	iconEditLabel:SetFontSize(12)
    iconEditLabel:SetTextFont(addonInfo.id, "Montserrat")
	iconEditLabel:SetText("Macro icon")

	-- Text field for macro editing
    local macroEdit = createTextField(ui:GetContent(), name .. ".macroEdit", ui:GetWidth() - 20, 100, 10, 68)
	
	-- Cancel button for the dialog
    local cancelButton = createButton(ui:GetContent(), name .. ".cancelButton", 150, 30, 10, ui:GetHeight() - 40, "Cancel macro", "gfx/icons/close.png")
	
	-- Event handler for cancel button
	Command.Event.Attach(LibEKL.events[name .. ".cancelButton"].Clicked, function (_, newValue)
		macroEdit:Leave(true)
		ui:SetVisible(false)
	end, name .. ".cancelButton.Clicked")
	
	-- Save button for the dialog
    local saveButton = createButton(ui:GetContent(), name .. ".saveButton", 150, 30, cancelButton:GetWidth() + 20, ui:GetHeight() - 40, "Save macro", "gfx/icons/ok.png")
	
	-- Event handler for save button
	Command.Event.Attach(LibEKL.events[name .. ".saveButton"].Clicked, function (_, newValue)		
		if inspectSystemSecure() then return end

		data.actionBarSetup.roles[inspectTEMPORARYRole()].bars[barIndex].slots[buttonIndex] =  { itemType = "macro", itemKey = macroEdit:GetText(), macroIcon = icon, macroCD = {contentType, contentKey} }
		macroEdit:Leave(true)
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
		
		if button.itemType ~= 'macro' then			
			local details
			
			if button.itemType == 'ability' then
				details = inspectAbilityNewDetail(button.itemKey)
			elseif button.itemKey ~= nil then
				details = inspectItemDetail(button.itemKey)
			end
			
			if details then
				button.macroIcon = details.icon
				button.macroCD = {  button.itemType, button.itemKey }
				
				if button.itemType == 'ability' then
					button.itemKey = 'cast ' .. details.name
				else
					button.itemKey = 'use ' .. details.name
				end
			end
			
			 button.itemType = 'macro'
			
		end
		
		icon = button.macroIcon
		
		if not button.macroIcon then
			iconEdit:ClearTexture()
		else	
			iconEdit:SetTexture("Rift", button.macroIcon)
		end
		
		macroEdit:SetText(button.itemKey or "")
		
		if button.macroCD then	
			contentType, contentKey = button.macroCD[1], button.macroCD[2]
		end
		
	end
	
	return ui

end