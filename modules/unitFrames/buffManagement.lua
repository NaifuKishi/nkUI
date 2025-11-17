local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

---------- init local variables ---------

-- Cache frequently used functions and values
local InspectUnitDetail     = Inspect.Unit.Detail
local InspectBuffDetail     = Inspect.Buff.Detail
local InspectUnitLookup     = Inspect.Unit.Lookup
local InspectBuffList       = Inspect.Buff.List

local mathFloor     = math.floor
local stringFormat  = string.format

---------- init global variables ---------

-- Buff management function

function _internal.manageBuffs(frame, unitId, buffUnit, buffs, action)

    -- Buff management variables
    local unitBuffIcons = frame:GetBuffIcons() or {}
    local unitDebuffIcons = frame:GetDebuffIcons() or {}
    local unitBuffDisplayList = frame:GetBuffDisplayList() or {}
    local unitDebuffDisplayList = frame:GetDebuffDisplayList() or {}

    local function updateBuffDisplay()
        local from, to, object, x, y = "BOTTOMLEFT", "TOPLEFT", frame, 0, -25
        local lastIcon
        local firstBuffIcon = frame

        for idx = 1, #unitBuffDisplayList do
            local icon = unitBuffIcons[unitBuffDisplayList[idx]].icon
            icon:ClearAll()
            icon:ClearPoint("BOTTOMLEFT")
            icon:SetPoint(from, object, to, x, y)
            icon:SetScale(.7 * frame:GetScale())
            lastIcon = icon
            from, to, object, x, y = "TOPLEFT", "TOPRIGHT", lastIcon, 2, 0

            if idx == 1 then firstBuffIcon = icon end
        end

        from, to, object, x, y = "TOPLEFT", "BOTTOMLEFT", frame, 0, 10
        lastIcon = nil

        for idx = 1, #unitDebuffDisplayList do
            local icon = unitDebuffIcons[unitDebuffDisplayList[idx]].icon
            if icon then
                icon:ClearAll()
                icon:SetPoint(from, object, to, x, y)
                icon:SetScale(.7 * frame:GetScale())
                lastIcon = icon
                from, to, object, x, y = "TOPLEFT", "TOPRIGHT", lastIcon, 5, 0
            end
        end
    end

    if action == "add" then
        if buffUnit == unitId then
            local details = InspectBuffDetail(buffUnit, buffs)

            for k, v in pairs(details) do
                if (v.remaining and v.remaining < 60) then
                    if v.poison == true or v.curse == true or v.disease == true or v.debuff == true then
                        if EnKai.tools.table.isMember(unitDebuffDisplayList, k) == false then
                            table.insert(unitDebuffDisplayList, k)

                            if unitDebuffIcons[k] == nil then
                                -- Use the icon manager to get an icon
                                local icon = _internal.iconManager.get(frame:GetUnitID(), "debuffIcon." .. k, .7 * frame:GetScale(), 0, 0)
                                unitDebuffIcons[k] = {
                                    icon = icon,
                                    visible = true,
                                    details = v
                                }
                                unitDebuffIcons[k].icon:SetBuff(buffUnit, k)
                                unitDebuffIcons[k].icon:SetEffect(privateVars.effects.gloss)
                                unitDebuffIcons[k].icon:ShowBorder(true)
                            else
                                unitDebuffIcons[k].details = details
                                unitDebuffIcons[k].visible = true
                            end

                            if v.poison then
                                unitDebuffIcons[k].icon:SetBorderColor(0, 1, 0, 1)
                            elseif v.curse then
                                unitDebuffIcons[k].icon:SetBorderColor(0, 1, 0, 1)
                            elseif v.disease then
                                unitDebuffIcons[k].icon:SetBorderColor(0.85, 0.85, 0, 1)
                            elseif v.debuff then
                                unitDebuffIcons[k].icon:SetBorderColor(0, 1, 0, 1)
                            end

                            unitDebuffIcons[k].icon:SetTexture("Rift", v.icon)
                            unitDebuffIcons[k].icon:SetVisible(true)
                        end
                    else
                        if EnKai.tools.table.isMember(unitBuffDisplayList, k) == false then
                            table.insert(unitBuffDisplayList, k)

                            if unitBuffIcons[k] == nil then
                                -- Use the icon manager to get an icon
                                local icon = _internal.iconManager.get(frame:GetUnitID(), "buffIcon." .. k, .7 * frame:GetScale(), 0, 0)
                                unitBuffIcons[k] = {
                                    icon = icon,
                                    visible = true,
                                    details = v
                                }
                                unitBuffIcons[k].icon:SetBuff(buffUnit, k)
                                unitBuffIcons[k].icon:SetEffect(privateVars.effects.gloss)
                                unitBuffIcons[k].icon:ShowBorder(true)
                            else
                                unitBuffIcons[k].details = details
                                unitBuffIcons[k].visible = true
                            end

                            unitBuffIcons[k].icon:SetTexture("Rift", v.icon)
                            unitBuffIcons[k].icon:SetVisible(true)
                        end
                    end
                end
            end
        end

        updateBuffDisplay()
    elseif action == "change" then
        -- Handle buff changes if needed
    elseif action == "clear" then
        for k, v in pairs(unitBuffIcons) do
            v.visible = false
            v.icon:SetVisible(false)
        end

        for k, v in pairs(unitDebuffIcons) do
            v.visible = false
            v.icon:SetVisible(false)
        end

        unitBuffDisplayList = {}
        unitDebuffDisplayList = {}
    elseif action == "remove" then
        if buffUnit == unitId then
            for id, v in pairs(buffs) do
                if unitBuffIcons[id] then
                    unitBuffIcons[id].visible = false
                    unitBuffIcons[id].icon:SetVisible(false)
                    EnKai.tools.table.removeValue(unitBuffDisplayList, id)
                elseif unitDebuffIcons[id] then
                    unitDebuffIcons[id].visible = false
                    unitDebuffIcons[id].icon:SetVisible(false)
                    EnKai.tools.table.removeValue(unitDebuffDisplayList, id)
                end
            end
        end

        updateBuffDisplay()
    end    

    -- Update frame's buff management data
    frame:SetBuffIcons(unitBuffIcons)
    frame:SetDebuffIcons(unitDebuffIcons)
    frame:SetBuffDisplayList(unitBuffDisplayList)
    frame:SetDebuffDisplayList(unitDebuffDisplayList)

end


function _internal.processBuffs ()

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

		local thisUnit = InspectUnitLookup(data.targetID)
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