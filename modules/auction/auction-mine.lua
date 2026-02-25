local addonInfo, privateVars = ...

---------- init namespace ---------

local auction       = privateVars.auction
local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local langTexts     = privateVars.langTexts

local InspectAuctionDetail = Inspect.Auction.Detail
local InspectTimeReal      = Inspect.Time.Real
local InspectShard         = Inspect.Shard

local stringFormat  = string.format
local mathFloor     = math.floor

---------- Phase 1B: My Auctions Tab ----------

-- Placeholder for Phase 1B implementation
-- When enabled, will include:
-- - auction.refreshMyAuctions() — scans all own auctions
-- - Populates auction.ownAuctions for Browse tab's My Price column
-- - Competition scoring with SCORE_TIERS coloring
-- - Grid columns: Icon | Item | Stack | Buyout | Unit | Expires | Score | Below
-- - Filter bar: 5 score tier checkboxes + Max below text field
-- - Cancel actions: [Cancel Selected] and [Cancel All] with confirmation
-- - Event handlers: "nkUI.Auction.Mine.Remove" and "nkUI.Auction.Mine.Add"
