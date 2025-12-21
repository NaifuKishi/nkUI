local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local _events       = privateVars.events

---------- init local variables ---------

local InspectMouse  = Inspect.Mouse

local stringFormat  = string.format
local mathFloor     = math.floor

local gridFrames = {}
local moveFrames = {}
local buffBarFrame
local moveActive = false

local function _moveFrame (moveFrame, label, callBack)

    local name = EnKai.tools.uuid()
    local width, height = moveFrame:GetWidth(), moveFrame:GetHeight()
   
    local info = moveFrame:ReadAll()

    local x, y = info.x[0.5].offset, info.y[0.5].offset    
    local newX, newY

    local frame = EnKai.uiCreateFrame("nkFrame", name, uiElements.contextTooltip)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    frame:SetBackgroundColor(0.529, 0.808, 0.922, 1)
    
    local text = EnKai.uiCreateFrame("nkText", name .. ".text", frame)
    text:SetFontSize(16)
    text:SetPoint("CENTER", frame, "CENTER")
    text:SetFontColor(1, 1, 1, 1)
    text:SetText(label)
    text:SetTextFont(addonInfo.id, "MontserratSemiBold")

    moveFrame:SetPoint("CENTER", frame, "CENTER")

    frame:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)            
        self.leftDown = true
        local mouse = InspectMouse()

        self.originalXDiff = mouse.x - x
        self.originalYDiff = mouse.y - y
    end, name .. ".Left.Down")

    frame:EventAttach( Event.UI.Input.Mouse.Cursor.Move, function (self, _, x, y)  
        if self.leftDown ~= true then return end

        newX, newY = x - self.originalXDiff, y - self.originalYDiff

        text:SetText(stringFormat("%s (%d/%d)", label, newX, newY))

        frame:SetPoint("CENTER", UIParent, "CENTER", newX, newY)
    end, name .. ".Cursor.Move")

    frame:EventAttach( Event.UI.Input.Mouse.Left.Up, function (self) 
        if self.leftDown ~= true then return end
        self.leftDown = false

        x, y = newX, newY
        
        callBack(newX, newY)
    end, name .. ".Left.Up")

    frame:EventAttach( Event.UI.Input.Mouse.Left.Upoutside, function (self)
        if self.leftDown ~= true then return end
        self.leftDown = false      

        callBack(newX, newY)
    end , name .. ".Left.Upoutside")
  
    return frame

end

function internalFunc.initMove ()

    if uiElements.frames["player"] then
        table.insert(moveFrames, _moveFrame (uiElements.frames["player"], "PLAYER FRAME", function (newX, newY)
            nkUISetup.modules.unitFrames.frames.player.x = newX
            nkUISetup.modules.unitFrames.frames.player.y = newY        
        end))
    end

    if uiElements.frames["player.pet"] then
        table.insert(moveFrames, _moveFrame (uiElements.frames["player.pet"], "PET FRAME", function (newX, newY)
            nkUISetup.modules.unitFrames.frames.playerPet.x = newX
            nkUISetup.modules.unitFrames.frames.playerPet.y = newY        
        end))
    end

    if uiElements.frames["player.target"] then
        table.insert(moveFrames, _moveFrame (uiElements.frames["player.target"], "TARGET FRAME", function (newX, newY)
            nkUISetup.modules.unitFrames.frames.target.x = newX
            nkUISetup.modules.unitFrames.frames.target.y = newY        
        end))
    end

    if uiElements.frames["focus"] then
        table.insert(moveFrames, _moveFrame (uiElements.frames["focus"], "FOCUS FRAME", function (newX, newY)
            nkUISetup.modules.unitFrames.frames.focus.x = newX
            nkUISetup.modules.unitFrames.frames.focus.y = newY        
        end))
    end

    if uiElements.frames["group01"] then
        table.insert(moveFrames, _moveFrame (uiElements.frames["group01"], "GROUP FRAME", function (newX, newY)
            nkUISetup.modules.unitFrames.frames.group.x = newX
            nkUISetup.modules.unitFrames.frames.group.y = newY        
        end))
    end

    if uiElements.frames["raid01"] then
        table.insert(moveFrames, _moveFrame (uiElements.frames["raid01"], "RAID FRAME", function (newX, newY)
            nkUISetup.modules.unitFrames.frames.raid.x = newX
            nkUISetup.modules.unitFrames.frames.raid.y = newY        
        end))
    end

    if uiElements.frames["player.ressourcebar"] then
        table.insert(moveFrames, _moveFrame (uiElements.frames["player.ressourcebar"], "RESSOURCE BAR", function (newX, newY)
            nkUISetup.modules.unitFrames.frames.ressourceBar.x = newX
            nkUISetup.modules.unitFrames.frames.ressourceBar.y = newY        
        end))
    end

    if uiElements.frames["player.castbar"] then
        table.insert(moveFrames, _moveFrame (uiElements.frames["player.castbar"], "PLAYER CASTBAR", function (newX, newY)
            nkUISetup.modules.unitFrames.frames.playerCastBar.x = newX
            nkUISetup.modules.unitFrames.frames.playerCastBar.y = newY        
        end))
    end

    if uiElements.frames["player.target.castbar"] then
        table.insert(moveFrames, _moveFrame (uiElements.frames["player.target.castbar"], "TARGET CASTBAR", function (newX, newY)
            nkUISetup.modules.unitFrames.frames.targetCastBar.x = newX
            nkUISetup.modules.unitFrames.frames.targetCastBar.y = newY        
        end))
    end

    if uiElements.actionbars.main then
        table.insert(moveFrames, _moveFrame (uiElements.actionbars.main, "ACTION BAR", function (newX, newY)
            nkUISetup.modules.actionBars.x = newX
            nkUISetup.modules.actionBars.y = newY        
        end))
    end

    if uiElements.actionbars.rightScreen then
        table.insert(moveFrames, _moveFrame (uiElements.actionbars.rightScreen, "RIGHT BAR", function (newX, newY)
            nkUISetup.modules.actionBars.rightBarX = newX
            nkUISetup.modules.actionBars.rightBarY = newY        
        end))
    end

    if nkUISetup.modules.buffBar.activate then
        buffBarFrame = EnKai.uiCreateFrame("nkFrame", EnKai.tools.uuid(), uiElements.contextDialog)
        buffBarFrame:SetPoint("CENTER", UIParent, "CENTER", nkUISetup.modules.buffBar.x, nkUISetup.modules.buffBar.y)
        buffBarFrame:SetWidth(nkUISetup.modules.buffBar.buffs.width)
        buffBarFrame:SetHeight(nkUISetup.modules.buffBar.buffs.height)

        table.insert(moveFrames, _moveFrame (buffBarFrame, "BUFF BAR", function (newX, newY)
            nkUISetup.modules.buffBar.x = newX
            nkUISetup.modules.buffBar.y = newY        
        end))
    end
    
    local height = UIParent:GetHeight()
    local width = UIParent:GetWidth()

    local stroke = {r = .6, g = .6, b = .6, a = .5, thickness = 1 }
    local path =  {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }  

    for idx = 1, mathFloor((height / 2) / 25), 1 do
        local thisGrid = EnKai.uiCreateFrame("nkCanvas", EnKai.tools.uuid(), uiElements.contextLowestRestricted)
        thisGrid:SetPoint("CENTER", UIParent, "CENTER", 0, idx * 25)
        thisGrid:SetShape(path, nil, stroke)
        thisGrid:SetWidth(width)
        thisGrid:SetHeight(25)

        table.insert(gridFrames, thisGrid)
    end

    for idx = 1, mathFloor((height / 2) / 25), 1 do
        local thisGrid = EnKai.uiCreateFrame("nkCanvas", EnKai.tools.uuid(), uiElements.contextLowestRestricted)
        thisGrid:SetPoint("CENTER", UIParent, "CENTER", 0, idx * -25)
        thisGrid:SetShape(path, nil, stroke)
        thisGrid:SetWidth(width)
        thisGrid:SetHeight(25)

        table.insert(gridFrames, thisGrid)
    end    

    for idx = 1, mathFloor((width / 2) / 25), 1 do
        local thisGrid = EnKai.uiCreateFrame("nkCanvas", EnKai.tools.uuid(), uiElements.contextLowestRestricted)
        thisGrid:SetPoint("CENTER", UIParent, "CENTER", idx * 25, 0)
        thisGrid:SetShape(path, nil, stroke)
        thisGrid:SetWidth(25)
        thisGrid:SetHeight(height)

        table.insert(gridFrames, thisGrid)
    end

    for idx = 1, mathFloor((width / 2) / 25), 1 do
        local thisGrid = EnKai.uiCreateFrame("nkCanvas", EnKai.tools.uuid(), uiElements.contextLowestRestricted)
        thisGrid:SetPoint("CENTER", UIParent, "CENTER", idx * -25, 0)
        thisGrid:SetShape(path, nil, stroke)
        thisGrid:SetWidth(25)
        thisGrid:SetHeight(height)

        table.insert(gridFrames, thisGrid)
    end

    EnKai.ui.reloadDialog ("Reload after you are done moving")

end