local addonInfo, privateVars = ...

---------- init namespace ---------

local minionManager = privateVars.minionManager
local langTexts     = privateVars.langTexts

local commandMinionSend      = Command.Minion.Send
local inspectMinionDetail    = Inspect.Minion.Minion.Detail
local inspectMinionList      = Inspect.Minion.Minion.List
local inspectAdventureList   = Inspect.Minion.Adventure.List
local inspectAdventureDetail = Inspect.Minion.Adventure.Detail

local stringFormat   = string.format
local pairs          = pairs
local pcall          = pcall
local tostring       = tostring

---------- stat fields shared with adventure details ---------

-- Adventure stat fields in the same order as STAT_ICONS
local ADV_STAT_FIELDS = {
    "statEarth", "statAir", "statFire", "statWater",
    "statLife", "statDeath", "statHunting", "statDiplomacy",
    "statHarvesting", "statDimension", "statArtifact", "statAssassination",
}

---------- helpers ---------

-- Returns how many stat fields in `adv` are non-zero/non-false.
-- Also returns a table of those field names for matching.
local function _advStats(adv)
    local fields = {}
    for i = 1, #ADV_STAT_FIELDS do
        local f = ADV_STAT_FIELDS[i]
        local v = adv[f]
        if v == true or (type(v) == "number" and v > 0) then
            fields[f] = true
        end
    end
    return fields
end

-- Returns the total stat value of a minion across all stats.
local function _minionTotalStats(det)
    local total = 0
    for i = 1, #ADV_STAT_FIELDS do
        local v = det[ADV_STAT_FIELDS[i]]
        if type(v) == "number" then total = total + v end
    end
    return total
end

-- Count how many of the adventure's stat fields the minion has a non-zero value for.
local function _matchCount(advStats, minionDet)
    local count = 0
    for f in pairs(advStats) do
        local v = minionDet[f]
        if type(v) == "number" and v > 0 then
            count = count + 1
        end
    end
    return count
end

---------- adventure selection ---------

-- Fetches available adventures directly from the API (does not rely on allAdvData).
local function _fetchAvailableAdventures()
    local ok1, advIds = pcall(inspectAdventureList)
    if not ok1 or advIds == nil then return {} end

    local ok2, advDetails = pcall(inspectAdventureDetail, advIds)
    if not ok2 or advDetails == nil then return {} end

    local available = {}
    for id, adv in pairs(advDetails) do
        if (adv.mode or "none") == "available" then
            available[id] = adv
        end
    end
    return available
end

-- Picks the best adventure id for the configured duration tier.
-- autoSendDuration: 1=quick (<300s), 2=short (<=1200s), 3=long (>1200s), 4=premium (any cost)
local function _pickAdventure(availableAdvs)
    local cfg      = nkUISetup.modules.minionManager
    local wantTier = cfg.autoSendDuration or 1

    local bestId  = nil
    local bestDur = math.huge

    for id, adv in pairs(availableAdvs) do
        local cost = (adv.costAventurine or 0) + (adv.costCredit or 0)
        local dur  = adv.duration or 0
        local tier

        if cost > 0 then
            tier = 4
        elseif dur < 300 then
            tier = 1
        elseif dur <= 1200 then
            tier = 2
        else
            tier = 3
        end

        if tier == wantTier then
            if dur < bestDur then
                bestDur = dur
                bestId  = id
            end
        end
    end

    return bestId
end

---------- minion scoring ---------

-- Scores a minion for a given adventure.
-- priority: 1=best stats, 2=lowest level, 3=highest level, 4=stamina distribution
-- match:    0=no requirement, 1=must match >=1 stat, 2=must match >=2 stats
local function _scoreMinion(minionDet, advStats, priority, matchReq)
    -- Check match requirement first
    local matched = _matchCount(advStats, minionDet)
    if matched < matchReq then return nil end  -- does not qualify

    local score
    local level = minionDet.level or 0
    if priority == 1 then
        -- Best total stats (highest is better)
        score = _minionTotalStats(minionDet)
    elseif priority == 2 then
        -- Lowest level (invert so lower = higher score)
        score = -level
    elseif priority == 3 then
        -- Highest level
        score = level
    else
        -- Priority 4: distribute stamina — prefer minion with highest remaining stamina
        score = minionDet.stamina or 0
    end

    return score
end

---------- public: autoSend ---------

function minionManager.autoSend()
    local mm  = minionManager
    local cfg = nkUISetup.modules.minionManager
    local lt  = langTexts.minionManager

    -- Fetch available adventures directly (works even if UI is not open)
    local availableAdvs = _fetchAvailableAdventures()

    -- Also update allAdvData so the UI stays consistent if it gets opened later
    mm.allAdvData = mm.allAdvData or {}
    for id, adv in pairs(availableAdvs) do
        mm.allAdvData[id] = adv
    end

    -- Pick adventure
    local advId = _pickAdventure(availableAdvs)
    if advId == nil then
        Command.Console.Display("general", true,
            stringFormat('<font color="#FF6A00">%s</font>', lt.autoSendNoAdventure), true)
        return
    end

    local adv      = mm.allAdvData[advId]
    local advStats = _advStats(adv)

    -- Fetch fresh minion list to find idle minions
    local ok1, minionIds = pcall(inspectMinionList)
    if not ok1 or minionIds == nil then minionIds = {} end

    local ok2, minionDetails = pcall(inspectMinionDetail, minionIds)
    if not ok2 or minionDetails == nil then minionDetails = {} end

    -- Build set of busy minion ids from active adventure slots
    local busyIds = {}
    local ok3, advIds = pcall(inspectAdventureList)
    if ok3 and advIds then
        local ok4, advDets = pcall(inspectAdventureDetail, advIds)
        if ok4 and advDets then
            for _, a in pairs(advDets) do
                local mode = a.mode or "none"
                if (mode == "working" or mode == "finished") and a.minion then
                    busyIds[a.minion] = true
                end
            end
        end
    end

    local priority = cfg.autoSendPriority or 1
    local matchReq = cfg.autoSendMatch    or 1

    -- Cap matchReq to the number of stats the adventure actually requires,
    -- then fall back down to 0 if no minion qualifies at the requested level.
    local advStatCount = 0
    for _ in pairs(advStats) do advStatCount = advStatCount + 1 end
    if matchReq > advStatCount then matchReq = advStatCount end

    local bestId    = nil
    local bestScore = nil

    while bestId == nil and matchReq >= 0 do
        for id, det in pairs(minionDetails) do
            if not busyIds[id] then
                local score = _scoreMinion(det, advStats, priority, matchReq)
                if score ~= nil then
                    if bestScore == nil or score > bestScore then
                        bestScore = score
                        bestId    = id
                    end
                end
            end
        end
        if bestId == nil then
            matchReq  = matchReq - 1
            bestScore = nil
        end
    end

    if bestId == nil then
        Command.Console.Display("general", true,
            stringFormat('<font color="#FF6A00">%s</font>', lt.autoSendNoMinion), true)
        return
    end

    local ok, err = pcall(commandMinionSend, bestId, advId)
    if not ok then
        LibEKL.Tools.Error.Display("nkUI.minionManager", tostring(err), 2)
    end
end
