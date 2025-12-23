local addonInfo, privateVars = ...

---------- init namespace ---------

local internal		= privateVars.internal
local uiElements	= privateVars.uiElements
local data			= privateVars.data

---------- init local variables ---------

local colorR, colorG, colorB, colorA = 0.9, 0.74, 0, 1

---------- init variables ---------

---------- local function block ---------

---------- addon internal function block ---------

function internal.buildAreaQuestUI ()

	local name = "nkQuestTracker.AreaQuestUI"
	local thisKey = nil
	
	local ui = EnKai.uiCreateFrame("nkWindowElement", name, uiElements.context)
	
	ui:SetReverseAtBorder(false)
	ui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", nkQuestTrackerSetup.areaquestui.xpos, nkQuestTrackerSetup.areaquestui.ypos)
	ui:SetWidth(nkQuestTrackerSetup.areaquestui.width)
	ui:SetBackgroundColor(0, 0, 0, nkQuestTrackerSetup.bgAlpha)	
	ui:SetLayer(1)
	ui:SetTitleFont(addonInfo.id, "Montserrat")
	ui:SetTitle(privateVars.langTexts.areaQuestUIHeader)
	ui:SetTitleColor(1, 1 ,1 ,1)
	ui:SetTitleAlign("left", 40)
	ui:SetCloseable(false)
	ui:ShowMoveToggle(true)
	ui:SetDragable(nkQuestTrackerSetup.areaquestui.moveable)
	ui:SetCollapseable(true)
	ui:DisplayHeader(nkQuestTrackerSetup.displayHeader)
	ui:SetFontSize(14)

	ui:GetHeader():SetBackgroundColor(0, 0, 0, nkQuestTrackerSetup.bgAlpha)	
	ui:SetTitleColor(colorR, colorG, colorB, colorA)
	ui:SetArrowTextures("nkQuestTracker", "gfx/windowModernArrowRight.png", "gfx/windowModernArrowDown.png")
	ui:GetMoveCheckbox():SetColor(colorR, colorG, colorB, colorA)	
	
	Command.Event.Attach(EnKai.events[name].Moved, function (_, xpos, ypos)
		nkQuestTrackerSetup.areaquestui.xpos = xpos
		nkQuestTrackerSetup.areaquestui.ypos = ypos
	end, name .. '.Moved')
	
	Command.Event.Attach(EnKai.events[name].Dragable, function (_, dragable)
		nkQuestTrackerSetup.areaquestui.moveable = dragable
	end, name .. '.Dragable')
	
	thisEntry = internal.questEntry("areaquest", ui:GetContent(), EnKai.tools.uuid())
	thisEntry:SetPoint("TOPLEFT", ui:GetContent(), "TOPLEFT")
	thisEntry:SetTitleColor ({1,1,1,1})
	thisEntry:SetTitleFontSize (14)
	thisEntry:SetBodyFontSize (12)
	thisEntry:SetBodyColor ({0,0,0,1})
	
	------------ Quest methods ------------
	
	function ui:AddQuest(key, questCategory, title, objectives, complete, level, zone)
		
		if thisKey ~= nil and thisKey ~= key then ui:RemoveQuest(thisKey) end
		
		thisEntry:SetTitle(title)

		if complete ~= true then
			for k, v in pairs(objectives) do
				thisEntry:AddObjective(v.description, v.count, v.countDone, v.complete)
			end
		end

		thisEntry:RecalcHeight()
		thisEntry:SetVisible(true)
		
		ui:SetHeight(thisEntry:GetHeight() + ui:GetHeader():GetHeight())
		ui:SetWidth(thisEntry:GetWidth())
		ui:SetVisible(true)
		
		thisKey = key
		
	end	
	
	function ui:RemoveQuest(key)
		
		if key ~= thisKey then return end
		
		thisEntry:SetVisible(false)
		thisEntry:ClearAllObjectives()
		ui:SetVisible(false)

		thisKey = nil
		
	end
	
	function ui:UpdateQuest(key, questCategory, title, objectives, complete, level)
	
		if key ~= thisKey then return end
	
		if thisEntry:GetTitle() ~= title then thisEntry:SetTitle(title) end

		if complete ~= true then
			thisEntry:ClearAllObjectives()
            for k, v in pairs(objectives) do              
				thisEntry:AddObjective(v.description, v.count, v.countDone, v.complete)
			end
        else
			thisEntry:ClearAllObjectives()
		end

		thisEntry:RecalcHeight()
		
		ui:SetHeight(thisEntry:GetHeight() + ui:GetHeader():GetHeight())
		ui:SetWidth(thisEntry:GetWidth())
	
	end
	
	-- function ui:CompleteQuest(key) -- vermutlich nicht mehr in Gebrauch
		
		-- if key ~= thisKey then return end
		
		-- thisEntry:ClearAllObjectives()
        -- thisEntry:RecalcHeight()
		
	-- end

	ui:SetVisible(false)
	
	return ui

end