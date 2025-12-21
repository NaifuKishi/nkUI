local addonInfo, privateVars = ...

---------- init namespace ---------

local data			= privateVars.data
local uiElements	= privateVars.uiElements
local internalFunc	= privateVars.internalFunc
local _events		= privateVars.events
local _ui			= privateVars.ui

local mathpi		= math.pi

---------- init local variables ---------

local _eventHandlers = {}

---------- init variables ---------

local name = "uiCastBars"

---------- local function block ---------

---------- addon internal function block ---------

function internalFunc.createCastBar (unitType, setup)

	local thisName = name .. "." .. unitType

	local castbar =  EnKai.uiCreateFrame("nkFrame", thisName .. ".castBar", uiElements.secureContext)
	castbar:SetVisible(false)
	castbar:SetWidth(setup.width)
	castbar:SetHeight(setup.height)
	castbar:SetBackgroundColor(0, 0, 0, 1)
	
	castbar:SetPoint("CENTER", UIParent, "CENTER", setup.x, setup.y)		

	local castbarFill = EnKai.uiCreateFrame("nkCanvas", thisName .. ".castBar.Inner", castbar)
	castbarFill:SetPoint("CENTERLEFT", castbar, "CENTERLEFT", 1, 0)
	castbarFill:SetHeight(setup.height-2)
	castbarFill:SetLayer(1)
	
	local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1 }
    local path = {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }  

	local color = { interruptible 	= {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = 0.1, g = 0.5, b = 0.8, a = 1, position = 0},  { r = 0.1, g = 0.4, b = 0.6, a = 1, position = 1 }}},
				  	uninterruptible = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = 0.8, g = 0.6, b = 0.2, a = 1, position = 0},  { r = 0.6, g = 0.4, b = 0.1, a = 1, position = 1 }}}
				}
	
	--castbarFill:SetShape (path, color, stroke)

	local castBarText = EnKai.uiCreateFrame("nkText", thisName .. ".castBar.Text", castbar)
	castBarText:SetPoint("CENTER", castbar, "CENTER")
	castBarText:SetFontSize(setup.fontSizes.text)
	castBarText:SetFontColor (1, 1, 1, 1)
	castBarText:SetEffectGlow({ strength = 3})
	castBarText:SetTextFont(addonInfo.id, "Montserrat")
	castBarText:SetLayer(2)

	local castBarTimer = EnKai.uiCreateFrame("nkText", thisName .. ".castBar.Timerr", castbar)
	castBarTimer:SetPoint("CENTERRIGHT", castbar, "CENTERRIGHT")
	castBarTimer:SetFontSize(setup.fontSizes.timer)
	castBarTimer:SetFontColor (1, 1, 1, 1)
	castBarTimer:SetEffectGlow({ strength = 3})
	castBarTimer:SetTextFont(addonInfo.id, "Montserrat")
	castBarTimer:SetLayer(2)
	
	function castbar:SetTimer (remaining, duration)
		local percent = 1 / duration * (duration - remaining)
		castbarFill:SetWidth((setup.width -2) * percent)		
		castBarTimer:SetText(string.format("%.1f", remaining))
	end

	function castbar:SetSpell(spellname)
		castBarText:ClearWidth()
		castBarText:SetText(spellname)

		if castBarText:GetWidth() > setup.width then
			castBarText:SetText(internalFunc.shortenName (spellname, 10))
		end
	end

	function castbar:SetInterruptible(flag)
		if flag then
			castbarFill:SetShape (path, color.interruptible, stroke)
		else
			castbarFill:SetShape (path, color.uninterruptible, stroke)
		end
	end

	function castbar:Redraw()
		castbar:SetTimer(1, 99)
		castbar:SetSpell("Sample spell")

		castbar:SetWidth(setup.width)
		castbar:SetHeight(setup.height)
		castbarFill:SetHeight(setup.height-2)
		castBarText:SetFontSize(setup.fontSizes.text)
		castBarTimer:SetFontSize(setup.fontSizes.timer)
	end

	return castbar

end
