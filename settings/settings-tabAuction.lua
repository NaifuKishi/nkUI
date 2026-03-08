local addonInfo, privateVars = ...

---------- init namespace ---------

local internalFunc  = privateVars.internalFunc
local settingsUI    = privateVars.settingsUI
local langTexts     = privateVars.langTexts

---------- init local variables ---------

function settingsUI.uiConfigTabAuction(name, parent)

    local frame = LibEKL.UICreateFrame("nkFrame", name, parent)
    local activateCheckbox
    local scanDepthSlider, trendThresholdSlider, priceFloorSlider, undercutSlider

    function frame:build()

        -- ── Activate ──────────────────────────────────────────────────────

        activateCheckbox = settingsUI.checkbox(name .. ".activateCheckbox", frame,
            langTexts.settings.activateModule, true, function(newValue)
                nkUISetup.modules.auction.activate = newValue
            end)
        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, settingsUI.PADDING.ACTIVE)
        activateCheckbox:SetChecked(nkUISetup.modules.auction.activate, true)

        -- ── Scan settings header ───────────────────────────────────────────

        local scanHeader = settingsUI.header(name .. ".scanHeader", frame,
            langTexts.auction.settingsScanHeader)
        scanHeader:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)

        -- ── Scan depth ────────────────────────────────────────────────────

        scanDepthSlider = settingsUI.slider(name .. ".scanDepthSlider", frame,
            langTexts.auction.settingsScanDepth, true, function(newValue)
                nkUISetup.modules.auction.scanDepth = newValue
            end)
        scanDepthSlider:SetPoint("TOPLEFT", scanHeader, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        scanDepthSlider:SetRange(1, 14)
        scanDepthSlider:SetMidValue(7)
        scanDepthSlider:SetPrecision(1)
        scanDepthSlider:AdjustValue(nkUISetup.modules.auction.scanDepth or 3)

        -- ── Trend threshold ───────────────────────────────────────────────

        trendThresholdSlider = settingsUI.slider(name .. ".trendThresholdSlider", frame,
            langTexts.auction.settingsTrendThreshold, true, function(newValue)
                nkUISetup.modules.auction.trendThreshold = newValue / 100
            end)
        trendThresholdSlider:SetPoint("TOPLEFT", scanDepthSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        trendThresholdSlider:SetRange(5, 50)
        trendThresholdSlider:SetMidValue(25)
        trendThresholdSlider:SetPrecision(1)
        trendThresholdSlider:AdjustValue((nkUISetup.modules.auction.trendThreshold or 0.15) * 100)

        -- ── Pricing header ────────────────────────────────────────────────

        local priceHeader = settingsUI.header(name .. ".priceHeader", frame,
            langTexts.auction.settingsPriceHeader)
        priceHeader:SetPoint("TOPLEFT", trendThresholdSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.HEADING)

        -- ── Price floor ───────────────────────────────────────────────────

        priceFloorSlider = settingsUI.slider(name .. ".priceFloorSlider", frame,
            langTexts.auction.settingsPriceFloor, true, function(newValue)
                nkUISetup.modules.auction.priceFloor = newValue / 100
            end)
        priceFloorSlider:SetPoint("TOPLEFT", priceHeader, "BOTTOMLEFT", 0, settingsUI.PADDING.AFTERHEADING)
        priceFloorSlider:SetRange(50, 100)
        priceFloorSlider:SetMidValue(75)
        priceFloorSlider:SetPrecision(1)
        priceFloorSlider:AdjustValue((nkUISetup.modules.auction.priceFloor or 0.85) * 100)

        -- ── Undercut amount ───────────────────────────────────────────────

        undercutSlider = settingsUI.slider(name .. ".undercutSlider", frame,
            langTexts.auction.settingsUndercut, true, function(newValue)
                nkUISetup.modules.auction.undercutAmount = newValue
            end)
        undercutSlider:SetPoint("TOPLEFT", priceFloorSlider, "BOTTOMLEFT", 0, settingsUI.PADDING.REGULAR)
        undercutSlider:SetRange(1, 1000)
        undercutSlider:SetMidValue(500)
        undercutSlider:SetPrecision(1)
        undercutSlider:AdjustValue(nkUISetup.modules.auction.undercutAmount or 1)

    end

    return frame

end
