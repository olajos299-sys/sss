local p = game.Players.LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
local r = c:WaitForChild("HumanoidRootPart")
local rs = game:GetService("ReplicatedStorage")
local vu = game:GetService("VirtualUser")

-- Nombres de ataques que vimos en tus fotos (F9)
local actions = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}

-- Buscador de eventos mejorado
local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true) or rs:FindFirstChild("Combat", true)

_G.AuraActiva = true

task.spawn(function()
    while _G.AuraActiva do
        local players = game.Players:GetPlayers()
        for i = 1, #players do
            local v = players[i]
            if v ~= p and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") then
                if v.Character.Humanoid.Health > 0 then
                    local er = v.Character.HumanoidRootPart
                    local dist = (r.Position - er.Position).Magnitude
                    
                    if dist < 20 then
                        -- 1. Mirar al enemigo (Crea un Hitbox válido para el servidor)
                        r.CFrame = CFrame.new(r.Position, Vector3.new(er.Position.X, r.Position.Y, er.Position.Z))
                        
                        -- 2. Simular clic real (Esto autoriza la acción en el servidor)
                        vu:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        
                        -- 3. Enviar el Remote con la secuencia correcta
                        if remote then
                            for j = 1, #actions do
                                pcall(function()
                                    remote:FireServer(actions[j], v.Character)
                                end)
                            end
                        end
                        
                        task.wait(0.1)
                        vu:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)
