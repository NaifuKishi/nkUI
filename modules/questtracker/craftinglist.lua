local addonInfo, privateVars = ...

privateVars.have = {}
privateVars.craftItems = {}
privateVars.missingItemList = {}

privateVars.debug = false

function privateVars.internal.craftinglist (internalFlag)

	if internalFlag ~= true and privateVars.uiElements.craftingList:GetVisible() == true then 
		privateVars.uiElements.craftingList:SetVisible(false)
		return
	end

	local category = privateVars.uiElements.questLog:GetCategory('crafting')
	if category == nil then return end
	if category:GetQuestCount() == 0 then return end
	
	--privateVars.uiElements.missingList:SetVisible(false)
	
	local tmpQuestList = category:GetQuestList()
	
	local questList = {}

	for idx = 1, #tmpQuestList, 1 do
		questList[tmpQuestList[idx]] = true
	end
	
	local flag, details = pcall(Inspect.Quest.Detail, questList)
	
	if flag == false then return end
	
	local lookupList = {}
	
	privateVars.have = {}
	privateVars.craftItems = {}
  	privateVars.missingItemList = {}
	
	
	for questKey, v in pairs(details) do
		local count, dbData = nkQuestBase.query.byKey (questKey)
		
		if dbData ~= nil and dbData.craft ~= nil then
			for idx = 1, #dbData.craft, 1 do
			
				local key = dbData.craft[idx].key
				local toCraft = dbData.craft[idx].count
			
				if privateVars.have[key] == nil then privateVars.have[key] = EnKai.inventory.queryByKey (key) end
				
				local temp = Inspect.Item.Detail(key)
				if privateVars.debug == true then print ('===== ' .. temp.name .. " =====") end
        if privateVars.debug == true then print ('have ' .. privateVars.have[key] .. " - need " .. toCraft) end
				
				if privateVars.have[key] == nil or privateVars.have[key] < toCraft then
				
					local realNeed = toCraft
					if privateVars.have[key] ~= nil then					   
					   realNeed = realNeed - privateVars.have[key]
					   privateVars.have[key] = 0				
					   if privateVars.debug == true then print ("reducing need to " .. realNeed) end	
					end
										
					privateVars.internal.checkRecipe(key, realNeed, lookupList)
				else
				  if privateVars.debug == true then  print ("reducing available by " .. toCraft) end
					privateVars.have[key] = privateVars.have[key] - toCraft
					privateVars.craftItems[key] = true;
				end
			end			
		end
	end	
	
	local itemDetails = Inspect.Item.Detail(lookupList)
	
	local gridValues = {}

	for key, count in pairs (privateVars.missingItemList) do
			local details = itemDetails[key]
			if details == nil then details = Inspect.Item.Detail(key) end
			if details == nil then details = { name = "UNKNOWN KEY " .. key} end
			
			table.insert(gridValues, { {key = key, value = details.icon}, { value = details.name}, { value = count }}) 
	end

	table.sort (gridValues, function (v1, v2) return v1[2].value < v2[2].value end )
	
	local grid = privateVars.uiElements.craftingList:GetGrid() 
	
	grid:SetRowPos(1, false)
	grid:SetCellValues(gridValues)
	privateVars.uiElements.craftingList:SetVisible(true)
	
end

function privateVars.internal.checkRecipe(key, realNeed, lookupList)

   if privateVars.debug == true then print ('----- check recipe -----') end

  local recipes = nkRecipeBase.query.byResultRiftKey (key)
	
	if #recipes == 0 then
		if realNeed > privateVars.have[key] then
		  realNeed = realNeed - privateVars.have[key]		  
		  privateVars.have[key] = 0
		  lookupList[key] = true
		  
		  if privateVars.debug == true then print ('no sub recipe: have 0 left - need another ' .. realNeed) end
		else
		  privateVars.have[key] = privateVars.have[key] - realNeed
		  realNeed = 0
		  
		  if privateVars.debug == true then print ("no sub recipe: have all " .. privateVars.have[key] .. " needed" ) end
		end
		
		privateVars.craftItems[key] = true
		
		if realNeed > 0 and privateVars.missingItemList[key] == nil then
      privateVars.missingItemList[key] = realNeed
    else
      privateVars.missingItemList[key] = privateVars.missingItemList[key] + realNeed
    end
	else
		for idx2 = 1, #recipes, 1 do
			local recipeData = nkRecipeBase.query.byKey(recipes[idx2])
			
			if recipeData ~= nil then
				if recipeData.creates[1].count ~= 20 then -- filter bulk crafting recipes
					
					for _, ingredient in pairs(recipeData.ingredients) do
						
						local akey = ingredient.akey
						
						if privateVars.have[akey] == nil then privateVars.have[akey] = EnKai.inventory.queryByKey (akey) end
						
						local temp = Inspect.Item.Detail(akey)
						
						local thisRealNeed = ingredient.count * realNeed
						
						if privateVars.debug == true then print ('have ' .. privateVars.have[akey] .. ' of ' .. temp.name .. " - need " .. thisRealNeed) end
						if privateVars.have[akey] == nil or privateVars.have[akey] < thisRealNeed then
							
              if privateVars.have[akey] ~= nil then             
                thisRealNeed = thisRealNeed - privateVars.have[akey]
                privateVars.have[akey] = 0        
                if privateVars.debug == true then print ("reducing need to " .. thisRealNeed) end  
              end
                    
              privateVars.internal.checkRecipe(akey, thisRealNeed, lookupList)
						else
						  if privateVars.debug == true then print ("reducing available by " .. thisRealNeed) end
              privateVars.have[akey] = privateVars.have[akey] - thisRealNeed
              privateVars.craftItems[akey] = true;
						end
					end
				end
			else
				EnKai.tools.error.display (addonInfo.toc.Identifier, "Could not find recipe for [" .. recipes[idx2] .. "]", 3)
			end
		end 
	end
	
end

function privateVars.internal.craftingUI ()
	
	local name = "nkQuestTracker.craftingUI"
	local gridRows = math.floor(privateVars.uiElements.questLog:GetHeight() / 19)
	
	local ui = UI.CreateFrame("Frame", name, privateVars.uiElements.questLog)
	ui:SetWidth(300)
	ui:SetHeight(privateVars.uiElements.questLog:GetHeight())
	ui:SetPoint("TOPRIGHT", privateVars.uiElements.questLog, "TOPLEFT")
	ui:SetBackgroundColor(0, 0, 0, nkQuestTrackerSetup.bgAlpha)
	ui:SetVisible(false)	
	
	local grid = EnKai.uiCreateFrame("nkGrid", name .. 'grid', ui)
		
	grid:SetHeaderHeight(0)
	grid:SetPoint("TOPLEFT", ui, "TOPLEFT")
	--grid:SetHeaderLabelColor(0.925, 0.894, 0.741, 1)
	grid:SetBorderColor(0, 0, 0, nkQuestTrackerSetup.bgAlpha)
	
	if (nkQuestTrackerSetup.bgAlpha-0.2 < 0) then
		grid:SetBodyColor(0, 0, 0, 0)
	else
	  grid:SetBodyColor(0, 0, 0, nkQuestTrackerSetup.bgAlpha-0.2)
	end
	
	grid:SetTransparentHeader()
		
	local cols = {	{ align = 'center', texture = true, textureType = 'Rift', textureHeight = 14, textureWidth = 14, width = 20,  },
						{ align = 'left', width = 255}, 
						{ align = 'center', width = 25} }	
	
	grid:Layout (cols, gridRows)
	
	function ui:GetGrid() return grid end
	
	Command.Event.Attach(EnKai.events["EnKai.InventoryManager"].Update, function (_, updates)
		
		if ui:GetVisible() == false then return end
		
		for k, change in pairs (updates) do		
			if change ~= 0 then			
				if privateVars.craftItems[k] ~= nil then
					privateVars.internal.craftinglist (true)
					return
				end				
			end
		end	
	end, "EnKai.InventoryManager.Update")
	
	return ui	

end