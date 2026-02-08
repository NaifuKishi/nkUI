local addonInfo, privateVars = ...

---------- init namespace ---------

local map			= privateVars.map
local mapEvents		= privateVars.mapEvents
local mapData       = privateVars.mapData
local uiElements    = privateVars.uiElements
local lang          = privateVars.langTexts

---------- make global functions local ---------

local InspectUnitDetail 	= Inspect.Unit.Detail
local InspectItemDetail 	= Inspect.Item.Detail

---------- local function block ---------

function map.CollectArtifact(itemData)
    if nkUIMapGathering.artifactsData[mapData.lastZone] == nil then nkUIMapGathering.artifactsData[mapData.lastZone] = {} end
    
    local unitDetails = InspectUnitDetail('player') 
    local coordRangeX = {unitDetails.coordX-2, unitDetails.coordX+2}
    local coordRangeZ = {unitDetails.coordZ-2, unitDetails.coordZ+2}
    
    for key, _ in pairs(itemData) do
        local details = InspectItemDetail(key)
        if details and string.find(details.category, "artifact") == 1 then
            local artifactType = string.upper(string.match(details.category, "artifact (.+)"))
            if artifactType == "FAE YULE" then artifactType = "FAEYULE" end
            local type = "TRACK.ARTIFACT." .. artifactType
            
            local knownPos = false
            for _, info in pairs(nkUIMapGathering.artifactsData[mapData.lastZone]) do
                if info.coordX >= coordRangeX[1] and info.coordX <= coordRangeX[2] and
                   info.coordZ >= coordRangeZ[1] and info.coordZ <= coordRangeZ[2] then
                    knownPos = true
                    break
                end
            end
            
            if knownPos == false then
                local thisData = { 
                    id = string.match(type, "TRACK.(.+)") .. LibEKL.Tools.UUID(), 
                    type = type, 
                    descList = {}, 
                    coordX = unitDetails.coordX, 
                    coordY = unitDetails.coordY, 
                    coordZ = unitDetails.coordZ 
                }
                nkUIMapGathering.artifactsData[mapData.lastZone][thismapData.id] = thisData
            end
        end
    end
end