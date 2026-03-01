local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local lowerBar    = privateVars.lowerBar

---------- init local variables ---------

local inspectSystemSecure       = Inspect.System.Secure
local inspectUnitDetail         = Inspect.Unit.Detail
local inspectAbilityNewDetail   = Inspect.Ability.New.Detail

local stringGSub                = string.gsub
local stringFormat              = string.format

---------- local functions ---------

-- Creates and manages the location display with teleport buttons
function lowerBar.location()
    
    local buttonShown = false

    local datasetFrame = lowerBar.dataSet("lowerBar.datasetloc", "gfx/lowerbarLocation.png", "right")
    
    function datasetFrame:Redraw()
        datasetFrame:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    end
    
    local buttons = {}
    local abilities = {"A3C5AEC64D3793518", "A665FDAC7EDD37636", "A6B16924B96299E96"}
    local abilityDetails = inspectAbilityNewDetail(abilities)

    local parent = datasetFrame
    
    for k, v in pairs(abilityDetails) do
        local datasetLocationButton = LibEKL.UICreateFrame('nkFrame', "lowerBar.location.button" .. k, parent)
        datasetLocationButton:SetVisible(false)
        datasetLocationButton:SetBackgroundColor(0, 0, 0, 1)
        datasetLocationButton:SetHeight(40)
        datasetLocationButton:SetWidth(40)
        datasetLocationButton:SetSecureMode('restricted')
        datasetLocationButton:SetPoint("BOTTOMCENTER", parent, "TOPCENTER")
        
        local datasetLocationButtonTexture = LibEKL.UICreateFrame('nkTexture', "lowerBar.location.button.texture" .. k, datasetLocationButton)
        datasetLocationButtonTexture:SetTexture("Rift", v.icon)
        datasetLocationButtonTexture:SetPoint("TOPLEFT", datasetLocationButton, "TOPLEFT", 1, 1)
        datasetLocationButtonTexture:SetPoint("BOTTOMRIGHT", datasetLocationButton, "BOTTOMRIGHT", -1, -1)
        
        local macro = "cast " .. stringGSub(v.name, "\n", "")
        datasetLocationButtonTexture:EventMacroSet(Event.UI.Input.Mouse.Left.Click, macro)
        datasetLocationButtonTexture:SetVisible(true)
        
        LibEKL.UI.attachAbilityTooltip(datasetLocationButtonTexture, v.id)
        
        table.insert(buttons, datasetLocationButton)
        
        parent = datasetLocationButton
    end
    
    datasetFrame:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        if inspectSystemSecure() then return end
        
        buttonShown = not buttonShown
        for _, v in pairs(buttons) do v:SetVisible(buttonShown) end
    end, datasetFrame:GetName() .. ".Left.Click")
    
    local function updateLocation(_, loc)
        local playerID = LibEKL.Unit.GetPlayerDetails().id
        
        if loc[playerID] == nil or loc[playerID] == false then return end
        
        datasetFrame:SetText(loc[playerID])
    end
    
    local function unitAvailable(_, info)
        for unit, data in pairs(info) do
            if data == "player" then
                local details = inspectUnitDetail(unit)
                datasetFrame:SetText(details.locationName)
                return
            end
        end
    end
    
    local details = inspectUnitDetail(LibEKL.Unit.GetPlayerDetails().id)
    datasetFrame:SetText(details.locationName)

    Command.Event.Attach(Event.Unit.Detail.LocationName, updateLocation, "nkUI.lowerbar.location.Unit.Detail.LocationName")
    Command.Event.Attach(Event.Unit.Availability.Full, unitAvailable, "nkUI.lowerbar.location.Unit.Availability.Full")
    
    return datasetFrame

end