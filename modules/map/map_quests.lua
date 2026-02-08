local addonInfo, privateVars = ...

---------- init namespace ---------

local map			= privateVars.map
local mapEvents		= privateVars.mapEvents
local mapData       = privateVars.mapData
local uiElements    = privateVars.uiElements

---------- addon internal function block ---------

function map.ShowQuest(flag)
    
    if flag == true and nkUISetup.modules.map.showQuest == true then
        map.GetQuests()
    else
        if mapData.currentQuestList ~= nil then
            for questId, mappoints in pairs(mapData.currentQuestList) do
                map.UpdateMap(mappoints, "remove")
            end
        end
        
        map.UpdateMap(mapData.minimapQuestList, "remove")
        
        if mapData.missingQuestList ~= nil then
            for questId, mappoints in pairs(mapData.missingQuestList) do
                map.UpdateMap(mappoints, "remove")
            end
        end
        
        mapData.currentQuestList = {}
        mapData.minimapQuestList = {}
        mapData.minimapIdToQuest = {}
        mapData.missingQuestList = {}
    end
end