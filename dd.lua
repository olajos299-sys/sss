-- JOS HUB V16 (RAYFIELD EDITION)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "JOS HUB | ELTON LEGACY V16",
   LoadingTitle = "Cargando Metodo Elton...",
   LoadingSubtitle = "by JOS",
   ConfigurationSaving = {
      Enabled = false
   },
   KeySystem = false
})

_G.KillAura = false
_G.Rango = 25

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatRemote = ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Melee")

local Tab = Window:CreateTab("Combate", 4483362458)

local Section = Tab:CreateSection("Multi-Target AOE")

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
                    local dist = (myPos - v.Character.HumanoidRootPart.Position).Magnitude
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

Tab:CreateToggle({
   Name = "Activar Kill Aura",
   CurrentValue = false,
   Flag = "KillAuraToggle",
   Callback = function(Value)
      _G.KillAura = Value
      if Value then
         Rayfield:Notify({
            Title = "Aura Activada",
            Content = "Buscando enemigos en el rango...",
            Duration = 3,
            Image = 4483362458,
         })
         EjecutarAura()
      end
   end,
})

Tab:CreateSlider({
   Name = "Radio de Ataque",
   Range = {10, 100},
   Increment = 5,
   Suffix = "Studs",
   CurrentValue = 25,
   Flag = "RangeSlider",
   Callback = function(Value)
      _G.Rango = Value
   end,
})

local ExtraTab = Window:CreateTab("Ajustes", 4483362458)

ExtraTab:CreateButton({
   Name = "Destruir Menu",
   Callback = function()
      Rayfield:Destroy()
   end,
})

print("JOS HUB V16 loaded")
