local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc

privateVars.minionManager = {}
local minionManager = privateVars.minionManager

---------- init local variables ---------

local inspectSystemSecure   = Inspect.System.Secure
local inspectTimeReal       = Inspect.Time.Real
local inspectTimeFrame      = Inspect.Time.Frame
local eventMinionAdvChange  = Event.Minion.Adventure.Change

local isInit        = false
local _timerUuid    = nil

minionManager.context = UI.CreateContext("nkUI.minionManager")
minionManager.context:SetStrata('hud')
minionManager.context:SetLayer(5)

---------- addon internalFunc function block ---------

function internalFunc.minionManagerInit()

    if inspectSystemSecure() then return end

    if uiElements.minionManager == nil then
        internalFunc.uiMinionManager()
    elseif isInit then
        uiElements.minionManager:SetVisible(not uiElements.minionManager:GetVisible())
    end

end

function internalFunc.uiMinionManager()

    -- Register the event namespace
    LibEKL.Events.CheckEvents("minionManager", true)

    Command.System.Watchdog.Quiet()

    minionManager.buildUI()
    minionManager.populate()

    Command.Event.Attach(eventMinionAdvChange, function()
        if not (uiElements.minionManager and uiElements.minionManager:GetVisible()) then return end
        -- Small delay so the RIFT API has time to update adventure data
        -- (e.g. after a hurry the mode/completion may not reflect immediately)
        LibEKL.Events.AddInsecure(function()
            minionManager.populate()
        end, inspectTimeFrame(), 0.5)
    end, "nkUI.minionManager.Adventure.Change")

    isInit = true

    if _timerUuid then
        LibEKL.Events.RemoveInsecure(_timerUuid)
        _timerUuid = nil
    end

    _timerUuid = LibEKL.Events.AddPeriodic(function()
        if uiElements.minionManager and uiElements.minionManager:GetVisible() then
            minionManager.refreshActiveMissions()
        end
    end, 1)

end
