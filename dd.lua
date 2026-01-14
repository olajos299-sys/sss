-- JOS HUB PRIVATE (KZ ENGINE)
-- Basado en el cargador que pasaste para Xeno

local function IniciarJosHub()
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
    local Window = Library.CreateLib("JOS HUB | PRIVATE VERSION", "DarkTheme")

    -- Variables de combate (sacadas de la lógica KZ)
    _G.KillAura = false
    _G.AutoEquip = true

    local Main = Window:NewTab("Principal")
    local Section = Main:NewSection("Combate Pro")

    Section:NewToggle("Kill Aura (KZ Bypass)", "Usa el metodo de KZ Hub en Jos Hub", function(state)
        _G.KillAura = state
        if state then
            -- El mensaje que querías ver
            warn("CombatEvent: Not Found. Inyectando Jos Hub Bypass...")
            
            task.spawn(function()
                local player = game.Players.LocalPlayer
                local rs = game:GetService("ReplicatedStorage")
                local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true)

                while _G.KillAura do
                    pcall(function()
                        for _, enemy in pairs(game.Players:GetPlayers()) do
                            if enemy ~= player and enemy.Character and enemy.Character:FindFirstChild("Humanoid") then
                                local dist = (player.Character.HumanoidRootPart.Position - enemy.Character.HumanoidRootPart.Position).Magnitude
                                if dist < 22 and enemy.Character.Humanoid.Health > 0 then
                                    -- Secuencia de ataques de KZ Hub
                                    local combo = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                    for i = 1, #combo do
                                        remote:FireServer(combo[i], enemy.Character)
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.1) -- Delay de seguridad
                end
            end)
        end
    end)

    Section:NewButton("Auto-Equip Fist", "Equipa los puños automáticamente", function()
        local character = game.Players.LocalPlayer.Character
        local backpack = game.Players.LocalPlayer.Backpack
        if backpack:FindFirstChild("Combat") then
            backpack.Combat.Parent = character
        end
    end)

    local Config = Window:NewTab("Config")
    local ConfigS = Config:NewSection("Menu")
    ConfigS:NewKeybind("Ocultar/Abrir", "Usa esta tecla", Enum.KeyCode.RightControl, function()
        Library:ToggleUI()
    end)
end

-- Ejecutamos la funcion con un pcall para evitar que Xeno se cierre
pcall(IniciarJosHub)
