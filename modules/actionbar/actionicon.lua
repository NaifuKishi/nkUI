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
	local texture, cooldown, macroFrame, tint
	local thisItemKey, thisItemType, thisMacroIcon, thisMacroCDType, thisMacroCDKey

	local cooldownActive = false
	local lastCooldown
	local interactive = false
	local isOOR, isUsable = false, true
	
	local thisDesign = "DEFAULT"

	-- Shape path for the icon	
	local path = {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 0}, {xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 1}, {xProportional = 0, yProportional = 0}}
	
	-- Fill color for the icon
	local fill = {type = 'solid', r = 0.078, g = 0.188, b = 0.306, a = 1}
	local thisScale = 1
	
	-- Set the shape and border of the frame
	frame:SetShape(path, fill, {r = 0, g = 0, b = 0, a = 1, thickness = 3 })

	local function createTexture ()

		--print (name, "createTexture")

		-- Create the texture for the icon
		texture = LibEKL.UICreateFrame("nkTexture", name .. '.texture', frame)  
		texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, 3)
		texture:SetMouseMasking("limited")
		texture:SetVisible(false)
		texture:SetLayer(1)

		local setup = data.actionBarDesigns[thisDesign] 
		local newSize = (setup[3] * thisScale) 
		texture:SetWidth(newSize-4)
		texture:SetHeight(newSize-4)		

		texture:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)
			frame:SetShape(path, fill, {r = 1, g = 1, b = 1, a = 1, thickness = 1 })
		end, texture:GetName() .. ".UI.Input.Mouse.Cursor.In")		

		texture:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)
			frame:SetDesign ()
		end, texture:GetName() .. ".UI.Input.Mouse.Cursor.Out")
	end

	local function createTint()
		--print ("createTint")

		-- Create the tint canvas
		tint = LibEKL.UICreateFrame("nkCanvas", name .. ".tint", frame)
		tint:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, 3)
		tint:SetVisible(false)
		tint:SetMouseMasking("limited")
		tint:SetVisible(false)
		tint:SetLayer(2)

		local setup = data.actionBarDesigns[thisDesign] 
		local newSize = (setup[3] * thisScale) 
		tint:SetWidth(newSize-4)
		tint:SetHeight(newSize-4)
	end

	local function createCooldown()
		-- Create the cooldown text
		cooldown = LibEKL.UICreateFrame("nkText", name .. '.cooldown', frame)
		cooldown:SetVisible(false)
		cooldown:SetFontSize(18)
		cooldown:SetPoint("CENTER", texture, "CENTER")
		cooldown:SetFontColor (1, 1, 1, 1)
		cooldown:SetEffectGlow({ strength = 3 })
		cooldown:SetLayer(99)
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
			data.actionBarSetup.roles[inspectTEMPORARYRole()].bars[barIndex].slots[buttonIndex] = { itemType = cType, itemKey = cHeld, macroIcon = nil }
		end
		
		Command.Cursor(nil)
	
	end
	
	--[[
      Function to clear the current item
      Clears the current item, ability, or macro from the action icon
    ]]
	function frame:ClearItem()
		
		if texture then
			LibEKL.UI.attachItemTooltip (texture, nil)
			LibEKL.UI.attachAbilityTooltip (texture, nil)
			LibEKL.UI.attachGenericTooltip (texture, nil)
		end
				
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

		--tint:SetVisible(false)

		if macroFrame then
			LibEKL.Events.AddInsecure(function() macroFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, nil) end, nil, nil)
		end

		if texture then texture:SetVisible(false) end
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
			if not texture then createTexture() end
			texture:SetTextureAsync("Rift", thisDetails.icon)
			texture:SetVisible(true)
		else
			if texture then texture:SetVisible(false) end
		end

		if interactive then
		
			if not macroFrame then
				macroFrame = LibEKL.UICreateFrame("nkFrame", name .. ".macroFrame", uiElements.unitFramesContextSecure)
				macroFrame:SetPoint("CENTER", frame, "CENTER", 1, 1)
				macroFrame:SetSecureMode("restricted")
				macroFrame:SetMouseMasking("limited")
				
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

		if texture then
			local tooltipTarget = texture
			if interactive then tooltipTarget = macroFrame end
							
			if thisItemType == 'item' then
				LibEKL.UI.attachItemTooltip (tooltipTarget, itemKey)
			elseif thisItemType == "ability" then
				LibEKL.UI.attachAbilityTooltip (tooltipTarget, itemKey)
				LibEKL.UI.abilityTooltipSetFont (addonInfo.id, "MontserratSemiBold")
			else -- macro
				LibEKL.UI.attachGenericTooltip (tooltipTarget, "nkUI macro", macro)
			end
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
		thisScale = newScale
		frame:SetDesign(DEFAULT_DESIGN)
	end

	--[[
      Function to set the design
      @param {string} design - The design to applytint
    ]]
	function frame:SetDesign (design)

		if design == nil then 
			thisDesign = DEFAULT_DESIGN 
		else
			thisDesign = design
		end
		
		local setup = data.actionBarDesigns[thisDesign] 
		
		path = setup[4]

		local mainColor = data.actionBarColors.mainColor
		local subColor = data.actionBarColors.subColor
		
		local thisStroke = LibEKL.Tools.Table.Copy(setup[6])
		local thisFill = LibEKL.Tools.Table.Copy(setup[5])
		
		thisFill.r, thisFill.g, thisFill.b = subColor.r, subColor.g, subColor.b
		thisFill.a = 0.6
				
		thisStroke.r, thisStroke.g, thisStroke.b = mainColor.r, mainColor.g, mainColor.b
		thisStroke.a = 0.6
		thisStroke.thickness = 3

		local newSize = (setup[3] * thisScale) 
		
		frame:SetWidth(newSize)
		frame:SetHeight(newSize)
		frame:SetShape(path, thisFill, thisStroke)

		if texture then
			texture:SetWidth(newSize-4)
			texture:SetHeight(newSize-4)
			texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, 3)
		end
			
		if tint then
			tint:SetWidth(newSize-4)
        	tint:SetHeight(newSize-4)				
			tint:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, 3)
		end
	end
	
	--[[
      Function to destroy the frame
      Cleans up resources and removes the frame from the UI
    ]]
	function frame:destroy()
	
		local target = texture
		if interactive then target = macroFrame end
					
		if thisItemType == 'item' then
			LibEKL.UI.attachItemTooltip (target, nil)
		elseif thisItemType == 'macro' then
			LibEKL.UI.attachGenericTooltip (target, nil, nil)
		else
			LibEKL.UI.attachAbilityTooltip (target, nil)
		end
		
		texture:destroy()
		tint:destroy()
		cooldown:destroy()
		internalFunc.uiAddToGarbageCollector ('nkFrame', frame, name)
	end

	-- due to the out event triggering when hover the texture we only want the frame events to run if texture is not visible

	frame:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)
		if not texture or not texture:GetVisible() then 
			frame:SetShape(path, fill, {r = 1, g = 1, b = 1, a = 1, thickness = 1 })
		end
	end, frame:GetName() .. ".UI.Input.Mouse.Cursor.In")

	frame:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)
		if not texture or not texture:GetVisible() then frame:SetDesign () end
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
								transform = Utility.Matrix.Create(2, 2, -(math.pi / 6), 0, 0), -- Negative angle for opposite direction
								color = {
									data.theme.windowStartColor,
									data.theme.windowEndColor
									}
							},  { r = 0, g = 0, b = 0, a = 1, thickness = 1})
		end
	end

	frame:EventAttach(Event.UI.Input.Mouse.Middle.Down, function (self)
		internalFunc.checkSecureAction(function()
			editMacro()
		end)		
	end, frame:GetName() .. ".UI.Input.Mouse.Middle.Down")
	
	frame:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
		internalFunc.checkSecureAction(function()
			frame:ClearItem()
			data.actionBarSetup.roles[inspectTEMPORARYRole()].bars[barIndex].slots[buttonIndex] = {}
		end)
	end, frame:GetName() .. ".UI.Input.Mouse.Right.Down")
	
	return frame

end