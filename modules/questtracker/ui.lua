local addonInfo, privateVars = ...

---------- init namespace ---------

local questTracker	= privateVars.questTracker
local uiElements	= privateVars.uiElements
local data			= privateVars.data

local inspectMouse			= Inspect.Mouse
local inspectSystemSecure	= Inspect.System.Secure

---------- init local variables ---------

local colorR, colorG, colorB, colorA = 0.9, 0.74, 0, 1
local categoryOrder = { "crafting", "daily", "weekly", "monthly", "guild", "ia", "pvp", "world", "zone", "area", "instant", "raid", "story", "personal", "carnage"}

---------- local function block ---------

---------- addon internal function block ---------

local function showCategoryFilter (parent)

	local name = "nkUI.QuestTracker.categoryFilter"

	local ui = EnKai.uiCreateFrame("nkFrame", name, uiElements.contextLowest)
	ui:SetLayer(2)
	ui:SetBackgroundColor(0, 0, 0, 1)
	ui:SetPoint("TOPLEFT", parent, "BOTTOMLEFT")

	local from, object, to, x, y = "TOPLEFT", ui, "TOPLEFT", 5, 5
	local height = 0

	for _, v in pairs(categoryOrder) do
		local checkbox = EnKai.uiCreateFrame("nkCheckbox", name.. "." .. v, ui)
		checkbox:SetText(privateVars.langTexts.showCategoryCheckbox[v])
		checkbox:SetChecked(nkUISetup.modules.questtracker.categoryShow[v])
		checkbox:SetLabelWidth(150)
		checkbox:SetFontSize(14)
		checkbox:SetTextFont(addonInfo.id, "Montserrat")
		checkbox:SetPoint(from, object, to, x, y)

		height = height + checkbox:GetHeight() + 5

		from, object, to, x, y = "TOPLEFT", checkbox, "BOTTOMLEFT", 0, 5

		Command.Event.Attach(EnKai.events[name.. "." .. v].CheckboxChanged, function (_, newValue)		
			nkUISetup.modules.questtracker.categoryShow[v] = newValue			
		end, name.. "." .. v .. ".CheckboxChanged")
	end

	ui:SetHeight(height + 5)
	ui:SetWidth(180)

	return ui

end

function questTracker.buildUI ()

	local name = "nkQuestTrackerUI"
	local scrollPane, content	

	local ui = EnKai.uiCreateFrame("nkWindowElement", name, uiElements.contextLowest)
	
	ui:SetReverseAtBorder(false)
	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.questtracker.x, nkUISetup.modules.questtracker.y)
	ui:SetWidth(nkUISetup.modules.questtracker.width)
	ui:SetHeight(nkUISetup.modules.questtracker.height)
	ui:SetBackgroundColor(0, 0, 0, 0)
	ui:SetLayer(1)
	ui:SetTitleFont(addonInfo.id, "MontserratSemiBold")	
	ui:SetTitle(addonInfo.name)
	ui:SetTitleEffectGlow({strength = 3})
	ui:SetTitleColor(colorR, colorG, colorB, colorA)

	ui:SetTitleAlign("left", 0)
	ui:SetCloseable(false)
	ui:ShowMoveToggle(false)
	ui:SetDragable(true)
	ui:SetCollapseable(false)
	ui:SetFontSize(16)

	ui:GetHeader():SetBackgroundColor(0, 0, 0, 0)	
	
	local headerLine = EnKai.uiCreateFrame("nkCanvas", name .. ".headerLine", ui:GetHeader())
	headerLine:SetHeight(2)
	headerLine:SetWidth(ui:GetWidth())
	headerLine:SetPoint("TOPLEFT", ui:GetHeader(), "BOTTOMLEFT")

    local path =  {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }  
	local fill = {
		type = "gradientLinear",
		transform = Utility.Matrix.Create(2, 2, (math.pi / 4), 0, 0),
		color = {
			{ r = 0.9, g = 0.74, b = 0, a = 0, position = 0 },
			{ r = 0.9, g = 0.74, b = 0, a = 1, position = 0.25 },
			{ r = 0.9, g = 0.74, b = 0, a = 1, position = 0.75 },
			{ r = 0.9, g = 0.74, b = 0, a = 0, position = 1 }
		}
	}

	headerLine:SetShape(path, fill, nil)
		 
	Command.Event.Attach(EnKai.events[name].Moved, function (_, xpos, ypos)
		nkUISetup.modules.questtracker.x = xpos
		nkUISetup.modules.questtracker.y = ypos
	end, name .. '.Moved')

	-- ********* QUEST ITEM BUTTON
		
	local useButton = EnKai.uiCreateFrame("nkActionButtonMetro", name .. "questIconButton", uiElements.secureContext)
	useButton:SetScale(.75)
	useButton:SetPoint("TOPRIGHT", ui, "TOPLEFT", -5, 0)	
	useButton:SetColor(0, 0, 0, 0)
	useButton:SetBackgroundColor(0, 0, 0, 0)
	useButton:SetSecureMode("restricted")	
	--useButton:SetVisible(false)

	local checkAlpha = nil

	useButton:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)
		if inspectSystemSecure() == false then
			checkAlpha = useButton:GetAlpha()
			useButton:SetAlpha(1)
		end
	end, name .. ".resizeIcon.Mouse.Cursor.In")

	useButton:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)
		if inspectSystemSecure() == false and checkAlpha ~= nil then
			useButton:SetAlpha(checkAlpha)
		end
	end, name .. ".resizeIcon.Mouse.Cursor.Out")

	function ui:getUseItemButton () return useButton end

	-- ********* ZONE FILTER BUTTON
	
	local zoneFilterIcon = EnKai.uiCreateFrame("nkFrame", name .. '.zoneFilterIcon', ui:GetHeader())
	zoneFilterIcon:SetWidth(16)
	zoneFilterIcon:SetHeight(16)
	zoneFilterIcon:SetBackgroundColor(colorR, colorG, colorB, 0)
	zoneFilterIcon:SetPoint("CENTERRIGHT", ui:GetHeader(), "CENTERRIGHT", -3, 0)
	
	local zoneFilterText = EnKai.uiCreateFrame('nkText', name .. '.zoneFilterIcon.text', zoneFilterIcon)	
	zoneFilterText:SetPoint("CENTER", zoneFilterIcon, "CENTER")
	zoneFilterText:SetText("Z")
	zoneFilterText:SetFontSize(14)
	zoneFilterText:SetFontColor(colorR, colorG, colorB, 1)
	zoneFilterText:SetTextFont(addonInfo.id, "MontserratSemiBold")
	zoneFilterText:SetEffectGlow({strength = 3})
	
	zoneFilterText:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)

		if data.zoneFilter == true then data.zoneFilter = false else data.zoneFilter = true end
		
		if data.zoneFilter then
			zoneFilterIcon:SetBackgroundColor(colorR, colorG, colorB, 1)
			zoneFilterText:SetEffectGlow({strength = 0})
			zoneFilterText:SetFontColor(0,0,0,1)
			zoneFilterText:SetTextFont(addonInfo.id, "MontserratBold")
		else
			zoneFilterIcon:SetBackgroundColor(colorR, colorG, colorB, 0)
			zoneFilterText:SetFontColor(colorR, colorG, colorB, 1)
			zoneFilterText:SetEffectGlow({strength = 3})
			zoneFilterText:SetTextFont(addonInfo.id, "MontserratSemiBold")
		end
		
		ui:GetContent():SetVisible(false)
		questTracker.clearLog( questTracker.fillLog )
		
	end, name .. ".zoneFilterText.text.Mouse.Left.Down")

	EnKai.ui.attachGenericTooltip (zoneFilterText, "nkUI Questtracker", privateVars.langTexts.zoneFilter)

	-- ********* CATEGORY FILTER BUTTON
	
	local categoryFilterIcon = EnKai.uiCreateFrame("nkFrame", name .. '.categoryFilterIcon', ui:GetHeader())
	categoryFilterIcon:SetWidth(16)
	categoryFilterIcon:SetHeight(16)
	categoryFilterIcon:SetBackgroundColor(colorR, colorG, colorB, 0)
	categoryFilterIcon:SetPoint("CENTERRIGHT", zoneFilterIcon, "CENTERLEFT", -5, 0)
	
	local categoryFilterText = EnKai.uiCreateFrame('nkText', name .. '.categoryFilterIcon.text', categoryFilterIcon)	
	categoryFilterText:SetPoint("CENTER", categoryFilterIcon, "CENTER")
	categoryFilterText:SetText("C")
	categoryFilterText:SetFontSize(14)
	categoryFilterText:SetFontColor(colorR, colorG, colorB, 1)
	categoryFilterText:SetTextFont(addonInfo.id, "MontserratSemiBold")
	categoryFilterText:SetEffectGlow({strength = 3})
	
	categoryFilterText:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
		if uiElements.categoryFilter == nil then
			uiElements.categoryFilter = showCategoryFilter (categoryFilterIcon)
		end
			
		if uiElements.categoryFilter:GetVisible() then
			questTracker.clearLog(questTracker.fillLog)
		end

		uiElements.categoryFilter:SetVisible(not uiElements.categoryFilter:GetVisible())
	end, name .. ".categoryFilterIcon.text.Mouse.Left.Down")	

	EnKai.ui.attachGenericTooltip (categoryFilterText, "nkUI Questtracker", privateVars.langTexts.categoryFilter)
	 	
	EnKai.ui.genericTooltipSetFont(addonInfo.id, "Montserrat")

	-- ********* ITEM BUTTON
	
	local itemIcon = EnKai.uiCreateFrame("nkFrame", name .. '.itemIcon', ui:GetHeader())
	itemIcon:SetWidth(16)
	itemIcon:SetHeight(16)
	itemIcon:SetBackgroundColor(colorR, colorG, colorB, 0)
	itemIcon:SetPoint("CENTERRIGHT", categoryFilterIcon, "CENTERLEFT", -5, 0)
	
	local itemIconText = EnKai.uiCreateFrame('nkText', name .. '.itemIcon.text', itemIcon)	
	itemIconText:SetPoint("CENTER", itemIcon, "CENTER")
	itemIconText:SetText("I")
	itemIconText:SetFontSize(14)
	itemIconText:SetFontColor(colorR, colorG, colorB, 1)
	itemIconText:SetTextFont(addonInfo.id, "MontserratSemiBold")
	itemIconText:SetEffectGlow({strength = 3})
	
	itemIconText:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
		uiElements.useUI:Toggle()
	end, name .. ".itemIcon.text.Mouse.Left.Down")	

	EnKai.ui.attachGenericTooltip (itemIconText, "nkUI Questtracker", privateVars.langTexts.questItems)	 	

	-- ********* RESIZE ICON
	
	local resizeIcon = UI.CreateFrame('Texture', name .. '.resizeIcon', ui:GetContent())
	resizeIcon:SetPoint("BOTTOMRIGHT", ui:GetContent(), "BOTTOMRIGHT")
	resizeIcon:SetTextureAsync(addonInfo.identifier, "gfx/resizeIcon.png")
	resizeIcon:SetWidth(20)
	resizeIcon:SetHeight(20)
	resizeIcon:SetAlpha(0)
	resizeIcon:SetLayer(2)
	
	resizeIcon:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self) resizeIcon:SetAlpha(1) end, name .. ".resizeIcon.Mouse.Cursor.In")
	resizeIcon:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self) resizeIcon:SetAlpha(0) end, name .. ".resizeIcon.Mouse.Cursor.Out")
	
	resizeIcon:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
		self.leftDown = true		
		
		local mouse = inspectMouse()
		
		self.origX = mouse.x
		self.origY = mouse.y
		self.origWidth = ui:GetWidth()
		self.origHeight= ui:GetHeight()	
	end, name .. ".resizeIcon.Mouse.Left.Down")
	
	resizeIcon:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function (self, _, x, y)	
		if self.leftDown ~= true then return end
		
		local mouse = inspectMouse()
		
		local newHeight = self.origHeight + (mouse.y - self.origY)
		if newHeight < 100 then newHeight = 100 end
		
		local newWidth = self.origWidth + (mouse.x - self.origX)
		if newWidth < 100 then newWidth = 100 end
		
		ui:SetHeight(newHeight)
		ui:SetWidth(newWidth)
		
		nkUISetup.modules.questtracker.width = newWidth
		nkUISetup.modules.questtracker.height = newHeight
		
		scrollPane:SetWidth(ui:GetContent():GetWidth())
		scrollPane:SetHeight(ui:GetContent():GetHeight())

		ui:RecalcDimensions()
	end, name .. ".header.Cursor.Move")
	
	resizeIcon:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self) 
		self.leftDown = false 
	end, name .. ".resizeIcon.Mouse.Left.Up")
	
	resizeIcon:EventAttach(Event.UI.Input.Mouse.Left.Upoutside, function (self) 
		self.leftDown = false
	end, name .. ".resizeIcon.Mouse.Left.UpOutside")
			
	-- ********* SCROLL PANE
			
	scrollPane = EnKai.uiCreateFrame("nkScrollPane", name .. 'scrollPane', ui:GetContent())
	scrollPane:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT", 0, 10)
	scrollPane:SetWidth(ui:GetContent():GetWidth())
	scrollPane:SetHeight(ui:GetContent():GetHeight() - 10)
	
	-- ***** Hide scrollbars by setting the color to transparent *****

	scrollPane:SetColor({r = 0.153, g = 0.314, b = 0.490, a = 0})	
	scrollPane:SetColorInner({r = 0, g = 0, b = 0, a = 0})
	scrollPane:SetColorHighlight({r = 0.153, g = 0.314, b = 0.490, a = 0})

	scrollPane:SetLayer(1)	
		
	content = UI.CreateFrame("Frame", name .. '.content', scrollPane)
	content:SetWidth(ui:GetContent():GetWidth())
		
	local questCategories = {}
			
	for idx = 1, #categoryOrder, 1 do
		local thisCategory = questTracker.questCategory(categoryOrder[idx], content, ui)
		thisCategory:SetVisible(false)
		thisCategory:SetHeight(0)
		
		if idx == 1 then
			thisCategory:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 10)
		else
			thisCategory:SetPoint("TOPLEFT", questCategories[idx-1], "BOTTOMLEFT")
		end
		
		local categoryName = content:GetName() .. ".questCategory." .. categoryOrder[idx]
		
		table.insert(questCategories, thisCategory)
	end	
	
	---------------------------------------
	----- UI dimension recalculations -----
	
	function ui:RecalcDimensions()
		content:SetWidth(ui:GetContent():GetWidth()	)
    
		for idx = 1, #questCategories, 1 do
			questCategories[idx]:SetWidth(ui:GetContent():GetWidth())
	    end
		
		ui:RecalcHeight()
	end
	
	function ui:RecalcHeight()
		local height = 10
    
		for idx = 1, #questCategories, 1 do
			if questCategories[idx]:GetVisible() == true then
		   	height = height + questCategories[idx]:GetHeight()
			end
		end

		content:SetHeight(height) 

		local value = scrollPane:GetLanePosition()
		scrollPane:SetContent(content)
		if value ~= nil then scrollPane:SetLanePosition(value) end
	end
	
	function content:RecalcHeight()
		ui:RecalcHeight()
	end
	
	---------------------------------------
  ------------ helper methods -----------
	
	function ui:GetCategory(category)
		for k, v in pairs(questCategories) do
			if v:GetCategory() == category then return v end
		end
	end

	function ui:GetQuestCount()
		local count = 0
		for k, v in pairs(questCategories) do
			count = count + v:GetQuestCount()
		end
		return count
	end
		
	---------------------------------------
	------------ Quest methods ------------
	
	function ui:AddQuest(key, questCategory, title, objectives, complete, level, zone)
		for k, v in pairs(questCategories) do
			if v:GetCategory() == questCategory then
				v:AddQuest(key, title, objectives, complete, level, zone)
				if nkUISetup.modules.questtracker.categoryShow[questCategory] == true then
					v:RecalcHeight() 
					v:SetVisible(true)
				else
					v:SetHeight(0)
					v:SetVisible(false)
				end

				ui:RecalcHeight()
				break
			end
		end
	end
	
	function ui:RemoveQuest(key)
		for k, v in pairs(questCategories) do
			if v:HasQuest(key) then 
				v:RemoveQuest(key)
				if v:GetQuestCount() == 0 then
					v:SetHeight(0)
					v:SetVisible(false)
				else
					v:RecalcHeight()
				end
				ui:RecalcHeight()
			end
		end
	end
	
	function ui:UpdateQuest(key, questCategory, title, objectives, complete, level)
		for k, v in pairs(questCategories) do
			if v:GetCategory() == questCategory and v:HasQuest(key) then 
				if v:UpdateQuest(key, title, objectives, complete, level) == false then
					if v:GetVisible() == true then
						v:RecalcHeight()
						ui:RecalcHeight()
					end
				end
			end
		end
	end	
	
	---------------------------------------
	------------ design update ------------
	
	function ui:UpdateDesign(updateContent)
		for k, v in pairs(questCategories) do
			if nkUISetup.modules.questtracker.categoryShow[v:GetCategory()] == true and v:GetQuestCount() > 0 then
				v:SetVisible(true)
				v:UpdateDesign(updateContent)
			else
				v:SetHeight(0)
				v:SetVisible(false)
			end
		end
		
		ui:RecalcHeight()
	end

	local oDisplayHeader = ui.DisplayHeader
	function ui:DisplayHeader(flag)
		oDisplayHeader(self, flag)
		EnKai.events.addInsecure( function() useButton:SetVisible(flag) end )
	end
	
	ui:DisplayHeader(true)
	
	return ui

end