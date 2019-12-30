-- START Feed Job
local feedJobActive = false
local feedJobData = false
local feedJobScenario = false
local feedJobScenarioCoords = { x=0, y=0, z=0 }
local feedJobActivityCount = 0
local feedJobNextDistance = 0.5
local feedJobRecentlyActive = false
-- END Feed Job

Citizen.CreateThread(function()
    Citizen.Wait(30000)

    -- START Feed Job
    local feedJob = CreateStartEndScenarion(
        'Feed Chickens', 'Find some chickens to feed.',
        GetHashKey('WORLD_PLAYER_CHORES_FEEDBAG_PICKUP'), GetHashKey('WORLD_PLAYER_CHORES_FEEDBAG_PUTDOWN'),
        -249.39, 685.53, 112.33, 332.19,
        1.0
    )

    print('FeedJob:', feedJob)
    

    RegisterNetEvent('immersion:job_started:' .. feedJob)
    AddEventHandler('immersion:job_started:' .. feedJob, function(_scenario)
        print('Job Started: ' .. _scenario.name)
        feedJobActive = true
        feedJobData = _scenario
        feedJobActivityCount = 0
    end)

    RegisterNetEvent('immersion:job_ended:' .. feedJob)
    AddEventHandler('immersion:job_ended:' .. feedJob, function(_scenario)
        print('Job Ended: ' .. _scenario.name)
        print('Tasks Completed: ' .. tostring(feedJobActivityCount))
        print('Item Returned: ' .. tostring(_scenario.item_returned))
        if feedJobScenario then
            N_0x81948dfe4f5a0283(feedJobScenario) -- DELETE_SCENARIO_POINT
        end
        feedJobActive = false
        feedJobScenario = false
    end)
    -- END Feed Job

    -- START Feed Job 2
    local feedJob2 = CreateStartEndScenarion(
        'Feed Chickens 2', 'Drop some feed in th chicken coop.',
        GetHashKey('WORLD_PLAYER_CHORES_FEEDBAG_PICKUP'), GetHashKey('WORLD_PLAYER_CHORES_FEEDBAG_PUTDOWN'),
        -246.88, 679.08, 112.32, 137.36,
        1.0
    )

    print('FeedJob2:', feedJob2)

    local feedJob2Data = false
    local feedJob2Scenario = false
    local feedJob2Completed = false
    local feedJob2Coord = randomizeScenario2Coord()

    RegisterNetEvent('immersion:job_started:' .. feedJob2)
    AddEventHandler('immersion:job_started:' .. feedJob2, function(_scenario)
        print('Job Started: ' .. _scenario.name)
        feedJob2Data = _scenario
        feedJob2Coord = randomizeScenario2Coord()
        feedJob2Scenario = N_0x94b745ce41db58a1(GetHashKey('WORLD_PLAYER_CHORES_FEED_CHICKENS'), feedJob2Coord.x, feedJob2Coord.y, feedJob2Coord.z, feedJob2Coord.h) -- CREATE_SCENARIO_POINT
        feedJob2Completed = false
        print('Feed Location: ' .. tostring(feedJob2Scenario))
    end)

    RegisterNetEvent('immersion:job_ended:' .. feedJob2)
    AddEventHandler('immersion:job_ended:' .. feedJob2, function(_scenario)
        print('Job Ended:' .. _scenario.name)
        print('Job Complete: ' .. tostring(feedJob2Completed))
        print('Item Returned: ' .. tostring(_scenario.item_returned))
        N_0x81948dfe4f5a0283(feedJob2Scenario) -- DELETE_SCENARIO_POINT
        feedJob2Scenario = false
    end)

    while true do
        Citizen.Wait(10)
        if feedJob2Scenario then
            local player = PlayerPedId()
            if Config.Debug == 1 then
                local str = 'Completed: ' .. tostring(feedJob2Completed) ..
                            '\nPedInScen: ' .. tostring(IsPedActiveInScenario(player)) ..
                            '\nScenExists: ' .. DoesScenarioExistInArea(feedJob2Coord.x, feedJob2Coord.y, feedJob2Coord.z, 1.0) ..
                            '\nScenOccupied: ' .. tostring(IsScenarioOccupied(feedJob2Scenario))
                TxtAtWorldCoord(feedJob2Data.coord.x, feedJob2Data.coord.y, feedJob2Data.coord.z + 1.0, str, 0.3, 1)
            end
            if not feedJob2Completed and DoesScenarioExistInArea(feedJob2Coord.x, feedJob2Coord.y, feedJob2Coord.z, 1.0) == 1 then
                DrawText3D(feedJob2Coord.x, feedJob2Coord.y, feedJob2Coord.z, 'Feed Chicken Coop')
            end
            if not feedJob2Completed and (DoesScenarioExistInArea(feedJob2Coord.x, feedJob2Coord.y, feedJob2Coord.z, 1.0) == 0 or IsPedActiveInScenario(player) == 1) then
                feedJob2Completed = true
            elseif feedJob2Completed then
                DrawText3D(feedJob2Data.coord.x, feedJob2Data.coord.y, feedJob2Data.coord.z, 'Return Feed')
            end
        end
    end
    -- END Feed Job 2
end)
-- START Feed Job 2
function randomizeScenario2Coord()
    local coord = {}
    coord.x = GetRandomFloatInRange(-246.75, -247.75)
    coord.y = GetRandomFloatInRange(673.0, 676.0)
    coord.z = 113.5
    coord.h = GetRandomFloatInRange(0.0, 360.0)
    return coord
end
-- END Feed Job 2

-- START Feed Job
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if feedJobActive then
            DrawText3D(feedJobData.coord.x, feedJobData.coord.y, feedJobData.coord.z, 'Return Feed')
            local player = PlayerPedId()
            local coords = GetEntityCoords(player)

            if Config.Debug == 1 then
                local str = 'Completed Tasks: ' .. tostring(feedJobActivityCount) .. tostring(feedJobActivityCount < 4) ..
                            '\nPedInScen: ' .. tostring(IsPedActiveInScenario(player)) ..
                            '\nRecently Active: ' .. tostring(feedJobRecentlyActive) ..
                            '\nNext Distance: ' .. tostring(feedJobNextDistance) ..
                            '\nDistance From Last: ' .. tostring(GetDistanceBetweenCoords(feedJobScenarioCoords.x, feedJobScenarioCoords.y, feedJobScenarioCoords.z, coords.x, coords.y, coords.z)) .. tostring(GetDistanceBetweenCoords(feedJobScenarioCoords.x, feedJobScenarioCoords.y, feedJobScenarioCoords.z, coords.x, coords.y, coords.z) > feedJobNextDistance)
                TxtAtWorldCoord(feedJobData.coord.x, feedJobData.coord.y, feedJobData.coord.z + 1.0, str, 0.3, 1)
            end

            if not feedJobRecentlyActive and IsPedActiveInScenario(player) and GetDistanceBetweenCoords(coords.x, coords.y, coords.z, feedJobScenarioCoords.x, feedJobScenarioCoords.y, feedJobScenarioCoords.z) < 2.0 then
                feedJobRecentlyActive = true
                feedJobActivityCount = feedJobActivityCount + 1
                feedJobNextDistance = 5.0
            elseif not IsPedActiveInScenario(player) or GetDistanceBetweenCoords(coords.x, coords.y, coords.z, feedJobScenarioCoords.x, feedJobScenarioCoords.y, feedJobScenarioCoords.z) > 2.0 then
                feedJobRecentlyActive = false
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        if feedJobActive and feedJobActivityCount < 4 and GetDistanceBetweenCoords(feedJobScenarioCoords.x, feedJobScenarioCoords.y, feedJobScenarioCoords.z, coords.x, coords.y, coords.z) > feedJobNextDistance then
            local shapeTest = StartShapeTestBox(coords.x, coords.y, coords.z - 1.0, 6.5, 6.5, 0.5, 0.0, 0.0, 0.0, true, 4, player)
            local rtnVal, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
            if hit > 0 then
                local pHeading = GetEntityHeading(player)
                if GetEntityModel(entityHit) == GetHashKey('A_C_CHICKEN_01') then
                    if feedJobScenario then
                        N_0x81948dfe4f5a0283(feedJobScenario) -- DELETE_SCENARIO_POINT
                    end
                    feedJobScenario = N_0x94b745ce41db58a1(GetHashKey('WORLD_PLAYER_CHORES_FEED_CHICKENS'), coords.x, coords.y, coords.z, pHeading) -- CREATE_SCENARIO_POINT
                    feedJobNextDistance = 0.5
                    feedJobScenarioCoords = coords
                end
            end
        end
    end
end)
-- END Feed Job
