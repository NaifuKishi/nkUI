local addonInfo, privateVars = ...

---------- init namespace ---------

local minionManager = privateVars.minionManager
local langTexts     = privateVars.langTexts

local mathFloor  = math.floor
local mathMax    = math.max
local mathMin    = math.min
local stringFormat = string.format
local tableInsert  = table.insert
local tableRemove  = table.remove
local pairs        = pairs
local tostring     = tostring

---------- layout constants ---------

minionManager.WIN_W        = 1060
minionManager.WIN_H        = 580
minionManager.PAD          = 6
minionManager.CARD_H       = 200
minionManager.CARD_W       = 170
minionManager.CARDS_VISIBLE = 4
minionManager.MINION_W     = 446
minionManager.MINION_COL_W = 220   -- width of one minion column ((446 - 6 gap) / 2)
minionManager.MINION_ROW_H = 68
minionManager.CENTER_W     = 170
minionManager.ACTIVE_ROW_H = 58
minionManager.ACTIVE_ROW_W = 1060 - 20 - 446 - 170 - 24 - 12  -- activeW minus scrollbar
minionManager.BOTTOM_BAR_H = 28

---------- colours ---------

minionManager.COL_GOLD   = { r = 1,    g = 0.8,  b = 0,    a = 1 }
minionManager.COL_WHITE  = { r = 1,    g = 1,    b = 1,    a = 1 }
minionManager.COL_DIM    = { r = 0.55, g = 0.55, b = 0.55, a = 1 }
minionManager.COL_GREEN  = { r = 0.2,  g = 0.85, b = 0.35, a = 1 }
minionManager.COL_BLUE   = { r = 0.25, g = 0.55, b = 1,    a = 1 }
minionManager.COL_ORANGE = { r = 1,    g = 0.45, b = 0.1,  a = 1 }
minionManager.COL_PURPLE = { r = 0.7,  g = 0.3,  b = 1.0,  a = 1 }

minionManager.RARITY_COLORS = {
    common   = minionManager.COL_DIM,
    uncommon = minionManager.COL_GREEN,
    rare     = minionManager.COL_BLUE,
    epic     = minionManager.COL_PURPLE,
}

-- Maps API reward type keys to human-readable display strings.
-- Unknown types fall back to the raw API string.
minionManager.REWARD_LABELS = {
    experience = "Minion Experience",
    material   = "Cloth, Salvage and Runecrafting Materials",
    diplomacy  = "Notoriety",
    harvest    = "Ore, Plants and Wood",
}

-- Maps adventure stat/reward type to border colour.
-- Unknown types fall back to COL_BLUE.
minionManager.STAT_COLORS = {
    fire          = { r = 0.95, g = 0.25, b = 0.1,  a = 1 },  -- Feuer       = Rot
    air           = { r = 0.65, g = 0.65, b = 0.65, a = 1 },  -- Luft        = Grau
    assassination = { r = 0.65, g = 0.2,  b = 0.9,  a = 1 },  -- Assassination = Violett
    earth         = { r = 0.85, g = 0.65, b = 0.1,  a = 1 },  -- Erde        = Gold
    -- known but colour TBD — placeholders:
    water         = { r = 0.2,  g = 0.6,  b = 1.0,  a = 1 },
    life          = { r = 0.2,  g = 0.85, b = 0.35, a = 1 },
    death         = { r = 0.5,  g = 0.1,  b = 0.6,  a = 1 },
    hunting       = { r = 0.7,  g = 0.45, b = 0.1,  a = 1 },
    diplomacy     = { r = 0.3,  g = 0.75, b = 0.75, a = 1 },
    harvesting    = { r = 0.45, g = 0.7,  b = 0.2,  a = 1 },
    dimension     = { r = 0.8,  g = 0.3,  b = 0.8,  a = 1 },
    artifact      = { r = 0.9,  g = 0.8,  b = 0.3,  a = 1 },
}

-- Stat fields present on adventure details
local ADV_STAT_FIELDS = {
    "statFire", "statAir", "statEarth", "statWater",
    "statLife", "statDeath", "statHunting", "statDiplomacy",
    "statHarvesting", "statDimension", "statArtifact", "statAssassination",
}

-- Returns the colour for the dominant stat of an adventure.
-- Picks the stat with the highest value; falls back to COL_BLUE.
function minionManager.getAdvColor(adv)
    if adv == nil then return minionManager.COL_BLUE end
    local bestKey = nil
    local bestVal = 0
    for i = 1, #ADV_STAT_FIELDS do
        local field = ADV_STAT_FIELDS[i]
        local v = adv[field]
        if type(v) == "number" and v > bestVal then
            bestVal = v
            bestKey = field
        elseif v == true and bestVal == 0 and bestKey == nil then
            -- boolean true means stat is present but no numeric value
            bestKey = field
        end
    end
    if bestKey then
        -- strip "stat" prefix and lowercase: "statFire" -> "fire"
        local statName = bestKey:sub(5, 5):lower() .. bestKey:sub(6)
        local c = minionManager.STAT_COLORS[statName]
        if c then return c end
    end
    return minionManager.COL_BLUE
end

---------- shared state (written by ui-build, read by all) ---------

minionManager.selectedAdvId    = nil
minionManager.selectedMinionId = nil
minionManager.allAdvData       = {}
minionManager.currentPage      = 1

minionManager.minionBin  = {}
minionManager.activeBin  = {}
minionManager.minionRows = {}
minionManager.cardSlots  = {}
minionManager.activeRows = {}

minionManager.minionContent  = nil
minionManager.minionScroll   = nil
minionManager.activeContent  = nil
minionManager.activeScroll   = nil
minionManager.sendNowBtn     = nil
minionManager.dropAdvHint    = nil
minionManager.dropMinionHint = nil
minionManager.currencyLabel  = nil

---------- canvas path helpers ---------

minionManager.RECT_PATH = {
    { xProportional = 0, yProportional = 0 },
    { xProportional = 1, yProportional = 0 },
    { xProportional = 1, yProportional = 1 },
    { xProportional = 0, yProportional = 1 },
    { xProportional = 0, yProportional = 0 },
}

function minionManager.solidFill(r, g, b, a)
    return { type = "solid", r = r, g = g, b = b, a = a }
end

function minionManager.border(col, thickness)
    return { r = col.r, g = col.g, b = col.b, a = col.a,
             cap = "round", miter = "miter", thickness = thickness or 1 }
end

function minionManager.setCanvasRect(canvas, fillR, fillG, fillB, fillA, borderCol, thickness)
    canvas:SetShape(minionManager.RECT_PATH,
        minionManager.solidFill(fillR, fillG, fillB, fillA),
        borderCol and minionManager.border(borderCol, thickness) or nil)
end

---------- stat icon table (shared by minion rows and adventure cards) ---------

minionManager.STAT_ICONS = {
    { field = "statEarth",         icon = "Minion_I141.dds" },
    { field = "statAir",           icon = "Minion_I143.dds" },
    { field = "statFire",          icon = "Minion_I145.dds" },
    { field = "statWater",         icon = "Minion_I147.dds" },
    { field = "statLife",          icon = "Minion_I149.dds" },
    { field = "statDeath",         icon = "Minion_I14B.dds" },
    { field = "statHunting",       icon = "Minion_I14D.dds" },
    { field = "statDiplomacy",     icon = "Minion_I14F.dds" },
    { field = "statHarvesting",    icon = "Minion_I151.dds" },
    { field = "statDimension",     icon = "Minion_I153.dds" },
    { field = "statArtifact",      icon = "Minion_I155.dds" },
    { field = "statAssassination", icon = "Minion_I157.dds" },
}

minionManager.STAT_ICON_SIZE = 14

---------- shared helpers ---------

-- Splits a text string into up to maxLines lines, each at most maxChars characters,
-- breaking only at word boundaries. Returns a table of line strings.
function minionManager.splitLines(text, maxChars, maxLines)
    local lines = {}
    local words = {}
    for word in text:gmatch("%S+") do
        tableInsert(words, word)
    end
    local line = ""
    for i = 1, #words do
        local word = words[i]
        if line == "" then
            line = word
        elseif #line + 1 + #word <= maxChars then
            line = line .. " " .. word
        else
            tableInsert(lines, line)
            if #lines >= maxLines then
                lines[maxLines] = lines[maxLines] .. "…"
                return lines
            end
            line = word
        end
    end
    if line ~= "" then tableInsert(lines, line) end
    return lines
end

-- Creates up to maxLines centered nkText frames stacked vertically.
-- Returns a table of the text frames and a setter function:
--   setLines(text) — re-splits and updates all frames
function minionManager.buildMultilineText(baseName, parent, maxChars, maxLines, fontSize, fontName, layer)
    local mm      = minionManager
    local frames  = {}
    local lineH   = fontSize + 4
    for i = 1, maxLines do
        local lbl = LibEKL.UICreateFrame("nkText", baseName .. ".l" .. i, parent)
        lbl:SetLayer(layer or 2)
        lbl:SetFontSize(fontSize)
        lbl:SetFontColor(mm.COL_WHITE.r, mm.COL_WHITE.g, mm.COL_WHITE.b, 1)
        LibEKL.UI.SetFont(lbl, addonInfo.id, fontName)
        lbl:SetVisible(false)
        frames[i] = lbl
    end

    -- fromBottom=false: lines grow downward from anchor (TOPCENTER)
    -- fromBottom=true:  lines grow upward from anchor (BOTTOMCENTER),
    --                   last line sits at anchor, earlier lines above it
    local function setLines(anchorFrame, anchorPoint, xOff, yOff, text, fromBottom)
        local lines = mm.splitLines(text or "", maxChars, maxLines)
        if fromBottom then
            local n = #lines
            for i = 1, maxLines do
                local lineIdx = n - (maxLines - i)  -- map frame slot to line index
                if lineIdx >= 1 and lines[lineIdx] then
                    frames[i]:SetText(lines[lineIdx])
                    frames[i]:SetPoint("BOTTOMCENTER", anchorFrame, anchorPoint,
                        xOff, yOff - (maxLines - i) * lineH)
                    frames[i]:SetVisible(true)
                else
                    frames[i]:SetVisible(false)
                end
            end
        else
            for i = 1, maxLines do
                if lines[i] then
                    frames[i]:SetText(lines[i])
                    frames[i]:SetPoint("TOPCENTER", anchorFrame, anchorPoint, xOff, yOff + (i - 1) * lineH)
                    frames[i]:SetVisible(true)
                else
                    frames[i]:SetVisible(false)
                end
            end
        end
    end

    return frames, setLines
end

function minionManager.formatTime(secs)
    if secs == nil or secs <= 0 then return langTexts.minionManager.done end
    local h = mathFloor(secs / 3600)
    local m = mathFloor((secs % 3600) / 60)
    local s = mathFloor(secs % 60)
    if h > 0 then return stringFormat("%dh %02dm", h, m)
    elseif m > 0 then return stringFormat("%dm %02ds", m, s)
    else return stringFormat("%ds", s)
    end
end

function minionManager.restackRows(rows, contentFrame, rowH)
    local totalH = 0
    for i = 1, #rows do
        if i == 1 then
            rows[i]:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
        else
            rows[i]:SetPoint("TOPLEFT", rows[i-1], "BOTTOMLEFT", 0, 1)
        end
        totalH = totalH + rowH + 1
    end
    if totalH > 0 then contentFrame:SetHeight(totalH) end
end

function minionManager.restackMinionRows(rows, contentFrame, rowH, colW, gap)
    local numCols = 2
    local totalH  = 0
    for i = 1, #rows do
        local col  = (i - 1) % numCols        -- 0 or 1
        local row  = mathFloor((i - 1) / numCols)
        local xOff = col * (colW + gap)
        local yOff = row * (rowH + 1)
        rows[i]:SetWidth(colW)
        if col == 0 then
            rows[i]:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xOff, yOff)
        else
            rows[i]:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xOff, yOff)
        end
        local rowBottom = yOff + rowH + 1
        if rowBottom > totalH then totalH = rowBottom end
    end
    if totalH > 0 then contentFrame:SetHeight(totalH) end
end

function minionManager.clearRows(rows, bin)
    for i = 1, #rows do
        rows[i]:SetVisible(false)
        tableInsert(bin, rows[i])
    end
    for i = #rows, 1, -1 do tableRemove(rows, i) end
end

function minionManager.drawProgressBar(barBg, barFill, progress)
    local COL_GREEN  = minionManager.COL_GREEN
    local COL_BLUE   = minionManager.COL_BLUE
    local COL_ORANGE = minionManager.COL_ORANGE
    minionManager.setCanvasRect(barBg, 0, 0, 0, 0.5, { r=0.25, g=0.25, b=0.25, a=0.8 }, 1)
    local p = mathMax(0.001, mathMin(progress, 1.0))
    local fillCol = (progress >= 1.0) and COL_GREEN or
                    (progress >= 0.5  and COL_BLUE  or COL_ORANGE)
    local fillPath = {
        { xProportional = 0, yProportional = 0 },
        { xProportional = p, yProportional = 0 },
        { xProportional = p, yProportional = 1 },
        { xProportional = 0, yProportional = 1 },
        { xProportional = 0, yProportional = 0 },
    }
    barFill:SetShape(fillPath,
        { type = "gradientLinear",
          transform = Utility.Matrix.Create(2, 1, 0, 0, 0),
          color = {
              { r = fillCol.r*0.6, g = fillCol.g*0.6, b = fillCol.b*0.6, a = 1, position = 0 },
              { r = fillCol.r,     g = fillCol.g,     b = fillCol.b,     a = 1, position = 1 },
          }
        }, nil)
end

function minionManager.updateSelectionState()
    local mm = minionManager
    if mm.dropAdvHint then
        if mm.selectedAdvId then
            mm.dropAdvHint:SetText(mm.allAdvData[mm.selectedAdvId] and mm.allAdvData[mm.selectedAdvId].name or "?")
            mm.dropAdvHint:SetFontColor(mm.COL_WHITE.r, mm.COL_WHITE.g, mm.COL_WHITE.b, 1)
        else
            mm.dropAdvHint:SetText(langTexts.minionManager.selectAdventure)
            mm.dropAdvHint:SetFontColor(mm.COL_DIM.r, mm.COL_DIM.g, mm.COL_DIM.b, 1)
        end
    end
    if mm.dropMinionHint then
        if mm.selectedMinionId then
            local mName = nil
            for i = 1, #mm.minionRows do
                if mm.minionRows[i]:GetMinionId() == mm.selectedMinionId then
                    mName = mm.minionRows[i]:GetMinionName()
                    break
                end
            end
            mm.dropMinionHint:SetText(mName or "?")
            mm.dropMinionHint:SetFontColor(mm.COL_WHITE.r, mm.COL_WHITE.g, mm.COL_WHITE.b, 1)
        else
            mm.dropMinionHint:SetText(langTexts.minionManager.selectMinion)
            mm.dropMinionHint:SetFontColor(mm.COL_DIM.r, mm.COL_DIM.g, mm.COL_DIM.b, 1)
        end
    end
    for i = 1, #mm.cardSlots do
        local slot = mm.cardSlots[i]
        if slot then slot:SetSelected(mm.selectedAdvId) end
    end
    for i = 1, #mm.minionRows do
        local row = mm.minionRows[i]
        row:SetHighlight(row:GetMinionId() == mm.selectedMinionId)
    end
end
