local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

---------- init local variables ---------

local stanceBuff = nil

---------- init variables ---------

data.activeCooldowns = {}

---------- local function block ---------

function _events.abBuffAdd (_, unit, info)

	if unit ~= EnKai.unit.getPlayerDetails().id then return end
	
	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_events.buffAdd") end
	
	for key, v in pairs(info) do
	
		if v == 'B109B81E0E0F231CF' or v == 'B55F770C673BE8384' then
			stanceBuff = key
			_internal.stanceActive(true)
			if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.buffRemove", debugId) end
			return
		end
		
	end
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.buffAdd", debugId) end

end

function _events.abBuffRemove (_, unit, info)

	if unit ~= EnKai.unit.getPlayerDetails().id then return end
	
	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_events.buffRemove") end

	for key, v in pairs(info) do
		
		if key == stanceBuff then
			stanceBuff = nil
			_internal.stanceActive(false)
			if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.buffRemove", debugId) end
			return
		end
		
	end
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.buffRemove", debugId) end

end

function _events.abAbilityUnusable(_, info)

	if data.abilityMap == nil then return end

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_events.abilityUnusable") end
	
	for key, v in pairs(info) do
		local details = Inspect.Ability.New.Detail(key)
	
		if data.abilityMap[key] ~= nil then
			for k, v in pairs(data.abilityMap[key]) do
				v:SetUsable(false)
			end
		 end
		
	end
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.abilityUnusable", debugId) end
	
end

function _events.abAbilityUsable(_, info)

	if data.abilityMap == nil then return end

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_events.abilityUsable") end
	
	for key, v in pairs(info) do
		if data.abilityMap[key] ~= nil then
			for k, v in pairs(data.abilityMap[key]) do
				v:SetUsable(true)
			end
		end
	end
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.abilityUsable", debugId) end
	
end

function _events.abAbilityOutOfRange (_, info)

	if data.abilityMap == nil then return end
	
	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_events.abilityOutOfRange") end

	for key, v in pairs(info) do
		if data.abilityMap[key] ~= nil then
			for k, v in pairs(data.abilityMap[key]) do
				v:SetOOR(true)
			end
		end
	end
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.abilityOutOfRange", debugId) end

end


function _events.abAbilityInRange (_, info)

	if data.abilityMap == nil then return end
	
	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_events.abilityInRange") end
	
	for key, v in pairs(info) do
		 if data.abilityMap[key] ~= nil then
			for _, frame in pairs(data.abilityMap[key]) do
				frame:SetOOR(false)
			end
		 end
		
	end
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.abilityInRange", debugId) end

end

function _events.abCooldownProcess (_, addon, info)

	if addon ~= addonInfo.identifier then return end

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_events.cooldownProcess") end

	local percent
  
	for key, details in pairs (info) do
	
		if data.abilityMap ~= nil and data.abilityMap[key] ~= nil then
			if details.remaining ~= nil then
				percent  = 1 / details.duration * details.remaining

				if details.remaining < 0 then
					for k, v in pairs(data.abilityMap[key]) do
						v:SetCooldown()  
					end
				elseif details.remaining <= 1 then
					--for k, v in pairs(data.abilityMap[key]) do
					--	v:Flicker()
					--end
					
					for k, v in pairs(data.abilityMap[key]) do
						v:SetCooldown(tostring(math.floor(details.remaining)), percent)
					end
				elseif details.remaining > 14400 then -- larger than 4h filter some stuff like stealth which has very loooooong cd
					for k, v in pairs(data.abilityMap[key]) do
						v:SetCooldown()  
					end
				elseif details.remaining > 3600 then
					for k, v in pairs(data.abilityMap[key]) do
						v:SetCooldown(tostring(math.floor(details.remaining / 3600)).."h", percent)
					end
				elseif details.remaining > 60 then
					for k, v in pairs(data.abilityMap[key]) do
						v:SetCooldown(tostring(math.floor(details.remaining / 60)).."m", percent)
					end
				else
					for k, v in pairs(data.abilityMap[key]) do
						v:SetCooldown(tostring(math.floor(details.remaining)), percent)
					end
				end
			else
				for k, v in pairs(data.abilityMap[key]) do
					v:SetCooldown()  
				end
			end
		end
	end  
  
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.cooldownProcess", debugId) end

end

function _events.abSecureEnter (_, info)

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_events.secureEnter") end

	_internal.combatHandler (false)
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.secureEnter", debugId) end

end

function _events.abSecureLeave (_, info)

	local debugId
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "_events.secureLeave") end

	for k, v in pairs(data.insecure) do
		v()
	end
	
	data.insecure = {}

	_internal.combatHandler (true)
	
	if nkDebug then nkDebug.traceEnd (addonInfo.identifier, "_events.secureLeave", debugId) end

end

function _events.abGcdStart (_, info)

	for key, remaining in pairs(info) do
		if data.abilityMap ~= nil and data.abilityMap[key] ~= nil then
			if remaining <= 1.5 then
				data.gcdActive = { flag = true, key = key}
				for k, v in pairs(data.abilityMap[key]) do
					v:SetGCD(remaining)
				end
			end
		end
	end
end

function _events.abSecureEnter()

	for k, v in pairs (uiElements.actionbars) do
        v:SetAlpha(nkUISetup.actionBarCombatAlpha)
    end

end

function _events.abSecureLeave()
	
	for k, v in pairs (uiElements.actionbars) do
        v:SetAlpha(nkUISetup.actionBarNonCombatAlpha)
    end

end