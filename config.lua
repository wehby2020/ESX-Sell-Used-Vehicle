Config = {}

Config.MarkerType = 36
Config.Locale = "en"
Config.Zones = {
	SellPosition = {
		Pos     = vector3(-1638.49, -814.90, 9.55),
		Size    = {x = 1.5, y = 1.5, z = 1.0},
		Heading = 140.34,
		Type    = -1
	},
}

Config.ListingFee = 100000 -- money should pay to list the vehicle
Config.Newcontract = 100000 -- sell Commission to make new vehicle doc.
Config.removeVehicle = 50000 --if player get back his vehicle 
--Config.CommissionRate = 0.10 --% --buy Commission

Config.Options = {
    ['time'] = true, -- if true it actives the timer rent. False to disabled it. Default true.
    ['time_rent'] = 180, -- seconds the player get when rent a vehicle. Default 120 seconds | 2 minutes.
	['time_finished'] = 'Your Testing time is up, thank you.',
}

Config.Vehiclekey = true
Config.VehicleKeySystem = 'onyxLocksystem' -- Example value, change to your actual key system

function GiveVehicleKeys(plate, model, vehicle)
    if Config.Vehiclekey then
        if Config.VehicleKeySystem == 'cd_garage' then
            TriggerEvent('cd_garage:AddKeys', exports['cd_garage']:GetPlate(vehicle))
        elseif Config.VehicleKeySystem == 'qs-vehiclekeys' then
            local vehicleName = GetDisplayNameFromVehicleModel(model)
            exports['qs-vehiclekeys']:GiveKeys(plate, vehicleName)
        elseif Config.VehicleKeySystem == 'wasabi-carlock' then
            exports.wasabi_carlock:GiveKey(plate)
        elseif Config.VehicleKeySystem == 'qb-vehiclekeys' then
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        elseif Config.VehicleKeySystem == 'onyxLocksystem' then
            exports["onyxLocksystem"]:givePlayerKeys(plate)
        end
    end
end

Config.SellPosition = {
    ["x"] = -1600.02, 
    ["y"] = -831.30, 
    ["z"] = 9.62
}

Config.VehiclePositions = {
    {
        ["x"] = -1600.83, 
        ["y"] = -820.15, 
        ["z"] = 9.36, 
        ["h"] = 139.84
    },

    {
        ["x"] = -1603.56, 
        ["y"] = -818.18, 
        ["z"] = 9.37, 
        ["h"] = 139.84
    },

    {
        ["x"] = -1605.99, 
        ["y"] = -816.71, 
        ["z"] = 9.37, 
        ["h"] = 139.84
    },

    {
        ["x"] = -1608.11, 
        ["y"] = -814.61, 
        ["z"] = 9.37, 
        ["h"] = 139.84
    },

    {
        ["x"] = -1610.72, 
        ["y"] = -812.72, 
        ["z"] = 9.37, 
        ["h"] = 139.84
    },

    {
        ["x"] = -1615.47, 
        ["y"] = -808.83, 
        ["z"] = 9.37, 
        ["h"] = 139.84
    },

    {
        ["x"] = -1617.67, 
        ["y"] = -806.81, 
        ["z"] = 9.37, 
        ["h"] = 139.84
    },

    {
        ["x"] = -1620.22, 
        ["y"] = -804.86, 
        ["z"] = 9.37, 
        ["h"] = 139.84
    },

    {
        ["x"] = -1622.99, 
        ["y"] = -801.90, 
        ["z"] = 9.37, 
        ["h"] = 139.84
    },

    {
        ["x"] = -1586.13, 
        ["y"] = -835.16, 
        ["z"] = 9.34,
        ["h"] = 48.57
    },

    {
        ["x"] = -1589.516, 
        ["y"] = -837.70, 
        ["z"] = 9.34,
        ["h"] = 48.57
    },
    {
        ["x"] = -1592.32, 
        ["y"] = -841.41, 
        ["z"] = 9.34,
        ["h"] = 48.57
    },
    {
        ["x"] = -1594.27, 
        ["y"] = -844.05, 
        ["z"] = 9.34,
        ["h"] = 48.57
    }
}