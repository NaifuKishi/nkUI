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

    local name = "lowerBar.datasetroles"
    local width = (uiElements.lowerBarCanvas:GetWidth() - uiElements.lowerBarTimeDate:GetWidth()) /8
    local height = uiElements.lowerBarCanvas:GetHeight()

    local datasetFrame = LibEKL.UICreateFrame("nkFrame", name .. ".frame", lowerBar.contextRestricted)
    datasetFrame:SetWidth(width)
    datasetFrame:SetHeight(height)
    datasetFrame:SetPoint("CENTERLEFT", uiElements.lowerBarCanvas, "CENTERLEFT", width * 2, 0)    
    --datasetFrame:SetBackgroundColor(1, 0, 0, 1)
    datasetFrame:SetSecureMode('restricted')
    datasetFrame:SetLayer(2)    
    
    local datasetRole = LibEKL.UICreateFrame("nkText", name .. ".text", lowerBar.contextRestricted)
    datasetRole:SetPoint("CENTER", datasetFrame, "CENTER", -21 , 0)
    datasetRole:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
    datasetRole:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
    datasetRole:SetTextFont(addonInfo.id, "MontserratMedium")
    datasetRole:SetEffectGlow(data.theme.GLOW_WEAK)
    datasetRole:SetSecureMode('restricted')
    datasetRole:SetLayer(5)

    local datasetRoleIcon = LibEKL.UICreateFrame("nkTexture", name .. ".icon", datasetFrame)
    datasetRoleIcon:SetPoint("CENTERRIGHT", datasetRole, "CENTERLEFT", -5, -2)
    datasetRoleIcon:SetHeight(16)
    datasetRoleIcon:SetWidth(16)
    datasetRoleIcon:SetSecureMode('restricted')
    datasetRoleIcon:SetTextureAsync("nkUI", "gfx/lowerbarRole.png")
    
    local roleSwitch = LibEKL.UICreateFrame("nkFrame", name .. ".switch", datasetRole)
    roleSwitch:SetPoint("BOTTOMCENTER", datasetRole, "TOPCENTER")
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
                datasetRole:SetText(stringFormat(langTexts.lowerBar.role, desc), true)
            else
                if roleDisplay[roleID] == nil then
                    thisRole = LibEKL.UICreateFrame("nkText", name .. ".thisRole." .. id, roleSwitch)
                    thisRole:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
                    thisRole:SetFontColor(data.colors.primary.r, data.colors.primary.g, data.colors.primary.b, data.colors.primary.a)
                    thisRole:SetEffectGlow(data.theme.GLOW_WEAK)
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
        datasetRole:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
        
        for k, v in pairs(roleDisplay) do
            v:SetFontSize(nkUISetup.modules.lowerBar.fontSize)
        end
    end
    
    updateRoles()
    
    datasetFrame:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
        if inspectSystemSecure() then return end
        
        buttonShown = not buttonShown
        roleSwitch:SetVisible(buttonShown)
    end, name .. "_Left_Click")
    
    Command.Event.Attach(Event.TEMPORARY.Role, function(handle, role)
        buttonShown = false
        updateRoles()
        roleSwitch:SetVisible(false)
    end, 'nkUI.lowerbar.role.TEMPORARY.role')
    
    table.insert(uiElements.lowerBarModules, datasetFrame)
end