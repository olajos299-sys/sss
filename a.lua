-- JOS HUB V16 (ORION EDITION)
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

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
local CombatRemote = ReplicatedStorage:WaitForChild("Combat", 5):WaitForChild("Melee", 5)

function EjecutarAura()
    local lp = game.Players.LocalPlayer
    
    task.spawn(function()
        while _G.KillAura do
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then 
                task.wait(1) 
                continue 
            end

            local targets = {}
            local myPos = lp.Character.HumanoidRootPart.Position

            for _, v in pairs(game.Players:GetPlayers()) do
                if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHRP = v.Character.HumanoidRootPart
                    local dist = (myPos - targetHRP.Position).Magnitude
                    
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

local MainTab = Window:MakeTab({
    Name = "Combate",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddSection({
    Name = "Multi-Target Kill Aura"
})

MainTab:AddToggle({
    Name = "Activar Elton Aura",
    Default = false,
    Callback = function(Value)
        _G.KillAura = Value
        if Value then
            OrionLib:MakeNotification({
                Name = "JOS HUB",
                Content = "Aura activada. Atacando enemigos...",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
            EjecutarAura()
        end
    end    
})

MainTab:AddSlider({
    Name = "Rango de Muerte",
    Min = 10,
    Max = 100,
    Default = 25,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Studs",
    Callback = function(Value)
        _G.Rango = Value
    end    
})

local ConfigTab = Window:MakeTab({
    Name = "Configuracion",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ConfigTab:AddButton({
    Name = "Cerrar Script",
    Callback = function()
        OrionLib:Destroy()
      end    
})

OrionLib:Init()
