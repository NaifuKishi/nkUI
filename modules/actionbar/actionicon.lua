--[[
  @module actionicon
  @description Creates and manages action icons for the action bar module
  @version 1.0

  This module handles the creation and management of individual action icons
  that appear on the action bars. It manages visual states, tooltips, and
  interactions with items, abilities, and macros.
]]
local addonInfo, privateVars = ...

-- Initialize namespace
local data        	= privateVars.data
local uiElements  	= privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events     	= privateVars.events

-- Cache frequently used functions and values
local inspectTimeFrame 			= Inspect.Time.Frame
local inspectItemDetail			= Inspect.Item.Detail
local inspectCursor				= Inspect.Cursor
local inspectTEMPORARYRole		= Inspect.TEMPORARY.Role
local inspectAbilityNewDetail	= Inspect.Ability.New.Detail

local stringGSub        		= string.gsub
local mathFloor					= math.floor

-- Predefined constants
local DEFAULT_SCALE = 1
local DEFAULT_DESIGN = 'default'

local contextSecure = UI.CreateContext("nkUI.actioniconSecure")
contextSecure:SetStrata('notify')
contextSecure:SetSecureMode("restricted")

--[[
  Main action icon function
  @param {string} name - The name of the icon
  @param {frame} parent - The parent frame
  @param {number} barIndex - The index of the bar
  @param {number} buttonIndex - The index of the button
  @return {frame} The created action icon frame
]]
function uiElements.actionIcon(name, parent, barIndex, buttonIndex)

	-- Create the main frame for the action icon
	local frame = LibEKL.UICreateFrame("nkCanvas", name, parent)
	
	-- Local variables for the icon components and state
	local cooldown, macroFrame, tint, keyBindLabel
	local thisItemKey, thisItemType, thisMacroIcon, thisMacroCDType, thisMacroCDKey

	local cooldownActive = false
	local lastCooldown
	local interactive = false
	local isOOR, isUsable = false, true
	
	local thisDesign = "DEFAULT"

	-- Shape path for the icon	
	local path = {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 0}, {xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 1}, {xProportional = 0, yProportional = 0}}
	
	-- Fill color for the icon
	local defaultFill = {type = 'solid', r = 0, g = 0, b = 0, a = .6}
	local fill = {type = 'solid', r = 0, g = 0, b = 0, a = .6}
	local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 2 }
	local thisScale = 1
	
	-- Set the shape and border of the frame
	frame:SetShape(path, defaultFill, stroke)
	
	local function createTint()
		tint = LibEKL.UICreateFrame("nkCanvas", name .. ".tint", frame)
		tint:SetPoint("CENTER", frame, "CENTER", 1, 1)
		tint:SetVisible(false)
		tint:SetMouseMasking("limited")
		tint:SetVisible(false)
		tint:SetLayer(2)

		tint:SetWidth(frame:GetWidth())
		tint:SetHeight(frame:GetWidth())
	end

	local function createCooldown()
		-- Create the cooldown text
		cooldown = LibEKL.UICreateFrame("nkText", name .. '.cooldown', frame)
		cooldown:SetVisible(false)
		cooldown:SetFontSize(18)
		cooldown:SetPoint("CENTER", frame, "CENTER")
		cooldown:SetFontColor (1, 1, 1, 1)
		cooldown:SetEffectGlow({ strength = 3 })
		cooldown:SetLayer(99)
	end

	local function createKeyBindLabel()
		-- Create the keybind label text element
		keyBindLabel = LibEKL.UICreateFrame("nkText", name .. '.keyBindLabel', frame)
		keyBindLabel:SetVisible(false)
		keyBindLabel:SetFontSize(10)
		keyBindLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, 2)
		keyBindLabel:SetFontColor(1, 1, 1, 1)
		keyBindLabel:SetEffectGlow({ strength = 1 })
		keyBindLabel:SetLayer(3)
		LibEKL.UI.SetFont(keyBindLabel, addonInfo.id, "MontserratBold")
	end

	function frame:SetTint(state)
		if state == nil then
			if tint then tint:SetVisible(false) end
			return
		end

		if not tint then createTint() end			
		tint:SetVisible(true)

		if state == "cooldown" then
			tint:SetShape(path, {type = 'solid', r = 1, g = 1, b = 1, a = .4}, nil)
		elseif state == "oor" then 
			tint:SetShape(path, {type = 'solid', r = 1, g = 0, b = 0, a = .6}, nil)
		elseif state == "unusable" and not isOOR then
			tint:SetShape(path, {type = 'solid', r = 0, g = 0, b = 0, a = .8}, nil)
		end		
	end
	
	--[[
      Function to set GCD (Global Cooldown)
      @param {number} duration - The duration of the GCD
    ]]
	function frame:SetGCD (duration)

		if duration == nil or cooldownActive == true then return end

		if not cooldown then createCooldown()  end

		local start = inspectTimeFrame()
		local lastRemaining

		local gcdCoRoutine = coroutine.create(function ()
			for idx = 1, 999, 1 do		
				local thisRemaining = duration - (inspectTimeFrame() - start)
				local checkRemaining = mathFloor(thisRemaining * 10) / 10

				if checkRemaining <= 0 then
					cooldown:SetVisible(false)
					frame:SetTint()
					return 9999 
				end

				--if inspectTimeFrame() - start > duration then return 9999 end

				if checkRemaining ~= lastRemaining then
					lastRemaining = checkRemaining
					cooldown:SetText(tostring(checkRemaining))
				end

				coroutine.yield(idx)
			end
		end)

		cooldownActive = true		
		cooldown:SetVisible(true)
		frame:SetTint("cooldown")
		cooldown:SetText(tostring(mathFloor(duration * 10) / 10))

		LibEKL.Coroutines.Add ({ func = gcdCoRoutine, counter = 999, active = true })
	end	

	--[[
      Function to set cooldown
      @param {string|number} timer - The cooldown timer text or number      
    ]]
	function frame:SetCooldown(timer)

		if timer == nil then
			if cooldown then
				cooldown:SetVisible(false)
				cooldown:SetFontColor (1, 1, 1, 1)
			end
			frame:SetTint()			
			cooldownActive = false
		else
			if not cooldown then createCooldown() end

			if cooldownActive == false then
				cooldownActive = true		
				cooldown:SetVisible(true)
				frame:SetTint("cooldown")
			end

			if type(timer) == 'number' and tonumber(timer) < 10 then
				cooldown:SetFontColor(1, 0, 0, 1)
			end
			
			if lastCooldown ~= timer then
				cooldown:SetText(timer)
			end
		end
	end

	--[[
      Function to set keybind label
      Creates/updates a text element showing the keybind label in the bottom-right corner
      @param {string|nil} key - The keybind label to display (e.g. "Q", "Shift+1"), or nil to hide
    ]]
	function frame:SetKeyBind(key)
		--print (key)

		if key == nil then
			-- Hide the label if no key is set
			if keyBindLabel then
				keyBindLabel:SetVisible(false)
			end
		else
			-- Lazy-create the label on first non-nil call
			if not keyBindLabel then
				createKeyBindLabel()
			end
			-- Set the text and show the label
			keyBindLabel:SetText(key)
			keyBindLabel:SetVisible(true)
		end
	end

	--[[
      Function to set out-of-range state
      @param {boolean} flag - Whether the ability is out of range
    ]]
	function frame:SetOOR (flag)
	
		isOOR = flag
	
		if flag == true then
			if tint then tint:SetVisible(true) end
			frame:SetTint("oor")
		else
			if isUsable then
				frame:SetTint()
			else
				frame:SetUsable(false)
			end
		end
	end
	
	--[[
      Function to set usable state
      @param {boolean} flag - Whether the ability is usable
    ]]
	function frame:SetUsable (flag)
	
		isUsable = flag
	
		if flag == true then
			if not isOOR then				
				frame:SetTint()
			end
		else
			frame:SetTint("unusable")
		end
	end
	
	--[[
      Function to check for dropped items/abilities
      Handles the dropping of items or abilities onto the action icon
    ]]
	local function fctCheckDrop ()
	
		local cType, cHeld = inspectCursor()
		
		if cType == 'item' or cType == 'ability' then
			frame:SetItem(cType, cHeld, nil)
			local existingSlot = data.actionBarSetup.roles[inspectTEMPORARYRole()].bars[barIndex].slots[buttonIndex]
			local existingKeyBind = existingSlot and existingSlot.keyBind or nil
			data.actionBarSetup.roles[inspectTEMPORARYRole()].bars[barIndex].slots[buttonIndex] = { itemType = cType, itemKey = cHeld, macroIcon = nil, keyBind = existingKeyBind }
		end
		
		Command.Cursor(nil)
	
	end
	
	--[[
      Function to clear the current item
      Clears the current item, ability, or macro from the action icon
    ]]
	function frame:ClearItem()

		LibEKL.UI.attachItemTooltip (frame, nil)
		LibEKL.UI.attachAbilityTooltip (frame, nil)
		LibEKL.UI.attachGenericTooltip (frame, nil)

		if thisMacroCDType ~= nil then
			LibEKL.Cooldowns.Unsubscribe(thisMacroCDType, thisMacroCDKey)

			data.abilityMap[thisMacroCDKey] = nil
			data.abilityList[thisMacroCDKey] = nil
		elseif thisItemKey ~= nil and thisItemKey ~= 'macro' then
			LibEKL.Cooldowns.Unsubscribe(thisItemType, thisItemKey)

			if not data.abilityMap then data.abilityMap = {} end
			if not data.abilityList then data.abilityList = {} end

			data.abilityMap[thisItemKey] = nil
			data.abilityList[thisItemKey] = nil
		end

		thisItemKey = nil
		thisItemType = nil
		thisMacroIcon = nil
		thisMacroCDType = nil
		thisMacroCDKey = nil

		-- Hide keybind label when clearing item (do NOT clear keyBind from SavedVars here,
		-- because ClearItem is also called internally by SetItem during Populate)
		frame:SetKeyBind(nil)

		fill = LibEKL.Tools.Table.Copy(defaultFill)
		frame:SetShape(path, defaultFill, stroke)

		--tint:SetVisible(false)

		if macroFrame then
			LibEKL.Events.AddInsecure(function() macroFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, nil) end, nil, nil)
		end
	end
	
	function frame:CheckState()
		if thisItemType ~= "ability" then return end

		local err, thisDetails = pcall(inspectAbilityNewDetail, itemKey)

		if err and thisDetails ~= nil then
			frame:SetOOR(thisDetails.outOfRange)
			frame:SetUsable(not thisDetails.unusable)
		end
	end
	
	--[[
      Function to set an item/ability/macro
      @param {string} itemType - The type of item ('item', 'ability', or 'macro')
      @param {string} itemKey - The key of the item or ability
      @param {string} macroIcon - The icon for the macro
      @param {string} macroCDType - The cooldown type for the macro
      @param {string} macroCDKey - The cooldown key for the macro
    ]]
	function frame:SetItem(itemType, itemKey, macroIcon, macroCDType, macroCDKey)

		-- Preserve existing keybind across item replacement
		local role = inspectTEMPORARYRole()
		local savedKeyBind
		if data.actionBarSetup and data.actionBarSetup.roles[role] then
			local slot = data.actionBarSetup.roles[role].bars[barIndex].slots[buttonIndex]
			if slot then savedKeyBind = slot.keyBind end
		end

		if thisItemType ~= nil then frame:ClearItem() end

		if itemType == nil or itemKey == nil then return end
				
		thisItemKey = itemKey
		thisItemType = itemType
		thisMacroIcon = macroIcon
		thisMacroCDType = macroCDType
		thisMacroCDKey = macroCDKey
		
		if macroCDType ~= nil then
			LibEKL.Cooldowns.Subscribe(macroCDType, macroCDKey)

			if data.abilityMap[macroCDKey] == nil then data.abilityMap[macroCDKey] = {} end
			table.insert(data.abilityMap[macroCDKey], frame)
			table.insert(data.abilityList, macroCDKey)
		else
			LibEKL.Cooldowns.Subscribe(thisItemType, thisItemKey)
			if data.abilityMap == nil then data.abilityMap = {} end
			if data.abilityMap[itemKey] == nil then data.abilityMap[itemKey] = {} end
			table.insert(data.abilityMap[itemKey], frame)
			table.insert(data.abilityList, itemKey)
		end
		
		local err, thisDetails, macro
		
		if thisItemType == 'item' then
			err, thisDetails = pcall(inspectItemDetail, itemKey)
			if err and thisDetails ~= nil then
				macro = "use " .. stringGSub(thisDetails.name, "\n", "")
			end
		elseif thisItemType == "ability" then
			err, thisDetails = pcall(inspectAbilityNewDetail, itemKey)

			if err and thisDetails ~= nil then
				frame:SetOOR(thisDetails.outOfRange)
				frame:SetUsable(not thisDetails.unusable)
				macro = "cast " .. stringGSub(thisDetails.name, "\n", "")
			end
		else -- macro
			macro = stringGSub(thisItemKey, "\r", "\n")
			err = true
			thisDetails = { icon = macroIcon }
		end
			
		if err and thisDetails ~= nil and thisDetails.icon ~= nil then
			local width = frame:GetWidth()
			fill = { type = "texture", source = "Rift", texture = thisDetails.icon, transform = Utility.Matrix.Create(width / data.textureRef.x, width / data.textureRef.x, 0, 0, 0) }			
		else
			fill = defaultFill
		end

		frame:SetShape(path, fill, stroke)

		if interactive then
		
			if not macroFrame then
				macroFrame = LibEKL.UICreateFrame("nkFrame", name .. ".macroFrame", contextSecure)
				macroFrame:SetPoint("CENTER", frame, "CENTER", 1, 1)
				macroFrame:SetSecureMode("restricted")
				macroFrame:SetMouseMasking("limited")
				--macroFrame:SetBackgroundColor(1, 0, 0, .2)
				
				local thisSize = frame:GetWidth() -2
				macroFrame:SetWidth(thisSize)
				macroFrame:SetHeight(thisSize)
				
				macroFrame:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self)
					fctCheckDrop()
				end, macroFrame:GetName() .. ".UI.Input.Mouse.Left.Up")
			end

			LibEKL.Events.AddInsecure(function() macroFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, macro) end, nil, nil)
			macroFrame:SetVisible(true)
			
		elseif macroFrame ~= nil then
			LibEKL.Events.AddInsecure(function() macroFrame:SetVisible(false) end, nil, nil)
		end

		if interactive then tooltipTarget = macroFrame end
						
		if thisItemType == 'item' then
			LibEKL.UI.attachItemTooltip (frame, itemKey)
		elseif thisItemType == "ability" then
			LibEKL.UI.attachAbilityTooltip (frame, itemKey)
			LibEKL.UI.abilityTooltipSetFont (addonInfo.id, "MontserratSemiBold")
		else -- macro
			LibEKL.UI.attachGenericTooltip (frame, "nkUI macro", macro)
		end

		-- Restore keybind that was preserved before ClearItem
		if savedKeyBind then
			frame:SetKeyBind(savedKeyBind)
		end
	end
	
	--[[
      Function to get the cooldown frame
      @return {frame} The cooldown frame
    ]]
	function frame:GetCooldown() return cooldown end

	--[[
      Function to set interactive state
      @param {boolean} flag - Whether the icon is interactive
      @param {boolean} doUpdate - Whether to update the item
    ]]
	function frame:SetInteractive(flag, doUpdate) 
		interactive = flag 
		if doUpdate then frame:SetItem(thisItemType, thisItemKey, nil) end
	end
	
	--[[
      Function to scale the icon
      @param {number} newScale - The new scale value
    ]]
    function frame:Scale (newScale)
		
		local newSize = nkUISetup.modules.actionBars.iconSize * newScale
		
		frame:SetWidth(newSize)
		frame:SetHeight(newSize)

		if thisItemKey then
			fill = { type = "texture", source = "Rift", texture = thisDetails.icon, transform = Utility.Matrix.Create(newSize / data.textureRef.x, newSize / data.textureRef.x, 0, 0, 0) }
		end

		frame:SetShape(path, fill, stroke)

		if tint then
			tint:SetWidth(newSize)
        	tint:SetHeight(newSize)				
			tint:SetPoint("CENTER", frame, "CENTER", 1, 1)
		end
	end
	
	-- due to the out event triggering when hover the texture we only want the frame events to run if texture is not visible

	frame:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)		
		frame:SetShape(path, fill, {r = 1, g = 1, b = 1, a = 1, thickness = 2 })		
	end, frame:GetName() .. ".UI.Input.Mouse.Cursor.In")

	frame:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)
		frame:SetShape(path, fill, stroke)
	end, frame:GetName() .. ".UI.Input.Mouse.Cursor.Out")


	--[[
	Function to edit macro
	Opens the macro editor dialog for the current action icon
	]]
	local function editMacroDialog ()
		if uiElements.macroEdit == nil then
			uiElements.macroEdit = internalFunc.macroEditDialog(parent)
		end

		uiElements.macroEdit:SetVisible(true)
		uiElements.macroEdit:SetButton(barIndex, buttonIndex)
	end

	--[[
	Function to edit keybind label
	Opens the keybind editor dialog for the current action icon
	]]
	local function editKeybindDialog ()
		if uiElements.keybindEdit == nil then
			uiElements.keybindEdit = internalFunc.keybindDialog(parent)
		end

		uiElements.keybindEdit:SetVisible(true)
		uiElements.keybindEdit:SetButton(barIndex, buttonIndex)
	end

	--[[
	Attach event handlers
	Sets up mouse event handlers for the action icon
	]]
	frame:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self)
		internalFunc.checkSecureAction(function()
			fctCheckDrop()
		end)			
	end, frame:GetName() .. ".UI.Input.Mouse.Left.Up")

	local function editMacro()
		if data.actionBarSetup.roles[inspectTEMPORARYRole()].bars[barIndex].interactive == true then
			editMacroDialog()
		else
			local dialog = LibEKL.UI.confirmDialog ('This bar is not flagged as interactive. Macros can be defined on interactive bars. However these bars cannot be hidden in combat.\n\nDo you want to change this bar to interactive mode?', function()
				data.actionBarSetup.roles[inspectTEMPORARYRole()].bars[barIndex].interactive = true
				parent:SetInteractive(true)
				editMacroDialog()
			end)

			dialog:SetTitle("nkUI")
			dialog:SetTitleFont(addonInfo.id, "MontserratSemiBold")
			dialog:SetTitleFontSize (20)    
			dialog:SetTitleAlign("center")
			dialog:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

			dialog:SetFont(addonInfo.id, "MontserratSemiBold")
			dialog:SetEffectGlow({ strength = 3 })
			dialog:SetButtonFont(addonInfo.id, "MontserratSemiBold")
			dialog:SetButtonFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
			dialog:SetButtonLabelColor (data.theme.labelColor)
			dialog:SetButtonBorderColor ({ r = 0, g = 0, b = 0, a = .7, thickness = 1})
			dialog:SetButtonEffect({ strength = 3 })
			dialog:SetHeight(200)
			
			dialog:SetColor({	type = "gradientLinear",
								transform = Utility.Matrix.Create(12, 12, math.pi / 4, 0, 0),  -- 45° rotation
								color = {
									{r = 0.1294, g = 0.1533, b = 0.2157, a = 1, position = 0}, -- Start color
									{r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1}  -- End color
								}
							}, data.theme.STROKE_BORDER)
		end
	end

	frame:EventAttach(Event.UI.Input.Mouse.Middle.Down, function (self)
		internalFunc.checkSecureAction(function()
			editMacro()
		end)		
	end, frame:GetName() .. ".UI.Input.Mouse.Middle.Down")
	
	frame:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
		-- Open keybind dialog for assigning keybind labels
		internalFunc.openKeybindDialog(barIndex, buttonIndex, self)
	end, frame:GetName() .. ".UI.Input.Mouse.Right.Down")

	return frame

end