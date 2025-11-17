local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

-- Cache frequently used functions and values
local InspectBuffList     	= Inspect.Buff.List
local InspectBuffDetail	  	= Inspect.Buff.Detail
local InspectUnitLookup	  	= Inspect.Unit.Lookup
local InspectUnitDetail	  	= Inspect.Unit.Detail
local InspectUnitCastbar	= Inspect.Unit.Castbar
local InspectTimeReal		= Inspect.Time.Real
local InspectSystemWatchdog = Inspect.System.Watchdog

local stringFind  	= string.find
local pairs			= pairs
local tonumber		= tonumber
local stringSub		= string.sub
local stringFormat	= string.format

local processBuffs	= _internal.processBuffs

---------- init local variables ---------

local _lastUpdate1, _lastUpdate2
local _eventsP1Index = 1
local _eventsS1Index = 1
local _eventsRemIndex = 1

---------- init variables ---------

data.playerCastbar = false
data.targetCastbar = false

---------- local function block ---------

function _events.unitChange (unitID, unitType)

	if stringfind(unitType, 'mt') ~= 1 and ((stringfind(unitType, 'group') == 1 and stringfind(unitType, 'group..%.') == nil) or stringfind(unitType, 'raid') == 1) then			
		for idx = 1, 3, 1 do			
		end
	end
	
	-- check for maintank target change
	
	for idx = 1, 3, 1 do
	end

end

local function _processFocus()
	if data.processPlayerFocus then
		local details = InspectUnitDetail("player")
		
		if details.focus ~= data.playerFocus then
			data.playerFocus = details.focus
			 uiElements.frames.playerRessourceBar:SetRessource(details.focus)
		end
	end
end

local function _processBuffs()

	--- process buffs and debuffs

	local buffList = InspectBuffList("player")

	if buffList then 
		local details = InspectBuffDetail("player", buffList)

		local buffIcons = _internal.buffBar:GetBuffIcons()
		local debuffIcons = _internal.buffBar:GetBuffIcons()

		for k, v in pairs (details) do
			if v.remaining then
				if buffIcons[k] then
					buffIcons[k].icon:SetTimer(v.remaining)
					if buffIcons[k] then buffIcons[k].icon:SetTimer(v.remaining) end
				elseif debuffIcons[k] then
					debuffIcons[k].icon:SetTimer(v.remaining)
					if debuffIcons[k].icon then debuffIcons[k].icon:SetTimer(v.remaining) end
				end
			end
		end
	

		--- process player

		local playerBuffIcons = uiElements.frames.player:GetBuffIcons()
		local playerDebuffIcons = uiElements.frames.player:GetDebuffIcons()

		for k, v in pairs (details) do
			if v.remaining then
				if playerBuffIcons[k] then
					playerBuffIcons[k].icon:SetTimer(v.remaining)
					if playerBuffIcons[k] then playerBuffIcons[k].icon:SetTimer(v.remaining) end
				elseif playerDebuffIcons[k] then
					playerDebuffIcons[k].icon:SetTimer(v.remaining)
					if playerDebuffIcons[k].icon then playerDebuffIcons[k].icon:SetTimer(v.remaining) end
				end
			end
		end
	end

	--- process pet

	if data.playerPetID then

		local buffList = InspectBuffList("player.pet")
		if (buffList) then
			local details = InspectBuffDetail("player.pet", buffList)

			local playerPetBuffIcons = uiElements.frames.playerPet:GetBuffIcons()
			local playerPetDebuffIcons = uiElements.frames.playerPet:GetDebuffIcons()

			for k, v in pairs (details) do
				if v.remaining then
					if playerPetBuffIcons[k] then
						playerPetBuffIcons[k].icon:SetTimer(v.remaining)
						if playerPetBuffIcons[k] then playerPetBuffIcons[k].icon:SetTimer(v.remaining) end
					elseif playerPetDebuffIcons[k] then
						playerPetDebuffIcons[k].icon:SetTimer(v.remaining)
						if playerPetDebuffIcons[k].icon then playerPetDebuffIcons[k].icon:SetTimer(v.remaining) end
					end
				end
			end
		end
	end

	--- process target

	if data.targetID then		

		local thisUnit = InsepctUnitLookup(data.targetID)
		if thisUnit == "player.target" then

			local buffList = InspectBuffList("player.target")			
			local details = InspectBuffDetail("player.target", buffList)

			local targetBuffIcons = uiElements.frames.target:GetBuffIcons()
			local targetDebuffIcons = uiElements.frames.target:GetDebuffIcons()

			for k, v in pairs (details) do
				if v.remaining then
					if targetBuffIcons[k] then
						targetBuffIcons[k].icon:SetTimer(v.remaining)
						if targetBuffIcons[k] then targetBuffIcons[k].icon:SetTimer(v.remaining) end
					elseif targetDebuffIcons[k] then
						targetDebuffIcons[k].icon:SetTimer(v.remaining)
						if targetDebuffIcons[k].icon then targetDebuffIcons[k].icon:SetTimer(v.remaining) end
					end
				end
			end
		end
	end
end

function _events.uiFramesInitEvents()	

	local function _unitAvailable (_, info)        
		for unit, thisData in pairs(info) do
			if thisData == "player" then
				data.playerID = unit
				uiElements.frames.player:ContextMenu(unit)
				uiElements.frames.player:update(unit)
				uiElements.frames.playerRessourceBar:update(unit)

				local petId = InspectUnitLookup("player.pet")
				if petId then
					data.playerPetID = petId
					uiElements.frames.playerPet:ContextMenu(petId)
					uiElements.frames.playerPet:SetVisible(true)
					uiElements.frames.playerPet:update(petId)
				end
			end		    
        end
	end

    local function _eventHealth (_, info)
        for unit, thisData in pairs(info) do
            if unit == data.playerID then
				uiElements.frames.player:SetHealth(thisData)
            elseif unit == data.targetID then
                uiElements.frames.target:SetHealth(thisData)
			elseif unit == data.playerPetID then
                uiElements.frames.playerPet:SetHealth(thisData)
            end
        end
    end

    local function _eventHealthCap (a,b,c)
    end

    local function _eventHealthMax (_, info)
        for unit, thisData in pairs(info) do
            if unit == data.playerID then
                uiElements.frames.player:SetHealthMax(thisData)
			elseif unit == data.playerPetID then
				uiElements.frames.playerPet:SetHealthMax(thisData)
            end
        end
    end

    local function _eventEnergy (_, info)
        for unit, thisData in pairs(info) do
			if unit == data.playerID then
				uiElements.frames.player:SetEnergy(thisData)
                uiElements.frames.playerRessourceBar:SetRessource(thisData)
                return
            end
        end
    end

    local function _eventEnergyMax (_, info)
		for unit, thisData in pairs(info) do
        	if unit == data.playerID then
                uiElements.frames.playerRessourceBar:SetRessourceMax(thisData)
                return
            end
        end
    end

	local function _eventMana (_, info)
        for unit, thisData in pairs(info) do
			if unit == data.playerID then
				uiElements.frames.player:SetEnergy(thisData)
                uiElements.frames.playerRessourceBar:SetRessource(thisData)
                return
            end
        end
    end

	local function _eventCharge (_, info)
        for unit, thisData in pairs(info) do
			if unit == data.playerID then
                uiElements.frames.playerRessourceBar:SetCharge(thisData)
                return
            end
        end
    end
    --local function _eventMaxMax (_, info)
	--	for unit, thisData in pairs(info) do
    --    	if unit == data.playerID then
    --            uiElements.frames.playerRessourceBar:SetRessourceMax(thisData)
    --            return
    --        end
    --    end
    --end

	local function _eventPower (_, info)
        for unit, thisData in pairs(info) do
            if unit == data.playerID then
                uiElements.frames.player:SetEnergy(thisData)
                uiElements.frames.playerRessourceBar:SetRessource(thisData)
                return
            end
        end
    end

    --local function _eventPowerMax (_, info)
	--	for unit, thisData in pairs(info) do
    --    	if unit == data.playerID then
    --            uiElements.frames.playerRessourceBar:SetRessourceMax(thisData)
    --            return
    --        end
    --    end
    --end
    
    local function _eventPlanar (_, info)
        for unit, thisData in pairs(info) do            
            if unit == data.playerID then
                uiElements.frames.player:SetPlanar(thisData)
                return
            end
        end
    end

	local function _eventCombo (_, info)
         for unit, thisData in pairs(info) do        
			if unit == data.playerID then
				uiElements.frames.playerRessourceBar:SetCombo(thisData)
			end
		 end
    end

    local function _eventUnitAdd (_, info)

        for unit, thisData in pairs(info) do
            if thisData == "player.target" then
                data.targetID = unit
				local thisFrame = uiElements.frames.target
                thisFrame:SetUnitID(unit)
				thisFrame:ProcessUnitDetails(unit)
                thisFrame:SetVisible(true)

				local buffs = InspectBuffList(unit)
				thisFrame:addBuff(unit, buffs)

				thisFrame.Event.RightClick =
					function()
						Command.Unit.Menu(data.targetID)
					end

			elseif thisData == "player.pet" then
				data.playerPetID = unit
				local thisFrame = uiElements.frames.playerPet

                thisFrame:SetUnitID(unit)
				thisFrame:ProcessUnitDetails(unit)
                thisFrame:SetVisible(true)

				thisFrame.Event.RightClick =
					function()
						Command.Unit.Menu(data.playerPetID)
					end
            end
        end
    end

    local function _eventUnitChange (_, info)
		print ("_eventUnitChange")
        dunp(info)
    end
    
    local function _eventUnitRemove (_, info)

        for unit, thisData in pairs(info) do
            if unit == data.targetID and thisData == false then
                -- only remove if data is false cause otherwiese mouseout event triggers
				data.targetID = nil

				local thisFrame = uiElements.frames.target
				thisFrame:SetVisible(false)
				thisFrame:ClearBuffs ()
            end

			if unit == data.playerPetID and thisData == false then
				data.playerPetID = nil

				local thisFrame = uiElements.frames.playerPet
				thisFrame:SetVisible(false)
				thisFrame:ClearBuffs ()
			end
        end
    end

    local function _eventBuffAdd (_, unit, buffs)

		if nkUISetup.buffFrame.activate == false then return end

        if unit == data.playerID then
            _internal.buffBar.addBuff(unit, buffs)
			_internal.buffBar.UpdateBuffDisplay()

			uiElements.frames.player:addBuff(unit, buffs)
		elseif unit == data.targetID then
			uiElements.frames.target:addBuff(unit, buffs)
		elseif unit == data.playerPetID then
			uiElements.frames.playerPet:addBuff(unit, buffs)
        end

        
    end

    local function _eventBuffChange (_, unit, buffs)
		if nkUISetup.buffFrame.activate == false then return end
    end

    local function _eventBuffRemove (_, unit, buffs)

		if nkUISetup.buffFrame.activate == false then return end

        if unit == data.playerID then            
            _internal.buffBar.removeBuff(unit, buffs)
        	_internal.buffBar.UpdateBuffDisplay()
			
			uiElements.frames.player:removeBuff(unit, buffs)
		elseif unit == data.targetID then
			uiElements.frames.target:removeBuff(unit, buffs)
		elseif unit == data.playerPetID then
			uiElements.frames.playerPet:removeBuff(unit, buffs)
        end


    end

	local function _eventCastBar(_, units) 
		for k, v in pairs (units) do			
			if k == data.playerID then
				if v then
					uiElements.frames.playerCastbar:SetVisible(true)
					data.playerCastbar = true
				else
					uiElements.frames.playerCastbar:SetVisible(false)
					data.playerCastbar = false
				end
			elseif k == data.targetID then
				if v then
					uiElements.frames.targetCastbar:SetVisible(true)
					data.targetCastbar = true
				else
					uiElements.frames.targetCastbar:SetVisible(false)
					data.targetCastbar = false
				end
			end
		end
	end

	local function _processCastBars () 

		if data.playerCastbar then
			local details = InspectUnitCastbar(data.playerID)

			if details then
				local thisFrame = uiElements.frames.playerCastbar
				thisFrame:SetSpell (details.abilityName)
				thisFrame:SetTimer (details.remaining, details.duration)
			end
		end

		if data.targetCastbar then
			local details = InspectUnitCastbar(data.targetID)

			if details then
				local thisFrame = uiElements.frames.targetCastbar
				thisFrame:SetSpell (details.abilityName)
				thisFrame:SetTimer (details.remaining, details.duration)
			end
		end

	end

	local function _fctSecureEnter()

		uiElements.frames.player:SetAlpha(1)
		uiElements.frames.playerPet:SetAlpha(1)
		uiElements.frames.target:SetAlpha(1)
		uiElements.frames.playerRessourceBar:SetVisible(true)
    
	end

	local function _fctSecureLeave()

		uiElements.frames.player:SetAlpha(0.2)
		uiElements.frames.playerPet:SetAlpha(0.2)
		uiElements.frames.target:SetAlpha(0.2)
		uiElements.frames.playerRessourceBar:SetVisible(false)
    
	end

	local function _fctZoneEvent(_, thisData)

		for k, v in pairs(thisData) do
			if k == data.playerID then
				_internal.processBuffs ()
			end
		end
	end

	local function _fctUpdateHandler()
		
		-- run always

		_processCastBars() -- this is updated quite fast on purpose to have a smooth scroll bar
		
		local _curTime = InspectTimeReal()
		local _watchDog = InspectSystemWatchdog()
		
		-- run every 1 second
		
		if (_lastUpdate2 == nil or _curTime - _lastUpdate2 >= 1) then
			if _watchDog >= 0.1 and _eventsS1Index == 1 then _eventsS1Index = 2 end			
			if _watchDog >= 0.1 and _eventsS1Index == 2 then  _eventsS1Index = 3 end			
			if _watchDog >= 0.1 and _eventsS1Index == 3 then _eventsS1Index = 1 end
			
			_lastUpdate2 = _curTime
		end
		
		-- run every 0.5 seconds
		
		if (_lastUpdate1 == nil or _curTime - _lastUpdate1 >= .5) then
		
			if _watchDog >= 0.1 and _eventsP1Index == 1 then
				_internal.processBuffs()
				_eventsP1Index = 2
			end
			
			if _watchDog >= 0.1 and _eventsP1Index == 2 then _eventsP1Index = 3 end			
			if _watchDog >= 0.1 and _eventsP1Index == 3 then _eventsP1Index = 1 end
		
			_lastUpdate1 = _curTime
		end
		
		-- run if there's processor time remaining
		
		if _watchDog >= 0.1 and _eventsRemIndex == 1 then _eventsRemIndex = 2 end		
		if _watchDog >= 0.1 and _eventsRemIndex == 2 then _eventsRemIndex = 1 end
		
	end

	EnKai.unit.subscribe("player.target")

	Command.Event.Attach(EnKai.events["EnKai.Unit"].Change, function(_, unit, unitType)
		if unitType == "player.target" then
			if unit ~= false then
				data.targetID = unit
				_eventUnitAdd (_, {[unit] = unitType})
			elseif data.targetID then
				_eventUnitRemove (_, {[data.targetID] = false})
			end
		end
	end, "nkUI.EnKai.Unit.Change")


	Command.Event.Attach(Event.System.Secure.Enter, _fctSecureEnter, "nkUI.Ssytem.Secure.Enter")
	Command.Event.Attach(Event.System.Secure.Leave, _fctSecureLeave, "nkUI.Ssytem.Secure.Leave")

    Command.Event.Attach(Event.Unit.Availability.Full, _unitAvailable, "nkUI.playerFrame.Unit.Availability.Full")    
    Command.Event.Attach(Event.Unit.Detail.Health, _eventHealth, "nkUI.playerFrame.Unit.Detail.Health")
    Command.Event.Attach(Event.Unit.Detail.HealthCap, _eventHealthCap, "nkUI.playerFrame.Unit.Detail.HealthCap")
    Command.Event.Attach(Event.Unit.Detail.HealthMax, _eventHealthMax, "nkUI.playerFrame.Unit.Detail.HealthMax")
    Command.Event.Attach(Event.Unit.Detail.Energy, _eventEnergy, "nkUI.playerFrame.Unit.Detail.Energy")
    Command.Event.Attach(Event.Unit.Detail.EnergyMax, _eventEnergyMax, "nkUI.playerFrame.Unit.Detail.EnergyMax")
	Command.Event.Attach(Event.Unit.Detail.Power, _eventPower, "nkUI.playerFrame.Unit.Detail.Power")    
	Command.Event.Attach(Event.Unit.Detail.Mana, _eventMana, "nkUI.playerFrame.Unit.Detail.Mana")    
	Command.Event.Attach(Event.Unit.Detail.Charge, _eventCharge, "nkUI.playerFrame.Unit.Detail.Charge")    
    Command.Event.Attach(Event.Unit.Detail.Planar, _eventPlanar, "nkUI.playerFrame.Unit.Detail.Planar")
	Command.Event.Attach(Event.Unit.Detail.Combo, _eventCombo, "nkUI.playerFrame.Unit.Detail.Combo")

	Command.Event.Attach(Event.Unit.Castbar, _eventCastBar, "nkUI.Unit.Castbar")

    Command.Event.Attach(Event.Buff.Add, _eventBuffAdd, "nkUI.Buff.Add")
	Command.Event.Attach(Event.Buff.Change, _eventBuffChange, "nkUI.Buff.Change")
	Command.Event.Attach(Event.Buff.Remove, _eventBuffRemove, "nkUI.Buff.Remove")

    Command.Event.Attach(Event.Unit.Add, _eventUnitAdd , "nkUI.playerFrame.Unit.Add")
    Command.Event.Attach(Event.Unit.Remove, _eventUnitRemove , "nkUI.playerFrame.Unit.Remove")

    Command.Event.Attach(Event.System.Update.Begin, _fctUpdateHandler, "nkUI.System.updateHandler")

	Command.Event.Attach(Event.Unit.Detail.Zone, _fctZoneEvent, "nkUI.Unit.Detail.Zone")

end