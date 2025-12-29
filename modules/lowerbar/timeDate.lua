local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local lowerBar    = privateVars.lowerBar

---------- init local variables ---------

local inspectTimeServer = Inspect.Time.Server
local stringFormat      = string.format
local osDate            = os.date

---------- local functions ---------

-- Creates and manages the time and date display
function lowerBar.timeDate()

    local datasetTime = LibEKL.UICreateFrame("nkText", "lowerBar.datasettime", lowerBar.contextRestricted)
    datasetTime:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMCENTER", 0, 0)
    datasetTime:SetText("00:00:00")
    datasetTime:SetFontSize(nkUISetup.modules.lowerBar.timeSize)
    datasetTime:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetTime:SetTextFont(addonInfo.id, "Montserrat")
    datasetTime:SetEffectGlow({ strength = 1, offsetX = 1, offsetY = 1, blurX=1, blurY = 1})
    datasetTime:SetLayer(10)
    
    function datasetTime:Redraw()
        datasetTime:SetFontSize(nkUISetup.modules.lowerBar.timeSize)
    end
    
    local datasetDate = LibEKL.UICreateFrame("nkText", "lowerBar.datasetdate", lowerBar.contextRestricted)
    datasetDate:SetPoint("BOTTOMCENTER", datasetTime, "TOPCENTER",0, 7)
    datasetDate:SetText("00/00/0000")
    datasetDate:SetFontSize(nkUISetup.modules.lowerBar.dateSize)
    datasetDate:SetFontColor(data.colors.accent.r, data.colors.accent.g, data.colors.accent.b, data.colors.accent.a)
    datasetDate:SetTextFont(addonInfo.id, "MontserratSemiBold")
    datasetDate:SetEffectGlow({ strength = 1 })
    datasetDate:SetLayer(10)
    
    function datasetDate:Redraw()
        datasetDate:SetFontSize(nkUISetup.modules.lowerBar.dateSize)
    end    
    
    local updateClockTime = inspectTimeServer()
    local updateDate
    
    local function updateClock()
        local now = inspectTimeServer()
        local deltaTime = now - updateClockTime
        
        if (updateDate == nil or deltaTime > 60) then
            local temp = osDate("*t", now)
            datasetTime:SetText(stringFormat("%02d:%02d", temp.hour, temp.min))
            updateClockTime = now
            
            if updateDate == nil then
                datasetDate:SetText(stringFormat("%02d/%02d/%02d", temp.day, temp.month, temp.year))
            end
        end
    end
    
    Command.Event.Attach(Event.System.Update.Begin, updateClock, "nkUI.lowerbar.time.System.Update.Begin")
    
    table.insert(uiElements.lowerBarModules, datasetTime)
    table.insert(uiElements.lowerBarModules, datasetDate)
    
end