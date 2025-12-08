local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

local inspectTimeFrame 			= Inspect.Time.Frame
local InspectItemDetail			= Inspect.Item.Detail
local InspectSystemSecure		= Inspect.System.Secure
local InspectCursor				= Inspect.Cursor
local InspectTEMPORARYRole		= Inspect.TEMPORARY.Role
local InspectAbilityNewDetail	= Inspect.Ability.New.Detail

local stringGSub        = string.gsub

---------- init global variables ---------


---------- init local variables ---------

function uiElements.actionIcon(name, parent, barIndex, buttonIndex)

	local frame = EnKai.uiCreateFrame("nkCanvas", name, parent)
	
	local texture, oorTint, cooldownTint, cooldown, macroFrame, overlay
	local thisItemKey, thisItemType, thisMacroIcon, thisMacroCDType, thisMacroCDKey

	local cooldownActive = false
	local interactive = false
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
	texture:SetPoint("CENTER", frame, "CENTER", 1, 1)
	texture:SetLayer(1)
	texture:SetMouseMasking("limited")
	
	overlay = EnKai.uiCreateFrame("nkCanvas", name .. ".overlay", frame)
	overlay:SetPoint("CENTER", frame, "CENTER", 1, 1)
	overlay:SetShape(path, nil, {r = 0, g = 0, b = 0, a = 1, thickness = 5 })
	overlay:SetLayer(2)
    overlay:SetVisible(false)
	
	oorTint = EnKai.uiCreateFrame("nkCanvas", name .. ".oorTint", frame)
	oorTint:SetVisible(false)
	oorTint:SetPoint("CENTER", overlay, "CENTER")
	oorTint:SetLayer(4)
	
	cooldownTint = EnKai.uiCreateFrame("nkCanvas", name .. ".cooldownTint", frame)
	cooldownTint:SetVisible(false)
	cooldownTint:SetPoint("CENTER", overlay, "CENTER")
	cooldownTint:SetLayer(5)
	
	cooldown = EnKai.uiCreateFrame("nkText", name .. '.cooldown', frame)
	cooldown:SetVisible(false)
	cooldown:SetFontSize(18)
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

		local start = inspectTimeFrame()

		local gcdCoRoutine = coroutine.create(function ()
			for idx = 1, 100, 1 do		
				local remaining = duration - (inspectTimeFrame() - start)
				if inspectTimeFrame() - start > duration then return 9999 end
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
	
		if InspectSystemSecure() == true then return end
		local cType, cHeld = InspectCursor()
		
		if cType == 'item' or cType == 'ability' then
			frame:SetItem(cType, cHeld, nil)
			data.actionBarSetup.roles[InspectTEMPORARYRole()].bars[barIndex].slots[buttonIndex] = { itemType = cType, itemKey = cHeld, macroIcon = nil }
		end
		
		Command.Cursor(nil)
	
	end
	
	function frame:ClearItem()
		
		EnKai.ui.attachItemTooltip (texture, nil)
		EnKai.ui.attachAbilityTooltip (texture, nil)
		EnKai.ui.attachGenericTooltip (texture, nil)
				
		if thisMacroCDType ~= nil then
			EnKai.cdManager.unsubscribe(thisMacroCDType, thisMacroCDKey)

			data.abilityMap[thisMacroCDKey] = nil
			data.abilityList[thisMacroCDKey] = nil
		elseif thisItemKey ~= nil and thisItemKey ~= 'macro' then
			EnKai.cdManager.unsubscribe(thisItemType, thisItemKey)

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

		if macroFrame then
			macroFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, nil)
		end

        texture:SetTextureAsync("nkUI", "gfx/emptyFrame.png")  
		
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
			err, data = pcall(InspectItemDetail, itemKey)
			if err and data ~= nil then
				macro = "use " .. stringGSub(data.name, "\n", "")
			end
		elseif thisItemType == "ability" then
			err, data = pcall(InspectAbilityNewDetail, itemKey)

			if err and data ~= nil then
				frame:SetOOR(data.outOfRange)
				frame:SetUsable(not data.unusable)
				macro = "cast " .. stringGSub(data.name, "\n", "")
			end
		else -- macro
			macro = string.gsub(thisItemKey, "\r", "\n")
			err = true
			data = { icon = macroIcon }
		end
			
		if err and data ~= nil and data.icon ~= nil then
			texture:SetTextureAsync("Rift", data.icon)  
		else
			texture:SetTextureAsync("nkUI", "gfx/equipslot_blank")  
		end

		if interactive then
		
			if not macroFrame then
				macroFrame = EnKai.uiCreateFrame("nkFrame", name .. ".macroFrame", uiElements.secureContext)
				macroFrame:SetPoint("CENTER", frame, "CENTER", 1, 1)
				macroFrame:SetSecureMode("restricted")
				macroFrame:SetMouseMasking("limited")
				--macroFrame:SetBackgroundColor(1,0,0,1)
				
				local thisSize = frame:GetWidth() -2
				macroFrame:SetWidth(thisSize)
				macroFrame:SetHeight(thisSize)
				
				macroFrame:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self)
					_checkDrop()
				end, macroFrame:GetName() .. ".UI.Input.Mouse.Left.Up")
			end

			EnKai.events.addInsecure(function() macroFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, macro) end, nil, nil)
			macroFrame:SetVisible(true)
			
		elseif macroFrame ~= nil then			
			macroFrame:SetVisible(false)
		end


        local tooltipTarget = texture
						
		if thisItemType == 'item' then
			EnKai.ui.attachItemTooltip (tooltipTarget, itemKey)
		elseif thisItemType == "ability" then
			EnKai.ui.attachAbilityTooltip (tooltipTarget, itemKey)
			EnKai.ui.abilityTooltipSetFont (addonInfo.id, "MontserratSemiBold")
		else -- macro
			EnKai.ui.attachGenericTooltip (tooltipTarget, "nkUI macro", macro)
		end
	end
	
	function frame:GetCooldown() return cooldown end

	function frame:SetInteractive(flag, doUpdate) 
		interactive = flag 
		if doUpdate then frame:SetItem(thisItemType, thisItemKey, nil) end
	end
	
    function frame:Scale (newScale)

		thisScale = newScale
		frame:SetDesign('default')

	end

	function frame:SetDesign (design)

		if design == nil then design = 'default' end
		local setup = data.actionBarDesigns[design] 
		
		path = setup[4]

		local mainColor = data.actionBarColors.mainColor
		local subColor = data.actionBarColors.subColor
		
		local thisStroke = EnKai.tools.table.copy(setup[6])
		local thisFill = EnKai.tools.table.copy(setup[5])
		
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
		
		texture:destroy()
		EnKai.uiAddToGarbageCollector ('nkFrame', frame, name)
	end

	local function _editMacro () 
	
		if InspectSystemSecure() == true then return end
		if uiElements.macroEdit == nil then
			uiElements.macroEdit = _internal.macroEditDialog(parent)			
		end
		
		uiElements.macroEdit:SetVisible(true)
		uiElements.macroEdit:SetButton(barIndex, buttonIndex)
	
	end
	
	texture:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self)
		_checkDrop()
	end, texture:GetName() .. ".UI.Input.Mouse.Left.Up")

	texture:EventAttach(Event.UI.Input.Mouse.Middle.Down, function (self)
		if data.actionBarSetup.roles[InspectTEMPORARYRole()].bars[barIndex].interactive == true then
			_editMacro()
		else
			EnKai.ui.confirmDialog ('This bar is not flagged as interactive. Do you want to change this bar to interactive mode?', function()
				data.actionBarSetup.roles[InspectTEMPORARYRole()].bars[barIndex].interactive = true
				parent:SetInteractive(true)
				_editMacro()
			end)
		end
	end, texture:GetName() .. ".UI.Input.Mouse.Middle.Down")
	
	texture:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
        frame:ClearItem()
		data.actionBarSetup.roles[InspectTEMPORARYRole()].bars[barIndex].slots[buttonIndex] = {}
	end, texture:GetName() .. ".UI.Input.Mouse.Right.Down")
	
	return frame

end