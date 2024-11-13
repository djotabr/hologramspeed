-- Events
RegisterNetEvent('HologramSpeed:SetTheme')

-- Constants
local ResourceName       = GetCurrentResourceName()
local HologramURI        = string.format("nui://%s/ui/hologram.html", ResourceName)
local AttachmentOffset   = vec3(2.5, -1, 0.85)
local AttachmentRotation = vec3(0, 0, -15)
local HologramModel      = `hologram_box_model`
local UpdateFrequency    = 0 -- Updates every tick if less than average frame time
local SettingKey         = string.format("%s:profile", GetCurrentServerEndpoint())
local DBG                = false -- Enables debug information

-- Variables
local duiObject = false
local duiIsReady = false
local hologramObject = 0
local usingMetric, shouldUseMetric = ShouldUseMetricMeasurements()
local textureReplacementMade = false
local displayEnabled = false
local currentTheme = GetConvar("hsp_defaultTheme", "default")
local maxSpeed = 0
local newmaxSpeed = 0
local playedMaxSpeedAlert = false -- Flag to track if max speed alert sound was played

-- Utility Functions
local function DebugPrint(...)
    if DBG then
        print(...)
    end
end

local function EnsureDuiMessage(data)
    if duiObject and duiIsReady then
        SendDuiMessage(duiObject, json.encode(data))
        return true
    end
    return false
end

local function SendChatMessage(message)
    TriggerEvent('chat:addMessage', {args = {message}})
end

local function LoadPlayerProfile()
    local jsonData = GetResourceKvpString(SettingKey)
    if jsonData then
        jsonData = json.decode(jsonData)
        displayEnabled = jsonData.displayEnabled
        currentTheme = jsonData.currentTheme
        AttachmentOffset = vec3(jsonData.attachmentOffset.x, jsonData.attachmentOffset.y, jsonData.attachmentOffset.z)
        AttachmentRotation = vec3(jsonData.attachmentRotation.x, jsonData.attachmentRotation.y, jsonData.attachmentRotation.z)
    end
end

local function SavePlayerProfile()
    local jsonData = {
        displayEnabled = displayEnabled,
        currentTheme = currentTheme,
        attachmentOffset = AttachmentOffset,
        attachmentRotation = AttachmentRotation,
    }
    SetResourceKvp(SettingKey, json.encode(jsonData))
end

local function ToggleDisplay()
    displayEnabled = not displayEnabled
    SendChatMessage("Holographic speedometer " .. (displayEnabled and "^2enabled^r" or "^1disabled^r") .. ".")
    SavePlayerProfile()
end

local function SetTheme(newTheme)
    if newTheme ~= currentTheme then
        EnsureDuiMessage {theme = newTheme}
        SendChatMessage(newTheme == "default" and "Holographic speedometer theme ^5reset^r." or ("Holographic speedometer theme set to ^5" .. newTheme .. "^r."))
        currentTheme = newTheme
        SavePlayerProfile()
    end
end

local function CheckRange(x, y, z, minVal, maxVal)
    return x and y and z and not (x < minVal or x > maxVal or y < minVal or y > maxVal or z < minVal or z > maxVal)
end

local function InitialiseDui()
    DebugPrint("Initialising...")
    duiObject = CreateDui(HologramURI, 512, 512)
    DebugPrint("\tDUI created")
    repeat Wait(0) until duiIsReady
    DebugPrint("\tDUI available")
    EnsureDuiMessage {
        useMetric = usingMetric,
        display = false,
        theme = currentTheme
    }
    DebugPrint("\tDUI initialised")
    local txdHandle = CreateRuntimeTxd("HologramDUI")
    local duiHandle = GetDuiHandle(duiObject)
    CreateRuntimeTextureFromDuiHandle(txdHandle, "DUI", duiHandle)
    DebugPrint("\tRuntime texture created")
    DebugPrint("Done!")
end

local function CreateHologram(currentVehicle)
    hologramObject = CreateVehicle(HologramModel, GetEntityCoords(currentVehicle), 0.0, false, true)
    SetVehicleIsConsideredByPlayer(hologramObject, false)
    SetVehicleEngineOn(hologramObject, true, true)
    SetEntityCollision(hologramObject, false, false)
    DebugPrint("DUI anchor created " .. tostring(hologramObject))
    return hologramObject
end

local function AttachHologramToVehicle(currentVehicle)
    AttachEntityToEntity(hologramObject, currentVehicle, GetEntityBoneIndexByName(currentVehicle, "chassis"), AttachmentOffset, AttachmentRotation, false, false, false, false, false, true)
    DebugPrint(string.format("DUI anchor %s attached to %s", hologramObject, currentVehicle))
end

local function saveMax(plate, speed)
    lib.callback.await("HologramSpeed:updateTopSpeed", false, plate, speed)
end

local function PlayAlertSound()
	local som = GetResourceKvpInt("hologramspeed:somMaxSpeed") or 0
    -- Play sound alert when max speed is reached
	if som == 1 then
    PlaySoundFrontend( -1, "Hack_Success","DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS",true)
	end
end

-- Event Handlers
AddEventHandler('HologramSpeed:SetTheme', function(theme)
    SetTheme(theme)
end)

RegisterCommand("hsp", function(_, args)
    if #args == 0 then
        ToggleDisplay()
    else
        CommandHandler(args)
    end
end, false)
RegisterCommand("alertapainel", function(_, args)
	print(".11",args[1])
	print(args[0])

    if tonumber(args[1]) == 0 then
        SetResourceKvpInt("hologramspeed:somMaxSpeed", 0)
		-- print("Alerta desligado")
		-- hood = GetResourceKvpInt("nome_do_KVP") or 0
    else
        SetResourceKvpInt("hologramspeed:somMaxSpeed", 1)
		-- print("Alerta ligado")
    end
end, false)


RegisterNUICallback("duiIsReady", function(_, cb)
    duiIsReady = true
    cb({ok = true})
end)

TriggerEvent('chat:addSuggestion', '/hsp', 'Toggle the holographic speedometer', {
    { name = "command", help = "Allow command: theme, offset, rotate" },
})

RegisterKeyMapping("hsp", "Toggle Holographic Speedometer", "keyboard", "grave")

-- Main Loop
CreateThread(function()
    if string.lower(ResourceName) ~= ResourceName then
        print(string.format("[WARNING] you should rename your HologramSpeed resource folder name to '%s'.", string.lower(ResourceName)))
        return
    end

    if not IsModelInCdimage(HologramModel) or not IsModelAVehicle(HologramModel) then
        SendChatMessage("^1Could not find `hologram_box_model` in the game... ^rHave you installed the resource correctly?")
        return
    end

    LoadPlayerProfile()
    InitialiseDui()

    CreateThread(function()
        while true do
            Wait(1000)
            shouldUseMetric = ShouldUseMetricMeasurements()
            if usingMetric ~= shouldUseMetric and EnsureDuiMessage {useMetric = shouldUseMetric} then
                usingMetric = shouldUseMetric
            end
        end
    end)

    local playerPed, currentVehicle

    while true do
        playerPed = PlayerPedId()

        if IsPedInAnyVehicle(playerPed) then
            currentVehicle = GetVehiclePedIsIn(playerPed, false)
            local plate = GetVehicleNumberPlateText(currentVehicle)
            if currentVehicle ~= nil and currentVehicle ~= 0 then
                maxSpeed = lib.callback.await("HologramSpeed:topSpeed", false, plate) or 0
            end

            if GetPedInVehicleSeat(currentVehicle, -1) == playerPed then
                EnsureDuiMessage {display = false}
                RequestModel(HologramModel)
                repeat Wait(0) until HasModelLoaded(HologramModel)
                hologramObject = CreateHologram(currentVehicle)

                if not textureReplacementMade then
                    AddReplaceTexture("hologram_box_model", "p_hologram_box", "HologramDUI", "DUI")
                    DebugPrint("Texture replacement made")
                    textureReplacementMade = true
                end
                SetModelAsNoLongerNeeded(HologramModel)

                if DoesEntityExist(currentVehicle) and GetPedInVehicleSeat(currentVehicle, -1) == playerPed then
                    AttachHologramToVehicle(currentVehicle)
                    playedMaxSpeedAlert = false -- Reset alert flag when attaching to a new vehicle
                    repeat
							if currentVehicle ~= nil and currentVehicle ~= 0 then
								local plate = GetVehicleNumberPlateText(currentVehicle)
								local speed = math.floor(GetEntitySpeed(currentVehicle) * 3.6)
								if speed > maxSpeed then
									maxSpeed = speed
									PlayAlertSound()
								end
							end
                        local vehicleSpeed = GetEntitySpeed(currentVehicle)
                        EnsureDuiMessage {
                            display = displayEnabled and IsVehicleEngineOn(currentVehicle),
                            rpm = GetVehicleCurrentRpm(currentVehicle),
                            gear = GetVehicleCurrentGear(currentVehicle),
                            abs = (GetVehicleWheelSpeed(currentVehicle, 0) == 0.0) and (vehicleSpeed > 0.0),
                            hBrake = GetVehicleHandbrake(currentVehicle),
                            rawSpeed = vehicleSpeed,
                            maxSpeed = maxSpeed,
                        }

                        if vehicleSpeed >= maxSpeed and not playedMaxSpeedAlert then
                            -- PlayAlertSound()
                            playedMaxSpeedAlert = true
                        end

                        Wait(displayEnabled and UpdateFrequency or 500)
                    until GetPedInVehicleSeat(currentVehicle, -1) ~= PlayerPedId()
                end
            end
        else
            if maxSpeed > newmaxSpeed then
				local plate = GetVehicleNumberPlateText(currentVehicle)
				newmaxSpeed = maxSpeed
                saveMax(plate, maxSpeed)
            end
        end

        if hologramObject ~= 0 and DoesEntityExist(hologramObject) then
            DeleteVehicle(hologramObject)
            DebugPrint("DUI anchor deleted " .. tostring(hologramObject))
        else
            hologramObject = 0
        end

        Wait(1000)
    end
end)

-- Resource Cleanup
AddEventHandler("onResourceStop", function(resource)
    if resource == ResourceName then
        DebugPrint("Cleaning up...")
        displayEnabled = false
        DebugPrint("\tDisplay disabled")
        if DoesEntityExist(hologramObject) then
            DeleteVehicle(hologramObject)
            DebugPrint("\tDUI anchor deleted " .. tostring(hologramObject))
        end
        RemoveReplaceTexture("hologram_box_model", "p_hologram_box")
        DebugPrint("\tReplace texture removed")
        if duiObject then
            DebugPrint("\tDUI browser destroyed")
            DestroyDui(duiObject)
            duiObject = false
        end
    end
end)

