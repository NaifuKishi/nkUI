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

-- Initialize variables
data.colors = {
    primary	= { r = 1, g = 1, b = 1, a = 1 },
    accent	= { r = 0.1176, g = 0.7490, b = 1, a = 1 }
}
				
data.uiScale = 1
local thisTutorialVersion = 40

-- Generate UI context
uiElements.contextLowest = UI.CreateContext("nkUI.lowest")
uiElements.contextLowest:SetStrata('hud')

uiElements.contextDialog = UI.CreateContext("nkUI.Dialog")
uiElements.contextDialog:SetStrata('dialog')

uiElements.contextTooltip = UI.CreateContext("nkUI.Tooltip")
uiElements.contextTooltip:SetStrata('tooltip')

uiElements.contextLowestRestricted = UI.CreateContext("nkUI.lowestRestricted")
uiElements.contextLowestRestricted:SetStrata('hud')
uiElements.contextLowestRestricted:SetSecureMode("restricted")

uiElements.secureContext = UI.CreateContext("nkUI.secure")
uiElements.secureContext:SetStrata('tutorial')
uiElements.secureContext:SetSecureMode("restricted")

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
		
        EnKai.ui.registerFont(addonInfo.id, "Montserrat", "fonts/Montserrat-Regular.ttf")
        EnKai.ui.registerFont(addonInfo.id, "MontserratSemiBold", "fonts/Montserrat-SemiBold.ttf")
		EnKai.ui.registerFont(addonInfo.id, "MontserratBold", "fonts/Montserrat-Bold.ttf")
        EnKai.ui.registerFont(addonInfo.id, "FiraMonoBold", "fonts/FiraMono-Bold.ttf")
        EnKai.ui.registerFont(addonInfo.id, "FiraMonoMedium", "fonts/FiraMono-Medium.ttf")
        EnKai.ui.registerFont(addonInfo.id, "FiraMono", "fonts/FiraMono-Regular.ttf")

		EnKai.art.SetTheme("nkUI")

		Command.Event.Attach(Event.Unit.Availability.Full, function()
			EnKai.unit.init()
			
			EnKai.BuffManager.init()
            EnKai.inventory.init(false, false)

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
					
					UI.Native.Bank:EventAttach(Event.UI.Native.Loaded, function()
						if uiElements.oneBag == nil then internalFunc.oneBagInit() end

						uiElements.oneBag:SetVisible(UI.Native.Bank:GetLoaded())
					end, "nkUI.OneBag.Native.Bank.Loaded")

					UI.Native.BagInventory1:EventAttach(Event.UI.Native.Loaded, function()
					if uiElements.oneBag == nil then internalFunc.oneBagInit() end

						uiElements.oneBag:SetVisible(UI.Native.BagInventory1:GetLoaded())
					end, "nkUI.OneBag.Native.Bag.Loaded")
				end

				--internalFunc.chat ()
				
			end

            Command.Event.Detach(Event.Unit.Availability.Full, nil, "nkUI.Unit.Availability.Full")

		end, "nkUI.Unit.Availability.Full")
		
		EnKai.managerV2.RegisterButton("nkUI", addonInfo.id, "gfx/minimapIcon.png", internalFunc.setupInit)

		Command.Console.Display("general", true, string.format(privateVars.langTexts.startUp, addonInfo.toc.Version), true)		
		Command.Console.Display("general", true, privateVars.langTexts.commandline, true)

		EnKai.version.init(addonInfo.toc.Identifier, addonInfo.toc.Version)
	end  
end

-- Startup events
Command.Event.Attach(Event.Addon.SavedVariables.Load.End, initializeAddon, "nkUI.SavedVariables.Load.End")
