local addonInfo, privateVars = ...

---------- init namespace ---------

---------- init language texts ---------

if ( EnKai.tools.lang.getLanguage()  == "German") then

	privateVars.langTexts = {
		startUp             		= '<font color="#0094FF">nkUI</font> V%s geladen',
		txtVersion          		= 'Version %s',
	}
end