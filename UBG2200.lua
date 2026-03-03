-- JOS HUB V4.1: ULTRA-HIGH BATTLE VISION
local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- CONFIGURACIÓN DE VISIÓN ELEVADA
local Keybind = "t"
local Prediction = 0.12
local Smoothness = 0.25 -- Aumentado para que el loop sea fluido desde arriba

-- AJUSTES DE CÁMARA (Modifica estos para subir más la vista)
local VerticalLookOffset = -2 -- NEGATIVO hace que la cámara mire más al suelo (subiendo la vista)
local CameraHeightBonus = 4   -- Añade altura extra a tu cámara actual

local Target = nil
local Locked = false

--- [ INTERFAZ ] ---
local sg = Instance.new("ScreenGui", game.CoreGui); sg.Name = "JosHub_V4_1"
local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 140, 0, 90); frame.Position = UDim2.new(0, 50, 0.5, -45)
frame.BackgroundColor3 = Color3.fromRGB(5, 5, 5); frame.Active = true; frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25); title.Text = "JOS HIGH VISION"; title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundColor3 = Color3.fromRGB(100, 50, 0)

local lockStatus = Instance.new("TextLabel", frame)
lockStatus.Size = UDim2.new(1, 0, 0, 30); lockStatus.Position = UDim2.new(0, 0, 0, 25)
lockStatus.Text = "LOCK: OFF"; lockStatus.TextColor3 = Color3.fromRGB(255, 50, 50); lockStatus.BackgroundTransparency = 1

local rjButton = Instance.new("TextButton", frame)
rjButton.Size = UDim2.new(0.9, 0, 0, 25); rjButton.Position = UDim2.new(0.05, 0, 0, 60)
rjButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30); rjButton.Text = "REJOIN [P]"; rjButton.TextColor3 = Color3.new(1, 1, 1)

--- [ LÓGICA ] ---

function GetClosest()
    local closestDist = math.huge
    local closestObj = nil
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= Player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if dist < closestDist then closestDist = dist; closestObj = v.Character end
            end
        end
    end
    return closestObj
end

Mouse.KeyDown:Connect(function(k)
    if k:lower() == Keybind then
        Locked = not Locked
        if Locked then
            Target = GetClosest()
            if not Target then Locked = false else
                lockStatus.Text = "LOCK: ON"; lockStatus.TextColor3 = Color3.fromRGB(50, 255, 50)
            end
        else
            Target = nil
            lockStatus.Text = "LOCK: OFF"; lockStatus.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    elseif k:lower() == "p" then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end
end)

--- [ MOTOR DE CÁMARA ALTA ] ---
RunService.RenderStepped:Connect(function()
    if Locked and Target and Target:FindFirstChild("HumanoidRootPart") then
        local enemyRoot = Target.HumanoidRootPart
        
        if Target.Humanoid.Health > 0 then
          
            local enemyPos = enemyRoot.Position + (enemyRoot.Velocity * Prediction)
            
            
            local focusPoint = enemyPos + Vector3.new(0, VerticalLookOffset, 0)
            
           
            -- Mantenemos la posición actual de la cámara pero la forzamos a mirar al punto de enfoque
            local targetCF = CFrame.lookAt(Camera.CFrame.Position, focusPoint)
            
            
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, Smoothness)
        else
            Locked = false; Target = nil
            lockStatus.Text = "LOCK: OFF"
        end
    end
end)
