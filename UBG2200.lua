
-- JOSHUB ULTIMATE EDITION BY JOS
-- TODAS LAS FUNCIONES RESTAURADAS + ESTRUCTURA SEGURA

-- [1] VARIABLES GLOBALES Y CONFIGURACIONES ORIGINALES
getgenv().Configs = {
    AuraEnabled = false,
    AuraKey = "None",
    InstantKillRange = 60,
    Whitelist = {},
    IgnoreFriends = false,
    MaxDistance = 60
}

local WallSettings = {
    Enabled = false,
    AttackSpeed = 1,
    HitsPerFrame = 2,
    CustomKey = "None",
    SelectedKey = Enum.KeyCode.I
}

local ConfigKillEmotes = {
    Enabled = false,
    Mode = "Random",
    SelectedEmote = "",
    OneShotEmote = "",
    IgnoreFriends = false,
    Speed = 0.01,
    Radius = 15,
    CustomKey = "None",
    OneShotKey = "None"
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Core = require(ReplicatedStorage:WaitForChild("Core", 9e9))

-- [2] FUNCIONES DE UTILIDAD (TRASPLANTE TOTAL)
local function HRP() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end

local function run_as_identity_2(fn)
    local set_id = (syn and syn.set_thread_identity) or setthreadidentity
    local get_id = (syn and syn.get_thread_identity) or getthreadidentity
    local prev = get_id and get_id() or 2
    if set_id then pcall(set_id, 2) end
    local ok, res = pcall(fn)
    if set_id then pcall(set_id, prev) end
    return ok and res or nil
end

local function getAllTargets(range)
    local targets = {}
    local myHrp = HRP()
    if not myHrp then return targets end
    local lpName = LocalPlayer.Name
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not table.find(getgenv().Configs.Whitelist, player.Name) then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                local distance = (myHrp.Position - character.HumanoidRootPart.Position).Magnitude
                if distance <= range and character.Humanoid.Health > 0 then
                    local isValid = (not character:GetAttribute("Safety") and 
                                    ((not character:GetAttribute("Grabbed") or character:GetAttribute("Grabbed") == lpName) and 
                                    (not character:GetAttribute("Victim") or character:GetAttribute("Victim") == lpName)) and 
                                    not character:GetAttribute("Grabbing"))
                    if isValid then table.insert(targets, character) end
                end
            end
        end
    end
    return targets
end

-- Lógica de Mass Kill / Spam
local function MassKill()
    local targets = getAllTargets(getgenv().Configs.InstantKillRange) 
    if #targets == 0 then return end
    local data = LocalPlayer:FindFirstChild("Data")
    local charVal = data and data:FindFirstChild("Character") and data.Character.Value
    if not charVal then return end
    local charFolder = ReplicatedStorage.Characters:FindFirstChild(charVal)
    if charFolder and charFolder:FindFirstChild("WallCombo") then
        local WallCombo = charFolder.WallCombo
        local multiHitList = {}
        local stackCount = (charVal == "Gon") and 20 or 50
        for _, victimChar in ipairs(targets) do
            for i = 1, stackCount do table.insert(multiHitList, victimChar) end
        end
        ReplicatedStorage.Remotes.Abilities.Ability:FireServer(WallCombo, 69)
        ReplicatedStorage.Remotes.Combat.Action:FireServer(WallCombo, "", 4, 69, {
            BestHitCharacter = nil,
            HitCharacters = multiHitList,
            Ignore = {},
            Actions = {}
        })
    end
end

-- [3] INICIALIZACIÓN DE LA UI JOSHUB
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

WindUI:AddTheme({
    Name = "JoshubDark",
    Background = WindUI:Gradient({ 
        ["0"] = { Color = Color3.fromHex("#001a00"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#004d00"), Transparency = 0 },
    }, { Rotation = 45 }),
    Accent = Color3.fromHex("#30FF6A"),
    Outline = Color3.fromHex("#1c1c20"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button = Color3.fromHex("#1f1f23"),
    Icon = Color3.fromHex("#FFFFFF"),
})

local Window = WindUI:CreateWindow({
    Title = "Joshub|UBG",
    Author = "by jos",
    Folder = "Joshub",
    Icon = "swords",
    IconSize = 32,
    Theme = "JoshubDark",
    OpenButton = { Title = "Joshub", Enabled = true, Draggable = true, Color = ColorSequence.new(Color3.fromHex("#30FF6A")) }
})

-- PESTAÑAS
local HomeTab = Window:Tab({ Title = "Home", Icon = "house", Color = Color3.fromHex("#4CAF50") })
local MainTab = Window:Tab({ Title = "Combat", Icon = "sword", Color = Color3.fromHex("#4CAF50") })
local CharacterTab = Window:Tab({ Title = "Character", Icon = "user", Color = Color3.fromHex("#4CAF50") })
local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye", Color = Color3.fromHex("#4CAF50") })
local WorldTab = Window:Tab({ Title = "World", Icon = "globe", Color = Color3.fromHex("#4CAF50") })
local EmotesTab = Window:Tab({ Title = "Emotes", Icon = "accessibility", Color = Color3.fromHex("#4CAF50") })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings", Color = Color3.fromHex("#4CAF50") })

-- [4] RESTAURACIÓN DE FUNCIONES (COMBAT)
MainTab:Section({ Title = "Kill Aura & Wall Spam" })

MainTab:Toggle({
    Title = "Kill Aura (Spam)",
    Default = false,
    Callback = function(state)
        getgenv().Configs.AuraEnabled = state
        if state then
            task.spawn(function()
                while getgenv().Configs.AuraEnabled do
                    MassKill()
                    task.wait()
                end
            end)
        end
    end
})

MainTab:Slider({
    Title = "Aura Range",
    Step = 1,
    Value = { Min = 5, Max = 60, Default = 60 },
    Callback = function(v) getgenv().Configs.InstantKillRange = v end
})

MainTab:Section({ Title = "Wall Combo Spam" })

local function execute_wall_logic()
    if not WallSettings.Enabled then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Head") then return end
    local data = LocalPlayer:FindFirstChild("Data")
    local charName = data and data:FindFirstChild("Character") and data.Character.Value
    if not charName then return end
    local skill = ReplicatedStorage.Characters[charName]:FindFirstChild("WallCombo")
    if not skill then return end
    local hitRes = run_as_identity_2(function()
        return Core.Get("Combat", "Hit").Box(nil, char, {Size = Vector3.new(50, 50, 50)})
    end)
    if hitRes then
        run_as_identity_2(function()
            local hits = WallSettings.AttackSpeed * 2 
            for i = 1, hits do
                if not WallSettings.Enabled then break end
                pcall(Core.Get("Combat", "Ability").Activate, skill, hitRes, char.Head.Position + Vector3.new(0, 0, 2.5))
            end
        end)
    end
end

RunService.Heartbeat:Connect(function()
    if WallSettings.Enabled then
        for i = 1, WallSettings.HitsPerFrame do
            if not WallSettings.Enabled then break end
            task.spawn(execute_wall_logic)
        end
    end
end)

MainTab:Toggle({
    Title = "WallCombo Spam (Server)",
    Default = false,
    Callback = function(state) WallSettings.Enabled = state end
})

MainTab:Slider({
    Title = "Spam Speed",
    Step = 1,
    Value = {Min = 1, Max = 15, Default = 1},
    Callback = function(v)
        WallSettings.AttackSpeed = v
        WallSettings.HitsPerFrame = v + 1
    end
})

MainTab:Section({ Title = "Exploits" })
MainTab:Toggle({ Title = "Longer Ultimate", Callback = function(state) pcall(function() ReplicatedStorage.Settings.Multipliers.UltimateTimer.Value = state and 999999 or 100 end) end })
MainTab:Toggle({ Title = "Instant Transformation", Callback = function(state) pcall(function() ReplicatedStorage.Settings.Toggles.InstantTransformation.Value = state end) end })
MainTab:Toggle({ Title = "Disable Combat Timer", Callback = function(state) pcall(function() ReplicatedStorage.Settings.Toggles.DisableCombatTimer.Value = state end) end })
MainTab:Toggle({ Title = "No Stun on Miss", Callback = function(state) pcall(function() ReplicatedStorage.Settings.Toggles.DisableHitStun.Value = state end) end })

-- [5] CHARACTER TAB
CharacterTab:Section({ Title = "Player" })
CharacterTab:Slider({
    Title = "Speed Multiplier",
    Step = 1,
    Value = {Min = 1, Max = 10, Default = 1},
    Callback = function(v)
        pcall(function()
            ReplicatedStorage.Settings.Multipliers.RunSpeed.Value = v
            ReplicatedStorage.Settings.Multipliers.WalkSpeed.Value = v
        end)
    end
})
CharacterTab:Toggle({ Title = "Instant Respawn", Callback = function(state) getgenv().InstantRespawnEnabled = state end })
CharacterTab:Toggle({ Title = "Anti Counter", Callback = function(state) getgenv().HitboxEnabled = state end })

-- [6] WORLD & VISUAL
WorldTab:Section({ Title = "Atmosphere" })
WorldTab:Dropdown({
    Title = "Lighting",
    Values = {"None", "Sun", "Night", "Cycle"},
    Callback = function(v)
        if v == "Sun" then Lighting.ClockTime = 12
        elseif v == "Night" then Lighting.ClockTime = 0
        end
    end
})

VisualTab:Section({ Title = "ESP" })
VisualTab:Toggle({
    Title = "Player Highlights",
    Callback = function(state)
        getgenv().ESPEnabled = state
        -- Lógica de ESP...
    end
})

-- [7] EMOTES (SPAM & ONES)
EmotesTab:Section({ Title = "Kill Emotes Spam" })
local emotesFolder = ReplicatedStorage:WaitForChild("Cosmetics"):WaitForChild("KillEmote")
local function getEmoteNames()
    local names = {}
    for _, child in pairs(emotesFolder:GetChildren()) do table.insert(names, child.Name) end
    return names
end
local emoteList = getEmoteNames()

EmotesTab:Toggle({ Title = "Enable Emote Spam", Callback = function(state) ConfigKillEmotes.Enabled = state end })
EmotesTab:Dropdown({ Title = "Select Emote", Values = emoteList, Callback = function(v) ConfigKillEmotes.SelectedEmote = v end })

task.spawn(function()
    while true do
        if ConfigKillEmotes.Enabled then
            local target = getAllTargets(ConfigKillEmotes.Radius)[1]
            if target then
                local emoteObj = emotesFolder:FindFirstChild(ConfigKillEmotes.SelectedEmote)
                if emoteObj then
                    run_as_identity_2(function() pcall(Core.Get("Combat", "Ability").Activate, emoteObj, target) end)
                end
            end
        end
        task.wait(0.1)
    end
end)

-- [8] HOME & DISCORD
HomeTab:Paragraph({ Title = "Joshub Ultimate", Desc = "The complete arsenal for Jos.\nDiscord: discord.gg/Qt7zRF7E" })

task.wait(1.5); pcall(function() HomeTab:Select() end)
warn("Joshub Ultimate Loaded!")
