local addonInfo, privateVars = ...

---------- init namespace ---------

local map			= privateVars.map
local mapEvents		= privateVars.mapEvents
local mapData       = privateVars.mapData
local uiElements    = privateVars.uiElements
local lang          = privateVars.langTexts

---------- make global functions local ---------

local LibEKLGetLanguage      = LibEKL.Tools.Lang.GetLanguage
local LibEKLGetLanguageShort = LibEKL.Tools.Lang.GetLanguageShort
local LibEKLTableCopy       = LibEKL.Tools.Table.Copy
local LibEKLUUID            = LibEKL.Tools.UUID

---------- local function block ---------

local function _processRareData(id, counter, name, x, z, comment)
    local thisId = "rare-" .. id .. "-" .. counter
    local thisData = { id = thisId, type = "UNIT.RARE", descList = {name}, coordX = x, coordZ = z }
    table.insert(thisData.descList, "Rare Mob")
    if comment ~= "" then table.insert(thisData.descList, comment) end
    uiElements.mapUI:AddElement(thisData)
    mapData._rareData[thisId] = thisData
end

local function _getRareDarData()
    if mapData._zoneDetails == nil then return end
    mapData._rareData = {}
    for idx = 1, #RareDar.data, 1 do
        if RareDar.data[idx].zone[LibEKLGetLanguage()] == mapData._zoneDetails.name then
            local mobs = RareDar.data[idx].mobs
            for idx2 = 1, #mobs, 1 do
                if mapData.rareMobKilled[mobs[idx2].achv[LibEKLGetLanguage()]] ~= true then
                    local posList = mobs[idx2].pos
                    for idx3 = 1, #posList, 1 do
                        _processRareData(mobs[idx2].id, idx3, mobs[idx2].targ[LibEKLGetLanguage()], posList[idx3][1], posList[idx3][2], mobs[idx2].comment[LibEKLGetLanguage()])
                    end
                end
            end
        end
    end
end

local function _getRareTrackerData()
    local zoneData = Inspect.Addon.Detail('RareTracker').mapData.moblocs[mapData.lastZone]
    if zoneData == nil then return end
    local mobs = zonemapData.mobs
    mapData._rareData = {}
    for idx = 1, #mobs, 1 do
        if mapData.rareMobKilled[mobs[idx].n[LibEKLGetLanguageShort()]] ~= true then
            local posList = mobs[idx].loc
            for idx2 = 1, #posList, 1 do
                _processRareData(mobs[idx].n[LibEKLGetLanguageShort()], idx2, mobs[idx].n[LibEKLGetLanguageShort()], posList[idx2].x, posList[idx2].z, "")
            end
        end
    end
end

---------- addon internal function block ---------

function map.ShowPOI(flag)
    local lastPoi = LibMap.map.GetZonePOI(mapData.lastZone)
    if flag == true and nkAM_Loot ~= nil and LibEKL.Unit.GetGroupStatus() ~= 'single' then
        local bossInfo = nkAM_Loot.getPOI(mapData.lastZone)
        if bossInfo ~= nil then
            if mapData.customPOIs[mapData.lastZone] == nil then mapData.customPOIs[mapData.lastZone] = {} end
            for k, v in pairs(bossInfo) do
                mapData.customPOIs[mapData.lastZone][k] = v
            end
        end
    end
    
    local customPoi = mapData.customPOIs[mapData.lastZone]
    if customPoi ~= nil then
        if lastPoi == nil then lastPoi = {} end
        for k, v in pairs(customPoi) do
            lastPoi[k] = v
            lastPoi[k].id = k
            if lastPoi[k].type == "POI.ACHIEVEMENT" then
                lastPoi[k].title = lang.poiAchievement
            elseif lastPoi[k].type == "POI.PUZZLE" then
                lastPoi[k].title = lang.poiPuzzle
            end
            lastPoi[k].descList = { v[LibEKLGetLanguageShort()] }
        end
    end
    
    if lastPoi == nil then return end
    if flag == true and nkUISetup.modules.map.showPOI == true then
        map.UpdateMap(lastPoi, "add", "map.ShowPOI")
    else
        map.UpdateMap(lastPoi, "remove")
    end
end

function map.ShowRareMobs(flag)

    if flag == true then
        if Inspect.Addon.Detail('RareDar') ~= nil then
            _getRareDarData()
        elseif Inspect.Addon.Detail('RareTracker') ~= nil then
            _getRareTrackerData()
        end
    elseif mapData._rareData then
        map.UpdateMap(mapData._rareData, "remove")
    end
end

function map.ShowGathering(flag)

    if nkUIMapGathering.gatheringData[mapData.lastZone] == nil then return end

    local action = "add"
    if flag == false then action = "remove" end
    
    local temp = {}

    for k, v in pairs(nkUIMapGathering.gatheringData[mapData.lastZone]) do
        table.insert(temp, {[k] = v})
    end
    
    local gridCoRoutine = coroutine.create(
        function ()
            for idx = 1, #temp, 1 do
                map.UpdateMap(temp[idx], action, "map.ShowGathering")
                coroutine.yield(idx)
            end
        end
    )
    LibEKL.Coroutines.Add({ func = gridCoRoutine, counter = #temp, active = true })
end

function map.ShowArtifacts(flag)
    if nkUIMapGathering.artifactsData[mapData.lastZone] == nil then return end
    if flag == true then
        map.UpdateMap(nkUIMapGathering.artifactsData[mapData.lastZone], "add")
    else
        map.UpdateMap(nkUIMapGathering.artifactsData[mapData.lastZone], "remove")
    end
end

function map.UpdateWaypointArrows()

    if uiElements.mapUI == nil or mapData.centerElement == nil then return end

    local map = uiElements.mapUI:GetMap()
    local mapInfo = uiElements.mapUI:GetMapInfo()
    local coordX, coordZ = uiElements.mapUI:GetElement(mapData.centerElement):GetCoord()
    local mask = uiElements.mapUI:GetMask()
    local mapWidth, mapHeight = map:GetWidth(), map:GetHeight()

    for key, details in pairs(mapData.waypoints) do
        if details.coordX >= mapInfo.x1 and details.coordX <= mapInfo.x2 and details.coordZ >= mapInfo.y1 and details.coordZ <= mapInfo.y2 then
            
            if details.gfx == nil then
                if not uiElements.mapWaypoints then uiElements.mapWaypoints = {} end

                if not next(uiElements.mapWaypoints) then
                    details.gfx = LibEKL.UICreateFrame("nkCanvas", "nkUI.waypointarrow." .. LibEKLUUID(), mask)
                else
                    --print "reuse"
                    details.gfx = table.remove(uiElements.mapWaypoints)
                    details.gfx:SetVisible(true)
                end

                --details.gfx = LibMap.ElementManager.GetElement("nkMapElementCanvas", "nkUI.waypointarrow." .. LibEKLUUID(), mask)
                details.gfx:SetLayer(999)
            end
            
            local stroke = { thickness = 3, r = 1, g = 0.8, b = 0.4, a = 1 }
            if details.player == true then stroke = { thickness = 3, r = 0.463, g = 0.741, b = 0.722, a = 1 } end
            
            local width, height, xmod, zmod, headX, headY = 0, 0, 0, 0, 0, 0
            local canvas
            
            if details.coordX <= coordX then
                width, xmod = coordX - details.coordX, -1
                if details.coordZ <= coordZ then
                    canvas = {{xProportional = 1, yProportional = 1}, {xProportional = 0, yProportional = 0}}
                    height, zmod = coordZ - details.coordZ, -1
                else
                    canvas = {{xProportional = 1, yProportional = 0}, {xProportional = 0, yProportional = 1}}
                    height, zmod, headY = details.coordZ - coordZ, 0, 1
                end
            else
                width, xmod, headX = details.coordX - coordX, 0, 1
                if details.coordZ <= coordZ then
                    canvas = {{xProportional = 0, yProportional = 1}, {xProportional = 1, yProportional = 0}}
                    height, zmod = coordZ - details.coordZ, -1
                else
                    canvas = {{xProportional = 0, yProportional = 0}, {xProportional = 1, yProportional = 1}}
                    height, zmod, headY = details.coordZ - coordZ, 0, 1
                end
            end
            
            local newWidth = mapWidth / (mapInfo.x2 - mapInfo.x1) * width
            local newHeight = mapHeight / (mapInfo.y2 - mapInfo.y1) * height
            local xP = 1 / (mapInfo.x2 - mapInfo.x1) * (coordX - mapInfo.x1)
            local yP = 1 / (mapInfo.y2 - mapInfo.y1) * (coordZ - mapInfo.y1)
            local thisX = (mapWidth * xP)
            local thisY = (mapHeight * yP)
            
            details.gfx:ClearAll()
            details.gfx:SetWidth(newWidth)
            details.gfx:SetHeight(newHeight)
            details.gfx:SetShape(canvas, nil, stroke)
            details.gfx:SetPoint("TOPLEFT", map, "TOPLEFT", thisX + (newWidth * xmod), thisY + (newHeight * zmod))
        end
    end
end

function map.WaypointDialog()
    local xpos, ypos
    if InspectSystemSecure() == true then return end
    
    if uiElements.waypointDialog == nil then
        local name = "nkUI.waypointDialog"
        local coordLabel, xposEdit, yposEdit, sepLabel, setButton
        uiElements.waypointDialog = LibEKL.UICreateFrame("nkWindow", name, uiElements.mapContextSecure)
        uiElements.waypointDialog:SetLayer(3)
        uiElements.waypointDialog:SetWidth(200)
        uiElements.waypointDialog:SetHeight(140)
        uiElements.waypointDialog:SetTitle(lang.waypointDialogTitle)
        uiElements.waypointDialog:SetSecureMode('restricted')
        uiElements.waypointDialog:SetTitleFont(addonInfo.id, "MontserratSemiBold")
        
        Command.Event.Attach(LibEKL.Events[name].Closed, function ()
            xposEdit:Leave()
            yposEdit:Leave()
        end, name .. ".Closed")
        
        coordLabel = LibEKL.UICreateFrame("nkText", name .. ".coordLabel", uiElements.waypointDialog:GetContent())
        coordLabel:SetPoint("CENTERTOP", uiElements.waypointDialog:GetContent(), "CENTERTOP", 0, 10)
        coordLabel:SetFontColor(1, 1, 1, 1)
        coordLabel:SetFontSize(12)
        coordLabel:SetText(lang.coordLabel)
        LibEKL.ui.setFont(coordLabel, addonInfo.id, "Montserrat")
        
        sepLabel = LibEKL.UICreateFrame("nkText", name .. ".sepLabel", uiElements.waypointDialog:GetContent())
        sepLabel:SetPoint("CENTERTOP", coordLabel, "CENTERBOTTOM", 0, 10)
        sepLabel:SetFontColor(1, 1, 1, 1)
        sepLabel:SetFontSize(12)
        sepLabel:SetText("/")
        LibEKL.ui.setFont(sepLabel, addonInfo.id, "Montserrat")
        
        xposEdit = LibEKL.UICreateFrame("nkTextField", name .. ".xposEdit", uiElements.waypointDialog:GetContent())
        yposEdit = LibEKL.UICreateFrame("nkTextField", name .. ".yposEdit", uiElements.waypointDialog:GetContent())
        
        xposEdit:SetPoint("CENTERRIGHT", sepLabel, "CENTERLEFT", -5, 0)
        xposEdit:SetWidth(50)
        xposEdit:SetTabTarget(yposEdit)
        
        local function _setMacro()
            if xpos == nil or ypos == nil or tonumber(xpos) == nil or tonumber(ypos) == nil then return end
            LibEKL.Events.AddInsecure(function() setButton:SetMacro(string.format("setwaypoint %d %d", xpos, ypos)) end)
        end
        
        Command.Event.Attach(LibEKL.Events[name .. ".xposEdit"].TextfieldChanged, function (_, newValue)
            xpos = newValue
            _setMacro()
        end, name .. ".xposEdit.TextfieldChanged")
        
        yposEdit:SetPoint("CENTERLEFT", sepLabel, "CENTERRIGHT", 5, 0)
        yposEdit:SetWidth(50)
        yposEdit:SetTabTarget(xposEdit)
        
        Command.Event.Attach(LibEKL.Events[name .. ".yposEdit"].TextfieldChanged, function (_, newValue)
            ypos = newValue
            _setMacro()
        end, name .. ".yposEdit.TextfieldChanged")
        
        setButton = LibEKL.UICreateFrame("nkButton", name .. ".setButton", uiElements.waypointDialog:GetContent())
        setButton:SetPoint("CENTERTOP", sepLabel, "CENTERBOTTOM", 0, 20)
        setButton:SetText(lang.btSet)
        setButton:SetScale(.8)
        setButton:SetLayer(9)
        setButton:SetFont(addonInfo.id, "MontserratSemiBold")
        
        Command.Event.Attach(LibEKL.Events[name .. ".setButton"].Clicked, function ()
            xposEdit:Leave()
            yposEdit:Leave()
            LibEKL.Events.AddInsecure(function() uiElements.waypointDialog:SetVisible(false) end)
        end, name .. ".setButton.Clicked")
    else
        if uiElements.waypointDialog:GetVisible() == true then
            uiElements.waypointDialog:SetVisible(false)
        else
            uiElements.waypointDialog:SetVisible(true)
        end
    end
    
    local mouseData = InspectMouse()
    uiElements.waypointDialog:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mousemapData.x - uiElements.waypointDialog:GetWidth(), mousemapData.y - uiElements.waypointDialog:GetHeight())
end

function map.ShowCustomPoints()
    if nkUISetup.modules.map.userPOI[mapData.currentWorld] ~= nil then map.UpdateMap(nkUISetup.modules.map.userPOI[mapData.currentWorld], "add") end
end