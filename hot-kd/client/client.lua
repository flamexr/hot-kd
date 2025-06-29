local isUIVisible = false
local playerKDData = {kills = 0, deaths = 0, kd_ratio = 0.00}


function ToggleUI(show)
    if Config.ShowUI then
        isUIVisible = show
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = 'toggle',
            show = show
        })
    end
end


function UpdateUIData(data)
    playerKDData = data
    if isUIVisible then
        SendNUIMessage({
            type = 'updateData',
            data = {
                kills = data.kills or 0,
                deaths = data.deaths or 0,
                kd_ratio = data.kd_ratio or 0.00
            }
        })
    end
end


AddEventHandler('playerSpawned', function()
    Wait(9000)
    TriggerServerEvent('kd:playerConnected')
    ToggleUI(true)
end)


AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(7000)
        TriggerServerEvent('kd:requestData')
        ToggleUI(true)
    end
end)


AddEventHandler('baseevents:onPlayerDied', function(killerType, coords)
    TriggerServerEvent('kd:addDeath')
end)


AddEventHandler('baseevents:onPlayerKilled', function(killerId, data)
    if killerId == PlayerId() then
        TriggerServerEvent('kd:addKill')
    end
end)


RegisterNetEvent('kd:updateUI')
AddEventHandler('kd:updateUI', function(data)
    UpdateUIData(data)
end)


RegisterNUICallback('closeUI', function(data, cb)
    ToggleUI(false)
    cb('ok')
end)


RegisterCommand('kd', function()
    if isUIVisible then
        ToggleUI(false)
    else
        ToggleUI(true)
    end
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        local playerPed = PlayerPedId()
        
        if IsPedDeadOrDying(playerPed, true) then
            local killer = GetPedSourceOfDeath(playerPed)
            
            if IsEntityAPed(killer) and IsPedAPlayer(killer) then
                local killerPlayer = NetworkGetPlayerIndexFromPed(killer)
                local killerServerId = GetPlayerServerId(killerPlayer)
                
                if killerServerId ~= GetPlayerServerId(PlayerId()) then

                    TriggerServerEvent('kd:addDeath')
                    

                    TriggerServerEvent('kd:playerKilledSomeone', killerServerId)
                end
            else

                TriggerServerEvent('kd:addDeath')
            end
            

            while IsPedDeadOrDying(playerPed, true) do
                Citizen.Wait(100)
            end
        end
    end
end)
