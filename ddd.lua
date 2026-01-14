local p = game.Players.LocalPlayer
local rs = game:GetService("RunService")

_G.HitboxAura = true
local RANGO = 25 -- Tamaño del área de daño

rs.RenderStepped:Connect(function()
    if _G.HitboxAura then
        for _, enemy in pairs(game.Players:GetPlayers()) do
            if enemy ~= p and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = enemy.Character.HumanoidRootPart
                -- Hacemos que la "caja de golpe" del enemigo sea gigante
                -- Así, cuando tú golpeas al aire, el juego cree que lo tocaste
                hrp.Size = Vector3.new(RANGO, RANGO, RANGO)
                hrp.Transparency = 0.7 -- Para que veas el área (puedes ponerlo en 1)
                hrp.CanCollide = false
            end
        end
    end
end)
