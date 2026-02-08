local addonInfo, privateVars = ...

---------- init namespace ---------

local map					= privateVars.map
local mapEvents				= privateVars.mapEvents
local data                  = privateVars.data
local uiElements            = privateVars.uiElements

---------- addon internal function block ---------

function map.ShowQuest(flag)
    
    if flag == true and nkUISetup.modules.map.showQuest == true then
        map.GetQuests()
    else
        if data.currentQuestList ~= nil then
            for questId, mappoints in pairs(data.currentQuestList) do
                map.UpdateMap(mappoints, "remove")
            end
        end
        
        map.UpdateMap(data.minimapQuestList, "remove")
        
        if data.missingQuestList ~= nil then
            for questId, mappoints in pairs(data.missingQuestList) do
                map.UpdateMap(mappoints, "remove")
            end
        end
        
        data.currentQuestList = {}
        data.minimapQuestList = {}
        data.minimapIdToQuest = {}
        data.missingQuestList = {}
    end
end