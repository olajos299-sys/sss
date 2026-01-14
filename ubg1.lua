-- Cargando librería con diseño similar al del video
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("ULTIMATE BATTLEGROUNDS | ELTON STYLE", "DarkTheme")

-- Configuración Inicial
_G.KillAura = false
_G.AuraRange = 20

-- Pestaña Principal
local Tab = Window:NewTab("Principal")
local Section = Tab:NewSection("Combate de Pro")

-- Botón de Kill Aura
Section:NewToggle("Kill Aura Bypass", "Ataca automáticamente sin errores de autorización", function(state)
    _G.KillAura = state
    if state then
        EjecutarAura()
    end
end)

-- Slider de Rango
Section:NewSlider("Rango de Daño", "Ajusta la distancia de ataque", 50, 10, function(s)
    _G.AuraRange = s
end)

-- Función de Daño (Bypass mejorado)
function EjecutarAura()
    local p = game.Players.LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true)
    local punchNames = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}

    task.spawn(function()
        while _G.KillAura do
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local target = nil
                local dist = _G.AuraRange
                
                -- Buscar objetivo más cercano
                for _, v in pairs(game.Players:GetPlayers()) do
                    if v ~= p and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                        local d = (char.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                        if d < dist then
                            target = v.Character
                            dist = d
                        end
                    end
                end

                if target then
                    pcall(function()
                        -- Alineación de Hitbox (Evita el error de "Too Far")
                        char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, Vector3.new(target.HumanoidRootPart.Position.X, char.HumanoidRootPart.Position.Y, target.HumanoidRootPart.Position.Z))
                        
                        -- Secuencia de ataques rápida
                        for _, move in pairs(punchNames) do
                            if _G.KillAura then
                                remote:FireServer(move, target)
                                task.wait(0.02) -- Pequeño delay para validación del servidor
                            end
                        end
                    end)
                end
            end
            task.wait(0.1)
        end
    end)
end

-- Pestaña de Ajustes
local Config = Window:NewTab("Ajustes")
local ConfigSection = Config:NewSection("Teclas")

ConfigSection:NewKeybind("Abrir/Cerrar Menú", "Presiona para ocultar el menú", Enum.KeyCode.RightControl, function()
	Library:ToggleUI()
end)

Section:NewLabel("Usa RightControl para ocultar")
