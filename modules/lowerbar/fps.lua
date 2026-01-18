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
    local width = (uiElements.lowerBarCanvas:GetWidth() - uiElements.lowerBarTimeDate:GetWidth()) /8
    local height = uiElements.lowerBarCanvas:GetHeight()

    local datasetFrame = LibEKL.UICreateFrame("nkFrame", name .. ".frame", lowerBar.contextRestricted)
    datasetFrame:SetWidth(width)
    datasetFrame:SetHeight(height)
    datasetFrame:SetPoint("CENTERLEFT", uiElements.lowerBarCanvas, "CENTERLEFT", width, 0)    
    --datasetFrame:SetBackgroundColor(1, 0, 1, 1)
    datasetFrame:SetLayer(2)

    local datasetFPS = LibEKL.UICreateFrame('nkText', name .. ".text", lowerBar.contextRestricted)
    datasetFPS:SetPoint("CENTER", datasetFrame, "CENTER", -21, 0)
    datasetFPS:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetFPS:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetFPS:SetTextFont(addonInfo.id, "MontserratMedium")
    datasetFPS:SetEffectGlow({ strength = 1})
    datasetFPS:SetLayer(5)

    datasetFPS:SetSecureMode('restricted')
	datasetFPS:EventMacroSet(Event.UI.Input.Mouse.Left.Click, "/nkd")

    local datasetFPSIcon = LibEKL.UICreateFrame("nkTexture", name .. ".icon", datasetFrame)
    datasetFPSIcon:SetPoint("CENTERRIGHT", datasetFPS, "CENTERLEFT", -5, 0)
    datasetFPSIcon:SetHeight(16)
    datasetFPSIcon:SetWidth(16)
    datasetFPSIcon:SetTextureAsync("nkUI", "gfx/lowerbarFPS.png")
    
    function datasetFrame:Redraw()
        datasetFPS:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
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
                if total <= .20 then
                    cpuColor = "#22B357"
                elseif  total >= .30 then
                    cpuColor = "#E84545"
                end

                if icon ~= lastIcon then
                    datasetFPSIcon:SetTextureAsync("nkUI", icon)
                end

                datasetFPS:SetText(stringFormat("<font color='%s'>%d fps</font> | <font color='%s'>%d%% CPU</font>", fpsColor, newFPS, cpuColor, total * 100), true)
                frameCount, fpsTimer = 0, 0
                lastFPS = newFPS
                lastTotal = total
            end
        end

        fpsUpdateTime = now
        
    end
    
    Command.Event.Attach(Event.System.Update.Begin, updateFPS, "nkUI.lowerbar.fps.System.Update.Begin")
    
    table.insert(uiElements.lowerBarModules, datasetFrame)
end