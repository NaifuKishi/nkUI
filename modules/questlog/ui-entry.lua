local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local internalFunc	= privateVars.internalFunc
local uiElements	= privateVars.uiElements
local data			= privateVars.data

local inspectQuestDetail	= Inspect.Quest.Detail
local inspectMouse			= Inspect.Mouse

local stringFormat			= string.format

---------- init local variables ---------

local questMenuKey

---------- init variables ---------

---------- local function block ---------

local function trackQuest()

	pcall (Command.Quest.Track, questMenuKey)
	uiElements.menu:SetVisible(false)

end

local function shareQuest ()

	Command.Quest.Share(questMenuKey)
	uiElements.menu:SetVisible(false)
	
end

local function abandonQuest ()

	local function noFunc ()
		uiElements.menu:SetVisible(false)
	end
	
	local function yesFunc()
		pcall (Command.Quest.Abandon, questMenuKey) 
		uiElements.menu:SetVisible(false)
	end
	
	local flag, quest = pcall(inspectQuestDetail, questMenuKey)
	if flag == false then return end
	
	local text = stringFormat(privateVars.langTexts.abandonQuestConfirm, quest.name)

	local dialog = LibEKL.UI.confirmDialog (text, yesFunc, noFunc) 
	dialog:SetTitle("nkUI")
	dialog:SetTitleFont(addonInfo.id, "MontserratSemiBold")
	dialog:SetTitleFontSize (20)    
	dialog:SetTitleAlign("center")
	dialog:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

	dialog:SetFont(addonInfo.id, "MontserratSemiBold")
	dialog:SetEffectGlow({ strength = 3 })
	dialog:SetButtonFont(addonInfo.id, "MontserratSemiBold")
	dialog:SetButtonFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
	dialog:SetButtonLabelColor (data.theme.labelColor)
	dialog:SetButtonBorderColor ({ r = 0, g = 0, b = 0, a = .7, thickness = 1})
	dialog:SetButtonEffect({ strength = 3 })
	dialog:SetHeight(200)
	
	dialog:SetColor({	type = "gradientLinear",
						transform = Utility.Matrix.Create(2, 2, -(math.pi / 6), 0, 0), -- Negative angle for opposite direction
						color = {
							data.theme.windowStartColor,
							data.theme.windowEndColor
							}
					},  { r = 0, g = 0, b = 0, a = 1, thickness = 1})
	
end

local function showMenu (parent, key)

	questMenuKey = key

	if uiElements.menu == nil then
		uiElements.menu = LibEKL.UICreateFrame("nkMenu", 'nkquestLog.menu', uiElements.contextTooltip)
		uiElements.menu:SetFont(addonInfo.id, "MontserratSemiBold")
		uiElements.menu:SetLayer(3)
		uiElements.menu:AddEntry({ label = privateVars.langTexts.track, callBack = trackQuest })
		uiElements.menu:AddEntry({ label = privateVars.langTexts.abandon, callBack = abandonQuest })
		uiElements.menu:AddEntry({ label = privateVars.langTexts.share, callBack = shareQuest})
	end
	
	local menu = uiElements.menu
	local mouse = inspectMouse()
	
	menu:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x, mouse.y)
	menu:SetVisible(true)
	
end

---------- addon internalFunc function block ---------

function questLog.questEntry (key, parent, counter)

	local name = parent:GetName() .. ".questEntry." .. counter
	local fontSize, color = 14
	
	local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
	frame:SetWidth(parent:GetWidth() -  10)
	
	local level = LibEKL.UICreateFrame("nkText", name .. '.levelText', frame)
	level:SetPoint("CENTERLEFT", frame, "CENTERLEFT")
	level:SetFontSize(fontSize)
	level:SetFontColor(1, 1, 1, 1)
	level:SetEffectGlow({ strength = 3})

	LibEKL.UI.SetFont(level, addonInfo.id, "MontserratSemiBold")

	local header = LibEKL.UICreateFrame("nkText", name .. '.Header', frame)
	header:SetPoint("CENTERLEFT", level, "CENTERLEFT", 20, 0)		
	header:SetFontSize(fontSize)
	header:SetFontColor(1, 1, 1, 1)
	--header:SetWordwrap(true)
	header:SetEffectGlow({ strength = 3})
	header:SetWidth(frame:GetWidth() - 20)

	LibEKL.UI.SetFont(header, addonInfo.id, "MontserratSemiBold")

	header:SetWidth(frame:GetWidth())
	
	if parent.GetCategory ~= nil then
		header:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
			uiElements.questLog:UpdateQuestDetails(key)
		end, name .. "Header.Left.Down")
	
		header:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
			if uiElements.menu ~= nil and uiElements.menu:GetVisible() == true then
				uiElements.menu:SetVisible(false)
			else
				showMenu(header, key)
			end
		end, name .. "Header.Left.Down")
	end
		
	---------------------------------------
	------------ helper methods -----------
	
	function frame:GetKey() return key end
	
	function frame:SetKey(newKey) key = newKey end
	
	function frame:GetTitle() return header:GetText() end 
			
	---------------------------------------
	----- UI dimension recalcualtions -----
	
	function frame:RecalcHeight()
		frame:SetHeight(header:GetHeight())		
	end		
	
	local oSetWidth = frame.SetWidth
	
	function frame:SetWidth(newWidth, silent)
		oSetWidth(self, newWidth)
		header:SetWidth(newWidth)
		frame:RecalcHeight()
	end
	
	---------------------------------------
	------------- Info setting ------------

	function frame:SetLevel(newLevel)
		if newLevel == nil then return end
		
		level:ClearHeight()
		level:SetText(newLevel, true)
	end
		
	function frame:SetTitle(title)
		header:ClearHeight()
		header:SetText(title, true)		
	end
	
	---------------------------------------
	------------ design update ------------
	
	function frame:SetTitleColor(rgb) 
		header:SetFontColor(rgb[1],rgb[2],rgb[3]) 	
	end
		
	function frame:SetTitleFontSize(newFontSize)
		level:SetFontSize(newFontSize)
		header:SetFontSize(newFontSize)
	end
	
	return frame

end