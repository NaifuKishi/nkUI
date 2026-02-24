local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local langTexts		= privateVars.langTexts

local stringFormat	= string.format

local displayItems = {}

local DEFAULT_ITEM_SIZE = 90

local function uiItemReward(name, parent)

	local thisItem

	local ui = LibEKL.UICreateFrame("nkCanvas", name, parent)
	ui:SetWidth((parent:GetWidth() -10 - 30) /3 ) -- 3 items per row with spacing
	ui:SetHeight(DEFAULT_ITEM_SIZE)

	ui:EventAttach(Event.UI.Input.Mouse.Cursor.In, function ()
		Command.Tooltip(thisItem)
	end, name .. ".Cursor.In")	

	ui:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function ()
		Command.Tooltip(nil)
	end, name .. ".Cursor.Out")

    -- Create a square path
    local path = {
        {xProportional = 0, yProportional = 0},
        {xProportional = 1, yProportional = 0},
        {xProportional = 1, yProportional = 1},
        {xProportional = 0, yProportional = 1},
        {xProportional = 0, yProportional = 0}
    }

	local fill = {
        type = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, math.pi / 3, 0, 0), -- 180 degree angle
        color = {
            {r = 0.149, g = 0.165, b = 0.216, a = 1, position = 0}, -- Start color
            {r = 0.086, g = 0.11, b = 0.153, a = 1, position = 1}  -- End color
        }
    }

    -- Set stroke color (lighter thickness variant)
    local stroke = {
        r = 0x66 / 255,
        g = 0x56 / 255,
        b = 0x2e / 255,
        a = 1,
        cap = "round",
        miter = "miter",
        thickness = 1
    }

    ui:SetShape(path, fill, stroke)

	local texture = LibEKL.UICreateFrame("nkTexture", name .. ".texture", ui)
	texture:SetPoint("TOPCENTER", ui, "TOPCENTER", 0, 10)
	texture:SetWidth(40)
	texture:SetHeight(40)
	texture:SetLayer(1)

	local text = LibEKL.UICreateFrame("nkText", name .. ".text", ui)
	text:SetPoint("BOTTOMCENTER", texture, "BOTTOMCENTER")
	text:SetFontSize(14)
	text:SetEffectGlow({strength = 3})
	text:SetLayer(1)

	LibEKL.UI.SetFont(text, addonInfo.id, "MontserratSemiBold")

	local count = LibEKL.UICreateFrame("nkText", name .. ".count", ui)
	count:SetPoint("CENTER", texture, "CENTER")
	count:SetFontSize(18)
	count:SetEffectGlow({strength = 3})
	count:SetLayer(2)

	LibEKL.UI.SetFont(count, addonInfo.id, "MontserratSemiBold")

	local coin = LibEKL.UICreateFrame("nkText", name .. ".coin", ui)
	coin:SetPoint("TOPRIGHT", ui, "TOPRIGHT", -10, 10)
	coin:SetFontSize(12)
	coin:SetEffectGlow({strength = 3})
	coin:SetLayer(2)

	function ui:SetItem(key, amount)
		local details = Inspect.Item.Detail(key)

		if not details then return end

		thisItem = key

		local color = LibEKL.Inventory.GetItemColor(details.rarity)
		local stroke = {
			r = color.r,
			g = color.g,
			b = color.b,
			a = 1,
			cap = "round",
			miter = "miter",
			thickness = 1
    	}
		
		ui:SetShape(path, fill, stroke)

		texture:SetTextureAsync("Rift", details.icon)
		text:ClearWidth()
		text:ClearPoint("BOTTOMCENTER")
		text:SetText(details.name)

		if text:GetWidth() > ui:GetWidth() - 10 then
			text:SetWidth(ui:GetWidth() - 10)
		end
		
		text:SetPoint("TOPCENTER", texture, "BOTTOMCENTER", 0, 10)

		if amount and amount > 1 then
			count:SetText(stringFormat("%d", amount))
			count:SetVisible(true)
		else
			count:SetVisible(false)
		end
		
		local color = LibEKL.Inventory.GetItemColor(details.rarity)
        text:SetFontColor(color.r, color.g, color.b, 1)

		if details.sell then
			local platin = math.floor(details.sell / 10000)
			local gold = math.floor((details.sell - (platin * 10000)) / 100)
			local silver = details.sell - (platin * 10000) - (gold * 100)

			-- Build the coin string with only non-zero values
			local coinParts = {}
			if platin > 0 then
				table.insert(coinParts, string.format("<font color=\"#efebff\">%dp</font>", platin))
			end
			
			if gold > 0 or platin > 0 then
				table.insert(coinParts, string.format("<font color=\"#eed234\">%dg</font>", gold))
			end
			if silver > 0 or (platin > 0 or gold > 0) then
				table.insert(coinParts, string.format("<font color=\"#a7aba7\">%ds</font>", silver))
			end

			-- Combine the parts with spaces
			local coinText = table.concat(coinParts, " ")

			coin:SetText(coinText, true)			
			coin:SetVisible(true)
		else
			coin:SetVisible(false)
		end
	end

	return ui

end

function questLog.uiItemRewards (type, name, parent)

    local itemFrame = questLog.uiBox (name .. ".itemRewards." .. type, parent)
	
	if type == "guaranteed" then
		itemFrame:SetTitle(langTexts.questLog.guaranteedRewards)
	else
		itemFrame:SetTitle(langTexts.questLog.chooseableRewards)
	end
	
	local oSetTitle = itemFrame.SetTitle

	function itemFrame:SetTitle(newTitle)
		oSetTitle(self, newTitle)
	end

	function itemFrame:SetItems(items)

		if not items then 
			itemFrame:SetVisible(false)
			return 
		end

		itemFrame:SetVisible(true)

		if not displayItems[type] then displayItems[type] = {} end

		for _, v in pairs(displayItems[type]) do
			v:SetVisible(false)
		end

		local itemCount = 1
		local rowCount = 1
		local itemsInRow = 0
		local prevRowReward = nil
		local height = 0

		local itemRewardsTable = displayItems[type]

		for itemId, count in pairs(items) do

			local thisItemReward
			if itemCount > #itemRewardsTable then
				local thisName = string.format("%s.ItemReward.%s.%d", name, type, itemCount)
				thisItemReward = uiItemReward(thisName, itemFrame)
				table.insert(itemRewardsTable, thisItemReward)
			else
				thisItemReward = itemRewardsTable[itemCount]
			end

			-- Calculate position
			if itemsInRow == 0 then
				-- First item in row
				if rowCount == 1 then
					thisItemReward:SetPoint("TOPLEFT", itemFrame:GetTitle(), "BOTTOMLEFT", 0, 10)
				else
					thisItemReward:SetPoint("TOPLEFT", prevRowReward, "BOTTOMLEFT", 0, 10)
				end
				prevRowReward = thisItemReward
				height = height + DEFAULT_ITEM_SIZE + 10
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

			itemCount = itemCount + 1
		end

		itemFrame:SetHeight(height +45)
	end

	return itemFrame

end