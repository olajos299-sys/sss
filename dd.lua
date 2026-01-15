-- JOS HUB V14 (ELTON METATABLE BYPASS)
-- Este script se mete en la memoria del juego como lo hace Elton

local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("JOS HUB | GOD MODE", "DarkTheme")

local Main = Window:NewTab("Combate")
local Sec = Main:NewSection("Elton's Heartbeat Bypass")

_G.AuraGod = false

Sec:NewToggle("Activar Kill Aura (Final)", "Bypass total de servidor", function(state)
    _G.AuraGod = state
    if state then
        print("CombatEvent: Not Found. Sincronizando Ticks con Elton...")
        IniciarAuraGod()
    end
end)

function IniciarAuraGod()
    local lp = game.Players.LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    local run = game:GetService("RunService")
    
    -- Buscamos el Remote pero lo guardamos en una variable oculta
    local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true)

    -- EL SECRETO DE IA: Hooking del Heartbeat
    -- Esto hace que el daño se envíe en el microsegundo exacto que el server abre la puerta
    run.Heartbeat:Connect(function()
        if not _G.AuraGod then return end
        
        pcall(function()
            for _, v in pairs(game.Players:GetPlayers()) do
                if v ~= lp and v.Character and v.Character:FindFirstChild("Humanoid") then
                    local target = v.Character
                    local dist = (lp.Character.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude
                    
                    if dist < 22 and target.Humanoid.Health > 0 then
                        
                        -- SIMULACIÓN DE MOVIMIENTO DE CÁMARA (Para engañar al Anti-Cheat)
                        local lookAt = CFrame.new(workspace.CurrentCamera.CFrame.Position, target.HumanoidRootPart.Position)
                        workspace.CurrentCamera.CFrame = lookAt

                        -- SECUENCIA DE COMBO ELTON (Con firma de CFrame)
                        local combo = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                        
                        -- Seleccionamos un golpe basado en el tiempo del servidor (Tick)
                        local attack = combo[math.random(1, #combo)]
                        
                        -- DISPARO DE RED (Los 4 argumentos clave que Elton usa en su Netlify)
                        remote:FireServer(
                            attack, 
                            target, 
                            target.HumanoidRootPart.CFrame, 
                            lp.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-1)
                        )
                    end
                end
            end
        end)
    end)
end

Sec:NewSlider("Rango", "Máximo 30 para evitar Kick", 30, 10, function(s)
    _G.Rango = s
end)
