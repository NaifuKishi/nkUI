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

local EnKaiGetPlayerDetails = EnKai.unit.getPlayerDetails

---------- init local function ---------

local function tooltipUI()

    local tooltipWidth, tooltipHeight = 250, 100

    UI.Native.Tooltip:SetLayer(1)

    local tooltip = EnKai.uiCreateFrame("nkFrame", TOOLTIP_NAME .. ".tooltip", uiElements.contextTooltip)
    tooltip:SetLayer(99)
    tooltip:SetVisible(false)
    tooltip:SetWidth(tooltipWidth)
    tooltip:SetHeight(tooltipHeight)

    tooltip:SetBackgroundColor(0, 0, 0, 1)
    tooltip:SetPoint("BOTTOMRIGHT", UI.Native.TooltipAnchor, "BOTTOMRIGHT")

    local title = EnKai.uiCreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.title", tooltip)
    title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 2, 2)
    title:SetFontSize(16)
    title:SetAlpha(1)
    title:SetTextFont(addonInfo.id, "MontserratSemiBold")

    local lines = {}
    local stats = {}
    local lastObject, x = title, 2

    for idx = 1, 10, 1 do
        local line = EnKai.uiCreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.line" .. idx, tooltip)
        line:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT",x , -5)
        line:SetWordwrap(true)
        line:SetFontSize(14)
        line:SetTextFont(addonInfo.id, "Montserrat")        
       
        lastObject, x = line, 0
       
        table.insert (lines, line)
    end

    local y = 5

    for idx = 1, 10, 1 do
        local line = EnKai.uiCreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.stats" .. idx, tooltip)
        line:SetPoint("TOPLEFT", lastObject, "BOTTOMLEFT", 0 ,y)
        line:SetWordwrap(true)
        line:SetFontSize(12)
        line:SetTextFont(addonInfo.id, "FiraMono")
        
        lastObject, y = line, -5
       
        table.insert (stats, line)
    end

    healthBarBG = EnKai.uiCreateFrame("nkFrame", TOOLTIP_NAME .. ".tooltip.healthBarBG", tooltip)
    healthBarBG:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT", 0, 2)
    healthBarBG:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 0, 12)
    healthBarBG:SetVisible(false)

    healthBar = EnKai.uiCreateFrame("nkCanvas", TOOLTIP_NAME .. ".tooltip.healthBar", healthBarBG)
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

    healthText = EnKai.uiCreateFrame("nkText", TOOLTIP_NAME .. ".tooltip.healthText", healthBar)
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

    local playerDetail = EnKaiGetPlayerDetails()

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


--[[
function _tooltip.item(iteminfo)

    local itemDetail = Inspect.Item.Detail(iteminfo)
    local playerDetail = EnKaiGetPlayerDetails()

    local infoLines = {}

    -- Item Name
    local color = "#FFFFFF" -- Default color
    if itemDetail.rarity then
        local qualityColors = {
            poor = "#9D9D9D",
            common = "#FFFFFF",
            uncommon = "#1EFF00",
            rare = "#0070FF",
            epic = "#A335EE",
            legendary = "#FF8000",
            artifact = "#E6CC80"
        }
        color = qualityColors[itemDetail.rarity] or "#FFFFFF"
    end
    
    if (itemDetail.stack) then        
        uiElements.tooltip:SetTitle(stringFormat('<font color="%s">%s (%d)</font>', color, itemDetail.name, itemDetail.stack))
    else
        uiElements.tooltip:SetTitle(stringFormat('<font color="%s">%s</font>', color, itemDetail.name))
    end

    if (itemDetail.category) then
         table.insert(infoLines, EnKai.strings.Capitalize(itemDetail.category))         
    end

    table.insert(infoLines, " ")

    local bound = ""

    if itemDetail.bind then
        if itemDetail.bind == "equip" then
            bound = "Bind on equip"
        elseif itemDetail.bind == "pickup" then
            bound = "Bind on pickup"
        end
    end

    if itemDetail.bound then
        table.insert(infoLines, stringFormat("%s (Bound)", bound))
    else
        table.insert(infoLines, bound)
    end
    
    if itemDetail.requiredCalling then
        local callings = EnKai.strings.split(itemDetail.requiredCalling, " ")
        for idx = 1, #callings, 1 do
            local tmpCalling = EnKai.strings.Capitalize(callings[idx])
            if callings[idx] == playerDetail.calling then
                callings[idx] = stringFormat("<font color='#00FF00'>%s</font>", tmpCalling)
            else
                callings[idx] = tmpCalling
            end
        end
        table.insert(infoLines, stringFormat("Required Calling: %s",table.concat(callings, " ")))
    end

    -- Item Sell Price
    if itemDetail.sell then
        local platin = mathFloor(itemDetail.sell / 10000)
        local gold = mathFloor((itemDetail.sell - (platin * 10000)) / 100)
        local silver = itemDetail.sell - (platin * 10000) - (gold * 100) 

        local sellPrice = nil
        if platin > 0 then sellPrice = stringFormat('<font color="#efebff">%dp</font>', platin) end
        if gold > 0 then 
            if sellPrice then sellPrice = sellPrice .. " " else sellPrice = "" end
            sellPrice = sellPrice .. stringFormat('<font color="#eed234">%dg</font>', gold)
        end
        if sellPrice then sellPrice = sellPrice .. " " else sellPrice = "" end
        sellPrice = sellPrice .. stringFormat('<font color="#a7aba7">%ds</font>', silver)
        
        table.insert(infoLines, " ")
        table.insert(infoLines, stringFormat('Sell Price: %s', sellPrice))
    end

     local statLines = {}

    if itemDetail.stats then
        -- Find the longest stat name to determine the maximum width needed
        local maxNameLength = 0
        for k, _ in pairs(itemDetail.stats) do
            local nameLength = string.len(EnKai.strings.Capitalize(k))
            if nameLength > maxNameLength then
                maxNameLength = nameLength
            end
        end

        -- Add each stat with proper spacing
        for k, v in pairs(itemDetail.stats) do
            local statName = EnKai.strings.Capitalize(k)
            -- Calculate the number of spaces needed to align values
            local spaces = string.rep(" ", maxNameLength - string.len(statName) + 2)
            table.insert(statLines, stringFormat('%s%s%s', statName, spaces, v))
        end
    end

    uiElements.tooltip:SetBody(infoLines)
    uiElements.tooltip:SetStats(statLines, true)
    uiElements.tooltip:SetHealth(nil, nil, false)
end

function _tooltip.ability(abilityInfo)

    local abilityDetail = Inspect.Ability.New.Detail(abilityInfo)
    
    if abilityDetail == nil then return end
    
    local playerDetail = EnKaiGetPlayerDetails()

    local infoLines = {}
    local statLines = {}

    -- Ability Name
    local color = "#FFFFFF" -- Default color
    if abilityDetail.rarity then
        local qualityColors = {
            poor = "#9D9D9D",
            common = "#FFFFFF",
            uncommon = "#1EFF00",
            rare = "#0070FF",
            epic = "#A335EE",
            legendary = "#FF8000",
            artifact = "#E6CC80"
        }
        color = qualityColors[abilityDetail.rarity] or "#FFFFFF"
    end

    uiElements.tooltip:SetTitle(stringFormat('<font color="%s">%s</font>', color, abilityDetail.name))

    -- Ability Flags
    if abilityDetail.autoattack then
        table.insert(infoLines, "Autoattack")
    end

    if abilityDetail.channeled then
        table.insert(infoLines, "Channeled")
    end

    if abilityDetail.continuous then
        table.insert(infoLines, "Continuous")
    end

    if abilityDetail.passive then
        table.insert(infoLines, "Passive")
    end

    if abilityDetail.positioned then
        table.insert(infoLines, "Positioned")
    end

    if abilityDetail.racial then
        table.insert(infoLines, "Racial")
    end

    if abilityDetail.stealthRequired then
        table.insert(infoLines, "Requires Stealth")
    end


    -- Ability Description
    if abilityDetail.description then
        table.insert(statLines, abilityDetail.description)
    end

    -- Ability Casting Time
    if abilityDetail.castingTime then
        table.insert(infoLines, stringFormat('Casting Time: %d sec', abilityDetail.castingTime))
    end

    -- Ability Cooldown
    if abilityDetail.cooldown then
        local minutes = mathFloor(abilityDetail.cooldown / 60)
        local seconds = mathFloor(abilityDetail.cooldown % 60)
        local cooldownText = ""

        if minutes > 0 then
            cooldownText = stringFormat('%d min', minutes)
            if seconds > 0 then
                cooldownText = cooldownText .. stringFormat(' %d sec', seconds)
            end
        elseif seconds > 0 then
            cooldownText = stringFormat('%d sec', seconds)
        end

        if cooldownText ~= "" then
            table.insert(infoLines, stringFormat('Cooldown: %s', cooldownText))
        end
    end

    -- Ability Costs
    if abilityDetail.costMana then
        table.insert(infoLines, stringFormat('Mana Cost: %d', abilityDetail.costMana))
    end

    if abilityDetail.costEnergy then
        table.insert(infoLines, stringFormat('Energy Cost: %d', abilityDetail.costEnergy))
    end

    if abilityDetail.costPower then
        table.insert(infoLines, stringFormat('Power Cost: %d', abilityDetail.costPower))
    end

    if abilityDetail.costCharge then
        table.insert(infoLines, stringFormat('Charge Cost: %d', abilityDetail.costCharge))
    end

    if abilityDetail.costPlanarCharge then
        table.insert(infoLines, stringFormat('Planar Charge Cost: %d', abilityDetail.costPlanarCharge))
    end

    -- Ability Range
    if abilityDetail.rangeMin and abilityDetail.rangeMax then
        table.insert(infoLines, stringFormat('Range: %d-%d meters', abilityDetail.rangeMin, abilityDetail.rangeMax))
    elseif abilityDetail.rangeMin then
        table.insert(infoLines, stringFormat('Range: %d meters (minimum)', abilityDetail.rangeMin))
    elseif abilityDetail.rangeMax then
        table.insert(infoLines, stringFormat('Range: %d meters (maximum)', abilityDetail.rangeMax))
    end

    
    if abilityDetail.weapon then
        table.insert(infoLines, stringFormat('Weapon: %s', EnKai.strings.Capitalize(abilityDetail.weapon)))
    end

    -- Ability Stats
    if abilityDetail.stats then
        -- Find the longest stat name to determine the maximum width needed
        local maxNameLength = 0
        for k, _ in pairs(abilityDetail.stats) do
            local nameLength = string.len(EnKai.strings.Capitalize(k))
            if nameLength > maxNameLength then
                maxNameLength = nameLength
            end
        end

        -- Add each stat with proper spacing
        for k, v in pairs(abilityDetail.stats) do
            local statName = EnKai.strings.Capitalize(k)
            -- Calculate the number of spaces needed to align values
            local spaces = string.rep(" ", maxNameLength - string.len(statName) + 2)
            table.insert(statLines, stringFormat('%s%s%s', statName, spaces, v))
        end
    end

    uiElements.tooltip:SetBody(infoLines)
    uiElements.tooltip:SetStats(statLines, false)
    uiElements.tooltip:SetHealth(nil, nil, false)
end
]]
