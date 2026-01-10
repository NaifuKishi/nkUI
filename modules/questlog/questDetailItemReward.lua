local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local langTexts		= privateVars.langTexts

local stringFormat	= string.format

local itemRewards = {}
local chooseableRewards = {}

local function uiItemReward(name, parent)

	local ui = LibEKL.UICreateFrame("nkFrame", name, parent)
	ui:SetWidth((parent:GetWidth() -10) /3 ) -- 3 items per row with spacing
	ui:SetHeight(45) -- 25% smaller height

	local texture = LibEKL.UICreateFrame("nkTexture", name .. ".texture", ui)
	texture:SetPoint("TOPCENTER", ui, "TOPCENTER")
	texture:SetWidth(30) -- 25% smaller width
	texture:SetHeight(30) -- 25% smaller height

	local text = LibEKL.UICreateFrame("nkText", name .. ".text", ui)
	text:SetPoint("BOTTOMCENTER", ui, "BOTTOMCENTER")
	text:SetFontSize(12) -- 25% smaller font size
	text:SetEffectGlow({strength = 3})

	LibEKL.UI.SetFont(text, addonInfo.id, "MontserratSemiBold")

	local count = LibEKL.UICreateFrame("nkText", name .. ".count", texture)
	count:SetPoint("CENTER", texture, "CENTER")
	count:SetFontSize(12) -- 25% smaller font size
	count:SetEffectGlow({strength = 3})

	LibEKL.UI.SetFont(count, addonInfo.id, "MontserratSemiBold")

	function ui:SetItem(key, amount)
		local details = Inspect.Item.Detail(key)

		if not details then return end

		texture:SetTextureAsync("Rift", details.icon)
		text:ClearWidth()
		text:ClearPoint("BOTTOMCENTER")
		text:SetText(details.name)

		if text:GetWidth() > ui:GetWidth() then
			text:SetWidth(ui:GetWidth())
		end
		
		text:SetPoint("BOTTOMCENTER", ui, "BOTTOMCENTER")

		if amount then
			count:SetText(stringFormat("%d", amount))
			count:SetVisible(true)
		else
			count:SetVisible(false)
		end
		
		local color = LibEKL.Inventory.GetItemColor(details.rarity)
        text:SetFontColor(color.r, color.g, color.b, 1)		
	end

	return ui

end

function questLog.DisplayItems(name, parentFrame, titleItem, itemList, itemRewardsTable)

    if not itemList or next(itemList) == nil then
        parentFrame:SetVisible(false)
        return false
    end

    local itemCount = 1
    local rowCount = 1
    local itemsInRow = 0
    local prevRowReward = nil
    local lastLeftItem = nil
	
	parentFrame:SetVisible(true)
	--parentFrame:SetBackgroundColor(1, 0, 0, .2)

	local height = titleItem:GetHeight() + 5

    for itemId, count in pairs(itemList) do
        local thisItemReward
        if itemCount > #itemRewardsTable then
            thisItemReward = uiItemReward(name .. ".ItemReward." .. itemCount, parentFrame)
            table.insert(itemRewardsTable, thisItemReward)
        else
            thisItemReward = itemRewardsTable[itemCount]
        end

        -- Calculate position
        if itemsInRow == 0 then
            -- First item in row
            if rowCount == 1 then
                thisItemReward:SetPoint("TOPLEFT", titleItem, "BOTTOMLEFT", 0, 10)
				height = height + 45 -- 25% smaller height
            else
                thisItemReward:SetPoint("TOPLEFT", prevRowReward, "BOTTOMLEFT", 0, 10)
				height = height + 55 -- 25% smaller height with spacing
            end
            prevRowReward = thisItemReward
            lastLeftItem = thisItemReward
        else
            -- Second or third item in row
            thisItemReward:SetPoint("TOPLEFT", itemRewardsTable[itemCount - 1], "TOPRIGHT", 10, 0)
        end

        -- Set item and make visible
        thisItemReward:SetItem(itemId, count)
        thisItemReward:SetVisible(true)

        -- Update counters
        itemsInRow = itemsInRow + 1
        if itemsInRow >= 3 then -- Changed from 2 to 3
            itemsInRow = 0
            rowCount = rowCount + 1
        end

		parentFrame:SetHeight(height)
        itemCount = itemCount + 1
    end

	return true

end