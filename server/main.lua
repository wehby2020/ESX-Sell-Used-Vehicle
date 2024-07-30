ESX = nil
ESX = exports['es_extended']:getSharedObject()
local VehiclesForSale = 0
ESX.RegisterServerCallback("esx_sellvehicles:retrieveVehicles", function(source, cb)
	local src = source
	local identifier = ESX.GetPlayerFromId(src)["identifier"]
    MySQL.Async.fetchAll("SELECT seller, vehicleProps, price FROM vehicles_for_sale", {}, function(result)
        local vehicleTable = {}
        VehiclesForSale = 0
        if result[1] ~= nil then
            for i = 1, #result, 1 do
                VehiclesForSale = VehiclesForSale + 1
				local seller = false
				if result[i]["seller"] == identifier then
					seller = true
				end
                table.insert(vehicleTable, { ["price"] = result[i]["price"], ["vehProps"] = json.decode(result[i]["vehicleProps"]), ["owner"] = seller })
            end
        end
        cb(vehicleTable)
    end)
end)

ESX.RegisterServerCallback("esx_sellvehicles:isVehicleValid", function(source, cb, vehicleProps, price, description)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
    local plate = vehicleProps["plate"]
	local isFound = false
	RetrievePlayerVehicles(xPlayer.identifier, function(ownedVehicles)
		for id, v in pairs(ownedVehicles) do
			if Trim(plate) == Trim(v.plate) and #Config.VehiclePositions ~= VehiclesForSale then
                MySQL.Async.execute("INSERT INTO vehicles_for_sale (seller, vehicleProps, price, description, plate) VALUES (@sellerIdentifier, @vehProps, @vehPrice, @vehDescription, @vehPlate)",
                    {
						["@sellerIdentifier"] = xPlayer["identifier"],
                        ["@vehProps"] = json.encode(vehicleProps),
                        ["@vehPrice"] = price,
                        ["@vehDescription"] = description,
                        ["@vehPlate"] = plate
                    }
                )
				MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate = @plate', { ["@plate"] = plate})
                TriggerClientEvent("esx_sellvehicles:refreshVehicles", -1)
				isFound = true
				break
			end		
		end
		cb(isFound)
	end)
end)

ESX.RegisterServerCallback("esx_sellvehicles:buyVehicle", function(source, cb, vehProps, price)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local price = price
	local plate = vehProps["plate"]
	if xPlayer.getAccount("bank")["money"] >= price or price == 0 then
		xPlayer.removeAccountMoney("bank", price)
		MySQL.Async.execute("INSERT INTO owned_vehicles (plate, owner, vehicle) VALUES (@plate, @identifier, @vehProps)",
			{
				["@plate"] = plate,
				["@identifier"] = xPlayer["identifier"],
				["@vehProps"] = json.encode(vehProps)
			}
		)
		TriggerClientEvent("esx_sellvehicles:refreshVehicles", -1)
		TriggerClientEvent("esx_sellvehicles:spawnPurchasedVehicle", src, vehProps)
		MySQL.Async.fetchAll('SELECT seller FROM vehicles_for_sale WHERE vehicleProps LIKE "%' .. plate .. '%"', {}, function(result)
			if result[1] ~= nil and result[1]["seller"] ~= nil then
				UpdateMoney(result[1]["seller"], price)
			else
				print("Something went wrong, there was no car.")
			end
		end)
		MySQL.Async.execute('DELETE FROM vehicles_for_sale WHERE vehicleProps LIKE "%' .. plate .. '%"', {})
		cb(true)
	else
		cb(false, xPlayer.getAccount("bank")["money"])
	end
end)

function RetrievePlayerVehicles(newIdentifier, cb)
	local identifier = newIdentifier
	local yourVehicles = {}
	MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE owner = @identifier", {['@identifier'] = identifier}, function(result) 
		for id, values in pairs(result) do
			local vehicle = json.decode(values.vehicle)
			local plate = values.plate
			table.insert(yourVehicles, { vehicle = vehicle, plate = plate })
		end
		cb(yourVehicles)
	end)
end

function UpdateMoney(identifier, money)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if xPlayer ~= nil then
        xPlayer.addAccountMoney("bank", money)
        TriggerClientEvent("esx:showNotification", xPlayer.source, "Someone bought your vehicle and transferred $" .. money)
    else
        MySQL.Async.fetchAll('SELECT accounts FROM users WHERE identifier = @identifier', { ["@identifier"] = identifier }, function(result)
            if result[1]["accounts"] ~= nil then
                local accounts = json.decode(result[1]["accounts"])
                accounts.bank = accounts.bank + money

                MySQL.Async.execute("UPDATE users SET accounts = @accounts WHERE identifier = @identifier",
                    {
                        ["@identifier"] = identifier,
                        ["@accounts"] = json.encode(accounts)
                    }
                )
            end
        end)
    end
end

Trim = function(word)
	if word ~= nil then
		return word:match("^%s*(.-)%s*$")
	else
		return nil
	end
end

RegisterServerEvent('esx:removeMoney')
AddEventHandler('esx:removeMoney', function(amount, notificationType)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.removeMoney(amount)
        
        local notificationMessage
        if notificationType == "registration" then
            notificationMessage = 'You have paid $' .. amount .. ' to make a new vehicle registration.'
        elseif notificationType == "new_registration" then
            notificationMessage = 'You have paid $' .. amount .. ' for a new registration for your new vehicle.'
        elseif notificationType == "taxes" then
            notificationMessage = 'You have paid $' .. amount .. ' in taxes for your vehicle.'
        else
            notificationMessage = 'You have paid $' .. amount .. '.'
        end
        
        TriggerClientEvent('esx:showNotification', source, notificationMessage)
    end
end)


MySQL.ready(function()
    MySQL.Async.execute('CREATE TABLE IF NOT EXISTS `carmileages` (`plate` TEXT DEFAULT NULL, `mileage` TEXT DEFAULT NULL)', {})
end)

ESX.RegisterServerCallback('getVehicleMileage', function(source, cb, plate)
    MySQL.Async.fetchAll('SELECT mileage FROM carmileages WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        local mileage = 0
        if result[1] then
            mileage = tonumber(result[1].mileage)
        end
        formattedMileage = string.format("%.2f", mileage):sub(1, 6)
        cb(formattedMileage)
    end)
end)

ESX.RegisterServerCallback('esx_sellvehicles:getVehicleDescription', function(source, cb, plate)
    MySQL.Async.fetchScalar('SELECT description FROM vehicles_for_sale WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(description)
        cb(description)
    end)
end)

