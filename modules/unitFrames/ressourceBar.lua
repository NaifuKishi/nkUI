local addonInfo, privateVars = ...

---------- init namespace ---------

local data          = privateVars.data
local uiElements    = privateVars.uiElements
local internalFunc  = privateVars.internalFunc
local _events       = privateVars.events

---------- init local variables ---------

-- Cache frequently used functions and values
local InspectUnitDetail     = Inspect.Unit.Detail
local InspectBuffDetail     = Inspect.Buff.Detail
local InspectUnitLookup     = Inspect.Unit.Lookup

local mathFloor     = math.floor
local mathpi        = math.pi
local stringFormat  = string.format

---------- init global variables ---------

local name = "uiRessourceBar"

local ressourceColor = {}

-- ressource bar function

function internalFunc.ressourcBar (unit, setup)

    ressourceColor = data.colors.ressource[nkUISetup.modules.unitFrames.colorScheme]

    local thisName = name .. ".ressourceBar." .. unit
    local ressourceMax
    local comboIcon = {}
    
    local ressourceBGFrame = LibEKL.uiCreateFrame("nkFrame", thisName .. ".ressourceBGFrame", uiElements.contextLowest)
    ressourceBGFrame:SetPoint("CENTER", UIParent, "CENTER", setup.x, setup.y)
    ressourceBGFrame:SetWidth(setup.width)
    ressourceBGFrame:SetHeight(setup.height)
    ressourceBGFrame:SetBackgroundColor(0, 0, 0, .25)
    ressourceBGFrame:SetVisible(false)

    local ressourceFrame = LibEKL.uiCreateFrame("nkCanvas", thisName .. ".ressourceFrame", ressourceBGFrame)
    
    ressourceFrame:SetPoint("TOPLEFT", ressourceBGFrame, "TOPLEFT", 1, 1)
    ressourceFrame:SetWidth(setup.width - 2)
    ressourceFrame:SetHeight(setup.height -2)    
    ressourceFrame:SetLayer(1)

    local stroke = {r = 0, g = 0, b = 0, a = 1, thickness = 1 }
    local path = {  {xProportional = 0, yProportional = 0},
                  {xProportional = 1, yProportional = 0},
                  {xProportional = 1, yProportional = 1},
                  {xProportional = 0, yProportional = 1},
                  {xProportional = 0, yProportional = 0}
                  }  
  
    local ressourceText = LibEKL.uiCreateFrame("nkText", thisName .. ".ressourceText", ressourceFrame)

    local focusIndicator = LibEKL.uiCreateFrame("nkFrame", thisName .. ".focusIndicator", ressourceBGFrame)
    
    focusIndicator:SetPoint("TOPLEFT", ressourceBGFrame, "TOPLEFT", 0, -5)
    focusIndicator:SetWidth(4)
    focusIndicator:SetHeight(setup.height + 10)
    focusIndicator:SetBackgroundColor(1, 0.84, 0, 1)
    focusIndicator:SetVisible(false)
    focusIndicator:SetLayer(2)

    ressourceText:SetPoint("CENTER", ressourceBGFrame, "CENTER", 1, setup.margins.ressource)
    ressourceText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    ressourceText:SetFontSize(setup.fontSizes.ressource)
    ressourceText:SetFontColor(1, 1, 1, 1)
    ressourceText:SetEffectGlow({ strength = 3})
    ressourceText:SetLayer(3)

    local chargeBGFrame = LibEKL.uiCreateFrame("nkFrame", thisName .. ".ressourceChargeBGFrame", ressourceBGFrame)
    chargeBGFrame:SetPoint ("BOTTOMCENTER", ressourceBGFrame, "TOPCENTER", 0, -2)
    chargeBGFrame:SetWidth(setup.charge.width)
    chargeBGFrame:SetHeight(setup.charge.height)
    chargeBGFrame:SetBackgroundColor(0, 0, 0, 1)
    chargeBGFrame:SetVisible(false)

    local chargeFrame = LibEKL.uiCreateFrame("nkCanvas", thisName .. ".ressourceChargeFrame", chargeBGFrame)    
    chargeFrame:SetPoint("TOPLEFT", chargeBGFrame, "TOPLEFT", 1, 1)
    chargeFrame:SetWidth(setup.charge.width-2)
    chargeFrame:SetHeight(setup.charge.height-2)    
    chargeFrame:SetShape (path, ressourceColor["charge"], nil)
    --chargeFrame:SetVisible(false)

    local chargeText = LibEKL.uiCreateFrame("nkText", thisName .. ".chargeText", chargeFrame)
    chargeText:SetPoint("CENTER", chargeBGFrame, "CENTER", 1, -7)
    chargeText:SetTextFont(addonInfo.id, "MontserratSemiBold")
    chargeText:SetFontSize(setup.fontSizes.charge)
    chargeText:SetFontColor(1, 1, 1, 1)
    chargeText:SetEffectGlow({ strength = 3})

    local comboFrame = LibEKL.uiCreateFrame("nkFrame", thisName .. ".ressourceComboFrame", ressourceBGFrame)
    comboFrame:SetPoint ("BOTTOMCENTER", ressourceBGFrame, "TOPCENTER", 0, -2)
    comboFrame:SetWidth(setup.combo.width * 5 + 8) -- can be done better. 5 combo points width 2 pixel margin
    comboFrame:SetHeight(setup.combo.height)
    comboFrame:SetVisible(false)

    local from, to, object, x, y = "TOPLEFT", "TOPLEFT", comboFrame, 0, 0
    
    local color = data.colors.combo[nkUISetup.modules.unitFrames.colorScheme]

    for idx = 1, 5, 1 do
        local combo = LibEKL.uiCreateFrame("nkFrame", thisName .. ".ressourceCombo." .. idx, comboFrame)
        combo:SetPoint(from, object, to, x, y)
        combo:SetWidth(setup.combo.width)
        combo:SetHeight(setup.combo.height)
        combo:SetBackgroundColor(0, 0, 0, 1)

        combo.inner = LibEKL.uiCreateFrame("nkFrame", thisName .. ".ressourceCombo." .. idx .. ".inner", combo)
        combo.inner:SetPoint("TOPLEFT", combo, "TOPLEFT", 1, 1)
        combo.inner:SetWidth(setup.combo.width-2)
        combo.inner:SetHeight(setup.combo.height-2)
        combo.inner:SetBackgroundColor(color[idx].r, color[idx].g, color[idx].b, color[idx].a)

        table.insert(comboIcon, combo)

        to, object, x, y = "TOPRIGHT", combo, 2, 0
    end


    function ressourceBGFrame:SetRessourceType(ressourceType)
        local fill = ressourceColor[ressourceType or "default"]
        ressourceFrame:SetShape (path, fill, nil)

        if ressourceType == "energy" then
            ressourceBGFrame:SetMaxCombo(5)
            focusIndicator:SetVisible(false)
        elseif ressourceType == "power" then
            ressourceBGFrame:SetMaxCombo(3)
            focusIndicator:SetVisible(false)
        elseif ressourceType == "focus" then
            focusIndicator:SetVisible(true)
            comboFrame:SetVisible(false)
        else
            comboFrame:SetVisible(false)
            focusIndicator:SetVisible(false)
        end
    end

    function ressourceBGFrame:SetCharge(newCharge)
         if (newCharge) then
            chargeBGFrame:SetVisible(true)
            local chargePercent = (newCharge / 100)
            chargeText:SetText(stringFormat("%d", mathFloor(chargePercent*100)))
            chargeFrame:SetWidth((setup.charge.width - 2) * chargePercent)
        end
    end

    function ressourceBGFrame:SetFocus(newFocus)
        -- goes from 0 to 200 while 100 is the middle

        local focus = newFocus or 0
        if focus > 100 then 
            focus = focus - 100 
        else
            focus = 100 - focus
        end

        local percent = newFocus / 200
        local x = setup.width * percent

        focusIndicator:SetPoint("TOPLEFT", ressourceBGFrame, "TOPLEFT", x , -5)

        ressourceText:SetText(stringFormat("%d", focus))
    end

    function ressourceBGFrame:SetRessourceMax(newMax)
        ressourceMax = newMax
    end

    function ressourceBGFrame:SetMaxCombo(maxCombo)
        local width = maxCombo * setup.combo.width
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
            --if ressourceMax == nil then ressourceMax = ressource end

            if ressource > ressourceMax then ressourceMax = ressource end            

            local playerRessourcePercent = (ressource / ressourceMax)

            ressourceText:SetText(stringFormat("%d", mathFloor(playerRessourcePercent*100)))
            ressourceFrame:SetWidth((setup.width -2) * playerRessourcePercent)
        end
    end

    function ressourceBGFrame:Redraw(newSetup)

        ressourceBGFrame:SetWidth(setup.width)
        ressourceBGFrame:SetHeight(setup.height)        
        ressourceFrame:SetWidth(setup.width - 2)
        ressourceFrame:SetHeight(setup.height -2)

        ressourceText:SetFontSize(setup.fontSizes.ressource)

        chargeBGFrame:SetWidth(setup.charge.width)
        chargeBGFrame:SetHeight(setup.charge.height)
        chargeFrame:SetWidth(setup.charge.width-2)
        chargeFrame:SetHeight(setup.charge.height-2)   
        chargeText:SetFontSize(setup.fontSizes.charge) 
        
        comboFrame:SetWidth(setup.combo.width * 5 + 8) -- can be done better. 5 combo points width 2 pixel margin
        comboFrame:SetHeight(setup.combo.height)

        for idx = 1, 5, 1 do
            comboIcon[idx]:SetWidth(setup.combo.width)
            comboIcon[idx]:SetHeight(setup.combo.height)

            comboIcon[idx].inner:SetWidth(setup.combo.width-2)
            comboIcon[idx].inner:SetHeight(setup.combo.height-2)
        end

        LibEKL.ui.reloadDialog ("nkUI")

    end

    return ressourceBGFrame

end
