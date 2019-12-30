function TxtAtWorldCoord(x, y, z, txt, size, font)
    local s, sx, sy = GetScreenCoordFromWorldCoord(x, y ,z)
    if (sx > 0 and sx < 1) or (sy > 0 and sy < 1) then
        local s, sx, sy = GetHudScreenPositionFromWorldPosition(x, y, z)
        DrawTxt(txt, sx, sy, size, true, 255, 255, 255, 255, true, font) -- Font 2 has some symbol conversions ex. @ becomes the rockstar logo
    end
end

function DrawTxt(str, x, y, size, enableShadow, r, g, b, a, centre, font)
    local str = CreateVarString(10, "LITERAL_STRING", str)
    SetTextScale(1, size)
    SetTextColor(math.floor(r), math.floor(g), math.floor(b), math.floor(a))
    SetTextCentre(centre)
    if enableShadow then SetTextDropshadow(1, 0, 0, 0, 255) end
    SetTextFontForCurrentCommand(font)
    DisplayText(str, x, y)
end

function RemoveEntity(entity)
    Citizen.CreateThread(function()
        SetEntityAsMissionEntity(entity, true, true)
        DeletePed(entity)
        DeleteEntity(entity)
    end)
end

function DrawText3D(x, y, z, text)
    local onScreen,_x,_y = GetHudScreenPositionFromWorldPosition(x, y, z)
    local size = 0.3

    SetTextScale(size, size)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str, _x, _y)

    local w, h = GetScreenResolution()

    DrawSprite("generic_textures", "hud_menu_4a", _x, _y + 0.0125, string.len(text) * (20 * size) / w, 60 * size / h, 0.1, 100, 1, 1, 190, 0)
end

-- 0x94B745CE41DB58A1 0x195CBF86
-- CREATE_SCENARIO_POINT
-- local retval --[[ Any ]] =
-- CreateScenarioPoint(
--     scenario --[[ scenarioHash ]], 
--     x --[[ number ]], 
--     y --[[ number ]], 
--     z --[[ number ]], 
--     heading --[[ number ]], 
--     p5 --[[ Any ]], 
--     p6 --[[ Any ]], 
--     p7 --[[ Any ]]
-- )

--- 0xEA31F199A73801D3 Scenario is Occupied
--- 0x81948DFE4F5A0283 Delete Scenario
--- 0x5A59271FFADD33C1 DoesScenarioExistInArea()

local scenarioId = 0
local scenarioDatas = {}

Citizen.CreateThread(function()
    if Config.Debug == 1 then
        while true do
            Citizen.Wait(10)
            for id, scenarioData in pairs(scenarioDatas) do
                local test = '[ ' .. tostring(id) .. ' ]' ..
                        '\nstart: ' .. tostring(scenarioData._start) .. ' | ' .. tostring(N_0xea31f199a73801d3(scenarioData._start)) ..
                        '\nend: ' .. tostring(scenarioData._end) .. ' | ' .. tostring(N_0xea31f199a73801d3(scenarioData._end)) ..
                        '\nentity: ' .. tostring(scenarioData.entity) .. ' | ' .. tostring(GetEntityAttachedTo(scenarioData.entity)) .. 
                        '\n' .. scenarioData.name ..
                        '\n' .. scenarioData.description
                TxtAtWorldCoord(scenarioData.coord.x, scenarioData.coord.y, scenarioData.coord.z + 1.0, test, 0.2, 1)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)

        for id, scenarioData in pairs(scenarioDatas) do
            if N_0xea31f199a73801d3(scenarioData._start) == 0 and N_0xea31f199a73801d3(scenarioData._end) == 0 then
                if not scenarioData.started then
                    scenarioData.started = true
                    TriggerEvent('immersion:job_started:' .. id, scenarioData)
                end
            end
            if (GetEntityAttachedTo(scenarioData.entity) == 0 or not (N_0xea31f199a73801d3(scenarioData._end) == 0)) and N_0xea31f199a73801d3(scenarioData._start) == 0 then
                if not (N_0xea31f199a73801d3(scenarioData._end) == 0) then
                    scenarioData.item_returned = true
                else
                    scenarioData.item_returned = false
                end
                scenarioData.started = false
                TriggerEvent('immersion:job_ended:' .. id, scenarioData)
                Citizen.Wait(500)
                local coord = scenarioData.coord
                N_0x81948dfe4f5a0283(scenarioData._start) -- DELETE_SCENARIO_POINT
                print('Spawning new feed')
                print('New Scenario Start:', scenarioData._start)
                scenarioData._start = N_0x94b745ce41db58a1(scenarioData._start_hash, coord.x, coord.y, coord.z, scenarioData.coord.h) -- CREATE_SCENARIO_POINT
                Citizen.Wait(50)

                RemoveEntity(scenarioData.entity)

                Citizen.Wait(50)

                scenarioData.entity = DetectEntityAtCoords(coord.x, coord.y, coord.z, scenarioData.detectionSize, scenarioData.entity)
            end
        end
    end
end)

function CreateStartEndScenarion(name, description, startScenario, endScenario, x, y, z, h, detectionSize)
    scenarioId = scenarioId + 1
    local id = scenarioId
    Citizen.CreateThread(function()
        local scenarioData = {}
        scenarioData.name = name
        scenarioData.description = description
        scenarioData.started = false
        scenarioData.coord = {}
        scenarioData.coord.x = x
        scenarioData.coord.y = y
        scenarioData.coord.z = z
        scenarioData.coord.h = h
        scenarioData._start = N_0x94b745ce41db58a1(startScenario, x, y, z, h) -- CREATE_SCENARIO_POINT
        scenarioData._start_hash = startScenario
        scenarioData._end = N_0x94b745ce41db58a1(endScenario, x, y, z, h) -- CREATE_SCENARIO_POINT
        scenarioData._end_hash = endScenario
        scenarioData.detectionSize = detectionSize

        scenarioData.entity = DetectEntityAtCoords(x, y, z, detectionSize)

        print('Scenario Start: ', scenarioData._start)
        print('Scenario End: ', scenarioData._end)
        print('Scenario Entity: ', scenarioData.entity)

        scenarioDatas[id] = scenarioData
    end)
    return id
end

function DetectEntityAtCoords(x, y, z, size, exclude)
    local shapeTest = StartShapeTestBox(x, y, z, size, size, size, 0.0, 0.0, 0.0, true, 16, exclude)
    local rtnVal, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
    local attempts = 0
    while entityHit == 0 and attempts < 1000 do
        Citizen.Wait(1)
        attempts = attempts + 1
        shapeTest = StartShapeTestBox(x, y, z, size, size, size, 0.0, 0.0, 0.0, true, 16, exclude)
        rtnVal, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
    end
    return entityHit
end
