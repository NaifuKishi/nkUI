local addonInfo, privateVars = ...

---------- init namespace ---------

local data			= privateVars.data
local uiElements	= privateVars.uiElements
local _internal		= privateVars.internal
local _events		= privateVars.events
local _ui			= privateVars.ui
local oFuncs		= privateVars.oFuncs

---------- init local variables ---------

local InspectBuffDetail = Inspect.Buff.Detail

local stringFormat	= string.format
local mathFloor		= math.floor

-- Cache frequently used functions and values
local _eventHandlers = {}

---------- init variables ---------

---------- local function block ---------

---------- addon internal function block ---------

privateVars.effects = {
	gloss = { alpha = 0.6, texturePath = 'gfx/iconDesignGloss.png', replaceBorder = false },
	round = { alpha = 0.6, texturePath = 'gfx/iconDesignRound.png', replaceBorder = false },
	basic = { alpha = 0.5, texturePath = 'gfx/iconDesignBasic.png', replaceBorder = false },
	chrome = { alpha = 1, texturePath = 'gfx/iconDesignChrome.png', replaceBorder = true, border = 7},
	roundedCorners = { alpha = 1, texturePath = 'gfx/iconDesignRoundedCorners.png', replaceBorder = true, border = 1},
}

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
	local thisUnitId, thisBuffId
		
	icon:SetWidth(50)
	icon:SetHeight(65)
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
	timer:SetEffectGlow({strength = 2})
	timer:SetPoint("BOTTOMCENTER", border, "BOTTOMCENTER", 0, -2)
	
	stack:SetLayer(4)
	stack:SetFontColor(1, 1, 1, 0)
	stack:SetFontSize(stackFontSize)
	stack:SetTextFont(addonInfo.id, "MontserratSemiBold")
	stack:SetEffectGlow({strength = 1})
	stack:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
		
	label:SetPoint("TOPCENTER", border, "BOTTOMCENTER")
	label:SetFontColor (1, 1, 1, 1)
	label:SetTextFont(addonInfo.id, "Montserrat")
	label:SetFontSize(labelFontSize)
	label:SetHeight(labelFontSize+4)
	
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
		stack:ClearWidth()
		if text == nil then
			stack:SetText("")
		else
			stack:SetText(tostring(text))
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
	
		icon:SetWidth(newSetup.width)
		icon:SetHeight(newSetup.height)
		
		border:SetWidth(newSetup.width)
		border:SetHeight(newSetup.height)
		
		label:SetFontSize(newSetup.label)
		label:SetHeight(newSetup.label + 4)
		
		timer:SetFontSize(newSetup.timer)
		timer:SetHeight(newSetup.timer + 4)
		
		stack:SetFontSize(newSetup.stack )
	end
	
	function icon:SetLabelColor(r, g, b, a)
		label:SetFontColor(r, g, b, a)
	end
	
	function icon:SetTimer (newTimer)
		if newTimer then 

			if mathFloor(newTimer) <= 10 then
				timer:SetFontColor(1, 0, 0, 0)				
			else
				timer:SetFontColor(1, 1, 1, 0)
			end

			local unit = "s"
			if newTimer > 3600 then
				newTimer = mathFloor(newTimer / 3600)
				unit = "h"
			elseif newTimer > 60 then
				newTimer = mathFloor(newTimer / 60)
				unit = "m"
			end			

			timer:ClearWidth()
			timer:SetText(stringFormat("%d%s", newTimer, unit))
			timer:SetVisible(true)
		else
			timer:SetVisible(false)
		end
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

	icon.Event.MouseIn =
		function()		
			icon:ShowTooltip()
		end

	icon.Event.MouseOut =
		function()
			icon:HideTooltip(thisBuffId)
		end

	icon.Event.RightClick =
		function()
			Command.Buff.Cancel(thisBuffId)
		end

	function icon:SetBuff(unitType, buffId)
		thisUnitType, thisBuffId = unitType, buffId
	end

	function icon:ShowTooltip()
		if thisBuffId then
			local details = InspectBuffDetail(thisUnitType, thisBuffId) -- this is a workaround for a bug I need to figure out some time
			if details then Command.Tooltip(thisUnitType, thisBuffId) end
		end
	end

	function icon:HideTooltip(buffId)
		Command.Tooltip(nil)
	end

	
	return icon
	
end