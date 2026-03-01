local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local lowerBar      = privateVars.lowerBar

---------- init local variables ---------

local inspectTimeFrame = Inspect.Time.Frame
local inspectAddonCpu  = Inspect.Addon.Cpu

local stringFormat      = string.format

local lastTotal, lastFPS, lastIcon

---------- local functions ---------

-- Creates and manages the FPS display
function lowerBar.fps()

    local name = "lowerBar.datasetfps"
    local height = uiElements.lowerBarCanvas:GetHeight()
    local width = 120

    local datasetFrame = lowerBar.dataSet("lowerBar.datasetfps", "gfx/lowerbarFPS.png", "left")

    if nkDebug then
	    datasetFrame:EventMacroSet(Event.UI.Input.Mouse.Left.Click, "/nkd")
    end

    function datasetFrame:Redraw()
        datasetFrame:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    end
    
    local fpsUpdateTime, fpsDeltaTime = nil, nil
    local frameCount, fpsTimer = 0, 0
    
    local function updateFPS()
        local now = inspectTimeFrame()
        local lastFrame = fpsUpdateTime or now
        local total = 0
        
        fpsDeltaTime = now - lastFrame
        fpsTimer = fpsTimer + fpsDeltaTime
        frameCount = frameCount + 1

        for k, v in pairs(inspectAddonCpu()) do
            for det, usage in pairs(v) do
                total = total + usage
            end
        end
        
        if (fpsTimer > 1) then
            if newFPS ~= lastFPS or total ~= lastTotal then
                local newFPS = frameCount / fpsTimer

                local fpsColor = "#E8C23B"
                local icon = "gfx/lowerbarFPS.png"

                if newFPS < 30 then
                    fpsColor = "#E84545"
                    icon = "gfx/lowerbarFPSBad.png"
                elseif newFPS >= 100 then
                    fpsColor = "#22B357"
                    icon = "gfx/lowerbarFPSGood.png"
                end

                local cpuColor = "#E8C23B"
                if total <= .25 then
                    cpuColor = "#22B357"
                elseif  total >= .50 then
                    cpuColor = "#E84545"
                end

                if icon ~= lastIcon then
                    datasetFrame:SetTextureAsync(icon)
                end

                datasetFrame:SetText(stringFormat("<font color='%s'>%d fps</font> | <font color='%s'>%d%% CPU</font>", fpsColor, newFPS, cpuColor, total * 100), true)
                frameCount, fpsTimer = 0, 0
                lastFPS = newFPS
                lastTotal = total
            end
        end

        fpsUpdateTime = now
        
    end
    
    Command.Event.Attach(Event.System.Update.Begin, updateFPS, "nkUI.lowerbar.fps.System.Update.Begin")
        
    return datasetFrame

end