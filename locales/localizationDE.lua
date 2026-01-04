local addonInfo, privateVars = ...

---------- init namespace ---------

---------- init language texts ---------

if ( LibEKL.Tools.Lang.GetLanguage()  == "German") then

	privateVars.langTexts = {
		startUp             	= '<font color="#0094FF">nkUI</font> V%s geladen',
		commandline             = '/nkui um die Einstellungen zu öffnen',
		questGiver				= 'Questgeber: <font color="#0094FF">%s</font>',
		scene					= 'Questort: <font color="#0094FF">%s</font>',
		zoneFilter				= "Klicke hier um die Liste auf die aktuelle Zone zu filtern",
		categoryFilter			= "Klicke hier um die Kategorien auszwählen die angezeigt werden sollen",
		questItems				= "Klicke hier um die Quest Items anzuzeigen oder zu verstecken",
		track					= "Quest verfolgen",
		abandon					= 'Abbrechen',
		share					= 'Teilen',
		abandonQuestConfirm		= 'Bist Du sicher, dass Du den Quest <font color="#0094FF">%s</font> abrechen willst?',
		abandonAllQuestsConfirm = 'Bist Du sicher, dass Du Quests der Kategorie <font color="#0094FF">%s</font> abrechen willst?',
		alphaSlider				= 'Sichtbarkeit Hintergrund %d%%',
		completeInfo			= '%s <font color="#FF0000">(fertig)</font>',
		categoryHeaderSize		= 'Grösse Kategorietitel %d',
		abandonAll				= 'Alle abbrechen',
		identifierCarnage		= 'Massaker',
		battlePass				= "Schlachtpass",
		showCategoryCheckbox	= {	battlepass = "Battle Pass",
									area = "Gebiet", 
									guild = "Gilde", 
									crafting = "Handwerk", 
									instant = "Instanz",
									carnage = "Massaker", 
									personal = "Regular quests",
									pvp="PvP", 
									raid = "Schlachtzug",  
									ia = "Sofort-Abenteuer", 
									daily = "Täglich", 
									world = "Welt", 
									weekly = "Wöchentlich", 
									monthly = "Monatlich",
									story	= "Geschichte",
									zone = "Zone"},
	}
end