local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local lowerBar      = privateVars.lowerBar

---------- init local variables ---------

local inspectFactionList   = Inspect.Faction.List
local inspectFactionDetail = Inspect.Faction.Detail
local inspectTimeFrame     = Inspect.Time.Frame

local stringFormat         = string.format
local mathFloor            = math.floor

---------- local functions ---------

-- Creates and manages the faction reputation display
function lowerBar.faction()
    local notorietyLevels = {
        {label = "neutral", required = 0},
        {label = "friendly", required = 3000},
        {label = "decorated", required = 10000},
        {label = "honored", required = 20000},
        {label = "revered", required = 35000},
        {label = "glorified", required = 60000},
        {label = "venerated", required = 90000},
    }
    
    local list = inspectFactionList()
    local currentFaction
    
    local flag, detailList = pcall(inspectFactionDetail, list)
    if flag and detailList ~= nil then
        for key, details in pairs(detailList) do
            currentFaction = details.id
            break
        end
    end
    
    local datasetFactionBarBG = LibEKL.uiCreateFrame('nkFrame', "lowerBar.factionFrameBG", lowerBar.contextRestricted)
    datasetFactionBarBG:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMCENTER", data.aThird - 10, -9)
    datasetFactionBarBG:SetWidth(nkUISetup.modules.lowerBar.barWidth)
    datasetFactionBarBG:SetHeight(nkUISetup.modules.lowerBar.barHeight)
    datasetFactionBarBG:SetBackgroundColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, .25)
    
    local datasetFactionBar = LibEKL.uiCreateFrame('nkFrame', "lowerBar.factionFrame", datasetFactionBarBG)
    datasetFactionBar:SetPoint("TOPLEFT", datasetFactionBarBG, "TOPLEFT")
    datasetFactionBar:SetHeight(nkUISetup.modules.lowerBar.barHeight)
    datasetFactionBar:SetWidth(0)
    datasetFactionBar:SetBackgroundColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    
    local datasetFaction = LibEKL.uiCreateFrame('nkText', "lowerBar.faction", datasetFactionBarBG)
    datasetFaction:SetPoint("BOTTOMCENTER", datasetFactionBarBG, "TOPCENTER", 0, 0)
    datasetFaction:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetFaction:SetFontColor(data.colors.accent.r, data.colors.accent.g, data.colors.accent.b, data.colors.accent.a)
    datasetFaction:SetTextFont(addonInfo.id, "MontserratSemiBold")
    datasetFaction:SetEffectGlow({ strength = 1 })
    
    local datasetFactionName = LibEKL.uiCreateFrame('nkText', "lowerBar.factionName", datasetFactionBar)
    datasetFactionName:SetPoint("CENTER", datasetFactionBarBG, "CENTER")
    datasetFactionName:SetFontSize(nkUISetup.modules.lowerBar.barText)
    datasetFactionName:SetFontColor(0, 0, 0, 1)
    datasetFactionName:SetTextFont(addonInfo.id, "MontserratSemiBold")
    datasetFactionName:SetEffectGlow({ strength = 1, colorR = 1, colorG = 1, colorB = 1})

    local datasetFactionBarBGIcon = LibEKL.uiCreateFrame("nkTexture", "lowerBar.factionFrameBG.icon", datasetFactionBarBG)
    datasetFactionBarBGIcon:SetPoint("CENTERRIGHT", datasetFactionBarBG, "CENTERLEFT", -5, 0)
    datasetFactionBarBGIcon:SetHeight(16)
    datasetFactionBarBGIcon:SetWidth(16)
    datasetFactionBarBGIcon:SetTextureAsync("nkUI", "gfx/lowerbarFaction.png")
    
    function datasetFactionBarBG:Redraw()
        datasetFactionBarBG:SetWidth(nkUISetup.modules.lowerBar.barWidth)
        datasetFactionBarBG:SetHeight(nkUISetup.modules.lowerBar.barHeight)
        datasetFactionBar:SetHeight(nkUISetup.modules.lowerBar.barHeight)
        datasetFaction:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
        datasetFactionName:SetFontSize(nkUISetup.modules.lowerBar.barText)
    end
    
    local function updateFaction(_, factionData)
        if factionData ~= nil then
            for k, v in pairs(factionData) do
                currentFaction = k
                break
            end
        end
        
        if currentFaction == nil then return end
        
        local now = inspectTimeFrame()
        
        if not updateTime or now - updateTime > 1 then
            updateTime = now
            local percent = 0
            local level = ""
            
            local faction = inspectFactionDetail(currentFaction)
            
            if faction == nil then
                datasetFaction:SetText(stringFormat("%d%%", 0))
                datasetFactionName:SetText("")
            elseif faction.notoriety == nil then
                datasetFaction:SetText(stringFormat("%d%%", 0))
                datasetFactionName:SetText("")
            else
                for k, v in ipairs(notorietyLevels) do
                    if (faction.notoriety - 26000) <= v.required then
                        percent = 100 / v.required * (faction.notoriety - 26000)
                        level = v.label
                        break
                    end
                end

                if LibEKL.Tools.Math.IsNaN(percent) then percent = 0 end
                
                datasetFactionName:SetText(stringFormat("%s (%s)", faction.name, level))
                datasetFaction:SetText(stringFormat("%d%%", percent))
                datasetFactionBar:SetWidth(nkUISetup.modules.lowerBar.barWidth * (percent/100))
            end
        end
    end
    
    updateFaction()
    Command.Event.Attach(Event.Faction.Notoriety, updateFaction, "nkui.lowerBar.faction.Event.Faction.Notoriety")
    
    table.insert(uiElements.lowerBarModules, datasetFactionBarBG)
end