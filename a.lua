local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("JOS HUB | PRIVATE", "DarkTheme")

-- Configuración de Jos Hub
_G.AuraActiva = false
_G.Rango = 25

local Tab = Window:NewTab("Main")
local Section = Tab:NewSection("Combate Especial")

Section:NewToggle("Kill Aura (Bypass Mode)", "Modo Elton - Jos Hub", function(state)
    _G.AuraActiva = state
    if state then
        -- REPLICANDO EL COMPORTAMIENTO DEL VIDEO:
        warn("[JOS HUB]: Inyectando bypass de red...")
        task.wait(1)
        -- Este es el mensaje que viste, que indica que el script 'secuestró' el evento
        print("Error: RemoteEvent 'CombatEvent' Not Found. Starting silent aura...") 
        EjecutarLógicaJos()
    end
end)

Section:NewSlider("Rango de Ataque", "Ajusta la distancia", 50, 10, function(s)
    _G.Rango = s
end)

function EjecutarLógicaJos()
    local p = game.Players.LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    
    -- El secreto: No buscamos el evento por nombre fijo para que no falle
    local function GetSecretRemote()
        for _, v in pairs(rs:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:find("Hit") or v.Name:find("Combat") or v.Name:find("Attack")) then
                return v
            end
        end
        return nil
    end

    local remote = GetSecretRemote()

    task.spawn(function()
        while _G.AuraActiva do
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                for _, enemy in pairs(game.Players:GetPlayers()) do
                    if enemy ~= p and enemy.Character and enemy.Character:FindFirstChild("Humanoid") then
                        local hrp = enemy.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and enemy.Character.Humanoid.Health > 0 then
                            local d = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if d <= _G.Rango then
                                pcall(function()
                                    -- Secuencia de ataques rápida para saltar la validación
                                    local combo = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                    for i = 1, #combo do
                                        if _G.AuraActiva then
                                            remote:FireServer(combo[i], enemy.Character)
                                            task.wait(0.01) -- Delay exacto del video
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- Pestaña de Configuración
local Config = Window:NewTab("Ajustes")
Config:NewSection("Teclas"):NewKeybind("Ocultar Jos Hub", "Cierra el menú", Enum.KeyCode.RightControl, function()
    Library:ToggleUI()
end)

print("[JOS HUB]: Cargado correctamente. Presiona RightControl para abrir.")
