local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local lowerBar      = privateVars.lowerBar
local internalFunc  = privateVars.internalFunc

---------- init local variables ---------

local inspectExperience = Inspect.Experience

local stringFormat      = string.format

---------- local functions ---------

-- Creates and manages the experience bar display
function lowerBar.experience()
    local datasetExpBarBG = LibEKL.UICreateFrame('nkFrame', "lowerBar.experienceFrameBG", lowerBar.contextRestricted)
    datasetExpBarBG:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMCENTER", -data.aFourth + 10, -9)
    datasetExpBarBG:SetWidth(nkUISetup.modules.lowerBar.barWidth)
    datasetExpBarBG:SetHeight(nkUISetup.modules.lowerBar.barHeight)
    datasetExpBarBG:SetBackgroundColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, .25)
    datasetExpBarBG:SetLayer(10)
    
    local datasetExpBar = LibEKL.UICreateFrame('nkFrame', "lowerBar.experienceFrame", datasetExpBarBG)
    datasetExpBar:SetPoint("TOPLEFT", datasetExpBarBG, "TOPLEFT")
    datasetExpBar:SetHeight(nkUISetup.modules.lowerBar.barHeight)
    datasetExpBar:SetWidth(0)
    datasetExpBar:SetLayer(1)
    datasetExpBar:SetBackgroundColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    
    local datasetExp = LibEKL.UICreateFrame('nkText', "lowerBar.experience", lowerBar.contextRestricted)
    datasetExp:SetPoint("BOTTOMCENTER", datasetExpBarBG, "TOPCENTER", 0, 0)
    datasetExp:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetExp:SetFontColor(data.colors.accent.r, data.colors.accent.g, data.colors.accent.b, data.colors.accent.a)
    datasetExp:SetTextFont(addonInfo.id, "MontserratSemiBold")
    datasetExp:SetEffectGlow({ strength = 1})
    datasetExp:SetLayer(10)

    local datasetExpLabel = LibEKL.UICreateFrame('nkText', "lowerBar.experienceLabel", datasetExpBarBG)
    datasetExpLabel:SetPoint("CENTER", datasetExpBarBG, "CENTER")
    datasetExpLabel:SetFontSize(nkUISetup.modules.lowerBar.barText)
    datasetExpLabel:SetFontColor(0, 0, 0, 1)
    datasetExpLabel:SetTextFont(addonInfo.id, "MontserratSemiBold")
    datasetExpLabel:SetLayer(2)
    datasetExpLabel:SetEffectGlow({ strength = 1, colorR = 1, colorG = 1, colorB = 1})

    local datasetExpBarBGIcon = LibEKL.UICreateFrame("nkTexture", "lowerBar.experienceFrameBG.icon", datasetExpBarBG)
    datasetExpBarBGIcon:SetPoint("CENTERRIGHT", datasetExpBarBG, "CENTERLEFT", -5, 0)
    datasetExpBarBGIcon:SetHeight(16)
    datasetExpBarBGIcon:SetWidth(16)
    datasetExpBarBGIcon:SetTextureAsync("nkUI", "gfx/lowerbarExperience.png")
    
    datasetExpBarBG:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
        internalFunc.questLogInit(true)
    end, datasetExpBarBG:GetName() .. ".Left.Down")  

    function datasetExpBarBG:Redraw()
        datasetExpBarBG:SetWidth(nkUISetup.modules.lowerBar.barWidth)
        datasetExpBarBG:SetHeight(nkUISetup.modules.lowerBar.barHeight)
        datasetExpBar:SetHeight(nkUISetup.modules.lowerBar.barHeight)
    end
    
    function datasetExp:Redraw()
        datasetExp:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    end
    
    local function updateExperience(experience)
        local percent = 0
        
        if experience == nil then experience = inspectExperience() end
        
        if experience == nil then
            datasetExp:SetText(stringFormat("%d%%", 0))
        elseif experience.accumulated == nil then
            datasetExp:SetText(stringFormat("%d%%", 0))
        else
            percent = 100 / experience.needed * experience.accumulated
            datasetExp:SetText(stringFormat("%d%%", percent))
        end
        
        datasetExpBar:SetWidth(nkUISetup.modules.lowerBar.barWidth * (percent/100))
        datasetExpLabel:SetText(stringFormat("Level %d", LibEKL.Unit.GetPlayerDetails().level))

    end
    
    Command.Event.Attach(Event.TEMPORARY.Experience, function(_, accumulated, rested, needed)        
        updateExperience({accumulated = accumulated, needed = needed, rested = rested})
    end, "nkui.lowerBar.exp.TEMPORARY.Experience")
    
    updateExperience()
    
    table.insert(uiElements.lowerBarModules, datasetExpBarBG)
    table.insert(uiElements.lowerBarModules, datasetExp)
end