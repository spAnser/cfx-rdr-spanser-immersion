---
--- Window Peek
--- Setup window peeking Prompt
--- WORLD_PLAYER_PEEK_WINDOW
---

local peekGroup = GetRandomIntInRange(0, 0xffffff)
local peekEndGroup = GetRandomIntInRange(0, 0xffffff)
print('peekGroup: ' .. peekGroup)
print('peekEndGroup: ' .. peekEndGroup)
local peekPrompt = false
local peekEndPrompt = false
local peekGroupName = 'Window'
local isPeeking = false
local isPeekStarting = false
local isPeekEnding = false

--- 0xC65A45D4453C2627
--- UIPromptGroupID, String, PageCount, InitialPageIndex, ???, ???, GroupPromptKey ?

Citizen.CreateThread(function()
    Citizen.Wait(10000)
    SetupPeekPrompt()
    SetupPeekEndPrompt()
end)

Citizen.CreateThread(function()
    -- Surrounding Info / Tracking
    while true do
        Citizen.Wait(10)
        local player = PlayerPedId()

        -- Facing Breakable Glass
        local coordsf = GetOffsetFromEntityInWorldCoords(player, 0.0, 0.45, 0.0)
        local shapeTest = StartShapeTestBox(coordsf.x, coordsf.y, coordsf.z, 0.4, 0.4, 1.0, 0.0, 0.0, 0.0, true, 64)
        local rtnVal, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
        if not isPeekEnding and not isPeeking and not IsPedActiveInScenario(player) then
            if hit > 0 then
                local pCoords = GetEntityCoords(player)
                if Config.Debug == 1 then
                    local str = 'Facing window: ' .. tostring(entityHit)
                    local eHeading = GetEntityHeading(entityHit)
                    local pHeading = GetEntityHeading(player)
                    str = str .. '\n' .. pHeading .. ' ' .. eHeading
                    str = str .. '\n' .. Absf(pHeading - eHeading)
                    if Absf(pHeading - eHeading) < 100  then
                        str = str .. '\nFace: ' .. eHeading
                    else
                        str = str .. '\nFace: ' .. 360.0 - eHeading - 180.0
                    end
                    TxtAtWorldCoord(pCoords.x, pCoords.y, pCoords.z, str, 0.2, 1)
                end
                PromptSetActiveGroupThisFrame(peekGroup, peekGroupName)
            end
        end

        if isPeeking and not isPeekStarting then
            PromptSetActiveGroupThisFrame(peekEndGroup, peekGroupName)
        end

        if PromptHasHoldModeCompleted(peekPrompt) then
            isPeeking = true
            isPeekStarting = true
            local eHeading = GetEntityHeading(entityHit)
            local pHeading = GetEntityHeading(player)
            if Absf(pHeading - eHeading) < 100  then
                SetPedDesiredHeading(player, eHeading)
            else
                SetPedDesiredHeading(player, Absf(360.0 - eHeading - 180.0))
            end
            Citizen.Wait(250)
            TaskStartScenarioInPlace(player, GetHashKey('WORLD_PLAYER_PEEK_WINDOW'), 0, true, false, false, false)
            Citizen.Wait(2250)
            isPeekStarting = false
        end
        if PromptHasStandardModeCompleted(peekEndPrompt) then
            isPeeking = false
            isPeekEnding = true
            ClearPedTasks(player)
            Citizen.Wait(1000)
            isPeekEnding = false
        end
    end
end)

function SetupPeekPrompt()
    if not PromptIsValid(peekPrompt) then
        Citizen.CreateThread(function()
            local str = 'Peek'
            peekPrompt = PromptRegisterBegin()
            PromptSetControlAction(peekPrompt, 0xCEFD9220)
            if Config.Debug == 1 then
                str = peekPrompt .. ' : ' .. str
            end
            str = CreateVarString(10, 'LITERAL_STRING', str)
            PromptSetText(peekPrompt, str)
            PromptSetEnabled(peekPrompt, 1)
            PromptSetVisible(peekPrompt, 1)
            PromptSetHoldMode(peekPrompt, 1)
            -- PromptSetAttribute(peekPrompt, 24, true)

            PromptSetGroup(peekPrompt, peekGroup)
            PromptRegisterEnd(peekPrompt)

            print('Created peekPrompt: ' .. peekPrompt)
        end)
    end
end

function SetupPeekEndPrompt()
    if not PromptIsValid(peekEndPrompt) then
        local str = 'Leave'
        peekEndPrompt = PromptRegisterBegin()
        PromptSetControlAction(peekEndPrompt, 0xB2F377E8)
        if Config.Debug == 1 then
            str = peekEndPrompt .. ' : ' .. str
        end
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(peekEndPrompt, str)
        PromptSetEnabled(peekEndPrompt, 1)
        PromptSetVisible(peekEndPrompt, 1)
        PromptSetStandardMode(peekEndPrompt, 1)

        PromptSetGroup(peekEndPrompt, peekEndGroup)
        PromptRegisterEnd(peekEndPrompt)

        print('Created peekEndPrompt: ' .. peekEndPrompt)
    end
end
