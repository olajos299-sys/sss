local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- --- CONFIGURACIONES ---
_G.AimlockEnabled = false
_G.ESPEnabled = false
_G.TargetPart = "Head"
local currentTarget = nil

-- --- INTERFAZ TÁCTIL PARA MOBILE ---
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
Title.Text = "Mobile Menu"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
local TitleCorner = Instance.new("UICorner", Title)
TitleCorner.CornerRadius = UDim.new(0, 8)

-- Botón Aimlock
local AimBtn = Instance.new("TextButton", MainFrame)
AimBtn.Size = UDim2.new(0.9, 0, 0, 32)
AimBtn.Position = UDim2.new(0.05, 0, 0.26, 0)
AimBtn.Text = "Aimlock: OFF"
AimBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
AimBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", AimBtn)

AimBtn.MouseButton1Click:Connect(function()
    _G.AimlockEnabled = not _G.AimlockEnabled
    AimBtn.Text = _G.AimlockEnabled and "Aimlock: ON" or "Aimlock: OFF"
    AimBtn.BackgroundColor3 = _G.AimlockEnabled and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(180, 50, 50)
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

    local function update()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if _G.ESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local rootPart = player.Character.HumanoidRootPart
                local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    local size = (Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, -3, 0)).Y)
                    box.Size = Vector2.new(math.abs(size * 0.6), math.abs(size))
                    box.Position = Vector2.new(pos.X - box.Size.X / 2, pos.Y - box.Size.Y / 2)
                    box.Visible = true
                else
                    box.Visible = false
                end
            else
                box.Visible = false
                if not player.Parent then
                    box:Remove()
                    connection:Disconnect()
                end
            end
        end)
    end
    coroutine.wrap(update)()
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createESP(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createESP(p) end end)

-- --- LÓGICA STICKY ---
local function isAlive(target)
    if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
        return target.Parent.Humanoid.Health > 0
    end
    return false
end

local function getClosest()
    local target = nil
    local dist = math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(_G.TargetPart) then
            local humanoid = v.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(v.Character[_G.TargetPart].Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < dist then
                        target = v.Character[_G.TargetPart]
                        dist = mag
                    end
                end
            end
        end
    end
    return target
end

-- --- AIMLOCK (FUERZA BRUTA) ---
RunService:BindToRenderStep("HardLockRivals", 201, function()
    if _G.AimlockEnabled then
        if not currentTarget or not isAlive(currentTarget) then
            currentTarget = getClosest()
        end

        if currentTarget then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, currentTarget.Position)
        end
    else
        currentTarget = nil
    end
end)
