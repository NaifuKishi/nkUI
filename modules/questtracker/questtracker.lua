local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events

---------- init local variables ---------

local InspectTimeFrame          = Inspect.Time.Frame
local InspectAbilityNewDetail   = Inspect.Ability.New.Detail
local InspectAbilityDetail      = Inspect.Ability.Detail
local InspectExperience         = Inspect.Experience

local EnKaiUnitGetUnitDetail    = EnKai.unit.GetUnitDetail

local stringFind        = string.find
local stringMatch       = string.match
local stringFormat      = string.format

local mathRandom        = math.random
local mathCos           = math.cos
local mathSin           = math.sin
local mathRad           = math.rad

---------- init variables ---------

local name = "nkUI.QT"
local questtrackerInit = false

local function handleQuestAbandon (self, quests)
end

local function handleQuestAccept (self, quests)
end

local function handleQuestChange (self, quests)
end

local function handleQuestComplete (self, quests)
end

local function questEntry (name, parent)

    local questTitle = EnKai.uiCreateFrame("nkText", name, parent)

    

end

local function questTrackerUI ()

    local trackerUI = EnKai.uiCreateFrame("nkWindowElement", name, uiElements.contextLowest)    
    trackerUI:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkUISetup.modules.questtracker.x, nkUISetup.modules.questtracker.y )
    trackerUI:SetWidth(300)
    trackerUI:SetHeight(200)
    trackerUI:SetBackgroundColor(0, 0, 0, 1)

    local header = EnKai.uiCreateFrame("nkText", name .. ".window.header", trackerUI.GetHeader())
    header:SetPoint("TOPLEFT", trackerUI, "TOPLEFT")
    header:SetFontSize(20)
    header:SetText("Quests")
    
    EnKai.ui.setFont(header, addonInfo.id, "MontserratSemiBold")

    return trackerUI

end

function internalFunc.questrackerInit()
    
    if questtrackerInit then return end
    
    uiElements.questTracker = questTrackerUI()
    
    Command.Event.Attach(Event.Quest.Abandon, handleQuestAbandon, "nkUI.questtracker.Quest.Abandon")
    Command.Event.Attach(Event.Quest.Accept, handleQuestAccept, "nkUI.questtracker.Quest.Accept")
    Command.Event.Attach(Event.Quest.Change, handleQuestChange, "nkUI.questtracker.Quest.Change")
    Command.Event.Attach(Event.Quest.Complete, handleQuestComplete, "nkUI.questtracker.Quest.Complete	")

    questtrackerInit = true
    --[[
    
    Command.Event.Attach(Event.Combat.Dodge, function( _, info ) handleCombatEvent(info, TEXT_DODGE) end, "nkUI.SCT.Combat.Dodge")
    Command.Event.Attach(Event.Combat.Immune, function( _, info ) handleCombatEvent(info, TEXT_IMMUNE) end, "nkUI.SCT.Combat.Immune")
    Command.Event.Attach(Event.Combat.Miss, function( _, info ) handleCombatEvent(info, TEXT_MISS) end, "nkUI.SCT.Combat.Miss")
    Command.Event.Attach(Event.Combat.Parry, function( _, info ) handleCombatEvent(info, TEXT_PARRY) end, "nkUI.SCT.Combat.Parry")
    Command.Event.Attach(Event.Combat.Resist, function( _, info ) handleCombatEvent(info, TEXT_RESIST) end, "nkUI.SCT.Combat.Resist")
    Command.Event.Attach(Event.Combat.Heal, handleCombatHeal, "nkUI.SCT.Combat.Heal")

    Command.Event.Attach(Event.Ability.New.Cooldown.Begin, handleCooldownStart, "nkUI.SCT.Ability.New.Cooldown.Begin")
    Command.Event.Attach(Event.Ability.New.Cooldown.End, handleCooldownEnd, "nkUI.SCT.Ability.New.Cooldown.End")

    Command.Event.Attach(Event.TEMPORARY.Experience, function(_, accumulated, rested, needed)
        if lastAccumulated == nil then lastAccumulated = accumulated end
        local gain = accumulated - lastAccumulated
        if gain == 0 then return end
        displayMovingMessage(stringFormat("%d exp", gain), 2)
        lastAccumulated = accumulated
    end, "nkui.SCT.TEMPORARY.Experience")

    sctInit = true
    ]]
end