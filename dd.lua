-- JOS HUB V13 (ELTON'S ENGINE BYPASS)
-- Usando el método exacto del loadstring que pasaste

local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("JOS HUB | ELTON EDITION", "DarkTheme")

_G.Aura = false

local Main = Window:NewTab("Combate")
local Sec = Main:NewSection("Elton's Method")

Sec:NewToggle("Kill Aura (V13 FINAL)", "Bypass de validacion de servidor", function(state)
    _G.Aura = state
    if state then
        warn("Bypass Inyectado: Sincronizando con el servidor...")
        EjecutarAuraElton()
    end
end)

function EjecutarAuraElton()
    local lp = game.Players.LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    
    -- El servidor de UBG a veces cambia de lugar el Remote, esto lo encuentra siempre
    local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true)

    task.spawn(function()
        while _G.Aura do
            pcall(function()
                for _, v in pairs(game.Players:GetPlayers()) do
                    if v ~= lp and v.Character and v.Character:FindFirstChild("Humanoid") then
                        local enemy = v.Character
                        local dist = (lp.Character.HumanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
                        
                        if dist < 22 and enemy.Humanoid.Health > 0 then
                            -- EL SECRETO DE ELTON:
                            -- El servidor valida el daño solo si el "LookVector" de la camara
                            -- coincide con la direccion del golpe.
                            
                            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, enemy.HumanoidRootPart.Position)

                            -- TABLA DE ARGUMENTOS QUE USA ELTON
                            local combo = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                            
                            for i = 1, #combo do
                                if _G.Aura then
                                    -- Enviamos el ataque simulando el script original del juego
                                    remote:FireServer(
                                        combo[i], 
                                        enemy, 
                                        enemy.HumanoidRootPart.CFrame, 
                                        lp.Character.HumanoidRootPart.CFrame
                                    )
                                    -- El delay de Elton para que no te de kick
                                    task.wait(0.012)
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.1)
        end
    end)
end

-- Boton extra por si el juego no detecta los puños
Sec:NewButton("Fix Daño (Forzar Puños)", "Equipa el combate si falla", function()
    local tool = lp.Backpack:FindFirstChild("Combat") or lp.Character:FindFirstChild("Combat")
    if tool then
        lp.Character.Humanoid:EquipTool(tool)
    end
end)
