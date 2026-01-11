local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local langTexts		= privateVars.langTexts

local stringFormat	= string.format

local itemRewards = {}
local chooseableRewards = {}
local typeTags = {}

function questLog.questDetail (name, parent)

	local parentContent = parent:GetContent()

	local ui = LibEKL.UICreateFrame("nkFrame", name, parent)
	ui:SetPoint ("TOPRIGHT", parentContent, "TOPRIGHT", 0, 0)
	ui:SetPoint ("BOTTOMLEFT", parentContent, "BOTTOMLEFT",  (300 * data.uiScale), 0)


	-- Create a scroll frame for the quest details
	local scrollPane = LibEKL.UICreateFrame("nkScrollPane", "QuestDetailScroll", ui)
	scrollPane:SetPoint("TOPLEFT", ui, "TOPLEFT", 10, 10)

	scrollPane:SetWidth(ui:GetWidth() -20)
	scrollPane:SetHeight(ui:GetHeight() -20)
	scrollPane:SetAdjust(10)
	scrollPane:SetColor(0, 0, 0, .2)
    scrollPane:SetColorInner({ r = 0, g = 0, b = 0, a = .4})
    scrollPane:SetColorHighlight(data.theme.formElementColorMain)    	

	scrollPane:SetLayer(1)	

	-- Create a content frame for the scroll frame
	local contentFrame = LibEKL.UICreateFrame("nkFrame", "QuestDetailContent", scrollPane)
	scrollPane:SetContent(contentFrame)

	contentFrame:SetWidth(ui:GetWidth())
	contentFrame:SetHeight(1000)
	--contentFrame:SetBackgroundColor(1, 0, 0, 1)

	-- Create static UI elements with improved styling
	local title = LibEKL.UICreateFrame("nkText", "QuestTitle", contentFrame)
	title:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
	title:SetFontSize(18)
	title:SetFontColor(1, 1, 1, 1)
	title:SetEffectGlow({ strength = 3 })
	
	LibEKL.UI.SetFont(title, addonInfo.id, "MontserratBold")	

	local level = LibEKL.UICreateFrame("nkText", "QuestLevel", contentFrame)
	level:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", -50, 0)
	level:SetFontSize(18)
	level:SetFontColor(1, 1, 1, 1)
	level:SetEffectGlow({ strength = 3 })
	
	LibEKL.UI.SetFont(level, addonInfo.id, "MontserratBold")	

	local tagFrame = LibEKL.UICreateFrame("nkFrame", "QuestType", contentFrame)
	tagFrame:SetWidth(contentFrame:GetWidth() - 20)
	tagFrame:SetHeight(25)
	--tagFrame:SetBackgroundColor(1, 0, 0, .2)
	tagFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 15)

	local summary = LibEKL.UICreateFrame("nkText", "QuestSummary", contentFrame)
	summary:SetPoint("TOPLEFT", tagFrame, "BOTTOMLEFT", 0, 15)
	summary:SetFontSize(14)
	summary:SetWordwrap(true)
	summary:SetWidth(contentFrame:GetWidth() - 20)
	summary:SetEffectGlow({ strength = 3 })
	
	LibEKL.UI.SetFont(summary, addonInfo.id, "MontserratSemiBoldItalic")

	local objectivesFrame = questLog.uiObjectives (name .. ".objectiveFrame", contentFrame)
	objectivesFrame:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, 15)

	local rewardsFrame = questLog.uiRewards (name .. ".rewardsFrame", contentFrame)
	rewardsFrame:SetPoint("TOPLEFT", objectivesFrame, "BOTTOMLEFT", 0, 15)

	local guaranteedItemsFrame = questLog.uiItemRewards ("guaranteed", name .. ".itemsFrame", contentFrame)
	guaranteedItemsFrame:SetPoint("TOPLEFT", rewardsFrame, "BOTTOMLEFT", 0, 15)

	local chooseItemFrame = questLog.uiItemRewards ("choose", name .. ".itemsFrame", contentFrame)
	chooseItemFrame:SetPoint("TOPLEFT", guaranteedItemsFrame, "BOTTOMLEFT", 0, 15)

	local descriptionFrame = questLog.uiBox (name .. ".description", contentFrame)	
	descriptionFrame:SetTitle(langTexts.questLog.detailedDescription)

	local description = LibEKL.UICreateFrame("nkText", "QuestDescription", descriptionFrame)
	description:SetPoint("TOPLEFT", descriptionFrame:GetTitle(), "BOTTOMLEFT", 0, 10)
	description:SetFontSize(14)
	description:SetWordwrap(true)
	description:SetWidth(descriptionFrame:GetWidth() - 20)
	description:SetEffectGlow({ strength = 3 })
	
	LibEKL.UI.SetFont(description, addonInfo.id, "MontserratSemiBoldItalic")

	-- Function to update quest details
	function ui:UpdateQuestDetails(thisDetails)

		local lvl, libDetails = LibQB.query.byKey(thisDetails.id, true)

		if libDetails ~= nil then		
			thisDetails.level = lvl		

			local color = "#009900"
			local playerLevel = LibEKL.Unit.getPlayerDetails().level

			if lvl == nil then
				color = "#009900"
			elseif lvl < playerLevel -7 then
				color = "#8E8E8E"
			elseif lvl > playerLevel +5 then
				color = "#FF3333"
			elseif lvl > playerLevel + 2 then
				color = "#FF8000"
			end

			if color ~= nil and thisDetails.level ~= nil then
				thisDetails.level = stringFormat("Level <font color='%s'>%s</font>", color, thisDetails.level)
			end
		end

		-- Update static elements
		title:SetText(thisDetails.name or "")
		level:SetText(thisDetails.level or "", true)

		for _, tag in pairs(typeTags) do
			tag:SetVisible(false)
		end
		
		local prevTag = tagFrame
		local from, object, to, x = "TOPLEFT", tagFrame, "TOPLEFT", 0

		if thisDetails.tagName then
			local tags = LibEKL.strings.split(thisDetails.tagName, ", ")

			for idx = 1, #tags, 1 do
				local thisTag

				if idx > #typeTags then
					thisTag = questLog.questDetailTag (name .. ".tag." .. idx, tagFrame)
					table.insert(typeTags, thisTag)
				else
					thisTag = typeTags[idx]
				end

				thisTag:SetVisible(true)
				thisTag:SetText(tags[idx])
				thisTag:SetPoint (from, object, to, x, 0)

				from, object, to, x = "TOPLEFT", thisTag, "TOPRIGHT", 10
			end
		end
		
		summary:SetText(thisDetails.summary or "")
		summary:SetWidth(contentFrame:GetWidth() - 20)

		objectivesFrame:AddObjectives(thisDetails.objective)

		rewardsFrame:SetPoint("TOPLEFT", objectivesFrame, "BOTTOMLEFT", 0, 15)
		rewardsFrame:SetRewards(thisDetails)

		guaranteedItemsFrame:SetItems (thisDetails.rewardGuaranteed)
		chooseItemFrame:SetItems (thisDetails.rewardChoose)

		if guaranteedItemsFrame:GetVisible() then
			chooseItemFrame:SetPoint("TOPLEFT", guaranteedItemsFrame, "BOTTOMLEFT", 0, 10)
		elseif rewardsFrame:GetVisible() then
			chooseItemFrame:SetPoint("TOPLEFT", rewardsFrame, "BOTTOMLEFT", 0, 10)
		else
			chooseItemFrame:SetPoint("TOPLEFT", objectivesFrame, "BOTTOMLEFT", 0, 10)
		end

		-- Position detailed description below rewards

		if thisDetails.description then
			description:ClearHeight()
			description:SetText(thisDetails.description)
			descriptionFrame:SetHeight(description:GetHeight()+55)
			descriptionFrame:SetVisible(true)

			if chooseItemFrame:GetVisible() then
				descriptionFrame:SetPoint("TOPLEFT", chooseItemFrame, "BOTTOMLEFT", 0, 10)
			elseif guaranteedItemsFrame:GetVisible() then
				descriptionFrame:SetPoint("TOPLEFT", guaranteedItemsFrame, "BOTTOMLEFT", 0, 10)
			elseif rewardsFrame:GetVisible() then				
				descriptionFrame:SetPoint("TOPLEFT", rewardsFrame, "BOTTOMLEFT", 0, 10)
			else
				descriptionFrame:SetPoint("TOPLEFT", objectivesFrame, "BOTTOMLEFT", 0, 10)
			end
		else
			
			descriptionFrame:SetVisible(false)
		end
		
	
		totalHeight = 2500

		contentFrame:SetHeight(totalHeight)

		local value = scrollPane:GetLanePosition()
		scrollPane:SetContent(contentFrame)
		if value ~= nil then scrollPane:SetLanePosition(value) end
	end

	return ui

end

