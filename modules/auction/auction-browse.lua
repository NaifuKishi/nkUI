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

-- Map text rarities to numeric indices for filtering
local function getRarityIndex(rarity)
    -- Handle both numeric and text rarities
    if type(rarity) == "number" then
        return rarity
    end
    
    -- Map text rarities to numeric indices
    local rarityMap = {
        sellable = 0,
        uncommon = 1,
        rare = 2,
        epic = 3,
        relic = 4,
        transcendent = 5,
        quest = 6
    }
    
    return rarityMap[rarity] or 0  -- Default to common (0) if unknown
end

local function isRarityVisible(rarity)
    local numericRarity = getRarityIndex(rarity)
    local browse = nkUISetup and nkUISetup.modules and nkUISetup.modules.auction and nkUISetup.modules.auction.browse
    if not browse then return true end
    local rf = browse.rarityFilter
    -- rarityFilter stores EXCLUDED rarities; empty = show all
    if not rf then return true end
    return rf[numericRarity] ~= true
end

local function updateRarityBtnVisuals()
    for rarity = 0, 6 do
        local btn = rarityBtns[rarity]
        if btn then
            local visible = isRarityVisible(rarity)
            if visible then
                -- bright: rarity is shown
                local color = RARITY_COLOR[rarity] or RARITY_COLOR[0]
                btn:SetFillColor({ type = "solid", r = color.r * 0.25, g = color.g * 0.25, b = color.b * 0.25, a = 0.9 })
            else
                -- dark: rarity is filtered out
                btn:SetFillColor({ type = "solid", r = 0.08, g = 0.08, b = 0.08, a = 0.9 })
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
            -- Check name filter (use clean name without HTML tags)
            local itemName = row.name or ""
            if searchText == "" or itemName:lower():find(searchText, 1, true) then
                tableInsert(filtered, row)
            end
        end
    end

    -- Sort by column
    local cfg = nkUISetup and nkUISetup.modules and nkUISetup.modules.auction and nkUISetup.modules.auction.browse
    local sortCol = (cfg and cfg.sortCol) or 7
    local sortAsc = not cfg or cfg.sortAsc ~= false

    -- Determine sort key based on column
    -- Numeric columns: TIME(5), LEVEL(6), UNIT PRICE(7), BUYOUT(8)
    local numCols = { [5] = true, [6] = true, [7] = true, [8] = true }

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
        -- For item names (column 2), use clean name without HTML tags
        tableSort(filtered, function(a, b)
            local aVal = a.row and a.row[sortCol] or ""
            local bVal = b.row and b.row[sortCol] or ""
            
            -- Special handling for item name column (column 2)
            if sortCol == 2 then
                aVal = a.name or ""  -- Use clean name for sorting
                bVal = b.name or ""
            else
                aVal = tostring(aVal)
                bVal = tostring(bVal)
            end
            
            aVal = aVal:lower()
            bVal = bVal:lower()
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

local function toggleRarity(rarity)
    local browse = nkUISetup and nkUISetup.modules and nkUISetup.modules.auction and nkUISetup.modules.auction.browse
    if not browse then return end
    if not browse.rarityFilter then browse.rarityFilter = {} end
    local rf = browse.rarityFilter
    -- rarityFilter stores EXCLUDED rarities; toggle exclude/include
    if rf[rarity] then
        rf[rarity] = nil   -- was excluded, now include
    else
        rf[rarity] = true  -- now excluded
    end
    applyFilterAndSort()
    updateRarityBtnVisuals()
end

local function processOneBrowseAuction(auctionID, newRows)
    local ok, detail = pcall(InspectAuctionDetail, auctionID)
    if not (ok and detail and detail.itemType and detail.buyout) then return end

    local itemType  = detail.itemType
    local stack     = detail.itemStack or 1
    local unitPrice = mathFloor(detail.buyout / stack)

    local ok2, itemDetail = pcall(InspectItemDetail, detail.item or itemType)
    local name, icon, rarity, vendor = "Unknown", nil, 0, 0
    if ok2 and itemDetail then
        name   = itemDetail.name or "Unknown"
        icon   = itemDetail.icon
        rarity = itemDetail.rarity or 0
        vendor = itemDetail.sell or 0
    end

    if icon == nil then icon = "iconBag.png" end

    local myPrice     = auction.ownAuctions[itemType]
    local vendorRatio = (vendor and vendor > 0) and (unitPrice / vendor) or nil

    local buyoutColor = nil
    local priceSummary = auction.getPriceSummary(itemType)
    if priceSummary and priceSummary.lastLo and unitPrice < priceSummary.lastLo then
        buyoutColor = { r = 0, g = 1, b = 0, a = 1 }
    end

    local unitStr    = fmtCoins(unitPrice)
    local buyoutStr  = fmtCoins(detail.buyout)
    local expiryStr  = auction.formatExpiry(detail.remaining or 0)
    local reqLevel   = (ok2 and itemDetail and itemDetail.requiredLevel and itemDetail.requiredLevel > 0)
                       and tostring(itemDetail.requiredLevel) or "-"

    local rarityColor = LibEKL.Inventory.GetItemColor(rarity)
    local coloredName = name
    if rarityColor then
        coloredName = stringFormat('<font color="#%02x%02x%02x">%s</font>',
            mathFloor(rarityColor.r * 255),
            mathFloor(rarityColor.g * 255),
            mathFloor(rarityColor.b * 255),
            name)
    end

    -- Row matches MAIN_COLS: icon | NAME | SELLER | STACKS | TIME | LEVEL | UNIT PRICE | BUYOUT
    local row = {
        icon,
        coloredName,
        detail.seller or "Unknown",
        tostring(stack),
        expiryStr,
        reqLevel,
        unitStr,
        buyoutColor and { value = buyoutStr, color = buyoutColor, key = auctionID }
                   or  { value = buyoutStr, key = auctionID },
    }

    tableInsert(newRows, {
        row      = row,
        sortKeys = {
            [5] = detail.remaining or 0,
            [6] = (ok2 and itemDetail and itemDetail.requiredLevel) or 0,
            [7] = unitPrice,
            [8] = detail.buyout or 0,
        },
        rarity = getRarityIndex(rarity),
        name   = name,
    })
end

local BROWSE_BATCH = 50

local function populateBrowseGrid(rawAuctions)
    browseRows = {}

    -- Flatten into batches of BROWSE_BATCH
    local batches = {}
    local batch   = {}
    local total   = 0
    for auctionID in pairs(rawAuctions) do
        tableInsert(batch, auctionID)
        total = total + 1
        if #batch >= BROWSE_BATCH then
            tableInsert(batches, batch)
            batch = {}
        end
    end
    if #batch > 0 then tableInsert(batches, batch) end

    if total == 0 then applyFilterAndSort() return end

    local newRows   = {}
    local processed = 0

    local co = coroutine.create(function()
        for b = 1, #batches do
            for _, auctionID in ipairs(batches[b]) do
                processOneBrowseAuction(auctionID, newRows)
            end
            processed = processed + #batches[b]
            coroutine.yield(processed)
        end
    end)

    LibEKL.Coroutines.Add({
        func     = co,
        counter  = total,
        active   = true,
        callBack = function()
            browseRows = newRows
            applyFilterAndSort()
        end,
    })
end

-- Expose for full-scan hook in auction.lua
auction.populateBrowseGrid = populateBrowseGrid

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
        { width = 28,  header = "", texture = true, textureType = "Rift", texturePath = "" },  -- 1: icon
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
        local browse = nkUISetup and nkUISetup.modules and nkUISetup.modules.auction and nkUISetup.modules.auction.browse
        if col and browse then
            browse.sortCol = col
            browse.sortAsc = (sortOrder ~= false)
        end
    end

    -- After layout finishes, restore saved sort
    Command.Event.Attach(LibEKL.Events[GRID_NAME].GridFinished, function()
        local cfg = nkUISetup and nkUISetup.modules and nkUISetup.modules.auction and nkUISetup.modules.auction.browse
        if cfg and cfg.sortCol then
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

    -- Set initial button visuals
    updateRarityBtnVisuals()
end
