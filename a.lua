local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("JOS HUB | PRIVATE VERSION", "DarkTheme")

-- Ajustes del Bypass
_G.AuraActiva = false
_G.Distancia = 22

local Tab = Window:NewTab("Combate")
local Section = Tab:NewSection("Aura Mode")

Section:NewToggle("Kill Aura (Bypass v2)", "Activa el modo silencio de Jos Hub", function(state)
    _G.AuraActiva = state
    if state then
        -- Simulamos el proceso que viste en el video
        warn("[JOS HUB]: Searching for combat address...")
        task.wait(0.7)
        print("Error: RemoteEvent 'CombatData' not found. Re-routing...") -- El mensaje clave
        ActivarJosAura()
    end
end)

Section:NewSlider("Distancia", "Rango de ataque", 45, 10, function(s)
    _G.Distancia = s
end)

function ActivarJosAura()
    local p = game.Players.LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    
    -- Buscador de Remote sin usar nombres específicos para evitar el parche
    local function GetEvent()
        for _, x in pairs(rs:GetDescendants()) do
            if x:IsA("RemoteEvent") and (x.Name:lower():find("hit") or x.Name:lower():find("combat")) then
                return x
            end
        end
    end

    local Evento = GetEvent()

    task.spawn(function()
        while _G.AuraActiva do
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local targets = game.Players:GetPlayers()
                for i = 1, #targets do
                    local v = targets[i]
                    if v ~= p and v.Character and v.Character:FindFirstChild("Humanoid") then
                        local root = v.Character:FindFirstChild("HumanoidRootPart")
                        if root and v.Character.Humanoid.Health > 0 then
                            local d = (char.HumanoidRootPart.Position - root.Position).Magnitude
                            if d <= _G.Distancia then
                                pcall(function()
                                    -- Secuencia de ataques rápida
                                    local m = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                    for j = 1, #m do
                                        if _G.AuraActiva then
                                            Evento:FireServer(m[j], v.Character)
                                            task.wait(0.01) -- Delay para saltar la protección
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(0.12)
        end
    end)
end

local Config = Window:NewTab("Ajustes")
Config:NewSection("Controles"):NewKeybind("Cerrar Menu", "RightCtrl", Enum.KeyCode.RightControl, function()
    Library:ToggleUI()
end)

print("[JOS HUB] Loaded successfully.")
