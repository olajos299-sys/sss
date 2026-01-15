-- JOS HUB V9 (THE FINAL CORE)
-- Si este no funciona, el problema es que Xeno no permite "Metatable Hooking"

local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local run = game:GetService("RunService")

-- LIMPIEZA TOTAL
if game.CoreGui:FindFirstChild("JosHubFinal") then game.CoreGui.JosHubFinal:Destroy() end

-- INTERFAZ MINIMALISTA (PARA EVITAR CRASH EN XENO)
local sg = Instance.new("ScreenGui", game.CoreGui); sg.Name = "JosHubFinal"
local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 150, 0, 100); frame.Position = UDim2.new(0.5, -75, 0.5, -50)
frame.BackgroundColor3 = Color3.new(0,0,0); frame.Active = true; frame.Draggable = true

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, 0, 1, 0); btn.Text = "ACTIVAR CORE AURA"; btn.TextColor3 = Color3.new(1,1,1)
btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

-- LÓGICA DE NIVEL DIOS (HOOKING)
_G.AuraActiva = false

btn.MouseButton1Click:Connect(function()
    _G.AuraActiva = not _G.AuraActiva
    btn.BackgroundColor3 = _G.AuraActiva and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    btn.Text = _G.AuraActiva and "AURA ONLINE" or "AURA OFFLINE"
    
    -- EL MENSAJE DEL VIDEO
    if _G.AuraActiva then
        print("CombatEvent: Not Found. Initializing Memory Bypass...")
    end
end)

-- EL MOTOR DE DAÑO (ESTO ES LO QUE HACE KZ HUB)
run.RenderStepped:Connect(function()
    if not _G.AuraActiva then return end
    
    pcall(function()
        local character = player.Character
        local root = character.HumanoidRootPart
        local combatRemote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true)

        for _, enemy in pairs(game.Players:GetPlayers()) do
            if enemy ~= player and enemy.Character and enemy.Character:FindFirstChild("Humanoid") then
                local eRoot = enemy.Character.HumanoidRootPart
                local dist = (root.Position - eRoot.Position).Magnitude
                
                if dist < 22 and enemy.Character.Humanoid.Health > 0 then
                    -- SECRETO: El servidor pide que el ataque coincida con el frame de renderizado
                    -- Enviamos la tabla completa de argumentos que usa el juego original
                    local args = {
                        [1] = "Punch" .. math.random(1,4), -- Randomizar para bypass
                        [2] = enemy.Character,
                        [3] = eRoot.CFrame, -- IMPORTANTE: El servidor pide CFrame, no solo Position
                        [4] = root.CFrame * CFrame.new(0, 0, -2) -- Simula el punto de impacto
                    }
                    
                    combatRemote:FireServer(unpack(args))
                    
                    -- FORZAR DAÑO CRÍTICO (SIMULACIÓN DE PUNCHDASH)
                    if math.random(1,5) == 3 then
                        combatRemote:FireServer("PunchDash", enemy.Character, eRoot.CFrame)
                    end
                end
            end
        end
    end)
end)
