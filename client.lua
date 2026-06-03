local function clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

local hudVisible = true

CreateThread(function()
    while true do
        Wait(0)
        HideHudComponentThisFrame(2)
        HideHudComponentThisFrame(3)
        HideHudComponentThisFrame(4)
        HideHudComponentThisFrame(6)
        HideHudComponentThisFrame(7)
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9)
        HideHudAndRadarThisFrame()
        DisplayRadar(true)
    end
end)

RegisterCommand('hud', function()
    SendNUIMessage({type = 'openCustomize'})
    SetNuiFocus(true, true)
end, false)

RegisterNUICallback('saveCustomization', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeCustomize', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

CreateThread(function()
    Wait(500)
    SendNUIMessage({
        type = 'setConfig',
        colors = Config.Colors,
        healthLowThreshold = Config.HealthLowThreshold,
        showVoice = Config.ShowVoiceIndicator,
        showStamina = Config.ShowStamina,
        showAmmo = Config.ShowAmmoCounter,
        showId = Config.ShowIdBox,
        speedUnit = Config.SpeedUnit,
    })
end)

CreateThread(function()
    while true do
        Wait(100)
        if not hudVisible then goto continue end

        local playerPed = PlayerPedId()
        local player = PlayerId()
        local health = GetEntityHealth(playerPed)
        local maxHealth = GetPedMaxHealth(playerPed)
        local healthPct = clamp(((health - 100) / (maxHealth - 100)) * 100, 0, 100)
        local armorPct = clamp(GetPedArmour(playerPed), 0, 100)

        if Config.UnlimitedStamina then
            SetPlayerStamina(player, 100.0)
        end
        local staminaPct = clamp(GetPlayerStamina(player), 0, 100)

        local isTalking = false
        if Config.ShowVoiceIndicator and NetworkIsPlayerTalking then
            isTalking = NetworkIsPlayerTalking(player)
        end

        local ammoCount = -1
        if Config.ShowAmmoCounter then
            local weapon = GetSelectedPedWeapon(playerPed)
            if weapon ~= nil and weapon ~= GetHashKey("WEAPON_UNARMED") then
                ammoCount = GetAmmoInPedWeapon(playerPed, weapon)
            else
                ammoCount = -1
            end
        end

        local speed = nil
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local speedMs = GetEntitySpeed(vehicle)
            if Config.SpeedUnit == "KPH" then
                speed = speedMs * 3.6
            else
                speed = speedMs * 2.236936
            end
        end

        SendNUIMessage({
            type = 'updateHud',
            health = math.floor(healthPct),
            armor = math.floor(armorPct),
            stamina = math.floor(staminaPct),
            talking = isTalking,
            ammo = ammoCount,
            playerId = GetPlayerServerId(player),
            speed = speed,
            inVehicle = IsPedInAnyVehicle(playerPed, false),
        })

        ::continue::
    end
end)

AddEventHandler('gameEventTriggered', function(name)
    if name == 'CEventNetworkEntityDamage' then
        local ped = PlayerPedId()
        if IsEntityDead(ped) then
            if Config.ShowOnDeath then
                SendNUIMessage({type = 'setDead', dead = true})
            else
                SendNUIMessage({type = 'setVisible', visible = false})
                hudVisible = false
            end
        end
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SendNUIMessage({type = 'setVisible', visible = true})
        SendNUIMessage({type = 'setDead', dead = false})
        hudVisible = true
    end
end)

AddEventHandler('baseevents:onPlayerLoaded', function()
    SendNUIMessage({type = 'setVisible', visible = true})
    SendNUIMessage({type = 'setDead', dead = false})
    hudVisible = true
end)

CreateThread(function()
    local wasDead = false
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local dead = IsEntityDead(ped)
        if wasDead and not dead then
            SendNUIMessage({type = 'setVisible', visible = true})
            SendNUIMessage({type = 'setDead', dead = false})
            hudVisible = true
        end
        wasDead = dead
    end
end)
