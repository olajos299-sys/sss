
-- JOSHUB ULTIMATE EDITION BY JOS (ENHANCED V3)
-- BASE: NEXOR | WALLCOMBO | + NUEVAS FUNCIONES

-- =====================================================
-- [1] VARIABLES GLOBALES
-- =====================================================
getgenv().Configs = {
    AuraEnabled = false,
    AuraKey = "None",
    InstantKillRange = 60,
    Whitelist = {},
    IgnoreFriends = false,
    MaxDistance = 60,
    GodMode = false,
    TargetEnabled = false,
    CurrentTarget = nil,
    SpeedValue = 16,
    KickMode = false
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

-- Configs nuevas (message8)
local KillAuraConfig = {
    KillAuraEnabled = false,
    KillAuraRangeEnabled = false,
    KillAuraDistance = 100,
    KillAuraDamage = 9000000000,
    IgnoreFriends = false,
    KillAuraLoop = nil,
    KillAuraOnHit = false,
    KillAuraHitMultiplier = 1
}

local RemoteCache = {
    CharactersFolder = nil,
    RemotesFolder = nil,
    AbilitiesRemote = nil,
    CombatRemote = nil,
    DashRemote = nil
}

local WallComboConfig = {
    WallComboEnabled = false,
    WallComboMethod = "Method 1",
    coreModule = nil,
    renderConnectionName = "WallComboV2",
    WallComboActionIDCounter = 0,
    WallComboIgnoreFriends = false
}

local HitboxSettings = {
    hitSize = 15,
    hitboxActive = false,
    hitLib = nil,
    oldBox = nil,
    pendingEnable = false
}

local GodModeNPC = false
local GodModeRanked = false
local LagServerEnabled = false
local AutoResetEnabled = false
local RespawnAtDeathEnabled = false
local deathPosition = nil

-- =====================================================
-- [2] SERVICIOS
-- =====================================================
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local LocalPlayer       = Players.LocalPlayer
local hb                = RunService.Heartbeat
local Core              = require(ReplicatedStorage:WaitForChild("Core", 9000000000))

local Folders = {
    Toggles     = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Toggles"),
    Multipliers = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Multipliers"),
    Cooldowns   = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Cooldowns")
}

-- =====================================================
-- [3] FUNCIONES DE UTILIDAD
-- =====================================================
local function HRP()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function run_as_identity_2(fn)
    local set_id = (syn and syn.set_thread_identity) or setthreadidentity
    local get_id = (syn and syn.get_thread_identity) or getthreadidentity
    local prev = get_id and get_id() or 2
    if set_id then pcall(set_id, 2) end
    local ok, res = pcall(fn)
    if set_id then pcall(set_id, prev) end
    return ok and res or nil
end

local function Setidentity()
    pcall(function()
        setthreadidentity(5)
        setthreadcontext(5)
    end)
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

-- =====================================================
-- [4] INICIALIZAR REMOTE CACHE (message8)
-- =====================================================
local function InitializeRemoteCache()
    task.spawn(function()
        RemoteCache.CharactersFolder = ReplicatedStorage:WaitForChild("Characters")
        RemoteCache.RemotesFolder    = ReplicatedStorage:WaitForChild("Remotes")
        RemoteCache.AbilitiesRemote  = RemoteCache.RemotesFolder:WaitForChild("Abilities"):WaitForChild("Ability")
        RemoteCache.CombatRemote     = RemoteCache.RemotesFolder:WaitForChild("Combat"):WaitForChild("Action")
        RemoteCache.DashRemote       = RemoteCache.RemotesFolder:WaitForChild("Character"):WaitForChild("Dash")
    end)
end
InitializeRemoteCache()

-- =====================================================
-- [5] KICK MODE (nexor)
-- =====================================================
local function KickPlayer(targetChar)
    if not targetChar then return end
    pcall(function()
        local data    = LocalPlayer:FindFirstChild("Data")
        local charVal = data and data:FindFirstChild("Character") and data.Character.Value
        if not charVal then return end
        local charFolder = ReplicatedStorage.Characters:FindFirstChild(charVal)
        local remote     = ReplicatedStorage.Remotes.Combat.Action
        for i = 1, 10 do
            remote:FireServer(charFolder:FindFirstChildOfClass("Folder"), "Kick", 100, 69, {
                HitCharacters = {targetChar},
                Actions = {"Kick"}
            })
        end
    end)
end

-- =====================================================
-- [6] GOD MODE SAFETY (nexor)
-- =====================================================
RunService.Stepped:Connect(function()
    if getgenv().Configs.GodMode then
        pcall(function()
            if LocalPlayer.Character then
                LocalPlayer.Character:SetAttribute("Safety", true)
            end
        end)
    else
        pcall(function()
            if LocalPlayer.Character then
                LocalPlayer.Character:SetAttribute("Safety", false)
            end
        end)
    end
end)

-- =====================================================
-- [7] SPEED (nexor)
-- =====================================================
RunService.Heartbeat:Connect(function()
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = getgenv().Configs.SpeedValue
        end
    end)
end)

-- =====================================================
-- [8] MASS KILL (nexor)
-- =====================================================
local function MassKill()
    local targets = {}
    if getgenv().Configs.TargetEnabled and getgenv().Configs.CurrentTarget then
        local tChar = getgenv().Configs.CurrentTarget.Character
        if tChar and tChar:FindFirstChild("HumanoidRootPart") and tChar.Humanoid.Health > 0 then
            table.insert(targets, tChar)
        end
    else
        targets = getAllTargets(getgenv().Configs.InstantKillRange)
    end
    if #targets == 0 then return end
    if getgenv().Configs.KickMode then
        for _, t in ipairs(targets) do KickPlayer(t) end
    end
    local data    = LocalPlayer:FindFirstChild("Data")
    local charVal = data and data:FindFirstChild("Character") and data.Character.Value
    if not charVal then return end
    local charFolder = ReplicatedStorage.Characters:FindFirstChild(charVal)
    if charFolder and charFolder:FindFirstChild("WallCombo") then
        local WallCombo    = charFolder.WallCombo
        local multiHitList = {}
        local stackCount   = (charVal == "Gon") and 20 or 50
        for _, victimChar in ipairs(targets) do
            for i = 1, stackCount do table.insert(multiHitList, victimChar) end
        end
        ReplicatedStorage.Remotes.Abilities.Ability:FireServer(WallCombo, 69)
        ReplicatedStorage.Remotes.Combat.Action:FireServer(WallCombo, "", 4, 69, {
            BestHitCharacter = nil,
            HitCharacters    = multiHitList,
            Ignore           = {},
            Actions          = {}
        })
    end
end

-- =====================================================
-- [9] KILL AURA MEJORADO (message8)
-- =====================================================
local function startKillAuraRange()
    if KillAuraConfig.KillAuraLoop then return end
    KillAuraConfig.KillAuraLoop = task.spawn(function()
        while KillAuraConfig.KillAuraRangeEnabled do
            if RemoteCache.DashRemote then
                local args = {
                    CFrame.new(741.36, 4.53, -157.57, 0.18, 1.2e-07, 0.98, -6.7e-09, 1, -1.2e-07, -0.98, 1.5e-08, 0.18),
                    "R",
                    Vector3.new(-0.81, 0, -0.59),
                    [5] = 1767116512.29,
                    [6] = false
                }
                RemoteCache.DashRemote:FireServer(unpack(args))
            end
            task.wait(0.2)
        end
        KillAuraConfig.KillAuraLoop = nil
    end)
end

local function stopKillAuraRange()
    KillAuraConfig.KillAuraRangeEnabled = false
    if KillAuraConfig.KillAuraLoop then
        task.cancel(KillAuraConfig.KillAuraLoop)
        KillAuraConfig.KillAuraLoop = nil
    end
end

local function ExecuteKillAuraMul(targetCharacter)
    if not targetCharacter then return end
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local humanoid       = targetCharacter:FindFirstChildOfClass("Humanoid")
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not humanoid or not targetRootPart then return end
    local health = humanoid:GetAttribute("Health") or humanoid.Health
    if health <= 0 then return end
    local currentCharacterName = LocalPlayer.Data.Character.Value
    if not currentCharacterName or not RemoteCache.CharactersFolder then return end
    local CharacterFolder  = RemoteCache.CharactersFolder:FindFirstChild(currentCharacterName)
    if not CharacterFolder then return end
    local localRootPart    = Character.HumanoidRootPart
    local targetPlayer     = Players:GetPlayerFromCharacter(targetCharacter)
    local targetName       = targetPlayer and targetPlayer.Name or targetCharacter.Name
    local WallComboAbility = CharacterFolder:FindFirstChild("WallCombo")
    if not WallComboAbility then return end
    RemoteCache.AbilitiesRemote:FireServer(WallComboAbility, KillAuraConfig.KillAuraDamage, {}, targetRootPart.Position)
    local startCFrameStr = tostring(localRootPart.CFrame)
    RemoteCache.CombatRemote:FireServer(
        WallComboAbility,
        "Characters:" .. currentCharacterName .. ":WallCombo",
        2,
        KillAuraConfig.KillAuraDamage,
        {
            HitboxCFrames     = {targetRootPart.CFrame, targetRootPart.CFrame},
            BestHitCharacter  = targetCharacter,
            HitCharacters     = {targetCharacter},
            Ignore            = {},
            DeathInfo         = {},
            BlockedCharacters = {},
            HitInfo           = {IsFacing = false, IsInFront = true},
            ServerTime        = 1757900883.31,
            Actions           = {ActionNumber1 = {[targetName] = {
                StartCFrameStr = startCFrameStr,
                Local          = true,
                Collision      = false,
                Animation      = "Punch1Hit",
                Preset         = "Punch",
                Velocity       = Vector3.zero,
                FromPosition   = targetRootPart.Position,
                Seed           = 100735804
            }}},
            FromCFrame = targetRootPart.CFrame
        },
        "Action150",
        0
    )
end

local lastKillAuraExecution = 0
local KILL_AURA_COOLDOWN    = 0.01

local function ExecuteKillAura()
    if not KillAuraConfig.KillAuraEnabled then return end
    local now = tick()
    if now - lastKillAuraExecution < KILL_AURA_COOLDOWN then return end
    lastKillAuraExecution = now
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local currentCharacterName = LocalPlayer.Data.Character.Value
    if not currentCharacterName or not RemoteCache.CharactersFolder then return end
    local CharacterFolder  = RemoteCache.CharactersFolder:FindFirstChild(currentCharacterName)
    if not CharacterFolder then return end
    local localRootPart    = Character.HumanoidRootPart
    local WallComboAbility = CharacterFolder:FindFirstChild("WallCombo")
    if not WallComboAbility then return end
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer == LocalPlayer or not targetPlayer.Character then continue end
        if not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then continue end
        if KillAuraConfig.IgnoreFriends and LocalPlayer:IsFriendsWith(targetPlayer.UserId) then continue end
        local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        local targetRootPart = targetPlayer.Character.HumanoidRootPart
        if not targetHumanoid then continue end
        local health = targetHumanoid:GetAttribute("Health") or targetHumanoid.Health
        if health <= 0 then continue end
        if (localRootPart.Position - targetRootPart.Position).Magnitude > KillAuraConfig.KillAuraDistance then continue end
        RemoteCache.AbilitiesRemote:FireServer(WallComboAbility, KillAuraConfig.KillAuraDamage, {}, targetRootPart.Position)
        local startCFrameStr = tostring(localRootPart.CFrame)
        RemoteCache.CombatRemote:FireServer(
            WallComboAbility,
            "Characters:" .. currentCharacterName .. ":WallCombo",
            2,
            KillAuraConfig.KillAuraDamage,
            {
                HitboxCFrames     = {targetRootPart.CFrame, targetRootPart.CFrame},
                BestHitCharacter  = targetPlayer.Character,
                HitCharacters     = {targetPlayer.Character},
                Ignore            = {},
                DeathInfo         = {},
                BlockedCharacters = {},
                HitInfo           = {IsFacing = false, IsInFront = true},
                ServerTime        = 1757900883.31,
                Actions           = {ActionNumber1 = {[targetPlayer.Name] = {
                    StartCFrameStr = startCFrameStr,
                    Local          = true,
                    Collision      = false,
                    Animation      = "Punch1Hit",
                    Preset         = "Punch",
                    Velocity       = Vector3.zero,
                    FromPosition   = targetRootPart.Position,
                    Seed           = 100735804
                }}},
                FromCFrame = targetRootPart.CFrame
            },
            "Action150",
            0
        )
    end
end

RunService.Heartbeat:Connect(function()
    for i = 1, 5 do ExecuteKillAura() end
end)

-- =====================================================
-- [10] DAMAGE MULTIPLIER HOOK (message8)
-- =====================================================
local ActionRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("Action")
local mt           = getrawmetatable(game)
local old          = mt.__namecall
setreadonly(mt, false)
local InternalCall = false
mt.__namecall = newcclosure(function(self, ...)
    local args   = {...}
    local method = getnamecallmethod()
    if self == ActionRemote and method == "FireServer" and not InternalCall then
        local data = args[5]
        if type(data) == "table" and data.HitCharacters and KillAuraConfig.KillAuraOnHit then
            for _, char in pairs(data.HitCharacters) do
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local health = humanoid:GetAttribute("Health") or humanoid.Health
                    if health > 0 then
                        InternalCall = true
                        for i = 1, KillAuraConfig.KillAuraHitMultiplier do
                            ExecuteKillAuraMul(char)
                        end
                        InternalCall = false
                    end
                end
            end
        end
    end
    return old(self, ...)
end)
setreadonly(mt, true)

-- =====================================================
-- [11] HITBOX EXTENDER (message8)
-- =====================================================
local enableHitbox

task.spawn(function()
    local CoreModule = ReplicatedStorage:WaitForChild("Core", 10)
    if not CoreModule then return end
    local core
    for _ = 1, 30 do
        local ok, res = pcall(function() return require(CoreModule) end)
        if ok and res and type(res.Get) == "function" then core = res; break end
        task.wait(0.25)
    end
    if not core then return end
    for _ = 1, 30 do
        local ok, res = pcall(function() return core.Get("Combat", "Hit") end)
        if ok and res and type(res.Box) == "function" then HitboxSettings.hitLib = res; break end
        task.wait(0.25)
    end
    if not HitboxSettings.hitLib then return end
    HitboxSettings.oldBox = HitboxSettings.hitLib.Box
    if HitboxSettings.pendingEnable then enableHitbox() end
end)

function enableHitbox()
    if not HitboxSettings.hitLib or not HitboxSettings.oldBox then
        HitboxSettings.pendingEnable = true; return false
    end
    if HitboxSettings.hitboxActive then return true end
    HitboxSettings.hitboxActive  = true
    HitboxSettings.pendingEnable = false
    HitboxSettings.hitLib.Box = function(_, ...)
        local args = {...}
        if not HitboxSettings.hitboxActive then
            return HitboxSettings.oldBox(_, unpack(args))
        end
        local size = HitboxSettings.hitSize or 15
        local opts = {}
        if type(args[2]) == "table" then
            for k, v in pairs(args[2]) do opts[k] = v end
        end
        opts.Size = Vector3.new(size, size, size)
        args[2]   = opts
        return HitboxSettings.oldBox(_, unpack(args))
    end
    return true
end

local function disableHitbox()
    if not HitboxSettings.hitLib or not HitboxSettings.oldBox then return end
    if not HitboxSettings.hitboxActive then return end
    HitboxSettings.hitboxActive  = false
    HitboxSettings.pendingEnable = false
    HitboxSettings.hitLib.Box    = HitboxSettings.oldBox
end

-- =====================================================
-- [12] WALLCOMBO (message8) - reemplaza el de nexor
-- =====================================================
task.spawn(function()
    local ok, res = pcall(function() return require(ReplicatedStorage.Core) end)
    if ok and res then WallComboConfig.coreModule = res end
end)

local function getCurrentCharacterName()
    local ok, res = pcall(function() return LocalPlayer.Data.Character.Value end)
    return (ok and res) or "Unknown"
end

local function characterHasWallCombo(charName)
    local ok, res = pcall(function()
        local chars = ReplicatedStorage:WaitForChild("Characters")
        if not chars:FindFirstChild(charName) then return false end
        return chars[charName]:FindFirstChild("WallCombo") ~= nil
    end)
    return ok and res
end

local function generateActionId()
    WallComboConfig.WallComboActionIDCounter = WallComboConfig.WallComboActionIDCounter + 1
    return WallComboConfig.WallComboActionIDCounter + math.random(1000, 5000)
end

local function findNearestPlayerTarget()
    local character = LocalPlayer.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, shortest = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if WallComboConfig.WallComboIgnoreFriends and LocalPlayer:IsFriendsWith(player.UserId) then continue end
            local tr = player.Character:FindFirstChild("HumanoidRootPart")
            local th = player.Character:FindFirstChildOfClass("Humanoid")
            if tr and th then
                local health = th:GetAttribute("Health") or th.Health
                if health > 0 then
                    local dist = (hrp.Position - tr.Position).Magnitude
                    if dist < shortest and dist < 50 then
                        shortest = dist; nearest = player
                    end
                end
            end
        end
    end
    return nearest
end

local function getWallPosition()
    local character = LocalPlayer.Character
    if not character then return Vector3.new(0,0,0) end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.new(0,0,0) end
    return hrp.Position + (hrp.CFrame.LookVector * 5)
end

local function getRootCFrame()
    local character = LocalPlayer.Character
    if not character then return CFrame.new() end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.CFrame or CFrame.new()
end

local function wallcomboMethod1()
    local currentCharacter = getCurrentCharacterName()
    if not characterHasWallCombo(currentCharacter) then return false end
    local targetPlayer = findNearestPlayerTarget()
    if not targetPlayer or not targetPlayer.Character then return false end
    if not LocalPlayer.Character then return false end
    pcall(function()
        local abilityObject = ReplicatedStorage.Characters[currentCharacter].WallCombo
        local abilityRemote = ReplicatedStorage.Remotes.Abilities.Ability
        local combatRemote  = ReplicatedStorage.Remotes.Combat.Action
        local actionId      = generateActionId()
        local serverTime    = tick()
        local wallPos       = getWallPosition()
        local fromCF        = getRootCFrame()
        local tChar         = targetPlayer.Character
        local tName         = targetPlayer.Name
        local tRoot         = tChar.HumanoidRootPart

        -- FireServer con indices 1,2,nil,4,5 para saltar el argumento 3
        local abilityFireArgs = {abilityObject, actionId, nil, tChar, wallPos}
        abilityRemote:FireServer(unpack(abilityFireArgs))

        combatRemote:FireServer(abilityObject, "Characters:"..currentCharacter..":WallCombo", 1, actionId, {
            HitboxCFrames={}, BestHitCharacter=tChar, HitCharacters={tChar},
            Ignore={}, DeathInfo={}, BlockedCharacters={},
            HitInfo={IsFacing=true, GetUp=true, IsInFront=true, Blocked=false},
            ServerTime=serverTime, Actions={}, FromCFrame=fromCF
        }, "Action"..math.random(1000,9999), 0)

        combatRemote:FireServer(abilityObject, "Characters:"..currentCharacter..":WallCombo", 2, actionId, {
            HitboxCFrames={CFrame.new(wallPos)}, BestHitCharacter=tChar, HitCharacters={tChar},
            Ignore={ActionNumber1={tChar}}, DeathInfo={}, BlockedCharacters={},
            HitInfo={IsFacing=true, IsInFront=true, Blocked=false},
            ServerTime=serverTime, Actions={ActionNumber1={}}, FromCFrame=fromCF
        }, "Action"..math.random(1000,9999))

        combatRemote:FireServer(abilityObject, "Characters:"..currentCharacter..":WallCombo", 3, actionId, {
            HitboxCFrames={CFrame.new(wallPos)}, BestHitCharacter=tChar, HitCharacters={tChar},
            Ignore={ActionNumber1={tChar}}, DeathInfo={}, BlockedCharacters={},
            HitInfo={IsFacing=true, IsInFront=true, Blocked=false},
            ServerTime=serverTime, Actions={ActionNumber1={}}, FromCFrame=fromCF
        }, "Action"..math.random(1000,9999))

        combatRemote:FireServer(abilityObject, "Characters:"..currentCharacter..":WallCombo", 4, actionId, {
            HitboxCFrames={CFrame.new(wallPos), CFrame.new(wallPos)},
            BestHitCharacter=tChar, HitCharacters={tChar},
            Ignore={}, DeathInfo={}, BlockedCharacters={},
            HitInfo={IsFacing=true, IsInFront=true, Blocked=false},
            ServerTime=serverTime,
            Actions={ActionNumber1={[tName]={
                StartCFrameStr     = tostring(CFrame.new(tRoot.Position)),
                ImpulseVelocity    = Vector3.new(-67499,150000,307),
                AbilityName        = "WallCombo",
                RotVelocityStr     = "0.000000,0.000000,-0.000000",
                VelocityStr        = "0.000000,0.000000,0.000000",
                Gravity            = 200000,
                RotImpulseVelocity = Vector3.new(8977,-5293,6185),
                Seed               = math.random(100000000,999999999),
                LookVectorStr      = tostring(fromCF.LookVector),
                Duration           = 2
            }}},
            FromCFrame=fromCF
        }, "Action"..math.random(1000,9999), 0.1)
    end)
    return true
end

local function wallcomboMethod2()
    if not WallComboConfig.coreModule then return end
    local character = LocalPlayer.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end
    local charVal = LocalPlayer.Data.Character.Value
    local res = WallComboConfig.coreModule.Get("Combat","Hit").Box(nil, character, {Size = Vector3.new(50,50,50)})
    if res then
        if WallComboConfig.WallComboIgnoreFriends then
            local tp = Players:GetPlayerFromCharacter(res)
            if tp and LocalPlayer:IsFriendsWith(tp.UserId) then return end
        end
        pcall(WallComboConfig.coreModule.Get("Combat","Ability").Activate,
            ReplicatedStorage.Characters[charVal].WallCombo, res,
            head.Position + Vector3.new(0,0,2.5))
    end
end

local function executeWallCombo()
    if not WallComboConfig.WallComboEnabled then return end
    if WallComboConfig.WallComboMethod == "Method 1" then
        wallcomboMethod1()
    else
        wallcomboMethod2()
    end
end

-- =====================================================
-- [13] GOD MODE V2 NPC Y RANKED (message8)
-- =====================================================
task.spawn(function()
    while true do
        if GodModeNPC then
            local npcNames = {"Attacking Bum", "Blocking Bum", "The Ultimate Bum"}
            for _, npcName in ipairs(npcNames) do
                local targetNPC = workspace.Characters.NPCs:FindFirstChild(npcName)
                if targetNPC then
                    pcall(function()
                        local aa = {ReplicatedStorage.Characters.Gon.WallCombo, 33036, nil, targetNPC, Vector3.new(527.693,4.532,79.978)}
                        ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(aa))
                        ReplicatedStorage.Remotes.Combat.Action:FireServer(
                            ReplicatedStorage.Characters.Gon.WallCombo, "Characters:Gon:WallCombo", 1, 33036, {
                                HitboxCFrames={}, BestHitCharacter=targetNPC, HitCharacters={targetNPC},
                                Ignore={}, DeathInfo={}, Actions={},
                                HitInfo={IsFacing=true, IsInFront=true}, BlockedCharacters={},
                                FromCFrame=CFrame.new(534.693,5.532,79.486)
                            }, "Action651", 0)
                    end)
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if GodModeRanked then
            local Character = LocalPlayer.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                local localRoot = Character.HumanoidRootPart
                local closest, closestDist = nil, math.huge
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local tr = player.Character:FindFirstChild("HumanoidRootPart")
                        local th = player.Character:FindFirstChild("Humanoid")
                        if tr and th and th.Health > 0 then
                            if KillAuraConfig.IgnoreFriends and LocalPlayer:IsFriendsWith(player.UserId) then continue end
                            local dist = (localRoot.Position - tr.Position).Magnitude
                            if dist < closestDist then closestDist = dist; closest = player.Character end
                        end
                    end
                end
                if closest then
                    pcall(function()
                        local aa = {ReplicatedStorage.Characters.Gon.WallCombo, 33036, nil, closest, Vector3.new(527.693,4.532,79.978)}
                        ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(aa))
                        ReplicatedStorage.Remotes.Combat.Action:FireServer(
                            ReplicatedStorage.Characters.Gon.WallCombo, "Characters:Gon:WallCombo", 1, 33036, {
                                HitboxCFrames={}, BestHitCharacter=closest, HitCharacters={closest},
                                Ignore={}, DeathInfo={}, Actions={},
                                HitInfo={IsFacing=true, IsInFront=true}, BlockedCharacters={},
                                FromCFrame=CFrame.new(534.693,5.532,79.486)
                            }, "Action651", 0)
                    end)
                end
            end
        end
        task.wait(0.1)
    end
end)

-- =====================================================
-- [14] LAG SERVER (message8)
-- =====================================================
task.spawn(function()
    while true do
        if LagServerEnabled then
            for _, npcName in ipairs({"Attacking Bum", "The Ultimate Bum"}) do
                local targetNPC = workspace.Characters.NPCs:FindFirstChild(npcName)
                if targetNPC then
                    pcall(function()
                        local aa = {ReplicatedStorage.Characters.Gon.WallCombo, 33036, nil, targetNPC, Vector3.new(527.693,4.532,79.978)}
                        ReplicatedStorage.Remotes.Abilities.Ability:FireServer(unpack(aa))
                        ReplicatedStorage.Remotes.Combat.Action:FireServer(
                            ReplicatedStorage.Characters.Gon.WallCombo, "Characters:Gon:WallCombo", 1, 33036, {
                                HitboxCFrames={}, BestHitCharacter=targetNPC, HitCharacters={targetNPC},
                                Ignore={}, DeathInfo={}, Actions={},
                                HitInfo={IsFacing=true, IsInFront=true}, BlockedCharacters={},
                                FromCFrame=CFrame.new(534.693,5.532,79.486)
                            }, "Action651", 0)
                    end)
                end
            end
        end
        task.wait()
    end
end)

-- =====================================================
-- [15] FAST SPAWN / RESPAWN AT DEATH (message8)
-- =====================================================
local function resetCharacterForced()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if typeof(replicatesignal) == "function" and LocalPlayer.Kill then
        replicatesignal(LocalPlayer.Kill)
    elseif humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    else
        character:BreakJoints()
    end
end

local function monitorHumanoid(humanoid)
    if not humanoid then return end
    humanoid:GetAttributeChangedSignal("Health"):Connect(function()
        local health = humanoid:GetAttribute("Health")
        if not health or health > 0 then return end
        if AutoResetEnabled then resetCharacterForced() end
        if RespawnAtDeathEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then deathPosition = hrp.CFrame end
        end
    end)
end

local function connectCharacter(character)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then monitorHumanoid(humanoid) end
    if RespawnAtDeathEnabled and deathPosition then
        task.spawn(function()
            local hrp = character:WaitForChild("HumanoidRootPart")
            task.wait(0.2)
            hrp.CFrame = deathPosition
        end)
    end
end

if LocalPlayer.Character then connectCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(connectCharacter)

-- =====================================================
-- [16] RAGDOLL / EVASIVE ESP (message8)
-- =====================================================
local RagdollESPEnabled = false
local EvasiveESPEnabled = false
local ragdollESPData    = {}
local evasiveESPData    = {}
local evasiveCooldowns  = {}
local evasiveStates     = {}
local ragdollRenderConn, evasiveRenderConn         = nil, nil
local ragdollAddedConn, ragdollRemovingConn         = nil, nil
local evasiveAddedConn, evasiveRemovingConn         = nil, nil

local CONFIG_RAGDOLL = {
    TextSize=15, TextFont=3, TextOutline=true,
    ColorHigh=Color3.fromRGB(0,255,100), ColorMid=Color3.fromRGB(255,200,0),
    ColorLow=Color3.fromRGB(255,50,50), OutlineColor=Color3.new(0,0,0), OffsetY=3.5
}
local CONFIG_EVASIVE = {
    TextSize=20, Font=3, Outline=true,
    ColorReady=Color3.fromRGB(100,200,255), ColorCooldown=Color3.fromRGB(255,100,255),
    OutlineColor=Color3.new(0,0,0), OffsetY=5.5
}
local EVASIVE_BASE = 25
local RagdollModule

task.spawn(function()
    Setidentity()
    local ok, res = pcall(function() return require(LocalPlayer.PlayerScripts.Combat.Ragdoll) end)
    if ok and res then RagdollModule = res end
end)

local function getColorFromProgress(p)
    if p > 0.5 then return CONFIG_RAGDOLL.ColorMid:Lerp(CONFIG_RAGDOLL.ColorHigh, (p-0.5)*2)
    else return CONFIG_RAGDOLL.ColorLow:Lerp(CONFIG_RAGDOLL.ColorMid, p*2) end
end

local function getEvasiveMultiplier()
    local settings = ReplicatedStorage:FindFirstChild("Settings")
    if not settings then return 1 end
    local cds = settings:FindFirstChild("Cooldowns")
    if not cds then return 1 end
    local v = cds:FindFirstChild("Evasive") or cds:FindFirstChild("Ragdoll")
    return (v and v.Value/100) or 1
end

local function createRagdollESP(player)
    if player == LocalPlayer then return end
    local text = Drawing.new("Text")
    text.Center=true; text.Size=CONFIG_RAGDOLL.TextSize; text.Outline=CONFIG_RAGDOLL.TextOutline
    text.OutlineColor=CONFIG_RAGDOLL.OutlineColor; text.Font=CONFIG_RAGDOLL.TextFont; text.Visible=false
    ragdollESPData[player] = {Text=text}
end

local function removeRagdollESP(player)
    local d = ragdollESPData[player]
    if d then d.Text:Remove(); ragdollESPData[player]=nil end
end

local function startRagdollESP()
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createRagdollESP(p) end end
    ragdollAddedConn    = Players.PlayerAdded:Connect(createRagdollESP)
    ragdollRemovingConn = Players.PlayerRemoving:Connect(removeRagdollESP)
    ragdollRenderConn = RunService.RenderStepped:Connect(function()
        if not RagdollModule then return end
        for player, data in pairs(ragdollESPData) do
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and typeof(char:GetAttribute("Ragdoll")) == "number"
               and RagdollModule.EndClocks and RagdollModule.EndClocks[char] then
                local endTime   = RagdollModule.EndClocks[char]
                local remaining = math.max(endTime - os.clock(), 0)
                local totalTime = endTime - RagdollModule.StartClocks[char]
                local sp, onScreen = workspace.CurrentCamera:WorldToViewportPoint(
                    hrp.Position + Vector3.new(0, CONFIG_RAGDOLL.OffsetY, 0))
                if onScreen and remaining > 0 then
                    data.Text.Text=string.format("%.1fs",remaining)
                    data.Text.Color=getColorFromProgress(remaining/totalTime)
                    data.Text.Position=Vector2.new(sp.X,sp.Y)
                    data.Text.Visible=true
                else data.Text.Visible=false end
            else data.Text.Visible=false end
        end
    end)
end

local function stopRagdollESP()
    if ragdollRenderConn   then ragdollRenderConn:Disconnect();   ragdollRenderConn=nil end
    if ragdollAddedConn    then ragdollAddedConn:Disconnect();    ragdollAddedConn=nil end
    if ragdollRemovingConn then ragdollRemovingConn:Disconnect(); ragdollRemovingConn=nil end
    for p in pairs(ragdollESPData) do removeRagdollESP(p) end
end

local function startEvasiveCooldown(player)
    evasiveCooldowns[player] = {start=os.clock(), duration=EVASIVE_BASE*getEvasiveMultiplier()}
end

local function getEvasiveRemaining(player)
    local d = evasiveCooldowns[player]
    if not d then return 0 end
    local t = d.duration-(os.clock()-d.start)
    if t <= 0 then evasiveCooldowns[player]=nil; return 0 end
    return t
end

local function monitorEvasivePlayer(player)
    evasiveStates[player] = {wasRagdoll=false, wasDash=false}
    local function onCharacter(char)
        local function update()
            local ragdoll = char:GetAttribute("Ragdoll")
            local dash    = char:GetAttribute("Dash")
            local s       = evasiveStates[player]
            if not s then return end
            if s.wasRagdoll and dash and not s.wasDash then startEvasiveCooldown(player) end
            s.wasRagdoll=ragdoll; s.wasDash=dash
        end
        char:GetAttributeChangedSignal("Ragdoll"):Connect(update)
        char:GetAttributeChangedSignal("Dash"):Connect(update)
        update()
    end
    if player.Character then onCharacter(player.Character) end
    player.CharacterAdded:Connect(onCharacter)
end

local function createEvasiveESP(player)
    local text = Drawing.new("Text")
    text.Center=true; text.Size=CONFIG_EVASIVE.TextSize; text.Font=CONFIG_EVASIVE.Font
    text.Outline=CONFIG_EVASIVE.Outline; text.OutlineColor=CONFIG_EVASIVE.OutlineColor; text.Visible=false
    evasiveESPData[player] = {Text=text}
end

local function removeEvasiveESP(player)
    local d = evasiveESPData[player]
    if d then d.Text:Remove(); evasiveESPData[player]=nil end
    evasiveCooldowns[player]=nil; evasiveStates[player]=nil
end

local function startEvasiveESP()
    for _, p in pairs(Players:GetPlayers()) do monitorEvasivePlayer(p); createEvasiveESP(p) end
    evasiveAddedConn    = Players.PlayerAdded:Connect(function(p) monitorEvasivePlayer(p); createEvasiveESP(p) end)
    evasiveRemovingConn = Players.PlayerRemoving:Connect(removeEvasiveESP)
    evasiveRenderConn = RunService.RenderStepped:Connect(function()
        for player, ui in pairs(evasiveESPData) do
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then ui.Text.Visible=false; continue end
            local remaining = getEvasiveRemaining(player)
            if player == LocalPlayer then
                ui.Text.Text     = remaining>0 and string.format("Evasive: %.1fs",remaining) or "Evasive: READY"
                ui.Text.Color    = remaining>0 and CONFIG_EVASIVE.ColorCooldown or CONFIG_EVASIVE.ColorReady
                ui.Text.Position = Vector2.new(100,100); ui.Text.Visible=true
            else
                local sp, onScreen = workspace.CurrentCamera:WorldToViewportPoint(
                    hrp.Position+Vector3.new(0,CONFIG_EVASIVE.OffsetY,0))
                if not onScreen then ui.Text.Visible=false; continue end
                ui.Text.Text     = remaining>0 and string.format("%.1fs",remaining) or "EVASIVE: READY"
                ui.Text.Color    = remaining>0 and CONFIG_EVASIVE.ColorCooldown or CONFIG_EVASIVE.ColorReady
                ui.Text.Position = Vector2.new(sp.X,sp.Y); ui.Text.Visible=true
            end
        end
    end)
end

local function stopEvasiveESP()
    if evasiveRenderConn   then evasiveRenderConn:Disconnect();   evasiveRenderConn=nil end
    if evasiveAddedConn    then evasiveAddedConn:Disconnect();    evasiveAddedConn=nil end
    if evasiveRemovingConn then evasiveRemovingConn:Disconnect(); evasiveRemovingConn=nil end
    for p in pairs(evasiveESPData) do removeEvasiveESP(p) end
end

-- =====================================================
-- [17] ABILITY SPAM - LAG SERVER V2 (message8)
-- =====================================================
local AbilitySpam = { enabled = false, connection = nil }

function AbilitySpam:GetCurrentCharacter()
    local ok, res = pcall(function() return LocalPlayer.Data.Character.Value end)
    if ok and res then return res end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum:GetAttribute("CharacterName") or "Unknown"
end

function AbilitySpam:HasAbility4(characterName)
    local ok, res = pcall(function()
        local chars  = ReplicatedStorage:WaitForChild("Characters")
        local folder = chars:FindFirstChild(characterName)
        local ab     = folder and folder:FindFirstChild("Abilities")
        return ab and ab:FindFirstChild("4") ~= nil
    end)
    return ok and res
end

function AbilitySpam:FindNearestPlayer()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local th = p.Character:FindFirstChild("Humanoid")
            if tr and th then
                local hp = th:GetAttribute("Health")
                if hp and hp > 0 then
                    local d = (hrp.Position - tr.Position).Magnitude
                    if d < dist then dist = d; nearest = p end
                end
            end
        end
    end
    return nearest
end

function AbilitySpam:GetNearestCFrame()
    local p = self:FindNearestPlayer()
    return p and p.Character and p.Character.HumanoidRootPart and p.Character.HumanoidRootPart.CFrame or CFrame.new()
end

function AbilitySpam:UseAbility4()
    local charName = self:GetCurrentCharacter()
    if not self:HasAbility4(charName) then return end
    local target = self:FindNearestPlayer()
    if not target then return end
    local targetChar = target.Character
    local targetCF   = self:GetNearestCFrame()
    pcall(function()
        local ability = ReplicatedStorage.Characters[charName].Abilities["4"]
        ReplicatedStorage.Remotes.Abilities.Ability:FireServer(ability, 9000000)
        local actions = {377,380,383,384,385,387,389}
        for i = 1, 7 do
            local args = {
                ability,
                charName .. ":Abilities:4",
                i,
                9000000,
                {
                    HitboxCFrames     = {targetCF, targetCF},
                    BestHitCharacter  = targetChar,
                    HitCharacters     = {targetChar},
                    Ignore            = i > 2 and {ActionNumber1 = {targetChar}} or {},
                    DeathInfo         = {},
                    BlockedCharacters = {},
                    HitInfo           = {IsFacing = not (i==1 or i==2), IsInFront = i<=2, Blocked = i>2 and false or nil},
                    ServerTime        = tick(),
                    Actions           = i > 2 and {ActionNumber1 = {}} or {},
                    FromCFrame        = targetCF
                },
                "Action" .. actions[i],
                i == 2 and 0.1 or nil
            }
            if i == 7 then
                args[5].RockCFrame = targetCF
                args[5].Actions = {ActionNumber1 = {[target.Name] = {
                    StartCFrameStr     = tostring(targetCF.X)..","..tostring(targetCF.Y)..","..tostring(targetCF.Z)..",0,0,0,0,0,0,0,0,0",
                    ImpulseVelocity    = Vector3.new(1901,-25000,291),
                    AbilityName        = "4",
                    RotVelocityStr     = "0,0,0",
                    VelocityStr        = "1.9,0.01,0.29",
                    Duration           = 2,
                    RotImpulseVelocity = Vector3.new(5868,-6649,-7414),
                    Seed               = math.random(1, 1e6),
                    LookVectorStr      = "0.99,0,0.15"
                }}}
            end
            ReplicatedStorage.Remotes.Combat.Action:FireServer(unpack(args))
        end
    end)
end

function AbilitySpam:Start()
    if self.connection then return end
    self.enabled    = true
    self.connection = RunService.Heartbeat:Connect(function()
        if not self.enabled then return end
        self:UseAbility4()
        task.wait(0.5)
        if self.enabled then
            pcall(function()
                local c = self:GetCurrentCharacter()
                ReplicatedStorage.Remotes.Abilities.AbilityCanceled:FireServer(
                    ReplicatedStorage.Characters[c].Abilities["4"]
                )
            end)
        end
        task.wait(0.001)
    end)
end

function AbilitySpam:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self.enabled = false
end

local MobRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Character"):WaitForChild("ChangeCharacter")

-- =====================================================
-- [18] UI - WIND UI (nexor, intacto)
-- =====================================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

WindUI:AddTheme({
    Name = "JoshubDark",
    Background = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#001a00"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#004d00"), Transparency = 0 },
    }, { Rotation = 45 }),
    Accent      = Color3.fromHex("#30FF6A"),
    Outline     = Color3.fromHex("#1c1c20"),
    Text        = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button      = Color3.fromHex("#1f1f23"),
    Icon        = Color3.fromHex("#FFFFFF"),
})

local Window = WindUI:CreateWindow({
    Title      = "Joshub|UBG",
    Author     = "by jos",
    Folder     = "Joshub",
    Icon       = "swords",
    IconSize   = 32,
    Theme      = "JoshubDark",
    OpenButton = { Title = "Joshub", Enabled = true, Draggable = true, Color = ColorSequence.new(Color3.fromHex("#30FF6A")) }
})

-- CONTROL BUTTON (draggable, minimiza la UI)
task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local UIS = game:GetService("UserInputService")
    if PlayerGui:FindFirstChild("ControlButtonGUI") then
        PlayerGui.ControlButtonGUI:Destroy()
    end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ControlButtonGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999999999
    ScreenGui.Parent = PlayerGui
    local ControlButton = Instance.new("ImageButton")
    ControlButton.Size = UDim2.new(0,55,0,55)
    ControlButton.Position = UDim2.new(0.10,-70,0.22,-25)
    ControlButton.Image = "rbxassetid://116498441103707"
    ControlButton.BackgroundColor3 = Color3.fromRGB(35,35,35)
    ControlButton.Parent = ScreenGui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = ControlButton
    local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(70,70,70); stroke.Parent = ControlButton
    local isMinimized = false
    ControlButton.MouseButton1Down:Connect(function() TweenService:Create(ControlButton,TweenInfo.new(0.1),{Size=UDim2.new(0,48,0,48)}):Play() end)
    ControlButton.MouseButton1Up:Connect(function() TweenService:Create(ControlButton,TweenInfo.new(0.1),{Size=UDim2.new(0,55,0,55)}):Play() end)
    ControlButton.MouseEnter:Connect(function() TweenService:Create(ControlButton,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(45,45,45)}):Play() end)
    ControlButton.MouseLeave:Connect(function() TweenService:Create(ControlButton,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(35,35,35)}):Play() end)
    ControlButton.MouseButton1Click:Connect(function() isMinimized = not isMinimized; Window:Minimize(isMinimized) end)
    local dragging, dragStart, startPos
    ControlButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = ControlButton.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            ControlButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        end
    end)
end)

-- PESTAÑAS
local HomeTab      = Window:Tab({ Title = "Home",      Icon = "house",         Color = Color3.fromHex("#4CAF50") })
local MainTab      = Window:Tab({ Title = "Combat",    Icon = "sword",         Color = Color3.fromHex("#4CAF50") })
local CharacterTab = Window:Tab({ Title = "Character", Icon = "user",          Color = Color3.fromHex("#4CAF50") })
local FarmTab      = Window:Tab({ Title = "Farm",      Icon = "list",          Color = Color3.fromHex("#4CAF50") })
local VisualTab    = Window:Tab({ Title = "Visual",    Icon = "eye",           Color = Color3.fromHex("#4CAF50") })
local WorldTab     = Window:Tab({ Title = "World",     Icon = "globe",         Color = Color3.fromHex("#4CAF50") })
local EmotesTab    = Window:Tab({ Title = "Emotes",    Icon = "accessibility", Color = Color3.fromHex("#4CAF50") })
local MiscTab      = Window:Tab({ Title = "Misc",      Icon = "box",           Color = Color3.fromHex("#4CAF50") })
local SettingsTab  = Window:Tab({ Title = "Settings",  Icon = "settings",      Color = Color3.fromHex("#4CAF50") })

-- =====================================================
-- COMBAT TAB (todo lo de Rage + Exploits)
-- =====================================================

-- Kill Aura Mejorado
MainTab:Section({ Title = "Kill Aura" })

local KillAuraToggle = MainTab:Toggle({
    Title   = "Kill Aura",
    Default = false,
    Callback = function(Value)
        KillAuraConfig.KillAuraEnabled = Value
        if Value then
            KillAuraConfig.KillAuraRangeEnabled = true
            startKillAuraRange()
        else
            KillAuraConfig.KillAuraRangeEnabled = false
            stopKillAuraRange()
        end
    end
})

MainTab:Toggle({
    Title   = "Ignore Friends",
    Default = false,
    Callback = function(Value) KillAuraConfig.IgnoreFriends = Value end
})

MainTab:Slider({
    Title    = "Aura Range",
    Step     = 1,
    Value    = { Min = 5, Max = 150, Default = 100 },
    Callback = function(v) KillAuraConfig.KillAuraDistance = v end
})

-- Damage Multiplier
MainTab:Section({ Title = "Damage Multiplier" })

MainTab:Toggle({
    Title   = "Damage Multiplier (On Hit)",
    Default = false,
    Callback = function(Value) KillAuraConfig.KillAuraOnHit = Value end
})

MainTab:Input({
    Title    = "Multiplicador (1-50)",
    Default  = "1",
    Numeric  = true,
    Callback = function(Value)
        KillAuraConfig.KillAuraHitMultiplier = math.clamp(tonumber(Value) or 1, 1, 50)
    end
})

-- WallCombo
MainTab:Section({ Title = "WallCombo" })

MainTab:Dropdown({
    Title    = "WallCombo Method",
    Values   = {"Method 1", "Method 2"},
    Default  = "Method 1",
    Callback = function(Value)
        WallComboConfig.WallComboMethod = Value
        if WallComboConfig.WallComboEnabled then
            if Value == "Method 1" then
                KillAuraConfig.KillAuraRangeEnabled = true; startKillAuraRange()
            else
                KillAuraConfig.KillAuraRangeEnabled = false; stopKillAuraRange()
            end
        end
    end
})

local wallcomboTogg = MainTab:Toggle({
    Title   = "Spam WallCombo",
    Default = false,
    Callback = function(Value)
        WallComboConfig.WallComboEnabled = Value
        Setidentity()
        if Value then
            if WallComboConfig.WallComboMethod == "Method 1" then
                KillAuraConfig.KillAuraRangeEnabled = true; startKillAuraRange()
            end
            RunService:BindToRenderStep(WallComboConfig.renderConnectionName, Enum.RenderPriority.Input.Value, executeWallCombo)
        else
            KillAuraConfig.KillAuraRangeEnabled = false; stopKillAuraRange()
            RunService:UnbindFromRenderStep(WallComboConfig.renderConnectionName)
        end
    end
})

MainTab:Toggle({
    Title   = "Ignore Friends (WallCombo)",
    Default = false,
    Callback = function(Value) WallComboConfig.WallComboIgnoreFriends = Value end
})

-- Kick Mode
MainTab:Section({ Title = "Kick Mode" })

MainTab:Toggle({
    Title   = "Kick Mode (Beta)",
    Default = false,
    Callback = function(state) getgenv().Configs.KickMode = state end
})

-- Target System
MainTab:Section({ Title = "Target System" })

MainTab:Toggle({
    Title   = "Use Target for Aura/WallCombo",
    Default = false,
    Callback = function(state) getgenv().Configs.TargetEnabled = state end
})

local playerNames = {}
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(playerNames, p.Name) end end

local TargetDropdown = MainTab:Dropdown({
    Title    = "Select Target",
    Values   = playerNames,
    Callback = function(v) getgenv().Configs.CurrentTarget = Players:FindFirstChild(v) end
})

task.spawn(function()
    while true do
        local currentNames = {}
        for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(currentNames, p.Name) end end
        TargetDropdown:SetValues(currentNames)
        task.wait(5)
    end
end)

-- God Mode
MainTab:Section({ Title = "God Mode" })

MainTab:Toggle({ Title = "God Mode (Safety)",    Callback = function(s) getgenv().Configs.GodMode = s end })
MainTab:Toggle({ Title = "God Mode V2 (NPC)",    Callback = function(s) GodModeNPC = s end })
MainTab:Toggle({ Title = "God Mode V2 (Ranked)", Callback = function(s) GodModeRanked = s end })

-- Hitbox Extender
MainTab:Section({ Title = "Hitbox Extender" })

MainTab:Toggle({
    Title   = "Hitbox Extender",
    Default = false,
    Callback = function(Value)
        if Value then enableHitbox() else disableHitbox() end
    end
})

MainTab:Input({
    Title    = "Hitbox Size (1-100)",
    Default  = "15",
    Numeric  = true,
    Callback = function(Value)
        HitboxSettings.hitSize = math.clamp(tonumber(Value) or 15, 1, 100)
    end
})

-- Lag Server
MainTab:Section({ Title = "Lag Server" })

MainTab:Toggle({
    Title   = "Lag Server",
    Default = false,
    Callback = function(Value) LagServerEnabled = Value end
})

MainTab:Toggle({
    Title       = "Lag Server V2 (Mob)",
    Default     = false,
    Callback    = function(Value)
        if Value then
            local mob = LocalPlayer.Data.Character.Value
            if mob ~= "Mob" then MobRemote:FireServer("Mob") end
            AbilitySpam:Start()
        else
            AbilitySpam:Stop()
        end
    end
})

-- Exploits
MainTab:Section({ Title = "Exploits" })
MainTab:Toggle({ Title = "Longer Ultimate",        Callback = function(s) pcall(function() ReplicatedStorage.Settings.Multipliers.UltimateTimer.Value = s and 999999 or 100 end) end })
MainTab:Toggle({ Title = "Instant Transformation", Callback = function(s) pcall(function() ReplicatedStorage.Settings.Toggles.InstantTransformation.Value = s end) end })
MainTab:Toggle({ Title = "Disable Combat Timer",   Callback = function(s) pcall(function() ReplicatedStorage.Settings.Toggles.DisableCombatTimer.Value = s end) end })
MainTab:Toggle({ Title = "No Stun on Miss",        Callback = function(s) pcall(function() ReplicatedStorage.Settings.Toggles.DisableHitStun.Value = s end) end })
MainTab:Toggle({ Title = "Disable Finishers",      Callback = function(s) pcall(function() Folders.Toggles:WaitForChild("DisableFinishers").Value = s end) end })
MainTab:Toggle({ Title = "Multi Cutscene",         Callback = function(s) pcall(function() Folders.Toggles:WaitForChild("MultiUseCutscenes").Value = s end) end })
MainTab:Toggle({ Title = "No Jump Fatigue",        Callback = function(s) pcall(function() Folders.Toggles:WaitForChild("NoJumpFatigue").Value = s end) end })
MainTab:Toggle({ Title = "No Slowdowns",           Callback = function(s) pcall(function() Folders.Toggles:WaitForChild("NoSlowdowns").Value = s end) end })

-- =====================================================
-- CHARACTER TAB
-- =====================================================
CharacterTab:Section({ Title = "Player" })

CharacterTab:Slider({
    Title    = "WalkSpeed",
    Step     = 1,
    Value    = {Min = 16, Max = 200, Default = 16},
    Callback = function(v) getgenv().Configs.SpeedValue = v end
})

CharacterTab:Slider({
    Title    = "Speed Multiplier (Server)",
    Step     = 1,
    Value    = {Min = 1, Max = 10, Default = 1},
    Callback = function(v)
        pcall(function()
            ReplicatedStorage.Settings.Multipliers.RunSpeed.Value = v
            ReplicatedStorage.Settings.Multipliers.WalkSpeed.Value = v
        end)
    end
})

CharacterTab:Toggle({ Title = "Instant Respawn", Callback = function(s) getgenv().InstantRespawnEnabled = s end })
CharacterTab:Toggle({ Title = "Anti Counter",    Callback = function(s) getgenv().HitboxEnabled = s end })

CharacterTab:Section({ Title = "Movement" })

CharacterTab:Input({
    Title    = "Dash Cooldown",   Default = "100", Numeric = true,
    Callback = function(v) pcall(function() Folders.Cooldowns:WaitForChild("Dash").Value = tonumber(v) or 100 end) end
})
CharacterTab:Input({
    Title    = "Dash Speed",      Default = "100", Numeric = true,
    Callback = function(v) pcall(function() Folders.Multipliers:WaitForChild("DashSpeed").Value = tonumber(v) or 100 end) end
})
CharacterTab:Input({
    Title    = "Jump Height",     Default = "100", Numeric = true,
    Callback = function(v) pcall(function() Folders.Multipliers:WaitForChild("JumpHeight").Value = tonumber(v) or 100 end) end
})
CharacterTab:Input({
    Title    = "Ragdoll Power",   Default = "100", Numeric = true,
    Callback = function(v) pcall(function() Folders.Multipliers:WaitForChild("RagdollPower").Value = tonumber(v) or 100 end) end
})
CharacterTab:Input({
    Title    = "Melee Speed",     Default = "100", Numeric = true,
    Callback = function(v) pcall(function() Folders.Multipliers:WaitForChild("MeleeSpeed").Value = tonumber(v) or 100 end) end
})
CharacterTab:Input({
    Title    = "Melee Cooldown",  Default = "100", Numeric = true,
    Callback = function(v) pcall(function() Folders.Cooldowns:WaitForChild("Melee").Value = tonumber(v) or 100 end) end
})

CharacterTab:Section({ Title = "TP Walk" })

local tpwalkActive = false
local tpwalkSpeed  = 0
local tpwalkChr, tpwalkHum

local function onTpCharacter(character)
    tpwalkChr = character
    tpwalkHum = character:WaitForChild("Humanoid")
end
if LocalPlayer.Character then onTpCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onTpCharacter)

task.spawn(function()
    while true do
        local delta = hb:Wait()
        if tpwalkActive and tpwalkSpeed > 0 and tpwalkChr and tpwalkHum and tpwalkHum.Parent then
            if tpwalkHum.MoveDirection.Magnitude > 0 then
                tpwalkChr:TranslateBy(tpwalkHum.MoveDirection * tpwalkSpeed * delta)
            end
        end
    end
end)

CharacterTab:Input({
    Title    = "TP Walk Speed",
    Default  = "0",
    Numeric  = true,
    Callback = function(Value) tpwalkSpeed = tonumber(Value) or 0 end
})

CharacterTab:Toggle({
    Title   = "TP Walk",
    Default = false,
    Callback = function(Value) tpwalkActive = Value end
})

-- =====================================================
-- FARM TAB
-- =====================================================
do
    local selectedFarmPlayer = nil
    local farmLoopThread     = nil
    local autoFarmEnabled    = false
    local autoFarmThread     = nil

    local function getPlayerList()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(list, p.Name) end
        end
        if #list == 0 then table.insert(list, "No players") end
        return list
    end

    local function getPlayerByName(name)
        for _, p in ipairs(Players:GetPlayers()) do if p.Name == name then return p end end
        return nil
    end

    local function isPlayerAlive(player)
        if not player or not player.Character then return false end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        local health = hum:GetAttribute("Health") or hum.Health
        return health > 0
    end

    local function teleportExact(player)
        if not player or not player.Character then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        local myChar    = LocalPlayer.Character
        local myHRP     = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not targetHRP or not myHRP then return end
        myHRP.CFrame = targetHRP.CFrame
        myHRP.AssemblyLinearVelocity  = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end

    local function teleportBelow(player)
        if not player or not player.Character then return end
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        local myChar    = LocalPlayer.Character
        local myHRP     = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not targetHRP or not myHRP then return end
        myHRP.CFrame = CFrame.new(targetHRP.Position.X, targetHRP.Position.Y - 10, targetHRP.Position.Z)
        myHRP.AssemblyLinearVelocity  = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end

    local function setCameraToPlayer(player)
        if not player or not player.Character then return end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then workspace.CurrentCamera.CameraSubject = hum end
    end

    local function resetCamera()
        local myChar = LocalPlayer.Character
        if myChar then
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            if hum then workspace.CurrentCamera.CameraSubject = hum end
        end
    end

    FarmTab:Section({ Title = "Player Teleport" })

    local PlayerDropdown = FarmTab:Dropdown({
        Title    = "Select Player",
        Values   = getPlayerList(),
        Callback = function(Value) selectedFarmPlayer = getPlayerByName(Value) end
    })

    local initialList = getPlayerList()
    if initialList[1] ~= "No players" then
        selectedFarmPlayer = getPlayerByName(initialList[1])
    end

    FarmTab:Button({
        Title    = "Refresh List",
        Callback = function()
            local newList = getPlayerList()
            PlayerDropdown:SetValues(newList)
            if selectedFarmPlayer and selectedFarmPlayer.Parent then
                PlayerDropdown:SetValue(selectedFarmPlayer.Name)
            else
                selectedFarmPlayer = getPlayerByName(newList[1])
            end
        end
    })

    FarmTab:Button({
        Title    = "Teleport to Selected",
        Callback = function()
            if selectedFarmPlayer then teleportExact(selectedFarmPlayer) end
        end
    })

    FarmTab:Toggle({
        Title   = "Loop Teleport",
        Default = false,
        Callback = function(Value)
            if Value then
                farmLoopThread = RunService.Heartbeat:Connect(function()
                    if selectedFarmPlayer and selectedFarmPlayer.Parent then
                        teleportExact(selectedFarmPlayer)
                    end
                end)
            else
                if farmLoopThread then farmLoopThread:Disconnect(); farmLoopThread = nil end
            end
        end
    })

    FarmTab:Section({ Title = "Auto Farm" })

    FarmTab:Toggle({
        Title   = "Auto Farm",
        Default = false,
        Callback = function(Value)
            autoFarmEnabled = Value
            if Value then
                KillAuraToggle:SetValue(true)
                autoFarmThread = task.spawn(function()
                    while autoFarmEnabled do
                        local foundTarget = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if not autoFarmEnabled then break end
                            if p ~= LocalPlayer and p.Character
                               and p.Character:FindFirstChild("HumanoidRootPart")
                               and isPlayerAlive(p) then
                                foundTarget = true
                                setCameraToPlayer(p)
                                teleportBelow(p)
                                task.wait(0.25)
                            end
                        end
                        if not foundTarget then task.wait(1) else task.wait(0.05) end
                    end
                end)
            else
                if autoFarmThread then task.cancel(autoFarmThread); autoFarmThread = nil end
                resetCamera()
                KillAuraToggle:SetValue(false)
            end
        end
    })

    FarmTab:Section({ Title = "Server Hop" })

    local serverHopEnabled = false
    local serverHopDelay   = 30
    local serverHopThread  = nil

    FarmTab:Input({
        Title    = "Delay (segundos)",
        Default  = "30",
        Numeric  = true,
        Callback = function(Value) serverHopDelay = tonumber(Value) or 30 end
    })

    FarmTab:Toggle({
        Title       = "Server Hop",
        Default     = false,
        Callback    = function(Value)
            serverHopEnabled = Value
            if Value then
                serverHopThread = task.spawn(function()
                    while serverHopEnabled do
                        task.wait(serverHopDelay)
                        if not serverHopEnabled then break end
                        pcall(function()
                            local TeleportService = game:GetService("TeleportService")
                            local placeId      = game.PlaceId
                            local currentJobId = game.JobId
                            local url      = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
                            local response = HttpService:JSONDecode(game:HttpGet(url))
                            local targetServer = nil
                            if response and response.data then
                                for _, server in ipairs(response.data) do
                                    if server.id ~= currentJobId and server.playing > 0 then
                                        targetServer = server.id; break
                                    end
                                end
                            end
                            if targetServer then
                                TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
                            else
                                TeleportService:Teleport(placeId, LocalPlayer)
                            end
                        end)
                    end
                end)
            else
                if serverHopThread then task.cancel(serverHopThread); serverHopThread = nil end
            end
        end
    })

    Players.PlayerAdded:Connect(function()
        task.wait(1); PlayerDropdown:SetValues(getPlayerList())
    end)
    Players.PlayerRemoving:Connect(function(player)
        if selectedFarmPlayer == player then selectedFarmPlayer = nil end
        PlayerDropdown:SetValues(getPlayerList())
    end)
end

-- =====================================================
-- VISUAL TAB
-- =====================================================
VisualTab:Section({ Title = "ESP" })

VisualTab:Toggle({
    Title    = "Player Highlights",
    Callback = function(state)
        getgenv().ESPEnabled = state
        task.spawn(function()
            while getgenv().ESPEnabled do
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        if not p.Character:FindFirstChild("Highlight") then
                            local h = Instance.new("Highlight", p.Character)
                            h.FillColor    = Color3.fromRGB(255,0,0)
                            h.OutlineColor = Color3.fromRGB(255,255,255)
                        end
                    end
                end
                task.wait(1)
            end
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Highlight") then
                    p.Character.Highlight:Destroy()
                end
            end
        end)
    end
})

VisualTab:Section({ Title = "ESP Avanzado" })

VisualTab:Toggle({
    Title   = "Ragdoll Timer ESP",
    Default = false,
    Callback = function(Value)
        RagdollESPEnabled = Value
        if Value then startRagdollESP() else stopRagdollESP() end
    end
})

VisualTab:Toggle({
    Title   = "Evasive Cooldown ESP",
    Default = false,
    Callback = function(Value)
        EvasiveESPEnabled = Value
        if Value then startEvasiveESP() else stopEvasiveESP() end
    end
})

-- =====================================================
-- WORLD TAB
-- =====================================================
WorldTab:Section({ Title = "Atmosphere" })

WorldTab:Dropdown({
    Title    = "Lighting",
    Values   = {"None", "Sun", "Night", "Cycle"},
    Callback = function(v)
        if v == "Sun"       then Lighting.ClockTime = 12
        elseif v == "Night" then Lighting.ClockTime = 0 end
    end
})

-- =====================================================
-- EMOTES TAB (completo de message8)
-- =====================================================

local COSMETICS = {
    Accessories = {"None","Chunin Exam Vest","Halo","Frozen Gloves","Devil's Eye","Devil's Tail","Devil's Wings",
        "Flower Wings","Frozen Crown","Frozen Tail","Frozen Wings","Garland Scarf","Hades Helmet",
        "Holiday Scarf","Krampus Hat","Red Kagune","Rudolph Antlers","Snowflake Wings","Sorting Hat","VIP Crown"},
    Auras = {"None","Butterflies","Northern Lights","Ki","Blue Lightning","Green Lightning","Purple Lightning","Yellow Lightning"},
    Capes = {"None","Ice Lord","Viking","Christmas Lights","Dracula","Krampus","Krampus Supreme","Santa","VIP","Webbed"}
}

local killEmoteFolderCos = ReplicatedStorage:WaitForChild("Cosmetics"):WaitForChild("KillEmote")

local SelectedKillEmote     = "None"
local SelectedKillEmoteSlot = 1
local SelectedAccessory     = "None"
local SelectedAura          = "None"
local SelectedCape          = "None"

local function ApplyKillEmote()
    local data = {}
    for i = 1, 4 do table.insert(data, {"Emote","None"}) end
    for i = 1, 4 do table.insert(data, true) end
    data[SelectedKillEmoteSlot] = {"KillEmote", SelectedKillEmote}
    LocalPlayer.Data.EmoteEquipped.Value = HttpService:JSONEncode(data)
end

local function ApplyCosmetic(cosmeticType)
    local selectedItem = cosmeticType == "Accessories" and SelectedAccessory
                      or cosmeticType == "Auras"       and SelectedAura
                      or SelectedCape
    if selectedItem == "None" then selectedItem = nil end
    local dataFolder  = LocalPlayer:WaitForChild("Data")
    local valueName   = cosmeticType .. "Equipped"
    local valueObject = dataFolder:FindFirstChild(valueName)
    if not valueObject then
        valueObject = Instance.new("StringValue"); valueObject.Name = valueName; valueObject.Parent = dataFolder
    end
    valueObject.Value = HttpService:JSONEncode(selectedItem and {selectedItem} or {})
end

local EmotesConfg = {
    selectedKillEmoteForSpam = "None",
    isSpammingRandomKillEmote = false,
    isSpammingSelectedKillEmote = false,
    randomSpamDelay = 0.05,
    selectedSpamDelay = 0.05,
    lastRandomSpam = 0,
    lastSelectedSpam = 0,
    lastEmoteUse = 0,
    emoteCooldown = 0.05
}

local function useKillEmote(emoteName)
    if not emoteName or emoteName == "None" then return end
    if tick() - EmotesConfg.lastEmoteUse < EmotesConfg.emoteCooldown then return end
    EmotesConfg.lastEmoteUse = tick()
    local emoteModule = ReplicatedStorage.Cosmetics.KillEmote:FindFirstChild(emoteName)
    if not emoteModule then return end
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local closestTarget, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local tr = player.Character:FindFirstChild("HumanoidRootPart")
            local th = player.Character:FindFirstChild("Humanoid")
            if tr and th then
                local d = (Character.HumanoidRootPart.Position - tr.Position).Magnitude
                if d < closestDist then closestDist = d; closestTarget = player.Character end
            end
        end
    end
    -- También revisa NPCs
    local npcs = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild("NPCs")
    if npcs then
        for _, npc in pairs(npcs:GetChildren()) do
            if npc:IsA("Model") then
                local tr = npc:FindFirstChild("HumanoidRootPart")
                if tr then
                    local d = (Character.HumanoidRootPart.Position - tr.Position).Magnitude
                    if d < closestDist then closestDist = d; closestTarget = npc end
                end
            end
        end
    end
    if closestTarget then
        task.spawn(function()
            _G.KillEmote = true
            pcall(function()
                pcall(function() setthreadidentity(2) end)
                pcall(function() setthreadcontext(2) end)
                Core.Get("Combat","Ability").Activate(emoteModule, closestTarget)
            end)
            _G.KillEmote = false
        end)
    end
end

local function useRandomKillEmote()
    local list = {}
    for _, emote in pairs(killEmoteFolderCos:GetChildren()) do table.insert(list, emote.Name) end
    if #list > 0 then useKillEmote(list[math.random(1,#list)]) end
end

RunService.Heartbeat:Connect(function()
    local now = tick()
    if EmotesConfg.isSpammingRandomKillEmote and now - EmotesConfg.lastRandomSpam >= EmotesConfg.randomSpamDelay then
        useRandomKillEmote(); EmotesConfg.lastRandomSpam = now
    end
    if EmotesConfg.isSpammingSelectedKillEmote and EmotesConfg.selectedKillEmoteForSpam ~= "None"
       and now - EmotesConfg.lastSelectedSpam >= EmotesConfg.selectedSpamDelay then
        useKillEmote(EmotesConfg.selectedKillEmoteForSpam); EmotesConfg.lastSelectedSpam = now
    end
end)

-- Kill Emotes Equip
EmotesTab:Section({ Title = "Kill Emote (Equipar)" })

local killEmoteListAll = {"None"}
for _, emote in pairs(killEmoteFolderCos:GetChildren()) do table.insert(killEmoteListAll, emote.Name) end

EmotesTab:Dropdown({ Title = "Select Kill Emote", Values = killEmoteListAll, Callback = function(v) SelectedKillEmote = v end })
EmotesTab:Dropdown({ Title = "Slot", Values = {"Slot 1","Slot 2","Slot 3","Slot 4"}, Callback = function(v) SelectedKillEmoteSlot = tonumber(v:match("%d+")) end })
EmotesTab:Button({ Title = "Aplicar Kill Emote", Callback = function() ApplyKillEmote() end })

-- Spam Kill Emotes
EmotesTab:Section({ Title = "Spam Kill Emote" })

local killEmoteSpamList = {"None"}
for _, emote in pairs(killEmoteFolderCos:GetChildren()) do table.insert(killEmoteSpamList, emote.Name) end

EmotesTab:Dropdown({ Title = "Emote para Spam", Values = killEmoteSpamList, Callback = function(v) EmotesConfg.selectedKillEmoteForSpam = v end })

local SpamRandomToggle  = EmotesTab:Toggle({ Title = "Spam Random Kill Emotes",   Default = false, Callback = function(v) EmotesConfg.isSpammingRandomKillEmote = v end })
local SpamSelectedToggle = EmotesTab:Toggle({ Title = "Spam Selected Kill Emote", Default = false, Callback = function(v) EmotesConfg.isSpammingSelectedKillEmote = v end })

EmotesTab:Input({ Title = "Random Delay (ms)",   Default = "50", Numeric = true, Callback = function(v) EmotesConfg.randomSpamDelay   = (tonumber(v) or 50)/1000 end })
EmotesTab:Input({ Title = "Selected Delay (ms)", Default = "50", Numeric = true, Callback = function(v) EmotesConfg.selectedSpamDelay = (tonumber(v) or 50)/1000 end })

-- Cosmetics
EmotesTab:Section({ Title = "Accesorios" })
EmotesTab:Dropdown({ Title = "Accesorio", Values = COSMETICS.Accessories, Callback = function(v) SelectedAccessory = v end })
EmotesTab:Button({ Title = "Aplicar Accesorio", Callback = function() ApplyCosmetic("Accessories") end })
EmotesTab:Dropdown({ Title = "Aura", Values = COSMETICS.Auras, Callback = function(v) SelectedAura = v end })
EmotesTab:Button({ Title = "Aplicar Aura", Callback = function() ApplyCosmetic("Auras") end })
EmotesTab:Dropdown({ Title = "Capa", Values = COSMETICS.Capes, Callback = function(v) SelectedCape = v end })
EmotesTab:Button({ Title = "Aplicar Capa", Callback = function() ApplyCosmetic("Capes") end })

-- =====================================================
-- INVISIBILIDAD (message8)
-- =====================================================
local InvisibleConfig = {
    isInvisible = false, platform = nil, mirrorModel = nil,
    mirrorPart = nil, movementConnection = nil, lastJumpHeight = 0
}

local function createPlatform_Invisible()
    local groundUnion = workspace.Map.Structural.Ground.Union
    local character   = LocalPlayer.Character
    if not groundUnion or not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local part = Instance.new("Part")
    part.Name = "InvisibilityPlatform"
    part.Size = Vector3.new(2000,1,2000)
    part.Position = Vector3.new(hrp.Position.X, groundUnion.Position.Y-20, hrp.Position.Z)
    part.Anchored = true; part.CanCollide = true; part.Transparency = 0.5
    part.BrickColor = BrickColor.new("Bright blue"); part.Parent = workspace
    return part
end

local function createMirrorClone()
    local character = LocalPlayer.Character
    if not character then return nil end
    character.Archivable = true
    local clone = character:Clone(); clone.Name = "MirrorClone"; clone.Parent = workspace
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
    end
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("BasePart") then d.CanCollide=false; d.Massless=true; d.Anchored=false end
    end
    local hrp = clone:FindFirstChild("HumanoidRootPart")
    if not hrp then clone:Destroy(); return nil end
    clone.PrimaryPart = hrp
    local hum = clone:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand=true; hum.AutoRotate=false end
    local srcHRP = character:FindFirstChild("HumanoidRootPart")
    if srcHRP then clone:PivotTo(srcHRP.CFrame) end
    InvisibleConfig.mirrorModel = clone
    return hrp
end

local function updateMirrorPosition(dt)
    local character = LocalPlayer.Character
    if not character or not InvisibleConfig.mirrorModel or not InvisibleConfig.mirrorModel.PrimaryPart then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local groundY = workspace.Map.Structural.Ground.Union.Position.Y
    local platformTopY = InvisibleConfig.platform and (InvisibleConfig.platform.Position.Y + InvisibleConfig.platform.Size.Y*0.5) or groundY
    local targetJH = math.min(math.max(0,(hrp.Position.Y-platformTopY)*0.5), 20)
    InvisibleConfig.lastJumpHeight = InvisibleConfig.lastJumpHeight + (targetJH - InvisibleConfig.lastJumpHeight) * math.clamp((dt or 1/60)*10,0,1)
    local newPos = Vector3.new(hrp.Position.X, groundY+3+InvisibleConfig.lastJumpHeight, hrp.Position.Z)
    local look = hrp.CFrame.LookVector
    local flatLook = Vector3.new(look.X,0,look.Z)
    if flatLook.Magnitude > 0 then InvisibleConfig.mirrorModel:PivotTo(CFrame.new(newPos, newPos+flatLook))
    else InvisibleConfig.mirrorModel:PivotTo(CFrame.new(newPos)) end
end

local function enableInvisible()
    if InvisibleConfig.isInvisible then return end
    local character = LocalPlayer.Character
    if not character then return end
    InvisibleConfig.platform = createPlatform_Invisible()
    if not InvisibleConfig.platform then return end
    InvisibleConfig.mirrorPart = createMirrorClone()
    if not InvisibleConfig.mirrorPart then InvisibleConfig.platform:Destroy(); InvisibleConfig.platform=nil; return end
    for _, p in ipairs(character:GetChildren()) do if p:IsA("BasePart") then p.CanCollide=false end end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        local platformTopY = InvisibleConfig.platform.Position.Y + InvisibleConfig.platform.Size.Y*0.5
        require(LocalPlayer.PlayerScripts.Character.FullCustomReplication).Override(character,
            CFrame.new(hrp.Position.X, platformTopY+hum.HipHeight+hrp.Size.Y*0.5, hrp.Position.Z))
    end
    local mirrorHum = InvisibleConfig.mirrorModel:FindFirstChildOfClass("Humanoid")
    workspace.CurrentCamera.CameraSubject = mirrorHum or InvisibleConfig.mirrorPart
    InvisibleConfig.movementConnection = RunService.Heartbeat:Connect(updateMirrorPosition)
    InvisibleConfig.isInvisible = true
end

local function disableInvisible()
    if not InvisibleConfig.isInvisible then return end
    local character = LocalPlayer.Character
    if InvisibleConfig.movementConnection then InvisibleConfig.movementConnection:Disconnect(); InvisibleConfig.movementConnection=nil end
    if character and InvisibleConfig.mirrorModel and InvisibleConfig.mirrorModel.PrimaryPart then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            for _, p in ipairs(character:GetChildren()) do if p:IsA("BasePart") then p.CanCollide=true end end
            local groundY = workspace.Map.Structural.Ground.Union.Position.Y
            task.wait()
            require(LocalPlayer.PlayerScripts.Character.FullCustomReplication).Override(character,
                CFrame.new(InvisibleConfig.mirrorModel.PrimaryPart.Position.X, groundY+hum.HipHeight+hrp.Size.Y*0.5, InvisibleConfig.mirrorModel.PrimaryPart.Position.Z))
            task.wait()
            workspace.CurrentCamera.CameraSubject = character:FindFirstChildOfClass("Humanoid") or hrp
        end
    else
        if character then
            for _, p in ipairs(character:GetChildren()) do if p:IsA("BasePart") then p.CanCollide=true end end
            workspace.CurrentCamera.CameraSubject = character:FindFirstChildOfClass("Humanoid") or character:FindFirstChild("HumanoidRootPart")
        end
    end
    if InvisibleConfig.platform    then InvisibleConfig.platform:Destroy() end
    if InvisibleConfig.mirrorModel then InvisibleConfig.mirrorModel:Destroy() end
    InvisibleConfig.platform=nil; InvisibleConfig.mirrorModel=nil; InvisibleConfig.mirrorPart=nil
    InvisibleConfig.lastJumpHeight=0; InvisibleConfig.isInvisible=false
end

-- =====================================================
-- MISC TAB
-- =====================================================
MiscTab:Section({ Title = "Spawn" })

MiscTab:Toggle({
    Title   = "Fast Spawn",
    Default = false,
    Callback = function(Value) AutoResetEnabled = Value end
})

MiscTab:Toggle({
    Title   = "Respawn at Death Position",
    Default = false,
    Callback = function(Value)
        RespawnAtDeathEnabled = Value
        if not Value then deathPosition = nil end
    end
})

MiscTab:Button({
    Title    = "Reset Character",
    Callback = function() resetCharacterForced() end
})

MiscTab:Section({ Title = "Invisibilidad" })

MiscTab:Toggle({
    Title       = "Invisibility",
    Default     = false,
    Callback    = function(Value)
        task.spawn(function()
            if Value then enableInvisible() else disableInvisible() end
        end)
    end
})

-- =====================================================
-- HOME TAB
-- =====================================================
HomeTab:Paragraph({
    Title = "Joshub Ultimate Enhanced V3",
    Desc  = "Base: Nexor | WallCombo: Message(8)\n+ Kill Aura, Hitbox, God V2, Lag Server, Farm, Cosmetics, ESP, Invisibilidad\nDiscord: discord.gg/Qt7zRF7E"
})

-- =====================================================
-- SETTINGS TAB
-- =====================================================
SettingsTab:Paragraph({
    Title = "V3 Info",
    Desc  = "Todo combat en Combat Tab\nFarm/Server Hop en Farm Tab\nCosmetics/Emotes en Emotes Tab\nInvisibilidad en Misc Tab\nESP en Visual Tab"
})

task.wait(1.5)
pcall(function() HomeTab:Select() end)
warn("Joshub Ultimate Enhanced V3 Loaded!")
