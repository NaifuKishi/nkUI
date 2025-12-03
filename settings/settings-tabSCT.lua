local addonInfo, privateVars = ...

---------- init namespace ---------

local _internal = privateVars.internal
local _settings = privateVars.settings

local stringFormat = string.format

---------- init local variables ---------

function _settings.uiConfigTabSCT (name, parent)

    local frame = EnKai.uiCreateFrame("nkFrame", name, parent)
    local activateCheckbox

    function frame:build()

        activateCheckbox = _settings.checkbox(name .. ".activateCheckbox", frame, "Activate this module", true, function(newValue)        
             nkUISetup.modules.sct.activate = newValue
            _internal.sctToggle(newValue)

            --if messageOffsetSizeSlider then messageOffsetSizeSlider:SetActive(newValue) end
        end)

        activateCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5)
        activateCheckbox:SetChecked(nkUISetup.modules.sct.activate, true)

        local moduleActive = nkUISetup.modules.sct.activate

        --[[positionHeader = _settings.header ( name .. ".positionHeader", frame, "Vertical offsets")
        positionHeader:SetPoint("TOPLEFT", activateCheckbox, "BOTTOMLEFT" , 0, 15)

        messageOffsetSizeSlider = _settings.slider (name .. ".messageOffsetSizeSlider", frame, "Message offset <font color='#3399FF'>%d</font>", moduleActive, function (newValue)
            nkUISetup.modules.sct.messageOffset = newValue
        end)
        
        messageOffsetSizeSlider:SetPoint("TOPLEFT", positionHeader, "BOTTOMLEFT", 0, 15)
        messageOffsetSizeSlider:SetRange(-400, 200)
        messageOffsetSizeSlider:SetMidValue(0)
        messageOffsetSizeSlider:SetPrecision(1)
        messageOffsetSizeSlider:AdjustValue(nkUISetup.modules.sct.messageOffset)]]
    end

    return frame

end