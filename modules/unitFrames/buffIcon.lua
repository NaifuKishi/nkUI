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
	
	local path = {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 0}, {xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 1}, {xProportional = 0, yProportional = 0}}
	local fill
	local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 3 }
	local thisTexture

	local icon = LibEKL.UICreateFrame('nkCanvas', name, parent)
	
	--local border = LibEKL.UICreateFrame('nkFrame', name .. '.border', icon)
	--local texture = LibEKL.UICreateFrame('nkTexture', name .. '.texture', icon)
	
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
	local scale = 1
	local thisBuffId
	local thisName, thisDescription
		
	icon:SetWidth(50)
	icon:SetHeight(50)
	--icon:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, 100)
		
	timer:SetLayer(4)
	timer:SetFontColor(1, 1, 1, 0)
	timer:SetFontSize(timerFontSize)
	timer:SetTextFont(addonInfo.id, "MontserratSemiBold")
	timer:SetEffectGlow({strength = 3})
	timer:SetPoint("BOTTOMCENTER", icon, "BOTTOMCENTER", 0, -2)
	
	stack:SetLayer(4)
	stack:SetFontColor(1, 1, 1, 0)
	stack:SetFontSize(stackFontSize)
	stack:SetTextFont(addonInfo.id, "MontserratSemiBold")
	stack:SetEffectGlow({strength = 3})
	stack:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
		
	function icon:SetTexture(textureType, texturePath)
		thisTexture = texturePath
		--texture:SetTextureAsync(textureType, texturePath)
		local width = icon:GetWidth()
		fill = { type = "texture", source = "Rift", texture = thisTexture, transform = Utility.Matrix.Create(1 / width * 32, 1 / width * 34, 0, 0, 0) }
        icon:SetShape(path, fill, stroke)
	end
	
	function icon:SetStack(text)
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
		stack:SetVisible(flag)
	end
	
	function icon:Setup(newSetup)
		
		local sizeUpdate = false

		if lastSetup.width ~= newSetup.width then	
			icon:SetWidth(newSetup.width)
			sizeUpdate = true
		end
		
		if lastSetup.height ~= newSetup.height then
			icon:SetHeight(newSetup.height)
			sizeUpdate = true
		end

		if sizeUpdate and thisTexture then
			local width = icon:GetWidth()
			fill = { type = "texture", source = "Rift", texture = thisTexture, transform = Utility.Matrix.Create(1 / width * 32, 1 / width * 34, 0, 0, 0) }
        	icon:SetShape(path, fill, stroke)
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
		if stroke then
			local lastThickness = stroke.thickness
			stroke = {r = r, g = g, b = b, a = a, thickness = lastThickness }
		end
	end
	
	function icon:SetBorder(newBorder)
		stroke.thickness = newBorder
	end

	icon:EventAttach(Event.UI.Input.Mouse.Right.Click, function()
        Command.Buff.Cancel(thisBuffId)
    end, name .. ".UI.Input.Mouse.Right.Click")

	function icon:SetBuff(buffId)
		thisBuffId = buffId
	end

	function icon:SetTooltip(name, description)
		thisName = name
		thisDescription = description
		LibEKL.UI.attachGenericTooltip (icon, thisName, thisDescription)
		LibEKL.UI.genericTooltipSetFont (addonInfo.id, "MontserratSemiBold")
	end	
	
	return icon
	
end