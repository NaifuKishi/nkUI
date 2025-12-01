local addonInfo, privateVars = ...

---------- init namespace ---------

local data      = privateVars.data
local uiElements= privateVars.uiElements
local _internal = privateVars.internal
local _events   = privateVars.events
local oFuncs    = privateVars.oFuncs

---------- init local variables ---------

local InspectMouse  = Inspect.Mouse

local function _moveFrame (x, y, height, width, label, callBack)

    local name = "nkUI.moveFrame." .. label

    local frame = uiElements.EnKai.uiCreateFrame("nkFrame", name, UIParent)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
    frame:SetBackgroundColor(0.529, 0.808, 0.922, 0.5)
    
    local text = uiElements.EnKai.uiCreateFrame("nkText", name .. ".text", frame)
    text:SetFontSize(16)
    text:SetPoint("CENTER", frame, "CENTER")
    text:SetFontColor(1, 1, 1, 1)
    text:SetText(label)

    frame:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)            
        self.leftDown = true
        local mouse = InspectMouse()

        self.originalXDiff = mouse.x - self:GetLeft()
        self.originalYDiff = mouse.y - self:GetTop()

        local left, top, right, bottom = window:GetBounds()

        frame:ClearPoint("TOPLEFT")
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, top)
    end, name .. ".Left.Down")

    frame:EventAttach( Event.UI.Input.Mouse.Cursor.Move, function (self, _, x, y)  
        if self.leftDown ~= true then return end

        local newX, newY = x - self.originalXDiff, y - self.originalYDiff

        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", newX, newY)
    end, name .. ".Cursor.Move")

    frame:EventAttach( Event.UI.Input.Mouse.Left.Up, function (self) 
        if self.leftDown ~= true then return end
        self.leftDown = false
        
        callBack(self:GetLeft(), self:GetTop())
    end, name .. ".Left.Up")

    header:EventAttach( Event.UI.Input.Mouse.Left.Upoutside, function (self)
        if self.leftDown ~= true then return end
        self.leftDown = false      
        callBack(self:GetLeft(), self:GetTop())  
    end , name .. ".Left.Upoutside")
  
    return frame

end

function _internal.initMove ()



end