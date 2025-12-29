--[[
   @module nkUI
   @description Main module for the nkUI addon
   @version 1.0
]]

local addonInfo, privateVars = ...

-- Initialize namespace
if not nkUI then nkUI = {} else return end

-- Initialize private variables
privateVars.data        	= {}
privateVars.internalFunc    = {}
privateVars.uiElements  	= {}
privateVars.events      	= {}

local data        	= privateVars.data
local uiElements  	= privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events     	= privateVars.events

-- Cache frequently used functions and values
local stringFind	= string.find
local mathpi		= math.pi

-- Initialize variables
data.colors = {
    primary	= { r = 1, g = 1, b = 1, a = 1 },
    accent	= { r = 0.1176, g = 0.7490, b = 1, a = 1 },
	callings = { rift = {
					rogue = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = .4, g = .67, b = .05, a = 1, position = 0},  { r = .3, g = .5, b = 0, a = 1, position = 1 }}},
					warrior = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = .4, g = .67, b = .05, a = 1, position = 0},  { r = .3, g = .5, b = 0, a = 1, position = 1 }}},
					cleric = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = .4, g = .67, b = .05, a = 1, position = 0},  { r = .3, g = .5, b = 0, a = 1, position = 1 }}},
					mage = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = .4, g = .67, b = .05, a = 1, position = 0},  { r = .3, g = .5, b = 0, a = 1, position = 1 }}},
					primalist = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = .4, g = .67, b = .05, a = 1, position = 0},  { r = .3, g = .5, b = 0, a = 1, position = 1 }}},
					default = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = .4, g = .67, b = .05, a = 1, position = 0},  { r = .3, g = .5, b = 0, a = 1, position = 1 }}}
				},
				 wow = {
					rogue = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = 1, g = .96, b = .41, a = 1, position = 0},  { r = 1, g = .8, b = .2, a = 1, position = 1 }}},
					warrior = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = .79, g = .61, b = .43, a = 1, position = 0},  { r = .7, g = .5, b = .3, a = 1, position = 1 }}},
					cleric = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = 1, g = 1, b = 1, a = 1, position = 0},  { r = .9, g = .9, b = .9, a = 1, position = 1 }}},
					mage = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = 0.25, g = .78, b = .92, a = 1, position = 0},  { r = 0.1, g = .6, b = .7, a = 1, position = 1 }}},
					primalist = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = 0, g = .44, b = .87, a = 1, position = 0},  { r = 0, g = .3, b = .6, a = 1, position = 1 }}},
					default = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0), color = {{ r = .4, g = .67, b = .05, a = 1, position = 0},  { r = .3, g = .5, b = 0, a = 1, position = 1 }}}
				}},
	ressource = { rift = {
					energy = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = 0.8235, g = 0.3059, b = 0.8627, a = 1, position = 0 },{ r = 0.7, g = 0.2, b = 0.7, a = 1, position = 1 }}},
					power = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = 0.9098, g = 0.8902, b = 0.2196, a = 1, position = 0 }, { r = 0.7, g = 0.6, b = 0.1, a = 1, position = 1 }}},
					charge = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = 0.2824, g = 0.7333, b = 0.6118, a = 1, position = 0 }, { r = 0.15, g = 0.5, b = 0.4, a = 1, position = 1 }}},
					mana = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = 0.2353, g = 0.4784, b = 0.8078, a = 1, position = 0 }, { r = 0.15, g = 0.3, b = 0.5, a = 1, position = 1 }}},
					focus = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = 1, g = 0, b = 0, a = 1, position = 0}, { r = 0, g = 0, b = 0, a = 1, position = .4}, { r = 0, g = .82, b = 1, a = 1, position = 1 }}},
					default = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = .1, g = .1, b = .1, a = 1, position = 0},  { r = .2, g = .2, b = .2, a = 1, position = 1 }}}
				},
				  wow = {
					energy = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = 1, g = .96, b = .41, a = 1, position = 0},  { r = 0.9, g = 0.5, b = 0.2, a = 1, position = 1 }}},
					power = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = 1, g = .5, b = .25, a = 1, position = 0},  { r = .9, g = .4, b = .1, a = 1, position = 1 }}},
					charge = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = .71, g = 1, b = .92, a = 1, position = 0},  { r = .5, g = .8, b = .7, a = 1, position = 1 }}},
					mana = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = 0, g = 0.82, b = 1, a = 1, position = 0},  { r = 0, g = 0.6, b = 0.8, a = 1, position = 1 }}},
					focus = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = 1, g = 0, b = 0, a = 1, position = 0}, { r = 0, g = 0, b = 0, a = 1, position = .4}, { r = 0, g = .82, b = 1, a = 1, position = 1 }}},
					default = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (mathpi / 4), 0, 0), color = {{ r = .1, g = .1, b = .1, a = 1, position = 0}, { r = .2, g = .2, b = .2, a = 1, position = 1 }}}
				}},
	combo = { 	rift = {{r = 1, g = 1, b = 1, a = 1},
						{r = 1, g = 1, b = 1, a = 1},
						{r = 1, g = 1, b = 1, a = 1},
						{r = 1, g = 1, b = 1, a = 1},
						{r = 1, g = 1, b = 1, a = 1}},
				wow = {	{ r = 0.97, g = 0.38, b = 0, a = 1 },    -- First combo point
						{ r = 0.9, g = 0.3, b = 0.1, a = 1 },   -- Second combo point
						{ r = 0.8, g = 0.2, b = 0.2, a = 1 },    -- Third combo point
						{ r = 0.7, g = 0.1, b = 0.3, a = 1 },   -- Fourth combo point
						{ r = 0.6, g = 0.05, b = 0.4, a = 1}}      -- Fifth combo point
			}
}
				
data.uiScale = 1
local thisTutorialVersion = 80


-- Generate UI context

uiElements.contextTooltip = UI.CreateContext("nkUI.Tooltip")
uiElements.contextTooltip:SetStrata('tooltip')
uiElements.contextTooltip:SetLayer(99)

local function animateLogo ()

	local logo = LibEKL.UICreateFrame("nkTexture", "nkUILogo", uiElements.contextTooltip )
	logo:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	logo:SetWidth(256)
	logo:SetHeight(253)
	logo:SetAlpha(0)
	logo:SetTextureAsync("nkUI", "gfx/nkUILogo.png")

	local canvas = LibEKL.UICreateFrame("nkCanvas", "nkUILogo.line", logo)
	canvas:SetPoint("TOPCENTER", logo, "BOTTOMCENTER", 0, -15) -- Position below the logo
	canvas:SetWidth(300)
	canvas:SetHeight(10)
	
	local text = LibEKL.UICreateFrame("nkText", "nkUILogo.text", logo)
	text:SetPoint("TOPCENTER", canvas, "BOTTOMCENTER", 0, 5)
	text:SetFontSize(20)
	text:SetFontColor(1, 1, 1, 1)
	text:SetEffectGlow({strength = 3})
	text:SetText("A modern style UI compilation for RIFT")

	LibEKL.UI.SetFont(text, addonInfo.id, "MontserratBold")
	
	local fillParams = {
		type = "gradientLinear",
		transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0),
		color = {
			{ r = 1, g = 0.8078, b = 0, a = 1, position = 0 },  -- ffce00 at start
			{ r = 1, g = 0.8078, b = 0, a = 1, position = 1 }   -- ffce00 at end
		}
	}
	local path = {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 0}, {xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 1}, {xProportional = 0, yProportional = 0}}
	local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 3 }
	canvas:SetShape(path, fillParams, stroke)

	local animateShow = coroutine.create(
		function ()
			for idx = 1, 100, 1 do
				logo:SetAlpha(idx / 100)
				canvas:SetAlpha(idx / 100)
				text:SetAlpha(idx / 100)
				coroutine.yield(idx)
			end
		end
	)

	local animateShine = coroutine.create(
		function ()
			for idx = 1, 100, 1 do
				local progress = idx / 100
				
				local fillParams = {
					type = "gradientLinear",
					transform = Utility.Matrix.Create(2, 2, (mathpi / 6), 0, 0),
					color = {
						{ r = 1, g = 0.8078, b = 0, a = 1, position = 0 },  -- ffce00 at start
						{ r = 1, g = 1, b = 1, a = 1, position = progress },  -- White at progress position
						{ r = 1, g = 0.8078, b = 0, a = 1, position = 1 }   -- ffce00 at end
					}
				}

				canvas:SetShape(path, fillParams, stroke)
				coroutine.yield(idx)
			end
		end
	)

	local animateHide = coroutine.create(
		function ()
			for idx = 1, 100, 1 do
				logo:SetAlpha((100 - idx) / 100)
				canvas:SetAlpha((100 - idx) / 100)
				text:SetAlpha((100 - idx) / 100)
				coroutine.yield(idx)
			end
		end
	)

	LibEKL.Coroutines.Add ({ func = animateShow, counter = 100, active = true, callBack = function ()
		LibEKL.Coroutines.Add ({ func = animateShine, counter = 100, active = true, callBack = function ()
			LibEKL.Coroutines.Add ({ func = animateHide, counter = 100, active = true, callBack = function ()
				--logo:destroy()1
				--canvas:destroy()
			end})
		end})
	end})

end

--[[
   @function commandHandler
   @description Handles slash commands for the addon
   @param {string} commandline - The command entered by the user
   @return {nil}
]]
local function commandHandler (commandline)

	if commandline == nil then return end
		
	if stringFind(commandline, "bag") ~= nil then
		if nkUISetup and nkUISetup.modules and nkUISetup.modules.oneBag and nkUISetup.modules.oneBag.activate then
			internalFunc.oneBagInit()
		end
	else
		internalFunc.setupInit ()
	end

end

--[[
   @function _main
   @description Main initialization function for the nkUI addon
   @param {any} _ - Unused parameter
   @param {string} addon - The addon identifier
   @return {nil}
]]
local function initializeAddon(_, addon)
	if addon == addonInfo.identifier then
		table.insert(Command.Slash.Register("nkui"), {commandHandler, "nkUI", "commandHandler"})
		
        LibEKL.UI.registerFont(addonInfo.id, "Montserrat", "fonts/Montserrat-Regular.ttf")
        LibEKL.UI.registerFont(addonInfo.id, "MontserratSemiBold", "fonts/Montserrat-SemiBold.ttf")
		LibEKL.UI.registerFont(addonInfo.id, "MontserratBold", "fonts/Montserrat-Bold.ttf")

        LibEKL.UI.registerFont(addonInfo.id, "FiraMonoBold", "fonts/FiraMono-Bold.ttf")
        LibEKL.UI.registerFont(addonInfo.id, "FiraMonoMedium", "fonts/FiraMono-Medium.ttf")
        LibEKL.UI.registerFont(addonInfo.id, "FiraMono", "fonts/FiraMono-Regular.ttf")

		Command.Event.Attach(Event.Unit.Availability.Full, function()
			LibEKL.Unit.init()			
			LibEKL.Inventory.Init(false, false)

			internalFunc.setupDefaults()

			if nkUISetup.tutorialVersion == nil or nkUISetup.tutorialVersion < thisTutorialVersion then 				
    			nkUISetup.tutorialVersion = thisTutorialVersion
				internalFunc.tutorial()
			end

			if nkUISetup and nkUISetup.modules then
				if nkUISetup.modules.tooltip and nkUISetup.modules.tooltip.activate then
					internalFunc.tooltip()
				end

				if nkUISetup.modules.lowerBar and nkUISetup.modules.lowerBar.activate then
					internalFunc.lowerBarInit()
				end

				if nkUISetup.modules.unitFrames and nkUISetup.modules.unitFrames.activate then
					internalFunc.uiFrames()
				end	
	LibEKL.eventHandlers["LibEKL.InventoryManager"]["Update"], LibEKL.Events["LibEKL.InventoryManager"]["Update"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.InventoryManagerUpdate")


				if nkUISetup.modules.actionBars and nkUISetup.modules.actionBars.activate then
					internalFunc.uiActionBars()
				end				
		
				if nkUISetup.modules.sct and nkUISetup.modules.sct.activate then
					internalFunc.sctInit()
				end

				if nkUISetup.modules.oneBag and nkUISetup.modules.oneBag.activate then
					
					UI.Native.Bank:EventAttach(Event.UI.Native.Loaded, function()
						if uiElements.oneBag == nil then internalFunc.oneBagInit() end

						uiElements.oneBag:SetVisible(UI.Native.Bank:GetLoaded())
					end, "nkUI.OneBag.Native.Bank.Loaded")

					UI.Native.BagInventory1:EventAttach(Event.UI.Native.Loaded, function()
					if uiElements.oneBag == nil then internalFunc.oneBagInit() end

						uiElements.oneBag:SetVisible(UI.Native.BagInventory1:GetLoaded())
					end, "nkUI.OneBag.Native.Bag.Loaded")
				end
				
				if nkUISetup.modules.questtracker and nkUISetup.modules.questtracker.activate then
					internalFunc.questTrackerInit(true)
				end

				--internalFunc.chat ()
				--internalFunc.questLogInit()							
			end

            Command.Event.Detach(Event.Unit.Availability.Full, nil, "nkUI.Unit.Availability.Full")

			if nkUISetup.showLogo then animateLogo () end

		end, "nkUI.Unit.Availability.Full")
		
		LibEKL.manager.RegisterButton("nkUI", addonInfo.id, "gfx/minimapIcon.png", internalFunc.setupInit)

		Command.Console.Display("general", true, string.format(privateVars.langTexts.startUp, addonInfo.toc.Version), true)		
		Command.Console.Display("general", true, privateVars.langTexts.commandline, true)

		LibEKL.version.init(addonInfo.toc.Identifier, addonInfo.toc.Version)
	end  
end

-- Startup events
Command.Event.Attach(Event.Addon.SavedVariables.Load.End, initializeAddon, "nkUI.SavedVariables.Load.End")
