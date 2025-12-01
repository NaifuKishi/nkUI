--[[
   main.lua
    Author: NaifuKishi
    Date Created: 22.11.2025
    Date Modified: 22.11.2025
    Description: Main entry point for the nkUI addon. Initializes the addon namespace, variables, and UI contexts. Handles addon startup and configuration.
    Public Functions:
        - _setupDefaults: Initializes default configuration values
        - _main: Main initialization function for the addon
    Version History:
        -
]]

local addonInfo, privateVars = ...

---------- init namespace ----------

if not nkUI then nkUI = {} else return end

privateVars.data        = {}
privateVars.internal    = {}
privateVars.uiElements  = {}
privateVars.events      = {}
privateVars.oFuncs		= {}

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events
local oFuncs	  = privateVars.oFuncs

---------- init local variables ----------

oFuncs.InspectTimeFrame				= Inspect.Time.Frame
oFuncs.InspectUnitDetail			= Inspect.Unit.Detail
oFuncs.InspectUnitLookup			= Inspect.Unit.Lookup
oFuncs.InspectSystemSecure			= Inspect.System.Secure
oFuncs.InspectTimeReal				= Inspect.Time.Real
oFuncs.InspectTimeServer 			= Inspect.Time.Server
oFuncs.InspectCurrencyDetail		= Inspect.Currency.Detail
oFuncs.InspectExperience			= Inspect.Experience
oFuncs.InspectFactionList			= Inspect.Faction.List
oFuncs.InspectFactionDetail			= Inspect.Faction.Detail
oFuncs.InspectGuildRosterList		= Inspect.Guild.Roster.List
oFuncs.InspectGuildRosterDetail		= Inspect.Guild.Roster.Detail
oFuncs.InspectGuildRankDetail		= Inspect.Guild.Rank.Detail
oFuncs.InspectSocialFriendDetail	= Inspect.Social.Friend.Detail
oFuncs.InspectSocialFriendList		= Inspect.Social.Friend.List
oFuncs.InspectZoneDetail			= Inspect.Zone.Detail
oFuncs.InspectAbilityNewList		= Inspect.Ability.New.List
oFuncs.InspectAbilityNewDetail		= Inspect.Ability.New.Detail
oFuncs.InspectBuffDetail			= Inspect.Buff.Detail
oFuncs.InspectBuffList				= Inspect.Buff.List

local stringFind					= string.find

---------- init variables ----------

data.colors = {
    primary	= { r = 1, g = 1, b = 1, a = 1 },
    accent	= { r = .24, g = .68, b = .91, a = 1 }
}
				
data.uiScaleX, data.uiScaleY = 1, 1
local thisTutorialVersion = 024

---------- generate ui context ----------

-- hud, notify, dialog, tutorial, menu, layout, topmost, loading, modal

uiElements.context = UI.CreateContext("nkUI") 
uiElements.context:SetStrata('dialog')

uiElements.secureContext = UI.CreateContext("nkUI.secure")
uiElements.secureContext:SetStrata('tutorial')
uiElements.secureContext:SetSecureMode("restricted")

uiElements.tooltipContext = UI.CreateContext("nkUI.Tooltip")
uiElements.tooltipContext:SetStrata('tooltip')

uiElements.contextTop = UI.CreateContext("nkUI.Dialog")
uiElements.contextTop:SetStrata('topmost')

uiElements.contextLowest = UI.CreateContext("nkUI.lowest")
uiElements.contextLowest:SetStrata('hud')
uiElements.contextLowest:SetSecureMode("restricted")

---------- local function block ----------

local function _commandHandler (commandline)

	if commandline == nil then return end
		
	if stringFind(commandline, "bag") ~= nil then
		if nkUISetup and nkUISetup.modules and nkUISetup.modules.oneBag and nkUISetup.modules.oneBag.activate then
			_internal.oneBagInit()
		end
	else
		_internal.setupInit ()
	end

end

--[[
   _main
    Description:
        Main initialization function for the nkUI addon.
        Sets up slash commands, registers fonts, initializes UI elements,
        and handles addon startup events.
    Parameters:
        _ (any): Unused parameter
        addon (string): The addon identifier
    Returns:
        None
    Notes:
]]
local function _main(_, addon)
	if addon == addonInfo.identifier then
		table.insert(Command.Slash.Register("nkui"), {_commandHandler, "nkUI", "commandHandler"})
		
		local items = { { label = privateVars.langTexts.configuration, callBack = _internal.tutorial} }

        EnKai.ui.registerFont(addonInfo.id, "Montserrat", "fonts/Montserrat-Regular.ttf")
        EnKai.ui.registerFont(addonInfo.id, "MontserratSemiBold", "fonts/Montserrat-SemiBold.ttf")
		EnKai.ui.registerFont(addonInfo.id, "MontserratBold", "fonts/Montserrat-Bold.ttf")
        EnKai.ui.registerFont(addonInfo.id, "FiraMonoBold", "fonts/FiraMono-Bold.ttf")
        EnKai.ui.registerFont(addonInfo.id, "FiraMonoMedium", "fonts/FiraMono-Medium.ttf")
        EnKai.ui.registerFont(addonInfo.id, "FiraMono", "fonts/FiraMono-Regular.ttf")

		EnKai.art.SetTheme("nkUI")

		local parentWidth = UIParent:GetWidth()
		local parentHeight = UIParent:GetHeight()
		data.uiScaleX = parentWidth / 3440
		data.uiScaleY = parentHeight / 1440
		data.layout = {
			fontSize = 15,
			barHeight = 17,
			barWidth = 300,
			barText = 15,
			timeSize = 36,
			dateSize = 15
		}

		Command.Event.Attach(Event.Unit.Availability.Full, function()
			EnKai.unit.init()
			
			local id = EnKai.unit.getPlayerDetails().id
			data.playerID = id

			EnKai.BuffManager.init() -- Initialize the BuffManager if not already done
            EnKai.inventory.init(false)
			
			_internal.setupDefaults()

			if nkUISetup.tutorialVersion == nil or nkUISetup.tutorialVersion < thisTutorialVersion then 				
    			nkUISetup.tutorialVersion = thisTutorialVersion
				_internal.tutorial()
			end

			if nkUISetup and nkUISetup.modules then
				if nkUISetup.modules.tooltip and nkUISetup.modules.tooltip.activate then
					_internal.tooltip()
				end

				if nkUISetup.modules.lowerBar and nkUISetup.modules.lowerBar.activate then
					_internal.lowerBar()
				end
				
				if nkUISetup.modules.unitFrames and nkUISetup.modules.unitFrames.activate then
					_internal.uiFrames()
				end

				if nkUISetup.modules.actionBars and nkUISetup.modules.actionBars.activate then
					_internal.uiActionBars()
				end				
				
				if nkUISetup.modules.sct and nkUISetup.modules.sct.activate then
					_internal.sctInit()
				end

				if nkUISetup.modules.oneBag and nkUISetup.modules.oneBag.activate then
					
					UI.Native.Bank:EventAttach(Event.UI.Native.Loaded, function()
						if uiElements.oneBag == nil then _internal.oneBagInit() end

						uiElements.oneBag:SetVisible(UI.Native.Bank:GetLoaded())
					end, "nkUI.OneBag.Native.Bank.Loaded")
				end
			end

			--_internal.cooldownInit()

            Command.Event.Detach(Event.Unit.Availability.Full, nil, "nkUI.Unit.Availability.Full")

		end, "nkUI.Unit.Availability.Full")
		
		EnKai.managerV2.RegisterButton("nkUI", addonInfo.id, "gfx/minimapIcon.png", _internal.setupInit)

		Command.Console.Display("general", true, string.format(privateVars.langTexts.startUp, addonInfo.toc.Version), true)
		Command.Console.Display("general", true, privateVars.langTexts.commandline, true)

		EnKai.version.init(addonInfo.toc.Identifier, addonInfo.toc.Version)
	end  
end

-------------------- STARTUP EVENTS --------------------

Command.Event.Attach(Event.Addon.Load.End, _main, "nkUI.Addon.Load.End")
