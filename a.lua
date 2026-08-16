local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- --- CONFIGURACIÓN PARA CELULAR ---
_G.AimlockEnabled = false
_G.ESPEnabled = false
_G.TargetPart = "Head"
_G.FOVRadius = 120 -- Tamaño del rango de enganche en pantalla
_G.Smoothness = 0.25 -- Suavidad (0.1 = muy suave, 1 = instantáneo)

local currentTarget = nil

-- --- INTERFAZ FLOTANTE MOBILE ---
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 160, 0, 150)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local Corner = Instance.new("UICorner", MainFrame)
Corner.CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Aimbot Mobile"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
local TitleCorner = Instance.new("UICorner", Title)
TitleCorner.CornerRadius = UDim.new(0, 8)

-- Botón Aimlock
local AimBtn = Instance.new("TextButton", MainFrame)
AimBtn.Size = UDim2.new(0.9, 0, 0, 32)
AimBtn.Position = UDim2.new(0.05, 0, 0.26, 0)
AimBtn.Text = "Aimbot: OFF"
AimBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
AimBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", AimBtn)

AimBtn.MouseButton1Click:Connect(function()
    _G.AimlockEnabled = not _G.AimlockEnabled
    AimBtn.Text = _G.AimlockEnabled and "Aimbot: ON" or "Aimbot: OFF"
    AimBtn.BackgroundColor3 = _G.AimlockEnabled and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
    if not _G.AimlockEnabled then currentTarget = nil end
end)

-- Botón ESP
local ESPBtn = Instance.new("TextButton", MainFrame)
ESPBtn.Size = UDim2.new(0.9, 0, 0, 32)
ESPBtn.Position = UDim2.new(0.05, 0, 0.50, 0)
ESPBtn.Text = "ESP: OFF"
ESPBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ESPBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ESPBtn)

ESPBtn.MouseButton1Click:Connect(function()
    _G.ESPEnabled = not _G.ESPEnabled
    ESPBtn.Text = _G.ESPEnabled and "ESP: ON" or "ESP: OFF"
    ESPBtn.BackgroundColor3 = _G.ESPEnabled and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
end)

-- Botón Rejoin
local RejoinBtn = Instance.new("TextButton", MainFrame)
RejoinBtn.Size = UDim2.new(0.9, 0, 0, 32)
RejoinBtn.Position = UDim2.new(0.05, 0, 0.74, 0)
RejoinBtn.Text = "Rejoin Server"
RejoinBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
RejoinBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", RejoinBtn)

RejoinBtn.MouseButton1Click:Connect(function()
    RejoinBtn.Text = "Reconectando..."
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nReconectando...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end)

-- --- SISTEMA ESP ---
local function createESP(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 1
    box.Transparency = 1
    box.Filled = false

    RunService.RenderStepped:Connect(function()
        if _G.ESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                local headPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0)).Y
                local legPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, -3, 0)).Y
                local sizeY = math.abs(headPos - legPos)
                
                box.Size = Vector2.new(sizeY * 0.6, sizeY)
                box.Position = Vector2.new(pos.X - box.Size.X / 2, pos.Y - box.Size.Y / 2)
                box.Visible = true
            else
                box.Visible = false
            end
        else
            box.Visible = false
            if not player.Parent then
                box:Remove()
            end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createESP(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createESP(p) end end)

-- --- BÚSQUEDA DE OBJETIVO VÁLIDO ---
local function getClosestPlayerInFOV()
    local target = nil
    local shortestDistance = _G.FOVRadius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(_G.TargetPart) then
            local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local part = v.Character[_G.TargetPart]
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                
                if onScreen then
                    local magnitude = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if magnitude < shortestDistance then
                        target = part
                        shortestDistance = magnitude
                    end
                end
            end
        end
    end
    return target
end

-- --- AIMBOT FLUIDO PARA PANTALLAS TÁCTILES ---
RunService.RenderStepped:Connect(function()
    if _G.AimlockEnabled then
        if not currentTarget or not currentTarget.Parent or not currentTarget.Parent:FindFirstChildOfClass("Humanoid") or currentTarget.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then
            currentTarget = getClosestPlayerInFOV()
        else
            -- Verificar si sigue dentro de la pantalla
            local pos, onScreen = Camera:WorldToViewportPoint(currentTarget.Position)
            if not onScreen then
                currentTarget = getClosestPlayerInFOV()
            end
        end

        if currentTarget then
            local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, currentTarget.Position)
            -- Interpolación para evitar tirones de cámara en mobile
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, _G.Smoothness)
        end
    end
end)
