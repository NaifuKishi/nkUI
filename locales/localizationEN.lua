local addonInfo, privateVars = ...

---------- init namespace ---------

---------- init language texts ---------

if ( EnKai.tools.lang.getLanguage()  ~= "German") then
	privateVars.langTexts = {
		startUp             		= '<font color="#0094FF">nkUI</font> V%s loaded',
		commandline             	= '/nkui to open settings',
		txtVersion          		= 'Version %s',
	}
end