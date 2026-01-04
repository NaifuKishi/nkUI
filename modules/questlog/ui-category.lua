local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local internalFunc	= privateVars.internalFunc
local uiElements	= privateVars.uiElements
local data			= privateVars.data

local oInspectMouse			= Inspect.Mouse
local oInspectSystemSecure	= Inspect.System.Secure

---------- init local variables ---------

local categoryMenuCategory

---------- init variables ---------

---------- addon internalFunc function block ---------

function questLog.questCategory(category, parent)

	local name = parent:GetName() .. ".questCategory." .. category
	local sortedQuestList = {}
	local recycleBin = {}

	local subFrame
	local frame = UI.CreateFrame("Frame", name, parent)
	frame:SetWidth(parent:GetWidth())

	local header = UI.CreateFrame("Frame", name .. '.header', frame)
	header:SetPoint("TOPLEFT", frame, "TOPLEFT")	
	header:SetWidth(frame:GetWidth())

	header:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
		if uiElements.menuCategory ~= nil and uiElements.menuCategory:GetVisible() == true then
			uiElements.menuCategory:SetVisible(false)
		else
			showMenuCategory(header, category)
		end
	end, name .. "Header.Left.Down")

	local headerText = UI.CreateFrame("Text", name .. '.headerText', frame)	
	headerText:SetWordwrap(true)
	headerText:SetPoint("CENTERLEFT", header, "CENTERLEFT", 5, 0)
	headerText:SetFontSize(14)

	local thisText = category
	if privateVars.langTexts.showCategoryCheckbox[category] ~= nil then thisText = privateVars.langTexts.showCategoryCheckbox[category] end

	headerText:SetText(thisText)
	headerText:SetWidth(header:GetWidth() - 15)
	headerText:SetEffectGlow ({ strength = 3 })	

	LibEKL.UI.SetFont(headerText, addonInfo.id, "MontserratSemiBold")

	local color = data.categoryColor[category]
	headerText:SetFontColor(1, 1, 1, 1)

	header:SetHeight(headerText:GetHeight())
	
	subFrame = UI.CreateFrame('Frame', name .. '.subFrame', frame)
	subFrame:SetWidth(frame:GetWidth())
	subFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 5)

	subFrame:SetVisible(true)
	
	local questEntries = {}
	local questCount = 0

	---------------------------------------
	------------ helper methods -----------

	function frame:GetCategory() return category end
	function subFrame:GetCategory() return category end

	function frame:HasQuest(key)
		for k, v in pairs(questEntries) do
			if v:GetVisible() == true and v:GetKey() == key then return true end
		end    
		return false
	end

	function frame:GetQuestCount() return questCount end

	function frame:GetQuestList()
		local questList = {} 
		for k, v in pairs(questEntries) do
			if v:GetVisible() == true then table.insert(questList, v:GetKey()) end
		end    

		return questList
	end 

	---------------------------------------
	----- UI dimension recalcualtions -----

	function frame:RecalcHeight()

		local height = 0

		for idx = 1, #questEntries, 1 do
			if questEntries[idx]:GetVisible() == true then
				height = height + (questEntries[idx]:GetHeight() + 5)
			end
		end

		subFrame:SetHeight(height)

		if subFrame:GetVisible() == true then
			frame:SetHeight(height + header:GetHeight() + 5)
		else
			frame:SetHeight(header:GetHeight() + 5)
		end
	end

	function subFrame:RecalcHeight()
		frame:RecalcHeight()
	end

	local oSetWidth = frame.SetWidth

	function frame:SetWidth(newWidth)
		oSetWidth(self, newWidth)
		header:SetWidth(newWidth)
		headerText:SetWidth(header:GetWidth() - 15)
		headerLine:SetWidth(header:GetWidth())

		for idx = 1, #questEntries, 1 do questEntries[idx]:SetWidth(newWidth, true) end
		if frame:GetVisible() == true then frame:RecalcHeight() end
	end 

	---------------------------------------
	------------ Quest methods ------------

	function frame:AddQuest(key, title, subTitle, objectives, complete, level, zone)

		local thisEntry

		if #recycleBin > 0 then
			thisEntry = recycleBin[1]
			thisEntry:SetKey(key);
			table.remove(recycleBin, 1)
		else    
			thisEntry = questTracker.questEntry(key, subFrame, #questEntries+1)
			thisEntry:SetTitleFontSize (nkUISetup.modules.questtracker.categoryFontSize.header)
			thisEntry:SetBodyFontSize (nkUISetup.modules.questtracker.categoryFontSize.body)
			thisEntry:SetBodyColor (questTracker.bodyColor)
		end

		local pos = -1
		if #sortedQuestList > 0 then
			for idx = 1, #sortedQuestList, 1 do
				if sortedQuestList[idx] > title then
					pos = idx
					break
				end
			end
		end

		if pos == -1 then
			table.insert(sortedQuestList, title)
			table.insert(questEntries, thisEntry)
		else
			table.insert(sortedQuestList, pos, title)
			table.insert(questEntries, pos, thisEntry)
		end

		for idx = 1, #questEntries, 1 do
			if idx == 1 then
				questEntries[idx]:SetPoint("TOPLEFT", subFrame, "TOPLEFT", 5, 0)
			else
				questEntries[idx]:SetPoint("TOPLEFT", questEntries[idx-1], "BOTTOMLEFT", 0, 5)
			end 
		end

		questCount = questCount + 1

		thisEntry:SetTitle(title)
		thisEntry:SetSubTitle(subTitle)
		thisEntry:SetLevel(level)

		if complete ~= true then
			for k, v in pairs(objectives) do
				if not v.complete then
					thisEntry:AddObjective(v.description, v.count, v.countDone, v.complete)
				end
			end
		end

		thisEntry:RecalcHeight()
		thisEntry:SetVisible(true)
	end

	function frame:RemoveQuest(key)

		for idx = 1, #questEntries, 1 do
			if questEntries[idx]:GetKey() == key then

				local thisEntry = questEntries[idx]
				thisEntry:SetVisible(false)
				thisEntry:ClearAllObjectives()

				table.insert(recycleBin, thisEntry)
				table.remove(questEntries, idx, 1)
				table.remove(sortedQuestList, idx, 1)

				questCount = questCount - 1

				for idx = 1, #questEntries, 1 do
					if idx == 1 then
						questEntries[idx]:SetPoint("TOPLEFT", subFrame, "TOPLEFT", 20, 0)
					else
						questEntries[idx]:SetPoint("TOPLEFT", questEntries[idx-1], "BOTTOMLEFT", 0, 5)
					end 
				end

				return

			end
		end
	end

	function frame:UpdateQuest(key, title, subTitle, objectives, complete, level)

		for idx = 1, #questEntries, 1 do
			if questEntries[idx]:GetKey() == key then
				local thisEntry = questEntries[idx]
				local isUpdate = false

				if thisEntry:GetTitle() ~= title then 
					thisEntry:SetTitle(title)
					isUpdate = true
				end

				if complete ~= true then
					thisEntry:ClearAllObjectives()
					if objectives ~= nil then
						for k, v in pairs(objectives) do
							if not v.complete then
								thisEntry:AddObjective(v.description, v.count, v.countDone, v.complete)
							end
						end
					end
				else
					thisEntry:ClearAllObjectives()
				end

				thisEntry:RecalcHeight()

				if isUpdate == true then 
					return false
				else
					return thisEntry:GetCollapsed()
				end
			end
		end 
	end

	---------------------------------------
	------------ design update ------------

	function frame:UpdateDesign(updateContent)

		headerText:ClearHeight()
		headerText:SetFontSize(nkUISetup.modules.questtracker.categoryHeaderSize)

		local color = data.categoryColor[category]
		headerText:SetFontColor(color[1], color[2], color[3], 0)

		fill = {type = 'solid', r = color[1], g = color[2], b = color[3], a = 1}
		stroke =  { r = color[1], g = color[2], b = color[3], a = 1, thickness = 1}

		headerLine:SetShape(canvas, fill, stroke)
		header:SetHeight(headerText:GetHeight())

		if updateContent == true then

			if oInspectSystemSecure() == false then Command.System.Watchdog.Quiet() end

			for idx = 1, #questEntries, 1 do
				questEntries[idx]:SetTitleColor(nkUISetup.modules.questtracker.categoryColor[category])
				questEntries[idx]:SetTitleFontSize(nkUISetup.modules.questtracker.categoryFontSize.header, true)
				questEntries[idx]:SetBodyFontSize (nkUISetup.modules.questtracker.categoryFontSize.body, true)
				questEntries[idx]:SetBodyColor (questTracker.bodyColor)
				questEntries[idx]:RecalcHeight()
			end
		
		end

		frame:RecalcHeight()
	end

	return frame

end