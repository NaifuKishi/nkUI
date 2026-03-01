local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local lowerBar      = privateVars.lowerBar
local langTexts     = privateVars.langTexts

---------- init local variables ---------

local inspectRoleList      = Inspect.Role.List
local inspectTEMPORARYRole = Inspect.TEMPORARY.Role
local inspectSystemSecure  = Inspect.System.Secure

local stringFormat         = string.format

---------- local functions ---------

-- Creates and manages the role selection display
function lowerBar.lowerBarRoles()

    local datasetFrame = lowerBar.dataSet("lowerBar.datasetroles", "gfx/lowerbarRole.png", "left", true)

    local roleSwitch = LibEKL.UICreateFrame("nkFrame", "lowerBar.datasetroles.switch", datasetFrame)
    roleSwitch:SetPoint("BOTTOMLEFT", datasetFrame, "TOPLEFT")
    roleSwitch:SetSecureMode('restricted')
    roleSwitch:SetHeight(1)
    roleSwitch:SetVisible(false)
    
    local buttonShown = false
    local roleDisplay = {}
    
    local function updateRoles()
        if inspectSystemSecure() == true then return end

        local roles = inspectRoleList()
        local curRole = inspectTEMPORARYRole()
        
        local object = roleSwitch
        
        for k, v in pairs(roleDisplay) do
            v:SetVisible(false)
        end
        
        for roleID, desc in pairs(roles) do
            local id = LibEKL.Tools.Math.Hex2number(roleID) + 1
            local thisRole
            
            if id == curRole then
                datasetFrame:SetText(stringFormat(langTexts.lowerBar.role, desc), true)
            else
                if roleDisplay[roleID] == nil then
                    thisRole = LibEKL.UICreateFrame("nkText", "lowerBar.datasetroles.thisRole." .. id, roleSwitch)
                    thisRole:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
                    thisRole:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
                    thisRole:SetEffectGlow({ strength = 1})
                    thisRole:SetTextFont(addonInfo.id, "MontserratMedium")
                    thisRole:SetText(desc)
                    thisRole:SetSecureMode('restricted')
                    
                    local macro = "role " .. id
                    thisRole:EventMacroSet(Event.UI.Input.Mouse.Left.Click, macro)
                    
                    roleDisplay[roleID] = thisRole
                else
                    thisRole = roleDisplay[roleID]
                    thisRole:SetTextFont(addonInfo.id, "MontserratMedium")
                end
                
                thisRole:SetVisible(true)
                thisRole:SetPoint("BOTTOMCENTER", object, "TOPCENTER")
                
                object = thisRole
            end
        end
    end
    
    function datasetFrame:Redraw()
        datasetFrame:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
        
        for k, v in pairs(roleDisplay) do
            v:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
        end
    end
    
    updateRoles()
    
    datasetFrame:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        if inspectSystemSecure() then return end
        
        buttonShown = not buttonShown
        roleSwitch:SetVisible(buttonShown)
    end, "lowerBar.datasetroles._Left_Click")
    
    Command.Event.Attach(Event.TEMPORARY.Role, function(handle, role)
        buttonShown = false
        updateRoles()
        roleSwitch:SetVisible(false)
    end, 'nkUI.lowerbar.role.TEMPORARY.role')
    
    return datasetFrame
end