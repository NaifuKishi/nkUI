local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local langTexts		= privateVars.langTexts

local inspectMouse			= Inspect.Mouse
local inspectSystemSecure	= Inspect.System.Secure
local inspectQuestDetail	= Inspect.Quest.Detail

---------- init local variables ---------

local colorR, colorG, colorB, colorA = 0.9, 0.74, 0, 1
local categoryOrder = { "battlepass", "crafting", "daily", "weekly", "monthly", "guild", "ia", "pvp", "world", "zone", "area", "instant", "raid", "story", "personal", "carnage"}

---------- local function block ---------

---------- addon internal function block ---------

function questLog.buildUI ()

	local name = "nkUI.questLog"
	local scrollPane, content
	local lastTitle

	local ui = LibEKL.UICreateFrame("nkWindow", name, questLog.context)
	
	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.questLog.x, nkUISetup.modules.questLog.y)
	ui:SetWidth(1000 * data.uiScale)
	ui:SetHeight(800 * data.uiScale)
	ui:SetBackgroundColor(0, 0, 0, 0)
	ui:SetLayer(1)
	ui:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    ui:SetTitleFontSize(16)
    ui:SetTitleEffect({ strength = 3})
    ui:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

	ui:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(12, 12, math.pi / 4, 0, 0),  -- 45° rotation
        color = {
            {r = 0.1294, g = 0.1533, b = 0.2157, a = 1, position = 0}, -- Start color
            {r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1}  -- End color
        }
    },  {
        r = 0x66 / 255,
        g = 0x56 / 255,
        b = 0x2e / 255,
        a = 1,
        cap = "round",
        miter = "miter",
        thickness = 2
    })


	-- ********* SCROLL PANE
			
	scrollPane = LibEKL.UICreateFrame("nkScrollPane", name .. 'scrollPane', ui)
	scrollPane:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT", 5, 5)
	scrollPane:SetWidth(300 * data.uiScale)
	scrollPane:SetHeight(ui:GetContent():GetHeight() - ui:GetHeader():GetHeight())
	scrollPane:SetAdjust(100)
	
	scrollPane:SetColor(0, 0, 0, .2)
    scrollPane:SetColorInner({ r = 0, g = 0, b = 0, a = .4})
    scrollPane:SetColorHighlight(data.theme.formElementColorMain)    	

	--scrollPane:SetColor({r = 0.153, g = 0.314, b = 0.490, a = 0})
	--scrollPane:SetColorInner({r = 0, g = 0, b = 0, a = 0})
	--scrollPane:SetColorHighlight({r = 0.153, g = 0.314, b = 0.490, a = 0})

	scrollPane:SetLayer(1)	
		
	content = UI.CreateFrame("Frame", name .. '.content', scrollPane)
	content:SetWidth(scrollPane:GetWidth())

	questDetail = questLog.questDetail (name .. ".QuestDetails", ui)

	function ui:UpdateQuestDetails(questKey)
		local questDetails = inspectQuestDetail(questKey)
		if questDetails then
			questDetail:UpdateQuestDetails(questDetails)
		end
	end
		
	local questCategories = {}

	for idx = 1, #categoryOrder, 1 do
		local thisCategory = questLog.questCategory(categoryOrder[idx], content)
		thisCategory:SetVisible(false)
		thisCategory:SetHeight(0)
		table.insert(questCategories, thisCategory)
	end

	function ui:ReorderCategories()

		-- Create a table to store the category order with names
		local categoryOrderWithNames = {}
		for _, category in ipairs(questCategories) do
			
			local name = category:GetCategory()

			if langTexts.showCategoryCheckbox[name] then
				name = langTexts.showCategoryCheckbox[name]
			end

			category:ClearPoint("TOPLEFT")			
			table.insert(categoryOrderWithNames, {name = name, original = category})
		end

		-- Sort the categoryOrderWithNames table by name
		table.sort(categoryOrderWithNames, function(a, b)
			return a.name < b.name
		end)

		-- Extract the sorted category order
		local sortedCategoryOrder = {}
		for idx = 1, #categoryOrderWithNames, 1 do
			if idx == 1 then
				categoryOrderWithNames[idx].original:SetPoint("TOPLEFT", content, "TOPLEFT")
			else
				categoryOrderWithNames[idx].original:SetPoint("TOPLEFT", categoryOrderWithNames[idx-1].original, "BOTTOMLEFT")
			end
		end
	end

	ui:ReorderCategories()
	
	---------------------------------------
	----- UI dimension recalculations -----
		
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
	
	function ui:AddQuest(key, questCategory, title, subTitle, level)

		local hasCategory = false

		for k, v in pairs(questCategories) do
			if v:GetCategory() == questCategory then
				v:AddQuest(key, title, subTitle, level)
				v:RecalcHeight() 
				v:SetVisible(true)
				ui:RecalcHeight()				
				hasCategory = true
				break
			end
		end

		if not hasCategory then
			local thisCategory = questLog.questCategory(questCategory, content)
			table.insert(questCategories, thisCategory)
			thisCategory:AddQuest(key, title, subTitle, level)
			thisCategory:RecalcHeight() 
			thisCategory:SetVisible(true)
			ui:RecalcHeight()
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
	
	function ui:UpdateQuest(key, questCategory, title, subTitle, complete, level)
		for k, v in pairs(questCategories) do
			if v:GetCategory() == questCategory and v:HasQuest(key) then 
				if v:UpdateQuest(key, title, subTitle, complete, level) == false then
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
			if v:GetQuestCount() > 0 then
				v:SetVisible(true)
				v:UpdateDesign(updateContent)
			else
				v:SetHeight(0)
				v:SetVisible(false)
			end
		end
		
		ui:RecalcHeight()
	end

	local oSetVisible = ui.SetVisible

    function ui:SetVisible(visible)
        oSetVisible(self, visible)
        if ui:GetLeft() > UIParent:GetWidth() then
            local x = UIParent:GetWidth() - ui:GetWidth()
            nkUISetup.modules.questLog.x = x
			ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.questLog.x, nkUISetup.modules.questLog.y)
        end
    end

	
	return ui

end