local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

---------- init global variables ---------

function _internal.macroEditDialog (editBar)

	local name = "nkHelios.ui.macroEditDialog"
	
	local barIndex, buttonIndex, contentType, contentKey, icon
	
	local ui = EnKai.uiCreateFrame("nkWindowElement", name, uiElements.contextDialog)
	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", UIParent:GetWidth() / 2 - 150, 300)
	ui:SetWidth(320)
	ui:SetHeight(230)
	ui:SetTitle("Macro edit")
    ui:SetTitleFont (addonInfo.id, "Montserrat")
	
	local iconEdit = EnKai.uiCreateFrame("nkActionButtonMetro", name .. ".iconEdit", ui:GetContent())
	iconEdit:SetWidth(48)
	iconEdit:SetHeight(48)
	iconEdit:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT", 85, 10)
	
	iconEdit:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self)
		if Inspect.System.Secure() == true then return end
		local cType, cHeld = Inspect.Cursor()
		
		contentType, contentKey = cType, cHeld
		
		if cType == 'item' then
			local details = Inspect.Item.Detail(cHeld)
			if details ~= nil then iconEdit:SetTexture("Rift", details.icon) end
			icon = details.icon
		elseif cType == 'ability' then			
			local details = Inspect.Ability.New.Detail(cHeld)
			if details ~= nil then iconEdit:SetTexture("Rift", details.icon) end
			icon = details.icon
		end
	end, iconEdit:GetName() .. ".UI.Input.Mouse.Left.Up")
	
	local iconEditLabel = EnKai.uiCreateFrame("nkText", name .. ".iconEditLabel", ui:GetContent())
	iconEditLabel:SetPoint("CENTERRIGHT", iconEdit, "CENTERLEFT")
	iconEditLabel:SetWidth(75)
	iconEditLabel:SetFontColor(1, 1, 1, 1)
	iconEditLabel:SetFontSize(12)
    iconEditLabel:SetTextFont(addonInfo.id, "Montserrat")
	iconEditLabel:SetText("Macro icon")

	local macroEdit = EnKai.uiCreateFrame("nkTextField", name .. ".macroEdit", ui:GetContent())
	macroEdit:SetWidth(ui:GetWidth()-20)
	macroEdit:SetHeight(100)
	macroEdit:SetMultiLine(true)
	macroEdit:SetRestoreOnExit(false)
    macroEdit:SetInnerColor({r = 0, g = 0, b = 0, a = 1})
	macroEdit:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT", 10, 68)
	
	local cancelButton = EnKai.uiCreateFrame("nkButtonMetro", name .. ".cancelButton", ui:GetContent())
	cancelButton:SetPoint("BOTTOMRIGHT", ui:GetContent(), "BOTTOMRIGHT", -10, -10)
	cancelButton:SetText("Cancel macro")
	cancelButton:SetIcon("EnKai", "gfx/icons/close.png")
    cancelButton:SetFont(addonInfo.id, "Montserrat")
	cancelButton:SetWidth(150)
	cancelButton:SetScale(.7)
	
	Command.Event.Attach(EnKai.events[name .. ".cancelButton"].Clicked, function (_, newValue)
		macroEdit:Leave(true)
		ui:SetVisible(false)
	end, name .. ".cancelButton.Clicked")
	
	local saveButton = EnKai.uiCreateFrame("nkButtonMetro", name .. ".saveButton", ui:GetContent())
	saveButton:SetPoint("CENTERRIGHT", cancelButton, "CENTERLEFT", -10, 0)
	saveButton:SetText("Save macro")
	saveButton:SetIcon("EnKai", "gfx/icons/ok.png")
    saveButton:SetFont(addonInfo.id, "Montserrat")
	saveButton:SetWidth(150)
	saveButton:SetScale(.7)
	
	Command.Event.Attach(EnKai.events[name .. ".saveButton"].Clicked, function (_, newValue)		
		data.actionBarSetup.roles[Inspect.TEMPORARY.Role()].bars[barIndex].slots[buttonIndex] =  { itemType = "macro", itemKey = macroEdit:GetText(), macroIcon = icon, macroCD = {contentType, contentKey} }
		macroEdit:Leave(true)
		ui:SetVisible(false)
		editBar:Populate()
	end, name .. ".saveButton.Clicked")
	
	function ui:SetButton (thisBarIndex, thisButtonIndex)
		barIndex, buttonIndex = thisBarIndex, thisButtonIndex
		
		local button = data.actionBarSetup.roles[Inspect.TEMPORARY.Role()].bars[barIndex].slots[buttonIndex]
		if button == nil then
			table.insert(data.actionBarSetup.roles[Inspect.TEMPORARY.Role()].bars[barIndex].slots, {})
			button = {}
		end
		
		if button.itemType ~= 'macro' then
			
			local details
			
			if button.itemType == 'ability' then
				details = Inspect.Ability.New.Detail(button.itemKey)
			elseif button.itemKey ~= nil then
				details = Inspect.Item.Detail(button.itemKey)
			end
			
			if details ~= nil then
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
		
		if button.macroIcon == nil then
			iconEdit:ClearTexture()
		else	
			iconEdit:SetTexture("Rift", button.macroIcon)
		end
		
		if button.itemKey == nil then
			macroEdit:SetText("")
		else
			macroEdit:SetText(button.itemKey)
		end
		
		if button.macroCD ~= nil then		
			contentType, contentKey = button.macroCD[1], button.macroCD[2]
		end
		
	end
	
	return ui

end
