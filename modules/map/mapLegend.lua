-- modules/MapLegend.lua
local addonInfo, privateVars = ...

local map           = privateVars.map
local mapData       = privateVars.mapData
local uiElements    = privateVars.uiElements
local langTexts     = privateVars.langTexts
local data          = privateVars.data
local internalFunc  = privateVars.internalFunc

-- Modul-Tabelle erstellen
local MapLegend = {}

local mapElements = {
    ["UNKNOWN"]                        = { path = "gfx/mapIcons/iconUnknown.png",           text = "Unknown" },
    ["WAYPOINT"]                       = { path = "gfx/mapIcons/iconWaypoint.png",          text = "Waypoint" },
    ["UNIT.PLAYER"]                    = { path = "gfx/mapIcons/iconPlayerPosition.png",    text = "Player" },
    ["POI.CAVE"]                       = { path = "gfx/mapIcons/iconCave.png",              text = "Cave" },
    ["POI.PORTAL"]                     = { path = "gfx/mapIcons/iconPortal.png",            text = "Portal" },
    ["POI.QUESTHUB"]                   = { path = "gfx/mapIcons/iconQuestHub.png",          text = "Quest Hub" },
    ["POI.OTHER"]                      = { path = "gfx/mapIcons/iconPOIOther.png",          text = "Other POI" },
    ["POI.DUNGEON"]                    = { path = "gfx/mapIcons/iconChronicles.png",        text = "Dungeon" },
    ["VENDOR"]                         = { path = "gfx/mapIcons/iconVendor.png",            text = "Vendor" },
    ["QUARTERMASTER"]                  = { path = "gfx/mapIcons/iconQuartermaster.png",     text = "Quartermaster" },
    ["VARIA.LETTERBOX"]                = { path = "gfx/mapIcons/iconMailbox.png",           text = "Mailbox" },
    ["VARIA.BANK"]                     = { path = "gfx/mapIcons/iconBank.png",              text = "Bank" },
    ["VARIA.AUCTIONHOUSE"]             = { path = "gfx/mapIcons/iconAuctionHouse.png",      text = "Auction House" },
    ["VARIA.STYLIST"]                  = { path = "gfx/mapIcons/iconBarber.png",            text = "Stylist" },
    ["TEACHER"]                        = { path = "gfx/mapIcons/iconTrainer.png",           text = "Teacher" },
    ["QUEST.RETURN"]                   = { path = "gfx/mapIcons/iconQuestReturn10.png",     text = "Quest Return" },
    ["QUEST.START"]                    = { path = "gfx/mapIcons/iconQuestStart.png",        text = "Quest Start" },
    ["QUEST.DAILY"]                    = { path = "gfx/mapIcons/iconQuestRepeatable.png",   text = "Quest Daily" },
    ["QUEST.MISSING"]                  = { path = "gfx/mapIcons/iconQuestUnavailable.png",  text = "Quest Unavailable" },
    ["QUEST.CARNAGEPOINT"]             = { path = "gfx/mapIcons/iconCarnage.png",           text = "Carnage Point" },
    ["QUEST.POINT"]                    = { path = "gfx/mapIcons/iconQuestLocation1.png",    text = "Quest Point" },
    ["QUEST.PROGRESS"]                 = { path = "gfx/mapIcons/iconQuestLocation1.png",    text = "Quest Progress" },
    ["RIFT.POST"]                      = { path = "gfx/mapIcons/iconFootholdFire.png",      text = "Rift Post" },
    ["RIFT.POST.GUARDIAN"]             = { path = "gfx/mapIcons/iconFootholdGuardian.png",  text = "Rift Post Guardian" },
    ["RIFT.POST.DEFIANT"]              = { path = "gfx/mapIcons/iconFootholdDefiant.png",   text = "Rift Post Defiant " },
    ["RIFT.INVASION"]                  = { path = "gfx/mapIcons/iconInvasionFire.png",      text = "Invasion" },
    ["RIFT.INVASION.GUARDIAN"]         = { path = "gfx/mapIcons/iconInvasionGuardian.png",  text = "Invasion Guardian" },
    ["RIFT.INVASION.DEFIANT"]          = { path = "gfx/mapIcons/iconInvasionDefiant.png",   text = "Invasion Defiant" },
    ["RIFT.CRAFTING"]                  = { path = "gfx/mapIcons/iconRiftCraft.png",         text = "Rift Crafting" },
    ["RIFT.MINOR.ACTIVE.FIRE"]         = { path = "gfx/mapIcons/iconRiftFire.png",          text = "Rift Minor" },    
    ["RIFT.MAJOR.ACTIVE.FIRE"]         = { path = "gfx/mapIcons/iconRiftMajorFire.png",     text = "Rift Major" },
    ["RIFT.EXPERT.ACTIVE.FIRE"]        = { path = "gfx/mapIcons/iconRiftExpertFire.png",    text = "Rift Expert" },
    ["RIFT.RAID.ACTIVE.FIRE"]          = { path = "gfx/mapIcons/iconRiftRaidFire.png",      text = "Rift Raid " },
    ["RIFT.MINOR.UNOPENED"]            = { path = "gfx/mapIcons/iconRiftMinorUnopened.png", text = "Unopened\nMinor Rift" },
    ["RIFT.MAJOR.UNOPENED"]            = { path = "gfx/mapIcons/iconRiftMajorUnopened.png", text = "Unopened\nMajor Rift" },
    ["RIFT.RAID.UNOPENED"]             = { path = "gfx/mapIcons/iconRiftRaidUnopened.png",  text = "Unopened\nRaid Rift" },
    ["RIFT.PLANE.ANCHOR"]              = { path = "gfx/map/icon_planeanchor.png",           text = "Plane Anchor" },
    ["RESOURCE.ARTIFACT"]              = { path = "gfx/mapIcons/iconArtifact.png",          text = "Artifact" },
    ["RESOURCE.FISH"]                  = { path = "gfx/mapIcons/iconFishingGround.png",     text = "Fishing Ground" },
    ["PROFESSION.TEACHER"]             = { path = "gfx/mapIcons/iconCrafting.png",          text = "Profession Teacher" },
    ["PROFESSION.RECIPESELLER"]        = { path = "gfx/mapIcons/iconCraftingRecipe.png",    text = "Recipe Seller" },
}

-- Standardposition und Größe
local DEFAULT_WIDTH, DEFAULT_HEIGHT = 600, 600
local ICONS_PER_ROW = 10  -- Anzahl der Icons pro Zeile
local ICON_SPACING = 100  -- Abstand zwischen Icons

-- Frame für die Legende erstellen
function MapLegend:CreateLegendFrame()
    if not uiElements.mapLegend then
        uiElements.mapLegend = LibEKL.UICreateFrame("nkWindow", "nkUIMapLegend", uiElements.mapContext or UIParent)
        uiElements.mapLegend:SetTitle("Map legend")
        uiElements.mapLegend:SetWidth(DEFAULT_WIDTH)
        uiElements.mapLegend:SetHeight(DEFAULT_HEIGHT)
        uiElements.mapLegend:SetPoint("TOPLEFT", UIParent, "TOPLEFT", uiElements.mapUI:GetLeft() - 700, 200)
        uiElements.mapLegend:SetCloseable(true)
        uiElements.mapLegend:SetVisible(false)
        
        uiElements.mapLegend:SetTitleFont(addonInfo.id, "MontserratSemiBold")
        uiElements.mapLegend:SetTitleFontSize(16)
        uiElements.mapLegend:SetTitleEffect({strength = 3})

        uiElements.mapLegend:SetTitleFontColor(data.theme.labelColor.r, data.theme.labelColor.g, data.theme.labelColor.b, data.theme.labelColor.a)

        uiElements.mapLegend:SetColor({
            type = "gradientLinear",
            transform = Utility.Matrix.Create(12, 12, math.pi / 4, 0, 0),  -- 45° rotation
            color = {
                {r = 0.1294, g = 0.1533, b = 0.2157, a = 1, position = 0}, -- Start color
                {r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1}  -- End color
            }
        }, data.theme.STROKE_BORDER)

        -- Erstelle eine sortierte Liste der Symbole
        local sortedSymbols = {}
        for key, symbol in pairs(mapElements) do
            table.insert(sortedSymbols, {key = key, symbol = symbol})
        end

        -- Sortiere die Symbole nach Text
        table.sort(sortedSymbols, function(a, b)
            return a.symbol.text < b.symbol.text
        end)

        -- Gefilterte Symbole laden
        local offsetX, offsetY = 20, 0
        local row = 0

        for _, entry in ipairs(sortedSymbols) do
            local key = entry.key
            local symbol = entry.symbol

            local icon = LibEKL.UICreateFrame("nkTexture", "legendIcon" .. key, uiElements.mapLegend:GetContent())
            icon:SetPoint("TOPLEFT", uiElements.mapLegend:GetContent(), "TOPLEFT", offsetX, offsetY)
            icon:SetWidth(48)
            icon:SetHeight(48)
            icon:SetTexture("LibMap", symbol.path)

            local text = LibEKL.UICreateFrame("nkText", "legendIcon" .. key .. ".text", uiElements.mapLegend:GetContent())
            text:SetPoint("CENTERTOP", icon, "BOTTOMCENTER", 0, 5)
            text:SetText(symbol.text)
            text:SetFontSize(10)
            text:SetFontColor(1, 1, 1, 1)
            LibEKL.UI.SetFont(text, addonInfo.id, "Montserrat")

            -- Umbruch nach X Icons
            offsetX = offsetX + ICON_SPACING
            if offsetX + 48 > DEFAULT_WIDTH - 20 then
                offsetX = 20
                offsetY = offsetY + 70  -- Neue Zeile
            end
        end
    end
end

-- Legende anzeigen/verstecken
internalFunc.mapLegendToggle = function ()
    if not uiElements.mapLegend then
        self:CreateLegendFrame()
    end
    uiElements.mapLegend:SetVisible(not uiElements.mapLegend:GetVisible())
end

map.mapLegendInit = function()
    MapLegend:CreateLegendFrame()
end