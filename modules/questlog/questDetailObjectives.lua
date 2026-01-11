local addonInfo, privateVars = ...

---------- init namespace ---------

local questLog		= privateVars.questLog
local uiElements	= privateVars.uiElements
local data			= privateVars.data
local langTexts		= privateVars.langTexts

local objectives = {}

local DEFAULT_OBJECTIVE_SIZE = 14

local function objectiveElement (name, parent)

    local objectiveIcon = LibEKL.UICreateFrame("nkTexture", name, parent)
    objectiveIcon:SetWidth(DEFAULT_OBJECTIVE_SIZE)
    objectiveIcon:SetHeight(DEFAULT_OBJECTIVE_SIZE)
    
    local objectiveText = LibEKL.UICreateFrame("nkText", name .. ".text", parent)
    objectiveText:SetPoint("CENTERLEFT", objectiveIcon, "CENTERRIGHT", 10, 0)
    objectiveText:SetWidth(parent:GetWidth() - DEFAULT_OBJECTIVE_SIZE - 10 - 20)
    objectiveText:SetWordwrap(true)
    objectiveText:SetFontSize(DEFAULT_OBJECTIVE_SIZE)
    objectiveText:SetEffectGlow({ strength = 3})

    LibEKL.UI.SetFont(objectiveText, addonInfo.id, "MontserratSemiBold")

    function objectiveIcon:SetComplete(isComplete)
        if isComplete then
            objectiveIcon:SetTextureAsync("nkUI", "gfx/questIconComplete.png")
            objectiveText:SetFontColor(0.18, .722, .404, 1)
        else
            objectiveIcon:SetTextureAsync("nkUI", "gfx/questIconIncomplete.png")
            objectiveText:SetFontColor(0.765, .757, .733, 1)
        end 
    end

    function objectiveIcon:SetText(newText)
        objectiveText:SetText(newText)
    end

    local oSetVisible = objectiveIcon.SetVisible

    function objectiveIcon:SetVisible(newFlag)
        oSetVisible(self, newFlag)
        objectiveText:SetVisible(newFlag)
    end

    return objectiveIcon

end

function questLog.uiObjectives (name, parent)

    local objectivesFrame = questLog.uiBox (name .. ".objectives", parent)	
	objectivesFrame:SetTitle(langTexts.questLog.objectives)

    function objectivesFrame:AddObjectives(objectiveList)

   		for _, objective in ipairs(objectives) do            
			objective:SetVisible(false)
		end

        -- Update objectives
		local prevObjective, height = objectivesFrame:GetTitle(), 0
		for i, objective in ipairs(objectiveList or {}) do
			
            local objectiveText

			if i > #objectives then
				objectiveText = objectiveElement(name .. ".objective"..i, objectivesFrame)
				table.insert(objectives, objectiveText)
			else
				objectiveText = objectives[i]				
			end            

            objectiveText:SetVisible(true)
			objectiveText:SetPoint("TOPLEFT", prevObjective, "BOTTOMLEFT", 0, 10)

			-- Extract and remove count from description if present
			local description = objective.description or ""
			local countText = ""
			local cleanDescription = description:gsub("(%d+)/(%d+)", function(a, b)
				countText = string.format("[%d/%d]", a, b)
				return ""
			end)

            objectiveText:SetComplete(objective.complete)
			objectiveText:SetText(cleanDescription)
            height = height + objectiveText:GetHeight() + 10

			prevObjective = objectiveText
		end

        height = height + 45 -- 30 as default for uiFrame
        objectivesFrame:SetHeight(height)

    end

    return objectivesFrame

end

