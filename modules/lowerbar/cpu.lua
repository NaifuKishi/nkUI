local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local lowerBar      = privateVars.lowerBar

---------- init variables ---------

local inspectAddonCpu	= Inspect.Addon.Cpu
local inspectTimeFrame  = Inspect.Time.Frame

local stringFormat		= string.format

---------- addon internal function block ---------

function plugins.cpu ()
	
	local updateTime = nil
		
	local function updateCPU()
	
		local now = inspectTimeFrame()

		if not updateTime or now - updateTime > 1 then
			updateTime = now
			local total = 0

			for k, v in pairs(inspectAddonCpu()) do
				for det, usage in pairs(v) do
					total = total + usage
				end
			end

			plugin:SetTitle(stringFormat(privateVars.langTexts.plugins.cpu, total * 100))
		end
	end
	
	Command.Event.Attach(Event.System.Update.Begin, updateCPU, "nkPanel.cpu.System.Update.Begin")
	
end