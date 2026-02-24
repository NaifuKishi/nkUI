# CLAUDE.md – nkUI Rift Addon

## Projektübersicht

**nkUI** ist eine UI-Suite für das MMORPG Rift, inspiriert von ndUI, ToxiUI und ElvUI.  
API-Referenz: https://www.seebs.net/rift/live/

---

## Technische Rahmenbedingungen

### Lua-Version
- Rift verwendet **Lua 5.1** – ausschließlich Lua-5.1-kompatible Syntax
- Kein `goto`, kein `//`-Kommentar, keine Bitwise-Operatoren (`&`, `|`, `~`)
- `unpack()` statt `table.unpack()`

### Manifest-Format
Die Datei heißt **`RiftAddon.toc`** (nicht `.addon`!) mit folgendem Format:
```
Identifier = "nkUI"
Name = "Naifukishi's UI Suite"
Version = "1.3.1"
Environment = "4.0"

RunOnStartup = {
    "main.lua",
    "modules/mymodule/mymodule.lua",
}

Embed = {
    ["Libs/LibEKL"] = true,
}

Dependencies = {
    LibEKL = {"required", "before"},
}

SavedVariables = {
    nkUISetup = "account",
}
```

### Projektstruktur
```
nkUI/
  RiftAddon.toc
  main.lua           ← Haupt-Einstiegspunkt, globaler Namespace
  theme.lua          ← Theme/Farben
  tools.lua          ← Hilfsfunktionen
  fonts/             ← TTF-Fontdateien
  gfx/               ← Texturen/Icons (.png)
  locales/           ← Lokalisierung (EN, DE, FR)
  Libs/LibEKL/       ← Eingebettete Library
  modules/           ← Feature-Module (je Ordner)
  settings/          ← Settings-UI
```

---

## Namespace- und Modul-Pattern

### Einstiegspunkt (`main.lua`)
Jede Datei erhält `addonInfo` und `privateVars` als Vararg `...`:
```lua
local addonInfo, privateVars = ...
```

Globaler Namespace wird nur einmal in `main.lua` initialisiert (Guard-Pattern):
```lua
if not nkUI then nkUI = {} else return end
```

`privateVars` enthält alle internen Strukturen, die zwischen Modulen geteilt werden:
```lua
privateVars.data         = {}
privateVars.internalFunc = {}
privateVars.uiElements   = {}
privateVars.events       = {}
```

### Modul-Pattern
Jedes Modul beginnt mit demselben Block – Namespace-Referenzen lokal cachen,
**Rift-API-Funktionen immer lokal cachen** (Performance-Pflicht):
```lua
local addonInfo, privateVars = ...

---------- init namespace ---------

local uiElements    = privateVars.uiElements
local data          = privateVars.data
local internalFunc  = privateVars.internalFunc

local inspectQuestDetail    = Inspect.Quest.Detail
local inspectSystemSecure   = Inspect.System.Secure
local inspectTimeReal       = Inspect.Time.Real
local stringFormat          = string.format
local mathFloor             = math.floor
local tableInsert           = table.insert
local tableRemove           = table.remove
```

Neue Sub-Namespaces im jeweiligen Modul initialisieren:
```lua
-- In questlog.lua:
privateVars.questLog = {}
local questLog = privateVars.questLog
```

### Kommentar-Trennlinien (Pflicht)
```lua
---------- init namespace ---------
---------- init local variables ---------
---------- local function block ---------
---------- addon internalFunc function block ---------
---------- library public function block ---------
-------------------- STARTUP EVENTS --------------------
```

---

## Rift API – Wichtige Konventionen

### Startup-Reihenfolge
Das korrekte Startup-Event ist **`Event.Addon.SavedVariables.Load.End`**:
```lua
local function initializeAddon(_, addon)
    if addon ~= addonInfo.identifier then return end
    -- SavedVars sind hier verfügbar
end
Command.Event.Attach(Event.Addon.SavedVariables.Load.End, initializeAddon,
    "nkUI.SavedVariables.Load.End")
```

Unit-Daten erst nach **`Event.Unit.Availability.Full`** verfügbar – danach detachen:
```lua
Command.Event.Attach(Event.Unit.Availability.Full, function()
    LibEKL.Unit.Init()
    LibEKL.Inventory.Init(false, false)
    -- Module initialisieren
    Command.Event.Detach(Event.Unit.Availability.Full, nil, "nkUI.Unit.Availability.Full")
end, "nkUI.Unit.Availability.Full")
```

### UI-Kontext
```lua
local context = UI.CreateContext("nkUI.myModule")
context:SetStrata('hud')   -- 'hud', 'tooltip', 'fullscreen'
context:SetLayer(2)
```

Für sichere UI-Elemente (z.B. Action Buttons):
```lua
context:SetSecureMode("restricted")
frame:SetSecureMode("restricted")
```

### UI-Elemente: LibEKL-Wrapper verwenden
Im Projekt wird **`LibEKL.UICreateFrame`** statt `UI.CreateFrame` verwendet:
```lua
local frame  = LibEKL.UICreateFrame("nkFrame",    "nkUI.myFrame",  parent)
local text   = LibEKL.UICreateFrame("nkText",     "nkUI.myText",   parent)
local tex    = LibEKL.UICreateFrame("nkTexture",  "nkUI.myTex",    parent)
local canvas = LibEKL.UICreateFrame("nkCanvas",   "nkUI.myCanvas", parent)
local scroll = LibEKL.UICreateFrame("nkScrollPane","nkUI.myScroll", parent)
local window = LibEKL.UICreateFrame("nkWindow",   "nkUI.myWindow", parent)
```

Nativer `UI.CreateFrame("Frame", ...)` nur für einfache Container ohne LibEKL-Features.

### SetPoint / Anchoring
```lua
frame:SetPoint("TOPLEFT",     parent,      "TOPLEFT",     xOff, yOff)
frame:SetPoint("CENTERLEFT",  otherFrame,  "CENTERRIGHT", 10,   0)
frame:SetPoint("TOPCENTER",   otherFrame,  "BOTTOMCENTER", 0,   5)
```

### Fonts
```lua
-- Registrierung einmalig in initializeAddon:
LibEKL.UI.registerFont(addonInfo.id, "MontserratBold", "fonts/Montserrat-Bold.ttf")

-- Setzen auf einem Text-Element:
LibEKL.UI.SetFont(textElement, addonInfo.id, "MontserratBold")
```

Verfügbare Fonts im Projekt: `Montserrat`, `MontserratItalic`, `MontserratMedium`,
`MontserratMediumItalic`, `MontserratSemiBold`, `MontserratSemiBoldItalic`,
`MontserratBold`, `MontserratExtraBold`, `MontserratBlack`,
`FiraMono`, `FiraMonoMedium`, `FiraMonoBold`

### Texturen
```lua
texture:SetTextureAsync("nkUI", "gfx/myIcon.png")  -- eigene Assets
texture:SetTextureAsync("Rift", details.icon)        -- Rift-interne Icons
```

### Event-Namenskonvention
Dritter Parameter immer eindeutig: `"AddonName.Modul.EventName"`:
```lua
Command.Event.Attach(Event.Quest.Accept, myHandler, "nkUI.questLog.Quest.Accept")
frame:EventAttach(Event.UI.Input.Mouse.Left.Down, myHandler, "nkUI.myFrame.Left.Down")
```

### Slash-Commands
```lua
table.insert(Command.Slash.Register("nkui"), {commandHandler, "nkUI", "commandHandler"})
```

### Console-Output
```lua
Command.Console.Display("general", true, "Meine Nachricht", true)
-- Mit Farbe:
Command.Console.Display("general", true,
    string.format('<font color="#FF6A00">Text</font>'), true)
```

### Custom Events erstellen (Utility.Event.Create)
```lua
LibEKL.eventHandlers["MyModule"] = {}
LibEKL.Events["MyModule"] = {}
LibEKL.eventHandlers["MyModule"]["myEvent"], LibEKL.Events["MyModule"]["myEvent"] =
    Utility.Event.Create(addonInfo.identifier, "MyModule.myEvent")
```

---

## Canvas / Shapes

```lua
local path = {
    {xProportional = 0, yProportional = 0},
    {xProportional = 1, yProportional = 0},
    {xProportional = 1, yProportional = 1},
    {xProportional = 0, yProportional = 1},
    {xProportional = 0, yProportional = 0}
}
local fill = {
    type = "gradientLinear",
    transform = Utility.Matrix.Create(2, 2, math.pi / 4, 0, 0),
    color = {
        {r = 0.13, g = 0.15, b = 0.22, a = 1, position = 0},
        {r = 0.05, g = 0.07, b = 0.11, a = 1, position = 1}
    }
}
local stroke = {r = 0x66/255, g = 0x56/255, b = 0x2e/255, a = 1,
                cap = "round", miter = "miter", thickness = 2}
canvas:SetShape(path, fill, stroke)
```

Für Rotation eines Canvas-Elements: **`LibEKL.Tools.Gfx.Rotate(frame, angle, scale)`**  
gibt eine fertige Transform-Matrix zurück.

---

## LibEKL – Vollständige API-Referenz

### Events

```lua
-- Einmalige insecure Ausführung (außerhalb secure context), optional verzögert:
LibEKL.Events.AddInsecure(func, Inspect.Time.Frame(), delayFrames)
LibEKL.Events.RemoveInsecure(uuid)

-- Periodische Ausführung (period in Sekunden):
local uuid = LibEKL.Events.AddPeriodic(func, period, tries)

-- Custom Event-Namespace registrieren:
LibEKL.Events.CheckEvents("MyNamespace", true)
```

Der zentrale Update-Handler läuft auf `Event.System.Update.Begin` und verarbeitet:
- jeden Frame: Coroutines, Periodic Events
- alle 0.1s: Cooldowns (Abilities, Items)
- alle 1.0s: sonstige periodische Checks
- wenn Watchdog frei (`>= 0.1`): Insecure Events, Performance Queue

**Watchdog prüfen** bevor teure Operationen:
```lua
if Inspect.System.Watchdog() < 0.1 then return end
```

### Coroutines

Für aufwändige Schleifen, die über mehrere Frames verteilt werden:
```lua
local co = coroutine.create(function()
    for idx = 1, #list do
        -- Arbeit pro Item
        coroutine.yield(idx)   -- gibt Kontrolle zurück
    end
end)

LibEKL.Coroutines.Add({
    func     = co,
    counter  = #list,   -- ab diesem yield-Wert gilt die Coroutine als fertig
    active   = true,
    delay    = 0.5,     -- optionale Startverzögerung in Sekunden
    callBack = function() end  -- wird nach Abschluss aufgerufen
})
```

### Performance Queue

Für Aufgaben mit niedrigster Priorität (läuft nur wenn Watchdog frei):
```lua
LibEKL.Tools.Performance.AddToQueue(function()
    -- teure Operation
end)
```

### Fehlerbehandlung

```lua
-- In eigenem Code immer pcall für Rift-API-Aufrufe:
local ok, result = pcall(Inspect.Quest.Detail, key)
if not ok then return end

-- Fehlermeldung ausgeben (Level: 1=Fatal, 2=Error, 3=Warning, 4=Info):
LibEKL.Tools.Error.Display("nkUI.myModule", "Fehlermeldung", 2)
```

### String-Funktionen (`LibEKL.strings`)

```lua
LibEKL.strings.split(text, delimiter)      -- → table
LibEKL.strings.trim(text)                  -- Whitespace entfernen
LibEKL.strings.find(source, pattern)       -- nil-sicheres string.find
LibEKL.strings.left(value, delimiter)      -- Text vor Delimiter
LibEKL.strings.right(value, delimiter)     -- Text nach Delimiter (plain)
LibEKL.strings.rightRegEx(value, delimiter)-- Text nach Delimiter (RegEx)
LibEKL.strings.leftBack(value, delimiter)  -- Text vor letztem Delimiter
LibEKL.strings.rightBack(value, delimiter) -- Text ab letztem Delimiter
LibEKL.strings.startsWith(value, start)    -- boolean
LibEKL.strings.endsWith(value, ending)     -- boolean
LibEKL.strings.Capitalize(text)            -- Ersten Buchstaben jedes Worts groß
LibEKL.strings.formatNumber(number)        -- 1000000 → "1.000.000"
```

### Tabellen-Funktionen (`LibEKL.Tools.Table`)

```lua
LibEKL.Tools.Table.IsMember(tbl, element)         -- boolean
LibEKL.Tools.Table.GetTablePos(tbl, element)       -- index oder -1
LibEKL.Tools.Table.AddValue(tbl, element)          -- fügt hinzu wenn nicht vorhanden
LibEKL.Tools.Table.RemoveValue(tbl, element)       -- entfernt Element
LibEKL.Tools.Table.Copy(tbl)                       -- deep copy
LibEKL.Tools.Table.Merge(tbl1, tbl2)               -- tbl2 in tbl1 (array)
LibEKL.Tools.Table.MergeIndexed(tbl1, tbl2)        -- tbl2 in tbl1 (key-value)
LibEKL.Tools.Table.GetSortedKeys(tbl)              -- sortierte Key-Liste
LibEKL.Tools.Table.GetSize(tbl)                    -- Anzahl Elemente
LibEKL.Tools.Table.GetFirstElement(tbl)            -- key, value
LibEKL.Tools.Table.GetLastElement(tbl)             -- key, value
LibEKL.Tools.Table.GetKeyByValue(tbl, value)       -- key oder nil
LibEKL.Tools.Table.Serialize(tbl)                  -- → string
```

### Math-Funktionen (`LibEKL.Tools.Math`)

```lua
LibEKL.Tools.Math.Round(num, decimals)   -- z.B. Round(1.567, 2) → 1.57
LibEKL.Tools.Math.IsNaN(x)              -- boolean
LibEKL.Tools.Math.Hex2number("hFF")     -- → 255
```

### Farb-Funktionen (`LibEKL.Tools.Color`)

```lua
local r, g, b = LibEKL.Tools.Color.HSV2RGB(hue, sat, val)
local hex     = LibEKL.Tools.Color.RGBToHex(r255, g255, b255)  -- 0-255 Input
local hex     = LibEKL.Tools.Color.RGBToHexColor(r, g, b)      -- 0-1 Input
local r, g, b = LibEKL.Tools.Color.Adjust(r, g, b, factor)     -- aufhellen/abdunkeln
```

### Datum/Zeit (`LibEKL.Tools.DateTime`)

```lua
LibEKL.Tools.DateTime.Today()                        -- os.time() auf Tagesbasis
LibEKL.Tools.DateTime.IsDatePast(date)               -- boolean
LibEKL.Tools.DateTime.AdjustDate(date, "day", n)     -- oder "month"
LibEKL.Tools.DateTime.AdjustTime(time, "min", n)
LibEKL.Tools.DateTime.SecondsToText(seconds)         -- "2h", "30m", "45s"
LibEKL.Tools.DateTime.GetDaysInMonth(month, year)
```

### Sprache (`LibEKL.Tools.Lang`)

```lua
LibEKL.Tools.Lang.GetLanguageShort()   -- "EN", "DE", "FR", "RU"
LibEKL.Tools.Lang.GetLanguage()        -- "German", "French", etc.
LibEKL.Tools.Lang.SetLanguage(lang)    -- überschreibt Systemsprache
LibEKL.Tools.Lang.ResetLanguage()
```

### Settings-Defaults (`LibEKL.Tools.Settings`)

Merged Default-Einstellungen in bestehende SavedVars (fehlende Keys ergänzen):
```lua
local defaults = { activate = true, x = 0, y = 0 }
LibEKL.Tools.Settings.UpdateSettings(defaults, nkUISetup.modules.myModule)
```

### UUID

```lua
local id = LibEKL.Tools.UUID()  -- "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
```

### Weitere LibEKL-Module

```lua
LibEKL.Unit.Init()
LibEKL.Unit.GetPlayerDetails()           -- { id, name, level, ... }
LibEKL.Unit.SetPlayerDetails(key, value)

LibEKL.Inventory.Init(bags, bank)
LibEKL.Inventory.getQuestItems()
LibEKL.Inventory.getAvailableSlots()
LibEKL.Inventory.queryByCategory("misc quest")
LibEKL.Inventory.GetItemColor(rarity)   -- { r, g, b }

LibEKL.UI.confirmDialog(text, yesFunc, noFunc)   -- Bestätigungs-Dialog
LibEKL.UI.setupBoundCheck()
LibEKL.manager.RegisterButton(id, addonId, icon, callback)
LibEKL.manager.GetFrame()
LibEKL.manager.UpdateFrame(anchorFrame)

LibQB.loadPackage("classic")            -- Quest-Datenbank laden
LibQB.query.byKey(questId, withLevel)   -- level, libDetails
LibQB.query.questItemByKey(itemType)
LibQB.query.isInit()
```

---

## SavedVariables

Die globale SavedVariable `nkUISetup` (Account-Scope) enthält alle Einstellungen.
Defaults immer über `LibEKL.Tools.Settings.UpdateSettings` setzen:
```lua
local defaults = {
    modules = {
        myModule = { activate = true, x = 0, y = 0 }
    }
}
LibEKL.Tools.Settings.UpdateSettings(defaults, nkUISetup)

-- Lesen mit nil-Guard:
if nkUISetup and nkUISetup.modules and nkUISetup.modules.myModule then
    -- ...
end
```

---

## Code-Stil

- Alle Variablen mit `local` deklarieren
- Rift-API und Standard-Library-Funktionen am Modulanfang cachen
- Kommentar-Trennlinien für Abschnitte verwenden (siehe oben)
- `pcall` für alle Rift-API-Aufrufe die fehlschlagen können
- Keine schwere Logik direkt in `Event.System.Update.Begin` – Watchdog prüfen oder über LibEKL-Event-System verteilen
- UI-Elemente einmalig erstellen, Sichtbarkeit per `SetVisible` steuern (Recycling-Pattern)
- Russisch (`RU`) wird nicht unterstützt – früh prüfen und `return`

---

## Lua Best Practices

### Locals sind schneller als Globals – immer

Der Lua-VM-Zugriff auf lokale Variablen ist deutlich schneller als auf globale,
weil Globals über eine Hash-Table-Suche in `_G` aufgelöst werden.
**Pflicht:** Alle häufig genutzten Globals, API-Funktionen und Upvalues am
Modulanfang einmalig lokal cachen:

```lua
-- Am Dateianfang – nicht innerhalb von Funktionen:
local tableInsert   = table.insert
local tableRemove   = table.remove
local mathFloor     = math.floor
local mathMax       = math.max
local stringFormat  = string.format
local stringFind    = string.find
local pairs         = pairs
local ipairs        = ipairs
local type          = type
local tostring      = tostring

local inspectTimeReal   = Inspect.Time.Real
local inspectTimeFrame  = Inspect.Time.Frame
```

### Tabellen effizient nutzen

```lua
-- Tabellengröße: # funktioniert nur zuverlässig bei reinen Array-Tables (integer keys 1..n)
-- Für gemischte Tables stattdessen LibEKL.Tools.Table.GetSize() verwenden

-- Vorallokierung: Größe bekannter Arrays direkt mit Werten befüllen statt table.insert in Loop
local t = {}
for i = 1, 100 do t[i] = i end   -- schneller als table.insert(t, i)

-- Tabellen wiederverwenden statt neu erstellen (Recycling-Pattern wie in questLog)
-- Elemente mit SetVisible(false) "parken", nicht neu erzeugen

-- Schleifen: ipairs ist für Arrays schneller als pairs
for i, v in ipairs(myArray) do end     -- Array (1..n, keine Lücken)
for k, v in pairs(myTable) do end      -- Hash / gemischte Tables

-- Letztes Element entfernen ist O(1), aus der Mitte ist O(n):
tableRemove(t)          -- schnell (Ende)
tableRemove(t, 1)       -- langsam (verschiebt alle Elemente)
-- → Stack-Pattern (LIFO) mit table.insert/remove am Ende bevorzugen
```

### Strings

```lua
-- String-Konkatenation in Loops ist teuer (erzeugt bei jedem .. einen neuen String)
-- Stattdessen table.concat verwenden:
local parts = {}
for i = 1, n do parts[i] = tostring(i) end
local result = table.concat(parts, ", ")

-- string.format ist langsamer als direktes Konkatenieren für sehr einfache Fälle,
-- aber bevorzugt für Lesbarkeit und bei mehr als 1-2 Teilen

-- string.find mit plainFlag = true (4. Parameter) ist schneller wenn kein Pattern nötig:
string.find(str, "nkUI.", 1, true)   -- plain search, kein Regex-Overhead
-- LibEKL.strings.find ist bereits nil-safe, daher im Projekt bevorzugen
```

### Funktionen und Closures

```lua
-- Closures erzeugen ein neues Objekt pro Aufruf – nicht in hot paths erstellen:

-- Schlecht (neue Closure bei jedem Frame):
Command.Event.Attach(Event.System.Update.Begin, function()
    local function helper() end   -- wird jedes Mal neu alloziert
    helper()
end, "...")

-- Gut (Funktion einmalig definieren):
local function helper() end
local function onUpdate() helper() end
Command.Event.Attach(Event.System.Update.Begin, onUpdate, "...")

-- Upvalues in Closures für Zustandsspeicherung nutzen (kein Overhead für globale Suche):
local count = 0
local function increment() count = count + 1 end   -- count ist Upvalue, nicht Global
```

### Nil-Checks und Kurzschlussauswertung

```lua
-- Lua wertet 'and'/'or' lazy aus – für Defaults nutzen:
local value = someVar or defaultValue
local name  = details and details.name or "Unknown"

-- Aber Vorsicht: false wird von 'or' als falsy behandelt!
-- Wenn false ein gültiger Wert ist, explizit prüfen:
if details.flag == nil then details.flag = false end

-- Früh returnen statt tiefes Nesting (Guard Clauses):
local function process(data)
    if data == nil then return end
    if data.name == nil then return end
    -- eigentliche Logik
end
```

### Performance in Event-Handlern

```lua
-- Event.System.Update.Begin läuft jeden Frame (~60x/s) – hier nichts Teures:
-- ✗ Keine String-Operationen, keine table.sort, keine API-Calls ohne Not
-- ✗ Kein UI-Layout (GetWidth/GetHeight löst Layout-Pass aus)
-- ✓ Nur Flags prüfen, Counters inkrementieren, leichte Berechnungen

-- Rate-Limiting mit Zeitstempel (wie im Projekt verwendet):
local lastUpdate = nil
local function onUpdate()
    local now = Inspect.Time.Real()
    if lastUpdate and (now - lastUpdate) < 0.5 then return end
    lastUpdate = now
    -- teure Logik hier
end

-- Watchdog prüfen bevor teure Operationen im Update-Handler:
if Inspect.System.Watchdog() < 0.1 then return end

-- Aufwändige Arbeit in Coroutinen auslagern (LibEKL.Coroutines.Add)
-- Niedrigste Priorität in Performance Queue (LibEKL.Tools.Performance.AddToQueue)
```

### Objekt-Methoden

Rift-Frame-Objekte sind C-seitige Userdata – `setmetatable` funktioniert auf
ihnen **nicht**. Methoden werden daher direkt auf das Frame-Objekt gesetzt,
wobei Upvalues den Instanz-Zustand halten:

```lua
function frame:SetTitle(text)
    headerText:SetText(text)   -- headerText ist Upvalue der Closure
end
```

Originale Methoden überschreiben mit dem **oFunc-Pattern** (wird in LibEKL
durchgängig verwendet, z.B. in nkText für SetText):
```lua
local oSetVisible = frame.SetVisible
function frame:SetVisible(flag)
    oSetVisible(self, flag)       -- Original aufrufen
    otherElement:SetVisible(flag) -- eigene Logik ergänzen
end
```

**Metatables in nkUI:** Sinnvoll einzusetzen für Konfigurations-Tables mit
automatischem Fallback-Wert, z.B. für `data.categoryColor`:
```lua
-- Statt manuellem nil-Check an jeder Verwendungsstelle:
local color = data.categoryColor[category]
if color == nil then color = {1, 1, 1, 1} end  -- aktuell nötig

-- Einmalig in questlog.lua setzen, danach überall ohne nil-Check nutzbar:
setmetatable(data.categoryColor, {
    __index = function(t, k) return {1, 1, 1, 1} end
})
local color = data.categoryColor[category]  -- Fallback automatisch
```

### Speicher und GC

```lua
-- Lua GC pausiert kurz beim Aufräumen – große Objekte vermeiden die häufig neu alloziert werden
-- UI-Elemente recyclen statt destroy/recreate (Recycling-Bin Pattern aus questLog):
local recycleBin = {}
-- Beim Entfernen:
thisEntry:SetVisible(false)
tableInsert(recycleBin, thisEntry)
-- Beim Hinzufügen:
if #recycleBin > 0 then
    thisEntry = recycleBin[1]
    tableRemove(recycleBin, 1)
else
    thisEntry = createNewEntry()  -- nur wenn kein Recycling möglich
end

-- Temporäre Tables in Loops vermeiden:
-- Schlecht: for i = 1, n do local t = {x=i, y=i} process(t) end
-- Gut: Werte direkt übergeben oder eine Table wiederverwenden
```

### Debugging

```lua
-- nkDebug ist optional verfügbar – immer mit nil-Check verwenden:
if nkDebug then
    nkDebug.logEntry(addonInfo.identifier, "functionName", "label", value)
end

-- Für Tracing in LibEKL-Funktionen:
local debugId
if nkDebug then debugId = nkDebug.traceStart(Inspect.Addon.Current(), "label") end
-- ... Code ...
if nkDebug then nkDebug.traceEnd(Inspect.Addon.Current(), "label", debugId) end
```
