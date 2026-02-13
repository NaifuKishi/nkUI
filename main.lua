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

local inspectTimeFrame	= Inspect.Time.Frame

local stringFind	= string.find
local stringFormat	= string.format
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
local thisTutorialVersion = 125


-- Generate UI context

uiElements.contextTooltip = UI.CreateContext("nkUI.Tooltip")
uiElements.contextTooltip:SetStrata('tooltip')
uiElements.contextTooltip:SetLayer(99)

local function animateLogo ()

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

	if uiElements.logo == nil then
		uiElements.logo = LibEKL.UICreateFrame("nkTexture", "nkUILogo", uiElements.contextTooltip )
	
		uiElements.logo:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		uiElements.logo:SetWidth(256)
		uiElements.logo:SetHeight(253)
		uiElements.logo:SetAlpha(0)
		uiElements.logo:SetTextureAsync("nkUI", "gfx/nkUILogo.png")

		uiElements.logoCanvas = LibEKL.UICreateFrame("nkCanvas", "nkUILogo.line", uiElements.logo)
		uiElements.logoCanvas:SetPoint("TOPCENTER", uiElements.logo, "BOTTOMCENTER", 0, -15) -- Position below the logo
		uiElements.logoCanvas:SetWidth(300)
		uiElements.logoCanvas:SetHeight(10)
		
		uiElements.logoText = LibEKL.UICreateFrame("nkText", "nkUILogo.text", uiElements.logo)
		uiElements.logoText:SetPoint("TOPCENTER", uiElements.logo, "BOTTOMCENTER", 0, 5)
		uiElements.logoText:SetFontSize(20)
		uiElements.logoText:SetFontColor(1, 1, 1, 1)
		uiElements.logoText:SetEffectGlow({strength = 3})
		uiElements.logoText:SetText(privateVars.langTexts.nkUISubTitle)

		LibEKL.UI.SetFont(uiElements.logoText, addonInfo.id, "MontserratBold")

		uiElements.logoCanvas:SetShape(path, fillParams, stroke)			
	else
		uiElements.logo:SetVisible(true)
		uiElements.logoCanvas:SetVisible(true)
		uiElements.logoText:SetVisible(true)
	end

	local animateShow = coroutine.create(
		function ()
			for idx = 1, 100, 1 do
				uiElements.logo:SetAlpha(idx / 100)
				uiElements.logoCanvas:SetAlpha(idx / 100)
				uiElements.logoText:SetAlpha(idx / 100)
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

				uiElements.logoCanvas:SetShape(path, fillParams, stroke)
				coroutine.yield(idx)
			end
		end
	)

	local animateHide = coroutine.create(
		function ()
			for idx = 1, 100, 1 do
				uiElements.logo:SetAlpha((100 - idx) / 100)
				uiElements.logoCanvas:SetAlpha((100 - idx) / 100)
				uiElements.logoText:SetAlpha((100 - idx) / 100)
				coroutine.yield(idx)
			end
		end
	)

	LibEKL.Coroutines.Add ({ func = animateShow, counter = 100, active = true, callBack = function ()
		LibEKL.Coroutines.Add ({ func = animateShine, counter = 100, active = true, callBack = function ()
			LibEKL.Coroutines.Add ({ func = animateHide, counter = 100, active = true, callBack = function ()
				uiElements.logo:SetVisible(false)
				uiElements.logoCanvas:SetVisible(false)
				uiElements.logoText:SetVisible(false)
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
	elseif stringFind(commandline, "logo") then
		LibEKL.Events.AddInsecure(animateLogo, inspectTimeFrame())
	elseif stringFind(commandline, "qlog") then
		internalFunc.questLogInit()
	elseif stringFind(commandline, "map") then
		if uiElements.mapUI == nil then return end

		if stringFind(commandline, "toggle") ~= nil then 
			uiElements.mapUI:ToggleMinMax(true)
		elseif stringFind(commandline, "debug") ~= nil and nkDebug then
			if uiElements.mapDebugPanel == nil then 
				uiElements.mapDebugPanel = internalFunc.mapDebugPanel()
			else
				uiElements.mapDebugPanel:SetVisible(not uiElements.mapDebugPanel:GetVisible())
			end
			
			local mapInfo = uiElements.mapUI:GetMapInfo()
			uiElements.mapDebugPanel:SetCoord(mapInfo.x1, mapInfo.x2, mapInfo.y1, mapInfo.y2)
			
		elseif stringFind(commandline, "show") ~= nil then
			internalFunc.mapShowHide()
		elseif stringFind(commandline, "add") ~= nil then
			local thisCommand = EnKai.strings.split(commandline, " ")
			
			if #thisCommand < 4 then
				EnKai.tools.error.display (addonInfo.identifier,  privateVars.langTexts.errorAddCommand, 2)
			else
				
				internalFunc.mapAddCustomPoint(tonumber(thisCommand[2]), tonumber(thisCommand[3]), EnKai.strings.right(commandline, thisCommand[3]))
			end
		elseif stringFind(commandline, "clear") ~= nil then
			internalFunc.mapClearCustomPoints()
		end
	else
		internalFunc.setupInit ()
	end

end

local function _fctProcessMessage(_, from, type, channel, identifier, msgData)

	if identifier ~= "nkUI.version" then return end

	if msgData == "getVersion" then
		local msgString = stringFormat("info=%s", addonInfo.toc.Version)
		Command.Message.Send(from, "nkUI.version", msgString, function() end)
	elseif stringFind(msgData, "info=") == 1 then
		local version = LibEKL.strings.right (msgData, "info=")         
		if version == nil then return end
		if data.versionCache == nil then data.versionCache = {} end
		data.versionCache[from] = version
	end

end

-------------------- STARTUP EVENTS --------------------

--[[
   @function _main
   @description Main initialization function for the nkUI addon
   @param {any} _ - Unused parameter
   @param {string} addon - The addon identifier
   @return {nil}
]]
local function initializeAddon(_, addon)

	if addon == addonInfo.identifier then

		if LibEKL.Tools.Lang.GetLanguageShort() == "RU" then
			return
		end

		table.insert(Command.Slash.Register("nkui"), {commandHandler, "nkUI", "commandHandler"})		
		
        LibEKL.UI.registerFont(addonInfo.id, "Montserrat", "fonts/Montserrat-Regular.ttf")
		LibEKL.UI.registerFont(addonInfo.id, "MontserratItalic", "fonts/Montserrat-Italic.ttf")        
		LibEKL.UI.registerFont(addonInfo.id, "MontserratSemiBold", "fonts/nkUI-Montserrat-SemiBold.ttf")
		LibEKL.UI.registerFont(addonInfo.id, "MontserratSemiBoldItalic", "fonts/Montserrat-SemiBoldItalic.ttf")
		LibEKL.UI.registerFont(addonInfo.id, "MontserratBold", "fonts/Montserrat-Bold.ttf")
		LibEKL.UI.registerFont(addonInfo.id, "MontserratExtraBold", "fonts/Montserrat-ExtraBold.ttf")
		LibEKL.UI.registerFont(addonInfo.id, "MontserratBlack", "fonts/Montserrat-Black.ttf")
		LibEKL.UI.registerFont(addonInfo.id, "MontserratMedium", "fonts/Montserrat-Medium.ttf")
		LibEKL.UI.registerFont(addonInfo.id, "MontserratMediumItalic", "fonts/Montserrat-MediumItalic.ttf")

		LibEKL.UI.registerFont(addonInfo.id, "FiraMonoBold", "fonts/FiraMono-Bold.ttf")
        LibEKL.UI.registerFont(addonInfo.id, "FiraMonoMedium", "fonts/FiraMono-Medium.ttf")
        LibEKL.UI.registerFont(addonInfo.id, "FiraMono", "fonts/FiraMono-Regular.ttf")

		Command.Event.Attach(Event.Unit.Availability.Full, function()
			LibEKL.Unit.Init()			
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

				if nkUISetup.modules.actionBars and nkUISetup.modules.actionBars.activate then
					internalFunc.uiActionBars()
				end				
		
				if nkUISetup.modules.sct and nkUISetup.modules.sct.activate then
					internalFunc.sctInit()
				end

				if nkUISetup.modules.oneBag and nkUISetup.modules.oneBag.activate then
					
					if nkUISetup.modules.oneBag.bankActivate then
						UI.Native.Bank:EventAttach(Event.UI.Native.Loaded, function()
							if uiElements.oneBag == nil then internalFunc.oneBagInit() end

							uiElements.oneBag:SetVisible(UI.Native.Bank:GetLoaded())
							uiElements.oneBank:SetVisible(UI.Native.Bank:GetLoaded())
						end, "nkUI.OneBag.Native.Bank.Loaded")
					end

					--[[unction UI.Native.Auction.Event:Loaded()
						if UI.Native.Auction:GetLoaded() then
							if uiElements.oneBag == nil then internalFunc.oneBagInit() end
							uiElements.oneBag:SetVisible(UI.Native.Auction:GetLoaded())
						else
							mainWindow:Close()
						end
					end]]

					UI.Native.Auction:EventAttach(Event.UI.Native.Loaded, function()
						if uiElements.oneBag == nil then internalFunc.oneBagInit() end
						uiElements.oneBag:SetVisible(UI.Native.Auction:GetLoaded())
						uiElements.oneBag:ShowAuction(UI.Native.Auction:GetLoaded())
					end, "nkUI.OneBag.Native.Auction.Loaded")

					UI.Native.BagInventory1:EventAttach(Event.UI.Native.Loaded, function()
						if uiElements.oneBag == nil then internalFunc.oneBagInit() end
						uiElements.oneBag:SetVisible(UI.Native.BagInventory1:GetLoaded())
					end, "nkUI.OneBag.Native.Bag.Loaded")
				end
			
				if nkUISetup.modules.questtracker and nkUISetup.modules.questtracker.activate then
					internalFunc.questTrackerInit(true)
				end

				if nkUISetup.modules.chat and nkUISetup.modules.chat.activate then
					internalFunc.chat ()
				end

				if nkUISetup.modules.map and nkUISetup.modules.map.activate then
					internalFunc.mapInit()
				end

				--internalFunc.questLogInit()							
			end

			--if nkUISetup.modules.map and nkUISetup.modules.map.activate then
			--	LibEKL.Events.AddInsecure(internalFunc.mapInit, inspectTimeFrame(), 5)
			--end

            Command.Event.Detach(Event.Unit.Availability.Full, nil, "nkUI.Unit.Availability.Full")

			if nkUISetup.showLogo then 
				LibEKL.Events.AddInsecure(animateLogo, inspectTimeFrame(), 5)
			end

			if nkUISetup.useManager then
				LibEKL.manager.RegisterButton("nkUI", addonInfo.id, "gfx/minimapIcon.png", internalFunc.setupInit)				

				if nkUISetup.modules.map and nkUISetup.modules.map.activate then

					LibEKL.manager.RegisterButton('nkUI.map.close', addonInfo.id, "gfx/mapMinimapIconClose.png", internalFunc.mapShowHide)
					LibEKL.manager.RegisterButton('nkUI.map.resize', addonInfo.id, "gfx/mapMinimapIconResize.png", internalFunc.mapToggleMinMax)
					LibEKL.manager.RegisterButton('nkUI.map.legend', addonInfo.id, "gfx/minimapIconLegend.png", internalFunc.mapLegendToggle)				

					LibEKL.Events.AddInsecure(function()
						local minimapFrame = LibEKL.manager.GetFrame()
						if minimapFrame then
							minimapFrame:ClearPoint("BOTTOMLEFT")
							minimapFrame:SetPoint("TOPLEFT", uiElements.mapUI, "BOTTOMLEFT")
							minimapFrame:SetWidth(uiElements.mapUI:GetWidth())
							LibEKL.manager.UpdateFrame(uiElements.mapUI)
						end
					end, Inspect.Time.Frame(), 10)
				end
			end

			Command.Message.Accept(nil, "nkUI.version")

--[[			Command.Event.Attach(Event.Mail, function(a,b,c) 
				dump(a)
				dump(b)
				dump(c)
			end, "nkUI.Version.Message.Receive")
]]
			Command.Event.Attach(Event.Message.Receive, _fctProcessMessage, "nkUI.Version.Message.Receive")

		end, "nkUI.Unit.Availability.Full")				

		Command.Console.Display("general", true, string.format(privateVars.langTexts.startUp, addonInfo.toc.Version), true)		
		Command.Console.Display("general", true, privateVars.langTexts.commandline1, true)
		Command.Console.Display("general", true, privateVars.langTexts.commandline2, true)
		Command.Console.Display("general", true, privateVars.langTexts.commandline3, true)
	end  
end

-- Startup events
Command.Event.Attach(Event.Addon.SavedVariables.Load.End, initializeAddon, "nkUI.SavedVariables.Load.End")
