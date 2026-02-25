local addonInfo, privateVars = ...

---------- init namespace ---------

local auction       = privateVars.auction
local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local langTexts     = privateVars.langTexts

local InspectAuctionDetail = Inspect.Auction.Detail
local InspectItemDetail    = Inspect.Item.Detail
local InspectShard         = Inspect.Shard

local stringFormat  = string.format
local mathFloor     = math.floor

---------- Phase 1A: Browse Tab Enhancements ----------

-- Placeholder for Phase 1A implementation
-- When enabled, will include:
-- - Rarity filter bar (7 toggles)
-- - Bid column in grid
-- - My Price column (from auction.ownAuctions)
-- - Sort persistence
-- - Event rename to "nkUI.Auction.Browse.Scan"
