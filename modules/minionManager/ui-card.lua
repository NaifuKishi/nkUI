local addonInfo, privateVars = ...

---------- init namespace ---------

local minionManager = privateVars.minionManager
local langTexts     = privateVars.langTexts

local inspectTimeFrame   = Inspect.Time.Frame
local commandMinionShuffle = Command.Minion.Shuffle

local mathFloor  = math.floor
local mathMax    = math.max
local stringFormat = string.format
local tableInsert  = table.insert
local pairs        = pairs
local pcall        = pcall
local tostring     = tostring

---------- card slot (adventure card) ---------

function minionManager.buildCardSlot(parent, index)
    local mm   = minionManager
    local base = "nkUI.mm.card." .. index

    local card = LibEKL.UICreateFrame("nkFrame", base, parent)
    card:SetHeight(mm.CARD_H)
    card:SetWidth(mm.CARD_W)

    local col = mm.COL_BLUE  -- updated dynamically in UpdateAdventure

    local bg = LibEKL.UICreateFrame("nkCanvas", base .. ".bg", card)
    bg:SetPoint("TOPLEFT",     card, "TOPLEFT",     0, 0)
    bg:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", 0, 0)
    bg:SetLayer(1)
    mm.setCanvasRect(bg, col.r*0.06, col.g*0.06, col.b*0.06, 0.9, col, 2)

    local selBg = LibEKL.UICreateFrame("nkCanvas", base .. ".selBg", card)
    selBg:SetPoint("TOPLEFT",     card, "TOPLEFT",     0, 0)
    selBg:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", 0, 0)
    selBg:SetLayer(3)
    mm.setCanvasRect(selBg, 1, 1, 0.5, 0.12, mm.COL_GOLD, 2)
    selBg:SetVisible(false)

    -- Per-card SHUFFLE button
    local shuffleBtn = LibEKL.UICreateFrame("nkButton", base .. ".shuffle", card)
    shuffleBtn:SetLayer(2)
    shuffleBtn:SetPoint("TOPCENTER", card, "TOPCENTER", 0, mm.PAD)
    shuffleBtn:SetText(langTexts.minionManager.shuffle)
    shuffleBtn:SetFont(addonInfo.id, "MontserratSemiBold")
    shuffleBtn:SetLabelColor(mm.COL_GOLD)
    shuffleBtn:SetEffectGlow({ strength = 2 })
    shuffleBtn:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = 0.5 })
    shuffleBtn:SetBorderColor({ r = col.r, g = col.g, b = col.b, a = 0.7, thickness = 1 })
    shuffleBtn:SetScale(0.7)

    -- Adventure name — multi-line centered, max 3 lines
    -- Fixed y positions from card TOPLEFT (CARD_H = 200):
    local Y_NAME1   = 34   -- name line 1
    local Y_NAME2   = 49   -- name line 2
    local Y_NAME3   = 64   -- name line 3
    local Y_DUR     = 84   -- duration text
    local Y_STATS   = 116  -- stat icons row
    local Y_STAM    = 136  -- stamina icon + value

    -- Name lines — fixed position, centered
    local nameFrames = {}
    local nameYs = { Y_NAME1, Y_NAME2, Y_NAME3 }
    for i = 1, 3 do
        local lbl = LibEKL.UICreateFrame("nkText", base .. ".name" .. i, card)
        lbl:SetLayer(2)
        lbl:SetPoint("TOPCENTER", card, "TOPCENTER", 0, nameYs[i])
        lbl:SetFontSize(11)
        lbl:SetFontColor(mm.COL_WHITE.r, mm.COL_WHITE.g, mm.COL_WHITE.b, 1)
        LibEKL.UI.SetFont(lbl, addonInfo.id, "MontserratSemiBold")
        lbl:SetVisible(false)
        nameFrames[i] = lbl
    end

    local function setNameLines(text)
        local lines = mm.splitLines(text or "", 16, 3)
        for i = 1, 3 do
            if lines[i] then
                nameFrames[i]:SetText(lines[i])
                nameFrames[i]:SetVisible(true)
            else
                nameFrames[i]:SetVisible(false)
            end
        end
    end

    -- Duration
    local durText = LibEKL.UICreateFrame("nkText", base .. ".dur", card)
    durText:SetLayer(2)
    durText:SetPoint("TOPCENTER", card, "TOPCENTER", 0, Y_DUR)
    durText:SetFontSize(18)
    durText:SetFontColor(mm.COL_WHITE.r, mm.COL_WHITE.g, mm.COL_WHITE.b, 1)
    LibEKL.UI.SetFont(durText, addonInfo.id, "MontserratBold")

    -- Stat icons — centered horizontally at Y_STATS
    local CARD_STAT_SIZE = 16
    local CARD_STAT_GAP  = 4
    local SI = mm.STAT_ICONS
    local cardStatIcons = {}
    for i = 1, #SI do
        local icon = LibEKL.UICreateFrame("nkTexture", base .. ".csi" .. i, card)
        icon:SetLayer(2)
        icon:SetWidth(CARD_STAT_SIZE)
        icon:SetHeight(CARD_STAT_SIZE)
        icon:SetTextureAsync("Rift", SI[i].icon)
        icon:SetVisible(false)
        cardStatIcons[i] = { frame = icon, key = SI[i].field }
    end

    -- Stamina cost — at Y_STAM, centered
    local staminaIcon = LibEKL.UICreateFrame("nkTexture", base .. ".stamIcon", card)
    staminaIcon:SetLayer(2)
    staminaIcon:SetWidth(14)
    staminaIcon:SetHeight(14)
    staminaIcon:SetTextureAsync("Rift", "Minion_I15B.dds")

    local staminaText = LibEKL.UICreateFrame("nkText", base .. ".stam", card)
    staminaText:SetLayer(2)
    staminaText:SetFontSize(10)
    staminaText:SetFontColor(mm.COL_DIM.r, mm.COL_DIM.g, mm.COL_DIM.b, 1)
    LibEKL.UI.SetFont(staminaText, addonInfo.id, "FiraMonoMedium")

    -- Reward type — layout from bottom up:
    --   -(PAD)          : "REWARD" label
    --   -(PAD+13)       : reward line 1 (bottom line)
    --   -(PAD+13+13)    : reward line 2 (above)
    local REWARD_LABEL_H = 13
    local REWARD_LINE_H  = 13

    local rewardLabel = LibEKL.UICreateFrame("nkText", base .. ".rewardLabel", card)
    rewardLabel:SetLayer(2)
    rewardLabel:SetPoint("BOTTOMCENTER", card, "BOTTOMCENTER", 0, -mm.PAD)
    rewardLabel:SetFontSize(9)
    rewardLabel:SetFontColor(mm.COL_DIM.r, mm.COL_DIM.g, mm.COL_DIM.b, 1)
    LibEKL.UI.SetFont(rewardLabel, addonInfo.id, "MontserratMedium")
    rewardLabel:SetText("REWARD")

    local rewardFrames, setRewardLines = mm.buildMultilineText(
        base .. ".reward", card, 16, 2, 10, "MontserratMedium", 2)

    -- Cost (top-right)
    local costText = LibEKL.UICreateFrame("nkText", base .. ".cost", card)
    costText:SetLayer(2)
    costText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -mm.PAD, mm.PAD + 2)
    costText:SetFontSize(10)
    costText:SetFontColor(mm.COL_GOLD.r, mm.COL_GOLD.g, mm.COL_GOLD.b, 1)
    LibEKL.UI.SetFont(costText, addonInfo.id, "FiraMonoMedium")

    -- Empty placeholder
    local emptyText = LibEKL.UICreateFrame("nkText", base .. ".empty", card)
    emptyText:SetLayer(2)
    emptyText:SetPoint("CENTER", card, "CENTER", 0, 0)
    emptyText:SetFontSize(12)
    emptyText:SetFontColor(mm.COL_DIM.r, mm.COL_DIM.g, mm.COL_DIM.b, 0.6)
    emptyText:SetText(langTexts.minionManager.noAdventure)
    LibEKL.UI.SetFont(emptyText, addonInfo.id, "MontserratMediumItalic")
    emptyText:SetVisible(false)

    local _advId = nil

    local function _setEmpty(empty)
        shuffleBtn:SetVisible(not empty)
        for i = 1, #nameFrames do nameFrames[i]:SetVisible(not empty) end
        durText:SetVisible(not empty)
        rewardLabel:SetVisible(not empty)
        for i = 1, #rewardFrames do rewardFrames[i]:SetVisible(not empty) end
        costText:SetVisible(not empty)
        emptyText:SetVisible(empty)
        if empty then
            for i = 1, #cardStatIcons do cardStatIcons[i].frame:SetVisible(false) end
            staminaIcon:SetVisible(false)
            staminaText:SetVisible(false)
        end
    end

    function card:UpdateAdventure(id, details)
        _advId = id
        if id == nil or details == nil then
            _setEmpty(true)
            selBg:SetVisible(false)
            bg:SetVisible(false)
            return
        end
        bg:SetVisible(true)
        _setEmpty(false)

        -- Update colour based on adventure stat type
        col = mm.getAdvColor(details)
        mm.setCanvasRect(bg, col.r*0.06, col.g*0.06, col.b*0.06, 0.9, col, 2)
        shuffleBtn:SetBorderColor({ r = col.r, g = col.g, b = col.b, a = 0.7, thickness = 1 })

        setNameLines(details.name or "?")

        -- Stat icons: collect present stats, center them horizontally
        local present = {}
        for i = 1, #cardStatIcons do
            local v = details[cardStatIcons[i].key]
            if v and v ~= false then
                tableInsert(present, cardStatIcons[i].frame)
            else
                cardStatIcons[i].frame:SetVisible(false)
            end
        end
        local totalW = #present * CARD_STAT_SIZE + mathFloor(mathMax(0, #present - 1)) * CARD_STAT_GAP
        local xOff   = -mathFloor(totalW / 2)
        for i = 1, #present do
            present[i]:SetPoint("TOPLEFT", card, "TOPCENTER",
                xOff + (i - 1) * (CARD_STAT_SIZE + CARD_STAT_GAP), Y_STATS)
            present[i]:SetVisible(true)
        end

        -- Stamina cost — at Y_STAM, centered
        local stamCost = details.costStamina or 0
        if stamCost > 0 then
            staminaIcon:SetPoint("TOPCENTER", card, "TOPCENTER", -10, Y_STAM)
            staminaIcon:SetVisible(true)
            staminaText:SetPoint("TOPCENTER", card, "TOPCENTER", 6, Y_STAM + 1)
            staminaText:SetText(tostring(stamCost))
            staminaText:SetVisible(true)
        else
            staminaIcon:SetVisible(false)
            staminaText:SetVisible(false)
        end
        local dur = details.duration or 0
        local h = mathFloor(dur / 3600)
        local m = mathFloor((dur % 3600) / 60)
        durText:SetText(h > 0 and stringFormat("%dh", h) or stringFormat("%dm", m))
        local rewardKey = details.reward or ""
        local rc = mm.RARITY_COLORS[details.rewardQuality] or mm.COL_WHITE
        local rewardStr = mm.REWARD_LABELS[rewardKey] or rewardKey
        local rewardLines = mm.splitLines(rewardStr, 16, 2)
        local numLines = #rewardLines
        for i = 1, 2 do
            if rewardLines[i] then
                -- line 1 sits just above rewardLabel, line 2 above line 1
                local yOff = -(mm.PAD + REWARD_LABEL_H + (numLines - i) * REWARD_LINE_H)
                rewardFrames[i]:SetText(rewardLines[i])
                rewardFrames[i]:SetPoint("BOTTOMCENTER", card, "BOTTOMCENTER", 0, yOff)
                rewardFrames[i]:SetFontColor(rc.r, rc.g, rc.b, 1)
                rewardFrames[i]:SetVisible(true)
            else
                rewardFrames[i]:SetVisible(false)
            end
        end
        local cost = details.costAventurine or details.costCredit or 0
        costText:SetText(cost > 0 and tostring(cost) or "")
    end

    function card:SetSelected(selectedId)
        selBg:SetVisible(_advId ~= nil and _advId == selectedId)
    end

    function card:GetAdvId() return _advId end

    bg:EventAttach(Event.UI.Input.Mouse.Left.Down, function()
        if _advId then
            mm.selectedAdvId = _advId
            mm.updateSelectionState()
        end
    end, base .. ".bg.LeftDown")

    Command.Event.Attach(LibEKL.Events[base .. ".shuffle"].Clicked, function()
        if _advId == nil then return end
        local details  = mm.allAdvData[_advId]
        local currency = (details and (details.costAventurine or 0) > 0) and "aventurine" or "credit"
        local ok, err  = pcall(commandMinionShuffle, _advId, currency)
        if not ok then LibEKL.Tools.Error.Display("nkUI.minionManager", tostring(err), 2) end
    end, base .. ".shuffle.Clicked")

    return card
end

---------- card categorisation ---------
-- Slot order (left to right):
--   1 = XP/Quick    (duration < 300s, no cost)   — covers 1m (60s) and 3m (180s)
--   2 = Short       (duration <= 1200s, no cost)  — 5m, 10m, 15m, 20m
--   3 = Long        (duration > 1200s, no cost)   — 8h, 10h
--   4 = Premium     (costAventurine > 0 or costCredit > 0)
-- Within each slot we pick the adventure with the shortest duration.

local function _advCategory(adv)
    local cost = (adv.costAventurine or 0) + (adv.costCredit or 0)
    if cost > 0 then return 4 end
    local dur = adv.duration or 0
    if dur < 300   then return 1 end
    if dur <= 1200 then return 2 end
    return 3
end

function minionManager.categorizeAdventures()
    local mm    = minionManager
    local slots    = { nil, nil, nil, nil }  -- winning id per slot
    local slotDurs = { math.huge, math.huge, math.huge, math.huge }
    for id, adv in pairs(mm.allAdvData) do
        local cat = _advCategory(adv)
        local dur = adv.duration or 0
        if dur < slotDurs[cat] then
            slots[cat]    = id
            slotDurs[cat] = dur
        end
    end
    return slots
end

function minionManager.refreshCards()
    local mm    = minionManager
    local slots = mm.categorizeAdventures()
    for i = 1, mm.CARDS_VISIBLE do
        local slot = mm.cardSlots[i]
        if slot then
            local id      = slots[i]
            local details = id and mm.allAdvData[id] or nil
            slot:UpdateAdventure(id, details)
            slot:SetSelected(mm.selectedAdvId)
        end
    end
end
