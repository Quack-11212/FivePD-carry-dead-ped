-- main.lua

local pickedUpPed = nil
local isCarryingPed = false

-- Function to display a progress bar
function DisplayProgressBar(duration, label)
    exports['mythic_progbar']:Progress({
        name = "carry_ped",
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
    })
end

-- Function to pick up or drop the dead NPC
function ToggleCarryPed()
    if isCarryingPed then
        DropPed()
    else
        CarryPed()
    end
end

-- Function to pick up the dead NPC
function CarryPed()
    if isCarryingPed then
        return  -- Skip if already carrying a ped
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local nearbyPeds = GetGamePool("CPed")

    for _, ped in ipairs(nearbyPeds) do
        if not IsPedInAnyVehicle(ped) and IsPedDeadOrDying(ped, true) and not IsEntityAMissionEntity(ped) then
            local pedCoords = GetEntityCoords(ped)
            local distance = GetDistanceBetweenCoords(coords, pedCoords, true)

            if distance < 2.0 then
                pickedUpPed = ped
                DisplayProgressBar(5000, "Picking up NPC") -- Adjust the duration and label as needed
                Citizen.Wait(5000) -- Wait for the progress bar animation to complete

                AttachEntityToEntity(ped, playerPed, GetPedBoneIndex(playerPed, 60309), 0.2, 0.0, 0.2, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                SetEntityAsMissionEntity(pickedUpPed, true, true)
                isCarryingPed = true
                break
            end
        end
    end
end

-- Function to drop the carried NPC
function DropPed()
    if not isCarryingPed then
        return  -- Skip if not carrying a ped
    end

    local playerPed = PlayerPedId()
    local forwardVector = GetEntityForwardVector(playerPed)
    local dropPosition = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 2.0, 0.0)

    DetachEntity(pickedUpPed, true, true)
    ClearPedTasksImmediately(pickedUpPed)
    SetEntityAsMissionEntity(pickedUpPed, false, true)
    SetEntityCoordsNoOffset(pickedUpPed, dropPosition.x, dropPosition.y, dropPosition.z, false, false, false)
    SetEntityVelocity(pickedUpPed, 0.0, 0.0, 0.0)
    SetPedToRagdoll(pickedUpPed, 5000, 5000, 0, 0, 0, 0)

    Citizen.Wait(500)  -- Wait briefly to prevent immediate re-pickup

    pickedUpPed = nil
    isCarryingPed = false

    Citizen.Wait(500) -- Wait before allowing pickup again
end

-- Command to pick up or drop the NPC
RegisterCommand('cped', function(source, args)
    ToggleCarryPed()
end)

-- Keybind can be disabled to prevent conflicts with the command
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        DisableControlAction(0, 73, true)  -- Disable "E" key (or any other key you want to use)
    end
end)
