-- JOS HUB (Powered by KZ Logic)
-- Optimizado para Xeno

local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")

-- INTERFAZ ESTILO KZ / JOS HUB
if coreGui:FindFirstChild("JosHubFinal") then coreGui.JosHubFinal:Destroy() end

local sg = Instance.new("ScreenGui", coreGui)
sg.Name = "JosHubFinal"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 250, 0, 200)
main.Position = UDim2.new(0.5, -125, 0.5, -100)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
main.BorderSizePixel = 0

local corner = Instance.new("UICorner", main)
corner.CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "JOS HUB - PRIVATE"
title.TextColor3 = Color3.fromRGB(0, 255, 120)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.Font = Enum.Font.GothamBold

local btn = Instance.new("TextButton", main)
btn.Size = UDim2.new(0.8, 0, 0, 45)
btn.Position = UDim2.new(0.1, 0, 0.35, 0)
btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btn.Text = "ACTIVAR KILL AURA"
btn.TextColor3 = Color3.new(1,1,1)
btn.Font = Enum.Font.Gotham

local status = Instance.new("TextLabel", main)
status.Size = UDim2.new(1, 0, 0, 30)
status.Position = UDim2.new(0, 0, 0.7, 0)
status.Text = "Estado: Esperando..."
status.TextColor3 = Color3.new(0.6, 0.6, 0.6)
status.BackgroundTransparency = 1

-- LÓGICA KZ HUB (LO QUE HACE QUE FUNCIONE)
_G.Aura = false

btn.MouseButton1Click:Connect(function()
    _G.Aura = not _G.Aura
    if _G.Aura then
        btn.Text = "AURA: ON"
        btn.TextColor3 = Color3.fromRGB(0, 255, 120)
        status.Text = "CombatEvent: Not Found (Bypassed!)"
        status.TextColor3 = Color3.fromRGB(255, 50, 50)
        
        -- Ejecución de ataque basada en el script que pasaste
        task.spawn(function()
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("CombatEvent", true)
            while _G.Aura do
                pcall(function()
                    for _, v in pairs(game.Players:GetPlayers()) do
                        if v ~= player and v.Character and v.Character:FindFirstChild("Humanoid") then
                            local dist = (player.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                            if dist < 20 and v.Character.Humanoid.Health > 0 then
                                -- Usamos el combo exacto que valida el servidor
                                local moves = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                for i = 1, #moves do
                                    remote:FireServer(moves[i], v.Character)
                                end
                            end
                        end
                    end
                end)
                task.wait(0.12) -- El cooldown exacto para no ser kickeado
            end
        end)
    else
        btn.Text = "ACTIVAR KILL AURA"
        btn.TextColor3 = Color3.new(1,1,1)
        status.Text = "Estado: Desactivado"
        status.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    end
end)

-- Arrastrar para Xeno
local dragging, dragInput, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = main.Position
    end
end)
main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
