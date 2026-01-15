-- JOS HUB V16 (ELTON AOE METHOD - FIXED ROUTE)
local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("JOS HUB | ELTON LEGACY", "DarkTheme")

_G.KillAura = false
_G.Rango = 25

-- DEFINICIÓN DEL EVENTO (Según lo que encontraste en Dex)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatRemote = ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Melee")

local Main = Window:NewTab("Combate")
local Sec = Main:NewSection("Multi-Target Aura")

function EjecutarAuraElton()
    local lp = game.Players.LocalPlayer
    
    task.spawn(function()
        while _G.KillAura do
            -- Verificamos que nuestro personaje exista antes de seguir
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then 
                task.wait(0.5) 
                continue 
            end

            local targets = {}
            local myPos = lp.Character.HumanoidRootPart.Position
            
            -- 1. BUSCAR OBJETIVOS (Jugadores)
            for _, v in pairs(game.Players:GetPlayers()) do
                if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHRP = v.Character.HumanoidRootPart
                    local dist = (myPos - targetHRP.Position).Magnitude
                    
                    if dist <= _G.Rango and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                        table.insert(targets, v.Character)
                    end
                end
            end

            -- 2. DISPARAR RÁFAGA AOE
            for _, char in pairs(targets) do
                if not _G.KillAura then break end
                
                pcall(function()
                    local attacks = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                    local randomAttack = attacks[math.random(1, #attacks)]
                    
                    -- Usamos la ruta que encontraste en Dex
                    CombatRemote:FireServer(
                        randomAttack, 
                        char, 
                        char.HumanoidRootPart.CFrame, 
                        lp.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -1)
                    )
                end)
            end

            task.wait(0.1) -- Velocidad de ataque (0.1 = 10 veces por segundo)
        end
    end)
end

Sec:NewToggle("Activar AOE Kill Aura", "Usa el Remote: Combat.Melee", function(state)
    _G.KillAura = state
    if state then
        EjecutarAuraElton()
    end
end)

Sec:NewSlider("Radio de Muerte", "Rango de proximidad", 50, 10, function(s)
    _G.Rango = s
end)

-- CONFIGURACIÓN DE INTERFAZ
local Config = Window:NewTab("Config")
Config:NewSection("Menu"):NewKeybind("Ocultar Menu", "RightControl", Enum.KeyCode.RightControl, function()
    Kavo:ToggleUI()
end)
