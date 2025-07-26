local handbrakeActive = false
local handbrakeLatched = false
local handbrakeControl = 76 -- INPUT_VEH_HANDBRAKE (Spacebar/R1)
local handbrakeHoldStart = 0
local latchThreshold = 500 -- milliseconds (reduced from 2000)
local wasControlPressed = false
local latchJustSet = false
local stoppedSpeed = 0.5 -- m/s

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local veh = GetVehiclePedIsIn(playerPed, false)
            local isPressed = IsControlPressed(0, handbrakeControl)
            local vehSpeed = GetEntitySpeed(veh)

            -- Only allow handbrake logic if vehicle is stopped
            if vehSpeed < stoppedSpeed then
                if isPressed then
                    if not wasControlPressed then
                        handbrakeHoldStart = GetGameTimer()
                    end
                    if not handbrakeActive then
                        SetVehicleHandbrake(veh, true)
                        handbrakeActive = true
                    end
                    -- Latch if held for 0.5 seconds
                    if not handbrakeLatched and (GetGameTimer() - handbrakeHoldStart) >= latchThreshold then
                        handbrakeLatched = true
                        latchJustSet = true
                    end
                else
                    if wasControlPressed then
                        -- If just released after latching, only toggle off if it was a tap (not a hold)
                        if handbrakeLatched and not latchJustSet then
                            SetVehicleHandbrake(veh, false)
                            handbrakeActive = false
                            handbrakeLatched = false
                        elseif handbrakeActive and not handbrakeLatched then
                            -- If not latched, release as normal
                            SetVehicleHandbrake(veh, false)
                            handbrakeActive = false
                        end
                    end
                    latchJustSet = false -- Reset after key is released
                end

                -- If latched, keep handbrake on
                if handbrakeLatched then
                    if not handbrakeActive then
                        SetVehicleHandbrake(veh, true)
                        handbrakeActive = true
                    end
                end
            else
                -- If vehicle starts moving, release handbrake and clear latch
                if handbrakeActive or handbrakeLatched then
                    SetVehicleHandbrake(veh, false)
                    handbrakeActive = false
                    handbrakeLatched = false
                    latchJustSet = false
                end
            end

            -- If handbrake is active and player drives forward or reverses, release handbrake and clear latch
            if handbrakeActive then
                if IsControlPressed(0, 71) or IsControlPressed(0, 72) or vehSpeed > stoppedSpeed then -- 71 = W (forward), 72 = S (reverse)
                    SetVehicleHandbrake(veh, false)
                    handbrakeActive = false
                    handbrakeLatched = false
                    latchJustSet = false
                end
            end

            wasControlPressed = isPressed
        else
            handbrakeActive = false
            handbrakeLatched = false
            wasControlPressed = false
            latchJustSet = false
        end
    end
end) 