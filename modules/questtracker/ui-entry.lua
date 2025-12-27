local addonInfo, privateVars = ...

---------- init namespace ---------

local questTracker	= privateVars.questTracker
local internalFunc	= privateVars.internalFunc
local uiElements	= privateVars.uiElements

local inspectQuestDetail	= Inspect.Quest.Detail
local inspectMouse			= Inspect.Mouse

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
	
	local text = string.format(privateVars.langTexts.abandonQuestConfirm, quest.name)

	LibEKL.ui.confirmDialog (text, yesFunc, noFunc) 
	
end

local function showMenu (parent, key)

	questMenuKey = key

	if uiElements.menu == nil then
		uiElements.menu = LibEKL.uiCreateFrame("nkMenu", 'nkQuestTracker.menu', uiElements.contextTooltip)
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
	
	local frame = LibEKL.uiCreateFrame("nkFrame", name, parent)
	frame:SetWidth(parent:GetWidth() -  20)
	
	local levelFrame = LibEKL.uiCreateFrame("nkFrame", name .. ".levelFrame", frame)
	levelFrame:SetWidth(20)
	levelFrame:SetHeight(20)
	levelFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")

	local level = LibEKL.uiCreateFrame("nkText", name .. '.levelText', levelFrame)
	level:SetPoint("TOPLEFT", frame, "TOPLEFT")		
	level:SetFontSize(15)
	level:SetFontColor(1, 1, 1, 1)
	level:SetWordwrap(true)
	level:SetEffectGlow({ strength = 3})

	local header = LibEKL.uiCreateFrame("nkText", name .. '.Header', frame)
	header:SetPoint("TOPLEFT", levelFrame, "TOPRIGHT", 5, 0)		
	header:SetFontSize(15)
	header:SetFontColor(1, 1, 1, 1)
	header:SetWordwrap(true)
	header:SetEffectGlow({ strength = 3})

	LibEKL.ui.setFont(header, addonInfo.id, "MontserratSemiBold")

	header:SetWidth(frame:GetWidth())

	local subHeader = LibEKL.uiCreateFrame("nkText", name .. '.subHeader', frame)
	subHeader:SetPoint("TOPLEFT", header, "BOTTOMLEFT")		
	subHeader:SetFontSize(fontSize)
	subHeader:SetFontColor(1, 1, 1, 1)
	subHeader:SetWordwrap(true)
	subHeader:SetEffectGlow({ strength = 3})

	LibEKL.ui.setFont(subHeader, addonInfo.id, "MontserratSemiBold")

	subHeader:SetWidth(frame:GetWidth())
	
	if parent.GetCategory ~= nil then
		header:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
			if subFrame:GetVisible() == true then
				subFrame:SetVisible(false)
				collapsed = true		
			else
				subFrame:SetVisible(true)
				collapsed = false
			end
			
			nkUISetup.modules.questtracker.collapseState[key] = subFrame:GetVisible()
			
			frame:RecalcHeight()
			parent:RecalcHeight()
		end, name .. "Header.Left.Down")
	
		header:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
			if uiElements.menu ~= nil and uiElements.menu:GetVisible() == true then
				uiElements.menu:SetVisible(false)
			else
				showMenu(header, key)
			end
		end, name .. "Header.Left.Down")
	
		header:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)		
				questTracker.showTooltip(header, key, nil, parent:GetCategory())
		end, name .. "Header.Left.Down")
		
		header:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)		
			if uiElements.qtTooltip ~= nil then uiElements.qtTooltip:SetVisible(false) end
		end, name .. "Header.Left.Down")
	end
	
	subFrame = LibEKL.uiCreateFrame("nkFrame", name .. '.subFrame', parent)
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
			subFrame:SetPoint("TOPLEFT", subHeader, "BOTTOMLEFT", 0, 0)
			subHeader:SetVisible(true)
		else
			subHeader:SetVisible(false)
			subFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
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
			
			LibEKL.ui.setFont(thisObjective, addonInfo.id, "MontserratSemiBold")
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
		thisObjective:SetText(string.format("%s", description))
		thisObjective.complete = complete
		
		if complete == true then
			thisObjective:SetFontColor(nkUISetup.modules.questtracker.bodyCompleteColor[1], nkUISetup.modules.questtracker.bodyCompleteColor[2], nkUISetup.modules.questtracker.bodyCompleteColor[3], 1)		
		else
			thisObjective:SetFontColor(nkUISetup.modules.questtracker.bodyColor[1], nkUISetup.modules.questtracker.bodyColor[2], nkUISetup.modules.questtracker.bodyColor[3], 1)			
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