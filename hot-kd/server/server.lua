
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS player_kd (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL UNIQUE,
            kills INT DEFAULT 0,
            deaths INT DEFAULT 0,
            kd_ratio DECIMAL(10,2) DEFAULT 0.00,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]], {})
end)


function GetPlayerKDData(identifier)
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_kd WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
    
    if result[1] then
        return result[1]
    else

        MySQL.Async.execute('INSERT INTO player_kd (identifier, kills, deaths, kd_ratio) VALUES (@identifier, 0, 0, 0.00)', {
            ['@identifier'] = identifier
        })
        return {identifier = identifier, kills = 0, deaths = 0, kd_ratio = 0.00}
    end
end


function CalculateKDRatio(kills, deaths)
    if deaths == 0 then
        return kills
    else
        return math.floor((kills / deaths) * 100) / 100
    end
end


function UpdateKills(identifier, kills)
    local playerData = GetPlayerKDData(identifier)
    local newKills = playerData.kills + kills
    local kdRatio = CalculateKDRatio(newKills, playerData.deaths)
    
    MySQL.Async.execute('UPDATE player_kd SET kills = @kills, kd_ratio = @kd_ratio WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@kills'] = newKills,
        ['@kd_ratio'] = kdRatio
    })
    
    return {kills = newKills, deaths = playerData.deaths, kd_ratio = kdRatio}
end


function UpdateDeaths(identifier, deaths)
    local playerData = GetPlayerKDData(identifier)
    local newDeaths = playerData.deaths + deaths
    local kdRatio = CalculateKDRatio(playerData.kills, newDeaths)
    
    MySQL.Async.execute('UPDATE player_kd SET deaths = @deaths, kd_ratio = @kd_ratio WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@deaths'] = newDeaths,
        ['@kd_ratio'] = kdRatio
    })
    
    return {kills = playerData.kills, deaths = newDeaths, kd_ratio = kdRatio}
end


RegisterServerEvent('kd:playerConnected')
AddEventHandler('kd:playerConnected', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local playerData = GetPlayerKDData(identifier)
    
    TriggerClientEvent('kd:updateUI', src, playerData)
end)


RegisterServerEvent('kd:addKill')
AddEventHandler('kd:addKill', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local updatedData = UpdateKills(identifier, 1)
    
    TriggerClientEvent('kd:updateUI', src, updatedData)
    print(GetPlayerName(src) .. ' kill aldı! Yeni K/D: ' .. updatedData.kd_ratio)
end)


RegisterServerEvent('kd:addDeath')
AddEventHandler('kd:addDeath', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local updatedData = UpdateDeaths(identifier, 1)
    
    TriggerClientEvent('kd:updateUI', src, updatedData)
    print(GetPlayerName(src) .. ' öldü! Yeni K/D: ' .. updatedData.kd_ratio)
end)


RegisterServerEvent('kd:requestData')
AddEventHandler('kd:requestData', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local playerData = GetPlayerKDData(identifier)
    
    TriggerClientEvent('kd:updateUI', src, playerData)
end)


RegisterServerEvent('kd:playerKilledSomeone')
AddEventHandler('kd:playerKilledSomeone', function(killerServerId)
    local src = source
    

    if killerServerId and GetPlayerName(killerServerId) then
        local killerIdentifier = GetPlayerIdentifier(killerServerId, 0)
        local updatedData = UpdateKills(killerIdentifier, 1)
        
        TriggerClientEvent('kd:updateUI', killerServerId, updatedData)
        print(GetPlayerName(killerServerId) .. ' bir oyuncuyu öldürdü! Yeni K/D: ' .. updatedData.kd_ratio)
    end
end)


RegisterCommand('resetkd', function(source, args, rawCommand)
    if source == 0 then -- sadece konsol gencolar
        if args[1] then
            local targetId = tonumber(args[1])
            if GetPlayerName(targetId) then
                local identifier = GetPlayerIdentifier(targetId, 0)
                MySQL.Async.execute('UPDATE player_kd SET kills = 0, deaths = 0, kd_ratio = 0.00 WHERE identifier = @identifier', {
                    ['@identifier'] = identifier
                })
                TriggerClientEvent('kd:updateUI', targetId, {kills = 0, deaths = 0, kd_ratio = 0.00})
                print('Oyuncu ' .. GetPlayerName(targetId) .. ' K/D verisi sıfırlandı.')
            else
                print('Geçersiz oyuncu ID!')
            end
        else
            print('Kullanım: resetkd [oyuncu_id]')
        end
    end
end, true)
