RegisterNetEvent("kick:ilv-scripts:KickKidnapScene", function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    local guardModel = joaat("s_m_m_armoured_02")
    RequestModel(guardModel)
    while not HasModelLoaded(guardModel) do Wait(0) end

    local guardPed = CreatePed(0, guardModel, coords.x + 1.0, coords.y, coords.z, 0.0, true, true)
    SetBlockingOfNonTemporaryEvents(guardPed, true)
    SetPedCanRagdoll(guardPed, false)
    SetPedAsNoLongerNeeded(guardPed)

    local vanModel = joaat("burrito")
    local van = GetClosestVehicle(coords, 15.0, vanModel, 70)
    if not DoesEntityExist(van) then
        RequestModel(vanModel)
        while not HasModelLoaded(vanModel) do Wait(0) end
        van = CreateVehicle(vanModel, coords.x + 3.0, coords.y + 1.0, coords.z, 0.0, true, false)
    end

    local scenePos = GetEntityCoords(van)
    local sceneRot = GetEntityRotation(van)
    local animDict = 'random@kidnap_girl'

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(0) end

    local scene = NetworkCreateSynchronisedScene(scenePos, sceneRot, 2, false, false, 1.0, 0, 1.0)
    NetworkAddPedToSynchronisedScene(playerPed, scene, animDict, "ig_1_girl_drag_into_van", 8.0, -4.0, 1, 16, 0, 0)
    NetworkAddPedToSynchronisedScene(guardPed, scene, animDict, "ig_1_guy2_drag_into_van", 8.0, -4.0, 1, 16, 0, 0)
    NetworkAddEntityToSynchronisedScene(van, scene, animDict, "drag_into_van_burr", 1.0, 1.0, 1)

    NetworkStartSynchronisedScene(scene)

    Wait(GetAnimDuration(animDict, "drag_into_van_burr") * 1000)

    ClearPedTasks(playerPed)
    DeleteEntity(guardPed)
end)
