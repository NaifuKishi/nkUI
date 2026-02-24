local addonInfo, privateVars = ...

---------- init namespace ---------

local questTracker	= privateVars.questTracker
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

	local dialog = LibEKL.UI.confirmDialog(text, yesFunc, noFunc)
	internalFunc.setupConfirmDialog(dialog)

end

local function showMenu (parent, key)

	questMenuKey = key

	if uiElements.menu == nil then
		uiElements.menu = LibEKL.UICreateFrame("nkMenu", 'nkQuestTracker.menu', uiElements.contextTooltip)
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

function questTracker.questEntry (key, parent, counter)

	local name = parent:GetName() .. ".questEntry." .. counter
	local subFrame
	local fontSize, color = 13
	local collapsed = false
	
	local objectives = {}
	local objectiveCount = 0
	local use = nil
	
	local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
	frame:SetWidth(parent:GetWidth() -  20)
	
	local levelFrame = LibEKL.UICreateFrame("nkFrame", name .. ".levelFrame", frame)
	levelFrame:SetWidth(20)
	levelFrame:SetHeight(20)
	levelFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")

	local level = LibEKL.UICreateFrame("nkText", name .. '.levelText', levelFrame)
	level:SetPoint("TOPLEFT", frame, "TOPLEFT")
	level:SetFontSize(15)
	level:SetFontColor(data.theme.COLOR_WHITE.r, data.theme.COLOR_WHITE.g, data.theme.COLOR_WHITE.b, data.theme.COLOR_WHITE.a)
	level:SetWordwrap(true)
	level:SetEffectGlow(data.theme.GLOW_STANDARD)
	internalFunc.setElementFont(level, "MontserratSemiBold")

	local header = LibEKL.UICreateFrame("nkText", name .. '.Header', frame)
	header:SetPoint("TOPLEFT", levelFrame, "TOPRIGHT", 5, 0)
	header:SetFontSize(15)
	header:SetFontColor(data.theme.COLOR_WHITE.r, data.theme.COLOR_WHITE.g, data.theme.COLOR_WHITE.b, data.theme.COLOR_WHITE.a)
	header:SetWordwrap(true)
	header:SetEffectGlow(data.theme.GLOW_STANDARD)

	internalFunc.setElementFont(header, "MontserratSemiBold")

	header:SetWidth(frame:GetWidth())

	local subHeader = LibEKL.UICreateFrame("nkText", name .. '.subHeader', frame)
	subHeader:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
	subHeader:SetFontSize(fontSize)
	subHeader:SetFontColor(data.theme.COLOR_WHITE.r, data.theme.COLOR_WHITE.g, data.theme.COLOR_WHITE.b, data.theme.COLOR_WHITE.a)
	subHeader:SetWordwrap(true)
	subHeader:SetEffectGlow(data.theme.GLOW_STANDARD)

	internalFunc.setElementFont(subHeader, "MontserratSemiBold")

	subHeader:SetWidth(frame:GetWidth())
	
	if parent.GetCategory ~= nil then
		header:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
			internalFunc.questLogInit(true)
			uiElements.questLog:UpdateQuestDetails(key)
		end, name .. "Header.Left.Down")

		header:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
			if uiElements.menu ~= nil and uiElements.menu:GetVisible() == true then
				uiElements.menu:SetVisible(false)
			else
				showMenu(header, key)
			end
		end, name .. "Header.Right.Down")

		header:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)
			questTracker.showTooltip(header, key, nil, parent:GetCategory())
		end, name .. "Header.Cursor.In")

		header:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)
			if uiElements.qtTooltip ~= nil then uiElements.qtTooltip:SetVisible(false) end
		end, name .. "Header.Cursor.Out")
	end
	
	subFrame = LibEKL.UICreateFrame("nkFrame", name .. '.subFrame', parent)
	subFrame:SetPoint("TOPLEFT", subHeader, "BOTTOMLEFT")
	subFrame:SetWidth(frame:GetWidth())
	
	if nkUISetup.modules.questtracker.collapseState[key] == nil then nkUISetup.modules.questtracker.collapseState[key] = true end
	subFrame:SetVisible(nkUISetup.modules.questtracker.collapseState[key])

	local anchor = subFrame	
	
	---------------------------------------
	------------ helper methods -----------
	
	function frame:GetKey() return key end
	
	function frame:SetKey(newKey) key = newKey end
	
	function frame:GetCollapsed() return collapsed end
	
	function frame:GetTitle() return header:GetText() end 
			
	---------------------------------------
	----- UI dimension recalcualtions -----
	
	function frame:RecalcHeight()
		local height = 0
		
		for idx = 1, #objectives, 1 do
			if objectives[idx]:GetVisible() == true then
				height = height + objectives[idx]:GetHeight()
			end
		end
		
		subFrame:SetHeight(height)
		
		if subFrame:GetVisible() == true then
			frame:SetHeight(height + header:GetHeight() + subHeader:GetHeight())
		else
			frame:SetHeight(header:GetHeight() + subHeader:GetHeight())
		end
		
	end		
	
	local oSetWidth = frame.SetWidth
	
	function frame:SetWidth(newWidth, silent)
		oSetWidth(self, newWidth)
		
		header:SetWidth(newWidth)
		for idx = 1, #objectives, 1 do
			objectives[idx]:SetWidth(newWidth-15)
		end
		
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

	function frame:SetSubTitle(title)
		if title ~= nil then
			subHeader:ClearHeight()
			subHeader:SetText(title, true)					
			subFrame:SetPoint("TOPLEFT", subHeader, "BOTTOMLEFT")
			subHeader:SetVisible(true)
		else
			subHeader:SetVisible(false)
			subFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
		end

		frame:RecalcHeight()
	end
	
	---------------------------------------
	------------- Objectives ------------
	
	function frame:ClearAllObjectives()
		for idx = 1, #objectives, 1 do objectives[idx]:SetVisible(false) end
		objectiveCount = 0
	end
	
	function frame:AddObjective(description, count, countDone, complete)
	
		local thisObjective
	
		if objectiveCount + 1 > #objectives then
			thisObjective = UI.CreateFrame("Text", name .. '.Objective.' .. objectiveCount + 1, subFrame)
			
			if objectiveCount == 0 then
				thisObjective:SetPoint("TOPLEFT", subFrame, "TOPLEFT")
			else				
				thisObjective:SetPoint("TOPLEFT", objectives[objectiveCount], "BOTTOMLEFT")
			end
			
			LibEKL.UI.SetFont(thisObjective, addonInfo.id, "MontserratSemiBold")
			thisObjective:SetEffectGlow({strength = 3})
			thisObjective:SetFontSize(fontSize)
			table.insert(objectives, thisObjective)
		else
			thisObjective = objectives[objectiveCount+1]
		end 
		
		objectiveCount = objectiveCount + 1
		thisObjective:SetVisible(true)
		thisObjective:SetWidth(subFrame:GetWidth()-15)
		thisObjective:SetWordwrap(true)		
		thisObjective:SetText(stringFormat("%s", description))
		thisObjective.complete = complete
		
		if complete == true then
			thisObjective:SetFontColor(questTracker.bodyCompleteColor[1], questTracker.bodyCompleteColor[2], questTracker.bodyCompleteColor[3], 1)		
		else
			thisObjective:SetFontColor(questTracker.bodyColor[1], questTracker.bodyColor[2], questTracker.bodyColor[3], 1)			
		end
		
	end
	
	---------------------------------------
	------------ design update ------------
	
	function frame:SetTitleColor(rgb) 
		header:SetFontColor(rgb[1],rgb[2],rgb[3]) 
		subHeader:SetFontColor(rgb[1],rgb[2],rgb[3]) 
	end
	
	function frame:SetBodyColor(rgb)
		for idx = 1, #objectives, 1 do
			objectives[idx]:SetFontColor(rgb[1],rgb[2],rgb[3])
		end
		color = rgb
	end
	
	function frame:SetTitleFontSize(newFontSize)
		header:SetFontSize(newFontSize)
	end
	
	function frame:SetBodyFontSize(newFontSize)
		for idx = 1, #objectives, 1 do
			objectives[idx]:SetFontSize(newFontSize)
		end

		subHeader:SetFontSize(newFontSize)
		fontSize = newFontSize
	end	
	
	return frame

end