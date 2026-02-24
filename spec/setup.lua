-- Test setup and mocks for nkUI
-- This file provides mock implementations of Rift API and LibEKL functions

local _G = _G or {}

-- Mock Inspect API
Inspect = Inspect or {}
Inspect.Time = Inspect.Time or {}
Inspect.System = Inspect.System or {}
Inspect.Quest = Inspect.Quest or {}
Inspect.Addon = Inspect.Addon or {}
Inspect.Unit = Inspect.Unit or {}

function Inspect.Time.Real()
  return 0.0
end

function Inspect.Time.Frame()
  return 0
end

function Inspect.System.Secure()
  return true
end

function Inspect.System.Watchdog()
  return 0.1
end

function Inspect.Addon.Current()
  return {
    identifier = "nkUI",
    version = "1.3.1",
  }
end

-- Mock Command API
Command = Command or {}
Command.Event = Command.Event or {}
Command.Console = Command.Console or {}
Command.Slash = Command.Slash or {}

function Command.Event.Attach(event, handler, name)
  return true
end

function Command.Event.Detach(event, handler, name)
  return true
end

function Command.Console.Display(channel, scrollToEnd, message, timestamp)
  return true
end

function Command.Slash.Register(command)
  return {}
end

-- Mock Utility API
Utility = Utility or {}
Utility.Event = Utility.Event or {}
Utility.Matrix = Utility.Matrix or {}

function Utility.Event.Create(addon, event)
  local handlers = {}
  local event_obj = {}
  return handlers, event_obj
end

function Utility.Matrix.Create(rows, cols, ...)
  return {}
end

-- Mock UI API
UI = UI or {}

function UI.CreateContext(name)
  local context = {
    SetStrata = function(self, strata) end,
    SetLayer = function(self, layer) end,
    SetSecureMode = function(self, mode) end,
  }
  return context
end

function UI.CreateFrame(type, name, parent)
  local frame = {
    SetPoint = function(self, point, anchor, anchorPoint, x, y) end,
    SetWidth = function(self, w) end,
    SetHeight = function(self, h) end,
    SetVisible = function(self, flag) end,
    SetText = function(self, text) end,
    SetTextColor = function(self, r, g, b, a) end,
    EventAttach = function(self, event, handler, name) end,
    EventDetach = function(self, event, handler, name) end,
  }
  return frame
end

-- Mock Event constants
Event = Event or {}
Event.Addon = Event.Addon or {}
Event.Addon.SavedVariables = Event.Addon.SavedVariables or {}
Event.Addon.SavedVariables.Load = Event.Addon.SavedVariables.Load or {}
Event.Addon.SavedVariables.Load.End = "Addon.SavedVariables.Load.End"
Event.Unit = Event.Unit or {}
Event.Unit.Availability = Event.Unit.Availability or {}
Event.Unit.Availability.Full = "Unit.Availability.Full"
Event.System = Event.System or {}
Event.System.Update = Event.System.Update or {}
Event.System.Update.Begin = "System.Update.Begin"
Event.Quest = Event.Quest or {}
Event.Quest.Accept = "Quest.Accept"
Event.UI = Event.UI or {}
Event.UI.Input = Event.UI.Input or {}
Event.UI.Input.Mouse = Event.UI.Input.Mouse or {}
Event.UI.Input.Mouse.Left = Event.UI.Input.Mouse.Left or {}
Event.UI.Input.Mouse.Left.Down = "UI.Input.Mouse.Left.Down"

-- Mock LibEKL library
LibEKL = LibEKL or {}
LibEKL.Events = LibEKL.Events or {}
LibEKL.Coroutines = LibEKL.Coroutines or {}
LibEKL.Tools = LibEKL.Tools or {}
LibEKL.Tools.Error = LibEKL.Tools.Error or {}
LibEKL.Tools.Settings = LibEKL.Tools.Settings or {}
LibEKL.Tools.Table = LibEKL.Tools.Table or {}
LibEKL.Tools.Math = LibEKL.Tools.Math or {}
LibEKL.Tools.Color = LibEKL.Tools.Color or {}
LibEKL.Tools.DateTime = LibEKL.Tools.DateTime or {}
LibEKL.Tools.Lang = LibEKL.Tools.Lang or {}
LibEKL.Tools.UUID = LibEKL.Tools.UUID or {}
LibEKL.strings = LibEKL.strings or {}
LibEKL.UI = LibEKL.UI or {}
LibEKL.Unit = LibEKL.Unit or {}
LibEKL.Inventory = LibEKL.Inventory or {}

function LibEKL.UICreateFrame(type, name, parent)
  return UI.CreateFrame(type, name, parent)
end

function LibEKL.Events.AddInsecure(func, time, delay)
  return "uuid"
end

function LibEKL.Events.RemoveInsecure(uuid)
  return true
end

function LibEKL.Events.AddPeriodic(func, period, tries)
  return "uuid"
end

function LibEKL.Events.CheckEvents(namespace, flag)
  return true
end

function LibEKL.Coroutines.Add(config)
  return true
end

function LibEKL.Tools.Error.Display(addon, message, level)
  return true
end

function LibEKL.Tools.Settings.UpdateSettings(defaults, target)
  for k, v in pairs(defaults) do
    if type(v) == "table" then
      target[k] = target[k] or {}
      LibEKL.Tools.Settings.UpdateSettings(v, target[k])
    else
      if target[k] == nil then target[k] = v end
    end
  end
end

function LibEKL.Tools.Table.IsMember(tbl, element)
  for k, v in pairs(tbl) do
    if v == element then return true end
  end
  return false
end

function LibEKL.Tools.Table.Copy(tbl)
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = type(v) == "table" and LibEKL.Tools.Table.Copy(v) or v
  end
  return copy
end

function LibEKL.Tools.Table.GetSize(tbl)
  local count = 0
  for _ in pairs(tbl) do count = count + 1 end
  return count
end

function LibEKL.Tools.Math.Round(num, decimals)
  local mult = 10 ^ (decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

function LibEKL.Tools.Color.RGBToHex(r, g, b)
  return string.format("%02X%02X%02X", r, g, b)
end

function LibEKL.Tools.DateTime.Today()
  return math.floor(os.time() / 86400)
end

function LibEKL.Tools.Lang.GetLanguageShort()
  return "EN"
end

function LibEKL.Tools.UUID()
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
end

function LibEKL.strings.split(text, delimiter)
  local result = {}
  for match in (text .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end
  return result
end

function LibEKL.strings.trim(text)
  return text:match("^%s*(.-)%s*$")
end

function LibEKL.UI.registerFont(addon, fontName, path)
  return true
end

function LibEKL.UI.SetFont(element, addon, fontName)
  return true
end

function LibEKL.Unit.Init()
  return true
end

function LibEKL.Unit.GetPlayerDetails()
  return { id = 1, name = "TestPlayer", level = 70 }
end

function LibEKL.Inventory.Init(bags, bank)
  return true
end
