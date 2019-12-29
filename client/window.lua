---
--- Window Peek
--- Setup window peeking Prompt
--- WORLD_PLAYER_PEEK_WINDOW
---

local peekGroup = GetRandomIntInRange(0, 0xffffff)
local peekEndGroup = GetRandomIntInRange(0, 0xffffff)
print('peekGroup: ' .. peekGroup)
print('peekEndGroup: ' .. peekEndGroup)
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
                Citizen.InvokeNative(0xC65A45D4453C2627, peekGroup, peekGroupName)
            end
        end

        if isPeeking and not isPeekStarting then
            Citizen.InvokeNative(0xC65A45D4453C2627, peekEndGroup, peekGroupName)
        end

        if Citizen.InvokeNative(0xE0F65F0640EF0617, peekPrompt) then -- _UIPROMPT_HAS_HOLD_MODE_COMPLETED
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
        if Citizen.InvokeNative(0xC92AC953F0A982AE, peekEndPrompt) then -- _UIPROMPT_HAS_STANDARD_MODE_COMPLETED
            isPeeking = false
            isPeekEnding = true
            ClearPedTasks(player)
            Citizen.Wait(1000)
            isPeekEnding = false
        end
    end
end)

function SetupPeekPrompt()
    if not Citizen.InvokeNative(0x347469FBDD1589A9, peekPrompt) then -- _UIPROMPT_IS_VALID
        Citizen.CreateThread(function()
            local str = CreateVarString(10, 'LITERAL_STRING', 'Peek')
            peekPrompt = Citizen.InvokeNative(0x29FA7910726C3889, 0xCEFD9220, str, 6, 1, 1, -1) -- _UIPROMPT_CREATE
            print('Created peekPrompt: ' .. peekPrompt)
            if Config.Debug == 1 then
                str = CreateVarString(10, 'LITERAL_STRING', peekPrompt .. ' : Peek')
                Citizen.InvokeNative(0x5DD02A8318420DD7, peekPrompt, str)
            end
            Citizen.InvokeNative(0x8A0FB4D03A630D21, peekPrompt, 1) -- _UIPROMPT_SET_ENABLED
            Citizen.InvokeNative(0x71215ACCFDE075EE, peekPrompt, 1) -- _UIPROMPT_SET_VISIBLE
            Citizen.InvokeNative(0x94073D5CA3F16B7B, peekPrompt, 1) -- _UIPROMPT_SET_HOLD_MODE -- Get Hold Mode with 0xB60C9F9ED47ABB76
            -- Citizen.InvokeNative(0x560E76D5E2E1803F, peekPrompt, 24, true) -- _UIPROMPT_SET_ATTRIBUTE
            -- Citizen.InvokeNative(0xD9459157EB22C895) -- Set Prompts to Horizontal ... Not sure how to turn back vertical after calling this.

            Citizen.InvokeNative(0x2F11D3A254169EA4, peekPrompt, peekGroup) -- _UIPROMPT_SET_GROUP
        end)
    end
end

function SetupPeekEndPrompt()
    if not Citizen.InvokeNative(0x347469FBDD1589A9, peekEndPrompt) then -- _UIPROMPT_IS_VALID
        local str = CreateVarString(10, 'LITERAL_STRING', 'Leave')
        peekEndPrompt = Citizen.InvokeNative(0x29FA7910726C3889, 0xB2F377E8, str, 6, 1, 1, -1) -- _UIPROMPT_CREATE
        print('Created peekEndPrompt: ' .. peekEndPrompt)
        if Config.Debug == 1 then
            str = CreateVarString(10, 'LITERAL_STRING', peekEndPrompt .. ' : Leave')
            Citizen.InvokeNative(0x5DD02A8318420DD7, peekEndPrompt, str)
        end
        Citizen.InvokeNative(0x8A0FB4D03A630D21, peekEndPrompt, 1) -- _UIPROMPT_SET_ENABLED
        Citizen.InvokeNative(0x71215ACCFDE075EE, peekEndPrompt, 1) -- _UIPROMPT_SET_VISIBLE
        Citizen.InvokeNative(0xCC6656799977741B, peekEndPrompt, 1) -- _UIPROMPT_SET_STANDARD_MODE
        -- Citizen.InvokeNative(0x560E76D5E2E1803F, peekEndPrompt, 24, true) -- _UIPROMPT_SET_ATTRIBUTE
        -- Citizen.InvokeNative(0xD9459157EB22C895) -- Set Prompts to Horizontal ... Not sure how to turn back vertical after calling this.

        Citizen.InvokeNative(0x2F11D3A254169EA4, peekEndPrompt, peekEndGroup) -- _UIPROMPT_SET_GROUP
    end
end
