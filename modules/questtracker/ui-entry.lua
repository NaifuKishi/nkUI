local addonInfo, privateVars = ...

---------- init namespace ---------

local internal		= privateVars.internal
local uiElements	= privateVars.uiElements
local data			= privateVars.data

local oInspectQuestDetail	= Inspect.Quest.Detail
local oInspectMouse			= Inspect.Mouse

---------- init local variables ---------

local questMenuKey

---------- init variables ---------

---------- local function block ---------

local function _fctTrackQuest()

	pcall (Command.Quest.Track, questMenuKey)
	uiElements.menu:SetVisible(false)

end

local function _fctShareQuest ()

	Command.Quest.Share(questMenuKey)
	uiElements.menu:SetVisible(false)
	
end

local function _fctAbandonQuest ()

	local function noFunc ()
		uiElements.menu:SetVisible(false)
	end
	
	local function yesFunc()
		pcall (Command.Quest.Abandon, questMenuKey) 
		uiElements.menu:SetVisible(false)
	end
	
	local flag, quest = pcall(oInspectQuestDetail, questMenuKey)
	if flag == false then return end
	
	local text = string.format(privateVars.langTexts.abandonQuestConfirm, quest.name)

	EnKai.ui.confirmDialog (text, yesFunc, noFunc) 
	
end

local function _fctShowMenu (parent, key)

	questMenuKey = key

	if uiElements.menu == nil then
		uiElements.menu = EnKai.uiCreateFrame("nkMenu", 'nkQuestTracker.menu', uiElements.context)
		uiElements.menu:SetFont(addonInfo.id, "MontserratSemiBold")
		uiElements.menu:SetLayer(3)
		uiElements.menu:AddEntry({ label = privateVars.langTexts.track, callBack = _fctTrackQuest })
		uiElements.menu:AddEntry({ label = privateVars.langTexts.abandon, callBack = _fctAbandonQuest })
		uiElements.menu:AddEntry({ label = privateVars.langTexts.share, callBack = _fctShareQuest})
	end
	
	local menu = uiElements.menu
	local mouse = oInspectMouse()
	
	menu:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouse.x, mouse.y)
	menu:SetVisible(true)
	
end

---------- addon internal function block ---------

function internal.questEntry (key, parent, counter)

	local name = parent:GetName() .. ".questEntry." .. counter
	local subFrame
	local fontSize, color = 13
	local collapsed = false
	
	local objectives = {}
	local objectiveCount = 0
	local use = nil
	
	local frame = UI.CreateFrame("Frame", name, parent)
	frame:SetWidth(parent:GetWidth() -  20)
	
	local level = UI.CreateFrame("Text", name .. '.level', frame)
	level:SetPoint("TOPLEFT", frame, "TOPLEFT")		
	level:SetFontSize(15)
	level:SetFontColor(1, 1, 1, 1)
	level:SetWordwrap(true)
	level:SetEffectGlow({ strength = 3})

	local header = UI.CreateFrame("Text", name .. '.Header', frame)
	header:SetPoint("TOPLEFT", level, "TOPRIGHT", 5, 0)		
	header:SetFontSize(15)
	header:SetFontColor(1, 1, 1, 1)
	header:SetWordwrap(true)
	header:SetEffectGlow({ strength = 3})

	EnKai.ui.setFont(header, addonInfo.id, "MontserratSemiBold")

	header:SetWidth(frame:GetWidth())

	local subHeader = UI.CreateFrame("Text", name .. '.subHeader', frame)
	subHeader:SetPoint("TOPLEFT", header, "BOTTOMLEFT")		
	subHeader:SetFontSize(fontSize)
	subHeader:SetFontColor(1, 1, 1, 1)
	subHeader:SetWordwrap(true)
	subHeader:SetEffectGlow({ strength = 3})

	EnKai.ui.setFont(subHeader, addonInfo.id, "MontserratSemiBold")

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
			
			nkQuestTrackerSetup.collapseState[key] = subFrame:GetVisible()
			
			frame:RecalcHeight()
			parent:RecalcHeight()
		end, name .. "Header.Left.Down")
	
		header:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
			if uiElements.menu ~= nil and uiElements.menu:GetVisible() == true then
				uiElements.menu:SetVisible(false)
			else
				_fctShowMenu(header, key)
			end
		end, name .. "Header.Left.Down")
	
		header:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)		
				internal.showTooltip(header, key, nil, parent:GetCategory())
		end, name .. "Header.Left.Down")
		
		header:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)		
			if uiElements.tooltip ~= nil then uiElements.tooltip:SetVisible(false) end
		end, name .. "Header.Left.Down")
	end
	
	subFrame = UI.CreateFrame("Frame", name .. '.subFrame', parent)
	subFrame:SetPoint("TOPLEFT", subHeader, "BOTTOMLEFT")
	subFrame:SetWidth(frame:GetWidth())
	
	if nkQuestTrackerSetup.collapseState[key] == nil then nkQuestTrackerSetup.collapseState[key] = true end
	subFrame:SetVisible(nkQuestTrackerSetup.collapseState[key])

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
			
			EnKai.ui.setFont(thisObjective, addonInfo.id, "MontserratSemiBold")
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
			thisObjective:SetFontColor(nkQuestTrackerSetup.bodyCompleteColor[1], nkQuestTrackerSetup.bodyCompleteColor[2], nkQuestTrackerSetup.bodyCompleteColor[3], 1)		
		else
			thisObjective:SetFontColor(nkQuestTrackerSetup.bodyColor[1], nkQuestTrackerSetup.bodyColor[2], nkQuestTrackerSetup.bodyColor[3], 1)			
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
		--subHeader:SetFontSize(fontSize)
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