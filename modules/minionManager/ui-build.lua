local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local minionManager = privateVars.minionManager
local langTexts     = privateVars.langTexts

local inspectTimeFrame  = Inspect.Time.Frame
local commandMinionSend = Command.Minion.Send

local mathFloor    = math.floor
local stringFormat = string.format
local pcall        = pcall

---------- buildUI ---------

function minionManager.buildUI()
    local mm = minionManager

    if uiElements.minionManager ~= nil then
        uiElements.minionManager:SetVisible(true)
        return
    end

    local name = "nkUI.mm"

    -- ── Window ────────────────────────────────────────────────
    local win = LibEKL.UICreateFrame("nkWindow", name .. ".win", mm.context)
    win:SetWidth(mm.WIN_W)
    win:SetHeight(mm.WIN_H)
    win:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
        nkUISetup.modules.minionManager.x,
        nkUISetup.modules.minionManager.y)
    win:SetTitle(langTexts.minionManager.windowTitle)
    win:SetTitleFont(addonInfo.id, "MontserratBold")
    win:SetTitleFontSize(15)
    win:SetTitleEffect({ strength = 3 })
    win:SetCloseable(true)
    win:SetTitleFontColor(mm.COL_GOLD.r, mm.COL_GOLD.g, mm.COL_GOLD.b, 1)
    win:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(12, 12, math.pi / 4, 0, 0),
        color = {
            { r = 0.1294, g = 0.1533, b = 0.2157, a = 1, position = 0 },
            { r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1 },
        },
    }, data.theme.STROKE_BORDER)

    Command.Event.Attach(LibEKL.Events[name .. ".win"].Moved, function()
        nkUISetup.modules.minionManager.x = win:GetLeft() - UIParent:GetLeft()
        nkUISetup.modules.minionManager.y = win:GetTop()  - UIParent:GetTop()
    end, name .. ".win.Moved")

    local content = win:GetContent()

    local function _label(lname, text, parent, anchor, xo, yo, size)
        local lbl = LibEKL.UICreateFrame("nkText", name .. "." .. lname, parent)
        lbl:SetPoint(anchor, parent, anchor, xo, yo)
        lbl:SetFontSize(size or 10)
        lbl:SetFontColor(mm.COL_GOLD.r, mm.COL_GOLD.g, mm.COL_GOLD.b, 1)
        lbl:SetText(text)
        LibEKL.UI.SetFont(lbl, addonInfo.id, "MontserratSemiBold")
        lbl:SetEffectGlow({ strength = 2 })
        return lbl
    end

    -- ── TOP: Adventure Cards ───────────────────────────────────

    local cardLabelH = 16
    _label("advLabel", langTexts.minionManager.adventures, content, "TOPLEFT", mm.PAD, mm.PAD)

    local cardsAreaW = mm.CARDS_VISIBLE * mm.CARD_W + (mm.CARDS_VISIBLE - 1) * mm.PAD
    local cardsArea  = LibEKL.UICreateFrame("nkFrame", name .. ".cardsArea", content)
    cardsArea:SetPoint("TOPCENTER", content, "TOPCENTER", 0, cardLabelH + mm.PAD)
    cardsArea:SetWidth(cardsAreaW)
    cardsArea:SetHeight(mm.CARD_H)
    cardsArea:SetLayer(2)

    -- Build card slots
    for i = 1, mm.CARDS_VISIBLE do
        local slot = mm.buildCardSlot(cardsArea, i)
        slot:SetWidth(mm.CARD_W)
        slot:SetHeight(mm.CARD_H)
        if i == 1 then
            slot:SetPoint("TOPLEFT", cardsArea, "TOPLEFT", 0, 0)
        else
            slot:SetPoint("TOPLEFT", mm.cardSlots[i-1], "TOPRIGHT", mm.PAD, 0)
        end
        mm.cardSlots[i] = slot
    end

    -- ── Horizontal divider ─────────────────────────────────────
    local divY = cardLabelH + mm.PAD + mm.CARD_H + mm.PAD

    local divider = LibEKL.UICreateFrame("nkCanvas", name .. ".div", content)
    divider:SetPoint("TOPLEFT",  content, "TOPLEFT",  mm.PAD,  divY)
    divider:SetPoint("TOPRIGHT", content, "TOPRIGHT", -mm.PAD, divY)
    divider:SetHeight(1)
    divider:SetLayer(1)
    divider:SetShape(mm.RECT_PATH, {
        type = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, 0, 0, 0),
        color = {
            { r = 0,             g = 0,             b = 0,             a = 0,   position = 0   },
            { r = mm.COL_GOLD.r, g = mm.COL_GOLD.g, b = mm.COL_GOLD.b, a = 0.4, position = 0.5 },
            { r = 0,             g = 0,             b = 0,             a = 0,   position = 1   },
        },
    }, nil)

    -- ── BOTTOM SECTION ─────────────────────────────────────────
    local bottomY = divY + 1 + mm.PAD
    local bottomH = mm.WIN_H - bottomY - mm.BOTTOM_BAR_H - mm.PAD * 2 - 36
    local activeW = mm.WIN_W - 20 - mm.MINION_W - mm.CENTER_W - mm.PAD * 4

    -- LEFT: Minion list
    local minionPanel = LibEKL.UICreateFrame("nkFrame", name .. ".minionPanel", content)
    minionPanel:SetPoint("TOPLEFT", content, "TOPLEFT", mm.PAD, bottomY)
    minionPanel:SetWidth(mm.MINION_W)
    minionPanel:SetHeight(bottomH)
    minionPanel:SetLayer(2)

    _label("minionLabel", langTexts.minionManager.available, minionPanel, "TOPLEFT", 0, 0, 10)

    mm.minionScroll = LibEKL.UICreateFrame("nkScrollPane", name .. ".minionScroll", minionPanel)
    mm.minionScroll:SetPoint("TOPLEFT", minionPanel, "TOPLEFT", 0, 16)
    mm.minionScroll:SetWidth(mm.MINION_W)
    mm.minionScroll:SetHeight(bottomH - 16)
    mm.minionScroll:SetAdjust(100)
    mm.minionScroll:SetColor(0, 0, 0, 0.2)
    mm.minionScroll:SetColorInner({ r = 0, g = 0, b = 0, a = 0.4 })
    mm.minionScroll:SetColorHighlight(mm.COL_GOLD)

    mm.minionContent = UI.CreateFrame("Frame", name .. ".minionContent", mm.minionScroll)
    mm.minionContent:SetWidth(mm.MINION_W - 12)
    mm.minionContent:SetHeight(mm.MINION_ROW_H)

    -- CENTER: Drop zones + SEND NOW
    local centerPanel = LibEKL.UICreateFrame("nkFrame", name .. ".center", content)
    centerPanel:SetPoint("TOPLEFT", minionPanel, "TOPRIGHT", mm.PAD, 0)
    centerPanel:SetWidth(mm.CENTER_W)
    centerPanel:SetHeight(bottomH)
    centerPanel:SetLayer(2)

    local dropAdvH = mathFloor((bottomH - mm.PAD * 3 - 28) / 2)

    local dropAdvBg = LibEKL.UICreateFrame("nkCanvas", name .. ".dropAdvBg", centerPanel)
    dropAdvBg:SetPoint("TOPLEFT",  centerPanel, "TOPLEFT",  0, 0)
    dropAdvBg:SetPoint("TOPRIGHT", centerPanel, "TOPRIGHT", 0, 0)
    dropAdvBg:SetHeight(dropAdvH)
    dropAdvBg:SetLayer(1)
    mm.setCanvasRect(dropAdvBg, 0, 0, 0, 0.4, { r=0.3, g=0.3, b=0.35, a=0.7 }, 1)

    mm.dropAdvHint = LibEKL.UICreateFrame("nkText", name .. ".dropAdvHint", dropAdvBg)
    mm.dropAdvHint:SetPoint("CENTER", dropAdvBg, "CENTER", 0, 0)
    mm.dropAdvHint:SetFontSize(11)
    mm.dropAdvHint:SetFontColor(mm.COL_DIM.r, mm.COL_DIM.g, mm.COL_DIM.b, 1)
    mm.dropAdvHint:SetText(langTexts.minionManager.selectAdventure)
    mm.dropAdvHint:SetLayer(2)
    LibEKL.UI.SetFont(mm.dropAdvHint, addonInfo.id, "MontserratMediumItalic")

    mm.sendNowBtn = LibEKL.UICreateFrame("nkButton", name .. ".sendNow", centerPanel)
    mm.sendNowBtn:SetLayer(2)
    mm.sendNowBtn:SetPoint("TOPLEFT", dropAdvBg, "BOTTOMLEFT", 0, mm.PAD)
    mm.sendNowBtn:SetWidth(mathFloor((mm.CENTER_W - mm.PAD) / 2))
    mm.sendNowBtn:SetText(langTexts.minionManager.sendNow)
    mm.sendNowBtn:SetFont(addonInfo.id, "MontserratBold")
    mm.sendNowBtn:SetLabelColor(mm.COL_GOLD)
    mm.sendNowBtn:SetEffectGlow({ strength = 5 })
    mm.sendNowBtn:SetFillColor({ type = "solid", r = 0.1, g = 0.08, b = 0, a = 0.8 })
    mm.sendNowBtn:SetBorderColor({ r = mm.COL_GOLD.r, g = mm.COL_GOLD.g, b = mm.COL_GOLD.b, a = 0.9, thickness = 1 })
    mm.sendNowBtn:SetScale(0.9)

    mm.autoSendBtn = LibEKL.UICreateFrame("nkButton", name .. ".autoSend", centerPanel)
    mm.autoSendBtn:SetLayer(2)
    mm.autoSendBtn:SetPoint("TOPRIGHT", dropAdvBg, "BOTTOMRIGHT", 0, mm.PAD)
    mm.autoSendBtn:SetWidth(mathFloor((mm.CENTER_W - mm.PAD) / 2))
    mm.autoSendBtn:SetText(langTexts.minionManager.autoSend)
    mm.autoSendBtn:SetFont(addonInfo.id, "MontserratBold")
    mm.autoSendBtn:SetLabelColor({ r = 0.4, g = 0.85, b = 1, a = 1 })
    mm.autoSendBtn:SetEffectGlow({ strength = 3 })
    mm.autoSendBtn:SetFillColor({ type = "solid", r = 0, g = 0.06, b = 0.12, a = 0.8 })
    mm.autoSendBtn:SetBorderColor({ r = 0.4, g = 0.85, b = 1, a = 0.9, thickness = 1 })
    mm.autoSendBtn:SetScale(0.9)

    local dropMinionBg = LibEKL.UICreateFrame("nkCanvas", name .. ".dropMinionBg", centerPanel)
    dropMinionBg:SetPoint("BOTTOMLEFT",  centerPanel, "BOTTOMLEFT",  0, 0)
    dropMinionBg:SetPoint("BOTTOMRIGHT", centerPanel, "BOTTOMRIGHT", 0, 0)
    dropMinionBg:SetHeight(dropAdvH)
    dropMinionBg:SetLayer(1)
    mm.setCanvasRect(dropMinionBg, 0, 0, 0, 0.4, { r=0.3, g=0.3, b=0.35, a=0.7 }, 1)

    mm.dropMinionHint = LibEKL.UICreateFrame("nkText", name .. ".dropMinionHint", dropMinionBg)
    mm.dropMinionHint:SetPoint("CENTER", dropMinionBg, "CENTER", 0, 0)
    mm.dropMinionHint:SetFontSize(11)
    mm.dropMinionHint:SetFontColor(mm.COL_DIM.r, mm.COL_DIM.g, mm.COL_DIM.b, 1)
    mm.dropMinionHint:SetText(langTexts.minionManager.selectMinion)
    mm.dropMinionHint:SetLayer(2)
    LibEKL.UI.SetFont(mm.dropMinionHint, addonInfo.id, "MontserratMediumItalic")

    mm.sendNowBtn:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        if mm.selectedMinionId == nil then
            Command.Console.Display("general", true,
                stringFormat('<font color="#FF6A00">%s</font>', langTexts.minionManager.noMinion), true)
            return
        end
        if mm.selectedAdvId == nil then
            Command.Console.Display("general", true,
                stringFormat('<font color="#FF6A00">%s</font>', langTexts.minionManager.noAdventure), true)
            return
        end
        local ok, err = pcall(commandMinionSend, mm.selectedMinionId, mm.selectedAdvId)
        if not ok then LibEKL.Tools.Error.Display("nkUI.minionManager", tostring(err), 2) end
        mm.selectedAdvId    = nil
        mm.selectedMinionId = nil
    end, name .. ".sendNow.LeftUp")

    mm.autoSendBtn:EventAttach(Event.UI.Input.Mouse.Left.Up, function()
        mm.autoSend()
    end, name .. ".autoSend.LeftUp")

    -- RIGHT: Active missions
    local activePanel = LibEKL.UICreateFrame("nkFrame", name .. ".activePanel", content)
    activePanel:SetPoint("TOPLEFT", centerPanel, "TOPRIGHT", mm.PAD, 0)
    activePanel:SetWidth(activeW)
    activePanel:SetHeight(bottomH)
    activePanel:SetLayer(2)

    _label("activeLabel", langTexts.minionManager.active, activePanel, "TOPLEFT", 0, 0, 10)

    mm.activeScroll = LibEKL.UICreateFrame("nkScrollPane", name .. ".activeScroll", activePanel)
    mm.activeScroll:SetPoint("TOPLEFT", activePanel, "TOPLEFT", 0, 16)
    mm.activeScroll:SetWidth(activeW)
    mm.activeScroll:SetHeight(bottomH - 16)
    mm.activeScroll:SetAdjust(100)
    mm.activeScroll:SetColor(0, 0, 0, 0.2)
    mm.activeScroll:SetColorInner({ r = 0, g = 0, b = 0, a = 0.4 })
    mm.activeScroll:SetColorHighlight(mm.COL_GOLD)

    mm.activeContent = UI.CreateFrame("Frame", name .. ".activeContent", mm.activeScroll)
    mm.activeContent:SetWidth(activeW - 12)
    mm.activeContent:SetHeight(mm.ACTIVE_ROW_H)

    -- BOTTOM BAR
    local bottomBar = LibEKL.UICreateFrame("nkCanvas", name .. ".bottomBar", content)
    bottomBar:SetPoint("BOTTOMLEFT",  content, "BOTTOMLEFT",  0, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    bottomBar:SetHeight(mm.BOTTOM_BAR_H)
    bottomBar:SetLayer(1)
    mm.setCanvasRect(bottomBar, 0, 0, 0, 0.5, { r=0.25, g=0.22, b=0.12, a=0.4 }, 1)

    local creditIcon = LibEKL.UICreateFrame("nkTexture", name .. ".creditIcon", bottomBar)
    creditIcon:SetLayer(2)
    creditIcon:SetPoint("CENTERLEFT", bottomBar, "CENTERLEFT", mm.PAD, 0)
    creditIcon:SetWidth(16)
    creditIcon:SetHeight(16)
    creditIcon:SetTextureAsync("Rift", "btn_credits_(normal).png.dds")

    mm.currencyLabel = LibEKL.UICreateFrame("nkText", name .. ".currency", bottomBar)
    mm.currencyLabel:SetLayer(2)
    mm.currencyLabel:SetPoint("CENTERLEFT", bottomBar, "CENTERLEFT", mm.PAD + 20, 0)
    mm.currencyLabel:SetFontSize(11)
    mm.currencyLabel:SetFontColor(mm.COL_GOLD.r, mm.COL_GOLD.g, mm.COL_GOLD.b, 1)
    mm.currencyLabel:SetText("")
    LibEKL.UI.SetFont(mm.currencyLabel, addonInfo.id, "MontserratMedium")

    uiElements.minionManager = win
    win:SetVisible(true)
end
