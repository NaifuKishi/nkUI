local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local lowerBar    = privateVars.lowerBar

---------- init local variables ---------

local stringFormat      = string.format

---------- local functions ---------

-- Creates and manages the FPS display
function lowerBar.vitality()

    local datasetVitality = LibEKL.UICreateFrame('nkText', "lowerBar.vitality", lowerBar.contextRestricted)
    datasetVitality:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMCENTER", (data.aFourth *2) + 10, -5)
    datasetVitality:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetVitality:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetVitality:SetTextFont(addonInfo.id, "Montserrat")
    datasetVitality:SetEffectGlow({ strength = 1})
    datasetVitality:SetLayer(10)

    local datasetVitalityIcon = LibEKL.UICreateFrame("nkTexture", "lowerBar.vitality.icon", datasetVitality)
    datasetVitalityIcon:SetPoint("CENTERRIGHT", datasetVitality, "CENTERLEFT", -5, 0)
    datasetVitalityIcon:SetHeight(16)
    datasetVitalityIcon:SetWidth(16)
    datasetVitalityIcon:SetTextureAsync("nkUI", "gfx/lowerbarVitality.png")
    
    function datasetVitality:Redraw()
        datasetVitality:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    end
    
    local details = LibEKL.Unit.getPlayerDetails()
    if details ~= nil then		
        datasetVitality:SetText(stringFormat("%d%% Vitality", details.vitality))
    end
    
    local function vitalityChange(_, units)
        if units[LibEKL.Unit.getPlayerID()] == nil then return end        
        datasetVitality:SetText(stringFormat("%d%% Vitality", units[LibEKL.Unit.getPlayerID()]))
    end
    
    Command.Event.Attach(Event.Unit.Detail.Vitality, vitalityChange, "nkUI.lowerBar.Vitality.Unit.Detail.Vitality")
    
    table.insert(uiElements.lowerBarModules, datasetVitality)
end