--[[
  Test Case: Rift Key Events for Keybind Label Detection

  Purpose: Test how Texture.Event:KeyDown behaves to determine if we can
  detect modifier keys (Shift, Ctrl, Alt) for UI interaction without requiring
  secure/interactive mode on the action bar.

  Usage: Load this addon to test in-game, check console output for key events

  Expected Behavior:
  - When user presses any key on an action icon, log the key to console
  - Track what key strings are reported for modifier keys
  - Verify if "shift", "ctrl", "alt" are detectable
  - Test if we can distinguish between "shift+q", "q", etc.
]]

local addonInfo, privateVars = ...

---------- init namespace ---------

local data = privateVars.data
local uiElements = privateVars.uiElements
local internalFunc = privateVars.internalFunc

---------- local variables ---------

local testFrame = nil
local keyLog = {}
local maxLogEntries = 50

---------- local functions ---------

local function logKey(key, eventType)
	-- Log key press to console for manual inspection
	local timestamp = os.date("%H:%M:%S")
	local logEntry = string.format("[%s] %s: %s", timestamp, eventType, tostring(key))

	Command.Console.Display("general", true, logEntry, true)

	-- Also store in table for later analysis
	table.insert(keyLog, logEntry)
	if #keyLog > maxLogEntries then
		table.remove(keyLog, 1)
	end
end

local function createTestFrame()
	-- Create a test frame to capture key events
	local context = UI.CreateContext("nkUI.testKeyEvents")
	context:SetStrata('hud')
	context:SetLayer(10)

	local frame = LibEKL.UICreateFrame("nkFrame", "nkUI.testKeyFrame", context)
	frame:SetWidth(200)
	frame:SetHeight(100)
	frame:SetBackgroundColor(0.1, 0.1, 0.2, 0.8)
	frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, 50)

	-- Add label
	local label = LibEKL.UICreateFrame("nkText", "nkUI.testKeyLabel", frame)
	label:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	label:SetText("Key Event Test Frame\n(Click to focus, then press keys)\n\nCheck console for output")
	label:SetFontColor(1, 1, 1, 1)
	label:SetFontSize(12)

	-- Attach key event handlers
	frame:EventAttach(Event.UI.Input.Key.Down, function(self, key)
		logKey(key, "KeyDown")
	end, "nkUI.testKeyEvents.KeyDown")

	frame:EventAttach(Event.UI.Input.Key.Up, function(self, key)
		logKey(key, "KeyUp")
	end, "nkUI.testKeyEvents.KeyUp")

	frame:EventAttach(Event.UI.Input.Key.Type, function(self, text)
		logKey(text, "KeyType")
	end, "nkUI.testKeyEvents.KeyType")

	frame:EventAttach(Event.UI.Input.Key.Focus.Gain, function(self)
		Command.Console.Display("general", true, "[KEY EVENT TEST] Frame gained key focus", true)
	end, "nkUI.testKeyEvents.KeyFocusGain")

	frame:EventAttach(Event.UI.Input.Key.Focus.Loss, function(self)
		Command.Console.Display("general", true, "[KEY EVENT TEST] Frame lost key focus", true)
	end, "nkUI.testKeyEvents.KeyFocusLoss")

	-- Note: SetKeyFocus should NOT be called here permanently
	-- It will be called by keybindDialog when needed to capture specific keys

	return frame
end

---------- addon init ---------

-- Create test frame on addon startup
if not testFrame then
	testFrame = createTestFrame()
	Command.Console.Display("general", true,
		"<font color='#00FF00'>[nkUI Key Event Test]</font> Test frame created at top-left. Click to focus, then press keys. Check console for output.",
		true)
	Command.Console.Display("general", true,
		"Test what keys are reported when pressing: Shift, Ctrl, Alt, Shift+Q, etc.",
		true)
end

---------- addon functions ---------

-- Slash command to show/hide test frame
local function commandShowTestFrame(args)
	if testFrame then
		local visible = testFrame:GetVisible()
		testFrame:SetVisible(not visible)
		local status = not visible and "shown" or "hidden"
		Command.Console.Display("general", true, "[nkUI Key Event Test] Frame " .. status, true)
	end
end

-- Slash command to dump key log
local function commandDumpKeyLog(args)
	Command.Console.Display("general", true, "[nkUI Key Event Test] Key log (last " .. #keyLog .. " entries):", true)
	for i, entry in ipairs(keyLog) do
		Command.Console.Display("general", true, "  " .. entry, true)
	end
end

-- Slash command to clear key log
local function commandClearKeyLog(args)
	keyLog = {}
	Command.Console.Display("general", true, "[nkUI Key Event Test] Key log cleared", true)
end

-- Register slash commands
table.insert(Command.Slash.Register("nkui"), {commandShowTestFrame, "nkUI", "testKeyFrame"})
table.insert(Command.Slash.Register("nkui"), {commandDumpKeyLog, "nkUI", "dumpKeyLog"})
table.insert(Command.Slash.Register("nkui"), {commandClearKeyLog, "nkUI", "clearKeyLog"})

---------- INSTRUCTIONS FOR TESTING ----------

--[[
TEST PROCEDURE - In-Game Testing:

1. Load nkUI addon
   - Test frame should appear at top-left of screen
   - Green message in console: "[nkUI Key Event Test] Test frame created..."

2. Click on the test frame to give it focus

3. Test individual keys and combinations:
   - Press: Q, W, E, R, etc. (check console output)
   - Press: Shift (alone)
   - Press: Shift+Q, Shift+W, etc.
   - Press: Ctrl, Ctrl+Q, etc.
   - Press: Alt, Alt+Q, etc.

4. Monitor console for output:
   - Watch what key strings are reported
   - Look for patterns (e.g., is Shift+Q reported as "shift+q" or "shift" then "q"?)

5. Commands to use:
   /nkui testKeyFrame  - Toggle frame visibility
   /nkui dumpKeyLog    - Print all logged keys to console
   /nkui clearKeyLog   - Clear the key log

6. Collect data:
   - Document what each key press produces
   - Determine if modifier keys are detectable
   - Check if we can use this to detect Shift+RightClick alternative

EXPECTED FINDINGS:
- If "shift", "ctrl", "alt" appear as key strings → We CAN detect modifiers!
- If only "q", "e", etc. appear → Modifiers are NOT detectable this way
- If we see "shift+q" → Perfect! We can detect modifier combinations

This will help us determine if we can use KeyDown event to detect
Right-click + Shift for opening keybind dialog without requiring
interactive mode on the action bar.
]]

