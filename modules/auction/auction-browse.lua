local addonInfo, privateVars = ...

---------- init namespace ---------

local auction       = privateVars.auction
local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local langTexts     = privateVars.langTexts

---------- init local variables ---------

local InspectAuctionDetail = Inspect.Auction.Detail
local InspectItemDetail    = Inspect.Item.Detail
local InspectShard         = Inspect.Shard
local stringFormat         = string.format
local mathFloor            = math.floor
local tableInsert          = table.insert
local tableSort            = table.sort
local pairs                = pairs
local tostring             = tostring
local pcall                = pcall

local grid          = nil   -- nkGrid widget
local searchInput   = nil   -- nkTextField
local rarityBtns    = {}    -- [0..6] toggle button frames
local browseRows    = {}    -- raw row data before filter, for re-filter on toggle
local GRID_NAME     = "nkUI.auction.browse.grid"

---------- rarity colors and labels ----------

local RARITY_COLOR = {
    [0] = {r=0.8, g=0.8, b=0.8, a=1},   -- Common: grey
    [1] = {r=0.1, g=0.9, b=0.1, a=1},   -- Uncommon: green
    [2] = {r=0.0, g=0.5, b=1.0, a=1},   -- Rare: blue
    [3] = {r=0.6, g=0.1, b=0.9, a=1},   -- Epic: purple
    [4] = {r=1.0, g=0.5, b=0.0, a=1},   -- Relic: orange
    [5] = {r=1.0, g=0.9, b=0.2, a=1},   -- Transcendent: gold
    [6] = {r=0.9, g=0.4, b=0.4, a=1},   -- Primalist: pink-red
}
local RARITY_LABEL = { [0]="C", [1]="U", [2]="R", [3]="E", [4]="Rel", [5]="T", [6]="P" }

---------- local function block ---------

local function fmtCoins(v)
    if not v or v == 0 then return "-" end
    return internalFunc.formatCoins(v)
end

local function isRarityVisible(rarity)
    local rf = nkUISetup.modules.auction.browse.rarityFilter
    -- empty table = show all
    if not rf or next(rf) == nil then return true end
    return rf[rarity] == true
end

local function toggleRarity(rarity)
    local rf = nkUISetup.modules.auction.browse.rarityFilter
    if rf[rarity] then
        rf[rarity] = nil
    else
        rf[rarity] = true
    end
    -- Re-apply filter to browseRows (re-populate grid from cached data)
    applyFilterAndSort()
    updateRarityBtnVisuals()
end

local function updateRarityBtnVisuals()
    for rarity = 0, 6 do
        local btn = rarityBtns[rarity]
        if btn then
            local visible = isRarityVisible(rarity)
            if visible then
                btn:SetFillColor({ type = "solid", r = 0.1, g = 0.1, b = 0.1, a = 0.7 })
            else
                btn:SetFillColor({ type = "solid", r = 0.3, g = 0.1, b = 0.1, a = 0.7 })
            end
        end
    end
end

local function applyFilterAndSort()
    if not grid or not browseRows then return end

    local searchText = searchInput and searchInput:GetText() or ""
    searchText = searchText:lower()

    local filtered = {}
    for i = 1, #browseRows do
        local row = browseRows[i]
        local rarity = row.rarity

        -- Check rarity filter
        if not isRarityVisible(rarity) then
            -- skip this row
        else
            -- Check name filter
            local itemName = row.name or ""
            if searchText == "" or itemName:lower():find(searchText, 1, true) then
                tableInsert(filtered, row)
            end
        end
    end

    -- Sort by column
    local cfg = nkUISetup.modules.auction.browse
    local sortCol = cfg.sortCol or 7
    local sortAsc = cfg.sortAsc ~= false

    -- Determine sort key based on column
    -- For numeric columns (bid, buyout, unit, vs vendor, myPrice), sort numerically
    local numCols = { [5] = true, [6] = true, [7] = true, [8] = true, [9] = true }

    if numCols[sortCol] then
        tableSort(filtered, function(a, b)
            local aVal = a.sortKeys and a.sortKeys[sortCol] or 0
            local bVal = b.sortKeys and b.sortKeys[sortCol] or 0
            if sortAsc then
                return aVal < bVal
            else
                return aVal > bVal
            end
        end)
    else
        -- String sort for name, seller, stack, expiry
        tableSort(filtered, function(a, b)
            local aVal = a.row and a.row[sortCol] or ""
            local bVal = b.row and b.row[sortCol] or ""
            aVal = tostring(aVal):lower()
            bVal = tostring(bVal):lower()
            if sortAsc then
                return aVal < bVal
            else
                return aVal > bVal
            end
        end)
    end

    -- Convert to grid format
    local gridRows = {}
    for i = 1, #filtered do
        tableInsert(gridRows, filtered[i].row)
    end

    grid:SetCellValues(gridRows)
end

local function populateBrowseGrid(rawAuctions)
    browseRows = {}
    local newRows = {}

    for auctionID in pairs(rawAuctions) do
        local ok, detail = pcall(InspectAuctionDetail, auctionID)
        if ok and detail and detail.itemType and detail.buyout then

        local itemType = detail.itemType
        local stack = detail.itemStack or 1
        local unitPrice = mathFloor(detail.buyout / stack)

        -- Get item details
        local ok2, itemDetail = pcall(InspectItemDetail, detail.item or itemType)
        local name, icon, rarity, vendor = "Unknown", nil, 0, 0
        if ok2 and itemDetail then
            name   = itemDetail.name or "Unknown"
            icon   = itemDetail.icon
            rarity = itemDetail.rarity or 0
            vendor = itemDetail.sell or 0
        end

        -- Get my price from ownAuctions
        local myPrice = auction.ownAuctions[itemType]

        -- Get vendor ratio
        local vendorRatio = nil
        if vendor and vendor > 0 then
            vendorRatio = unitPrice / vendor
        end

        -- Check if buyout is below last known low
        local buyoutColor = nil
        local priceSummary = auction.getPriceSummary(itemType)
        if priceSummary and priceSummary.lastLo and unitPrice < priceSummary.lastLo then
            buyoutColor = { r = 0, g = 1, b = 0, a = 1 }  -- green
        end

        -- Format values for display
        local bidStr = fmtCoins(detail.bid)
        local buyoutStr = fmtCoins(detail.buyout)
        local unitStr = fmtCoins(unitPrice)
        local vendorStr = "-"
        if vendorRatio then
            vendorStr = stringFormat("%.1fx", vendorRatio)
            if vendorRatio > 5 then
                vendorStr = "<font color=\"#FF0000\">" .. vendorStr .. "</font>"
            end
        end
        local myPriceStr = fmtCoins(myPrice)

        -- Format expiry
        local expiryTime = detail.timeRemaining or 0
        local expiryStr = auction.formatExpiry(expiryTime)

        -- Build row with sort keys
        local row = {
            icon,                                              -- 1: texture
            "<font color=\"#" .. colorRarityToHex(rarity) .. "\">" .. name .. "</font>",  -- 2: item name
            detail.seller or "Unknown",                        -- 3: seller
            tostring(stack),                                   -- 4: stack
            bidStr,                                            -- 5: bid
            buyoutStr,                                         -- 6: buyout
            unitStr,                                           -- 7: unit price
            vendorStr,                                         -- 8: vendor ratio
            myPriceStr,                                        -- 9: my price
            { value = expiryStr, key = auctionID }             -- 10: expiry + row key
        }

        if buyoutColor then
            row[6] = "<font color=\"#00FF00\">" .. buyoutStr .. "</font>"
        end

        -- Store row data with sort keys
            tableInsert(newRows, {
                row = row,
                sortKeys = {
                    [5] = detail.bid or 0,
                    [6] = detail.buyout or 0,
                    [7] = unitPrice,
                    [8] = vendorRatio or 0,
                    [9] = myPrice or 0
                },
                rarity = rarity,
                name = name
            })
        end
    end

    browseRows = newRows
    applyFilterAndSort()
end

local function colorRarityToHex(rarity)
    local color = RARITY_COLOR[rarity] or RARITY_COLOR[0]
    local r = mathFloor(color.r * 255)
    local g = mathFloor(color.g * 255)
    local b = mathFloor(color.b * 255)
    return stringFormat("%02X%02X%02X", r, g, b)
end

local function doSearch()
    if not auction.isAtAH() then
        Command.Console.Display("general", true, langTexts.auction.notAtAH, true)
        return
    end
    auction.setBrowseSearchPending(true)
    Command.Auction.Scan({ type = "search" })
end

---------- auction.refreshOwnAuctions ----------

function auction.refreshOwnAuctions()
    auction.ownAuctions = {}
    local ok, list = pcall(Inspect.Auction.List)
    if not ok or not list then return end

    for auctionID in pairs(list) do
        local ok2, detail = pcall(InspectAuctionDetail, auctionID)
        if ok2 and detail and detail.itemType and detail.buyout then
            local unitPrice = mathFloor(detail.buyout / (detail.itemStack or 1))
            local existing  = auction.ownAuctions[detail.itemType]
            if existing == nil or unitPrice < existing then
                auction.ownAuctions[detail.itemType] = unitPrice
            end
        end
    end
end

---------- auction.buildBrowseTab ----------

function auction.buildBrowseTab(browseFrame)
    if grid then return end  -- Already built

    local context = UI.CreateContext("nkUI.auction.browse")
    context:SetStrata('dialog')
    context:SetLayer(3)

    -- Search bar row
    local searchContainer = LibEKL.UICreateFrame("nkFrame", "nkUI.auction.browse.searchContainer", browseFrame)
    searchContainer:SetPoint("TOPLEFT",     browseFrame, "TOPLEFT",     0, 0)
    searchContainer:SetPoint("TOPRIGHT",    browseFrame, "TOPRIGHT",    0, 0)
    searchContainer:SetHeight(28)

    searchInput = LibEKL.UICreateFrame("nkTextField", "nkUI.auction.browse.search", searchContainer)
    searchInput:SetPoint("TOPLEFT", searchContainer, "TOPLEFT", 5, 2)
    searchInput:SetWidth(280)
    searchInput:SetHeight(24)
    searchInput:SetInnerColor({r = 0, g = 0, b = 0, a = 0.3})
    searchInput:SetFocusColor(data.theme.labelColor or {r = 1, g = 1, b = 1, a = 1})
    searchInput:SetBorderColor({r = 0.5, g = 0.5, b = 0.5, a = 1})

    local searchBtn = auction.makeBtn("nkUI.auction.browse.searchBtn", searchContainer, langTexts.auction.btnSearch, 80, 24)
    searchBtn:SetPoint("TOPLEFT", searchInput, "TOPRIGHT", 5, 0)

    searchBtn:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        doSearch()
    end, "nkUI.auction.browse.searchBtn.Click")

    Command.Event.Attach(LibEKL.Events["nkUI.auction.browse.search"].KeyDown, function(_, key)
        if key == "Return" then
            doSearch()
        end
    end, "nkUI.auction.browse.search.KeyDown")

    -- Rarity filter row
    local rarityContainer = LibEKL.UICreateFrame("nkFrame", "nkUI.auction.browse.rarityContainer", browseFrame)
    rarityContainer:SetPoint("TOPLEFT",     browseFrame, "TOPLEFT",     0, 28)
    rarityContainer:SetPoint("TOPRIGHT",    browseFrame, "TOPRIGHT",    0, 28)
    rarityContainer:SetHeight(30)

    local xOff = 5
    for rarity = 0, 6 do
        local rarityLabel = RARITY_LABEL[rarity] or "?"
        local btn = auction.makeBtn("nkUI.auction.browse.rarityBtn" .. rarity, rarityContainer, rarityLabel, 40, 22)
        btn:SetPoint("TOPLEFT", rarityContainer, "TOPLEFT", xOff, 4)

        local color = RARITY_COLOR[rarity] or RARITY_COLOR[0]
        btn:SetLabelColor(color)
        btn:SetFillColor({ type = "solid", r = 0.1, g = 0.1, b = 0.1, a = 0.7 })

        btn:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
            toggleRarity(rarity)
        end, "nkUI.auction.browse.rarityBtn" .. rarity .. ".Click")

        rarityBtns[rarity] = btn
        xOff = xOff + 45
    end

    -- Create grid
    grid = LibEKL.UICreateFrame("nkGrid", GRID_NAME, browseFrame)
    grid:SetPoint("TOPLEFT",     browseFrame, "TOPLEFT",     0, 60)
    grid:SetPoint("BOTTOMRIGHT", browseFrame, "BOTTOMRIGHT", 0, 0)

    grid:SetFont(addonInfo.id, "MontserratMedium")
    grid:SetBodyColor(0.05, 0.06, 0.09, 0.9)
    grid:SetBorderColor(0.3, 0.3, 0.3, 1)
    grid:SetHeaderLabelColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)
    grid:SetSortable(true)

    local cols = {
        { width = 28,  header = "" },                                    -- 1: icon
        { width = 200, header = langTexts.auction.colItem },              -- 2: item name
        { width = 100, header = langTexts.auction.colSeller },            -- 3: seller
        { width = 40,  header = langTexts.auction.colStack },             -- 4: stack
        { width = 80,  header = langTexts.auction.colBid },               -- 5: bid
        { width = 80,  header = langTexts.auction.colBuyout },            -- 6: buyout
        { width = 80,  header = langTexts.auction.colUnit },              -- 7: unit price
        { width = 65,  header = langTexts.auction.colVendorRatio },       -- 8: vs vendor
        { width = 80,  header = langTexts.auction.colMyPrice },           -- 9: my price
        { width = 60,  header = langTexts.auction.colExpires }            -- 10: expires
    }

    -- Wrap grid:Sort to persist sort preference
    local oSort = grid.Sort
    function grid:Sort(col, sortOrder)
        oSort(self, col, sortOrder)
        if col then
            nkUISetup.modules.auction.browse.sortCol = col
            nkUISetup.modules.auction.browse.sortAsc = (sortOrder ~= false)
        end
    end

    -- After layout finishes, restore saved sort
    Command.Event.Attach(LibEKL.Events[GRID_NAME].GridFinished, function()
        local cfg = nkUISetup.modules.auction.browse
        if cfg.sortCol then
            oSort(grid, cfg.sortCol, cfg.sortAsc ~= false)
        end
    end, "nkUI.auction.browse.GridFinished")

    grid:Layout(cols, 30)

    -- Attach scan result event for browse tab
    Command.Event.Attach(Event.Auction.Scan, function(_, info, auctions)
        if info.type ~= "search" then return end
        if not auction.isBrowseSearchPending() then return end
        auction.setBrowseSearchPending(false)

        auction.refreshOwnAuctions()
        populateBrowseGrid(auctions)
    end, "nkUI.Auction.Browse.Scan")

    -- Attach search input change event for live filtering
    Command.Event.Attach(LibEKL.Events["nkUI.auction.browse.search"].TextfieldChanged, function()
        applyFilterAndSort()
    end, "nkUI.auction.browse.search.Changed")
end
