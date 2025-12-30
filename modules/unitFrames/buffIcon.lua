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

local LibEKLToolsMathRound = LibEKL.Tools.Math.Round

-- Cache frequently used functions and values
local _eventHandlers = {}

function uiElements.icon (name, parent)
	
	local icon = LibEKL.UICreateFrame('nkFrame', name, parent)
	
	local border = LibEKL.UICreateFrame('nkFrame', name .. '.border', icon)
	local texture = LibEKL.UICreateFrame('nkTexture', name .. '.texture', icon)
	
	local timer = LibEKL.UICreateFrame('nkText', name ..'.timer', icon)
	local stack = LibEKL.UICreateFrame('nkText', name ..'.stack', icon)
		
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
	local showBorder = true
	local scale = 1
	local thisBuffId
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
		
	function icon:SetTexture(textureType, texturePath)
		texture:SetTextureAsync(textureType, texturePath)
	end
	
	function icon:SetStack(text)
		--stack:ClearWidth()
		if text == nil then
			stack:SetText("")
		elseif text ~= lastStack then			
			stack:SetText(tostring(text))
			lastStack = text
		end
	end
		
	function icon:ShowTimer(flag)
		timer:SetVisible(flag)
	end
	
	function icon:ShowStack(flag)
		stack:SetVisible(flag)SetAlpha
	end
	
	function icon:ShowBorder(flag)
	
		showBorder = flag
		
		texture:ClearAll()
	
		if flag == true then
			texture:SetPoint("TOPLEFT", border, "TOPLEFT", 3, 3)
			texture:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -3, -3)
		else
			texture:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
			texture:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
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
		
		if lastSetup.timer ~= newSetup.timer then		
			timer:SetFontSize(newSetup.timer)
			timer:SetHeight(newSetup.timer + 4)
		end
			
		if lastSetup.stack ~= newSetup.stack then
			stack:SetFontSize(newSetup.stack )
		end

		lastSetup = newSetup
	end
		
	function icon:SetTimer (newTimer)
		if newTimer then

			local roundedTimer = LibEKLToolsMathRound (newTimer, 0)
			if roundedTimer ~= lastTimer then

				if roundedTimer <= 10 then
					if isBelow10 == false then
						timer:SetFontColor(1, 0, 0, 0)
						isBelow10 = true
					end
				elseif isBelow10 == true then
					isBelow10 = false
					timer:SetFontColor(1, 1, 1, 0)
				end

				local thisTimer = newTimer

				local unit = "s"
				if thisTimer > 3600 then
					thisTimer = thisTimer / 3600
					unit = "h"
				elseif thisTimer > 60 then
					thisTimer = thisTimer / 60
					unit = "m"
				end

				thisTimer = LibEKLToolsMathRound (thisTimer, 0)			
				timer:SetText(stringFormat("%d%s", thisTimer, unit))

				if timerVisible == false then 
					timer:SetVisible(true)
					timerVisible = true
				end

				lastTimer = thisTimer
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
		
	
	function icon:Recycle()
		icon:SetVisible(false)
	end

	texture:EventAttach(Event.UI.Input.Mouse.Right.Click, function()
        Command.Buff.Cancel(thisBuffId)
    end, name .. ".UI.Input.Mouse.Right.Click")

	function icon:SetBuff(buffId)
		thisBuffId = buffId
	end

	function icon:SetTooltip(name, description)
		--print (name)
		thisName = name
		thisDescription = description
		LibEKL.UI.attachGenericTooltip (texture, thisName, thisDescription)
		LibEKL.UI.genericTooltipSetFont (addonInfo.id, "MontserratSemiBold")
	end	
	
	return icon
	
end