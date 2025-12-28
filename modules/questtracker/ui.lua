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

	local ui = LibEKL.uiCreateFrame("nkFrame", name, uiElements.contextLowest)
	ui:SetLayer(2)
	ui:SetBackgroundColor(0, 0, 0, 1)
	ui:SetPoint("TOPLEFT", parent, "BOTTOMLEFT")

	local from, object, to, x, y = "TOPLEFT", ui, "TOPLEFT", 5, 5
	local height = 0

	for _, v in pairs(categoryOrder) do
		local checkbox = LibEKL.uiCreateFrame("nkCheckbox", name.. "." .. v, ui)
		checkbox:SetText(privateVars.langTexts.showCategoryCheckbox[v])
		checkbox:SetChecked(nkUISetup.modules.questtracker.categoryShow[v])
		checkbox:SetLabelWidth(150)
		checkbox:SetFontSize(14)
		checkbox:SetTextFont(addonInfo.id, "Montserrat")
		checkbox:SetPoint(from, object, to, x, y)

		height = height + checkbox:GetHeight() + 5

		from, object, to, x, y = "TOPLEFT", checkbox, "BOTTOMLEFT", 0, 5

		Command.Event.Attach(LibEKL.events[name.. "." .. v].CheckboxChanged, function (_, newValue)		
			nkUISetup.modules.questtracker.categoryShow[v] = newValue			
		end, name.. "." .. v .. ".CheckboxChanged")
	end

	ui:SetHeight(height + 5)
	ui:SetWidth(180)

	return ui

end

function questTracker.buildUI ()

	local name = "nkUI.questTracker"
	local scrollPane, content	

	local ui = LibEKL.uiCreateFrame("nkFrame", name, uiElements.contextLowest)
	
	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.questtracker.x, nkUISetup.modules.questtracker.y)
	ui:SetWidth(nkUISetup.modules.questtracker.width)
	ui:SetHeight(nkUISetup.modules.questtracker.height)
	ui:SetBackgroundColor(0, 0, 0, 0)
	ui:SetLayer(1)

	local header = LibEKL.uiCreateFrame("nkText", name .. ".header", ui)	
	header:SetText(addonInfo.name)
	header:SetEffectGlow({strength = 3})
	header:SetFontColor(colorR, colorG, colorB, colorA)
	header:SetFontSize(16)
	header:SetPoint("TOPLEFT", ui, "TOPLEFT")

	header:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)            	    
    	self.leftDown = true
    	local mouse = inspectMouse()
    
    	self.originalXDiff = mouse.x - ui:GetLeft()
    	self.originalYDiff = mouse.y - ui:GetTop()
    
    	local left, top, right, bottom = ui:GetBounds()
    
    	ui:ClearPoint("TOPLEFT")
    	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, top)
  	end, name .. ".header.Left.Down")
  
	header:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function (self, _, x, y)  
		if self.leftDown ~= true then return end
		
		local newX, newY = x - self.originalXDiff, y - self.originalYDiff

		-- the boundary below if fucked in scale mode and turned out to be completely useless

		ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", newX, newY)    
	end, name .. ".header.Cursor.Move")
	
	header:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self) 
		if self.leftDown ~= true then return end
		self.leftDown = false

		nkUISetup.modules.questtracker.x = ui:GetLeft()
		nkUISetup.modules.questtracker.y = ui:GetTop()

	end, name .. ".header.Left.Up")
	
	header:EventAttach( Event.UI.Input.Mouse.Left.Upoutside, function (self)
		if self.leftDown ~= true then return end
		self.leftDown = false

		nkUISetup.modules.questtracker.x = ui:GetLeft()
		nkUISetup.modules.questtracker.y = ui:GetTop()
	end , name .. ".header.Left.Upoutside")

	LibEKL.ui.setFont(header, addonInfo.id, "MontserratSemiBold")	

	local headerLine = LibEKL.uiCreateFrame("nkCanvas", name .. ".headerLine", ui)
	headerLine:SetHeight(2)
	headerLine:SetWidth(ui:GetWidth())
	headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT")

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

	-- ********* ZONE FILTER BUTTON

	local zoneFilterIcon = LibEKL.uiCreateFrame("nkClickButton", name .. '.zoneFilterIcon', ui)
	zoneFilterIcon:SetWidth(16)
	zoneFilterIcon:SetHeight(16)
	zoneFilterIcon:SetToggleable(true)
	zoneFilterIcon:SetColor({ r = colorR, g = colorG, b = colorB, a = 1})
	zoneFilterIcon:SetText("Z")
  	zoneFilterIcon:SetPoint("TOPRIGHT", ui, "TOPRIGHT", -10, 5)
  	zoneFilterIcon:SetTooltip("nkUI Questtracker", privateVars.langTexts.zoneFilter)

	Command.Event.Attach(LibEKL.events[name .. '.zoneFilterIcon'].Clicked, function (_, newValue)		
		if data.zoneFilter == true then data.zoneFilter = false else data.zoneFilter = true end				
		questTracker.clearLog( questTracker.fillLog )
	end,name .. '.zoneFilterIcon.Clicked')	

	-- ********* CATEGORY FILTER BUTTON

	local categoryFilterIcon = LibEKL.uiCreateFrame("nkClickButton", name .. '.categoryFilterIcon', ui)
	categoryFilterIcon:SetWidth(16)
	categoryFilterIcon:SetHeight(16)
	categoryFilterIcon:SetColor({ r = colorR, g = colorG, b = colorB, a = 1})
	categoryFilterIcon:SetText("C")
  	categoryFilterIcon:SetPoint("CENTERRIGHT", zoneFilterIcon, "CENTERLEFT", -5, 0)
  	categoryFilterIcon:SetTooltip("nkUI Questtracker", privateVars.langTexts.categoryFilter)

	Command.Event.Attach(LibEKL.events[name .. '.categoryFilterIcon'].Clicked, function (_, newValue)		
		if uiElements.categoryFilter == nil then
			uiElements.categoryFilter = showCategoryFilter (categoryFilterIcon)
		end
			
		if uiElements.categoryFilter:GetVisible() then
			questTracker.clearLog(questTracker.fillLog)
		end

		uiElements.categoryFilter:SetVisible(not uiElements.categoryFilter:GetVisible())
	end,name .. '.categoryFilterIcon.Clicked')		
	
	-- ********* ITEM BUTTON

	local itemIcon = LibEKL.uiCreateFrame("nkClickButton", name .. '.itemIcon', ui)
	itemIcon:SetWidth(16)
	itemIcon:SetHeight(16)
	itemIcon:SetColor({ r = colorR, g = colorG, b = colorB, a = 1})
	itemIcon:SetText("I")
  	itemIcon:SetPoint("CENTERRIGHT", categoryFilterIcon, "CENTERLEFT", -5, 0)
  	itemIcon:SetTooltip("nkUI Questtracker", privateVars.langTexts.questItems)

	Command.Event.Attach(LibEKL.events[name .. '.itemIcon'].Clicked, function (_, newValue)		
		uiElements.useUI:Toggle()
	end,name .. '.itemIcon.Clicked') 	

	-- ********* RESIZE ICON
	
	local resizeIcon = UI.CreateFrame('Texture', name .. '.resizeIcon', ui)
	resizeIcon:SetPoint("BOTTOMRIGHT", ui, "BOTTOMRIGHT")
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
		
		scrollPane:SetWidth(ui:GetWidth())
		scrollPane:SetHeight(ui:GetHeight())

		ui:RecalcDimensions()
	end, name .. ".header.Cursor.Move")
	
	resizeIcon:EventAttach(Event.UI.Input.Mouse.Left.Up, function (self) 
		self.leftDown = false 
	end, name .. ".resizeIcon.Mouse.Left.Up")
	
	resizeIcon:EventAttach(Event.UI.Input.Mouse.Left.Upoutside, function (self) 
		self.leftDown = false
	end, name .. ".resizeIcon.Mouse.Left.UpOutside")
			
	-- ********* SCROLL PANE
			
	scrollPane = LibEKL.uiCreateFrame("nkScrollPane", name .. 'scrollPane', ui)
	scrollPane:SetPoint("TOPLEFT", header, "TOPLEFT", -5, 30)
	scrollPane:SetWidth(ui:GetWidth())
	scrollPane:SetHeight(ui:GetHeight() - 30)
	
	-- ***** Hide scrollbars by setting the color to transparent *****

	scrollPane:SetColor({r = 0.153, g = 0.314, b = 0.490, a = 0})	
	scrollPane:SetColorInner({r = 0, g = 0, b = 0, a = 0})
	scrollPane:SetColorHighlight({r = 0.153, g = 0.314, b = 0.490, a = 0})

	scrollPane:SetLayer(1)	
		
	content = UI.CreateFrame("Frame", name .. '.content', scrollPane)
	content:SetWidth(ui:GetWidth())
		
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
		content:SetWidth(ui:GetWidth()	)
    
		for idx = 1, #questCategories, 1 do
			questCategories[idx]:SetWidth(ui:GetWidth())
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

	function ui:SetTitle(newTitle)
		header:SetText(newTitle)
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
	
	return ui

end