local addonInfo, privateVars = ...

---------- init namespace ---------

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

---------- init local variables ---------

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

---------- init variables ---------

data.colors = { primary	= { r = 1, g = 1, b = 1, a = 1 }, 
				accent	= { r = .24, g = .68, b = .91, a = 1 }}
				
data.uiScaleX, data.uiScaleY = 1, 1
local thisTutorialVersion = 008

---------- generate ui context ---------

-- hud, notify, dialog, tutorial, menu, layout, topmost, loading, modal

uiElements.context = UI.CreateContext("nkUI") 
uiElements.context:SetStrata ('dialog')

uiElements.secureContext = UI.CreateContext("nkUI.secure")
uiElements.secureContext:SetStrata ('tutorial')
uiElements.secureContext:SetSecureMode("restricted")

uiElements.tooltipContext = UI.CreateContext("nkUI.Tooltip")
uiElements.tooltipContext:SetStrata ('tooltip')

uiElements.contextTop = UI.CreateContext("nkUI.Dialog")
uiElements.contextTop:SetStrata ('topmost')

uiElements.contextLowest = UI.CreateContext("nkUI.lowest")
uiElements.contextLowest:SetStrata ('hud')
uiElements.contextLowest:SetSecureMode("restricted")

---------- local function block ---------

local function _setupDefaults ()

	if nkUISetup == nil then 		
		nkUISetup = {}
		nkUISetup.uiFrames = { activate = true }
		nkUISetup.lowerBar = { activate = true }
		nkUISetup.tooltip = { activate = true }
		nkUISetup.buffFrame = { activate = true }
		nkUISetup.buffUnitFrame = { activate = true }
		nkUISetup.combatAlpha = 1
		nkUISetup.nonCombatAlpha = .2
		nkUISetup.tutorialVersion = 0
	else
		nkUISetup.tutorial = nil -- V0.0.8 change
		nkUISetup.buffUnitFrame = { activate = true } -- V0.0.8 change		
		nkUISetup.combatAlpha = 1 -- V0.0.8 change		
		nkUISetup.nonCombatAlpha = .2 -- V0.0.8 change		
	end


end

local function _main(_, addon)

	if addon == addonInfo.identifier then

		table.insert(Command.Slash.Register("nkui"), {_internal.tutorial, "nkUI", "commandHandler"})

		local items = { { label = privateVars.langTexts.configuration, callBack = _internal.tutorial} }

		EnKai.ui.registerFont (addonInfo.id, "Montserrat", "fonts/Montserrat-Regular.ttf")
		EnKai.ui.registerFont (addonInfo.id, "MontserratSemiBold", "fonts/Montserrat-SemiBold.ttf")
		EnKai.ui.registerFont (addonInfo.id, "FiraMonoBold", "fonts/FiraMono-Bold.ttf")
		EnKai.ui.registerFont (addonInfo.id, "FiraMonoMedium", "fonts/FiraMono-Medium.ttf")
		EnKai.ui.registerFont (addonInfo.id, "FiraMono", "fonts/FiraMono-Regular.ttf")

		EnKai.art.SetTheme("nkUI")

		local parentWidth = UIParent:GetWidth()
		local parentHeight = UIParent:GetHeight()
		data.uiScaleX = parentWidth / 3440
		data.uiScaleY = parentHeight / 1440
		--local scale = 1

		data.layout = {
			fontSize = 15,
			barHeight = 17,
			barWidth = 300,
			barText = 15,
			timeSize = 36,
			dateSize = 15
		}

		--local frame = EnKai.uiCreateFrame("nkFrame", "test", uiElements.context)
		--frame:SetPoint("TOPLEFT", UI.Native.BarBottom1, "TOPLEFT")
		--frame:SetPoint("BOTTOMRIGHT", UI.Native.BarBottom1, "BOTTOMRIGHT")
		--frame:SetBackgroundColor(1,1,1,1)

		Command.Event.Attach(Event.Unit.Availability.Full, function()
			--EnKai.manager.init('nkUI', items, nil)

			EnKai.unit.init()
			local id = EnKai.unit.getPlayerDetails().id
			data.playerID = id

			EnKai.BuffManager.init() -- Initialize the BuffManager if not already done
			EnKai.inventory.init (false)

			
			if nkUISetup and nkUISetup.tooltip and nkUISetup.tooltip.activate then
				_internal.tooltip()
			end

			if nkUISetup and nkUISetup.lowerBar and nkUISetup.lowerBar.activate then
				_internal.lowerBar()
			end

			if nkUISetup and nkUISetup.uiFrames and nkUISetup.uiFrames.activate then
				_internal.uiFrames ()
			end			

			Command.Event.Detach(Event.Unit.Availability.Full, nil,  "nkUI.Unit.Availability.Full")

			if nkUISetup.tutorialVersion == nil or nkUISetup.tutorialVersion < thisTutorialVersion then 
				_setupDefaults()

    			nkUISetup.tutorialVersion = thisTutorialVersion

				print  (nkUISetup.tutorialVersion, thisTutorialVersion)
				_internal.tutorial()
			end

		end, "nkUI.Unit.Availability.Full")
		
		
		Command.Console.Display("general", true, string.format(privateVars.langTexts.startUp, addonInfo.toc.Version), true)

		EnKai.version.init(addonInfo.toc.Identifier, addonInfo.toc.Version)
	end  
  
end

-------------------- STARTUP EVENTS --------------------

Command.Event.Attach(Event.Addon.Load.End, _main, "nkUI.Addon.Load.End")
