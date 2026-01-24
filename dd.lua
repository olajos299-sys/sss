local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "JOS HUB | ELTON LEGACY V16",
   LoadingTitle = "Cargando Metodo Elton...",
   LoadingSubtitle = "by JOS",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- Variables Globales
_G.KillAura = false
_G.Rango = 25
_G.AttackSpeed = 0.1 -- Tiempo entre ráfagas de golpes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

-- Referencia al Remote (Asegúrate de que esta ruta sea correcta según el juego)
-- Según tu imagen, existe 'ReplicatedStorage.Combat.Melee' o similar.
local CombatRemote = ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Melee")

local Tab = Window:CreateTab("Combate", 4483362458)
local Section = Tab:CreateSection("Multi-Target AOE")

function EjecutarAura()
    task.spawn(function()
        while _G.KillAura do
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then 
                task.wait(1) 
                continue 
            end

            local myPos = lp.Character.HumanoidRootPart.Position
            
            -- Buscamos objetivos
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    local targetRoot = v.Character.HumanoidRootPart
                    local targetHum = v.Character:FindFirstChild("Humanoid")
                    local dist = (myPos - targetRoot.Position).Magnitude

                    if dist <= _G.Rango and targetHum and targetHum.Health > 0 then
                        -- Lista de ataques que el servidor reconoce
                        local attacks = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                        local randomAttack = attacks[math.random(1, #attacks)]
                        
                        -- Ejecución del ataque vía Remote
                        pcall(function()
                            CombatRemote:FireServer(
                                randomAttack, 
                                v.Character, 
                                targetRoot.CFrame, 
                                lp.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -1)
                            )
                        end)
                    end
                end
            end
            task.wait(_G.AttackSpeed) -- Control de velocidad para evitar Kick por spam
        end
    end)
end

-- Interfaz de Usuario
Tab:CreateToggle({
   Name = "Activar Kill Aura",
   CurrentValue = false,
   Flag = "KillAuraToggle",
   Callback = function(Value)
      _G.KillAura = Value
      if Value then
         Rayfield:Notify({
            Title = "Aura Activada",
            Content = "Buscando enemigos...",
            Duration = 2,
            Image = 4483362458,
         })
         EjecutarAura()
      end
   end,
})

Tab:CreateSlider({
   Name = "Radio de Ataque",
   Range = {10, 100},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = 25,
   Flag = "RangeSlider",
   Callback = function(Value)
      _G.Rango = Value
   end,
})

-- Botón extra para limpiar el menú
local ExtraTab = Window:CreateTab("Ajustes", 4483362458)
ExtraTab:CreateButton({
   Name = "Destruir Menu",
   Callback = function()
      Rayfield:Destroy()
   end,
})
