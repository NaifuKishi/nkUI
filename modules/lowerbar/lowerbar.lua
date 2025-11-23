local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

---------- init local variables ---------

local InspectSystemSecure       = Inspect.System.Secure
local InspectTimeServer         = Inspect.Time.Server
local InspectTimeFrame          = Inspect.Time.Frame
local InspectCurrencyDetail     = Inspect.Currency.Detail
local InspectAbilityNewDetail   = Inspect.Ability.New.Detail
local InspectUnitDetail         = Inspect.Unit.Detail
local InspectExperience         = Inspect.Experience
local InspectFactionList        = Inspect.Faction.List
local InspectFactionDetail      = Inspect.Faction.Detail
local InspectGuildRosterDetail  = Inspect.Guild.Roster.Detail
local InspectGuildRosterList    = Inspect.Guild.Roster.List
local InspectSocialFriendDetail = Inspect.Social.Friend.Detail
local InspectSocialFriendList   = Inspect.Social.Friend.List

local stringGSub        = string.gsub
local stringFormat      = string.format
local osDate            = os.date
local mathFloor         = math.floor

local name = "lowerBar"
local parentWidth = UIParent:GetWidth()
local halfWidth = parentWidth / 2
local aThird = halfWidth / 3

---------- init variables ---------

data.insecure = {}
data.designs = {}
uiElements.lowerBarModules = {}

---------- init local function ---------

function _internal.timeDate () 
    
    local datasetTime = EnKai.uiCreateFrame("nkText", name .. ".datasettime", uiElements.contextLowest)
    datasetTime:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMCENTER", 0, 0)
    datasetTime:SetText("00:00:00")
    datasetTime:SetFontSize(data.layout.timeSize)
    datasetTime:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetTime:SetTextFont(addonInfo.id, "Montserrat")
    datasetTime:SetEffectGlow({ strength = 1, offsetX = 1, offsetY = 1, blurX=1, blurY = 1})

    local datasetDate = EnKai.uiCreateFrame("nkText", name .. ".datasetdate", uiElements.contextLowest)
    datasetDate:SetPoint("BOTTOMCENTER", datasetTime, "TOPCENTER",0, 7)
    datasetDate:SetText("00/00/0000")
    datasetDate:SetFontSize(data.layout.dateSize)
    datasetDate:SetFontColor(data.colors.accent.r, data.colors.accent.g, data.colors.accent.b, data.colors.accent.a)
    datasetDate:SetTextFont(addonInfo.id, "Montserrat")
    datasetDate:SetEffectGlow({ strength = 1})

    local updateClockTime = InspectTimeServer()
    local updateDate

    local function _updateClock ()

		local now = InspectTimeServer()
		deltaTime = now - updateClockTime

		if (updateDate == nil or deltaTime > 60) then
            local temp = osDate("*t", now)
            datasetTime:SetText(stringFormat("%02d:%02d", temp.hour, temp.min))
            updateCockTime = now

            if updateDate == nil then
                datasetDate:SetText(stringFormat("%02d/%02d/%02d", temp.day, temp.month, temp.year))            
            end
        end        
    end

    Command.Event.Attach(Event.System.Update.Begin, _updateClock, "nkUI.lowerbar.time.System.Update.Begin")

    table.insert(uiElements.lowerBarModules, datasetTime)
    table.insert(uiElements.lowerBarModules, datasetDate)
end

function _internal.currency ()

    local x = halfWidth / 3
    local currencyText = '%d<font color="#efebff">p</font> %d<font color="#eed234">g</font> %d<font color="#a7aba7">s</font> (%d)'    
    local freeBagCount = 0
    local freeBagSlots = EnKai.inventory.getAvailableSlots()
    if freeBagSlots == false then 
        EnKai.inventory.updateDB ()
        freeBagSlots = EnKai.inventory.getAvailableSlots()
         if freeBagSlots ~= false then freeBagCount = #freeBagSlots end
    else
        freeBagCount = #freeBagSlots
    end

    local datasetCurrency = EnKai.uiCreateFrame("nkText", name .. ".currency", uiElements.contextLowest)
    datasetCurrency:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMRIGHT", -aThird, -5)
    datasetCurrency:SetFontSize(data.layout.fontSize)
    datasetCurrency:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetCurrency:SetTextFont(addonInfo.id, "Montserrat")    
    datasetCurrency:SetEffectGlow({ strength = 1})

    local function _updateCoin(_, currency)
	
		if currency['coin'] == nil then return end
	
		local details = InspectCurrencyDetail('coin')
			
		if details ~= nil and details.stack ~= nil then
			local platin = mathFloor(details.stack / 10000)
			local gold = mathFloor((details.stack - (platin * 10000)) / 100)
			local silver = details.stack - (platin * 10000) - (gold * 100) 
            
			datasetCurrency:SetText(stringFormat(currencyText, platin, gold, silver, freeBagCount), true)
		end
	end

    Command.Event.Attach(EnKai.events["EnKai.InventoryManager"].Update, function (_, a, b)
        local freeBagSlots = EnKai.inventory.getAvailableSlots()
        if freeBagSlots ~= false then freeBagCount = #freeBagSlots end
		_updateCoin(_, {coin = true})
	end, "nkUI.EnKai.InventoryManager.Update")	

	Command.Event.Attach(Event.Currency, _updateCoin, "nkUI.lowerbar.Currency.Currency")

    _updateCoin(_, {coin = true})

    table.insert(uiElements.lowerBarModules, datasetCurrency)

end

function _internal.fps()

    local x = halfWidth / 3

    local datasetFPS = EnKai.uiCreateFrame('nkText', name .. ".fps", uiElements.contextLowest)
    datasetFPS:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMLEFT", aThird, -5)
    datasetFPS:SetFontSize(data.layout.fontSize)
    datasetFPS:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetFPS:SetTextFont(addonInfo.id, "Montserrat")    
    datasetFPS:SetEffectGlow({ strength = 1})

    local fpsUpdateTime, fpsDeltaTime = nil, nil
	local frameCount, fpsTimer = 0, 0
		
	local function _updateFPS()

		local now = InspectTimeFrame()
		local lastFrame = fpsUpdateTime or now

		fpsDeltaTime = now - lastFrame
		fpsTimer = fpsTimer + fpsDeltaTime
		frameCount = frameCount + 1

		if (fpsTimer > 1) then
			datasetFPS:SetText(stringFormat("%d fps", frameCount / fpsTimer))
			frameCount, fpsTimer = 0, 0
		end

		fpsUpdateTime = now
    end
  	
    Command.Event.Attach(Event.System.Update.Begin, _updateFPS, "nkUI.lowerbar.fps.System.Update.Begin")

    table.insert(uiElements.lowerBarModules, datasetFPS)

end

function _internal.location()
   
    local buttonShown = false

    local datasetLocation = EnKai.uiCreateFrame('nkText', name .. ".location", uiElements.contextLowest)
    datasetLocation:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, -5)
    datasetLocation:SetFontSize(data.layout.fontSize)
    datasetLocation:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetLocation:SetTextFont(addonInfo.id, "Montserrat")
    datasetLocation:SetSecureMode('restricted')
    datasetLocation:SetEffectGlow({ strength = 1})

    local buttons = {}
    local abilities = {["A3C5AEC64D3793518"] = true}
    local abilityDetails = InspectAbilityNewDetail(abilities)
    local parent = datasetLocation

    for k, v in pairs (abilityDetails) do
        
        local datasetLocationButton = EnKai.uiCreateFrame('nkFrame', name .. ".location.button" .. k, datasetLocation)
        datasetLocationButton:SetVisible(false)
        datasetLocationButton:SetBackgroundColor(0, 0, 0, 1)
        datasetLocationButton:SetHeight(40)
        datasetLocationButton:SetWidth(40)
        datasetLocationButton:SetSecureMode('restricted')
        datasetLocationButton:SetPoint("BOTTOMCENTER", parent, "TOPCENTER")
        
        local datasetLocationButtonTexture = EnKai.uiCreateFrame('nkTexture', name .. ".location.button.texture" .. k, datasetLocationButton)
        datasetLocationButtonTexture:SetTexture("Rift", v.icon)
        datasetLocationButtonTexture:SetPoint("TOPLEFT", datasetLocationButton, "TOPLEFT", 1, 1)
        datasetLocationButtonTexture:SetPoint("BOTTOMRIGHT", datasetLocationButton, "BOTTOMRIGHT", -1, -1)

        local macro = "cast " .. stringGSub(v.name, "\n", "")
        datasetLocationButtonTexture:EventMacroSet(Event.UI.Input.Mouse.Left.Click, macro)
        datasetLocationButtonTexture:SetVisible(true)
        table.insert (buttons, datasetLocationButton)        

        parent = datasetLocationButton
    end

    datasetLocation:EventAttach(Event.UI.Input.Mouse.Left.Click, function ()        
        if buttonShown == true then buttonShown = false else buttonShown = true end
        for k, v in pairs(buttons) do v:SetVisible(buttonShown) end
	end, name .. "_Left_Click")
    
   	local function _updateLocation(_, loc)
	
		if playerID == nil then
			local playerDetails = InspectUnitDetail('player')
			if playerDetails == nil then return end
			playerID = playerDetails.id
			if playerID == nil then return end
		end
		
		if loc[playerID] == nil or loc[playerID] == false then return end
		
		datasetLocation:SetText(loc[playerID])
	end
	
	local function _unitAvailable (_, info)
		for unit, data in pairs(info) do
			if data == "player" then
				playerID = unit
				local details = InspectUnitDetail(unit)
				datasetLocation:SetText(details.locationName)
				return
			end
		end
	end

    Command.Event.Attach(Event.Unit.Detail.LocationName, _updateLocation, "nkUI.lowerbar.location.Unit.Detail.LocationName")
	Command.Event.Attach(Event.Unit.Availability.Full, _unitAvailable, "nkUI.lowerbar.location.Unit.Availability.Full")

    table.insert(uiElements.lowerBarModules, datasetLocation)

end

function _internal.experience ()

	local exp, rested = 0, 0
    local x = halfWidth / 3
    local updateTime

    local datasetExpBarBG = EnKai.uiCreateFrame('nkFrame', name .. ".experienceFrameBG", uiElements.contextLowest)
    datasetExpBarBG:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMCENTER", -aThird, -11)
    datasetExpBarBG:SetWidth(data.layout.barWidth)
    datasetExpBarBG:SetHeight(data.layout.barHeight)
    datasetExpBarBG:SetBackgroundColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, .25)

    local datasetExpBar = EnKai.uiCreateFrame('nkFrame', name .. ".experienceFrame", datasetExpBarBG)
    datasetExpBar:SetPoint("TOPLEFT", datasetExpBarBG, "TOPLEFT")
    datasetExpBar:SetHeight(data.layout.barHeight)
    datasetExpBar:SetWidth(0)
    datasetExpBar:SetBackgroundColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)

    local datasetExp = EnKai.uiCreateFrame('nkText', name .. ".experience", uiElements.contextLowest)
    datasetExp:SetPoint("BOTTOMCENTER", datasetExpBarBG, "TOPCENTER", 0, 0)
    datasetExp:SetFontSize(data.layout.fontSize)
    datasetExp:SetFontColor(data.colors.accent.r, data.colors.accent.g, data.colors.accent.b, data.colors.accent.a)
    datasetExp:SetTextFont(addonInfo.id, "Montserrat")
    datasetExp:SetEffectGlow({ strength = 1})

	local function _updateExperience()

		local now = InspectTimeFrame()

		if not updateTime or now - updateTime > 1 then
			updateTime = now
            percent = 0

			local experience = InspectExperience()

			if experience == nil then 
				datasetExp:SetText(stringFormat("%d%%", 0))
			elseif experience.accumulated == nil then
				datasetExp:SetText(stringFormat("%d%%", 0))
			else			
                percent = 100 / experience.needed * experience.accumulated
				datasetExp:SetText(stringFormat("%d%%", percent ))
			end

            datasetExpBar:SetWidth ( data.layout.barWidth * (percent/100))

		end
	end

    
    Command.Event.Attach(Event.System.Update.Begin, _updateExperience, "nkui.lowerBar.exp.System.Update.Begin")

    _updateExperience()

    table.insert(uiElements.lowerBarModules, datasetExpBarBG)
    table.insert(uiElements.lowerBarModules, datasetExp)

end

function _internal.faction ()

    local exp = 0
    local x = halfWidth / 3
    local updateTime
    local currentFaction
    
    local notorietyLevels = {
            neutral = 0,
            friendly = 3000,
            decorated = 10000,
            honored = 20000,
            revered = 35000,
            glorified = 60000,
            venerated = 90000
    }

    local list = InspectFactionList()

    local flag, detailList = pcall (InspectFactionDetail, list)
    if flag and detailList ~= nil then
        for key, details in pairs(detailList) do
            currentFaction = details.id
            break
        end
    end
    
    local datasetFactionBarBG = EnKai.uiCreateFrame('nkFrame', name .. ".factionFrameBG", uiElements.contextLowest)
    datasetFactionBarBG:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMCENTER", aThird, -11)
    datasetFactionBarBG:SetWidth(data.layout.barWidth)
    datasetFactionBarBG:SetHeight(data.layout.barHeight)
    datasetFactionBarBG:SetBackgroundColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, .25)

    local datasetFactionBar = EnKai.uiCreateFrame('nkFrame', name .. ".factionFrame", datasetFactionBarBG)
    datasetFactionBar:SetPoint("TOPLEFT", datasetFactionBarBG, "TOPLEFT")
    datasetFactionBar:SetHeight(data.layout.barHeight)
    datasetFactionBar:SetWidth(0)
    datasetFactionBar:SetBackgroundColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)

    local datasetFaction = EnKai.uiCreateFrame('nkText', name .. ".faction", uiElements.contextLowest)
    datasetFaction:SetPoint("BOTTOMCENTER", datasetFactionBarBG, "TOPCENTER", 0, 0)
    datasetFaction:SetFontSize(data.layout.fontSize)
    datasetFaction:SetFontColor(data.colors.accent.r, data.colors.accent.g, data.colors.accent.b, data.colors.accent.a)
    datasetFaction:SetTextFont(addonInfo.id, "Montserrat")
    datasetFaction:SetEffectGlow({ strength = 1, offsetX = 1, offsetY = 1, blurX=1, blurY = 1})
    
    local datasetFactionName = EnKai.uiCreateFrame('nkText', name .. ".factionName", datasetFactionBar)
    datasetFactionName:SetPoint("CENTER", datasetFactionBarBG, "CENTER")
    datasetFactionName:SetFontSize(data.layout.barText)
    datasetFactionName:SetFontColor(0, 0, 0, 1)
    datasetFactionName:SetTextFont(addonInfo.id, "Montserrat")
    
    local function _updateFaction(_, factionData)

        if factionData ~= nil then
            for k, v in pairs(factionData) do
                currentFaction = k
            end            
        end

        if currentFaction == nil then return end

        local now = InspectTimeFrame()

		if not updateTime or now - updateTime > 1 then
			updateTime = now
            percent = 0
            level = ""
            
			local faction = InspectFactionDetail(currentFaction)

			if faction == nil then 
				datasetFaction:SetText(stringFormat("%d%%", 0))
                datasetFactionName:SetText("")
			elseif faction.notoriety == nil then
				datasetFaction:SetText(stringFormat("%d%%", 0))
                datasetFactionName:SetText("")datasetExp:SetText(stringFormat("%d%%", percent ))
            else
                for k, v in pairs (notorietyLevels) do
                    if faction.notoriety <= v then
                        percent = 100 / v * faction.notoriety
                        level = k
                        break
                    end
                end
                
                datasetFactionName:SetText(stringFormat("%s (%s)", faction.name, level))
                datasetFaction:SetText(stringFormat("%d%%", percent ))
                datasetFactionBar:SetWidth ( data.layout.barWidth * (percent/100))
			end
		end
    end

    _updateFaction()
    Command.Event.Attach(Event.Faction.Notoriety, _updateFaction, "nkui.lowerBar.faction.Event.Faction.Notoriety")

    table.insert(uiElements.lowerBarModules, datasetFactionBarBG)

end

function _internal.social ()

	local playerName
	local lastGuildUpdate
	local body, typeSelect, grid
	
	local _friendlist, _guildList = {}, {}

    local datasetSocial = EnKai.uiCreateFrame("nkText", name .. ".datasetsocial", uiElements.contextLowest)
    datasetSocial:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, -5)
    datasetSocial:SetFontSize(data.layout.fontSize)
    datasetSocial:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetSocial:SetTextFont(addonInfo.id, "Montserrat")    
    datasetSocial:SetEffectGlow({ strength = 1})
	
	local function _findGuildEntry (name) -- needed

		for k, v in pairs(_guildList) do
			if v.name == name then return k end
		end
		
		return nil
	
	end
	
	local function _processGuildMember (memberName) -- needed

		local details = InspectGuildRosterDetail(memberName)
		
		if details == nil then return end
		
		if _findGuildEntry(memberName) ~= nil then table.remove(_guildList, _findGuildEntry(memberName), 1) end
		table.insert(_guildList, { name = details.name })
	
	end
	
	local function _loadGuildRoaster() --needed

		local glist = InspectGuildRosterList()
		
		if glist ~= nil then
			for k, v in pairs (glist) do
				if v == "online" then _processGuildMember(k) end
			end
		end
		
		lastGuildUpdate = InspectTimeFrame()
		
	end
	
	local function _processFriend (friendName) -- needed

		local details = InspectSocialFriendDetail(friendName)
		
		table.insert(_friendlist, { name = details.name, level = details.level, calling = EnKai.unit.getCallingText(details.calling), zone = "" }) 
	
	end
		
	local function _friendChange () -- needed

		_friendlist = {}
		local flist = InspectSocialFriendList()
		
		for k, v in pairs(flist) do
			if v == "online" then _processFriend(k) end
		end

		datasetSocial:SetText(stringFormat("Friends %d | Guild %d", #_friendlist, #_guildList))
	end
	
	
	local function _guildStatusChange (_, data) --needed

		if lastGuildUpdate == nil or lastGuildUpdate - InspectTimeFrame() > 60 then
			_loadGuildRoaster()
		else
			for k, v in pairs(data) do

				if _findGuildEntry(k) == nil then
					_loadGuildRoaster()
					break
				end	
			
				if v == "online" then
					_processGuildMember(k)
				else
					local pos = _findGuildEntry(k)
					if pos then table.remove(_guildList, pos, 1) end
				end
			end

			datasetSocial:SetText(stringFormat("Friends %d | Guild %d", #_friendlist, #_guildList))
		end
	end
	
	local function _guildZoneChange (_, data)

		if lastGuildUpdate == nil or lastGuildUpdate - InspectTimeFrame() > 60 then
			_loadGuildRoaster()
		else
			for k, v in pairs(data) do
				if _findGuildEntry(k) == nil then
					_loadGuildRoaster()
					break
				end	

				_processGuildMember(k)
			end

			datasetSocial:SetText(stringFormat("Friends %d | Guild %d", #_friendlist, #_guildList))
		end
	end
	
	local function _checkPlayer (_, info)
	
		for k, v in pairs(info) do
			if v == "player" then
			
				playerName = v.name

				Command.Event.Detach(Event.Unit.Availability.Full, nil, "nkPanel.plugin-Social.Unit.Availability.Full")

				_loadGuildRoaster()
				_friendChange()
				return
			end
		end
	end
	
	Command.Event.Attach(Event.Social.Friend, _friendChange, "nkUI.lowerbar.Social.Friend")
	Command.Event.Attach(Event.Guild.Roster.Detail.Status, _guildStatusChange, "nkUI.lowerbar.Guild.Roster.Status")
	Command.Event.Attach(Event.Guild.Roster.Detail.Zone, _guildZoneChange, "nkUI.lowerbar.Guild.Roster.Zone")	
	Command.Event.Attach(Event.Unit.Availability.Full, _checkPlayer, "nkUI.lowerbar.Unit.Availability.Full")
	
    table.insert(uiElements.lowerBarModules, datasetSocial)

end


function _internal.lowerBar ()

    --- guild / friends

    _internal.social ()

    --- experience

    _internal.experience ()

    --- faction

    _internal.faction ()

    --- souls


    --- time / date

    _internal.timeDate()

    --- currency

    _internal.currency()

    --- fps

    _internal.fps()

    --- location / port

    _internal.location()

--local roleList = Inspect.Role.List()

--for k, v in pairs (roleList) do
    --print (v)
--end

end

function _internal.lowerBarInit (value)

    if #uiElements.lowerBarModules == 0 then    
        _internal.lowerBar()
    else
        for k, v in pairs (uiElements.lowerBarModules) do
            v:SetVisible(value)
        end
    end

end

---------- local function block ---------


