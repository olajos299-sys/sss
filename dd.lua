-- JOS HUB V16 (ELTON AOE METHOD - RUTA FIJA)
local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("JOS HUB | ELTON LEGACY", "DarkTheme")

_G.KillAura = false
_G.Rango = 25

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatRemote = ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Melee")

local Main = Window:NewTab("Combate")
local Sec = Main:NewSection("Multi-Target Aura")

function EjecutarAuraElton()
    local lp = game.Players.LocalPlayer
    
    task.spawn(function()
        while _G.KillAura do
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then 
                task.wait(1) 
                continue 
            end

            local targets = {}

            for _, v in pairs(game.Players:GetPlayers()) do
                if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (lp.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= _G.Rango and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                        table.insert(targets, v.Character)
                    end
                end
            end

            for _, char in pairs(targets) do
                if not _G.KillAura then break end
                pcall(function()
                    local attacks = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                    local randomAttack = attacks[math.random(1, #attacks)]
                    
                    CombatRemote:FireServer(
                        randomAttack, 
                        char, 
                        char.HumanoidRootPart.CFrame, 
                        lp.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -1)
                    )
                end)
            end

            task.wait(0.1) 
        end
    end)
end

Sec:NewToggle("Activar AOE Kill Aura", "Mata a todos en Combat.Melee", function(state)
    _G.KillAura = state
    if state then
        EjecutarAuraElton()
    end
end)

Sec:NewSlider("Radio de Muerte", "Rango de proximidad", 35, 10, function(s)
    _G.Rango = s
end)

local Config = Window:NewTab("Config")
local ConfigSec = Config:NewSection("Menu")

ConfigSec:NewKeybind("Ocultar con Tecla", "Cierra el menu", Enum.KeyCode.RightControl, function()
    Kavo:ToggleUI()
end)

print("JOS HUB V16 Cargado con éxito.")
