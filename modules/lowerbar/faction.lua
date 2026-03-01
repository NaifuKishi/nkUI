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
            if details.name == "The Lycini" then
                currentFaction = details.id
                break
            end
        end
    end

    local name = "lowerBar.datasetfaction"
    local height = uiElements.lowerBarCanvas:GetHeight()

    local datasetFrame = LibEKL.UICreateFrame("nkFrame", name .. ".frame", lowerBar.contextRestricted)
    datasetFrame:SetHeight(height)
    datasetFrame:SetLayer(2)

    local datasetFactionBarBG = LibEKL.UICreateFrame('nkCanvas', name .. ".background", lowerBar.contextRestricted)
    datasetFactionBarBG:SetPoint("CENTERRIGHT", datasetFrame, "CENTERRIGHT",  0, 0)
    datasetFactionBarBG:SetWidth(nkUISetup.modules.lowerBar.barWidth)
    datasetFactionBarBG:SetHeight(nkUISetup.modules.lowerBar.barHeight)
    datasetFactionBarBG:SetLayer(10)

    datasetFactionBarBG:SetShape({  {xProportional = 0, yProportional = 0}, 
                            {xProportional = 1, yProportional = 0}, 
                            {xProportional = 1, yProportional = 1}, 
                            {xProportional = 0, yProportional = 1}, 
                            {xProportional = 0, yProportional = 0}}, 
                        { type = "solid", r = 0x36 / 255, g = 0x40 / 255, b = 0x52 / 255, a = 0.5}, 
                        { r = 0xA3 / 255, g = 0x66 / 255, b = 0xCC / 255, a = 0.3, thickness = 2 })
    
    local datasetFactionBar = LibEKL.UICreateFrame('nkFrame', "lowerBar.factionFrame", datasetFactionBarBG)
    datasetFactionBar:SetPoint("CENTERLEFT", datasetFactionBarBG, "CENTERLEFT", 1, 0)
    datasetFactionBar:SetHeight(nkUISetup.modules.lowerBar.barHeight - 2)
    datasetFactionBar:SetWidth(0)
    datasetFactionBar:SetBackgroundColor(0x33 / 255, 0xCC / 255, 0xCC / 255, 1)
    
    local datasetFactionName = LibEKL.UICreateFrame('nkText', "lowerBar.factionName", datasetFactionBar)
    datasetFactionName:SetPoint("CENTER", datasetFactionBarBG, "CENTER")
    datasetFactionName:SetFontSize(nkUISetup.modules.lowerBar.barText)
    datasetFactionName:SetFontColor(1, 1, 1, 1)
    datasetFactionName:SetTextFont(addonInfo.id, "MontserratMedium")
    datasetFactionName:SetEffectGlow({ strength = 3})

    local datasetFactionBarBGIcon = LibEKL.UICreateFrame("nkTexture", "lowerBar.factionFrameBG.icon", datasetFactionBarBG)
    datasetFactionBarBGIcon:SetPoint("CENTERRIGHT", datasetFactionBarBG, "CENTERLEFT", -21, 0)
    datasetFactionBarBGIcon:SetHeight(16)
    datasetFactionBarBGIcon:SetWidth(16)
    datasetFactionBarBGIcon:SetTextureAsync("nkUI", "gfx/lowerbarFaction.png")
    
    function datasetFrame:Redraw()
        datasetFactionBarBG:SetWidth(nkUISetup.modules.lowerBar.barWidth)
        datasetFactionBarBG:SetHeight(nkUISetup.modules.lowerBar.barHeight)
        datasetFactionBar:SetHeight(nkUISetup.modules.lowerBar.barHeight)
        --datasetFaction:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
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
                --datasetFaction:SetText(stringFormat("%d%%", 0))
                datasetFactionName:SetText("")
            elseif faction.notoriety == nil then
                --datasetFaction:SetText(stringFormat("%d%%", 0))
                datasetFactionName:SetText("")
            else
                local factionNeeded = 0
                local previousNeeded = 0
                local previousLabel = nil
                local currentNotoriety = faction.notoriety - 23000

                for k, v in ipairs(notorietyLevels) do
                    factionNeeded = factionNeeded + v.required
                    if factionNeeded > currentNotoriety then
                        local realValue = currentNotoriety - previousNeeded
                        percent = (realValue / v.required) * 100
                        level = previousLabel
                        break
                    end

                    previousLabel = v.label
                    previousNeeded = previousNeeded + v.required
                end

                if LibEKL.Tools.Math.IsNaN(percent) then percent = 0 end
                
                datasetFactionName:SetText(stringFormat("%s (%d%%) %s", faction.name, percent, level))
                --datasetFaction:SetText(stringFormat("%d%%", percent))
                datasetFactionBar:SetWidth(nkUISetup.modules.lowerBar.barWidth * (percent/100))
            end
        end
    end
    
    updateFaction()
    Command.Event.Attach(Event.Faction.Notoriety, updateFaction, "nkui.lowerBar.faction.Event.Faction.Notoriety")
    
    return datasetFrame

end