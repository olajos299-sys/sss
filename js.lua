local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("JOS HUB | ULTIMATE BATTLEGROUNDS", "DarkTheme")

-- Configuración
_G.AuraActiva = false
_G.Rango = 20

-- Pestaña Principal
local Tab = Window:NewTab("Principal")
local Section = Tab:NewSection("Combate")

Section:NewToggle("Kill Aura (Silent)", "Activa el modo bypass de Jos Hub", function(state)
    _G.AuraActiva = state
    if state then
        -- El mensaje que indica que el bypass está funcionando
        warn("[JOS HUB]: CombatEvent Not Found - Injecting Bypass...")
        EjecutarAura()
    end
end)

Section:NewSlider("Rango", "Distancia de ataque", 50, 10, function(s)
    _G.Rango = s
end)

-- Lógica de Daño
function EjecutarAura()
    local p = game.Players.LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    
    -- Buscador de Remote dinámico para evitar parches
    local function GetRemote()
        for _, v in pairs(rs:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:find("Hit") or v.Name:find("Combat") or v.Name:find("Attack")) then
                return v
            end
        end
        return nil
    end

    local remote = GetRemote()

    task.spawn(function()
        while _G.AuraActiva do
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                for _, enemy in pairs(game.Players:GetPlayers()) do
                    if enemy ~= p and enemy.Character and enemy.Character:FindFirstChild("Humanoid") then
                        local hrp = enemy.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (char.HumanoidRootPart.Position - hrp.Position).Magnitude < _G.Rango then
                            if enemy.Character.Humanoid.Health > 0 then
                                pcall(function()
                                    -- Secuencia de ataques rápida estilo Elton
                                    local combos = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                    for _, move in pairs(combos) do
                                        if _G.AuraActiva then
                                            remote:FireServer(move, enemy.Character)
                                            task.wait(0.01) -- Delay crítico para el bypass
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

-- Ajustes del Menú
local Config = Window:NewTab("Configuración")
local ConfigSection = Config:NewSection("Interfaz")

ConfigSection:NewKeybind("Abrir/Cerrar Menu", "Teclas para ocultar Jos Hub", Enum.KeyCode.RightControl, function()
	Library:ToggleUI()
end)

ConfigSection:NewLabel("Jos Hub - Versión 1.0")
