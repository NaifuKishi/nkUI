
local addonInfo, privateVars = ...

---------- init namespace ---------

local data        = privateVars.data
local uiElements  = privateVars.uiElements
local _internal   = privateVars.internal
local _events     = privateVars.events

---------- init local variables ---------

-- Cache frequently used functions and values
local InspectUnitDetail     = Inspect.Unit.Detail
local InspectBuffDetail     = Inspect.Buff.Detail
local InspectUnitLookup     = Inspect.Unit.Lookup

local mathFloor     = math.floor
local stringFormat  = string.format

---------- init global variables ---------

local name = "uiRessourceBar"

local ressourceColor = {
    energy = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = 1, g = .96, b = .41, a = 1, position = 0},  { r =.5, g = .5, b = .5, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}},
    power = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = 1, g = .5, b = .25, a = 1, position = 0},  { r =.5, g = .5, b = .5, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}},
    charge = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = .71, g = 1, b = .92, a = 1, position = 0},  { r =.5, g = .5, b = .5, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}},
    mana = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = 0, g = 0.82, b = 1, a = 1, position = 0},  { r =.5, g = .5, b = .5, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}},
    focus = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 1, 0, 0, 0), color = {{ r = 1, g = 0, b = 0, a = 1, position = 0}, { r = 0, g = .82, b = 1, a = 1, position = 1 }}},
    default = {type = "gradientLinear", transform = Utility.Matrix.Create(2, 2, (math.pi / 2), 0, 0), color = {{ r = .1, g = .1, b = .1, a = 1, position = 0},  { r =.5, g = .5, b = .5, a = 1, position = .2 },  { r = 0.5, g = .5, b = .5, a = 1, position = 1 }}}
}

-- ressource bar function

function _internal.ressourcBar (unit, scale, x, y)

    local thisName = name .. ".ressourceBar." .. unit
    local ressourceMax
    local comboIcon = {}
    
    local ressourceBGFrame = EnKai.uiCreateFrame("nkFrame", thisName .. ".ressourceBGFrame", uiElements.context)
    ressourceBGFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
    ressourceBGFrame:SetWidth(200 * scale)
    ressourceBGFrame:SetHeight(17 * scale)
    ressourceBGFrame:SetBackgroundColor(0, 0, 0, .25)
    ressourceBGFrame:SetVisible(false)

    local ressourceFrame = EnKai.uiCreateFrame("nkCanvas", thisName .. ".ressourceFrame", ressourceBGFrame)
    
    ressourceFrame:SetPoint("TOPLEFT", ressourceBGFrame, "TOPLEFT", 1, 1)
    ressourceFrame:SetWidth(198)
    ressourceFrame:SetHeight(15)    

    local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1 }
    local path = {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }  
  
    local ressourceText = EnKai.uiCreateFrame("nkText", thisName .. ".ressourceText", ressourceFrame)

    ressourceText:SetPoint("CENTER", ressourceBGFrame, "CENTER", 0, 10)

    ressourceText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    ressourceText:SetFontSize(20 * scale)
    ressourceText:SetFontColor(1, 1, 1, 1)
    ressourceText:SetEffectGlow({ strength = 1})

    local chargeBGFrame = EnKai.uiCreateFrame("nkFrame", thisName .. ".ressourceChargeBGFrame", ressourceBGFrame)
    chargeBGFrame:SetPoint ("BOTTOMCENTER", ressourceBGFrame, "TOPCENTER", 0, -2)
    chargeBGFrame:SetWidth(160)
    chargeBGFrame:SetHeight(12)
    chargeBGFrame:SetBackgroundColor(0, 0, 0, 1)
    chargeBGFrame:SetVisible(false)

    local chargeFrame = EnKai.uiCreateFrame("nkCanvas", thisName .. ".ressourceChargeFrame", chargeBGFrame)    
    chargeFrame:SetPoint("TOPLEFT", chargeBGFrame, "TOPLEFT", 1, 1)
    chargeFrame:SetWidth(158)
    chargeFrame:SetHeight(10)    
    chargeFrame:SetShape (path, ressourceColor["charge"], nil)
    chargeFrame:SetVisible(false)

    local chargeText = EnKai.uiCreateFrame("nkText", thisName .. ".chargeText", chargeFrame)
    chargeText:SetPoint("CENTER", chargeFrame, "CENTER", 0, -7)
    chargeText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    chargeText:SetFontSize(16 * scale)
    chargeText:SetFontColor(1, 1, 1, 1)
    chargeText:SetEffectGlow({ strength = 1})

    local comboFrame = EnKai.uiCreateFrame("nkFrame", thisName .. ".ressourceComboFrame", ressourceBGFrame)
    comboFrame:SetPoint ("BOTTOMCENTER", ressourceBGFrame, "TOPCENTER", 0, -2)
    comboFrame:SetWidth(158)
    comboFrame:SetHeight(12)
    comboFrame:SetVisible(false)

    local from, to, object, x, y = "TOPLEFT", "TOPLEFT", comboFrame, 0, 0
    local color = {
        {r = 1, g = .4, b = 0, a = 1},
        {r = .97, g = .38, b = 0, a = 1},
        {r = .94, g = .36, b = 0, a = 1},
        {r = .91, g = .34, b = 0, a = 1},
        {r = .88, g = .32, b = 0, a = 1}
    }

    for idx = 1, 5, 1 do
        local combo = EnKai.uiCreateFrame("nkFrame", thisName .. ".ressourceCombo." .. idx, comboFrame)
        combo:SetPoint(from, object, to, x, y)
        combo:SetWidth(30)
        combo:SetHeight(12)
        combo:SetBackgroundColor(0, 0, 0, 1)

        combo.inner = EnKai.uiCreateFrame("nkFrame", thisName .. ".ressourceCombo." .. idx .. ".inner", combo)
        combo.inner:SetPoint("TOPLEFT", combo, "TOPLEFT", 1, 1)
        combo.inner:SetWidth(28)
        combo.inner:SetHeight(10)
        combo.inner:SetBackgroundColor(color[idx].r, color[idx].g, color[idx].b, color[idx].a)

        table.insert(comboIcon, combo)

        to, object, x, y = "TOPRIGHT", combo, 2, 0
    end


    function ressourceBGFrame:SetRessourceType(ressourceType)
        local fill = ressourceColor[ressourceType or "default"]
        ressourceFrame:SetShape (path, fill, nil)

        if ressourceType == "energy" then
            ressourceBGFrame:SetMaxCombo(5)
        elseif ressourceType == "power" then
            ressourceBGFrame:SetMaxCombo(3)
        else
            comboFrame:SetVisible(false)
        end
    end

    function ressourceBGFrame:SetCharge(newCharge)
         if (newCharge) then
            chargeBGFrame:SetVisible(true)
            local chargePercent = (newCharge / 100)
            chargeText:SetText(stringFormat("%d", mathFloor(chargePercent*100)))
            chargeFrame:SetWidth(158 * scale * chargePercent)
        end
    end

    function ressourceBGFrame:SetRessourceMax(newMax)
        --print ("ressourceMax", newMax)
        ressourceMax = newMax
    end

    function ressourceBGFrame:SetMaxCombo(maxCombo)
        local width = maxCombo * 30
        width = width + ((maxCombo - 1) *2)
        comboFrame:SetWidth(width)
    end

    function ressourceBGFrame:SetCombo(newCombo)

        if newCombo == 0 then
            comboFrame:SetVisible(false)
        else
             comboFrame:SetVisible(true)
            for idx = 1, 5, 1 do
                if idx <= newCombo then
                    comboIcon[idx]:SetVisible(true)
                else
                    comboIcon[idx]:SetVisible(false)
                end
            end
        end
    end

    function ressourceBGFrame:SetRessource(ressource)
        if (ressource) then
            local playerRessourcePercent = (ressource / ressourceMax)
            ressourceText:SetText(stringFormat("%d", mathFloor(playerRessourcePercent*100)))
            ressourceFrame:SetWidth(198 * scale * playerRessourcePercent)
        end
    end

    return ressourceBGFrame

end
