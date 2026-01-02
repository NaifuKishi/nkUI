--[[ 
    Tooltip Module for nkUI
    
    This module handles the creation and management of custom tooltips in the nkUI addon.
    It provides enhanced tooltip functionality with custom styling and information display.
    
    @module tooltip
    @version 1.0
]]

local addonInfo, privateVars = ...

--[[ Constants ]]--
local TOOLTIP_NAME = "nkUI.tooltip"

--[[ Local Variables ]]--
local uiElements = privateVars.uiElements
local internalFunc = privateVars.internalFunc

local relationColors = {
    friendly = "#40BC40",
    hostile = "#C41F3B",
}

local levelColor = {
    hard = "#C41F3B",
    manageable = "#FF7D0A",
    same = "#40BC40",
    trivial = "#9D9D9D",
}

local callingColor = {
    rift = {
        rogue = "#FFFFFF",
        warrior = "#FFFFFF",
        cleric = "#FFFFFF",
        primalist = "#FFFFFF",
        mage = "#FFFFFF"
    },
    wow = {
        rogue = "#FFF569",
        warrior = "#C79C6E",
        cleric = "#FFFFFF",
        primalist = "#0070DE",
        mage = "#69CCF0"
    }
}

local TOOLTIP_MAXWIDTH = 250
local TOOLTIP_INNERBORDER = 6 -- actually 3 but left and right

--[[ Local Functions ]]--
local function createTooltipFrame(width, height)
    local tooltip = LibEKL.UICreateFrame("nkFrame", TOOLTIP_NAME .. ".tooltip", uiElements.contextTooltip)
    tooltip:SetLayer(99)
    tooltip:SetVisible(false)
    tooltip:SetWidth(width)
    tooltip:SetHeight(height)
    tooltip:SetBackgroundColor(0, 0, 0, 1)
    tooltip:SetPoint("BOTTOMRIGHT", UI.Native.TooltipAnchor, "BOTTOMRIGHT")
    
    return tooltip
end

local function createTitleText(tooltip)
    local title = LibEKL.UICreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.title", tooltip)
    title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", TOOLTIP_INNERBORDER / 2,  TOOLTIP_INNERBORDER / 2)
    title:SetFontSize(nkUISetup.modules.tooltip.fontSizes.header)
    title:SetAlpha(1)
    title:SetTextFont(addonInfo.id, "MontserratSemiBold")
    title:SetWordwrap(true)

    return title
end

local function createBodyLines(tooltip, title, count)
    local lines = {}
    local lastObject, x, y = title, 0, 0
    
    for idx = 1, count, 1 do
        local line = LibEKL.UICreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.line" .. idx, tooltip)
        line:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", x, y)
        line:SetWordwrap(true)
        line:SetFontSize(nkUISetup.modules.tooltip.fontSizes.body)
        line:SetTextFont(addonInfo.id, "Montserrat")
        
        lastObject, x, y = line, 0, -5
        table.insert(lines, line)
    end
    
    return lines
end

local function createStatsLines(tooltip, lastObject, count, y)
    local stats = {}
    
    for idx = 1, count, 1 do
        local line = LibEKL.UICreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.stats" .. idx, tooltip)
        line:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0, y)
        line:SetWordwrap(true)
        line:SetFontSize(nkUISetup.modules.tooltip.fontSizes.body - 2)
        line:SetTextFont(addonInfo.id, "FiraMono")
        
        lastObject, y = line, -5
        table.insert(stats, line)
    end
    
    return stats
end

local function createHealthBar(tooltip)
    local healthBarBG = LibEKL.UICreateFrame("nkFrame", TOOLTIP_NAME .. ".tooltip.healthBarBG", tooltip)
    healthBarBG:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT", 0, 2)
    healthBarBG:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 0, 12)
    healthBarBG:SetVisible(false)
    
    local healthBar = LibEKL.UICreateFrame("nkCanvas", TOOLTIP_NAME .. ".tooltip.healthBar", healthBarBG)
    healthBar:SetPoint("TOPLEFT", healthBarBG, "TOPLEFT", 1, 1)
    healthBar:SetHeight(8)
    
    local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1}
    local path = {
        {xProportional = 0, yProportional = 0},
        {xProportional = 1, yProportional = 0},
        {xProportional = 1, yProportional = 1},
        {xProportional = 0, yProportional = 1},
        {xProportional = 0, yProportional = 0}
    }
    local fill = {
        type = "gradientLinear",
        transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0),
        color = {
            {r = 0, g = .7, b = .0, a = 1, position = 0},
            {r = .5, g = .5, b = .5, a = 1, position = .2},
            {r = 0.5, g = .5, b = .5, a = 1, position = 1}
        }
    }
    
    healthBar:SetShape(path, fill, stroke)
    
    local healthText = LibEKL.UICreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.healthText", healthBar)
    healthText:SetPoint("CENTER", healthBarBG, "CENTER", 0, 0)
    healthText:SetFontSize(14)
    healthText:SetFontColor(1, 1, 1, 1)
    healthText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    
    return healthBarBG, healthBar, healthText
end

local function calculateTooltipDimensions(tooltip, title, lines, stats)
    
    local tooltipWidth = title:GetWidth() + TOOLTIP_INNERBORDER

    --print (1, tooltipWidth)
    
    if tooltipWidth > TOOLTIP_MAXWIDTH then
        title:SetWidth(TOOLTIP_MAXWIDTH - TOOLTIP_INNERBORDER)
        tooltipWidth = TOOLTIP_MAXWIDTH
    end

    --print (2, tooltipWidth)
    
    local height = title:GetHeight() + TOOLTIP_INNERBORDER
    
    for idx = 1, #lines, 1 do
        if lines[idx]:GetVisible() then
            local lineWidth = lines[idx]:GetWidth()

            if lineWidth > TOOLTIP_MAXWIDTH then
                lines[idx]:SetWidth(TOOLTIP_MAXWIDTH - TOOLTIP_INNERBORDER)
                tooltipWidth = TOOLTIP_MAXWIDTH
            elseif (lineWidth + TOOLTIP_INNERBORDER) > tooltipWidth then 
                tooltipWidth = lineWidth + TOOLTIP_INNERBORDER 
            end
            
            height = height + lines[idx]:GetHeight() - 5            
        end
    end

    --print (3, tooltipWidth)
    
    for idx = 1, #stats, 1 do
        if stats[idx]:GetVisible() then
            local lineWidth = stats[idx]:GetWidth()

            if lineWidth > TOOLTIP_MAXWIDTH then
                stats[idx]:SetWidth(TOOLTIP_MAXWIDTH - TOOLTIP_INNERBORDER)
                tooltipWidth = TOOLTIP_MAXWIDTH
            elseif (lineWidth + TOOLTIP_INNERBORDER) > tooltipWidth then 
                tooltipWidth = lineWidth + TOOLTIP_INNERBORDER 
            end
            
            height = height + stats[idx]:GetHeight()
        end
    end
    
    --print (4, tooltipWidth)
    
    return tooltipWidth, height
end

local function updateTooltipDimensions(tooltip, width, height)
    
    local tooltipHeight = UI.Native.Tooltip:GetHeight()
    local tooltipWidth = UI.Native.Tooltip:GetWidth()
    
    if height > tooltipHeight then
        tooltip:SetHeight(height)
    else
        tooltip:SetHeight(tooltipHeight)
    end
    
    if width > tooltipWidth then
        tooltip:SetWidth(width)
    else
        tooltip:SetWidth(tooltipWidth)
    end
end

local function createTooltipUI()

    local tooltipWidth, tooltipHeight = 250, 100
    
    UI.Native.Tooltip:SetLayer(1)
    
    local tooltip = createTooltipFrame(tooltipWidth, tooltipHeight)
    local title = createTitleText(tooltip)
    local lines = createBodyLines(tooltip, title, 10)
    local stats = createStatsLines(tooltip, lines[#lines], 10, 5)
    local healthBarBG, healthBar, healthText = createHealthBar(tooltip)
    
    local function redraw()
        local width, height = calculateTooltipDimensions(tooltip, title, lines, stats)
        updateTooltipDimensions(tooltip, width, height)
    end
    
    function tooltip:SetTooltipSize(newWidth, newHeight)
        tooltipWidth = newWidth + 6
        tooltipHeight = newHeight + 6
    end
    
    function tooltip:SetTitle(newTitle)
        title:SetText(newTitle, true)
        title:ClearWidth()
    end
    
    function tooltip:SetBody(newBody)
        local lastLine = title
        
        for idx = 1, 10, 1 do
            if #newBody >= idx then
                lines[idx]:ClearWidth()
                lines[idx]:ClearHeight()
                lines[idx]:SetText(newBody[idx], true)                
                lines[idx]:SetVisible(true)
                lastLine = lines[idx]
            else
                lines[idx]:SetVisible(false)
            end
        end
        
        stats[1]:SetPoint("TOPLEFT", lastLine, "BOTTOMLEFT", 0, 5)
        redraw()
    end
    
    function tooltip:SetStats(newStats, mono)
        for idx = 1, 10, 1 do
            if #newStats >= idx then
                stats[idx]:ClearWidth()
                stats[idx]:ClearHeight()
                stats[idx]:SetText(newStats[idx], true)
                
                if mono then
                    stats[idx]:SetTextFont(addonInfo.id, "FiraMono")
                else
                    stats[idx]:SetTextFont(addonInfo.id, "Montserrat")
                end
                
                stats[idx]:SetVisible(true)
            else
                stats[idx]:SetVisible(false)
            end
        end
        
        redraw()
    end
    
    function tooltip:SetHealth(health, healthMax, show)
        if show then
            if health == 0 then
                show = false
            else
                local healthPercent = health / healthMax
                healthBar:SetWidth(healthPercent * healthBarBG:GetWidth() - 2)
                healthText:SetText(string.format("%d", math.floor(healthPercent * 100)))
            end
        end
        
        healthBarBG:SetVisible(show)
    end
    
    return tooltip
end

local function formatUnitTooltip(unitInfo)
    local unitDetail = Inspect.Unit.Detail(unitInfo)
    
    if unitDetail == nil then return end
    
    local infoLines = {}
    
    local color = "#FFFFFF"
    if unitDetail.relation then
        color = relationColors[unitDetail.relation] or "#FFFFFF"
    end
    
    uiElements.tooltip:SetTitle(string.format('<font color="%s">%s</font>', color, unitDetail.name))
    
    if unitDetail.nameSecondary then
        table.insert(infoLines, string.format('<font color="%s">%s</font>', color, unitDetail.nameSecondary))
    end
    
    local playerDetail = LibEKL.Unit.getPlayerDetails()
    
    if unitDetail.guild then
        table.insert(infoLines, unitDetail.guild)
    end
    
    if unitDetail.level then
        local levelLine
        local level = unitDetail.level
        
        if type(level) == "string" and level == "??" then
            levelLine = '<font color="#C41F3B">Level ??</font>'
        else
            local diff = tonumber(level) - playerDetail.level
            
            if diff > 10 then
                color = levelColor.hard
            elseif diff > 5 then
                color = levelColor.manageable
            elseif diff <= 5 and diff >= -5 then
                color = levelColor.same
            else
                color = levelColor.trivial
            end
            
            levelLine = string.format('<font color="%s">Level %d</font>', color, level)
        end
        
        if unitDetail.tagName then
            levelLine = levelLine .. " " .. unitDetail.tagName
        end
        
        if unitDetail.raceName then
            levelLine = levelLine .. " " .. unitDetail.raceName
        end
        
        table.insert(infoLines, levelLine)
    end
    
    if unitDetail.calling then
        local firstChar = string.sub(unitDetail.calling, 1, 1)
        local restOfString = string.sub(unitDetail.calling, 2)
        
        local callingColors = callingColor[nkUISetup.modules.unitFrames.colorScheme]
        
        table.insert(infoLines, string.format('<font color="%s">%s%s</font>', callingColors[unitDetail.calling], string.upper(firstChar), restOfString))
    end
    
    if unitDetail.locationName then
        table.insert(infoLines, unitDetail.locationName)
    end
    
    if unitDetail.publicSize then
        table.insert(infoLines, string.format('Public group size: %d', unitDetail.publicSize))
    end
    
    uiElements.tooltip:SetBody(infoLines)
    uiElements.tooltip:SetStats({}, false)
    
    if unitDetail.health then
        local healthMax = unitDetail.healthMax or unitDetail.health
        uiElements.tooltip:SetHealth(unitDetail.health, healthMax, true)
    else
        uiElements.tooltip:SetHealth(nil, nil, false)
    end
end

local function handleTooltipEvent(_, tooltipType, tooltipInfo)
    if nkUISetup.modules.tooltip.activate == false then return end
    
    if tooltipType == nil then
        uiElements.tooltip:SetVisible(false)
        return
    end
    
    if tooltipType == "unit" then
        formatUnitTooltip(tooltipInfo)
        uiElements.tooltip:SetVisible(true)
    end
end

function internalFunc.tooltip()
    if uiElements.tooltip ~= nil then return end
    
    uiElements.tooltip = createTooltipUI()
    
    Command.Event.Attach(Event.Tooltip, handleTooltipEvent, "nkUI.Event.tooltip")
end
