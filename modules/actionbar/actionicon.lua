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
local InspectItemDetail			= Inspect.Item.Detail
local InspectSystemSecure		= Inspect.System.Secure
local InspectCursor				= Inspect.Cursor
local InspectTEMPORARYRole		= Inspect.TEMPORARY.Role
local InspectAbilityNewDetail	= Inspect.Ability.New.Detail

local stringGSub        		= string.gsub
local mathFloor					= math.floor

-- Predefined constants
local DEFAULT_SCALE = 1
local DEFAULT_DESIGN = 'default'
local EMPTY_FRAME_TEXTURE = "gfx/emptyFrame.png"
local BLANK_TEXTURE = "gfx/equipslot_blank"

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
	local frame = LibEKL.uiCreateFrame("nkCanvas", name, parent)
	
	-- Local variables for the icon components and state
	local texture, oorTint, cooldownTint, cooldown, macroFrame, overlay
	local thisItemKey, thisItemType, thisMacroIcon, thisMacroCDType, thisMacroCDKey

	local cooldownActive = false
	local interactive = false
	local oor, usable = false, true

	-- Shape path for the icon	
	local path = {{xProportional = 0.5, yProportional = 0}, 
                  {xProportional = 1, yProportional = 0.5, xControlProportional = (61/64), yControlProportional = (3/64)},
                  {xProportional = 0.5, yProportional = 1, xControlProportional = (61/64), yControlProportional = (61/64)},
                  {xProportional = 0, yProportional = 0.5, xControlProportional = (3/64), yControlProportional = (61/64)},
                  {xProportional = 0.5, yProportional = 0, xControlProportional = (3/64), yControlProportional = (3/64)}}
	
	-- Fill color for the icon
	local fill = {type = 'solid', r = 0.078, g = 0.188, b = 0.306, a = 1}
	local thisScale = 1
	
	-- Set the shape and border of the frame
	frame:SetShape(path, fill, {r = 0, g = 0, b = 0, a = 1, thickness = 1 })

	-- Create the texture for the icon
	texture = LibEKL.uiCreateFrame("nkTexture", name .. '.texture', frame)  
	texture:SetPoint("CENTER", frame, "CENTER", 1, 1)
	texture:SetLayer(1)
	texture:SetMouseMasking("limited")
	
	 -- Create the overlay for the icon
	overlay = LibEKL.uiCreateFrame("nkCanvas", name .. ".overlay", frame)
	overlay:SetPoint("CENTER", frame, "CENTER", 1, 1)
	overlay:SetShape(path, nil, {r = 0, g = 0, b = 0, a = 1, thickness = 5 })
	overlay:SetLayer(2)
    overlay:SetVisible(false)
	
	-- Create the out-of-range tint
	oorTint = LibEKL.uiCreateFrame("nkCanvas", name .. ".oorTint", frame)
	oorTint:SetVisible(false)
	oorTint:SetPoint("CENTER", overlay, "CENTER")
	oorTint:SetLayer(4)
	
	-- Create the cooldown tint
	cooldownTint = LibEKL.uiCreateFrame("nkCanvas", name .. ".cooldownTint", frame)
	cooldownTint:SetVisible(false)
	cooldownTint:SetPoint("CENTER", overlay, "CENTER")
	cooldownTint:SetLayer(5)
	
	-- Create the cooldown text
	cooldown = LibEKL.uiCreateFrame("nkText", name .. '.cooldown', frame)
	cooldown:SetVisible(false)
	cooldown:SetFontSize(18)
	cooldown:SetPoint("CENTER", frame, "CENTER")
	cooldown:SetFontColor (1, 1, 1, 1)
	--cooldown:SetEffectGlow({ colorB = 0, colorA = 1, colorG = 0, colorR = 0, strength = 3, blurX = 3, blurY = 3 })
	cooldown:SetEffectGlow({ strength = 3 })
	cooldown:SetLayer(6)
	
	--[[
      Function to show/hide cooldown
      @param {boolean} flag - Whether to show the cooldown
    ]]
	function frame:ShowCooldown(flag) cooldown:SetVisible(flag) end
	
	--[[
      Function to make the icon flicker
      This could be improved for better visual feedback
    ]]
	function frame:Flicker()
		cooldownTint:SetShape(path, {type = 'solid', r = 1, g = 1, b = 1, a = .4}, nil)
		cooldownTint:SetVisible(true)		
	end

	--[[
      Function to set GCD (Global Cooldown)
      @param {number} duration - The duration of the GCD
    ]]
	function frame:SetGCD (duration)

		if duration == nil or cooldownActive == true then return end

		local start = inspectTimeFrame()
		local lastRemaining

		local gcdCoRoutine = coroutine.create(function ()
			for idx = 1, 999, 1 do		
				local thisRemaining = duration - (inspectTimeFrame() - start)
				local checkRemaining = mathFloor(thisRemaining * 10) / 10

				if checkRemaining <= 0 then 
					cooldown:SetVisible(false)
					cooldownTint:SetVisible(false)					
					return 9999 
				end

				--if inspectTimeFrame() - start > duration then return 9999 end

				if checkRemaining ~= lastRemaining then					
					cooldown:SetText(tostring(checkRemaining))
				end

				coroutine.yield(idx)
			end
		end)

		cooldownActive = true		
		cooldown:SetVisible(true)
		cooldownTint:SetVisible(true)
		cooldown:SetText(tostring(mathFloor(duration * 10) / 10))

		LibEKL.coroutines.add ({ func = gcdCoRoutine, counter = 999, active = true })
	end	

	--[[
      Function to set cooldown
      @param {string|number} timer - The cooldown timer text or number
      @param {number} percent - The percentage of cooldown remaining
    ]]
	function frame:SetCooldown(timer, percent)
	
		if timer == nil then
			cooldown:SetVisible(false)
			cooldownTint:SetVisible(false)
			cooldownTint:SetShape(path, {type = 'solid', r = 1, g = 1, b = 1, a = .4}, nil)
			cooldown:SetFontColor (1, 1, 1, 1)
			cooldownActive = false
		else
			if cooldownActive == false then
				cooldownActive = true		
				cooldown:SetVisible(true)
				cooldownTint:SetVisible(true)
			end

			if type(timer) == 'number' and tonumber(timer) < 10 then
				cooldown:SetFontColor(1, 0, 0, 1)
			end
			
			cooldown:SetText(timer)
		end		
	end
	
	--[[
      Function to set out-of-range state
      @param {boolean} flag - Whether the ability is out of range
    ]]
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
	
	--[[
      Function to set usable state
      @param {boolean} flag - Whether the ability is usable
    ]]
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
	
	--[[
      Function to check for dropped items/abilities
      Handles the dropping of items or abilities onto the action icon
    ]]
	local function fctCheckDrop ()
	
		if InspectSystemSecure() == true then return end
		local cType, cHeld = InspectCursor()
		
		if cType == 'item' or cType == 'ability' then
			frame:SetItem(cType, cHeld, nil)
			data.actionBarSetup.roles[InspectTEMPORARYRole()].bars[barIndex].slots[buttonIndex] = { itemType = cType, itemKey = cHeld, macroIcon = nil }
		end
		
		Command.Cursor(nil)
	
	end
	
	--[[
      Function to clear the current item
      Clears the current item, ability, or macro from the action icon
    ]]
	function frame:ClearItem()
		
		LibEKL.ui.attachItemTooltip (texture, nil)
		LibEKL.ui.attachAbilityTooltip (texture, nil)
		LibEKL.ui.attachGenericTooltip (texture, nil)
				
		if thisMacroCDType ~= nil then
			LibEKL.cdManager.unsubscribe(thisMacroCDType, thisMacroCDKey)

			data.abilityMap[thisMacroCDKey] = nil
			data.abilityList[thisMacroCDKey] = nil
		elseif thisItemKey ~= nil and thisItemKey ~= 'macro' then
			LibEKL.cdManager.unsubscribe(thisItemType, thisItemKey)

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

		frame:SetOOR(false)
		frame:SetUsable(true)
		frame:SetCooldown(nil)

		if macroFrame then
			macroFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, nil)
		end

        texture:SetTextureAsync("nkUI", EMPTY_FRAME_TEXTURE)
		
	end
	
	function frame:CheckState()
		if thisItemType ~= "ability" then return end

		local err, thisDetails = pcall(InspectAbilityNewDetail, itemKey)

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
			LibEKL.cdManager.subscribe(macroCDType, macroCDKey)

			if data.abilityMap[macroCDKey] == nil then data.abilityMap[macroCDKey] = {} end
			table.insert(data.abilityMap[macroCDKey], frame)
			table.insert(data.abilityList, macroCDKey)
		else
			LibEKL.cdManager.subscribe(thisItemType, thisItemKey)
			if data.abilityMap == nil then data.abilityMap = {} end
			if data.abilityMap[itemKey] == nil then data.abilityMap[itemKey] = {} end
			table.insert(data.abilityMap[itemKey], frame)
			table.insert(data.abilityList, itemKey)
		end
		
		local err, thisDetails, macro
		
		if thisItemType == 'item' then
			err, thisDetails = pcall(InspectItemDetail, itemKey)
			if err and thisDetails ~= nil then
				macro = "use " .. stringGSub(thisDetails.name, "\n", "")
			end
		elseif thisItemType == "ability" then
			err, thisDetails = pcall(InspectAbilityNewDetail, itemKey)

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
			texture:SetTextureAsync("Rift", thisDetails.icon)  
		else
			texture:SetTextureAsync("nkUI", BLANK_TEXTURE)
		end

		if interactive then
		
			if not macroFrame then
				macroFrame = LibEKL.uiCreateFrame("nkFrame", name .. ".macroFrame", uiElements.secureContext)
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

			LibEKL.events.addInsecure(function() macroFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, macro) end, nil, nil)
			macroFrame:SetVisible(true)
			
		elseif macroFrame ~= nil then			
			macroFrame:SetVisible(false)
		end


        local tooltipTarget = texture
		if interactive then tooltipTarget = macroFrame end
						
		if thisItemType == 'item' then
			LibEKL.ui.attachItemTooltip (tooltipTarget, itemKey)
		elseif thisItemType == "ability" then
			LibEKL.ui.attachAbilityTooltip (tooltipTarget, itemKey)
			LibEKL.ui.abilityTooltipSetFont (addonInfo.id, "MontserratSemiBold")
		else -- macro
			LibEKL.ui.attachGenericTooltip (tooltipTarget, "nkUI macro", macro)
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
      @param {string} design - The design to apply
    ]]
	function frame:SetDesign (design)

		if design == nil then design = DEFAULT_DESIGN end
		local setup = data.actionBarDesigns[design] 
		
		path = setup[4]

		local mainColor = data.actionBarColors.mainColor
		local subColor = data.actionBarColors.subColor
		
		local thisStroke = LibEKL.tools.table.copy(setup[6])
		local thisFill = LibEKL.tools.table.copy(setup[5])
		
		thisFill.r, thisFill.g, thisFill.b = subColor.r, subColor.g, subColor.b
		thisFill.a = 0.6
				
		thisStroke.r, thisStroke.g, thisStroke.b = mainColor.r, mainColor.g, mainColor.b
		thisStroke.a = 0.6
		
		frame:SetWidth((setup[3] * thisScale))
		frame:SetHeight((setup[3] * thisScale))
		frame:SetShape(path, thisFill, thisStroke)

        local thisSize = frame:GetWidth() -2

        texture:SetWidth(thisSize)
        texture:SetHeight(thisSize)
		
		thisStroke.r, thisStroke.g, thisStroke.b, thisStroke.a = thisFill.r, thisFill.g, thisFill.b, 1
		
		overlay:SetWidth(thisSize)
        overlay:SetHeight(thisSize)
		overlay:SetShape(path, nil, thisStroke)
		
		oorTint:SetShape(path, {type = 'solid', r = 1, g = 0, b = 0, a = .6}, nil)
        oorTint:SetWidth(thisSize)
        oorTint:SetHeight(thisSize)

		cooldownTint:SetShape(path, {type = 'solid', r = 1, g = 1, b = 1, a = .4}, nil)
        cooldownTint:SetWidth(thisSize)
        cooldownTint:SetHeight(thisSize)
		
		overlay:SetVisible(setup[7])	
				
	end
	
	--[[
      Function to destroy the frame
      Cleans up resources and removes the frame from the UI
    ]]
	function frame:destroy()
	
		local target = texture
		if interactive then target = macroFrame end
					
		if thisItemType == 'item' then
			LibEKL.ui.attachItemTooltip (target, nil)
		elseif thisItemType == 'macro' then
			LibEKL.ui.attachGenericTooltip (target, nil, nil)
		else
			LibEKL.ui.attachAbilityTooltip (target, nil)
		end
		
		texture:destroy()
		LibEKL.uiAddToGarbageCollector ('nkFrame', frame, name)
	end

	--[[
	Function to edit macro
	Opens the macro editor dialog for the current action icon
	]]
	local function fctEditMacro () 
	
		if InspectSystemSecure() == true then return end
		if uiElements.macroEdit == nil then
			uiElements.macroEdit = internalFunc.macroEditDialog(parent)			
		end
		
		uiElements.macroEdit:SetVisible(true)
		uiElements.macroEdit:SetButton(barIndex, buttonIndex)
	
	end

	texture:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)
		frame:SetShape(path, fill, {r = 1, g = 1, b = 1, a = 1, thickness = 1 })
	end, texture:GetName() .. ".UI.Input.Mouse.Cursor.In")

	texture:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)
		frame:SetDesign ()
	end, texture:GetName() .. ".UI.Input.Mouse.Cursor.Out")
	
	--[[
	Attach event handlers
	Sets up mouse event handlers for the action icon
	]]
	texture:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self)
		fctCheckDrop()
	end, texture:GetName() .. ".UI.Input.Mouse.Left.Up")

	texture:EventAttach(Event.UI.Input.Mouse.Middle.Down, function (self)
		if data.actionBarSetup.roles[InspectTEMPORARYRole()].bars[barIndex].interactive == true then
			fctEditMacro()
		else
			local dialog = LibEKL.ui.confirmDialog ('This bar is not flagged as interactive. Do you want to change this bar to interactive mode?', function()
				data.actionBarSetup.roles[InspectTEMPORARYRole()].bars[barIndex].interactive = true
				parent:SetInteractive(true)
				fctEditMacro()
			end)

			dialog:SetFont(addonInfo.id, "MontserratSemiBold")
			dialog:SetEffectGlow({ strength = 3 })
			dialog:SetButtonFont(addonInfo.id, "MontserratSemiBold")
			dialog:SetButtonFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
			dialog:SetButtonLabelColor (data.theme.labelColor)
			dialog:SetButtonBorderColor ({ r = 0, g = 0, b = 0, a = .7, thickness = 1})
			dialog:SetButtonEffect({ strength = 3 })

			dialog:SetColor({	type = "gradientLinear",
								transform = Utility.Matrix.Create(2, 2, -(math.pi / 6), 0, 0), -- Negative angle for opposite direction
								color = {
									data.theme.windowStartColor,
									data.theme.windowEndColor
									}
							},  { r = 0, g = 0, b = 0, a = 1, thickness = 1})
		end
	end, texture:GetName() .. ".UI.Input.Mouse.Middle.Down")
	
	texture:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
        frame:ClearItem()
		data.actionBarSetup.roles[InspectTEMPORARYRole()].bars[barIndex].slots[buttonIndex] = {}
	end, texture:GetName() .. ".UI.Input.Mouse.Right.Down")
	
	return frame

end