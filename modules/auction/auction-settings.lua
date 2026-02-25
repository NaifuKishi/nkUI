local addonInfo, privateVars = ...

---------- init namespace ---------

local auction       = privateVars.auction
local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local langTexts     = privateVars.langTexts

---------- Phase 4: Settings Pane ----------

-- Placeholder for Phase 4 implementation
-- When enabled, will include:
-- - settingsUI.uiConfigTabAuction(name, parent) — settings tab builder
-- - Pattern: mirrors settings/settings-tabTooltip.lua
-- - Settings exposed:
--   - Auto-open with AH (checkbox)
--   - Show price in tooltip (checkbox)
--   - Bid % of buyout (slider 50–100)
--   - Undercut type (dropdown: absolute / relative)
--   - Undercut amount (nkTextField)
--   - Default price model (dropdown)
--   - Default duration (dropdown)
--   - Price history depth / scan depth (slider)
--   - Auto-scan on AH open (checkbox)
-- - Injected into settings.lua internalFunc.setupUI() as new tab
