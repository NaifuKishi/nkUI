local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal

local oSGSub      = string.gsub
local _mainColor      = {r = 0.153, g = 0.314, b = 0.490, a = 1}

local oInspectTimeFrame = Inspect.Time.Frame

---------- init local variables ---------

---------- init variables ---------

---------- local function block ---------

local function _macroEditDialog ()

	local name = "nkHelios.ui.macroEditDialog"
	
	local barIndex, buttonIndex, contentType, contentKey, icon
	
	local ui = EnKai.uiCreateFrame("nkWindowElement", name, uiElements.contextTop)
	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", UIParent:GetWidth() / 2 - 150, 300)
	ui:SetWidth(320)
	ui:SetHeight(230)
	ui:SetTitle(privateVars.langTexts.macroEditTitle)
	
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
	iconEditLabel:SetText(privateVars.langTexts.macroIconLabel)

	local macroEdit = EnKai.uiCreateFrame("nkTextField", name .. ".macroEdit", ui:GetContent())
	macroEdit:SetWidth(ui:GetWidth()-20)
	macroEdit:SetHeight(100)
	macroEdit:SetMultiLine(true)
	macroEdit:SetRestoreOnExit(false)
	macroEdit:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT", 10, 68)
	
	local cancelButton = EnKai.uiCreateFrame("nkButtonMetro", name .. ".cancelButton", ui:GetContent())
	cancelButton:SetPoint("BOTTOMRIGHT", ui:GetContent(), "BOTTOMRIGHT", -10, -10)
	cancelButton:SetText(privateVars.langTexts.btCancelMacro)
	cancelButton:SetIcon("EnKai", "gfx/icons/close.png")
	cancelButton:SetFontColor(1, 1, 1)
	cancelButton:SetColor(_mainColor.r, _mainColor.g, _mainColor.b)
	cancelButton:SetWidth(135)
	cancelButton:SetScale(.7)
	
	Command.Event.Attach(EnKai.events[name .. ".cancelButton"].Clicked, function (_, newValue)
		ui:SetVisible(false)
	end, name .. ".cancelButton.Clicked")
	
	local saveButton = EnKai.uiCreateFrame("nkButtonMetro", name .. ".saveButton", ui:GetContent())
	saveButton:SetPoint("CENTERRIGHT", cancelButton, "CENTERLEFT", -10, 0)
	saveButton:SetText(privateVars.langTexts.btSaveMacro)
	saveButton:SetIcon("EnKai", "gfx/icons/ok.png")
	saveButton:SetFontColor(1, 1, 1)
	saveButton:SetColor(_mainColor.r, _mainColor.g, _mainColor.b)
	saveButton:SetWidth(135)
	saveButton:SetScale(.7)
	
	Command.Event.Attach(EnKai.events[name .. ".saveButton"].Clicked, function (_, newValue)		
		data.setup.roles[Inspect.TEMPORARY.Role()].bars[barIndex].slots[buttonIndex] =  { itemType = "macro", itemKey = macroEdit:GetText(), macroIcon = icon, macroCD = {contentType, contentKey} }
		ui:SetVisible(false)
		uiElements.bars[barIndex]:ReDraw()
	end, name .. ".saveButton.Clicked")
	
	function ui:SetButton (thisBarIndex, thisButtonIndex)
		barIndex, buttonIndex = thisBarIndex, thisButtonIndex
		
		local button = data.setup.roles[Inspect.TEMPORARY.Role()].bars[barIndex].slots[buttonIndex]
		if button == nil then
			table.insert(data.setup.roles[Inspect.TEMPORARY.Role()].bars[barIndex].slots, {})
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

local function _fctButton (name, parent, barIndex, buttonIndex)

	local frame = EnKai.uiCreateFrame("nkCanvas", name, parent)
	
	local outter, texture, oorTint, cooldownTint, cooldown, macroFrame, overlay
	local thisItemKey, thisItemType, thisMacroIcon, thisMacroCDType, thisMacroCDKey
	local interactive = false
	local cooldownActive = false
	local oor, usable = false, true
	
	local path = {{xProportional = 0.5, yProportional = 0}, 
                  {xProportional = 1, yProportional = 0.5, xControlProportional = (61/64), yControlProportional = (3/64)},
                  {xProportional = 0.5, yProportional = 1, xControlProportional = (61/64), yControlProportional = (61/64)},
                  {xProportional = 0, yProportional = 0.5, xControlProportional = (3/64), yControlProportional = (61/64)},
                  {xProportional = 0.5, yProportional = 0, xControlProportional = (3/64), yControlProportional = (3/64)}}
	local fill = {type = 'solid', r = 0.078, g = 0.188, b = 0.306, a = 1}
	local thisScale = 1
	
	frame:SetShape(path, fill, {r = 0, g = 0, b = 0, a = 1, thickness = 1 })

	texture = EnKai.uiCreateFrame("nkTexture", name .. '.texture', frame)  
	--texture:SetPoint("CENTER", frame, "CENTER")
	texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, 1)
	texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, -1)
	texture:SetLayer(1)
	texture:SetMouseMasking("limited")
	
	overlay = EnKai.uiCreateFrame("nkCanvas", name .. ".overlay", frame)
	overlay:SetPoint("TOPLEFT", frame, "TOPLEFT")
	overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
	overlay:SetShape(path, nil, {r = 0, g = 0, b = 0, a = 1, thickness = 5 })
	overlay:SetLayer(2)
	
	outter = EnKai.uiCreateFrame("nkTexture", name .. ".outter", frame)
	outter:SetLayer(3)

	oorTint = EnKai.uiCreateFrame("nkCanvas", name .. ".oorTint", frame)
	oorTint:SetVisible(false)
	oorTint:SetPoint("TOPLEFT", overlay, "TOPLEFT")
	oorTint:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT")
	oorTint:SetLayer(4)
	
	cooldownTint = EnKai.uiCreateFrame("nkCanvas", name .. ".cooldownTint", frame)
	cooldownTint:SetVisible(false)
	cooldownTint:SetPoint("TOPLEFT", overlay, "TOPLEFT")
	cooldownTint:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT")
	cooldownTint:SetLayer(5)
	
	cooldown = EnKai.uiCreateFrame("nkText", name .. '.cooldown', frame)
	cooldown:SetVisible(false)
	cooldown:SetPoint("CENTER", frame, "CENTER")
	cooldown:SetFontColor (1, 1, 1, 1)
	cooldown:SetEffectGlow({ colorB = 0, colorA = 1, colorG = 0, colorR = 0, strength = 3, blurX = 3, blurY = 3 })
	cooldown:SetLayer(6)
	
	function frame:ShowCooldown(flag) cooldown:SetVisible(flag) end
	
	function frame:Flicker()
		-- könnte man verbessern
		cooldownTint:SetShape(path, {type = 'solid', r = 1, g = 1, b = 1, a = .4}, nil)
		cooldownTint:SetVisible(true)		
	end

	function frame:SetGCD (duration)

		if duration == nil or cooldownActive == true then return end

		local start = oInspectTimeFrame()

		local gcdCoRoutine = coroutine.create(function ()
			for idx = 1, 100, 1 do		
				local remaining = duration - (oInspectTimeFrame() - start)
				if oInspectTimeFrame() - start > duration then return 9999 end
				cooldown:SetText(tostring(math.floor(remaining * 10) / 10))
				coroutine.yield(idx)
			end
		end)

		cooldownActive = true		
		cooldown:SetVisible(true)
		cooldownTint:SetVisible(true)
		cooldown:SetText(tostring(math.floor(duration * 10) / 10))

		EnKai.coroutines.add ({ func = gcdCoRoutine, counter = 100, active = true })
	end	

	function frame:SetCooldown(timer, percent)
	
		if timer == nil then
			cooldown:SetVisible(false)
			cooldownTint:SetVisible(false)
			cooldownTint:SetShape(path, {type = 'solid', r = 1, g = 1, b = 1, a = .4}, nil)
			cooldownActive = false
		else
			if cooldownActive == false then
				cooldownActive = true		
				cooldown:SetVisible(true)
				cooldownTint:SetVisible(true)
			end
			
			cooldown:SetText(timer)
			--cooldownTint:SetHeight( overlay:GetHeight())
			--cooldownTint:SetWidth( overlay:GetWidth())
			
		end		
	end
	
	function frame:SetOOR (flag)
	
		oor = flag
	
		if flag == true then
			oorTint:SetVisible(true)
			oorTint:SetShape(path, {type = 'solid', r = 1, g = 0, b = 0, a = .6}, nil)
		else
			if usable then
				oorTint:SetVisible(false)
			else
				frame:SetUsable(false)
			end
		end
	end
	
	function frame:SetUsable (flag)
	
		usable = flag
	
		if flag == true then
			if oor then
				frame:SetOOR(true)
			else
				oorTint:SetVisible(false)
			end
		else
			oorTint:SetVisible(true)
			oorTint:SetShape(path, {type = 'solid', r = 0, g = 0, b = 0, a = .8}, nil)
		end
	end
	
	local function _checkDrop ()
	
		if Inspect.System.Secure() == true then return end
		local cType, cHeld = Inspect.Cursor()
		
		if cType == 'item' or cType == 'ability' then			
		
			frame:SetItem(cType, cHeld, nil)
			data.setup.roles[Inspect.TEMPORARY.Role()].bars[barIndex].slots[buttonIndex] = { itemType = cType, itemKey = cHeld, macroIcon = nil }
		end
		
		Command.Cursor(nil)
	
	end
	
	function frame:ClearItem()
		
		EnKai.ui.attachItemTooltip (texture, nil)
		EnKai.ui.attachAbilityTooltip (texture, nil)
		EnKai.ui.attachGenericTooltip (texture, nil)
		
		if macroFrame ~= nil then
			EnKai.ui.attachItemTooltip (macroFrame, nil)
			EnKai.ui.attachAbilityTooltip (macroFrame)
			EnKai.ui.attachGenericTooltip (macroFrame, nil)
			
			macroFrame:SetVisible(false)
		end
		
		if thisMacroCDType ~= nil then
			EnKai.cdManager.unsubscribe(thisMacroCDType, thisMacroCDKey)
		elseif thisItemKey ~= nil and thisItemKey ~= 'macro' then
			EnKai.cdManager.unsubscribe(thisItemType, thisItemKey)
		end	
		
		thisItemKey = nil
		thisItemType = nil
		thisMacroIcon = nil
		thisMacroCDType = nil
		thisMacroCDKey = nil
		
		texture:SetTextureAsync("nkHelios", "gfx/equipslot_blank.png")  
		
	end
	
	function frame:SetItem(itemType, itemKey, macroIcon, macroCDType, macroCDKey)

		if thisItemType ~= nil then frame:ClearItem() end

		if itemType == nil or itemKey == nil then return end
				
		thisItemKey = itemKey
		thisItemType = itemType
		thisMacroIcon = macroIcon
		thisMacroCDType = macroCDType
		thisMacroCDKey = macroCDKey
		
		if macroCDType ~= nil then
			EnKai.cdManager.subscribe(macroCDType, macroCDKey)

			if data.abilityMap[macroCDKey] == nil then data.abilityMap[macroCDKey] = {} end
			table.insert(data.abilityMap[macroCDKey], frame)
			table.insert(data.abilityList, macroCDKey)
		else
			EnKai.cdManager.subscribe(thisItemType, thisItemKey)
			if data.abilityMap[itemKey] == nil then data.abilityMap[itemKey] = {} end
			table.insert(data.abilityMap[itemKey], frame)
			table.insert(data.abilityList, itemKey)
		end
		
		local err, data, macro
		
		if thisItemType == 'item' then
			err, data = pcall(Inspect.Item.Detail, itemKey)
			if err and data ~= nil then
				macro = "use " .. oSGSub(data.name, "\n", "")
			end
		elseif thisItemType == "ability" then
			err, data = pcall(Inspect.Ability.New.Detail, itemKey)
			if err and data ~= nil then
				frame:SetOOR(data.outOfRange)
				frame:SetUsable(not data.unusable)
				macro = "cast " .. oSGSub(data.name, "\n", "")
			end
		else -- macro
			macro = string.gsub(thisItemKey, "\r", "\n")
			err = true
			data = { icon = macroIcon }
		end
			
		if err and data ~= nil and data.icon ~= nil then
			texture:SetTextureAsync("Rift", data.icon)  
		else
			texture:SetTextureAsync("nkHelios", "gfx/equipslot_blank.png")  
		end
		
		if interactive then
		
			if not macroFrame then
				macroFrame = EnKai.uiCreateFrame("nkFrame", name .. ".macroFrame", uiElements.secureContext)
				macroFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
				macroFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
				macroFrame:SetSecureMode("restricted")
				macroFrame:SetMouseMasking("limited")
				--macroFrame:SetBackgroundColor(0,0,0,1)
				
				macroFrame:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self)
					_checkDrop()
				end, macroFrame:GetName() .. ".UI.Input.Mouse.Left.Up")
			end

			--if macro ~= nil then print ('setting macro ' .. name .. ' ' .. macro) end
			--if macro ~= nil then print (string.gsub(macro, "\r", "\13")) end
			
			EnKai.events.addInsecure(function() macroFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, macro) end, nil, nil)
			macroFrame:SetVisible(true)
			
		elseif macroFrame ~= nil then			
			macroFrame:SetVisible(false)
		end
		
		local tooltipTarget = texture
		if interactive == true then tooltipTarget = macroFrame end
		
		if thisItemType == 'item' then
			EnKai.ui.attachItemTooltip (tooltipTarget, itemKey)
		elseif thisItemType == "ability" then
			EnKai.ui.attachAbilityTooltip (tooltipTarget, itemKey)
		else -- macro
			EnKai.ui.attachGenericTooltip (tooltipTarget, "nkHelios macro", macro)
		end
		
		--frame:SetBackgroundColor(0.078, 0.188, 0.306, 1)			
	end
	
	function frame:GetOutter() return outter end
	function frame:GetCooldown() return cooldown end
	
	function frame:SetInteractive(flag, doUpdate) 
		interactive = flag 
		if doUpdate then frame:SetItem(thisItemType, thisItemKey, thisMacroIcon) end
	end
		
	function frame:Scale (newScale)

		thisScale = newScale
		frame:SetDesign(data.setup.roles[Inspect.TEMPORARY.Role()].design)

	end

	function frame:SetDesign (design)
		if design == nil then design = 'default' end
		local setup = data.designs[design] 
		
		path = setup[4]
		
		local mainColor = data.setup.roles[Inspect.TEMPORARY.Role()].mainColor
		local subColor = data.setup.roles[Inspect.TEMPORARY.Role()].subColor
		
		local thisStroke = EnKai.tools.table.copy(setup[6])
		local thisFill = EnKai.tools.table.copy(setup[5])
		
		thisFill.r, thisFill.g, thisFill.b = subColor.r, subColor.g, subColor.b
		thisFill.a = 0.6
				
		thisStroke.r, thisStroke.g, thisStroke.b = mainColor.r, mainColor.g, mainColor.b
		thisStroke.a = 0.6
		
		frame:SetWidth(setup[3] * thisScale)
		frame:SetHeight(setup[3] * thisScale)
		frame:SetShape(path, thisFill, thisStroke)
		
		thisStroke.r, thisStroke.g, thisStroke.b, thisStroke.a = thisFill.r, thisFill.g, thisFill.b, 1
		
		overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", setup[6].thickness, setup[6].thickness)
		overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -setup[6].thickness, -setup[6].thickness)
		overlay:SetShape(path, nil, thisStroke)
		
		oorTint:SetShape(path, {type = 'solid', r = 1, g = 0, b = 0, a = .6}, nil)
		cooldownTint:SetShape(path, {type = 'solid', r = 1, g = 1, b = 1, a = .4}, nil)
		
		texture:ClearAll()
		texture:SetPoint("TOPLEFT", frame, "TOPLEFT", setup[6].thickness + setup[8], setup[6].thickness + setup[8])
		texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(setup[6].thickness + setup[8]), -(setup[6].thickness + setup[8]))
		
		if setup[1] ~= "" then
			outter:SetTextureAsync(setup[1], setup[2])
			outter:SetPoint("TOPLEFT", frame, "TOPLEFT", -(10 * thisScale), -(10 * thisScale))
			outter:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", (10 * thisScale), (10 * thisScale))
			--outter:SetWidth(setup[3] * thisScale)
			--outter:SetHeight(setup[3] * thisScale)
			outter:SetVisible(true)
		else
			outter:SetVisible(false)
		end
		
		overlay:SetVisible(setup[7])	
				
	end
		
	function frame:destroy()
	
		local target = texture
		if interactive then target = macroFrame end
					
		if thisItemType == 'item' then
			EnKai.ui.attachItemTooltip (target, nil)
		elseif thisItemType == 'macro' then
			EnKai.ui.attachGenericTooltip (target, nil, nil)
		else
			EnKai.ui.attachAbilityTooltip (target, nil)
		end
		
		macroFrame:destroy()
		texture:destroy()
		EnKai.uiAddToGarbageCollector ('nkFrame', frame, name)
	end
	
	
	local function _editMacro () 
	
		if Inspect.System.Secure() == true then return end
		if uiElements.macroEdit == nil then
			uiElements.macroEdit = _macroEditDialog()			
		end
		
		uiElements.macroEdit:SetVisible(true)
		uiElements.macroEdit:SetButton(barIndex, buttonIndex)
	
	end
	
	texture:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self)
		_checkDrop()
	end, texture:GetName() .. ".UI.Input.Mouse.Left.Up")
	
	texture:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
		frame:ClearItem()
		data.setup.roles[Inspect.TEMPORARY.Role()].bars[barIndex].slots[buttonIndex] = {}
	end, texture:GetName() .. ".UI.Input.Mouse.Right.Down")
	
	texture:EventAttach(Event.UI.Input.Mouse.Middle.Down, function (self)
		if data.setup.roles[Inspect.TEMPORARY.Role()].bars[barIndex].interactive == true then
			_editMacro()
		else
			EnKai.ui.confirmDialog (privateVars.langTexts.barNotInteractive, function()
				data.setup.roles[Inspect.TEMPORARY.Role()].bars[barIndex].interactive = true
				parent:SetInteractive(true)
				_editMacro()
			end)
		end
	end, texture:GetName() .. ".UI.Input.Mouse.Middle.Down")
	
	return frame

end

function _internal.uiActionBar(name, parent, index, interactive)

	local buttons = {}
	local moveableFlag

	local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
	
	local setupFrame = EnKai.uiCreateFrame("nkCanvas", name .. ".setupFrame", parent)
	setupFrame:SetLayer(1)
	local setupIcon = EnKai.uiCreateFrame("nkTexture", name .. ".setupIcon", parent)
	setupIcon:SetLayer(2)
	setupIcon:SetPoint("CENTER", setupFrame, "CENTER")
	setupIcon:SetTexture("nkHelios", "gfx/iconFrameSetup.png")
	
	local path = {{xProportional = 0, yProportional = 0}, 
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}}
	local fill = {type = 'solid', r = 0, g = 0, b = 0, a = 1}

	setupFrame:SetShape(path, fill, {r = 0.078, g = 0.188, b = 0.306, a = 1, thickness = 2 })
	setupFrame:SetVisible(false)
	setupIcon:SetVisible(false)
	
	local barSetup = data.setup.roles[Inspect.TEMPORARY.Role()].bars[index]
	
	if not barSetup then return nil end
	
	setupFrame:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)    
		self.leftDown = true
		local mouse = Inspect.Mouse()

		self.originalXDiff = mouse.x - self:GetLeft()
		self.originalYDiff = mouse.y - self:GetTop()

		local left, top, right, bottom = frame:GetBounds()

		frame:ClearPoint("TOPLEFT")
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, top)
	end, setupFrame:GetName() .. ".Left.Down")

	setupFrame:EventAttach( Event.UI.Input.Mouse.Cursor.Move, function (self, _, x, y)  
		if self.leftDown ~= true then return end

		local newX, newY = x - self.originalXDiff, y - self.originalYDiff

		if newX >= EnKai.uiGetBoundLeft() and newX + frame:GetWidth() <= EnKai.uiGetBoundRight() and newY >= EnKai.uiGetBoundTop() and newY + frame:GetHeight() <= EnKai.uiGetBoundBottom() then    
			frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", newX, newY)
		end
	end, setupFrame:GetName() .. ".Cursor.Move")

	setupFrame:EventAttach( Event.UI.Input.Mouse.Left.Up, function (self) 
		if self.leftDown ~= true then return end
		self.leftDown = false
		barSetup.x = frame:GetLeft()
		barSetup.y = frame:GetTop()
		
		if uiElements.config ~= nil then uiElements.config:UpdateCoords() end
		
	end, setupFrame:GetName() .. ".Left.Up")
	
	setupFrame:EventAttach( Event.UI.Input.Mouse.Left.Upoutside, function (self)
		if self.leftDown ~= true then return end
		self.leftDown = false
		barSetup.x = frame:GetLeft()
		barSetup.y = frame:GetTop()
		
		if uiElements.config ~= nil then uiElements.config:UpdateCoords() end
		
	end , setupFrame:GetName() .. ".Left.Upoutside")
	
	setupFrame:EventAttach( Event.UI.Input.Mouse.Right.Down, function (self) 
		if barSetup.vertical then 
			barSetup.vertical = false
		else
			barSetup.vertical = true
		end
		frame:ReDraw()
	end, setupFrame:GetName() .. ".Right.Down")
	
	function frame:ReDraw()
	
		local debugId
		if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "uiActionBar " .. name .. " Redraw") end
		
		if Inspect.System.Secure() == false then Command.System.Watchdog.Quiet() end
		
		local from, to, object, x, y = "TOPLEFT", "TOPLEFT", frame, nil, nil
		local count, realFirstSlot, firstSlot, lastSlot = 0, nil, nil, nil
		
		barSetup = data.setup.roles[Inspect.TEMPORARY.Role()].bars[index]
		
		local width, height
		local topLeft, BottomRight
		local fontSize = 24 * barSetup.scale / 100

		checkValue = barSetup.cols
		if barSetup.vertical == true then 
			checkValue = barSetup.rows 
		end
		
		for idx = 1, barSetup.rows * barSetup.cols, 1 do
			
			local thisSlot = buttons[idx]
			if thisSlot == nil then
				thisSlot = _fctButton(name .. ".barButton." .. idx, frame, index, idx)
				table.insert(buttons, thisSlot)
			else
				thisSlot:ClearItem()
			end
									
			thisSlot:ClearAll()
			thisSlot:Scale(barSetup.scale / 100)

			if x == nil then x, y = 0, 0 end
			
			thisSlot:GetCooldown():SetFontSize(fontSize)
			thisSlot:SetPoint(from, object, to, x, y)
			thisSlot:SetUsable(true)
			thisSlot:SetCooldown()
			thisSlot:SetInteractive(interactive, false)
			
			local item = barSetup.slots[idx]
			
			if item ~= nil then
				if item.macroCD ~= nil then
					thisSlot:SetItem(item.itemType, item.itemKey, item.macroIcon, item.macroCD[1], item.macroCD[2])
				else
					thisSlot:SetItem(item.itemType, item.itemKey, item.macroIcon)
				end
			end
			
			if item ~= nil or data.setup.roles[Inspect.TEMPORARY.Role()].hideempty == false then
				thisSlot:SetVisible(true)
			else
				thisSlot:SetVisible(false)				
			end
			
			from, to, object, x, y = "CENTERLEFT", "CENTERRIGHT", thisSlot, barSetup.padding, 0
			
			if count == 0 then 
				if realFirstSlot == nil then realFirstSlot = thisSlot end
				firstSlot = thisSlot 
			end
			
			count =  count + 1
			if count == checkValue then
				from, to, object, x, y = "CENTERTOP", "CENTERBOTTOM", firstSlot, 0, barSetup.padding
				count = 0
			end
			
			if idx == barSetup.rows * barSetup.cols then lastSlot = thisSlot end
			
		end
		
		frame:SetAlpha((barSetup.outOfCombatAlpha or 100) / 100)
		
		for idx = (barSetup.rows * barSetup.cols) + 1, #buttons, 1 do
			local thisSlot = buttons[idx]
			if thisSlot ~= nil then
				thisSlot:SetVisible(false)
				thisSlot:ClearItem()
			end
		end
		
		setupFrame:ClearAll()
		
		if barSetup.vertical == true then 
			setupFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, - 20)
			setupFrame:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0)						
			
			frame:SetWidth(lastSlot:GetWidth() * barSetup.rows + (barSetup.rows -1) + ((barSetup.padding or data.defaultBar.padding) * (barSetup.rows-1)))
			frame:SetHeight(lastSlot:GetHeight() * barSetup.cols + (barSetup.cols -1))
		else
			setupFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -20, 0)
			setupFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 0)			
			
			frame:SetWidth(lastSlot:GetWidth() * barSetup.cols + (barSetup.cols -1) + ((barSetup.padding or data.defaultBar.padding) * (barSetup.cols-1)))
			frame:SetHeight(lastSlot:GetHeight() * barSetup.rows + (barSetup.rows -1))
		end
		
		setupIcon:SetHeight(setupFrame:GetHeight() - 8)
		setupIcon:SetWidth(setupFrame:GetWidth() - 8)
		setupIcon:SetTexture("nkHelios", "gfx/iconFrameSetup.png")
		
		if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "uiActionBar " .. name .. " Redraw", debugId) end
		
	end
		
	function frame:destroy()
		for idx = 1, #buttons, 1 do
			buttons[idx]:destroy()
			EnKai.uiAddToGarbageCollector ('nkFrame', frame, name)
		end
	end
	
	function frame:SetInteractive(flag, doUpdate)
		interactive = flag
		
		if #buttons > 0 then		
			for idx = 1, #buttons, 1 do
				buttons[idx]:SetInteractive(flag, doUpdate)
			end
		end
	end
	
	function frame:SetMoveable (flag)
	
		if flag == moveableFlag then return end
		moveableFlag = flag
	
		setupFrame:SetVisible(flag)
		setupIcon:SetVisible(flag)
		frame:SetInteractive(not flag, true)
	end
	
	local oSetVisible = frame.SetVisible
	
	function frame:SetVisible(flag)
		oSetVisible(self, flag)
		if flag == false then
			setupFrame:SetVisible(false)
			setupIcon:SetVisible(false)
		end
	end
	
	return frame
	
end