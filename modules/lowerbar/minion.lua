local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local lowerBar      = privateVars.lowerBar
local langTexts     = privateVars.langTexts

---------- init local variables ---------

local inspectMinionSlot      = Inspect.Minion.Slot
local inspectAdventureList   = Inspect.Minion.Adventure.List
local inspectAdventureDetail = Inspect.Minion.Adventure.Detail
local eventMinionAdvChange   = Event.Minion.Adventure.Change

local stringFormat  = string.format
local pairs         = pairs
local pcall         = pcall
local tostring      = tostring

---------- local functions ---------

function lowerBar.minion()

    local datasetFrame = lowerBar.dataSet("lowerBar.datasetMinion", "gfx/lowerbarMinion.png", "right")

    function datasetFrame:Redraw()
        datasetFrame:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    end

    -- Cache updated outside hardware events (pcall not allowed inside hardware event handlers)
    local cachedFinishedIds = {}

    local function refreshDisplay()
        cachedFinishedIds = {}
        local totalSlots = inspectMinionSlot() or 0
        local working, finished = 0, 0

        local ok1, advIds = pcall(inspectAdventureList)
        if not ok1 or advIds == nil then advIds = {} end

        local ok2, advDetails = pcall(inspectAdventureDetail, advIds)
        if ok2 and advDetails then
            for id, adv in pairs(advDetails) do
                local mode = adv.mode or "none"
                if mode == "working" then
                    working = working + 1
                elseif mode == "finished" then
                    finished = finished + 1
                    cachedFinishedIds[#cachedFinishedIds + 1] = id
                end
            end
        end

        local free = totalSlots - working - finished
        local text = stringFormat(
            "<font color='#22B357'>%d</font> | <font color='#E8C23B'>%d</font> | <font color='#E84545'>%d</font>",
            free, working, finished)
        datasetFrame:SetText(text)
    end

    datasetFrame:EventAttach(Event.UI.Input.Mouse.Left.Up, function ()
        if #cachedFinishedIds > 0 then
            for i = 1, #cachedFinishedIds do
                Command.Minion.Claim(cachedFinishedIds[i])
                break
            end
        else
            local mm = privateVars.minionManager
            if mm and mm.autoSend then
                mm.autoSend()
            end
        end
    end, "nkUI.lowerbar.minion.Left.Up")

    datasetFrame:EventAttach(Event.UI.Input.Mouse.Right.Up, function()
        internalFunc.minionManagerInit()
    end, "nkUI.lowerbar.minion.Right.Up")

    -- Update on adventure change events
    Command.Event.Attach(eventMinionAdvChange, function()
        refreshDisplay()
    end, "nkUI.lowerbar.minion.Adventure.Change")

    -- Poll the first 5 seconds after login (like MinionSender) until server data arrives
    local initTicks = 0
    LibEKL.Events.AddPeriodic(function()
        initTicks = initTicks + 1
        refreshDisplay()
        if initTicks >= 5 then return true end  -- return true stops the periodic
    end, 1)

    return datasetFrame

end
