local addonInfo, privateVars = ...

---------- init namespace ---------

---------- init language texts ---------

if ( LibEKL.Tools.Lang.GetLanguage()  ~= "German") then

	privateVars.langTexts = {
		startUp             	= '<font color="#0094FF">nkUI</font> V%s loaded',
		commandline             = '/nkui to open settings',
		questGiver				= 'Quest giver: <font color="#0094FF">%s</font>',
		scene					= 'Quest location: <font color="#0094FF">%s</font>',
		zoneFilter				= "Click here to filter the list by the current zone",
		categoryFilter			= "Click here to filter to select which categories to show",
		questItems				= "Click here to hide or show the quest items",
		track					= "Track quest",
		abandon					= 'Abandon',
		share					= 'Share',
		abandonQuestConfirm		= 'Are you sure that you want to abandon the quest %s?',
		abandonAllQuestsConfirm = 'Are you sure that you want to abandon all quests of category %s?',
		alphaSlider				= 'Background alpha %d%%',
		completeInfo			= '%s <font color="#FF0000">(done)</font>',
		categoryHeaderSize		= 'Category title size %d',
		abandonAll				= 'Abandon all',
		identifierCarnage		= 'Carnage',
		battlePass				= "Battle Pass",
		showCategoryCheckbox	= {	battlepass = "Battle Pass",
									crafting = "Crafting", 
									weekly = "Weekly", 
									monthly = "Monthly",
									daily = "Daily", 
									guild = "Guild", 
									ia = "Instant Adventure", 
									world = "World", 
									zone = "Zone", 
									area = "Area", 
									instant = "Instance", 
									raid = "Raid", 
									personal = "Regular quests", 
									carnage = "Carnage", 
									story	= "Story",
									pvp="PvP"},
	}
end