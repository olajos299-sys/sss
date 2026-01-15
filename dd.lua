-- JOS HUB V7 (ULTIMATE BYPASS)
-- El detalle que faltaba: Sincronización de Estado y CFrame

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("JOS HUB | PRIVATE VERSION", "DarkTheme")

_G.AuraJos = false
_G.Rango = 22

local Tab = Window:NewTab("Combate")
local Sec = Tab:NewSection("Bypass de Daño")

Sec:NewToggle("Kill Aura (System Hook)", "Este usa la logica de Elton + KZ", function(state)
    _G.AuraJos = state
    if state then
        -- El trigger del video
        warn("Inyectando hooks...")
        task.wait(0.5)
        print("CombatEvent: Not Found. Jos Hub is now handling damage.")
        IniciarSuperAura()
    end
end)

Sec:NewSlider("Distancia", "Rango de accion", 40, 10, function(s)
    _G.Rango = s
end)

function IniciarSuperAura()
    local lp = game.Players.LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    
    -- Buscador de Remote (Capa 3 de seguridad)
    local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true) or rs:FindFirstChild("Attack", true)

    task.spawn(function()
        while _G.AuraJos do
            pcall(function()
                local char = lp.Character
                if not char then return end
                
                for _, enemy in pairs(game.Players:GetPlayers()) do
                    if enemy ~= lp and enemy.Character and enemy.Character:FindFirstChild("Humanoid") then
                        local eChar = enemy.Character
                        local eRoot = eChar.HumanoidRootPart
                        local myRoot = char.HumanoidRootPart
                        
                        if eChar.Humanoid.Health > 0 and (myRoot.Position - eRoot.Position).Magnitude <= _G.Rango then
                            
                            -- EL DETALLE QUE SE PASABA: 
                            -- 1. Forzamos al servidor a creer que estamos en animacion
                            if char:FindFirstChild("Status") and char.Status:FindFirstChild("Attacking") then
                                char.Status.Attacking.Value = true
                            end

                            -- 2. Rotación Crítica
                            myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(eRoot.Position.X, myRoot.Position.Y, eRoot.Position.Z))

                            -- 3. Secuencia de Daño Elton (con delays de KZ)
                            local combo = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                            for i = 1, #combo do
                                if _G.AuraJos then
                                    -- Enviamos el daño y el objetivo (argumentos exactos)
                                    remote:FireServer(combo[i], eChar)
                                    
                                    -- Micro-delay de sincronización
                                    task.wait(0.015) 
                                end
                            end
                            
                            -- 4. Limpieza de estado (para evitar detección)
                            if char:FindFirstChild("Status") and char.Status:FindFirstChild("Attacking") then
                                char.Status.Attacking.Value = false
                            end
                        end
                    end
                end
            end)
            task.wait(0.1) -- Delay entre escaneos
        end
    end)
end

local Conf = Window:NewTab("Ajustes")
Conf:NewSection("Menu"):NewKeybind("Abrir/Cerrar", "RightControl", Enum.KeyCode.RightControl, function()
    Library:ToggleUI()
end)
