local addonInfo, privateVars = ...

---------- init namespace ---------

local minionManager = privateVars.minionManager
local langTexts     = privateVars.langTexts

local inspectMinionList      = Inspect.Minion.Minion.List
local inspectMinionDetail    = Inspect.Minion.Minion.Detail
local inspectAdventureList   = Inspect.Minion.Adventure.List
local inspectAdventureDetail = Inspect.Minion.Adventure.Detail
local inspectCurrencyList    = Inspect.Currency.List

local stringFormat = string.format
local tableInsert  = table.insert
local pairs        = pairs
local pcall        = pcall

---------- populate ---------

function minionManager.populate()
    local mm = minionManager
    if mm.minionContent == nil then return end

    mm.clearRows(mm.minionRows, mm.minionBin)
    mm.clearRows(mm.activeRows, mm.activeBin)

    -- Fetch minions
    local ok1, minionIds = pcall(inspectMinionList)
    if not ok1 or minionIds == nil then minionIds = {} end

    local ok2, minionDetails = pcall(inspectMinionDetail, minionIds)
    if not ok2 or minionDetails == nil then minionDetails = {} end

    -- Fetch adventures
    local ok3, advIds = pcall(inspectAdventureList)
    if not ok3 or advIds == nil then advIds = {} end

    local ok4, advDetails = pcall(inspectAdventureDetail, advIds)
    if not ok4 or advDetails == nil then advDetails = {} end

    -- Split adventures by mode
    local busyMinionIds = {}
    mm.allAdvData = {}

    for id, adv in pairs(advDetails) do
        local mode = adv.mode or "available"
        if mode == "available" then
            mm.allAdvData[id] = adv
        elseif mode == "working" or mode == "finished" then
            if adv.minion then busyMinionIds[adv.minion] = true end
            local mDet = adv.minion and minionDetails[adv.minion] or nil
            local arow = mm.createActiveRow(mm.activeContent)
            arow:Update(id, adv, mDet)
            tableInsert(mm.activeRows, arow)
        end
    end

    mm.restackRows(mm.activeRows, mm.activeContent, mm.ACTIVE_ROW_H)
    if mm.activeScroll then mm.activeScroll:SetContent(mm.activeContent) end

    -- Idle minions
    for id, details in pairs(minionDetails) do
        if not busyMinionIds[id] then
            local mrow = mm.createMinionRow(mm.minionContent)
            mrow:Update(id, details)
            tableInsert(mm.minionRows, mrow)
        end
    end

    mm.restackMinionRows(mm.minionRows, mm.minionContent, mm.MINION_ROW_H, mm.MINION_COL_W, mm.PAD)
    if mm.minionScroll then mm.minionScroll:SetContent(mm.minionContent) end

    -- Validate selections
    if mm.selectedMinionId ~= nil then
        local found = false
        for i = 1, #mm.minionRows do
            if mm.minionRows[i]:GetMinionId() == mm.selectedMinionId then found = true; break end
        end
        if not found then mm.selectedMinionId = nil end
    end
    if mm.selectedAdvId ~= nil and mm.allAdvData[mm.selectedAdvId] == nil then
        mm.selectedAdvId = nil
    end

    -- Adventure cards
    mm.refreshCards()
    mm.updateSelectionState()

    -- Currency bar
    if mm.currencyLabel then
        local ok5, currList = pcall(inspectCurrencyList)
        if ok5 and currList then
            local credits = currList["credit"] or 0
            mm.currencyLabel:SetText(stringFormat(langTexts.minionManager.currencyHint, credits))
        end
    end
end

function minionManager.refreshActiveMissions()
    local mm = minionManager
    for i = 1, #mm.activeRows do
        mm.activeRows[i]:RefreshTime()
    end
end
