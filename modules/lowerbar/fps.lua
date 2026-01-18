local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local lowerBar      = privateVars.lowerBar

---------- init local variables ---------

local inspectTimeFrame = Inspect.Time.Frame
local inspectAddonCpu  = Inspect.Addon.Cpu

local stringFormat      = string.format

---------- local functions ---------

-- Creates and manages the FPS display
function lowerBar.fps()

    local datasetFPS = LibEKL.UICreateFrame('nkText', "lowerBar.fps", lowerBar.contextRestricted)
    datasetFPS:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMLEFT", (data.aFourth - 10), -5)
    datasetFPS:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetFPS:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetFPS:SetTextFont(addonInfo.id, "Montserrat")
    datasetFPS:SetEffectGlow({ strength = 1})
    datasetFPS:SetLayer(10)

    datasetFPS:SetSecureMode('restricted')
	datasetFPS:EventMacroSet(Event.UI.Input.Mouse.Left.Click, "/nkd")

    local datasetFPSIcon = LibEKL.UICreateFrame("nkTexture", "lowerBar.fps.icon", datasetFPS)
    datasetFPSIcon:SetPoint("CENTERRIGHT", datasetFPS, "CENTERLEFT", -5, 0)
    datasetFPSIcon:SetHeight(16)
    datasetFPSIcon:SetWidth(16)
    datasetFPSIcon:SetTextureAsync("nkUI", "gfx/lowerbarFPS.png")
    
    function datasetFPS:Redraw()
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
            datasetFPS:SetText(stringFormat("%d fps | %d%% CPU", frameCount / fpsTimer, total * 100))
            frameCount, fpsTimer = 0, 0
        end

        fpsUpdateTime = now
        
    end
    
    Command.Event.Attach(Event.System.Update.Begin, updateFPS, "nkUI.lowerbar.fps.System.Update.Begin")
    
    table.insert(uiElements.lowerBarModules, datasetFPS)
end