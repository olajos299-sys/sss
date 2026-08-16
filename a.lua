local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- --- CONFIGURACIÓN DELTA ---
_G.AimlockEnabled = false
_G.ESPEnabled = false
_G.TargetPart = "Head"
_G.FOVRadius = 150
_G.Smoothness = 0.2 -- Ajuste de velocidad (0.1 = muy suave, 0.5 = rápido)

local currentTarget = nil

-- --- INTERFAZ COMPATIBLE CON DELTA MOBILE ---
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaHubMobile"
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 150, 0, 140)
MainFrame.Position = UDim2.new(0.02, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local Corner = Instance.new("UICorner", MainFrame)
Corner.CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 28)
Title.Text = "DELTA HUB"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
local TitleCorner = Instance.new("UICorner", Title)
TitleCorner.CornerRadius = UDim.new(0, 8)

-- Botón Aimbot
local AimBtn = Instance.new("TextButton", MainFrame)
AimBtn.Size = UDim2.new(0.9, 0, 0, 30)
AimBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
AimBtn.Text = "Aimbot: OFF"
AimBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
AimBtn.TextColor3 = Color3.new(1, 1, 1)
AimBtn.Font = Enum.Font.SourceSans
Instance.new("UICorner", AimBtn)

AimBtn.MouseButton1Click:Connect(function()
    _G.AimlockEnabled = not _G.AimlockEnabled
    AimBtn.Text = _G.AimlockEnabled and "Aimbot: ON" or "Aimbot: OFF"
    AimBtn.BackgroundColor3 = _G.AimlockEnabled and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
    if not _G.AimlockEnabled then currentTarget = nil end
end)

-- Botón ESP
local ESPBtn = Instance.new("TextButton", MainFrame)
ESPBtn.Size = UDim2.new(0.9, 0, 0, 30)
ESPBtn.Position = UDim2.new(0.05, 0, 0.50, 0)
ESPBtn.Text = "ESP: OFF"
ESPBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
ESPBtn.TextColor3 = Color3.new(1, 1, 1)
ESPBtn.Font = Enum.Font.SourceSans
Instance.new("UICorner", ESPBtn)

ESPBtn.MouseButton1Click:Connect(function()
    _G.ESPEnabled = not _G.ESPEnabled
    ESPBtn.Text = _G.ESPEnabled and "ESP: ON" or "ESP: OFF"
    ESPBtn.BackgroundColor3 = _G.ESPEnabled and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
end)

-- Botón Rejoin
local RejoinBtn = Instance.new("TextButton", MainFrame)
RejoinBtn.Size = UDim2.new(0.9, 0, 0, 30)
RejoinBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
RejoinBtn.Text = "Rejoin Same Server"
RejoinBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
RejoinBtn.TextColor3 = Color3.new(1, 1, 1)
RejoinBtn.Font = Enum.Font.SourceSans
Instance.new("UICorner", RejoinBtn)

RejoinBtn.MouseButton1Click:Connect(function()
    RejoinBtn.Text = "Reconectando..."
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nReconectando al servidor...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end)

-- --- ESP HIGHLIGHT (OPTIMIZADO PARA DELTA) ---
local function applyESP(player)
    if player == LocalPlayer then return end

    local function setupHighlight(char)
        if not char then return end
        local hl = char:FindFirstChild("DeltaESP") or Instance.new("Highlight")
        hl.Name = "DeltaESP"
        hl.FillColor = Color3.fromRGB(255, 0, 50)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0
        hl.Enabled = _G.ESPEnabled
        hl.Parent = char
    end

    if player.Character then setupHighlight(player.Character) end
    player.CharacterAdded:Connect(setupHighlight)
end

for _, p in pairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(applyESP)

RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hl = p.Character:FindFirstChild("DeltaESP")
            if hl then
                hl.Enabled = _G.ESPEnabled
            end
        end
    end
end)

-- --- VALIDACIÓN EXCLUSIVA DE ENEMIGOS ---
local function isTargetValid(part)
    if not part or not part.Parent then return false end
    local char = part.Parent
    
    -- Ignorar completamente al jugador local y su personaje
    if LocalPlayer.Character and char:IsDescendantOf(LocalPlayer.Character) then return false end
    if char == LocalPlayer.Character then return false end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    return true
end

-- --- BÚSQUEDA DEL OBJETIVO MÁS CERCANO A LA PANTALLA ---
local function getClosestEnemy()
    local closestTarget = nil
    local maxDistance = _G.FOVRadius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(_G.TargetPart)
            if targetPart and isTargetValid(targetPart) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < maxDistance then
                        closestTarget = targetPart
                        maxDistance = dist
                    end
                end
            end
        end
    end
    return closestTarget
end

-- --- EJECUCIÓN DEL AIMBOT SIN BLOQUEAR CÁMARA MÓVIL ---
RunService.RenderStepped:Connect(function()
    if _G.AimlockEnabled then
        if not isTargetValid(currentTarget) then
            currentTarget = getClosestEnemy()
        else
            local _, onScreen = Camera:WorldToViewportPoint(currentTarget.Position)
            if not onScreen then
                currentTarget = getClosestEnemy()
            end
        end

        if currentTarget then
            local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, currentTarget.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, _G.Smoothness)
        end
    else
        currentTarget = nil
    end
end)
