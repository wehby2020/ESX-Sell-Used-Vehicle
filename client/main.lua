ESX = nil

PlayerData = {}
Citizen.CreateThread(function()
	while ESX == nil do
		ESX = exports['es_extended']:getSharedObject()
		Citizen.Wait(0)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end
	ESX.PlayerData = ESX.GetPlayerData()
end)

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(10)
		ESX = exports['es_extended']:getSharedObject()
    end
    if ESX.IsPlayerLoaded() then
		PlayerData = ESX.GetPlayerData()
		RemoveVehicles()
		Citizen.Wait(500)
		LoadSellPlace()
		SpawnVehicles()
    end
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(response)
	PlayerData = response
	LoadSellPlace()
	SpawnVehicles()
end)

RegisterNetEvent("esx_sellvehicles:spawnPurchasedVehicle")
AddEventHandler("esx_sellvehicles:spawnPurchasedVehicle", function(vehProps)
    local playerPed = PlayerPedId()
    local coords = Config.Zones.SellPosition.Pos
    local heading = Config.Zones.SellPosition.Heading
    ESX.Game.SpawnVehicle(vehProps.model, coords, heading, function(vehicle)
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        ESX.Game.SetVehicleProperties(vehicle, vehProps)
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
        SetVehicleFuelLevel(vehicle, 100.0)
        SetVehicleDeformationFixed(vehicle)
        local plate = GetVehicleNumberPlateText(vehicle)
        local model = GetEntityModel(vehicle)
        GiveVehicleKeys(plate, model, vehicle) -- Use the function from config.lua
    end)
end)


RegisterNetEvent("esx_sellvehicles:refreshVehicles")
AddEventHandler("esx_sellvehicles:refreshVehicles", function()
	RemoveVehicles()
	Citizen.Wait(500)
	SpawnVehicles()
end)


function DrawText3D(coords, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextEntry("STRING")
        SetTextCentre(1)
        SetTextColour(255, 255, 255, 215)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 140)
    end
end

local isMenuOpen = false
local currentVehicle = nil

function LoadSellPlace()
    Citizen.CreateThread(function()
        local SellPos = Config.SellPosition
        local markerType = Config.MarkerType
        local Blip = AddBlipForCoord(SellPos["x"], SellPos["y"], SellPos["z"])
        SetBlipSprite(Blip, 227)
        SetBlipDisplay(Blip, 4)
        SetBlipScale(Blip, 1.0)
        SetBlipColour(Blip, 50)
        SetBlipAsShortRange(Blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Used Cars")
        EndTextCommandSetBlipName(Blip)

        while true do
            local sleepThread = 500
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local dstCheck = GetDistanceBetweenCoords(pedCoords, SellPos["x"], SellPos["y"], SellPos["z"], true)

            if dstCheck <= 10.0 then
                sleepThread = 5
                DrawMarker(markerType, SellPos.x, SellPos.y, SellPos.z, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.5, 128, 0, 128, 100, false, true, 2, true, nil, nil, false)

                if dstCheck <= 4.2 then
                    ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to open the menu")

                    if IsControlJustPressed(0, 38) then
                        if IsPedInAnyVehicle(ped, false) then
                            local vehicle = GetVehiclePedIsUsing(ped)
                            
                            -- Ensure the vehicle entity is valid
                            if DoesEntityExist(vehicle) and not IsEntityDead(vehicle) then
                                -- Ensure the engine is off
                                SetVehicleEngineOn(vehicle, false, true, true)
                                OpenSellMenu(vehicle)
                            else
                                ESX.ShowNotification("Invalid vehicle")
                            end
                        else
                            ESX.ShowNotification("You must sit in a ~g~vehicle")
                        end
                    end
                end
            end

            for i = 1, #Config.VehiclePositions, 1 do
                if Config.VehiclePositions[i]["entityId"] ~= nil then
                    local vehCoords = GetEntityCoords(Config.VehiclePositions[i]["entityId"])
                    local dstCheck = GetDistanceBetweenCoords(pedCoords, vehCoords, true)

                    if dstCheck <= 2.5 then
                        sleepThread = 5

                        if IsPedInVehicle(ped, Config.VehiclePositions[i]["entityId"], false) then
                            DrawText3D(vehCoords, "[~g~E~w~] Open Vehicle Details", 0.4)

                            if IsControlJustPressed(0, 38) then
                                isMenuOpen = true
                                currentVehicle = Config.VehiclePositions[i]["entityId"]
                                OpenSellMenu(currentVehicle, Config.VehiclePositions[i]["price"], Config.VehiclePositions[i]["description"], true, Config.VehiclePositions[i]["owner"])

                                local plate = GetVehicleNumberPlateText(currentVehicle)
                                local model = GetEntityModel(currentVehicle)
                                GiveVehicleKeys(plate, model, currentVehicle) -- Use the function from config.lua
                            end

                            -- Freeze the vehicle
                            FreezeEntityPosition(currentVehicle, true)
                        else
                            DrawText3D(vehCoords, "[~g~F~w~] Enter Vehicle For Details", 0.4)
                            -- Unfreeze the vehicle if the player is not inside
                            FreezeEntityPosition(Config.VehiclePositions[i]["entityId"], false)
                        end
                    end
                end
            end

            if isMenuOpen and currentVehicle then
                if not IsPedInVehicle(ped, currentVehicle, false) then
                    ESX.UI.Menu.CloseAll()
                    isMenuOpen = false
                    FreezeEntityPosition(currentVehicle, false)
                    currentVehicle = nil
                end
            end

            Citizen.Wait(sleepThread)
        end
    end)
end

function OpenSellMenu(veh, price, description, buyVehicle, owner)
    local elements = {}

    local function truncateDescription(desc)
        local words = {}
        for word in desc:gmatch("%S+") do
            table.insert(words, word)
        end
        if #words > 3 then
            return table.concat(words, " ", 1, 3) .. "..."
        else
            return table.concat(words, " ")
        end
    end

    local plate = GetVehicleNumberPlateText(veh)
    
    if not buyVehicle then
        if price ~= nil then
            table.insert(elements, { ["label"] = "Change Price - " .. price .. "$", ["value"] = "price" })
        else
            table.insert(elements, { ["label"] = "Set Price - :-", ["value"] = "price" })
        end
    else
        table.insert(elements, { ["label"] = "Sale Price: " .. price .. "$", ["value"] = "buy" })
        table.insert(elements, { ["label"] = "Seller Description", ["value"] = "show_description" })
        table.insert(elements, { ["label"] = "Test Vehicle", ["value"] = "test_vehicle" })
    end

    table.insert(elements, { ["label"] = "Vehicle Plate: " .. plate, ["value"] = "plate" })

    if not buyVehicle then
        if description ~= nil then
            local truncatedDesc = truncateDescription(description)
            table.insert(elements, { ["label"] = "Description - " .. truncatedDesc, ["value"] = "description" })
        else
            table.insert(elements, { ["label"] = "Set Description - :-", ["value"] = "description" })
        end
    end

    ESX.TriggerServerCallback('getVehicleMileage', function(mileage)
        table.insert(elements, { ["label"] = "Vehicle Mileage: " .. mileage .. " km", ["value"] = "mileage" })

        if not buyVehicle then
            if price ~= nil then
                table.insert(elements, { ["label"] = "Put out for sale", ["value"] = "sell" })
            end
        else
            if owner then
                table.insert(elements, { ["label"] = "Remove Vehicle", ["value"] = "remove" })
            end
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'sell_veh',
            {
                title    = "Vehicle Menu",
                align    = 'top-right',
                elements = elements
            },
        function(data, menu)
            local action = data.current.value

            if action == "price" then
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'sell_veh_price',
                    {
                        title = "Vehicle Price"
                    },
                function(data2, menu2)
                    local vehPrice = tonumber(data2.value)
                    menu2.close()
                    menu.close()
                    OpenSellMenu(veh, vehPrice, description, buyVehicle, owner)
                end, function(data2, menu2)
                    menu2.close()
                end)
            elseif action == "description" then
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'sell_veh_description',
                    {
                        title = "Vehicle Description"
                    },
                function(data2, menu2)
                    local vehDescription = tostring(data2.value)
                    menu2.close()
                    menu.close()
                    OpenSellMenu(veh, price, vehDescription, buyVehicle, owner)
                end, function(data2, menu2)
                    menu2.close()
                end)
            elseif action == "show_description" then
                ESX.TriggerServerCallback("esx_sellvehicles:getVehicleDescription", function(desc)
                    if desc and desc ~= "" then
                        local lines = splitDescriptionIntoLines(desc, 10)
                        local descriptionElements = {}

                        for _, line in ipairs(lines) do
                            table.insert(descriptionElements, { ["label"] = line, ["value"] = "line" })
                        end
                        table.insert(descriptionElements, { ["label"] = "Back", ["value"] = "cancel" })
                        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_description',
                            {
                                title = "Vehicle Description",
                                align = 'top-right',
                                elements = descriptionElements
                            },
                        function(data2, menu2)
                            if data2.current.value == "cancel" then
                                menu2.close()
                            end
                        end, function(data2, menu2)
                            menu2.close()
                        end)
                    else
                        ESX.ShowNotification("No description available.")
                    end
                end, plate)
            elseif action == "sell" then
                local vehProps = ESX.Game.GetVehicleProperties(veh)
                ESX.TriggerServerCallback("esx_sellvehicles:isVehicleValid", function(valid)
                    if valid then
                        local hasEnoughMoney = ESX.PlayerData.money >= Config.ListingFee
                        if hasEnoughMoney then
                            DeleteVehicle(veh)
                            ESX.ShowNotification("You put out the vehicle for sale for " .. price .. " $.")
                            TriggerServerEvent('esx:removeMoney', Config.ListingFee, "registration")
                            TriggerServerEvent('esx_sellvehicles:addVehicle', vehProps, price, description)
                            menu.close()
                        else
                            ESX.ShowNotification("You need $" .. Config.ListingFee .. " to put your vehicle for sale.")
                        end
                    else
                        ESX.ShowNotification("You must own the vehicle or there are already " .. #Config.VehiclePositions .. " vehicles for sale.")
                    end
                end, vehProps, price, description)
            elseif action == "buy" then
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'confirm_buy',
                    {
                        title    = "Confirm Purchase",
                        align    = 'top-right',
                        elements = {
                            { ["label"] = "Are you sure you want to buy this vehicle for " .. price .. "$?", ["value"] = "confirm" },
                            { ["label"] = "Back", ["value"] = "cancel" }
                        }
                    },
                function(data2, menu2)
                    local choice = data2.current.value
                    if choice == "confirm" then
                        ESX.TriggerServerCallback("esx_sellvehicles:buyVehicle", function(isPurchasable, totalMoney)
                            if isPurchasable then
                                local hasEnoughMoney = ESX.PlayerData.money >= Config.Newcontract
                                if hasEnoughMoney then
                                    ESX.ShowNotification("You bought the vehicle for " .. price .. "$.")
                                    TriggerServerEvent('esx:removeMoney', Config.Newcontract, "new_registration")
                                    DeleteVehicle(veh)
                                    menu2.close()
                                    menu.close()
                                else
                                    ESX.ShowNotification("You need $" .. Config.Newcontract .. " to buy this vehicle.")
                                end
                            else
                                ESX.ShowNotification("You don't have enough cash, missing " .. (price - totalMoney) .. "$.")
                            end
                        end, ESX.Game.GetVehicleProperties(veh), price)
                    elseif choice == "cancel" then
                        menu2.close()
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)
            elseif action == "remove" then
                ESX.TriggerServerCallback("esx_sellvehicles:buyVehicle", function(isPurchasable, totalMoney)
                    if isPurchasable then
                        local hasEnoughMoney = ESX.PlayerData.money >= Config.removeVehicle
                        if hasEnoughMoney then
                            ESX.ShowNotification("You paid $" .. Config.removeVehicle .. " to remove the vehicle from sale.")
                            TriggerServerEvent('esx:removeMoney', Config.removeVehicle, "taxes")
                            DeleteVehicle(veh)
                            menu.close()
                        else
                            ESX.ShowNotification("You need $" .. Config.removeVehicle .. " to remove the vehicle from sale.")
                        end
                    end
                end, ESX.Game.GetVehicleProperties(veh), 0)
            elseif action == "test_vehicle" then
                testusedvehicle(veh)
                menu.close()
            end
        end, function(data, menu)
            menu.close()
        end)
    end, GetVehicleNumberPlateText(veh))
end



function splitDescriptionIntoLines(desc, maxWordsPerLine)
    local lines = {}
    local words = {}
    for word in desc:gmatch("%S+") do
        table.insert(words, word)
        if #words >= maxWordsPerLine then
            table.insert(lines, table.concat(words, " "))
            words = {}
        end
    end
    if #words > 0 then
        table.insert(lines, table.concat(words, " "))
    end
    return lines
end

function testusedvehicle(vehicle)
    local playerPed = PlayerPedId()
    IsInShopMenu = false

    local vehicleData = ESX.Game.GetVehicleProperties(vehicle)
    ESX.Game.SpawnVehicle(vehicleData.model, Config.Zones.SellPosition.Pos, Config.Zones.SellPosition.Heading, function(spawnedVehicle)
        TaskWarpPedIntoVehicle(playerPed, spawnedVehicle, -1)
        SetVehicleNumberPlateText(spawnedVehicle, "TEST")
        DecorSetFloat(spawnedVehicle, "_FUEL_LEVEL", 90.0)
        SetEntityVisible(playerPed, true)
        ESX.UI.Menu.CloseAll()
        local plate = GetVehicleNumberPlateText(spawnedVehicle)
        exports["onyxLocksystem"]:givePlayerKeys(plate)
        if Config.Options['time'] then
            show_timer()
        end
        local isTestDriving = true
        local function MonitorVehicleExit()
            Citizen.CreateThread(function()
                while isTestDriving do
                    Citizen.Wait(0)
                    
                    -- Check if the player has exited the vehicle
                    if not IsPedInAnyVehicle(playerPed, false) then
                        -- If the player exits the vehicle, stop the test drive
                        isTestDriving = false
                        DeleteVehicle(spawnedVehicle)
                        SetEntityCoords(playerPed, Config.Zones.SellPosition.Pos, false, false, false, false)
                        ESX.ShowNotification("Test drive finished.")
                        FreezeEntityPosition(playerPed, false)
                        SendNUIMessage({action = "hide_timer"})
                        SetEntityInvincible(spawnedVehicle, false)
                        return
                    end
                end
            end)
        end
        -- Call the function to monitor vehicle exit during the test drive
        MonitorVehicleExit()
        SetEntityInvincible(spawnedVehicle, true)
    
        Citizen.CreateThread(function()
            local counter = Config.Options['time_rent']
            while counter > 0 and isTestDriving do
                Citizen.Wait(1000) -- Wait for 1 second
                counter = counter - 1 -- Decrement counter by 1 second
            end
            if isTestDriving then
                -- If the test drive is still ongoing, end it after the timer
                DeleteVehicle(spawnedVehicle)
                SetEntityCoords(playerPed, Config.Zones.SellPosition.Pos, false, false, false, false)
                ESX.ShowNotification("Test drive finished.")
                FreezeEntityPosition(playerPed, false)
                SendNUIMessage({action = "hide_timer"})
                SetEntityInvincible(spawnedVehicle, false)
                isTestDriving = false
            end
        end)
    end)
end

function show_timer()
    SendNUIMessage({action = "show_timer", content = { time = Config.Options['time_rent'] }})
    SetNuiFocus(false, false)
end

function RemoveVehicles()
	local VehPos = Config.VehiclePositions
	for i = 1, #VehPos, 1 do
		local veh, distance = ESX.Game.GetClosestVehicle(VehPos[i])
		if DoesEntityExist(veh) and distance <= 1.0 then
			DeleteEntity(veh)
		end
	end
end

function SpawnVehicles()
	local VehPos = Config.VehiclePositions
	ESX.TriggerServerCallback("esx_sellvehicles:retrieveVehicles", function(vehicles)
		for i = 1, #vehicles, 1 do
			local vehicleProps = vehicles[i]["vehProps"]
			LoadModel(vehicleProps["model"])
			VehPos[i]["entityId"] = CreateVehicle(vehicleProps["model"], VehPos[i]["x"], VehPos[i]["y"], VehPos[i]["z"], VehPos[i]["h"], false)
			VehPos[i]["price"] = vehicles[i]["price"]
			VehPos[i]["owner"] = vehicles[i]["owner"]
			ESX.Game.SetVehicleProperties(VehPos[i]["entityId"], vehicleProps)
			SetVehicleOnGroundProperly(VehPos[i]["entityId"])
			SetEntityAsMissionEntity(VehPos[i]["entityId"], true, true)
			SetModelAsNoLongerNeeded(vehicleProps["model"])
		end
	end)
end

LoadModel = function(model)
	while not HasModelLoaded(model) do
		RequestModel(model)
		Citizen.Wait(1)
	end
end
