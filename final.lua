local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rs = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")

-- Intentamos encontrar el "Combat Handler" que usan los Hubs
local combatRemote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true)

_G.KillAuraV2 = true

local function getClosestPlayer()
    local closest, dist = nil, 20
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local d = (character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then
                closest = v.Character
                dist = d
            end
        end
    end
    return closest
end

task.spawn(function()
    while _G.KillAuraV2 do
        local target = getClosestPlayer()
        if target then
            -- SIMULACIÓN DE SEGURIDAD (Bypass)
            -- En lugar de solo FireServer, simulamos el estado de "Atacando"
            pcall(function()
                -- 1. Mirar al objetivo (Evita el error de "Too Far")
                character.HumanoidRootPart.CFrame = CFrame.new(character.HumanoidRootPart.Position, target.HumanoidRootPart.Position)
                
                -- 2. Secuencia de ataques del juego
                local attacks = {"Punch1", "Punch2", "Punch3", "Punch4"}
                for _, move in pairs(attacks) do
                    -- El secreto de los Hubs: Enviar el ataque y esperar un milisegundo
                    combatRemote:FireServer(move, target)
                    task.wait(0.01) 
                end
            end)
        end
        task.wait(0.1) -- Velocidad estable para que el Anti-Cheat no te eche
    end
end)
