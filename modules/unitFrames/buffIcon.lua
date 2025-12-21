local addonInfo, privateVars = ...

---------- init namespace ---------

local data			= privateVars.data
local uiElements	= privateVars.uiElements
local internalFunc	= privateVars.internalFunc
local _events		= privateVars.events
local _ui			= privateVars.ui

---------- init local variables ---------

local InspectBuffDetail = Inspect.Buff.Detail

local stringFormat	= string.format
local mathFloor		= math.floor

-- Cache frequently used functions and values
local _eventHandlers = {}

function uiElements.icon (name, parent)
	
	local icon = EnKai.uiCreateFrame('nkFrame', name, parent)
	
	local border = EnKai.uiCreateFrame('nkFrame', name .. '.border', icon)
	local texture = EnKai.uiCreateFrame('nkTexture', name .. '.texture', icon)
	local effect = EnKai.uiCreateFrame('nkTexture', name .. '.effect', icon)
	
	local timer = EnKai.uiCreateFrame('nkText', name ..'.timer', icon)
	local stack = EnKai.uiCreateFrame('nkText', name ..'.stack', icon)
	
	local label = EnKai.uiCreateFrame('nkText', name .. 'label', icon)
	
	local properties = {}
	local tooltipIcon = nil
	local lastTimer = nil
	local lastStack = nil
	local isBelow10 = false
	local timerVisible = false
	local lastSetup = {}

	function icon:SetValue(property, value)
		properties[property] = value
	end
	
	function icon:GetValue(property)
		return properties[property]
	end
	
	icon:SetValue("name", name)
	icon:SetValue("parent", parent)
	
	icon:SetMouseMasking('limited')
	
	local timerFontSize = 18
	local stackFontSize = 16
	local labelFontSize = 16
	local showBorder = true
	local activeEffect = 'none'
	local scale = 1
	local thisUnitId, thisBuffId, thisBuffType
	local thisName, thisDescription
		
	icon:SetWidth(50)
	icon:SetHeight(50)
	--icon:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, 100)
	
	border:SetPoint("TOPLEFT", icon, "TOPLEFT")
	border:SetWidth(50)
	border:SetHeight(50)
	border:SetBackgroundColor(0, 0, 0, 1)
	border:SetLayer(1)
	
	texture:SetPoint("TOPLEFT", border, "TOPLEFT", 1, 1)
	texture:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, -1)
	texture:SetLayer(2)
	
	timer:SetLayer(4)
	timer:SetFontColor(1, 1, 1, 0)
	timer:SetFontSize(timerFontSize)
	timer:SetTextFont(addonInfo.id, "MontserratSemiBold")
	timer:SetEffectGlow({strength = 3})
	timer:SetPoint("BOTTOMCENTER", border, "BOTTOMCENTER", 0, -2)
	
	stack:SetLayer(4)
	stack:SetFontColor(1, 1, 1, 0)
	stack:SetFontSize(stackFontSize)
	stack:SetTextFont(addonInfo.id, "MontserratSemiBold")
	stack:SetEffectGlow({strength = 3})
	stack:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
		
	label:SetPoint("TOPCENTER", border, "BOTTOMCENTER")
	label:SetFontColor (1, 1, 1, 1)
	label:SetTextFont(addonInfo.id, "Montserrat")
	label:SetFontSize(labelFontSize)
	label:SetHeight(labelFontSize+4)
	label:SetEffectGlow({strength = 3})
	
	effect:SetLayer(3)
	effect:SetVisible(false)
	
	function icon:SetTexture(textureType, texturePath)
		texture:SetTextureAsync(textureType, texturePath)
	end
	
	function icon:SetLabel(text)
		label:ClearWidth()
		label:SetText(text)
	end
	
	--function icon:SetTimer(text)
	--	timer:ClearWidth()
	--	timer:SetText(text)
	--end
	
	function icon:SetStack(text)
		--stack:ClearWidth()
		if text == nil then
			stack:SetText("")
		elseif text ~= lastStack then			
			stack:SetText(tostring(text))
			lastStack = text
		end
	end
	
	function icon:ShowLabel(flag)
		label:SetVisible(flag)
	end
	
	function icon:ShowTimer(flag)
		timer:SetVisible(flag)
	end
	
	function icon:ShowStack(flag)
		stack:SetVisible(flag)
	end
	
	function icon:ShowBorder(flag)
	
		showBorder = flag
		
		effect:ClearAll()
		texture:ClearAll()
	
		if flag == true then
			texture:SetPoint("TOPLEFT", border, "TOPLEFT", 1, 1)
			texture:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, -1)
			
			effect:SetPoint("TOPLEFT", border, "TOPLEFT", 1, 1)
			effect:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, -1)
		else
			texture:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
			texture:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
			
			effect:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
			effect:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
		end
	end
	
	function icon:Setup(newSetup)

		if lastSetup.width ~= newSetup.width then	
			icon:SetWidth(newSetup.width)
			border:SetWidth(newSetup.width)
		end
		
		if lastSetup.height ~= newSetup.height then
			icon:SetHeight(newSetup.height)
			border:SetHeight(newSetup.height)
		end

		if lastSetup.label ~= newSetup.label then		
			label:SetFontSize(newSetup.label)
			label:SetHeight(newSetup.label + 4)
		end
		
		if lastSetup.timer ~= newSetup.timer then		
			timer:SetFontSize(newSetup.timer)
			timer:SetHeight(newSetup.timer + 4)
		end
			
		if lastSetup.stack ~= newSetup.stack then
			stack:SetFontSize(newSetup.stack )
		end

		lastSetup = newSetup
	end
	
	function icon:SetLabelColor(r, g, b, a)
		label:SetFontColor(r, g, b, a)
	end
	
	function icon:SetTimer (newTimer)
		if newTimer then 

			if EnKai.tools.math.round (newTimer, 0) <= 10 then
				if isBelow10 == false then
					timer:SetFontColor(1, 0, 0, 0)
					isBelow10 = true
				end
			elseif isBelow10 == true then
				isBelow10 = false
				timer:SetFontColor(1, 1, 1, 0)
			end

			local unit = "s"
			if newTimer > 3600 then
				newTimer = newTimer / 3600
				unit = "h"
			elseif newTimer > 60 then
				newTimer = newTimer / 60
				unit = "m"
			end

			newTimer = EnKai.tools.math.round (newTimer, 0)

			if newTimer ~= lastTimer then
				--timer:ClearWidth()
				timer:SetText(stringFormat("%d%s", newTimer, unit))

				if timerVisible == false then 
					timer:SetVisible(true)
					timerVisible = true
				end

				lastTimer = newTimer
			end
		else
			if timerVisible == true then 
				timer:SetVisible(true)
				timerVisible = false
			end

			lastTimer = nil
		end
	end

	function icon:Clear()
		
		lastTimer = nil
		timerVisible = false
		isBelow10 = false
		timer:SetFontColor(1, 1, 1, 0)
		icon:SetVisible(false)		
	end

	function icon:SetTimerColor(r, g, b, a, ro, go, bo)
		timer:SetFontColor(r, g, b, a)
		timer:SetEffectGlow({ strength = 5, offsetX = 0, offsetY = 0, blurX = 3, blurY = 3, colorR = ro, colorG = go, colorB = bo })
	end
	
	function icon:SetStackColor(r, g, b, a)
		stack:SetFontColor(r, g, b, a)
		stack:SetEffectGlow({ offsetX = 1, offsetY = 1})
	end
	
	function icon:SetBorderColor(r, g, b, a)
		border:SetBackgroundColor(r, g, b, a)
	end
	
	function icon:SetEffect(newEffect)
		activeEffect = newEffect
	
		if newEffect == nil then
			effect:SetVisible(false)
			return
		end
	
		effect:SetTextureAsync("nkUI", newEffect.texturePath)
		effect:SetAlpha(newEffect.alpha)
		
		effect:ClearAll()
		texture:ClearAll()
		
		if newEffect.replaceBorder == false and showBorder == true then
			effect:SetPoint("TOPLEFT", border, "TOPLEFT", 1, 1)
			effect:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, -1)
			
			texture:SetPoint("TOPLEFT", border, "TOPLEFT", 1, 1)
			texture:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, -1)
			
			border:SetVisible(true)
		else
			effect:SetPoint("TOPLEFT", border, "TOPLEFT")
			effect:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
			
			if newEffect.border == nil then
				texture:SetPoint("TOPLEFT", border, "TOPLEFT", 1, 1)
				texture:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, -1)				
			else
				texture:SetPoint("CENTER", border, "CENTER")			
				local width, height = icon:GetWidth(), icon:GetHeight()
			
				if newEffect.border ~= nil then
					width = mathFloor(width - (newEffect.border * 2 * (50 / width)))
					height = mathFloor(height - (newEffect.border * 2 * (50 / height)))
					
				end
				
				texture:SetWidth(width)
				texture:SetHeight(height)
			end			
			
			border:SetVisible(false)
		end
		
		effect:SetVisible(true)
		
	end
	
	function icon:Recycle()
		icon:SetVisible(false)
	end

	texture:EventAttach(Event.UI.Input.Mouse.Right.Click, function()
        Command.Buff.Cancel(thisBuffId)
    end, name .. ".UI.Input.Mouse.Right.Click")

	function icon:SetBuff(unitType, buffId, buffType)
		thisUnitType, thisBuffId, thisBuffType = unitType, buffId, buffType
	end

	function icon:SetTooltip(name, description)
		--print (name)
		thisName = name
		thisDescription = description
		EnKai.ui.attachGenericTooltip (texture, thisName, thisDescription)
		EnKai.ui.genericTooltipSetFont (addonInfo.id, "MontserratSemiBold")
	end	
	
	return icon
	
end