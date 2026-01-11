local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local langTexts		= privateVars.langTexts

local DEFAULT_REWARD_SIZE = 14

local rewards = {}
local notorieties = {}

local function rewardElement (name, parent)

    local rewardIcon = LibEKL.UICreateFrame("nkTexture", name, parent)
    rewardIcon:SetWidth(DEFAULT_REWARD_SIZE)
    rewardIcon:SetHeight(DEFAULT_REWARD_SIZE)
    
    local rewardText = LibEKL.UICreateFrame("nkText", name .. ".text", parent)
    rewardText:SetPoint("CENTERLEFT", rewardIcon, "CENTERRIGHT", 10, 0)
    rewardText:SetWidth(parent:GetWidth() - DEFAULT_REWARD_SIZE - 10 - 20)
    rewardText:SetWordwrap(true)
    rewardText:SetFontSize(DEFAULT_REWARD_SIZE)
    rewardText:SetEffectGlow({ strength = 3})

    LibEKL.UI.SetFont(rewardText, addonInfo.id, "MontserratSemiBold")

    function rewardIcon:SetType(rewardType)

        local rewardIcons = { 
            exp = "gfx/questIconExp.png", 
            coin = "gfx/questIconCoin.png", 
            notority = "gfx/questIconNotority.png", 
            prestige = "gfx/questIconPrestige.png", 
            favor = "gfx/questIconFavor.png",
            guildExp = "gfx/questIconGuildExp.png"
        }
        
        local rewardColors = { 
            exp = { .6, .4, .8},
            coin = {.914, .733, .188},
            notority = {.235, .655, .863}, 
            prestige = {.6, .4, .8}, 
            favor = { .639, .102, .902},
            guildExp = {0.18, .722, .404}
        }

        rewardIcon:SetTextureAsync("nkUI", rewardIcons[rewardType])
        rewardText:SetFontColor(rewardColors[rewardType][1], rewardColors[rewardType][2], rewardColors[rewardType][3], 1)
    end

    function rewardIcon:SetText(value, suffix, bonus)
        local thisText = string.format("%s", value)
        if suffix then thisText = string.format("%s <font color=\"#7a869c\">%s</font>", thisText, suffix) end
        if bonus then thisText = string.format("%s <font color=\"#2a9c5c\">(+ %s)</font>", thisText, bonus) end
        rewardText:SetText(thisText, true)
    end

    return rewardIcon

end

function questLog.uiRewards (name, parent)

    local ability = Inspect.Ability.New.Detail("A665FDAC7EDD37636")
	local hasPatron = ability ~= nil

    local rewardsFrame = questLog.uiBox (name , parent)	
	rewardsFrame:SetTitle("REWARDS")

    function rewardsFrame:SetRewardCoin(rewardCoin)
        local thisReward

        if rewards["coin"] == nil then
            thisReward = rewardElement (name .. ".coin", rewardsFrame)
            rewards["coin"] = thisReward
        else
            thisReward = rewards["coin"]
        end

        thisReward:SetVisible(true)
        thisReward:SetType("coin")

        local platin = math.floor(rewardCoin / 10000)
        local gold = math.floor((rewardCoin - (platin * 10000)) / 100)
        local silver = rewardCoin - (platin * 10000) - (gold * 100)

        -- Build the coin string with only non-zero values
        local coinParts = {}
        if platin > 0 then
            table.insert(coinParts, string.format("<font color=\"#efebff\">%dp</font>", platin))
        end
        if gold > 0 then
            table.insert(coinParts, string.format("<font color=\"#eed234\">%dg</font>", gold))
        end
        if silver > 0 then
            table.insert(coinParts, string.format("<font color=\"#a7aba7\">%ds</font>", silver))
        end

        -- Combine the parts with spaces
        local coinText = table.concat(coinParts, " ")

        -- Add the "Coins" prefix and patron bonus if applicable
        if hasPatron then
            local bonusPlatin = math.floor(rewardCoin * 0.15 / 10000)
            local bonusGold = math.floor((rewardCoin * 0.15 - (bonusPlatin * 10000)) / 100)
            local bonusSilver = math.floor(rewardCoin * 0.15 - (bonusPlatin * 10000) - (bonusGold * 100))

            local bonusParts = {}
            if bonusPlatin > 0 then
                table.insert(bonusParts, string.format("%dp", bonusPlatin))
            end
            if bonusGold > 0 then
                table.insert(bonusParts, string.format("%dg", bonusGold))
            end
            if bonusSilver > 0 then
                table.insert(bonusParts, string.format("%ds", bonusSilver))
            end

            local bonusText = table.concat(bonusParts, " ")
            thisReward:SetText(coinText, nil, bonusText)
        else
            thisReward:SetText(coinText, nil)
        end
    end

    function rewardsFrame:SetReward(rewardType, rewardValue)       
        local suffixList = { 
            exp = "Experience",
            prestige = "Prestige", 
            favor = "Favor",
            guildExp = "Guild Experience"
        }

        local thisReward

        if rewards[rewardType] == nil then
            thisReward = rewardElement (name .. "." .. rewardType, rewardsFrame)
            rewards[rewardType] = thisReward
        else
            thisReward = rewards[rewardType]
        end

        thisReward:SetVisible(true)
        thisReward:SetType(rewardType)

        if hasPatron then
            local bonusValue = math.floor(rewardValue * 0.4)
            thisReward:SetText(rewardValue, suffixList[rewardType], bonusValue)
        else
            thisReward:SetText(rewardValue, suffixList[rewardType])
        end
    end

    function rewardsFrame:SetNotoriety (rewardNotoriety)
		
        local count = 1
        for factionId, amount in pairs(rewardNotoriety) do
            
            local thisFactionReward

            if count > #notorieties then
                thisFactionReward = rewardElement (name .. ".notoriety." .. count, rewardsFrame)
                table.insert(notorieties, thisFactionReward)
            else
                thisFactionReward = notorieties[count] 
            end

            count = count + 1
            
            local factionName = Inspect.Faction.Detail(factionId).name or "Unknown Faction"					
            local suffix = string.format("Reputation with <font color=\"#3ca7dd\">%s</font>", factionName)

            if hasPatron then
                local bonusNotoriety = math.floor(amount * 0.4)
                thisFactionReward:SetText(rewardValue, suffix, bonusValue)
            else
                thisFactionReward:SetText(rewardValue, suffix)
            end

            thisFactionReward:SetVisible(true)
        end
	end

    function rewardsFrame:Clear()
        for _, v in pairs(rewards) do
            v:SetVisible(false)
        end

        for _, v in pairs(notorieties) do
            v:SetVisible(false)
        end
    end

    function rewardsFrame:Build()
        local height = 0 
        local from, objective, to = "TOPLEFT", rewardsFrame:GetTitle(), "BOTTOMLEFT"

        for _, reward in pairs (rewards) do
            if reward:GetVisible() then
                height = height + DEFAULT_REWARD_SIZE + 10
                reward:SetPoint(from, objective, to, 0, 10)
                from, objective, to = "TOPLEFT", reward, "BOTTOMLEFT"
            end            
        end

        for _, notoriety in pairs (notorieties) do
            if notoriety:GetVisible() then
                height = height + DEFAULT_REWARD_SIZE + 10
                notoriety:SetPoint(from, objective, to, 0, 10)
                from, objective, to = "TOPLEFT", reward, "BOTTOMLEFT"
            end
        end

        rewardsFrame:SetHeight(height + 45)
    end

    function rewardsFrame:SetRewards(thisDetails)
        rewardsFrame:Clear()
        
        if thisDetails.rewardCoin then rewardsFrame:SetRewardCoin(thisDetails.rewardCoin) end
        if thisDetails.rewardExperience then rewardsFrame:SetReward("exp", thisDetails.rewardExperience) end
        if thisDetails.rewardExperienceGuild then rewardsFrame:SetReward("guildExp", thisDetails.rewardExperienceGuild) end
        if thisDetails.rewardFavor then rewardsFrame:SetReward("favor", thisDetails.rewardFavor) end
        if thisDetails.rewardPrestige then rewardsFrame:SetReward("prestige", thisDetails.rewardPrestige) end
        if thisDetails.rewardrewardNotorietyPrestige then rewardsFrame:SetNotoriety(thisDetails.rewardNotoriety) end
        
        rewardsFrame:Build()
    end

    return rewardsFrame

end

