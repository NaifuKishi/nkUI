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

    local name = "lowerBar.datasetexp"
    local width = (uiElements.lowerBarCanvas:GetWidth() - uiElements.lowerBarTimeDate:GetWidth()) /8
    local height = uiElements.lowerBarCanvas:GetHeight()

    local datasetFrame = LibEKL.UICreateFrame("nkFrame", name .. ".frame", lowerBar.contextRestricted)
    datasetFrame:SetWidth(width)
    datasetFrame:SetHeight(height)
    datasetFrame:SetPoint("CENTERLEFT", uiElements.lowerBarCanvas, "CENTERLEFT", width * 3, 0)    
    --datasetFrame:SetBackgroundColor(1, 0, 0, 1)
    datasetFrame:SetLayer(2)
    
    local datasetExpBarBG = LibEKL.UICreateFrame('nkCanvas', name .. ".experienceFrameBG", lowerBar.contextRestricted)
    datasetExpBarBG:SetPoint("CENTER", datasetFrame, "CENTER", (21 / 2), 0)
    datasetExpBarBG:SetWidth(nkUISetup.modules.lowerBar.barWidth)
    datasetExpBarBG:SetHeight(nkUISetup.modules.lowerBar.barHeight)
    datasetExpBarBG:SetBackgroundColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, .25)
    datasetExpBarBG:SetLayer(10)

    datasetExpBarBG:SetShape({  {xProportional = 0, yProportional = 0}, 
                                {xProportional = 1, yProportional = 0}, 
                                {xProportional = 1, yProportional = 1}, 
                                {xProportional = 0, yProportional = 1}, 
                                {xProportional = 0, yProportional = 0}}, 
                            { type = "solid", r = 0x36 / 255, g = 0x40 / 255, b = 0x52 / 255, a = 0.5}, 
                            { r = 0xA3 / 255, g = 0x66 / 255, b = 0xCC / 255, a = 0.3, thickness = 2 })
   
    local datasetExpBar = LibEKL.UICreateFrame('nkFrame', name .. ".expBar", datasetExpBarBG)
    datasetExpBar:SetPoint("CENTERLEFT", datasetExpBarBG, "CENTERLEFT", 1, 0)
    datasetExpBar:SetHeight(nkUISetup.modules.lowerBar.barHeight - 2)
    datasetExpBar:SetWidth(0)
    datasetExpBar:SetLayer(1)
    datasetExpBar:SetBackgroundColor(0xA3 / 255, 0x66 / 255, 0xCC / 255, 1)
    
    --[[local datasetExp = LibEKL.UICreateFrame('nkText', "lowerBar.experience", lowerBar.contextRestricted)
    datasetExp:SetPoint("BOTTOMCENTER", datasetExpBarBG, "TOPCENTER", 0, 0)
    datasetExp:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetExp:SetFontColor(0xE8 / 255, 0xC2 / 255, 0x3B / 255, 1)
    datasetExp:SetTextFont(addonInfo.id, "MontserratMedium")
    datasetExp:SetEffectGlow({ strength = 1})
    datasetExp:SetLayer(10)]]

    local datasetExpLabel = LibEKL.UICreateFrame('nkText', name .. ".label", datasetExpBarBG)
    datasetExpLabel:SetPoint("CENTER", datasetExpBarBG, "CENTER")
    datasetExpLabel:SetFontSize(nkUISetup.modules.lowerBar.barText)
    datasetExpLabel:SetFontColor(1, 1, 1, 1)
    datasetExpLabel:SetTextFont(addonInfo.id, "MontserratMedium")
    datasetExpLabel:SetLayer(2)
    datasetExpLabel:SetEffectGlow({ strength = 3 })

    local datasetExpBarBGIcon = LibEKL.UICreateFrame("nkTexture", name .. ".icon", datasetExpBarBG)
    datasetExpBarBGIcon:SetPoint("CENTERRIGHT", datasetExpBarBG, "CENTERLEFT", -5, 0)
    datasetExpBarBGIcon:SetHeight(16)
    datasetExpBarBGIcon:SetWidth(16)
    datasetExpBarBGIcon:SetTextureAsync("nkUI", "gfx/lowerbarExperience.png")
    
    datasetFrame:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
        internalFunc.questLogInit(true)
    end, datasetFrame:GetName() .. ".Left.Down")  

    function datasetFrame:Redraw()
        datasetExpBarBG:SetWidth(nkUISetup.modules.lowerBar.barWidth)
        datasetExpBarBG:SetHeight(nkUISetup.modules.lowerBar.barHeight)
        datasetExpBar:SetHeight(nkUISetup.modules.lowerBar.barHeight)
        datasetExpLabel:SetFontSize(nkUISetup.modules.lowerBar.barText)
    end
    
    --function datasetExp:Redraw()
    --    datasetExp:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    --end
    
    local function updateExperience(experience)
        local percentText, percent = "0%", 0
        
        if experience == nil then experience = inspectExperience() end
                
        if experience and experience.accumulated then
            percent = 100 / experience.needed * experience.accumulated
            percentText = stringFormat("%d%%", percent)
        end
        
        datasetExpBar:SetWidth(nkUISetup.modules.lowerBar.barWidth * (percent/100))        

        datasetExpLabel:SetText(stringFormat("Level %d (%s)", LibEKL.Unit.GetPlayerDetails().level, percentText))

    end
    
    Command.Event.Attach(Event.TEMPORARY.Experience, function(_, accumulated, rested, needed)        
        updateExperience({accumulated = accumulated, needed = needed, rested = rested})
    end, "nkui.lowerBar.exp.TEMPORARY.Experience")
    
    updateExperience()
    
    table.insert(uiElements.lowerBarModules, datasetFrame)
    --table.insert(uiElements.lowerBarModules, datasetExp)
end