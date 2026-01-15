-- JOS HUB V16 FIXED
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jannidv/Orion-UI-Library/main/source.lua'))()

local Window = OrionLib:MakeWindow({
    Name = "JOS HUB | ELTON LEGACY V16", 
    HidePremium = false, 
    SaveConfig = false, 
    IntroText = "JOS HUB V16",
    IntroIcon = "rbxassetid://4483345998"
})

_G.KillAura = false
_G.Rango = 25

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage:WaitForChild("Combat", 5)
local MeleeRemote = CombatFolder and CombatFolder:WaitForChild("Melee", 5)

function EjecutarAura()
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
                    if MeleeRemote then
                        MeleeRemote:FireServer(
                            attacks[math.random(1, #attacks)], 
                            char, 
                            char.HumanoidRootPart.CFrame, 
                            lp.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -1)
                        )
                    end
                end)
            end
            task.wait(0.1)
        end
    end)
end

local MainTab = Window:MakeTab({
    Name = "Combate",
    Icon = "rbxassetid://4483345998"
})

MainTab:AddToggle({
    Name = "Activar Elton Aura",
    Default = false,
    Callback = function(Value)
        _G.KillAura = Value
        if Value then
            EjecutarAura()
        end
    end    
})

MainTab:AddSlider({
    Name = "Rango",
    Min = 10,
    Max = 100,
    Default = 25,
    Increment = 1,
    Callback = function(Value)
        _G.Rango = Value
    end    
})

OrionLib:Init()
