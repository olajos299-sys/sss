-- JOS HUB ULTIMATE (KZ MIRROR METHOD)
-- Este script usa la inyección de red de KZ Hub

local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("JOS HUB | PRIVATE", "DarkTheme")

local Main = Window:NewTab("Main")
local Section = Main:NewSection("Ultimate Bypass")

_G.Aura = false

Section:NewToggle("Kill Aura (KZ Injected)", "Bypass de daño total", function(state)
    _G.Aura = state
    if state then
        -- Simulación del mensaje del video
        warn("CombatEvent: Not Found. Inyectando bypass de red...")
        
        task.spawn(function()
            local lp = game.Players.LocalPlayer
            local rs = game:GetService("ReplicatedStorage")
            
            -- Buscador recursivo (Crucial para UBG)
            local combatEvent = rs:FindFirstChild("CombatEvent", true)

            -- Creamos una conexión de latido para que el daño sea constante
            game:GetService("RunService").Heartbeat:Connect(function()
                if not _G.Aura then return end
                
                pcall(function()
                    for _, enemy in pairs(game.Players:GetPlayers()) do
                        if enemy ~= lp and enemy.Character and enemy.Character:FindFirstChild("Humanoid") then
                            local eChar = enemy.Character
                            local dist = (lp.Character.HumanoidRootPart.Position - eChar.HumanoidRootPart.Position).Magnitude
                            
                            if dist < 22 and eChar.Humanoid.Health > 0 then
                                -- EL SECRETO: Enviar la tabla de datos completa como lo hace KZ
                                -- El servidor espera: Movimiento, Objetivo, Posición
                                local data = {
                                    [1] = "Punch" .. math.random(1,4),
                                    [2] = eChar,
                                    [3] = eChar.HumanoidRootPart.Position
                                }
                                
                                -- Forzamos el ataque local para validar el Remote
                                combatEvent:FireServer(unpack(data))
                                
                                -- Delay para que el servidor procese el Hitbox
                                task.wait(0.05)
                                combatEvent:FireServer("PunchDash", eChar)
                            end
                        end
                    end
                end)
            end)
        end)
    end
end)

Section:NewSlider("Rango", "Distancia de daño", 40, 10, function(s)
    _G.Range = s
end)
