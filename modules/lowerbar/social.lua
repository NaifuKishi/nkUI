local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local lowerBar    = privateVars.lowerBar

---------- init local variables ---------

local inspectSocialFriendDetail = Inspect.Social.Friend.Detail
local inspectSocialFriendList   = Inspect.Social.Friend.List
local inspectGuildRosterDetail  = Inspect.Guild.Roster.Detail
local inspectGuildRosterList    = Inspect.Guild.Roster.List
local inspectTimeFrame          = Inspect.Time.Frame
local stringFormat              = string.format

---------- local functions ---------

-- Creates and manages the social display (friends and guild)
function lowerBar.social()
    local playerName
    local lastGuildUpdate
    local _friendlist, _guildList = {}, {}
    
    local datasetSocial = EnKai.uiCreateFrame("nkText", "lowerBar.datasetsocial", uiElements.contextLowestRestricted)
    datasetSocial:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, -5)
    datasetSocial:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetSocial:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetSocial:SetTextFont(addonInfo.id, "Montserrat")
    datasetSocial:SetEffectGlow({ strength = 1})
    
    function datasetSocial:Redraw()
        datasetSocial:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    end
    
    local function findGuildEntry(name)
        for k, v in pairs(_guildList) do
            if v.name == name then return k end
        end
        return nil
    end
    
    local function processGuildMember(memberName)
        local details = inspectGuildRosterDetail(memberName)
        
        if details == nil then return end
        
        if findGuildEntry(memberName) ~= nil then
            table.remove(_guildList, findGuildEntry(memberName), 1)
        end
        table.insert(_guildList, { name = details.name })
    end
    
    local function loadGuildRoster()
        local glist = inspectGuildRosterList()
        
        if glist ~= nil then
            for k, v in pairs(glist) do
                if v == "online" then processGuildMember(k) end
            end
        end
        
        lastGuildUpdate = inspectTimeFrame()
    end
    
    local function processFriend(friendName)
        local details = inspectSocialFriendDetail(friendName)
        
        table.insert(_friendlist, {
            name = details.name,
            level = details.level,
            calling = EnKai.unit.getCallingText(details.calling),
            zone = ""
        })
    end
    
    local function friendChange()
        _friendlist = {}
        local flist = inspectSocialFriendList()
        
        for k, v in pairs(flist) do
            if v == "online" then processFriend(k) end
        end
        
        datasetSocial:SetText(stringFormat("Friends %d | Guild %d", #_friendlist, #_guildList))
    end
    
    local function guildStatusChange(_, data)
        if lastGuildUpdate == nil or lastGuildUpdate - inspectTimeFrame() > 60 then
            loadGuildRoster()
        else
            for k, v in pairs(data) do
                if findGuildEntry(k) == nil then
                    loadGuildRoster()
                    break
                end
                
                if v == "online" then
                    processGuildMember(k)
                else
                    local pos = findGuildEntry(k)
                    if pos then table.remove(_guildList, pos, 1) end
                end
            end
            
            datasetSocial:SetText(stringFormat("Friends %d | Guild %d", #_friendlist, #_guildList))
        end
    end
    
    local function guildZoneChange(_, data)
        if lastGuildUpdate == nil or lastGuildUpdate - inspectTimeFrame() > 60 then
            loadGuildRoster()
        else
            for k, v in pairs(data) do
                if findGuildEntry(k) == nil then
                    loadGuildRoster()
                    break
                end
                
                processGuildMember(k)
            end
            
            datasetSocial:SetText(stringFormat("Friends %d | Guild %d", #_friendlist, #_guildList))
        end
    end
    
    local function checkPlayer(_, info)
        for k, v in pairs(info) do
            if v == "player" then
                playerName = v.name
                
                Command.Event.Detach(Event.Unit.Availability.Full, nil, "nkPanel.plugin-Social.Unit.Availability.Full")
                
                loadGuildRoster()
                friendChange()
                return
            end
        end
    end
    
    Command.Event.Attach(Event.Social.Friend, friendChange, "nkUI.lowerbar.Social.Friend")
    Command.Event.Attach(Event.Guild.Roster.Detail.Status, guildStatusChange, "nkUI.lowerbar.Guild.Roster.Status")
    Command.Event.Attach(Event.Guild.Roster.Detail.Zone, guildZoneChange, "nkUI.lowerbar.Guild.Roster.Zone")
    Command.Event.Attach(Event.Unit.Availability.Full, checkPlayer, "nkUI.lowerbar.Unit.Availability.Full")
    
    table.insert(uiElements.lowerBarModules, datasetSocial)
end