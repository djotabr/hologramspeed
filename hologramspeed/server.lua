-- Função para garantir que a coluna 'topspeed' exista na tabela 'player_vehicles'
local function ensureTopSpeedColumn()
    -- Consulta para verificar se a coluna 'topspeed' já existe
    local query = [[
        SELECT COLUMN_NAME 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'player_vehicles' AND COLUMN_NAME = 'topspeed'
    ]]
    
    -- Executar a consulta no banco de dados
    MySQL.Async.fetchAll(query, {}, function(result)
        if #result == 0 then
            -- Se não encontrar a coluna, adiciona a coluna 'topspeed' na tabela 'player_vehicles'
            local alterTableQuery = [[
                ALTER TABLE player_vehicles 
                ADD COLUMN topspeed INT(11) DEFAULT 0
            ]]
            MySQL.Async.execute(alterTableQuery, {}, function(rowsChanged)
                if rowsChanged > 0 then
                    print("Coluna 'topspeed' adicionada com sucesso à tabela 'player_vehicles'.")
                else
                    print("Erro ao tentar adicionar a coluna 'topspeed' à tabela 'player_vehicles'.")
                end
            end)
        else
            -- print("A coluna 'topspeed' já existe na tabela 'player_vehicles'.")
        end
    end)
end

-- Evento para iniciar o resource e garantir que a coluna 'topspeed' exista
AddEventHandler('onResourceStart', function(resourceName)
	local resourceName = GetCurrentResourceName()
    if GetCurrentResourceName() == resourceName then
		-- print(resourceName,'Mecanica DJota Carregada!')
        ensureTopSpeedColumn()
    end
end)



RegisterServerEvent('HologramSpeed:CheckTheme')

local resourceName = GetCurrentResourceName()
local lowerCaseName = string.lower(resourceName)
if lowerCaseName ~= resourceName then
	print(string.format("\n^1Please rename the resource %s to %s or a similar name with ^8no^1 capital letters.^7\nDue to NUI restrictions, the resource will ^1not^7 work until you do this!!!\n", resourceName, lowerCaseName))
else
	SetConvarReplicated("hsp_defaultTheme", "default")
end

-- AddEventHandler('HologramSpeed:CheckTheme', function(theme)
-- 	local netID = source
-- 	if theme == 'default' then
-- 		TriggerClientEvent('HologramSpeed:SetTheme', netID, theme)
-- 	elseif string.match(theme, '(%w+)') then
-- 		local path = string.format("%s/ui/css/themes/%s.css", GetResourcePath(GetCurrentResourceName()), theme)
-- 		local file = io.open(path,"r")
-- 		if file ~= nil then
-- 			io.close(file)
-- 			TriggerClientEvent('HologramSpeed:SetTheme', netID, theme)
-- 		else
-- 			TriggerClientEvent('chat:addMessage', netID, {args = {"Cannot find the theme ^1" .. theme .. "^r!"}})
-- 		end
-- 	else
-- 		TriggerClientEvent('chat:addMessage', netID, {args = {"Invalid theme name ^1" .. theme .. "^r!"}})
-- 	end
-- end)

-- ======== teste=======

-- Função para buscar o valor de topspeed usando a placa do veículo
	function getTopSpeedByPlate(plate)
		-- print("Placa:", plate)
		-- local plate = '82YGL198'
		-- Correção da consulta SQL, utilizando o valor da variável plate
		local results = MySQL.query.await("SELECT topspeed FROM player_vehicles WHERE plate = ?", {plate})
	
		-- Exibe o conteúdo completo dos resultados da consulta
		-- print("Resultados da consulta:", json.encode(results))
	
		-- Se os resultados não estiverem vazios, exibe e retorna o topspeed
		if results and #results > 0 then
			local topspeed = tonumber(results[1].topspeed) -- Seleciona o primeiro resultado e converte para número
			-- print("Top Speed encontrado:", topspeed)
			return topspeed
		else
			-- print("Nenhum Top Speed encontrado para a placa:", plate)
			return 0 -- Retorna 0 se não encontrar valor
		end
	end


	lib.callback.register('HologramSpeed:topSpeed', function(source, plate)
		-- print("Placa no callback:", plate)
		return getTopSpeedByPlate(plate)
		
	end)

	function updateTopSpeed(plate,speed)
		-- print("Atualizando TopSpeed")
		-- local plate = '82YGL198'
		-- Correção da consulta SQL, utilizando o valor da variável plate
		local update = MySQL.Async.execute("UPDATE player_vehicles SET topspeed = ? WHERE plate = ?", {speed,plate})
	
	end


	lib.callback.register('HologramSpeed:updateTopSpeed', function(source, plate, speed)
		
		return updateTopSpeed(plate,speed)
		
	end)






	
	-- Evento que verifica o tema e usa o valor de topspeed
	RegisterServerEvent('HologramSpeed:CheckTheme')
	
	local resourceName = GetCurrentResourceName()
	local lowerCaseName = string.lower(resourceName)
	if lowerCaseName ~= resourceName then
		print(string.format("\n^1Please rename the resource %s to %s or a similar name with ^8no^1 capital letters.^7\nDue to NUI restrictions, the resource will ^1not^7 work until you do this!!!\n", resourceName, lowerCaseName))
	else
		SetConvarReplicated("hsp_defaultTheme", "default")
	end
	
	AddEventHandler('HologramSpeed:CheckTheme', function(theme, plate)
		local netID = source
		
		-- Chama a função para obter o topspeed do veículo usando a placa
		if theme == 'default' then
			TriggerClientEvent('HologramSpeed:SetTheme', netID, theme)
		elseif string.match(theme, '(%w+)') then
			local path = string.format("%s/ui/css/themes/%s.css", GetResourcePath(GetCurrentResourceName()), theme)
			local file = io.open(path, "r")
			if file ~= nil then
				io.close(file)
				TriggerClientEvent('HologramSpeed:SetTheme', netID, theme)
			else
				TriggerClientEvent('chat:addMessage', netID, {args = {"Cannot find the theme ^1" .. theme .. "^r!"}})
			end
		else
			TriggerClientEvent('chat:addMessage', netID, {args = {"Invalid theme name ^1" .. theme .. "^r!"}})
		end
	end)
	