function Trim(value)
    if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

function Round(value, numDecimalPlaces)
    if not numDecimalPlaces then return math.floor(value + 0.5) end
    local power = 10 ^ numDecimalPlaces
    return math.floor((value * power) + 0.5) / (power)
end

function SamePlates(plate1, plate2)
    return (Trim(plate1) == Trim(plate2))
end

function GetDistance(pos1, pos2)
    return #(vector3(pos1.x, pos1.y, pos1.z) - vector3(pos2.x, pos2.y, pos2.z))
end

function DoesVehicleAlreadyExsistOnServer(plate)
    local found, vehicles = GetAllVehicles()
    if type(vehicles) == 'table' then
        for i = 1, #vehicles, 1 do
            local tplate = GetPlate(vehicles[i])
            if tplate == plate then return true end
        end
    end
    return false
end
