local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local langTexts		= privateVars.langTexts

local stringFormat	= string.format

local itemRewards = {}
local chooseableRewards = {}

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

	--scrollPane:SetColor({r = 0.153, g = 0.314, b = 0.490, a = 0})
	--scrollPane:SetColorInner({r = 0, g = 0, b = 0, a = 0})
	--scrollPane:SetColorHighlight({r = 0.153, g = 0.314, b = 0.490, a = 0})

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

	local typeText = LibEKL.UICreateFrame("nkText", "QuestType", contentFrame)
	typeText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
	typeText:SetFontSize(14)
	typeText:SetFontColor(0.8, 0.8, 0.8, 1)
	typeText:SetEffectGlow({ strength = 3 })
	
	LibEKL.UI.SetFont(typeText, addonInfo.id, "MontserratSemiBold")

	local summary = LibEKL.UICreateFrame("nkText", "QuestSummary", contentFrame)
	summary:SetPoint("TOPLEFT", typeText, "BOTTOMLEFT", 0, 15)
	summary:SetFontSize(14)
	summary:SetWordwrap(true)
	summary:SetWidth(contentFrame:GetWidth() - 10)
	summary:SetEffectGlow({ strength = 3 })
	
	LibEKL.UI.SetFont(summary, addonInfo.id, "Montserrat")

	local objectivesTitle = LibEKL.UICreateFrame("nkText", "ObjectivesTitle", contentFrame)
	objectivesTitle:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, 20)
	objectivesTitle:SetText("Objectives:")
	objectivesTitle:SetFontSize(16)
	objectivesTitle:SetFontColor(1, 1, 1, 1)
	objectivesTitle:SetEffectGlow({ strength = 3 })
	
	LibEKL.UI.SetFont(objectivesTitle, addonInfo.id, "MontserratBold")

	local rewardsTitle = LibEKL.UICreateFrame("nkText", "RewardsTitle", contentFrame)
	rewardsTitle:SetPoint("TOPLEFT", objectivesTitle, "BOTTOMLEFT", 0, 20)
	rewardsTitle:SetText("Rewards:")
	rewardsTitle:SetFontSize(16)
	rewardsTitle:SetFontColor(1, 1, 1, 1)
	rewardsTitle:SetEffectGlow({ strength = 3 })
	
	LibEKL.UI.SetFont(rewardsTitle, addonInfo.id, "MontserratBold")	

	-- Create detailed description element
	local detailedDescriptionTitle = LibEKL.UICreateFrame("nkText", "DetailedDescriptionTitle", contentFrame)
	detailedDescriptionTitle:SetText("Detailed Description:")
	detailedDescriptionTitle:SetFontSize(16)
	detailedDescriptionTitle:SetFontColor(1, 1, 1, 1)
	detailedDescriptionTitle:SetEffectGlow({ strength = 3 })
	
	LibEKL.UI.SetFont(detailedDescriptionTitle, addonInfo.id, "MontserratBold")		

	local detailedDescription = LibEKL.UICreateFrame("nkText", "DetailedDescription", contentFrame)
	detailedDescription:SetPoint("TOPLEFT", detailedDescriptionTitle, "BOTTOMLEFT", 0, 5)
	detailedDescription:SetFontSize(14)
	detailedDescription:SetWordwrap(true)
	detailedDescription:SetWidth(contentFrame:GetWidth() - 10)
	detailedDescription:SetEffectGlow({ strength = 3 })
	
	LibEKL.UI.SetFont(detailedDescription, addonInfo.id, "Montserrat")		

	local coinReward = LibEKL.UICreateFrame("nkText", "CoinReward", contentFrame)
	coinReward:SetFontSize(14)
	coinReward:SetEffectGlow({ strength = 3 })

	LibEKL.UI.SetFont(coinReward, addonInfo.id, "Montserrat")		

	local expReward = LibEKL.UICreateFrame("nkText", "ExpReward", contentFrame)		
	expReward:SetFontSize(14)
	expReward:SetEffectGlow({ strength = 3 })

	LibEKL.UI.SetFont(expReward, addonInfo.id, "Montserrat")		
	
	local itemReward = LibEKL.UICreateFrame("nkText", "ItemReward", contentFrame)
	itemReward:SetFontSize(14)
	itemReward:SetEffectGlow({ strength = 3 })

	LibEKL.UI.SetFont(itemReward, addonInfo.id, "Montserrat")

	local prestigeReward = LibEKL.UICreateFrame("nkText", "prestigeReward", contentFrame)
	prestigeReward:SetFontSize(14)
	prestigeReward:SetEffectGlow({ strength = 3 })

	LibEKL.UI.SetFont(prestigeReward, addonInfo.id, "Montserrat")

	local favorReward = LibEKL.UICreateFrame("nkText", "favorReward", contentFrame)
	favorReward:SetFontSize(14)
	favorReward:SetEffectGlow({ strength = 3 })

	LibEKL.UI.SetFont(favorReward, addonInfo.id, "Montserrat")
	
	local guarantueedItemFrame = LibEKL.UICreateFrame("nkFrame", "guarantueedItemFrame", contentFrame)
	guarantueedItemFrame:SetWidth(contentFrame:GetWidth() - 30)
	guarantueedItemFrame:SetVisible(false)

	local guaranteedRewardsTitle = LibEKL.UICreateFrame("nkText", "GuaranteedRewardsTitle", guarantueedItemFrame)
	guaranteedRewardsTitle:SetText("Guaranteed Rewards:")
	guaranteedRewardsTitle:SetFontSize(16)
	guaranteedRewardsTitle:SetFontColor(1, 1, 1, 1)	
	guaranteedRewardsTitle:SetEffectGlow({ strength = 3 })
	guaranteedRewardsTitle:SetPoint("TOPLEFT", guarantueedItemFrame, "TOPLEFT", 0, 0)
	
	LibEKL.UI.SetFont(guaranteedRewardsTitle, addonInfo.id, "MontserratBold")	

	local chooseItemFrame = LibEKL.UICreateFrame("nkFrame", "chooseItemFrame", contentFrame)
	chooseItemFrame:SetWidth(contentFrame:GetWidth() - 30)
	chooseItemFrame:SetVisible(false)

	local chooseableRewardsTitle = LibEKL.UICreateFrame("nkText", "ChooseableRewardsTitle", chooseItemFrame)
	chooseableRewardsTitle:SetText("Chooseable Rewards:")
	chooseableRewardsTitle:SetFontSize(16)
	chooseableRewardsTitle:SetFontColor(1, 1, 1, 1)
	chooseableRewardsTitle:SetEffectGlow({ strength = 3 })
	chooseableRewardsTitle:SetPoint("TOPLEFT", chooseItemFrame, "TOPLEFT", 0, 0)
	
	LibEKL.UI.SetFont(chooseableRewardsTitle, addonInfo.id, "MontserratBold")		


	-- Tables to store dynamic elements
	local objectives = {}
	local rewards = {}
	local factionRewards = {}

	table.insert(rewards, coinReward)
	table.insert(rewards, expReward)
	table.insert(rewards, repReward)
	table.insert(rewards, repReward)

	-- Function to update quest details
	function ui:UpdateQuestDetails(thisDetails)

		-- Clear previous dynamic content
		for _, objective in ipairs(objectives) do
			objective:SetVisible(false)
		end
		for _, reward in ipairs(rewards) do
			reward:SetVisible(false)
		end
		for _, reward in ipairs(factionRewards) do
			reward:SetVisible(false)
		end
		for _, reward in ipairs(itemRewards) do
			reward:SetVisible(false)
		end
		
		-- Check if player has patron ability
		local hasPatronAbility = false
		local ability = Inspect.Ability.New.Detail("A665FDAC7EDD37636")
		hasPatronAbility = ability ~= nil		
		
		-- Update static elements
		title:SetText(thisDetails.name or "")
		typeText:SetText(string.format("Type: %s", thisDetails.tagName or "Unknown"))
		summary:SetText(thisDetails.summary or "")

		-- Update objectives
		local prevObjective, objCount = 1
		for i, objective in ipairs(thisDetails.objective or {}) do
			local objectiveText

			if i > #objectives then
				objectiveText = LibEKL.UICreateFrame("nkText", "Objective"..i, contentFrame)
				objectiveText:SetWidth(contentFrame:GetWidth() - 20)
				objectiveText:SetWordwrap(true)
				objectiveText:SetFontSize(14)
				objectiveText:SetEffectGlow({ strength = 3})

				LibEKL.UI.SetFont(objectiveText, addonInfo.id, "Montserrat")

				table.insert(objectives, objectiveText)
			else
				objectiveText = objectives[i]
				objectiveText:SetVisible(true)
			end

			if i == 1 then
				objectiveText:SetPoint("TOPLEFT", objectivesTitle, "BOTTOMLEFT", 0, 5)
			else
				objectiveText:SetPoint("TOPLEFT", prevObjective, "BOTTOMLEFT", 0, 5)
			end

			-- Extract and remove count from description if present
			local description = objective.description or ""
			local countText = ""
			local cleanDescription = description:gsub("(%d+)/(%d+)", function(a, b)
				countText = string.format("[%d/%d]", a, b)
				return ""
			end)

			-- Use the extracted count or fall back to the objective count
			local status
			if countText ~= "" then
				status = countText
			else
				status = objective.complete and "[Complete]" or (objective.count and objective.count > 0 and string.format("[%d/%d]", objective.countDone or 0, objective.count) or "")
			end

			-- Set text color based on completion status
			if objective.complete then
				objectiveText:SetFontColor(0.5, 0.5, 0.5, 1) -- Darker grey for completed objectives
			else
				objectiveText:SetFontColor(1, 1, 1, 1) -- Normal color for active objectives
			end

			objectiveText:SetText(status ~= "" and string.format("%s %s", status, cleanDescription) or cleanDescription)
			prevObjective = objectiveText
		end

		rewardsTitle:SetPoint("TOPLEFT", prevObjective, "BOTTOMLEFT", 0, 15)

		-- Update rewards
		local prevReward
		if thisDetails.rewardCoin and thisDetails.rewardCoin > 0 then
			coinReward:SetPoint("TOPLEFT", rewardsTitle, "BOTTOMLEFT", 0, 5)
			local platin = math.floor(thisDetails.rewardCoin / 10000)
			local gold = math.floor((thisDetails.rewardCoin - (platin * 10000)) / 100)
			local silver = thisDetails.rewardCoin - (platin * 10000) - (gold * 100)

			-- Build the coin string with only non-zero values
			local coinParts = {}
			if platin > 0 then
				table.insert(coinParts, string.format("%d<font color=\"#efebff\">p</font>", platin))
			end
			if gold > 0 then
				table.insert(coinParts, string.format("%d<font color=\"#eed234\">g</font>", gold))
			end
			if silver > 0 then
				table.insert(coinParts, string.format("%d<font color=\"#a7aba7\">s</font>", silver))
			end

			-- Combine the parts with spaces
			local coinText = table.concat(coinParts, " ")

			-- Add the "Coins" prefix and patron bonus if applicable
			if hasPatronAbility then
				local bonusPlatin = math.floor(thisDetails.rewardCoin * 0.15 / 10000)
				local bonusGold = math.floor((thisDetails.rewardCoin * 0.15 - (bonusPlatin * 10000)) / 100)
				local bonusSilver = math.floor(thisDetails.rewardCoin * 0.15 - (bonusPlatin * 10000) - (bonusGold * 100))

				local bonusParts = {}
				if bonusPlatin > 0 then
					table.insert(bonusParts, string.format("%d<font color=\"#efebff\">p</font>", bonusPlatin))
				end
				if bonusGold > 0 then
					table.insert(bonusParts, string.format("%d<font color=\"#eed234\">g</font>", bonusGold))
				end
				if bonusSilver > 0 then
					table.insert(bonusParts, string.format("%d<font color=\"#a7aba7\">s</font>", bonusSilver))
				end

				local bonusText = table.concat(bonusParts, " ")
				coinReward:SetText(string.format("Coins: %s (+ %s)", coinText, bonusText), true)
			else
				coinReward:SetText(string.format("Coins: %s", coinText), true)
			end
			coinReward:SetVisible(true)
			prevReward = coinReward
		end

		if thisDetails.rewardExperience and thisDetails.rewardExperience > 0 then				
			expReward:SetPoint("TOPLEFT", prevReward or rewardsTitle, "BOTTOMLEFT", 0, 5)
			if hasPatronAbility then
				local bonusExp = math.floor(thisDetails.rewardExperience * 0.4)
				expReward:SetText(string.format("Experience: %d (+ %d)", thisDetails.rewardExperience, bonusExp))
			else
				expReward:SetText(string.format("Experience: %d", thisDetails.rewardExperience))
			end
			expReward:SetVisible(true)
			prevReward = expReward
		end

		if thisDetails.rewardFavor and thisDetails.rewardFavor > 0 then
			favorReward:SetPoint("TOPLEFT", prevReward or rewardsTitle, "BOTTOMLEFT", 0, 5)
			if hasPatronAbility then
				local bonusFavor = math.floor(thisDetails.rewardFavor * 0.4)
				favorReward:SetText(string.format("Favor: %d (+ %d)", thisDetails.rewardFavor, bonusFavor))
			else
				favorReward:SetText(string.format("Favor: %d", thisDetails.rewardFavor))
			end
			favorReward:SetVisible(true)
			prevReward = favorReward
		end

		if thisDetails.rewardPrestige and thisDetails.rewardPrestige > 0 then
			prestigeReward:SetPoint("TOPLEFT", prevReward or rewardsTitle, "BOTTOMLEFT", 0, 5)
			if hasPatronAbility then
				local bonusPrestige = math.floor(thisDetails.rewardPrestige * 0.4)
				prestigeReward:SetText(string.format("Prestige: %d (+ %d)", thisDetails.rewardPrestige, bonusPrestige))
			else
				prestigeReward:SetText(string.format("Prestige: %d", thisDetails.rewardPrestige))
			end
			prestigeReward:SetVisible(true)
			prevReward = prestigeReward
		end

		if thisDetails.rewardNotoriety then
			local count = 1
			for factionId, amount in pairs(thisDetails.rewardNotoriety) do
				local factionName = Inspect.Faction.Detail(factionId).name or "Unknown Faction"					
				local thisFactionReward
				if count > #factionRewards then
					thisFactionReward = LibEKL.UICreateFrame("nkText", name .. ".RepReward." .. count, contentFrame)
					thisFactionReward:SetFontSize(14)
					thisFactionReward:SetEffectGlow({ strength = 3 })

					LibEKL.UI.SetFont(thisFactionReward, addonInfo.id, "Montserrat")
					table.insert(factionRewards, thisFactionReward)
				else
					thisFactionReward = factionRewards[count] 
				end

				count = count + 1

				thisFactionReward:SetPoint("TOPLEFT", prevReward or rewardsTitle, "BOTTOMLEFT", 0, 5)
				if hasPatronAbility then
					local bonusNotoriety = math.floor(amount * 0.4)
					thisFactionReward:SetText(string.format("Reputation with %s: %d (+ %d)", factionName, amount, bonusNotoriety))
				else
					thisFactionReward:SetText(string.format("Reputation with %s: %d", factionName, amount))
				end
				thisFactionReward:SetVisible(true)
				prevReward = thisFactionReward
			end
		end

		if not prevReward then
			rewardsTitle:SetVisible(false)
			prevReward = prevObjective
		else
			rewardsTitle:SetVisible(true)
		end

		for _, v in pairs(itemRewards) do
			v:SetVisible(false)
		end

		for _, v in pairs(chooseableRewards) do
			v:SetVisible(false)
		end

		-- Display guaranteed rewards
		if questLog.DisplayItems(name .. ".rewardGuaranteed", guarantueedItemFrame, guaranteedRewardsTitle, thisDetails.rewardGuaranteed, itemRewards) then
			guarantueedItemFrame:SetPoint("TOPLEFT", prevReward, "BOTTOMLEFT", 0, 15)
			prevReward = guarantueedItemFrame			
		else
			guarantueedItemFrame:SetVisible(false)
		end

		-- Display chooseable rewards
		if questLog.DisplayItems(name .. ".rewardChoose", chooseItemFrame, chooseableRewardsTitle, thisDetails.rewardChoose, chooseableRewards) then
			chooseItemFrame:SetPoint("TOPLEFT", prevReward, "BOTTOMLEFT", 0, 15)
			prevReward = chooseItemFrame
		else
			chooseItemFrame:SetVisible(false)
		end

		-- Position detailed description below rewards

		if thisDetails.description then
			detailedDescriptionTitle:SetPoint("TOPLEFT", prevReward or rewardsTitle, "BOTTOMLEFT", 0, 20)
			detailedDescription:SetText(thisDetails.description or "")
			detailedDescriptionTitle:SetVisible(true)
			detailedDescription:SetVisible(true)
		else
			detailedDescriptionTitle:SetVisible(false)
			detailedDescription:SetVisible(false)
		end
		
		local totalHeight = 0

		-- Add height for static elements
		totalHeight = totalHeight + title:GetHeight()
		totalHeight = totalHeight + typeText:GetHeight()
		totalHeight = totalHeight + summary:GetHeight()
		totalHeight = totalHeight + objectivesTitle:GetHeight()
		totalHeight = totalHeight + rewardsTitle:GetHeight()
		
		if guaranteedRewardsTitle:GetVisible() then
			totalHeight = totalHeight + guaranteedRewardsTitle:GetHeight()
		end

		if chooseableRewardsTitle:GetVisible() then
			totalHeight = totalHeight + chooseableRewardsTitle:GetHeight()
		end

		totalHeight = totalHeight + detailedDescriptionTitle:GetHeight()
		totalHeight = totalHeight + detailedDescription:GetHeight()

		-- Add height for dynamic elements
		for _, objective in ipairs(objectives) do
			if objective:GetVisible() then
				totalHeight = totalHeight + objective:GetHeight() + 5 -- Add spacing
			end
		end

		for _, reward in ipairs(rewards) do
			if reward:GetVisible() then
				totalHeight = totalHeight + reward:GetHeight() + 5 -- Add spacing
			end
		end

		for _, reward in ipairs(factionRewards) do
			if reward:GetVisible() then
				totalHeight = totalHeight + reward:GetHeight() + 5 -- Add spacing
			end
		end

		-- Add height for item rewards (each row is 60px high with 10px spacing)
		local visibleItemRewards = 0
		for _, reward in ipairs(itemRewards) do
			if reward:GetVisible() then
				visibleItemRewards = visibleItemRewards + 1
			end
		end
		local itemRewardRows = math.ceil(visibleItemRewards / 2)
		totalHeight = totalHeight + (itemRewardRows * 60) + ((itemRewardRows - 1) * 10)

		-- Add height for chooseable rewards (each row is 60px high with 10px spacing)
		local visibleChooseableRewards = 0
		for _, reward in ipairs(chooseableRewards) do
			if reward:GetVisible() then
				visibleChooseableRewards = visibleChooseableRewards + 1
			end
		end

		local chooseableRewardRows = math.ceil(visibleChooseableRewards / 2)
		totalHeight = totalHeight + (chooseableRewardRows * 60) + ((chooseableRewardRows - 1) * 10)

		-- Add some padding at the bottom
		totalHeight = totalHeight + 200

		contentFrame:SetHeight(totalHeight)

		local value = scrollPane:GetLanePosition()
		scrollPane:SetContent(contentFrame)
		if value ~= nil then scrollPane:SetLanePosition(value) end
	end

	return ui

end

