local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local lowerBar      = privateVars.lowerBar
local langTexts     = privateVars.langTexts

---------- init local variables ---------

local stringFormat      = string.format

---------- local functions ---------

-- Creates and manages the FPS display
function lowerBar.vitality()

    local name = "lowerBar.datasetvitality"
    local width = (uiElements.lowerBarCanvas:GetWidth() - uiElements.lowerBarTimeDate:GetWidth()) /8
    local height = uiElements.lowerBarCanvas:GetHeight()

    local datasetFrame = LibEKL.UICreateFrame("nkFrame", name .. ".frame", lowerBar.contextRestricted)
    datasetFrame:SetWidth(width)
    datasetFrame:SetHeight(height)
    datasetFrame:SetPoint("CENTERRIGHT", uiElements.lowerBarCanvas, "CENTERRIGHT", -(width*2), 0)    
    --datasetFrame:SetBackgroundColor(1, 0, 0, 1)
    datasetFrame:SetLayer(2)    

    local datasetVitality = LibEKL.UICreateFrame('nkText', name .. ".text", lowerBar.contextRestricted)
    datasetVitality:SetPoint("CENTER", datasetFrame, "CENTER", 21, 0)
    datasetVitality:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetVitality:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetVitality:SetTextFont(addonInfo.id, "MontserratMedium")
    datasetVitality:SetEffectGlow({ strength = 1})
    datasetVitality:SetLayer(10)

    local datasetVitalityIcon = LibEKL.UICreateFrame("nkTexture", name .. ".icon", datasetFrame)
    datasetVitalityIcon:SetPoint("CENTERRIGHT", datasetVitality, "CENTERLEFT", -5, 0)
    datasetVitalityIcon:SetHeight(16)
    datasetVitalityIcon:SetWidth(16)
    datasetVitalityIcon:SetTextureAsync("nkUI", "gfx/lowerbarVitality.png")
    
    function datasetFrame:Redraw()
        datasetVitality:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    end
    
    local details = LibEKL.Unit.GetPlayerDetails()
    if details ~= nil then		
        datasetVitality:SetText(stringFormat(langTexts.lowerBar.vitality, details.vitality), true)
    end
    
    local function vitalityChange(_, units)
        if units[LibEKL.Unit.getPlayerID()] == nil then return end        
        datasetVitality:SetText(stringFormat(langTexts.lowerBar.vitality, units[LibEKL.Unit.getPlayerID()]), true)
    end
    
    Command.Event.Attach(Event.Unit.Detail.Vitality, vitalityChange, "nkUI.lowerBar.Vitality.Unit.Detail.Vitality")
    
    table.insert(uiElements.lowerBarModules, datasetFrame)
end