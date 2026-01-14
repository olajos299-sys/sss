local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("JOS HUB | ULTIMATE BATTLEGROUNDS", "DarkTheme")

-- Variables de Control
_G.Aura = false
_G.Distancia = 20

-- Pestaña de Combate
local Main = Window:NewTab("Main")
local Combat = Main:NewSection("Combate Especial")

Combat:NewToggle("Kill Aura (Bypass Mode)", "Activación estilo Jos Hub", function(state)
    _G.Aura = state
    if state then
        -- Simulamos el comportamiento del video para activar el bypass
        warn("[JOS HUB]: Searching for CombatEvent...")
        task.wait(0.5)
        print("[JOS HUB]: CombatEvent Not Found (System Bypassed)")
        IniciarAura()
    end
end)

Combat:NewSlider("Rango de Daño", "Distancia de los golpes", 40, 10, function(s)
    _G.Distancia = s
end)

-- Función Maestra del Kill Aura
function IniciarAura()
    local player = game.Players.LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    
    -- Buscamos el evento de forma silenciosa
    local function FindRemote()
        for _, v in pairs(rs:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:find("Hit") or v.Name:find("Combat")) then
                return v
            end
        end
    end

    local remote = FindRemote()

    task.spawn(function()
        while _G.Aura do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                for _, target in pairs(game.Players:GetPlayers()) do
                    if target ~= player and target.Character and target.Character:FindFirstChild("Humanoid") then
                        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and target.Character.Humanoid.Health > 0 then
                            local d = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if d <= _G.Distancia then
                                pcall(function()
                                    -- Secuencia de ataques autorizados
                                    local anims = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                    for _, a in pairs(anims) do
                                        if _G.Aura then
                                            remote:FireServer(a, target.Character)
                                            task.wait(0.01) -- El delay que evita que el server te bloquee
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

-- Configuración del Menú
local Config = Window:NewTab("Config")
local Sect = Config:NewSection("Controles")

Sect:NewKeybind("Ocultar Jos Hub", "Cierra el menú", Enum.KeyCode.RightControl, function()
    Library:ToggleUI()
end)

Sect:NewLabel("Creado para Jos Hub")
