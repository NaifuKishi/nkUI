local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local events        = privateVars.events
local sct           = privateVars.sct

local name = "scrollingcombattext"

local framePool = {}
local activeFrames = {}
local sctInit = false

local context = UI.CreateContext("nkUI.SCT")
context:SetStrata('hud')
context:SetLayer(2)

-- Creates a new text frame for displaying combat text
-- @return The created text frame
local function createTextFrame()
    local name = LibEKL.Tools.UUID()
    local thisAddonID, thisFontName, thisFontSize, thisFontColor
    local thisTextureSource, thisTexture

    local frame = LibEKL.UICreateFrame("nkText", name, context)
    frame:SetEffectGlow({ strength = 3 })
    frame:SetVisible(false)

    -- Create an icon frame for the text frame
    local icon = LibEKL.UICreateFrame("nkTexture", name .. "." .. LibEKL.Tools.UUID(), frame)
    icon:SetPoint("CENTERRIGHT", frame, "CENTERLEFT", -5, 0)
    icon:SetVisible(false)
    icon:SetWidth(24)
    icon:SetHeight(24)

    local oSetTextFont = frame.SetTextFont
    function frame:SetTextFont(addonID, fontName)
        if addonID ~= thisAddonID or fontName ~= thisFontName then
            oSetTextFont(self, addonID, fontName)
            thisAddonID = addonID
            thisFontName = fontName
        end
    end

    local oSetFontSize = frame.SetFontSize
    function frame:SetFontSize(fontSize)
        if fontSize ~= thisFontSize then
            oSetFontSize(self, fontSize)
            thisFontSize = fontSize
        end
    end

    local oSetFontColor = frame.SetFontColor
    function frame:SetFontColor(r, g, b, a)
        if not thisFontColor or r ~= thisFontColor or g ~= thisFontColor.g or b ~= thisFontColor.b or a ~= thisFontColor.a then
            oSetFontColor(self, r, g, b, a)
            thisFontColor = { r = r, g = g, b = b, a = a }
        end
    end

    local oSetTextureAsync = icon.SetTextureAsync
    function frame:SetTextureAsync(source, texture)
        if source ~= thisTextureSource or texture ~= thisTexture then

            if not source or not texture then
                icon:SetVisible(false)
            else                
                icon:SetVisible(true)
                oSetTextureAsync(icon, source, texture)
                thisTextureSource = source
                thisTexture = texture
            end
        end
    end

    -- Store the icon frame in the text frame for later access
    frame.icon = icon

    return frame
end

-- Gets a frame from the pool or creates a new one
-- @return A text frame for displaying combat text
function sct.GetFrame()
    if #framePool > 0 then
        return table.remove(framePool)        
    else
        return createTextFrame()        
    end
end

-- Releases a frame back to the pool
-- @param frame The frame to release
function sct.ReleaseFrame(frame)
    frame:SetVisible(false)
    frame.icon:SetVisible(false)
    table.insert(framePool, frame)
end