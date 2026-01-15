-- JOS HUB V10 (ELTON'S SECRET METHOD)
-- Este script activa la animación local para validar el daño

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("JOS HUB | ELTON BYPASS", "DarkTheme")

local Main = Window:NewTab("Main")
local Sec = Main:NewSection("Bypass de Animacion")

_G.Aura = false

Sec:NewToggle("Kill Aura (Animation Hook)", "Obliga al servidor a aceptar el daño", function(state)
    _G.Aura = state
    if state then
        print("CombatEvent: Not Found. Sincronizando animaciones...")
        IniciarAura()
    end
end)

function IniciarAura()
    local lp = game.Players.LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true)

    task.spawn(function()
        while _G.Aura do
            pcall(function()
                for _, enemy in pairs(game.Players:GetPlayers()) do
                    if enemy ~= lp and enemy.Character and enemy.Character:FindFirstChild("Humanoid") then
                        local eRoot = enemy.Character.HumanoidRootPart
                        local myRoot = lp.Character.HumanoidRootPart
                        
                        if (myRoot.Position - eRoot.Position).Magnitude < 22 and enemy.Character.Humanoid.Health > 0 then
                            
                            -- EL SECRETO DE ELTON:
                            -- 1. Mirar al enemigo
                            myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(eRoot.Position.X, myRoot.Position.Y, eRoot.Position.Z))
                            
                            -- 2. Forzar Animación Local (Sin esto el daño es 0)
                            local anim = Instance.new("Animation")
                            anim.AnimationId = "rbxassetid://15243144578" -- ID de golpe de UBG
                            local load = lp.Character.Humanoid:LoadAnimation(anim)
                            load:Play()

                            -- 3. Enviar el Daño exacto de KZ Hub
                            local combo = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                            for i = 1, #combo do
                                remote:FireServer(combo[i], enemy.Character)
                                task.wait(0.01)
                            end
                            
                            task.wait(0.1) -- Cooldown
                        end
                    end
                end
            end)
            task.wait(0.05)
        end
    end)
end
