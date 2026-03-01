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

    local datasetFrame = lowerBar.dataSet("lowerBar.datasetvitality", "gfx/lowerbarVitality.png", "right")
    
    function datasetFrame:Redraw()
        datasetFrame:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    end
    
    local details = LibEKL.Unit.GetPlayerDetails()
    if details ~= nil then		
        datasetFrame:SetText(stringFormat(langTexts.lowerBar.vitality, details.vitality), true)
    end
    
    local function vitalityChange(_, units)
        if units[LibEKL.Unit.GetPlayerID()] == nil then return end        
        datasetFrame:SetText(stringFormat(langTexts.lowerBar.vitality, units[LibEKL.Unit.GetPlayerID()]), true)
    end
    
    Command.Event.Attach(Event.Unit.Detail.Vitality, vitalityChange, "nkUI.lowerBar.Vitality.Unit.Detail.Vitality")
    
    return datasetFrame
end