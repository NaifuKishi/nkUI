local addonInfo, privateVars = ...

---------- init namespace ---------

local questTracker	= privateVars.questTracker
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local events		= privateVars.events

local oInspectMouse			= Inspect.Mouse
local oInspectSystemSecure	= Inspect.System.Secure

---------- init local variables ---------

local colorR, colorG, colorB, colorA = 0.9, 0.74, 0, 1
local categoryOrder = { "crafting", "daily", "weekly", "monthly", "guild", "ia", "pvp", "world", "zone", "area", "instant", "raid", "story", "personal", "carnage"}

---------- local function block ---------

---------- addon internal function block ---------

function questTracker.buildUI ()

	local name = "nkQuestTrackerUI"
	local scrollPane, content	

	local ui = EnKai.uiCreateFrame("nkWindowElement", name, uiElements.contextLowest)
	
	ui:SetReverseAtBorder(false)
	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.questtracker.x, nkUISetup.modules.questtracker.y)
	ui:SetWidth(nkUISetup.modules.questtracker.width)
	ui:SetHeight(nkUISetup.modules.questtracker.height)
	ui:SetBackgroundColor(0, 0, 0, nkUISetup.modules.questtracker.bgAlpha)
	ui:SetLayer(1)
	ui:SetTitleFont(addonInfo.id, "MontserratSemiBold")	
	ui:SetTitle(addonInfo.name)
	ui:SetTitleEffectGlow({strength = 3})
	
	--ui:SetTitleColor(1, 1 ,1 ,1)
	ui:SetTitleColor(colorR, colorG, colorB, colorA)

	ui:SetTitleAlign("left", 40)
	ui:SetCloseable(false)
	ui:ShowMoveToggle(true)
	ui:SetDragable(true)
	ui:SetCollapseable(true)
	--ui:SetAutoHideHeader(nkQuestTrackerSetup.autoHide, 2, 30)
	ui:SetFontSize(16)

	ui:GetHeader():SetBackgroundColor(0, 0, 0, nkUISetup.modules.questtracker.bgAlpha)	
	
	ui:SetArrowTextures(addonInfo.identifier, "gfx/windowModernArrowRight.png", "gfx/windowModernArrowDown.png")
	ui:GetMoveCheckbox():SetColor(colorR, colorG, colorB, colorA)
	
	Command.Event.Attach(EnKai.events[name].HeaderHide, function (_)
	  EnKai.events.addInsecure(
	    function()
	      if uiElements.useUI ~= nil then uiElements.useUI:SetVisible(false) end
    	  ui:getUseItemButton():SetAlpha(0.5)
    	end)
	end, name .. '.HeaderHide')
	
	Command.Event.Attach(EnKai.events[name].HeaderShown, function (_)
		EnKai.events.addInsecure(
			function() ui:getUseItemButton():SetAlpha(1) end
		)
	end, name .. '.HeaderShown')
	 
	Command.Event.Attach(EnKai.events[name].Moved, function (_, xpos, ypos)
		nkUISetup.modules.questtracker.x = xpos
		nkUISetup.modules.questtracker.y = ypos
	end, name .. '.Moved')
	
	--Command.Event.Attach(EnKai.events[name].Dragable, function (_, dragable)
	--	nkQuestTrackerSetup.moveable = dragable
	--end, name .. '.Dragable')


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
		if oInspectSystemSecure() == false then
			checkAlpha = useButton:GetAlpha()
			useButton:SetAlpha(1)
		end
	end, name .. ".resizeIcon.Mouse.Cursor.In")

	useButton:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)
		if oInspectSystemSecure() == false and checkAlpha ~= nil then
			useButton:SetAlpha(checkAlpha)
		end
	end, name .. ".resizeIcon.Mouse.Cursor.Out")

	function ui:getUseItemButton () return useButton end

	local questItemsIcon = UI.CreateFrame('Texture', name .. '.zoneFilterIcon', ui:GetHeader())
	questItemsIcon:SetPoint("CENTERRIGHT", ui:GetHeader(), "CENTERRIGHT", -3, 0)	
	questItemsIcon:SetTextureAsync(addonInfo.identifier, "gfx/items.png");
	questItemsIcon:SetWidth(12)
	questItemsIcon:SetHeight(12)
	
	questItemsIcon:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
		uiElements.useUI:toggle()		
	end, name .. ".questItemsIcon.Mouse.Left.Down")

	-- ********* ZONE FILTER BUTTON
	
	local zoneFilterIcon = UI.CreateFrame('Texture', name .. '.zoneFilterIcon', ui:GetHeader())
	zoneFilterIcon:SetPoint("CENTERRIGHT", questItemsIcon, "CENTERLEFT", -5, 0)
	zoneFilterIcon:SetTextureAsync(addonInfo.identifier, "gfx/zoneFilterOff.png");
	zoneFilterIcon:SetWidth(12)
	zoneFilterIcon:SetHeight(12)
	
	zoneFilterIcon:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
		if data.zoneFilter == true then data.zoneFilter = false else data.zoneFilter = true end
		
		if data.zoneFilter then
			zoneFilterIcon:SetTextureAsync(addonInfo.identifier, "gfx/zoneFilterOn.png")
		else
			zoneFilterIcon:SetTextureAsync(addonInfo.identifier, "gfx/zoneFilterOff.png")
		end
		
		ui:GetContent():SetVisible(false)
		questTracker.clearLog( questTracker.fillLog )
		
	end, name .. ".zoneFilterIcon.Mouse.Left.Down")
	 	
	EnKai.ui.attachGenericTooltip (zoneFilterIcon, "nkQuestTracker", privateVars.langTexts.zoneFilter)
	EnKai.ui.genericTooltipSetFont(addonInfo.id, "Montserrat")

	local missingIcon = UI.CreateFrame('Texture', name .. '.missingIcon', ui:GetHeader())
	missingIcon:SetPoint("CENTERRIGHT", zoneFilterIcon, "CENTERLEFT", -5, 0)
	missingIcon:SetTextureAsync(addonInfo.identifier, "gfx/missingIcon.png");
	missingIcon:SetWidth(12)
	missingIcon:SetHeight(12)
	
	missingIcon:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
		questTracker.missingList()
	end, name .. ".missingIcon.Mouse.Left.Down")
	
	EnKai.ui.attachGenericTooltip (missingIcon, "nkQuestTracker", privateVars.langTexts.missingList)
	
	local refreshIcon = UI.CreateFrame('Texture', name .. '.refreshIcon', ui:GetHeader())
	refreshIcon:SetPoint("CENTERRIGHT", missingIcon, "CENTERLEFT", -5, 0)
	refreshIcon:SetTextureAsync(addonInfo.identifier, "gfx/refreshIcon.png");
	refreshIcon:SetWidth(12)
	refreshIcon:SetHeight(12)
	
	refreshIcon:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
		questTracker.clearLog(questTracker.fillLog)
	end, name .. ".refreshIcon.Mouse.Left.Down")
	
	EnKai.ui.attachGenericTooltip (missingIcon, "nkQuestTracker", privateVars.langTexts.missingList)
		
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
		
		local mouse = oInspectMouse()
		
		self.origX = mouse.x
		self.origY = mouse.y
		self.origWidth = ui:GetWidth()
		self.origHeight= ui:GetHeight()	
	end, name .. ".resizeIcon.Mouse.Left.Down")
	
	resizeIcon:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function (self, _, x, y)	
		if self.leftDown ~= true then return end
		
		local mouse = oInspectMouse()
		
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
	scrollPane:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT", 0, 0)
	scrollPane:SetWidth(ui:GetContent():GetWidth())
	scrollPane:SetHeight(ui:GetContent():GetHeight())
	
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