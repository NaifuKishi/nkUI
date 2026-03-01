local addonInfo, privateVars = ...

---------- init namespace ---------

local minionManager = privateVars.minionManager
local langTexts     = privateVars.langTexts
local internalFunc  = privateVars.internalFunc

local inspectTimeFrame  = Inspect.Time.Frame
local commandMinionClaim = Command.Minion.Claim
local commandMinionHurry = Command.Minion.Hurry

local osTime       = os.time
local mathFloor    = math.floor
local mathMax      = math.max
local stringFormat = string.format
local tableRemove  = table.remove
local pcall        = pcall
local tostring     = tostring

---------- stat display helpers ---------

local STAT_ICON_SIZE = minionManager.STAT_ICON_SIZE
local STAT_SLOT_W    = 34   -- icon(14) + gap(2) + number text(~12) + spacing

---------- minion row ---------

local _mrowCount = 0
local _arowCount = 0

function minionManager.createMinionRow(parent)
    local mm = minionManager

    if #mm.minionBin > 0 then
        local recycled = mm.minionBin[#mm.minionBin]
        tableRemove(mm.minionBin, #mm.minionBin)
        recycled:SetVisible(true)
        return recycled
    end

    _mrowCount = _mrowCount + 1
    local base = "nkUI.mm.mrow." .. _mrowCount

    local row = LibEKL.UICreateFrame("nkFrame", base, parent)
    row:SetHeight(mm.MINION_ROW_H)

    local rowBg = LibEKL.UICreateFrame("nkCanvas", base .. ".bg", row)
    rowBg:SetPoint("TOPLEFT",     row, "TOPLEFT",     0, 0)
    rowBg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    rowBg:SetLayer(1)
    mm.setCanvasRect(rowBg, 0, 0, 0, 0.2, nil, nil)

    local hlBar = LibEKL.UICreateFrame("nkCanvas", base .. ".hl", row)
    hlBar:SetPoint("TOPLEFT",    row, "TOPLEFT",    0, 2)
    hlBar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, -2)
    hlBar:SetWidth(3)
    hlBar:SetLayer(3)
    mm.setCanvasRect(hlBar, mm.COL_GOLD.r, mm.COL_GOLD.g, mm.COL_GOLD.b, 1, nil, nil)
    hlBar:SetVisible(false)

    local lvlBadge = LibEKL.UICreateFrame("nkCanvas", base .. ".lvlBg", row)
    lvlBadge:SetLayer(2)
    lvlBadge:SetPoint("CENTERLEFT", row, "CENTERLEFT", mm.PAD, 0)
    lvlBadge:SetWidth(28)
    lvlBadge:SetHeight(28)
    mm.setCanvasRect(lvlBadge, 0.1, 0.12, 0.18, 1, mm.COL_BLUE, 1)

    local lvlText = LibEKL.UICreateFrame("nkText", base .. ".lvl", lvlBadge)
    lvlText:SetPoint("CENTER", lvlBadge, "CENTER", 0, 0)
    lvlText:SetFontSize(11)
    lvlText:SetFontColor(mm.COL_WHITE.r, mm.COL_WHITE.g, mm.COL_WHITE.b, 1)
    LibEKL.UI.SetFont(lvlText, addonInfo.id, "MontserratBold")

    -- Name
    local nameText = LibEKL.UICreateFrame("nkText", base .. ".name", row)
    nameText:SetLayer(2)
    nameText:SetPoint("TOPLEFT", lvlBadge, "TOPRIGHT", 10, -4)
    nameText:SetWidth(mm.MINION_COL_W - 28 - mm.PAD * 2)
    nameText:SetFontSize(12)
    nameText:SetFontColor(mm.COL_WHITE.r, mm.COL_WHITE.g, mm.COL_WHITE.b, 1)
    LibEKL.UI.SetFont(nameText, addonInfo.id, "MontserratSemiBold")

    -- Stamina — unterhalb der Level-Box
    local staminaText = LibEKL.UICreateFrame("nkText", base .. ".stamina", row)
    staminaText:SetLayer(2)
    staminaText:SetPoint("TOPLEFT", lvlBadge, "BOTTOMLEFT", 0, 4)
    staminaText:SetFontSize(9)
    staminaText:SetFontColor(mm.COL_DIM.r, mm.COL_DIM.g, mm.COL_DIM.b, 1)
    LibEKL.UI.SetFont(staminaText, addonInfo.id, "FiraMonoMedium")

    -- Stat icons — one icon+value pair per stat, shown only when value > 0
    local statSlots = {}
    local statsY    = 36
    local xStart    = mm.PAD + 28 + 10  -- same x as nameText (PAD + lvlBadge width + offset)
    local SI = mm.STAT_ICONS
    for i = 1, #SI do
        local slotX = xStart + (i - 1) * STAT_SLOT_W

        local icon = LibEKL.UICreateFrame("nkTexture", base .. ".si" .. i, row)
        icon:SetLayer(2)
        icon:SetPoint("TOPLEFT", row, "TOPLEFT", slotX, statsY)
        icon:SetWidth(STAT_ICON_SIZE)
        icon:SetHeight(STAT_ICON_SIZE)
        icon:SetTextureAsync("Rift", SI[i].icon)
        icon:SetVisible(false)

        local val = LibEKL.UICreateFrame("nkText", base .. ".sv" .. i, row)
        val:SetLayer(2)
        val:SetPoint("TOPLEFT", row, "TOPLEFT", slotX + STAT_ICON_SIZE + 2, statsY)
        val:SetFontSize(9)
        val:SetFontColor(mm.COL_WHITE.r, mm.COL_WHITE.g, mm.COL_WHITE.b, 0.9)
        LibEKL.UI.SetFont(val, addonInfo.id, "FiraMonoMedium")
        val:SetVisible(false)

        statSlots[i] = { icon = icon, val = val, key = SI[i].field }
    end

    local _minionId   = nil
    local _minionName = nil

    function row:Update(id, details)
        _minionId   = id
        _minionName = details.name or "?"
        nameText:SetText(_minionName)
        lvlText:SetText(tostring(details.level or 0))
        local sta    = details.stamina    or 0
        local staMax = details.staminaMax or 0
        staminaText:SetText(stringFormat("%d/%d", sta, staMax))
        local rarity = details.rarity or "common"
        local rc = mm.RARITY_COLORS[rarity] or mm.COL_DIM
        mm.setCanvasRect(lvlBadge, 0.1, 0.12, 0.18, 1, rc, 1)

        -- Position and show only non-zero stats, pack them left
        local xPos = xStart
        for i = 1, #statSlots do
            local slot   = statSlots[i]
            local v      = details[slot.key] or 0
            if v > 0 then
                slot.icon:SetPoint("TOPLEFT", row, "TOPLEFT", xPos, statsY)
                slot.icon:SetVisible(true)
                slot.val:SetText(tostring(v))
                slot.val:SetPoint("TOPLEFT", row, "TOPLEFT", xPos + STAT_ICON_SIZE + 2, statsY)
                slot.val:SetVisible(true)
                xPos = xPos + STAT_SLOT_W
            else
                slot.icon:SetVisible(false)
                slot.val:SetVisible(false)
            end
        end
    end

    function row:SetHighlight(active)
        hlBar:SetVisible(active)
        mm.setCanvasRect(rowBg, 0, 0, 0, active and 0.4 or 0.2, nil, nil)
    end

    function row:GetMinionId()   return _minionId   end
    function row:GetMinionName() return _minionName end

    row:EventAttach(Event.UI.Input.Mouse.Left.Down, function()
        if _minionId then
            mm.selectedMinionId = _minionId
            mm.updateSelectionState()
        end
    end, base .. ".LeftDown")

    return row
end

---------- active mission row ---------

function minionManager.createActiveRow(parent)
    local mm = minionManager

    if #mm.activeBin > 0 then
        local recycled = mm.activeBin[#mm.activeBin]
        tableRemove(mm.activeBin, #mm.activeBin)
        recycled:SetVisible(true)
        return recycled
    end

    _arowCount = _arowCount + 1
    local base = "nkUI.mm.arow." .. _arowCount

    local row = LibEKL.UICreateFrame("nkFrame", base, parent)
    row:SetWidth(mm.ACTIVE_ROW_W)
    row:SetHeight(mm.ACTIVE_ROW_H)

    local rowBg = LibEKL.UICreateFrame("nkCanvas", base .. ".bg", row)
    rowBg:SetPoint("TOPLEFT",     row, "TOPLEFT",     0, 0)
    rowBg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    rowBg:SetLayer(1)
    mm.setCanvasRect(rowBg, 0.06, 0.08, 0.12, 0.95, { r=0.2, g=0.2, b=0.25, a=0.8 }, 1)

    local statusStrip = LibEKL.UICreateFrame("nkCanvas", base .. ".strip", row)
    statusStrip:SetPoint("TOPLEFT",    row, "TOPLEFT",    0, 0)
    statusStrip:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    statusStrip:SetWidth(3)
    statusStrip:SetLayer(2)
    mm.setCanvasRect(statusStrip, mm.COL_BLUE.r, mm.COL_BLUE.g, mm.COL_BLUE.b, 1, nil, nil)

    -- Layout (ACTIVE_ROW_H = 58):
    --   y=6  : adventure name
    --   y=26 : minion name (dim italic)
    --   y=42 : timeText | totalText | progress bar
    -- Right side: action button fixed 60px wide, 4px from right edge
    local BTN_W = 60
    local xL    = mm.PAD + 4   -- left text margin (after status strip)
    local xR    = mm.PAD + 4   -- right margin for button

    local nameText = LibEKL.UICreateFrame("nkText", base .. ".name", row)
    nameText:SetLayer(3)
    nameText:SetPoint("TOPLEFT", row, "TOPLEFT", xL, 6)
    nameText:SetFontSize(12)
    nameText:SetFontColor(mm.COL_WHITE.r, mm.COL_WHITE.g, mm.COL_WHITE.b, 1)
    LibEKL.UI.SetFont(nameText, addonInfo.id, "MontserratSemiBold")

    local minionNameText = LibEKL.UICreateFrame("nkText", base .. ".minionName", row)
    minionNameText:SetLayer(3)
    minionNameText:SetPoint("TOPLEFT", row, "TOPLEFT", xL, 26)
    minionNameText:SetFontSize(10)
    minionNameText:SetFontColor(mm.COL_DIM.r, mm.COL_DIM.g, mm.COL_DIM.b, 1)
    LibEKL.UI.SetFont(minionNameText, addonInfo.id, "MontserratMediumItalic")

    local actionBtn = LibEKL.UICreateFrame("nkButton", base .. ".action", row)
    actionBtn:SetLayer(3)
    actionBtn:SetWidth(BTN_W)
    actionBtn:SetHeight(22)
    actionBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", -xR, 6)
    actionBtn:SetText(langTexts.minionManager.hurry)
    actionBtn:SetFont(addonInfo.id, "MontserratSemiBold")
    actionBtn:SetLabelColor(mm.COL_GOLD)
    actionBtn:SetEffectGlow({ strength = 3 })
    actionBtn:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = 0.4 })
    actionBtn:SetBorderColor({ r = 0.4, g = 0.4, b = 0.5, a = 0.8, thickness = 1 })
    actionBtn:SetScale(0.7)

    local timeText = LibEKL.UICreateFrame("nkText", base .. ".time", row)
    timeText:SetLayer(3)
    timeText:SetPoint("TOPLEFT", row, "TOPLEFT", xL, 42)
    timeText:SetFontSize(10)
    timeText:SetFontColor(mm.COL_WHITE.r, mm.COL_WHITE.g, mm.COL_WHITE.b, 1)
    LibEKL.UI.SetFont(timeText, addonInfo.id, "FiraMonoMedium")

    local totalText = LibEKL.UICreateFrame("nkText", base .. ".total", row)
    totalText:SetLayer(3)
    totalText:SetPoint("TOPLEFT", row, "TOPLEFT", xL + 55, 42)
    totalText:SetFontSize(10)
    totalText:SetFontColor(mm.COL_DIM.r, mm.COL_DIM.g, mm.COL_DIM.b, 0.7)
    LibEKL.UI.SetFont(totalText, addonInfo.id, "FiraMonoMedium")

    local barBg = LibEKL.UICreateFrame("nkCanvas", base .. ".barBg", row)
    barBg:SetPoint("TOPLEFT",  row, "TOPLEFT",  xL + 110, 46)
    barBg:SetPoint("TOPRIGHT", row, "TOPRIGHT", -(xR + BTN_W + mm.PAD), 46)
    barBg:SetHeight(5)
    barBg:SetLayer(2)

    local barFill = LibEKL.UICreateFrame("nkCanvas", base .. ".barFill", row)
    barFill:SetPoint("TOPLEFT",  row, "TOPLEFT",  xL + 110, 46)
    barFill:SetPoint("TOPRIGHT", row, "TOPRIGHT", -(xR + BTN_W + mm.PAD), 46)
    barFill:SetHeight(5)
    barFill:SetLayer(3)

    local _advId           = nil
    local _duration        = 1
    local _completion      = 0
    local _isDone          = false
    local _hurryCost       = 0
    local _hurryAventurine = 0
    local _hurryCredit     = 0

    local function _calcRemaining()
        return mathMax(0, _completion - osTime())
    end

    local function _refresh(remaining, mode)
        _isDone = mode == "finished" or remaining <= 0
        timeText:SetText(mm.formatTime(_isDone and 0 or remaining))
        if _isDone then
            actionBtn:SetText(langTexts.minionManager.claim)
            actionBtn:SetLabelColor(mm.COL_GREEN)
            actionBtn:SetFillColor({ type = "solid", r = 0, g = 0.1, b = 0, a = 0.5 })
            actionBtn:SetBorderColor({ r = mm.COL_GREEN.r, g = mm.COL_GREEN.g, b = mm.COL_GREEN.b, a = 0.8, thickness = 1 })
            mm.setCanvasRect(statusStrip, mm.COL_GREEN.r, mm.COL_GREEN.g, mm.COL_GREEN.b, 1, nil, nil)
            mm.drawProgressBar(barBg, barFill, 1.0)
        else
            actionBtn:SetText(langTexts.minionManager.hurry)
            actionBtn:SetLabelColor(mm.COL_GOLD)
            actionBtn:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = 0.4 })
            actionBtn:SetBorderColor({ r = 0.4, g = 0.4, b = 0.5, a = 0.8, thickness = 1 })
            mm.setCanvasRect(statusStrip, mm.COL_BLUE.r, mm.COL_BLUE.g, mm.COL_BLUE.b, 1, nil, nil)
            mm.drawProgressBar(barBg, barFill, 1.0 - remaining / _duration)
        end
    end

    function row:Update(id, advDetails, minionDetails)
        _advId      = id
        _duration   = mathMax(1, advDetails and advDetails.duration or 1)
        _completion = advDetails and advDetails.completion or 0
        _hurryAventurine = advDetails and (advDetails.hurryAventurine or 0) or 0
        _hurryCredit     = advDetails and (advDetails.hurryCredit     or 0) or 0
        _hurryCost       = _hurryAventurine > 0 or _hurryCredit > 0

        nameText:SetText(advDetails and advDetails.name or "?")
        minionNameText:SetText(minionDetails and minionDetails.name or "")

        local dur = advDetails and advDetails.duration or 0
        local h = mathFloor(dur / 3600)
        local m = mathFloor((dur % 3600) / 60)
        totalText:SetText(h > 0 and stringFormat("%dh", h) or stringFormat("%dm", m))

        local mode      = advDetails and advDetails.mode or "working"
        local remaining = mode == "finished" and 0 or _calcRemaining()
        _refresh(remaining, mode)
    end

    function row:RefreshTime()
        local remaining = _calcRemaining()
        _refresh(remaining, remaining <= 0 and "finished" or "working")
    end

    function row:GetAdventureId() return _advId end

    actionBtn:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        if _isDone then
            local ok, err = pcall(commandMinionClaim, _advId)
            if not ok then LibEKL.Tools.Error.Display("nkUI.minionManager", tostring(err), 2) end
        else
            local advId = _advId
            local lt    = langTexts.minionManager
            local msg   = lt.hurryDialogMsg
            local dlg = LibEKL.UI.choiceDialog(
                msg,
                stringFormat(lt.hurryAventurine, _hurryAventurine),
                function()
                    local ok, err = pcall(commandMinionHurry, advId, "aventurine")
                    if not ok then LibEKL.Tools.Error.Display("nkUI.minionManager", tostring(err), 2) end
                end,
                stringFormat(lt.hurryCredit, _hurryCredit),
                function()
                    local ok, err = pcall(commandMinionHurry, advId, "credit")
                    if not ok then LibEKL.Tools.Error.Display("nkUI.minionManager", tostring(err), 2) end
                end
            )
            internalFunc.setupConfirmDialog(dlg)
        end
    end, base .. ".action.LeftUp")

    return row
end
