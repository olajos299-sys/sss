-- JOS HUB V16 (ELTON AOE METHOD - FIX BOTONES)
repeat task.wait() until game:IsLoaded()

local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("JOS HUB | ELTON LEGACY", "DarkTheme")

_G.KillAura = false
_G.Rango = 25

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage:WaitForChild("Combat", 5)
local MeleeRemote = CombatFolder and CombatFolder:WaitForChild("Melee", 5)

local Main = Window:NewTab("Combate")
local Sec = Main:NewSection("Multi-Target Aura")

local function EjecutarAura()
    local lp = game.Players.LocalPlayer
    
    task.spawn(function()
        while _G.KillAura do
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then 
                task.wait(1) 
                continue 
            end

            for _, v in pairs(game.Players:GetPlayers()) do
                if _G.KillAura == false then break end
                
                if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = v.Character.HumanoidRootPart
                    local dist = (lp.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    
                    if dist <= _G.Rango and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                        pcall(function()
                            local attacks = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                            local randomAttack = attacks[math.random(1, #attacks)]
                            
                            if MeleeRemote then
                                MeleeRemote:FireServer(
                                    randomAttack, 
                                    v.Character, 
                                    hrp.CFrame, 
                                    lp.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -1)
                                )
                            end
                        end)
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

Sec:NewToggle("Activar Kill Aura", "Usa Combat.Melee", function(state)
    _G.KillAura = state
    if state then
        EjecutarAura()
    else
        print("Aura Desactivada")
    end
end)

Sec:NewSlider("Radio de Muerte", "Rango de ataque", 50, 10, function(s)
    _G.Rango = s
end)

local Config = Window:NewTab("Config")
local ConfigSec = Config:NewSection("Ajustes del Menu")

ConfigSec:NewKeybind("Ocultar Menu", "Cierra con esta tecla", Enum.KeyCode.RightControl, function()
    Kavo:ToggleUI()
end)

print("JOS HUB Loaded")
