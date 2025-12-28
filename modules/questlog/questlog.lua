local addonInfo, privateVars = ...

---------- init namespace ---------

privateVars.questLog = {}

local internalFunc	= privateVars.internalFunc
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local questLog	    = privateVars.questLog

local inspectQuestList      = Inspect.Quest.List
local inspectQuestDetail    = Inspect.Quest.Detail
local inspectZoneDetail		= Inspect.Zone.Detail

local colorR, colorG, colorB, colorA = 0.9, 0.74, 0, 1

local function uiQuestLog()

    local name = "nkUI.questLog"
	local scrollPane, content
	local questCategories

	local ui = LibEKL.uiCreateFrame("nkwindow", name, questTracker.context)
	
	ui:SetReverseAtBorder(false)
	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 600, 400)
	ui:SetWidth(600)
	ui:SetHeight(500)
	ui:SetBackgroundColor(0, 0, 0, .6)
	ui:SetLayer(1)
	ui:SetTitleFont(addonInfo.id, "MontserratSemiBold")	
	ui:SetTitle(addonInfo.name)
	ui:SetTitleEffectGlow({strength = 3})
	ui:SetTitleColor(colorR, colorG, colorB, colorA)    

	ui:SetTitleAlign("center", 0)
	ui:SetCloseable(false)
	ui:ShowMoveToggle(false)
	ui:SetDragable(true)
	ui:SetCollapseable(false)
	ui:SetFontSize(16)

	ui:GetHeader():SetBackgroundColor(0, 0, 0, .6)	

    -- collapse button
    -- expand all button

    -- ********* SCROLL PANE
			
	scrollPane = LibEKL.uiCreateFrame("nkScrollPane", name .. '.scrollPane', ui:GetContent())
	scrollPane:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT", 20, 30)
	scrollPane:SetWidth(300)
	scrollPane:SetHeight(ui:GetContent():GetHeight() - 40)

	-- ***** Hide scrollbars by setting the color to transparent *****

	scrollPane:SetColor({r = 0.153, g = 0.314, b = 0.490, a = 1})	
	scrollPane:SetColorInner({r = 0, g = 0, b = 0, a = 1})
	scrollPane:SetColorHighlight({r = 0.153, g = 0.314, b = 0.490, a = 1})

	scrollPane:SetLayer(1)
		
	content = LibEKL.uiCreateFrame("nkFrame", name .. '.content', scrollPane)
	content:SetWidth(ui:GetContent():GetWidth())	
	
	function ui:getScrollPane()
		return scrollPane
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

	function ui:SetCategories(categories)
		questCategories = categories
	end

	return ui

end

local function fillLog ()

    local quests = inspectQuestList()

    if not quests then return end
    
    local questDetail = inspectQuestDetail(quests)
    
    local zones = {}
	local tags = {}

    for questID, v in pairs (questDetail) do
        local zone = LibQB.query.getZoneByQuest (questID)
        if zone == "UNKNOWN_ZONE" then
			if not v.tag then v.tag = 'personal' end
        	tags[v.tag] = true
        else
			if not zones[zone] then
				local thisZone = inspectZoneDetail(zone)
            	zones[thisZone.name] = true
			end
        end        
    end

	local zoneNames = LibEKL.Tools.Table.GetSortedKeys(zones)
	local tagNames = LibEKL.Tools.Table.GetSortedKeys(tags)

	local lastObject
	local categories = {}

	for idx = 1, #zoneNames, 1 do
		local questCategory = questLog.questCategory(zoneNames[idx], uiElements.questLog:getScrollPane())

		if idx == 1 then
			questCategory:SetPoint("TOPLEFT", uiElements.questLog:getScrollPane(), "TOPLEFT")
		else
			questCategory:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT")
		end

		table.insert(categories, questCategory)
		
		lastObject = questCategory
	end

	for idx = 1, #tagNames, 1 do
		local questCategory = questLog.questCategory(tagNames[idx], uiElements.questLog:getScrollPane())

		if not lastObject then
			questCategory:SetPoint("TOPLEFT", uiElements.questLog:getScrollPane(), "TOPLEFT")
		else
			questCategory:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT")
		end

		table.insert(categories, questCategory)
		
		lastObject = questCategory
	end

	uiElements.questLog:SetCategories(categories)
	uiElements.questLog:RecalcHeight()

end

function internalFunc.questLogInit()

    if not uiElements.questLog then uiElements.questLog = uiQuestLog() end
    fillLog ()

end

