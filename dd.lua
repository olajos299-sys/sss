-- JOS HUB PRIVATE - KILL AURA FIX
local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("JOS HUB | FIX DAÑO", "DarkTheme")

local Main = Window:NewTab("Main")
local Section = Main:NewSection("Combat Bypass")

_G.KillAura = false
_G.Distance = 22 -- Default distance

Section:NewToggle("Kill Aura (KZ Method)", "Este SI hace daño", function(state)
    _G.KillAura = state
    if state then
        -- Mensaje de confirmación del video
        print("CombatEvent: Not Found. Starting Jos Hub Damage Sequence...")

        task.spawn(function()
            local lp = game.Players.LocalPlayer
            local rs = game:GetService("ReplicatedStorage")

            -- Buscador de Remote EXACTO de KZ Hub
            local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true)

            if not remote then
                warn("Remote event not found!")
                return
            end

            while _G.KillAura do
                pcall(function()
                    for _, v in pairs(game.Players:GetPlayers()) do
                        if v ~= lp and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                            local enemyPart = v.Character.HumanoidRootPart
                            local myPart = lp.Character.HumanoidRootPart
                            local dist = (myPart.Position - enemyPart.Position).Magnitude

                            if dist < _G.Distance then
                                -- EL SECRETO: El servidor pide que "mires" al objetivo y ataques en orden
                                -- 1. Orientación rápida
                                myPart.CFrame = CFrame.new(myPart.Position, Vector3.new(enemyPart.Position.X, myPart.Position.Y, enemyPart.Position.Z))

                                -- 2. Secuencia de Daño KZ (No enviar todo junto, usar micro-delays)
                                local combo = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                for i = 1, #combo do
                                    if _G.KillAura then
                                        -- Enviamos el daño con la tabla de argumentos que el server espera
                                        remote:FireServer(combo[i], v.Character)
                                        task.wait(0.01) -- Micro-delay para que el server no lo ignore
                                        print("Fired ", combo[i], " to ", v.Name) -- Debug information
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.1) -- Cooldown entre combos
            end
        end)
    end
end)

Section:NewSlider("Rango", "Distancia", 50, 10, function(s)
    _G.Distance = s
end)
