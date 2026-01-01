local addonInfo, privateVars = ...

---------- init namespace ---------

local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc

---------- init local variables ---------

local TOOLTIP_NAME = "nkUI.tooltip"

local InspectUnitDetail   = Inspect.Unit.Detail

local mathFloor    = math.floor
local mathpi       = math.pi

local stringFormat  = string.format
local stringSub     = string.sub
local stringUpper   = string.upper

local LibEKLGetPlayerDetails = LibEKL.Unit.getPlayerDetails

---------- init local function ---------

local function tooltipUI()

    local tooltipWidth, tooltipHeight = 250, 100

    UI.Native.Tooltip:SetLayer(1)

    local tooltip = LibEKL.UICreateFrame("nkFrame", TOOLTIP_NAME .. ".tooltip", uiElements.contextTooltip)
    tooltip:SetLayer(99)
    tooltip:SetVisible(false)
    tooltip:SetWidth(tooltipWidth)
    tooltip:SetHeight(tooltipHeight)

    tooltip:SetBackgroundColor(0, 0, 0, 1)
    tooltip:SetPoint("BOTTOMRIGHT", UI.Native.TooltipAnchor, "BOTTOMRIGHT")

    local title = LibEKL.UICreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.title", tooltip)
    title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 2, 2)
    title:SetFontSize(16)
    title:SetAlpha(1)
    title:SetTextFont(addonInfo.id, "MontserratSemiBold")

    local lines = {}
    local stats = {}
    local lastObject, x = title, 2

    for idx = 1, 10, 1 do
        local line = LibEKL.UICreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.line" .. idx, tooltip)
        line:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT",x , -5)
        line:SetWordwrap(true)
        line:SetFontSize(14)
        line:SetTextFont(addonInfo.id, "Montserrat")        
       
        lastObject, x = line, 0
       
        table.insert (lines, line)
    end

    local y = 5

    for idx = 1, 10, 1 do
        local line = LibEKL.UICreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.stats" .. idx, tooltip)
        line:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0 ,y)
        line:SetWordwrap(true)
        line:SetFontSize(12)
        line:SetTextFont(addonInfo.id, "FiraMono")
        
        lastObject, y = line, -5
       
        table.insert (stats, line)
    end

    healthBarBG = LibEKL.UICreateFrame("nkFrame", TOOLTIP_NAME .. ".tooltip.healthBarBG", tooltip)
    healthBarBG:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT", 0, 2)
    healthBarBG:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 0, 12)
    healthBarBG:SetVisible(false)

    healthBar = LibEKL.UICreateFrame("nkCanvas", TOOLTIP_NAME .. ".tooltip.healthBar", healthBarBG)
    healthBar:SetPoint("TOPLEFT", healthBarBG, "TOPLEFT", 1, 1)
    healthBar:SetHeight(8)
    
    local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1 }
    local path = {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }
    local fill = {  type = "gradientLinear", 
                    transform = Utility.Matrix.Create(2, 2, (mathpi / 2), 0, 0), 
                    color = {   { r = 0, g = .7, b = .0, a = 1, position = 0},  
                                { r =.5, g = .5, b = .5, a = 1, position = .2 },  
                                { r = 0.5, g = .5, b = .5, a = 1, position = 1 }
                            }
                }

    healthBar:SetShape (path, fill, stroke)

    healthText = LibEKL.UICreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.healthText", healthBar)
    healthText:SetPoint("CENTER", healthBarBG, "CENTER", 0, 0)
    healthText:SetFontSize(14)
    healthText:SetFontColor(1,1,1,1)
    healthText:SetTextFont(addonInfo.id, "MontserratSemiBold")

    function _reDraw()        
        local width = title:GetWidth() + 6

        if width > 300 then
            title:SetWidth(tooltipWidth)
            title:SetWordwrap(true)
            width = tooltipWidth
        else
            title:SetWordwrap(false)
        end

        local height = title:GetHeight() + 6

        for idx = 1, 10, 1 do
            if lines[idx]:GetVisible() then
                if lines[idx]:GetWidth() > tooltipWidth then
                    lines[idx]:SetWidth(tooltipWidth)
                end

                height = height + lines[idx]:GetHeight() -5
                if lines[idx]:GetWidth() > width then width = lines[idx]:GetWidth() + 6 end
            end
        end

        for idx = 1, 10, 1 do
            
            if stats[idx]:GetVisible() then
                 if stats[idx]:GetWidth() > tooltipWidth then
                    stats[idx]:SetWidth(tooltipWidth)
                end

                height = height + stats[idx]:GetHeight()
                if stats[idx]:GetWidth() > width then width = stats[idx]:GetWidth() + 6 end
            end
        end

        
        tooltipHeight = UI.Native.Tooltip:GetHeight()
        tooltipWidth = UI.Native.Tooltip:GetWidth()
        
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
                lines[idx]:SetText(newBody[idx], true)
                lines[idx]:ClearWidth()
                lines[idx]:ClearHeight()
                lines[idx]:SetVisible(true)
                lastLine = lines[idx]
            else
                lines[idx]:SetVisible(false)
            end
        end

        stats[1]:SetPoint("TOPLEFT", lastLine, "BOTTOMLEFT", 0 ,5)

        _reDraw()
    end

    function tooltip:SetStats(newStats, mono)
        for idx = 1, 10, 1 do
            if #newStats >= idx then
                stats[idx]:SetText(newStats[idx], true)
                stats[idx]:ClearWidth()
                stats[idx]:ClearHeight()

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

        _reDraw()
    end

    function tooltip:SetHealth(health, healthMax, show)
        if show then
            if health == 0 then 
                show = false 
            else
                local healthPercent = health / healthMax
                healthBar:SetWidth(healthPercent * healthBarBG:GetWidth() -2)
                healthText:SetText(stringFormat("%d", mathFloor(healthPercent * 100)))
            end
        end

        healthBarBG:SetVisible(show)
    end

    return tooltip

end

local function tooltipUnit (unitInfo)

    local unitDetail = InspectUnitDetail(unitInfo)

    if unitDetail == nil then return end

    local infoLines = {}
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

    local callingColor = { rift = { rogue = "#FFFFFF",
                                    warrior = "#FFFFFF",
                                    cleric = "#FFFFFF",
                                    primalist = "#FFFFFF",
                                    mage = "#FFFFFF"},
                            wow = { rogue = "#FFF569",
                                    warrior = "#C79C6E",
                                    cleric = "#FFFFFF",
                                    primalist = "#0070DE",
                                    mage = "#69CCF0"}
    }    
    
    local color = "#FFFFFF"
    if unitDetail.relation then
        color = relationColors[unitDetail.relation] or "#FFFFFF"
    end

    uiElements.tooltip:SetTitle(stringFormat('<font color="%s">%s</font>', color, unitDetail.name))

    if unitDetail.nameSecondary then
        table.insert(infoLines, stringFormat('<font color="%s">%s</font>', color, unitDetail.nameSecondary))
    end

    local playerDetail = LibEKLGetPlayerDetails()

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
                colro = levelColor.same
            else
                color = levelColor.trivial
            end

            levelLine = stringFormat('<font color="%s">Level %d</font>', color, level)
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
        local firstChar = stringSub(unitDetail.calling, 1, 1)
        local restOfString = stringSub(unitDetail.calling, 2)

        local callingColors = callingColor[nkUISetup.modules.unitFrames.colorScheme]

        table.insert(infoLines, stringFormat('<font color="%s">%s%s</font>', callingColors[unitDetail.calling], stringUpper(firstChar), restOfString))
    end

    if unitDetail.locationName then
        table.insert(infoLines, unitDetail.locationName)
    end

    if unitDetail.publicSize then
        table.insert(infoLines, stringFormat('Public group size: %d', unitDetail.publicSize) )
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

local function tooltipEvent (_, tooltipType, tooltipInfo)

    if nkUISetup.modules.tooltip.activate == false then return end

    if (tooltipType == nil) then
        uiElements.tooltip:SetVisible(false)
        return
    end

    if (tooltipType == "unit") then
        tooltipUnit(tooltipInfo)
        uiElements.tooltip:SetVisible(true)
    end

end

function internalFunc.tooltip()

    if uiElements.tooltip ~= nil then return end

    uiElements.tooltip = tooltipUI()

    Command.Event.Attach(Event.Tooltip, tooltipEvent, "nkUI.Event.tooltip")

end