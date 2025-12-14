local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local lowerBar    = privateVars.lowerBar

---------- init local variables ---------

local inspectRoleList      = Inspect.Role.List
local inspectTEMPORARYRole = Inspect.TEMPORARY.Role

local stringFormat         = string.format

---------- local functions ---------

-- Creates and manages the role selection display
function lowerBar.lowerBarRoles()
    local name = "lowerbar.roles"
    
    local datasetRole = EnKai.uiCreateFrame("nkText", name .. ".datasetrole", uiElements.contextLowestRestricted)
    datasetRole:SetPoint("BOTTOMCENTER", UIParent, "BOTTOMCENTER", -data.aFourth * 2, -5)
    datasetRole:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetRole:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetRole:SetTextFont(addonInfo.id, "Montserrat")
    datasetRole:SetEffectGlow({ strength = 1})
    datasetRole:SetSecureMode('restricted')
    
    local roleSwitch = EnKai.uiCreateFrame("nkFrame", name .. ".datasetrole.switch", datasetRole)
    roleSwitch:SetPoint("BOTTOMCENTER", datasetRole, "TOPCENTER")
    roleSwitch:SetSecureMode('restricted')
    roleSwitch:SetHeight(1)
    roleSwitch:SetVisible(false)
    
    local buttonShown = false
    local roleDisplay = {}
    
    local function updateRoles()
        local roles = inspectRoleList()
        local curRole = inspectTEMPORARYRole()
        
        local object = roleSwitch
        
        for k, v in pairs(roleDisplay) do
            v:SetVisible(false)
        end
        
        for roleID, desc in pairs(roles) do
            local id = EnKai.tools.hex2number(roleID) + 1
            local thisRole
            
            if id == curRole then
                datasetRole:SetText(stringFormat("Active role: %s", desc))
            else
                if roleDisplay[roleID] == nil then
                    thisRole = EnKai.uiCreateFrame("nkText", name .. ".thisRole." .. id, roleSwitch)
                    thisRole:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
                    thisRole:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
                    thisRole:SetEffectGlow({ strength = 1})
                    thisRole:SetTextFont(addonInfo.id, "Montserrat")
                    thisRole:SetText(desc)
                    thisRole:SetSecureMode('restricted')
                    
                    local macro = "role " .. id
                    thisRole:EventMacroSet(Event.UI.Input.Mouse.Left.Click, macro)
                    
                    roleDisplay[roleID] = thisRole
                else
                    thisRole = roleDisplay[roleID]
                    thisRole:SetTextFont(addonInfo.id, "Montserrat")
                end
                
                thisRole:SetVisible(true)
                thisRole:SetPoint("BOTTOMCENTER", object, "TOPCENTER")
                
                object = thisRole
            end
        end
    end
    
    function datasetRole:Redraw()
        datasetRole:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
        
        for k, v in pairs(roleDisplay) do
            v:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
        end
    end
    
    updateRoles()
    
    datasetRole:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        if InspectSystemSecure() then return end
        
        buttonShown = not buttonShown
        roleSwitch:SetVisible(buttonShown)
    end, name .. "_Left_Click")
    
    Command.Event.Attach(Event.TEMPORARY.Role, function(handle, role)
        buttonShown = false
        updateRoles()
        roleSwitch:SetVisible(false)
    end, 'nkUI.lowerbar.role.TEMPORARY.role')
    
    table.insert(uiElements.lowerBarModules, datasetRole)
end