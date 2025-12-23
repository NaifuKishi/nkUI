local addonInfo, privateVars = ...

---------- init namespace ---------

local internal		= privateVars.internal
local uiElements	= privateVars.uiElements

local oInspectQuestDetail	= Inspect.Quest.Detail
local oInspectUnitDetail	= Inspect.Unit.Detail
local oInspectSystemSecure	= Inspect.System.Secure
local oInspectQuestComplete	= Inspect.Quest.Complete

---------- init local variables ---------

local colorR, colorG, colorB, colorA = 0.9, 0.74, 0, 1

---------- init variables ---------

---------- local function block ---------

---------- addon internal function block ---------

function internal.missingList ()

	if uiElements.missingList:GetVisible() == true then 
		uiElements.missingList:SetVisible(false)
		return
	end

	local playerDetails = oInspectUnitDetail('player')
	local list = nkQuestBase.query.getQuestsByZone(playerDetails.zone)
	
	if list == nil then
		uiElements.missingList:SetVisible(false)
		return
	end

	--uiElements.craftingList:SetVisible(false)

	if oInspectSystemSecure() == false then Command.System.Watchdog.Quiet() end

	local complete = oInspectQuestComplete()

	local questList = {}

	for _, questId in pairs (list) do
		table.insert(questList, questId)   
	end 

	local tempList = {}
	local queryList = {}
	local count = 0

	uiElements.progressBar:SetRange(1, #questList)
	uiElements.progressBar:SetValue(1)
	uiElements.progressBar:SetVisible(true)

	local gridValues = {}

	local missingCoRoutine = coroutine.create(
		function ()
			for idx = 1, #questList, 1 do
				uiElements.progressBar:SetValue(idx)

				local questId = questList[idx]

				if complete[questId] == nil then
					local abbrev = string.format("%sxxxxxxxx", string.sub(questId, 1, 8))
					
					if complete[abbrev] == nil then
						local lvl, libDetails = nkQuestBase.query.byKey(questId, false)
						
						if libDetails ~= nil and libDetails.domain ~= "ia" then
							local detailsList = oInspectQuestDetail({[questId]=true})
							for key, details in pairs(detailsList) do   
								if details.domain ~= 'ia' and details.name ~= "" then
									local level = internal.processQuest(details, false)
									local domainText = privateVars.langTexts.showCategoryCheckbox[details.domain]
									table.insert(gridValues, { {key = key, value = string.gsub(details.name, "[\n\r]", "")}, { value = level }, { value = domainText } })
								end
							end 
						end       
					end
				end   

				coroutine.yield(idx)
			end
		end
	)

	local callBack = function ()
		uiElements.progressBar:SetVisible(false) 
		table.sort (gridValues, function (v1, v2) return v1[1].value < v2[1].value end )

		local grid = uiElements.missingList:GetGrid() 

		grid:SetRowPos(1, false)
		grid:SetCellValues(gridValues)
		uiElements.missingList:SetVisible(true)

		if #gridValues > 30 then
			uiElements.missingList:GetSlider():SetVisible(true)
			uiElements.missingList:GetSlider():SetRange(1, #gridValues-29)
			uiElements.missingList:GetSlider():AdjustValue(1)
		else
			uiElements.missingList:GetSlider():SetVisible(false)
		end 
	end

	EnKai.coroutines.add ({ func = missingCoRoutine, counter = #questList, active = true, callBack = callBack })

end

function internal.missingUI ()
	
	local name = "nkQuestTracker.missingUI"
	local gridRows = math.floor(uiElements.questLog:GetHeight() / 19)
	local slider
	
	local ui = EnKai.uiCreateFrame("nkWindowMetro", name, uiElements.configContext)
	ui:SetWidth(400)
	--ui:SetHeight(527)
	ui:SetPoint("TOPRIGHT", uiElements.questLog, "TOPLEFT")
	ui:SetTitle(privateVars.langTexts.missingQuests)
	ui:SetTitleFont(addonInfo.id, "Montserrat")
	ui:SetTitleAlign("left", 0)
	ui:SetTitleFontColor(colorR, colorG, colorB, colorA)
	ui:SetVisible(false)		
	
	local grid = EnKai.uiCreateFrame("nkGrid", name .. 'grid', ui:GetContent())
		
	grid:SetFont (addonInfo.id, "Montserrat")
	grid:SetHeaderHeight(0)
	grid:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT", 0, 0)
	grid:SetBorderColor(0, 0, 0, nkQuestTrackerSetup.bgAlpha)
	
	if nkQuestTrackerSetup.bgAlpha-0.2 < 0 then
		grid:SetBodyColor(0, 0, 0, 0)
	else
	  grid:SetBodyColor(0, 0, 0, nkQuestTrackerSetup.bgAlpha-0.2)
	end
	
	grid:SetTransparentHeader()
		
	local cols = {	{ align = 'left', width = 300},
						{ align = 'center', width = 25},
						{ align = 'center', width = 75}  }	
	
	grid:Layout (cols, gridRows)
	
	Command.Event.Attach(EnKai.events[name .. 'grid'].MouseOver, function (_, rowPos)
		local ttRowPos = grid:GetRowPos() + rowPos -1
		local key = grid:GetKey(ttRowPos)
		if key ~= nil then internal.showTooltip(grid:GetCell(rowPos, 1), key, nil, nil, nil) end
	end, name .. 'grid.Grid.MouseOver')
	
	Command.Event.Attach(EnKai.events[name .. 'grid'].MouseOut, function (_, rowPos)			
		if uiElements.tooltip ~= nil then uiElements.tooltip:SetVisible(false) end
	end, name .. 'grid.Grid.MouseOut')
	
	Command.Event.Attach(EnKai.events[name .. 'grid'].WheelForward, function (_, rowPos)			
		slider:AdjustValue (rowPos)
	end, name .. 'grid.Grid.WheelForward')
	
	Command.Event.Attach(EnKai.events[name .. 'grid'].WheelBack, function (_, rowPos)
		slider:AdjustValue (rowPos)
	end, name .. 'grid.Grid.WheelBack')
	
	slider = EnKai.uiCreateFrame("nkScrollbox", name .. "slider", grid)	
		
	slider:SetPoint("TOPLEFT", grid, "TOPRIGHT", -14, 0)
	slider:SetHeight(grid:GetHeight())
	slider:SetRange(1, 1)
	slider:SetVisible(false)
	slider:SetLayer(2)
	slider:SetColor( 1,1,1,1 )
	
	Command.Event.Attach(EnKai.events[name .. "slider"].ScrollboxChanged, function ()		
		grid:SetRowPos(math.floor(slider:GetValue('value')), true)
	end, name .. 'slider.ScrollboxChanged')
	
	ui:SetHeight(grid:GetHeight()+30)

	function ui:GetGrid() return grid end
	function ui:GetSlider() return slider end

	return ui

end