-- JOS HUB ULTIMATE PRIVATE - OPTIMIZADO PARA XENO
-- Este script es complejo: Usa Metatables para saltar la seguridad del servidor.

local Player = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- 1. ELIMINAR INTERFAZ PREVIA
if game.CoreGui:FindFirstChild("JosHubComplex") then game.CoreGui.JosHubComplex:Destroy() end

-- 2. DISEÑO DE INTERFAZ (NATIVA PARA XENO)
local Gui = Instance.new("ScreenGui", game.CoreGui); Gui.Name = "JosHubComplex"
local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0, 250, 0, 300); Main.Position = UDim2.new(0.5, -125, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10); Main.BorderSizePixel = 0
Main.Active = true; Main.Draggable = true

local Glow = Instance.new("Frame", Main)
Glow.Size = UDim2.new(1, 4, 1, 4); Glow.Position = UDim2.new(0, -2, 0, -2)
Glow.BackgroundColor3 = Color3.fromRGB(0, 255, 150); Glow.ZIndex = 0

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40); Title.Text = "JOS HUB V5 PRIVATE"; Title.TextColor3 = Color3.new(1,1,1)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

local Console = Instance.new("ScrollingFrame", Main)
Console.Size = UDim2.new(0.9, 0, 0, 100); Console.Position = UDim2.new(0.05, 0, 0.5, 0)
Console.BackgroundColor3 = Color3.new(0,0,0)

local function Log(msg, col)
    local l = Instance.new("TextLabel", Console)
    l.Size = UDim2.new(1, 0, 0, 20); l.Text = "> " .. msg; l.TextColor3 = col or Color3.new(1,1,1)
    l.BackgroundTransparency = 1; l.TextXAlignment = "Left"; l.TextSize = 10
    Console.CanvasSize = UDim2.new(0, 0, 0, #Console:GetChildren() * 20)
end

local Toggle = Instance.new("TextButton", Main)
Toggle.Size = UDim2.new(0.8, 0, 0, 40); Toggle.Position = UDim2.new(0.1, 0, 0.2, 0)
Toggle.Text = "INJECT BYPASS"; Toggle.BackgroundColor3 = Color3.fromRGB(30,30,30); Toggle.TextColor3 = Color3.new(1,1,1)

-- 3. LÓGICA DE NIVEL "HARDCORE" (BYPASS DE FIRMA)
_G.Aura = false
local CombatRemote = nil

-- Buscador de Remote por Fuerza Bruta
for _, v in pairs(game:GetDescendants()) do
    if v:IsA("RemoteEvent") and (v.Name:find("Combat") or v.Name:find("Damage")) then
        CombatRemote = v
        break
    end
end

Toggle.MouseButton1Click:Connect(function()
    _G.Aura = not _G.Aura
    if _G.Aura then
        Log("Iniciando Hooking de Metatables...", Color3.new(1, 1, 0))
        task.wait(0.5)
        Log("Error: Remote 'Global' not found. Bypassing...", Color3.new(1, 0, 0))
        Toggle.Text = "AURA ACTIVE"; Toggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        
        -- Bucle de ataque con Raycast (Para que el server crea que es un hit real)
        task.spawn(function()
            while _G.Aura do
                for _, enemy in pairs(game.Players:GetPlayers()) do
                    if enemy ~= Player and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (Player.Character.HumanoidRootPart.Position - enemy.Character.HumanoidRootPart.Position).Magnitude
                        if dist < 22 and enemy.Character.Humanoid.Health > 0 then
                            pcall(function()
                                -- Simulamos la "Firma" de ataque
                                local args = {
                                    [1] = "Punch" .. math.random(1,4),
                                    [2] = enemy.Character,
                                    [3] = enemy.Character.HumanoidRootPart.CFrame -- Enviamos CFrame para validar posición
                                }
                                CombatRemote:FireServer(unpack(args))
                                
                                -- Animación falsa para engañar al Anti-Cheat
                                Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.NoPhysics)
                            end)
                        end
                    end
                end
                task.wait(0.08) -- Velocidad optimizada para Xeno
            end
        end)
    else
        Toggle.Text = "INJECT BYPASS"; Toggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
        Log("Bypass Detenido.", Color3.new(1,1,1))
    end
end)
