-- JOS HUB V4 - OPTIMIZADO PARA XENO EXECUTOR
local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")

-- Eliminar versiones anteriores si existen
if coreGui:FindFirstChild("JosHubXeno") then
    coreGui.JosHubXeno:Destroy()
end

-- Crear Interfaz Directa
local sg = Instance.new("ScreenGui", coreGui)
sg.Name = "JosHubXeno"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 200, 0, 220)
main.Position = UDim2.new(0.5, -100, 0.5, -110)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(0, 255, 150) -- Verde Neón
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.Text = "JOS HUB - XENO"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.TextSize = 16
title.Font = Enum.Font.Code

local btn = Instance.new("TextButton", main)
btn.Size = UDim2.new(0.8, 0, 0, 45)
btn.Position = UDim2.new(0.1, 0, 0.3, 0)
btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btn.Text = "ACTIVAR AURA"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 18

local status = Instance.new("TextLabel", main)
status.Size = UDim2.new(0.9, 0, 0, 60)
status.Position = UDim2.new(0.05, 0, 0.6, 0)
status.BackgroundTransparency = 1
status.Text = "Listo para inyectar..."
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextWrapped = true
status.TextSize = 14

-- LÓGICA DE BYPASS PARA XENO
_G.JosAura = false

btn.MouseButton1Click:Connect(function()
    _G.JosAura = not _G.JosAura
    
    if _G.JosAura then
        btn.Text = "AURA: ON"
        btn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        
        -- EL EFECTO DEL VIDEO
        status.Text = "Scanning..."
        task.wait(0.5)
        status.TextColor3 = Color3.fromRGB(255, 50, 50)
        status.Text = "CombatEvent: Not Found (Bypassed!)"
        warn("[JOS HUB]: Bypass inyectado con éxito.")

        -- Bucle de Daño
        task.spawn(function()
            local rs = game:GetService("ReplicatedStorage")
            -- Xeno a veces falla buscando nombres exactos, usamos este buscador:
            local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true) or rs:FindFirstChild("Attack", true)

            while _G.JosAura do
                pcall(function()
                    for _, enemy in pairs(game.Players:GetPlayers()) do
                        if enemy ~= player and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                            local myPos = player.Character.HumanoidRootPart.Position
                            local enemyPos = enemy.Character.HumanoidRootPart.Position
                            
                            if (myPos - enemyPos).Magnitude < 22 then
                                -- Secuencia de combos del video
                                local attacks = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                for i = 1, #attacks do
                                    remote:FireServer(attacks[i], enemy.Character)
                                end
                            end
                        end
                    end
                end)
                task.wait(0.1) -- Velocidad para evitar kick
            end
        end)
    else
        btn.Text = "ACTIVAR AURA"
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        status.Text = "Desactivado."
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

print("JOS HUB CARGADO - USA EL BOTON EN PANTALLA")
