-- JOS HUB V16 (ELTON AOE METHOD)
-- No necesitas mirar a los enemigos. Solo corre cerca de ellos.

local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("JOS HUB | ELTON LEGACY", "DarkTheme")

_G.KillAura = false
_G.Rango = 25

local Main = Window:NewTab("Combate")
local Sec = Main:NewSection("Multi-Target Aura")

Sec:NewToggle("Activar AOE Kill Aura", "Mata a todos alrededor sin mirar", function(state)
    _G.KillAura = state
    if state then
        print("CombatEvent: Not Found. Iniciando ráfaga AOE...")
        EjecutarAuraElton()
    end
end)

Sec:NewSlider("Radio de Muerte", "Rango de proximidad", 35, 10, function(s)
    _G.Rango = s
end)

function EjecutarAuraElton()
    local lp = game.Players.LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true)

    task.spawn(function()
        while _G.KillAura do
            local targets = {}
            
            -- 1. BUSCAR A TODOS LOS ENEMIGOS EN RANGO SIMULTÁNEAMENTE
            for _, v in pairs(game.Players:GetPlayers()) do
                if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (lp.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= _G.Rango and v.Character.Humanoid.Health > 0 then
                        table.insert(targets, v.Character)
                    end
                end
            end

            -- 2. DISPARAR RÁFAGA A TODOS (Sin wait interno para que sea instantáneo)
            for _, char in pairs(targets) do
                pcall(function()
                    -- Firma de Elton: Punch aleatorio + PunchDash para romper defensa
                    local attacks = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                    local randomAttack = attacks[math.random(1, #attacks)]
                    
                    -- Enviamos el daño con la posición relativa (Bypass de validación física)
                    remote:FireServer(
                        randomAttack, 
                        char, 
                        char.HumanoidRootPart.CFrame, 
                        lp.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -1)
                    )
                end)
            end

            -- 3. VELOCIDAD DE REFRESCO (Igual al video de Elton)
            task.wait(0.08) 
        end
    end)
end

-- CONFIGURACIÓN DE XENO
local Config = Window:NewTab("Config")
Config:NewSection("Menu"):NewKeybind("Ocultar", "RightControl", Enum.KeyCode.RightControl, function()
    Kavo:ToggleUI()
end)
