--[[
    settings/manual.lua
    Author: NaifuKishi
    Description: Manual window explaining all nkUI modules to the user.
    Public Functions:
        - internalFunc.manual(): Opens the manual window
]]

local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local langTexts     = privateVars.langTexts
local THEME         = privateVars.theme

---------- init local variables ---------

-- Sections are defined later once langTexts is confirmed available.
-- The manual window is created lazily on first open.

---------- local function block ---------

local function _createManualWindow()

    local name = "nkUI.manualWindow"

    local manualWindow = LibEKL.UICreateFrame("nkWindow", name, uiElements.settingsContext)
    manualWindow:SetLayer(3)
    manualWindow:SetTitle(langTexts.manual.windowTitle)
    manualWindow:SetTitleFont(addonInfo.id, "MontserratSemiBold")
    manualWindow:SetWidth(700)
    manualWindow:SetHeight(700)
    manualWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
        (LibEKL.UI.getBoundRight() / 2) - (700 / 2), 180)
    manualWindow:SetTitleFontSize(16)
    manualWindow:SetTitleEffect({strength = 3})
    manualWindow:SetTitleFontColor(
        data.theme.labelColor.r, data.theme.labelColor.g,
        data.theme.labelColor.b, data.theme.labelColor.a)
    manualWindow:SetCloseable(true)

    manualWindow:SetColor(THEME.WINDOW_BACKGROUND, THEME.WINDOW_BORDER)

    local content = manualWindow:GetContent()

    -- ---- Sections list ----
    local sections = langTexts.manual.sections

    -- ---- Left sidebar: section list ----

    local sidebarWidth = 180
    local sidebar = LibEKL.UICreateFrame("nkFrame", name .. ".sidebar", content)
    sidebar:SetPoint("TOPLEFT", content, "TOPLEFT", 8, 8)
    sidebar:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 8, -50)
    sidebar:SetWidth(sidebarWidth)

    -- ---- Right content pane (scrollable) ----

    -- Explicit dimensions required: anchor-only sizing gives GetHeight()=0 at init,
    -- which breaks SetContent's scrollbar range calculation.
    -- Window=700, titlebar~30, bottom area=50 → scroll height ≈ 580
    local SCROLL_W = 472
    local SCROLL_H = 580

    local scrollPane = LibEKL.UICreateFrame("nkScrollPane", name .. ".scroll", content)
    scrollPane:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
    scrollPane:SetWidth(SCROLL_W)
    scrollPane:SetHeight(SCROLL_H)
    scrollPane:SetAdjust(100)
    scrollPane:SetColor(0, 0, 0, 0.2)
    scrollPane:SetColorInner({ r = 0, g = 0, b = 0, a = 0.4 })
    scrollPane:SetColorHighlight(data.theme.formElementColorMain)

    -- Inner content container with fixed height (allows scrollbar to work)
    local scrollContent = UI.CreateFrame("Frame", name .. ".scrollContent", scrollPane)
    scrollContent:SetWidth(SCROLL_W - 12)   -- -12 for scrollbar width
    scrollContent:SetHeight(1200)

    -- ---- Content text/image elements ----

    -- Content area width: scrollContent width minus horizontal padding
    local contentTextWidth = SCROLL_W - 12 - 20

    local sectionTitle = LibEKL.UICreateFrame("nkText", name .. ".sectionTitle", scrollContent)
    sectionTitle:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 10, 10)
    sectionTitle:SetFontSize(18)
    sectionTitle:SetTextFont(addonInfo.id, "MontserratBold")
    sectionTitle:SetFontColor(
        data.theme.labelColor.r, data.theme.labelColor.g,
        data.theme.labelColor.b, data.theme.labelColor.a)
    sectionTitle:SetEffectGlow({strength = 3})

    local sectionBody = LibEKL.UICreateFrame("nkText", name .. ".sectionBody", scrollContent)
    sectionBody:SetPoint("TOPLEFT", sectionTitle, "BOTTOMLEFT", 0, 12)
    sectionBody:SetFontSize(14)
    sectionBody:SetTextFont(addonInfo.id, "MontserratSemiBold")
    sectionBody:SetFontColor(
        data.theme.labelColor.r, data.theme.labelColor.g,
        data.theme.labelColor.b, data.theme.labelColor.a)
    sectionBody:SetWordwrap(true)
    sectionBody:SetEffectGlow({strength = 2})

    -- Logo stays outside the scroll content so it doesn't scroll
    local logoImage = LibEKL.UICreateFrame("nkTexture", name .. ".logo", content)
    logoImage:SetVisible(false)

    -- ---- Section buttons ----

    local buttonHeight = 30
    local buttonPadding = 4
    local sectionButtons = {}
    local currentSection = 1

    sectionTitle:SetWidth(contentTextWidth)
    sectionBody:SetWidth(contentTextWidth)

    local function showSection(idx)
        currentSection = idx
        local sec = sections[idx]
        sectionTitle:SetText(sec.title)
        sectionBody:SetText(sec.body)
        scrollContent:SetHeight(1200)
        scrollPane:SetContent(scrollContent)
        scrollPane:SetLanePosition(0)

        -- Show/hide logo based on section
        if idx == 1 then
            logoImage:SetVisible(true)
            logoImage:SetPoint("CENTER", scrollPane, "CENTER", -6, -30)
            logoImage:SetWidth(200)
            logoImage:SetHeight(197)
            logoImage:SetTextureAsync(addonInfo.identifier, "gfx/nkUILogo.png")
            sectionTitle:SetVisible(false)
            sectionBody:SetVisible(false)
        else
            logoImage:SetVisible(false)
            sectionTitle:SetVisible(true)
            sectionBody:SetVisible(true)
        end

        -- Highlight active button
        for i, btn in ipairs(sectionButtons) do
            if i == idx then
                btn:SetFillColor({type = "solid",
                    r = data.theme.windowEndColor.r,
                    g = data.theme.windowEndColor.g,
                    b = data.theme.windowEndColor.b,
                    a = 0.5})
            else
                btn:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = 0.3})
            end
        end
    end

    for i = 1, #sections do
        local sec = sections[i]
        local btn = LibEKL.UICreateFrame("nkButton", name .. ".nav." .. i, sidebar)
        local yOff = (i - 1) * (buttonHeight + buttonPadding) + 4
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 4, yOff)
        btn:SetWidth(sidebarWidth - 8)
        btn:SetHeight(buttonHeight)
        btn:SetText(sec.title)
        btn:SetFont(addonInfo.id, "MontserratSemiBold")
        btn:SetLabelColor(data.theme.labelColor)
        btn:SetEffectGlow({strength = 2})
        btn:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = 0.3})
        btn:SetBorderColor({r = 0, g = 0, b = 0, a = 0.5, thickness = 1})
        btn:SetFontSize(12)

        local capturedIdx = i
        Command.Event.Attach(LibEKL.Events[name .. ".nav." .. i].Clicked,
            function()
                showSection(capturedIdx)
            end,
            name .. ".nav." .. i .. ".Clicked")

        sectionButtons[i] = btn
    end

    -- ---- Close button ----

    local closeButton = LibEKL.UICreateFrame("nkButton", name .. ".closeButton", content)
    closeButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, -10)
    closeButton:SetText(langTexts.settings.close)
    closeButton:SetScale(0.8)
    closeButton:SetLayer(9)
    closeButton:SetFont(addonInfo.id, "MontserratSemiBold")
    closeButton:SetLabelColor(data.theme.labelColor)
    closeButton:SetEffectGlow({strength = 3})
    closeButton:SetFillColor({type = "solid", r = 0, g = 0, b = 0, a = 0.4})
    closeButton:SetBorderColor({r = 0, g = 0, b = 0, a = 0.7, thickness = 1})

    Command.Event.Attach(LibEKL.Events[name .. ".closeButton"].Clicked,
        function()
            manualWindow:SetVisible(false)
        end,
        name .. ".closeButton.Clicked")

    -- Show first section on open
    showSection(1)

    function manualWindow:open()
        showSection(1)
        manualWindow:SetVisible(true)
    end

    return manualWindow
end

---------- addon internalFunc function block ---------

function internalFunc.manual()
    if uiElements.manualWindow == nil then
        uiElements.manualWindow = _createManualWindow()
    else
        uiElements.manualWindow:open()
    end
end
