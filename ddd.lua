-- =====================================================
-- JOSHUB V4 - BY JOS
-- =====================================================

-- =====================================================
-- [1] SERVICIOS
-- =====================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local LocalPlayer       = Players.LocalPlayer
local RS                = ReplicatedStorage

local Folders = {
    Toggles     = RS:WaitForChild("Settings"):WaitForChild("Toggles"),
    Multipliers = RS:WaitForChild("Settings"):WaitForChild("Multipliers"),
    Cooldowns   = RS:WaitForChild("Settings"):WaitForChild("Cooldowns"),
}


-- =====================================================
-- [2] CORE MODULE
-- =====================================================
local Core = nil
task.spawn(function()
    pcall(function()
        local set_id = setthreadidentity or (syn and syn.set_thread_identity)
        if set_id then pcall(set_id, 2) end
        Core = require(RS:WaitForChild("Core", 10))
    end)
end)

-- =====================================================
-- [3] REMOTE CACHE
-- =====================================================
local RemoteCache = { AbilitiesRemote=nil, CombatRemote=nil, DashRemote=nil, CharactersFolder=nil }
task.spawn(function()
    local remotes = RS:WaitForChild("Remotes", 10)
    if not remotes then return end
    RemoteCache.AbilitiesRemote  = remotes:WaitForChild("Abilities"):WaitForChild("Ability")
    RemoteCache.CombatRemote     = remotes:WaitForChild("Combat"):WaitForChild("Action")
    RemoteCache.DashRemote       = remotes:WaitForChild("Character"):WaitForChild("Dash")
    RemoteCache.CharactersFolder = RS:WaitForChild("Characters")
end)

local MobRemote = RS:WaitForChild("Remotes"):WaitForChild("Character"):WaitForChild("ChangeCharacter")

-- =====================================================
-- [4] UTILIDADES
-- =====================================================
local function Setidentity()
    pcall(function() setthreadidentity(5); setthreadcontext(5) end)
end

local function getCharName()
    local ok, v = pcall(function() return LocalPlayer.Data.Character.Value end)
    return (ok and v) or "Gon"
end

local function getPlayersInRange(dist, ignoreAllies)
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local result = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end
        if ignoreAllies and LocalPlayer:IsFriendsWith(p.UserId) then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then continue end
        local hp = hum:GetAttribute("Health") or hum.Health
        if hp <= 0 then continue end
        if (myHRP.Position - hrp.Position).Magnitude <= dist then
            table.insert(result, p.Character)
        end
    end
    return result
end

local function MassKill(targets, stackCount)
    if not targets or #targets == 0 then return end
    local charName = getCharName()
    local charFolder = RemoteCache.CharactersFolder and RemoteCache.CharactersFolder:FindFirstChild(charName)
    if not charFolder then return end
    local wallCombo = charFolder:FindFirstChild("WallCombo")
    if not wallCombo then return end
    stackCount = stackCount or 50
    local hitList = {}
    for _, tc in ipairs(targets) do
        for i = 1, stackCount do table.insert(hitList, tc) end
    end
    pcall(function()
        RemoteCache.AbilitiesRemote:FireServer(wallCombo, 69)
        RemoteCache.CombatRemote:FireServer(wallCombo, "", 4, 69, {
            BestHitCharacter=nil, HitCharacters=hitList, Ignore={}, Actions={}
        })
    end)
end

-- =====================================================
-- [5] KILL AURA CONFIGS
-- =====================================================
local KillAuraV1Config = { Enabled=false, Distance=50, IgnoreAllies=false }
local KillAuraV2Config = { Enabled=false, Distance=50, IgnoreAllies=false }
local KillAuraV3Config = { Enabled=false, Distance=50, Delay=0.05, IgnoreFriends=false }
local KillAuraEnabled  = false
local AutoClaimEmote   = false
local _autoClaimConn   = nil

-- KA V1 loop
task.spawn(function() task.wait(1)
    while true do
        if KillAuraV1Config.Enabled then
            local t = getPlayersInRange(KillAuraV1Config.Distance, KillAuraV1Config.IgnoreAllies)
            if #t > 0 then MassKill(t, 50) end
            task.wait()
        else task.wait(0.05) end
    end
end)

-- KA V2 loop (Anti God Mode)
task.spawn(function() task.wait(1)
    while true do
        if KillAuraV2Config.Enabled then
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                local targets = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p == LocalPlayer or not p.Character then continue end
                    if KillAuraV2Config.IgnoreAllies and LocalPlayer:IsFriendsWith(p.UserId) then continue end
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if not hrp or not hum then continue end
                    local hp = hum:GetAttribute("Health") or hum.Health
                    if hp <= 0 then continue end
                    if (myHRP.Position - hrp.Position).Magnitude <= KillAuraV2Config.Distance then
                        table.insert(targets, p.Character)
                    end
                end
                if #targets > 0 then MassKill(targets, 50) end
            end
            task.wait()
        else task.wait(0.05) end
    end
end)

-- KA V3 loop (Kill Farming - instant, stack 100)
task.spawn(function() task.wait(1)
    while true do
        if KillAuraV3Config.Enabled then
            local t = getPlayersInRange(KillAuraV3Config.Distance, KillAuraV3Config.IgnoreFriends)
            if #t > 0 then MassKill(t, 100) end
            task.wait() -- next frame
        else task.wait(0.05) end
    end
end)

-- =====================================================
-- [6] WALLCOMBO
-- =====================================================
local WallComboConfig = {
    WallComboEnabled=false, WallComboMethod="Method 1",
    coreModule=nil, renderConnectionName="WallComboV2",
    WallComboActionIDCounter=0, WallComboIgnoreFriends=false
}

task.spawn(function()
    if not setthreadidentity and not (syn and syn.set_thread_identity) then return end
    for i = 1, 30 do
        local ok, res = pcall(function()
            local set_id = setthreadidentity or (syn and syn.set_thread_identity)
            if set_id then pcall(set_id, 2) end
            return require(RS.Core)
        end)
        if ok and res and type(res.Get) == "function" then WallComboConfig.coreModule = res; break end
        task.wait(0.5)
    end
end)

local function startKillAuraRange() KillAuraConfig = KillAuraConfig or {}; KillAuraConfig.KillAuraRangeEnabled = true end
local function stopKillAuraRange()  KillAuraConfig = KillAuraConfig or {}; KillAuraConfig.KillAuraRangeEnabled = false end
local KillAuraConfig = { KillAuraRangeEnabled=false }

local function generateActionId()
    WallComboConfig.WallComboActionIDCounter = WallComboConfig.WallComboActionIDCounter + 1
    return WallComboConfig.WallComboActionIDCounter + math.random(1000,5000)
end

local function findNearestPlayer()
    local char = LocalPlayer.Character; if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local nearest, shortest = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if WallComboConfig.WallComboIgnoreFriends and LocalPlayer:IsFriendsWith(p.UserId) then continue end
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local th = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and th and (th:GetAttribute("Health") or th.Health) > 0 then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < shortest and d < 50 then shortest=d; nearest=p end
            end
        end
    end
    return nearest
end

local function wallcomboMethod1()
    local charName = getCharName()
    local target = findNearestPlayer()
    if not target or not target.Character or not LocalPlayer.Character then return end
    pcall(function()
        local abilityObject = RS.Characters[charName].WallCombo
        local actionId = generateActionId()
        local serverTime = tick()
        local tChar = target.Character
        local tName = target.Name
        local tRoot = tChar.HumanoidRootPart
        local wallPos = LocalPlayer.Character.HumanoidRootPart.Position + LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 5
        local fromCF  = LocalPlayer.Character.HumanoidRootPart.CFrame
        local ar = RS.Remotes.Abilities.Ability
        local cr = RS.Remotes.Combat.Action
        ar:FireServer(abilityObject, actionId, nil, tChar, wallPos)
        cr:FireServer(abilityObject,"Characters:"..charName..":WallCombo",1,actionId,{HitboxCFrames={},BestHitCharacter=tChar,HitCharacters={tChar},Ignore={},DeathInfo={},BlockedCharacters={},HitInfo={IsFacing=true,GetUp=true,IsInFront=true,Blocked=false},ServerTime=serverTime,Actions={},FromCFrame=fromCF},"Action"..math.random(1000,9999),0)
        cr:FireServer(abilityObject,"Characters:"..charName..":WallCombo",2,actionId,{HitboxCFrames={CFrame.new(wallPos)},BestHitCharacter=tChar,HitCharacters={tChar},Ignore={ActionNumber1={tChar}},DeathInfo={},BlockedCharacters={},HitInfo={IsFacing=true,IsInFront=true,Blocked=false},ServerTime=serverTime,Actions={ActionNumber1={}},FromCFrame=fromCF},"Action"..math.random(1000,9999))
        cr:FireServer(abilityObject,"Characters:"..charName..":WallCombo",3,actionId,{HitboxCFrames={CFrame.new(wallPos)},BestHitCharacter=tChar,HitCharacters={tChar},Ignore={ActionNumber1={tChar}},DeathInfo={},BlockedCharacters={},HitInfo={IsFacing=true,IsInFront=true,Blocked=false},ServerTime=serverTime,Actions={ActionNumber1={}},FromCFrame=fromCF},"Action"..math.random(1000,9999))
        cr:FireServer(abilityObject,"Characters:"..charName..":WallCombo",4,actionId,{HitboxCFrames={CFrame.new(wallPos),CFrame.new(wallPos)},BestHitCharacter=tChar,HitCharacters={tChar},Ignore={},DeathInfo={},BlockedCharacters={},HitInfo={IsFacing=true,IsInFront=true,Blocked=false},ServerTime=serverTime,Actions={ActionNumber1={[tName]={StartCFrameStr=tostring(CFrame.new(tRoot.Position)),ImpulseVelocity=Vector3.new(-67499,150000,307),AbilityName="WallCombo",RotVelocityStr="0,0,0",VelocityStr="0,0,0",Gravity=200000,RotImpulseVelocity=Vector3.new(8977,-5293,6185),Seed=math.random(100000000,999999999),LookVectorStr=tostring(fromCF.LookVector),Duration=2}}},FromCFrame=fromCF},"Action"..math.random(1000,9999),0.1)
    end)
end

local function wallcomboMethod2()
    if not WallComboConfig.coreModule then return end
    local char = LocalPlayer.Character; if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    local charName = getCharName()
    local res = WallComboConfig.coreModule.Get("Combat","Hit").Box(nil, char, {Size=Vector3.new(50,50,50)})
    if res then
        if WallComboConfig.WallComboIgnoreFriends then
            local tp = Players:GetPlayerFromCharacter(res)
            if tp and LocalPlayer:IsFriendsWith(tp.UserId) then return end
        end
        pcall(WallComboConfig.coreModule.Get("Combat","Ability").Activate,
            RS.Characters[charName].WallCombo, res, head.Position+Vector3.new(0,0,2.5))
    end
end

local function executeWallCombo()
    if not WallComboConfig.WallComboEnabled then return end
    if WallComboConfig.WallComboMethod == "Method 1" then wallcomboMethod1()
    else wallcomboMethod2() end
end

-- =====================================================
-- [7] HITBOX
-- =====================================================
local HitboxSettings = { hitSize=15, hitboxActive=false, hitLib=nil, oldBox=nil, pendingEnable=false }
local enableHitbox, disableHitbox

task.spawn(function()
    local CoreModule = RS:WaitForChild("Core", 10); if not CoreModule then return end
    if not setthreadidentity and not (syn and syn.set_thread_identity) then return end
    local core
    for _ = 1, 30 do
        local ok, res = pcall(function()
            local set_id = setthreadidentity or (syn and syn.set_thread_identity)
            if set_id then pcall(set_id, 2) end
            return require(CoreModule)
        end)
        if ok and res and type(res.Get) == "function" then core=res; break end
        if not ok then break end
        task.wait(0.25)
    end
    if not core then return end
    for _ = 1, 30 do
        local ok, res = pcall(function() return core.Get("Combat","Hit") end)
        if ok and res and type(res.Box) == "function" then HitboxSettings.hitLib=res; break end
        task.wait(0.25)
    end
    if not HitboxSettings.hitLib then return end
    HitboxSettings.oldBox = HitboxSettings.hitLib.Box
    if HitboxSettings.pendingEnable then enableHitbox() end
end)

function enableHitbox()
    if not HitboxSettings.hitLib or not HitboxSettings.oldBox then HitboxSettings.pendingEnable=true; return false end
    if HitboxSettings.hitboxActive then return true end
    HitboxSettings.hitboxActive=true; HitboxSettings.pendingEnable=false
    HitboxSettings.hitLib.Box = function(_, ...)
        local args={...}
        if not HitboxSettings.hitboxActive then return HitboxSettings.oldBox(_, unpack(args)) end
        local opts={}
        if type(args[2])=="table" then for k,v in pairs(args[2]) do opts[k]=v end end
        opts.Size=Vector3.new(HitboxSettings.hitSize,HitboxSettings.hitSize,HitboxSettings.hitSize)
        args[2]=opts
        return HitboxSettings.oldBox(_, unpack(args))
    end
    return true
end

function disableHitbox()
    if not HitboxSettings.hitLib or not HitboxSettings.hitboxActive then return end
    HitboxSettings.hitboxActive=false; HitboxSettings.pendingEnable=false
    HitboxSettings.hitLib.Box = HitboxSettings.oldBox
end

-- =====================================================
-- [8] GOD MODE V2 (NPC + RANKED)
-- =====================================================
local GodModeNPC    = false
local GodModeRanked = false

task.spawn(function() task.wait(3)
    while true do
        if GodModeNPC then
            local cn = getCharName()
            local cf = RS.Characters:FindFirstChild(cn)
            local wc = cf and cf:FindFirstChild("WallCombo")
            if wc then
                for _, npcName in ipairs({"Attacking Bum","Blocking Bum","The Ultimate Bum"}) do
                    local npc = workspace.Characters.NPCs:FindFirstChild(npcName)
                    if npc then
                        local hl = {}; for i=1,50 do hl[i]=npc end
                        pcall(function()
                            RS.Remotes.Abilities.Ability:FireServer(wc,33036,nil,npc,Vector3.new(527.693,4.532,79.978))
                            RS.Remotes.Combat.Action:FireServer(wc,"Characters:"..cn..":WallCombo",1,33036,{HitboxCFrames={},BestHitCharacter=npc,HitCharacters=hl,Ignore={},DeathInfo={},Actions={},HitInfo={IsFacing=true,IsInFront=true},BlockedCharacters={},FromCFrame=CFrame.new(534.693,5.532,79.486)},"Action651",0)
                        end)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function() task.wait(3)
    while true do
        if GodModeRanked then
            local cn = getCharName()
            local cf = RS.Characters:FindFirstChild(cn)
            local wc = cf and cf:FindFirstChild("WallCombo")
            local char = LocalPlayer.Character
            if wc and char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                local closest, closestDist = nil, math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local tr = p.Character:FindFirstChild("HumanoidRootPart")
                        local th = p.Character:FindFirstChildOfClass("Humanoid")
                        if tr and th and (th:GetAttribute("Health") or th.Health) > 0 then
                            local d = (root.Position - tr.Position).Magnitude
                            if d < closestDist then closestDist=d; closest=p.Character end
                        end
                    end
                end
                if closest then
                    local hl={}; for i=1,50 do hl[i]=closest end
                    pcall(function()
                        RS.Remotes.Abilities.Ability:FireServer(wc,33036,nil,closest,Vector3.new(527.693,4.532,79.978))
                        RS.Remotes.Combat.Action:FireServer(wc,"Characters:"..cn..":WallCombo",1,33036,{HitboxCFrames={},BestHitCharacter=closest,HitCharacters=hl,Ignore={},DeathInfo={},Actions={},HitInfo={IsFacing=true,IsInFront=true},BlockedCharacters={},FromCFrame=CFrame.new(534.693,5.532,79.486)},"Action651",0)
                    end)
                end
            end
        end
        task.wait(0.1)
    end
end)

-- =====================================================
-- [9] ANTI-KILL
-- =====================================================
local AntiKillEnabled = false
task.spawn(function() task.wait(3)
    local lastHP = 100
    while true do
        if AntiKillEnabled then
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local hp   = hum and (hum:GetAttribute("Health") or hum.Health) or 100
            if hp < lastHP - 30 or hp <= 10 then
                local cn = getCharName()
                local cf = RS.Characters:FindFirstChild(cn)
                local wc = cf and cf:FindFirstChild("WallCombo")
                if wc and char then
                    local hl={}; for i=1,100 do hl[i]=char end
                    for _ = 1, 3 do
                        pcall(function()
                            RS.Remotes.Abilities.Ability:FireServer(wc,33036,nil,char,Vector3.new(527.693,4.532,79.978))
                            RS.Remotes.Combat.Action:FireServer(wc,"Characters:"..cn..":WallCombo",1,33036,{HitboxCFrames={},BestHitCharacter=char,HitCharacters=hl,Ignore={},DeathInfo={},Actions={},HitInfo={IsFacing=true,IsInFront=true},BlockedCharacters={},FromCFrame=CFrame.new(534.693,5.532,79.486)},"Action651",0)
                        end)
                    end
                end
            end
            lastHP = hp
        end
        task.wait()
    end
end)

-- =====================================================
-- [10] RANKED LAGGER V3
-- =====================================================
local RankedLagger = { Enabled=false, Threads={}, FriendOnly=false, Intensity=3, Session=0, BootstrapThread=nil }
local LagRemotes   = { Action=nil, Ability=nil, AbilityCanceled=nil, MobAbilities={}, ready=false }

task.spawn(function()
    pcall(function()
        local remotes = RS:WaitForChild("Remotes", 10); if not remotes then return end
        LagRemotes.Action          = remotes:WaitForChild("Combat"):WaitForChild("Action", 5)
        LagRemotes.Ability         = remotes:WaitForChild("Abilities"):WaitForChild("Ability", 5)
        LagRemotes.AbilityCanceled = remotes:WaitForChild("Abilities"):WaitForChild("AbilityCanceled", 5)
        local mob = RS:WaitForChild("Characters"):WaitForChild("Mob", 5)
        if mob then local ab=mob:FindFirstChild("Abilities"); if ab then for i=1,4 do LagRemotes.MobAbilities[i]=ab:FindFirstChild(tostring(i)) end end end
        LagRemotes.ready = true
    end)
end)

local function lagSpamAbility(abilityNum, targets)
    if not LagRemotes.ready then return end
    local ability = LagRemotes.MobAbilities[abilityNum]; if not ability then return end
    local actions = {377,380,383,384,385,387,389}
    for _, tc in ipairs(targets) do
        local hrp = tc:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        local targetCF = hrp.CFrame
        local tName = (Players:GetPlayerFromCharacter(tc) or {Name=tc.Name}).Name
        pcall(function()
            LagRemotes.AbilityCanceled:FireServer(ability)
            LagRemotes.Ability:FireServer(ability, 9000000)
            for i = 1, 7 do
                local data = {HitboxCFrames={targetCF,targetCF},BestHitCharacter=tc,HitCharacters={tc},Ignore=i>2 and {ActionNumber1={tc}} or {},DeathInfo={},BlockedCharacters={},HitInfo={IsFacing=not(i==1 or i==2),IsInFront=i<=2},ServerTime=tick(),Actions=i>2 and {ActionNumber1={}} or {},FromCFrame=targetCF}
                if i==7 then data.RockCFrame=targetCF; data.Actions={ActionNumber1={[tName]={StartCFrameStr=tostring(targetCF.X)..","..tostring(targetCF.Y)..","..tostring(targetCF.Z)..",0,0,0,0,0,0,0,0,0",ImpulseVelocity=Vector3.new(1901,-25000,291),AbilityName=tostring(abilityNum),RotVelocityStr="0,0,0",VelocityStr="1.9,0.01,0.29",Duration=2,RotImpulseVelocity=Vector3.new(5868,-6649,-7414),Seed=math.random(1,1e6),LookVectorStr="0.99,0,0.15"}}} end
                LagRemotes.Action:FireServer(ability,"Mob:Abilities:"..abilityNum,i,9000000,data,"Action"..actions[i],i==2 and 0.01 or nil)
                if i==3 or i==6 then task.wait() end
            end
        end)
    end
end

local function getLagTargets()
    local t={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer then continue end
        if RankedLagger.FriendOnly and LocalPlayer:IsFriendsWith(p.UserId) then continue end
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then table.insert(t, p.Character) end
    end
    pcall(function() for _,npc in ipairs(workspace.Characters.NPCs:GetChildren()) do if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then table.insert(t,npc) end end end)
    return t
end

local function startRankedLagger()
    RankedLagger.Session = (RankedLagger.Session or 0) + 1
    local currentSession = RankedLagger.Session

    RankedLagger.Enabled = true

    if RankedLagger.BootstrapThread then
        pcall(function() task.cancel(RankedLagger.BootstrapThread) end)
        RankedLagger.BootstrapThread = nil
    end

    for _, t in ipairs(RankedLagger.Threads) do
        pcall(function() task.cancel(t) end)
    end
    RankedLagger.Threads = {}
    RankedLagger._toggleAbility = false

    RankedLagger.BootstrapThread = task.spawn(function()
        local w = 0
        while currentSession == RankedLagger.Session and not LagRemotes.ready and w < 6 do
            task.wait(0.25)
            w = w + 0.25
        end

        if currentSession ~= RankedLagger.Session or not RankedLagger.Enabled then return end
        if not LagRemotes.ready then
            RankedLagger.Enabled = false
            return
        end

        pcall(function()
            if LocalPlayer.Data.Character.Value ~= "Mob" then
                MobRemote:FireServer("Mob")
            end
        end)

        task.wait(0.15)
        if currentSession ~= RankedLagger.Session or not RankedLagger.Enabled then return end

        if not LagRemotes.MobAbilities[4] then
            pcall(function()
                local mob = RS.Characters:FindFirstChild("Mob")
                local ab = mob and mob:FindFirstChild("Abilities")
                if ab then
                    for i = 1, 4 do
                        LagRemotes.MobAbilities[i] = ab:FindFirstChild(tostring(i))
                    end
                end
            end)
        end

        local function addThread(fn)
            table.insert(RankedLagger.Threads, task.spawn(function()
                while RankedLagger.Enabled and currentSession == RankedLagger.Session do
                    fn()
                end
            end))
        end

        addThread(function()
            pcall(function() lagSpamAbility(4, getLagTargets()) end)
            task.wait()
        end)
        addThread(function()
            pcall(function() lagSpamAbility(4, getLagTargets()) end)
            task.wait()
        end)
        addThread(function()
            pcall(function() lagSpamAbility(3, getLagTargets()) end)
            task.wait()
        end)
        addThread(function()
            pcall(function() lagSpamAbility(3, getLagTargets()) end)
            task.wait()
        end)

        if RankedLagger.Intensity >= 2 then
            addThread(function()
                RankedLagger._toggleAbility = not RankedLagger._toggleAbility
                pcall(function() lagSpamAbility(RankedLagger._toggleAbility and 1 or 2, getLagTargets()) end)
                task.wait(0.005)
            end)
            addThread(function()
                pcall(function()
                    if not LagRemotes.AbilityCanceled then return end
                    for i = 1, 4 do
                        local ab = LagRemotes.MobAbilities[i]
                        if ab then
                            LagRemotes.AbilityCanceled:FireServer(ab)
                        end
                    end
                end)
                task.wait(0.005)
            end)
        end

        if RankedLagger.Intensity >= 3 then
            addThread(function()
                pcall(function()
                    local mob = RS.Characters:FindFirstChild("Mob")
                    local wc = mob and mob:FindFirstChild("WallCombo")
                    if not wc then return end
                    for _, tc in ipairs(getLagTargets()) do
                        if not RankedLagger.Enabled or currentSession ~= RankedLagger.Session then break end
                        local hrp = tc:FindFirstChild("HumanoidRootPart")
                        if not hrp then continue end
                        LagRemotes.Ability:FireServer(wc, 9000000, nil, tc, hrp.Position)
                        LagRemotes.Action:FireServer(wc, "Mob:WallCombo", 1, 9000000, {
                            HitboxCFrames = {},
                            BestHitCharacter = tc,
                            HitCharacters = { tc },
                            Ignore = {},
                            DeathInfo = {},
                            Actions = {},
                            HitInfo = { IsFacing = true, IsInFront = true },
                            BlockedCharacters = {},
                            FromCFrame = hrp.CFrame
                        }, "Action651", 0)
                    end
                end)
                task.wait()
            end)
            addThread(function()
                pcall(function()
                    for _, tc in ipairs(getLagTargets()) do
                        if not RankedLagger.Enabled or currentSession ~= RankedLagger.Session then break end
                        for i = 1, 4 do
                            local ab = LagRemotes.MobAbilities[i]
                            if ab then
                                LagRemotes.Ability:FireServer(ab, 9000000)
                            end
                        end
                    end
                end)
                task.wait()
            end)
        end
    end)
end

local function stopRankedLagger()
    RankedLagger.Enabled = false
    RankedLagger.Session = (RankedLagger.Session or 0) + 1

    if RankedLagger.BootstrapThread then
        pcall(function() task.cancel(RankedLagger.BootstrapThread) end)
        RankedLagger.BootstrapThread = nil
    end

    for _, t in ipairs(RankedLagger.Threads) do
        pcall(function() task.cancel(t) end)
    end
    RankedLagger.Threads = {}

    pcall(function()
        if not LagRemotes.AbilityCanceled then return end
        for i = 1, 4 do
            local ab = LagRemotes.MobAbilities[i]
            if ab then
                LagRemotes.AbilityCanceled:FireServer(ab)
            end
        end
    end)
end

-- =====================================================
-- [11] ANTI-HACK
-- =====================================================
local AntiHack = { SafetyShield=false, AntiWallCombo=false, SafetyThread=nil, AntiKAThread=nil, HookConn=nil, OriginalNc=nil }

local function startSafetyShield()
    AntiHack.SafetyThread = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character; if not char then return end
        pcall(function() char:SetAttribute("Safety", true) end)
    end)
end
local function stopSafetyShield()
    if AntiHack.SafetyThread then AntiHack.SafetyThread:Disconnect(); AntiHack.SafetyThread=nil end
    pcall(function() if LocalPlayer.Character then LocalPlayer.Character:SetAttribute("Safety",false) end end)
end

local function startAntiWallComboHook()
    if AntiHack.HookConn then return end
    pcall(function()
        if not getrawmetatable or not setreadonly or not newcclosure then return end
        local mt = getrawmetatable(game); if not mt then return end
        setreadonly(mt, false)
        local orig = mt.__namecall; AntiHack.OriginalNc = orig
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" then
                local ok, rname = pcall(function() return self.Name end)
                if ok and rname == "Action" then
                    local args = {...}; local data = args[5]
                    if type(data) == "table" then
                        local myChar = LocalPlayer.Character
                        local hits = data.HitCharacters
                        if myChar and type(hits) == "table" then
                            for _, v in ipairs(hits) do if v == myChar then return end end
                        end
                    end
                end
            end
            return orig(self, ...)
        end)
        setreadonly(mt, true)
        AntiHack.HookConn = true
    end)
end
local function stopAntiWallComboHook()
    if not AntiHack.HookConn then return end
    pcall(function()
        if not getrawmetatable or not setreadonly then return end
        local mt = getrawmetatable(game); setreadonly(mt,false); mt.__namecall=AntiHack.OriginalNc; setreadonly(mt,true)
    end)
    AntiHack.HookConn=nil; AntiHack.OriginalNc=nil
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if AntiHack.SafetyShield then stopSafetyShield(); startSafetyShield() end
end)

-- =====================================================
-- [12] ABILITY SPAM
-- =====================================================
local AbilitySpamCustom = { enabled=false, thread=nil, abilityNum="1", ignoreAllies=false }

local function spamCustomAbility()
    local charName = getCharName()
    local charFolder = RS.Characters:FindFirstChild(charName); if not charFolder then return end
    local abFolder = charFolder:FindFirstChild("Abilities"); if not abFolder then return end
    local ability = abFolder:FindFirstChild(AbilitySpamCustom.abilityNum); if not ability then return end
    local myChar = LocalPlayer.Character; local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local closest, closestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if AbilitySpamCustom.ignoreAllies and LocalPlayer:IsFriendsWith(p.UserId) then continue end
            local d = (myHRP.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < closestDist then closestDist=d; closest=p.Character end
        end
    end
    pcall(function()
        local npcs=workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild("NPCs")
        if npcs then for _,npc in pairs(npcs:GetChildren()) do if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then local d=(myHRP.Position-npc.HumanoidRootPart.Position).Magnitude; if d<closestDist then closestDist=d;closest=npc end end end end
    end)
    if not closest then return end
    local targetCF = closest.HumanoidRootPart.CFrame
    local targetName = (Players:GetPlayerFromCharacter(closest) or {Name=closest.Name}).Name
    pcall(function()
        local actions={377,380,383,384,385,387,389}
        RS.Remotes.Abilities.AbilityCanceled:FireServer(ability)
        RS.Remotes.Abilities.Ability:FireServer(ability, 9000000)
        for i=1,7 do
            local args={ability,charName..":Abilities:"..AbilitySpamCustom.abilityNum,i,9000000,{HitboxCFrames={targetCF,targetCF},BestHitCharacter=closest,HitCharacters={closest},Ignore=i>2 and {ActionNumber1={closest}} or {},DeathInfo={},BlockedCharacters={},HitInfo={IsFacing=not(i==1 or i==2),IsInFront=i<=2},ServerTime=tick(),Actions=i>2 and {ActionNumber1={}} or {},FromCFrame=targetCF},"Action"..actions[i],i==2 and 0.1 or nil}
            if i==7 then args[5].RockCFrame=targetCF; args[5].Actions={ActionNumber1={[targetName]={StartCFrameStr=tostring(targetCF.X)..","..tostring(targetCF.Y)..","..tostring(targetCF.Z)..",0,0,0,0,0,0,0,0,0",ImpulseVelocity=Vector3.new(1901,-25000,291),AbilityName=AbilitySpamCustom.abilityNum,RotVelocityStr="0,0,0",VelocityStr="1.9,0.01,0.29",Duration=2,RotImpulseVelocity=Vector3.new(5868,-6649,-7414),Seed=math.random(1,1e6),LookVectorStr="0.99,0,0.15"}}} end
            RS.Remotes.Combat.Action:FireServer(unpack(args))
        end
    end)
end

-- AbilitySpam (Kill Mob)
local AbilitySpam = { enabled=false, connection=nil, ignoreAllies=false }
function AbilitySpam:Start()
    if self.connection then return end; self.enabled=true
    self.connection = task.spawn(function()
        pcall(function() if LocalPlayer.Data.Character.Value~="Mob" then MobRemote:FireServer("Mob"); task.wait(1) end end)
        while self.enabled do
            local charName="Mob"; local charFolder=RS.Characters:FindFirstChild(charName)
            local abFolder=charFolder and charFolder:FindFirstChild("Abilities")
            local ab4=abFolder and abFolder:FindFirstChild("4")
            if ab4 then
                local t=nil; local myChar=LocalPlayer.Character; local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    local d=math.huge
                    for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then if self.ignoreAllies and LocalPlayer:IsFriendsWith(p.UserId) then continue end local tr=p.Character:FindFirstChild("HumanoidRootPart") local th=p.Character:FindFirstChildOfClass("Humanoid") if tr and th and (th:GetAttribute("Health") or th.Health)>0 then local dd=(myHRP.Position-tr.Position).Magnitude; if dd<d then d=dd;t=p.Character end end end end
                end
                if t and t:FindFirstChild("HumanoidRootPart") then
                    local targetCF=t.HumanoidRootPart.CFrame; local tp=Players:GetPlayerFromCharacter(t); local tName=(tp and tp.Name) or t.Name
                    pcall(function()
                        local actions={377,380,383,384,385,387,389}
                        RS.Remotes.Abilities.AbilityCanceled:FireServer(ab4)
                        RS.Remotes.Abilities.Ability:FireServer(ab4, 9000000)
                        for i=1,7 do
                            local data={HitboxCFrames={targetCF,targetCF},BestHitCharacter=t,HitCharacters={t},Ignore=i>2 and {ActionNumber1={t}} or {},DeathInfo={},BlockedCharacters={},HitInfo={IsFacing=not(i==1 or i==2),IsInFront=i<=2},ServerTime=tick(),Actions=i>2 and {ActionNumber1={}} or {},FromCFrame=targetCF}
                            if i==7 then data.RockCFrame=targetCF; data.Actions={ActionNumber1={[tName]={StartCFrameStr=tostring(targetCF.X)..","..tostring(targetCF.Y)..","..tostring(targetCF.Z)..",0,0,0,0,0,0,0,0,0",ImpulseVelocity=Vector3.new(1901,-25000,291),AbilityName="4",RotVelocityStr="0,0,0",VelocityStr="1.9,0.01,0.29",Duration=2,RotImpulseVelocity=Vector3.new(5868,-6649,-7414),Seed=math.random(1,1e6),LookVectorStr="0.99,0,0.15"}}} end
                            RS.Remotes.Combat.Action:FireServer(ab4,"Mob:Abilities:4",i,9000000,data,"Action"..actions[i],i==2 and 0.01 or nil)
                        end
                    end)
                end
            end
            task.wait(0.05)
        end
    end)
end
function AbilitySpam:Stop() self.enabled=false; if self.connection then pcall(function() task.cancel(self.connection) end); self.connection=nil end end

-- =====================================================
-- [13] DASH ANTI KNOCKBACK
-- Detecta velocidad alta (knockback) y la cancela
-- =====================================================
local DashAntiKB = { Enabled=false, Conn=nil, Cooldown=false }
local function startDashAntiKB()
    if DashAntiKB.Conn then return end
    DashAntiKB.Conn = RunService.Heartbeat:Connect(function()
        if not DashAntiKB.Enabled or DashAntiKB.Cooldown then return end
        local char = LocalPlayer.Character; if not char then return end
        local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local vel  = hrp.AssemblyLinearVelocity
        local hspeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
        if hspeed > 50 or math.abs(vel.Y) > 80 then
            DashAntiKB.Cooldown = true
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.new(0, math.min(vel.Y, 5), 0)
            end)
            task.delay(0.2, function() DashAntiKB.Cooldown = false end)
        end
    end)
end
local function stopDashAntiKB()
    DashAntiKB.Enabled = false
    if DashAntiKB.Conn then DashAntiKB.Conn:Disconnect(); DashAntiKB.Conn = nil end
    DashAntiKB.Cooldown = false
end

-- =====================================================
-- [14] TP WALK
-- =====================================================
local tpwalkActive2 = false
local tpwalkSpeed2  = 0
do
    local tpChr, tpHum
    local function onChar(ch) tpChr=ch; tpHum=ch:WaitForChild("Humanoid") end
    if LocalPlayer.Character then onChar(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(onChar)
    task.spawn(function()
        local hb = RunService.Heartbeat
        while true do
            local delta = hb:Wait()
            if tpwalkActive2 and tpwalkSpeed2>0 and tpChr and tpHum and tpHum.Parent then
                if tpHum.MoveDirection.Magnitude>0 then
                    tpChr:TranslateBy(tpHum.MoveDirection * tpwalkSpeed2 * delta)
                end
            end
        end
    end)
end

-- =====================================================
-- [15] AIMBOT
-- =====================================================
local AimbotConfig = { Enabled=false, Prediction=0.12, Smoothness=0.25, VertOffset=-2, FOV=999 }
local AimbotTarget = nil
local AimbotLocked = false

-- =====================================================
-- [16] ESP
-- =====================================================
local RagdollESPEnabled = false
local EvasiveESPEnabled = false
local ragdollESPData={}
local evasiveESPData={}
local evasiveCooldowns={}
local evasiveStates={}
local ragdollRenderConn, evasiveRenderConn, ragdollAddedConn, ragdollRemovingConn, evasiveAddedConn, evasiveRemovingConn = nil,nil,nil,nil,nil,nil

local CONFIG_RAGDOLL={TextSize=15,TextFont=3,TextOutline=true,ColorHigh=Color3.fromRGB(0,255,100),ColorMid=Color3.fromRGB(255,200,0),ColorLow=Color3.fromRGB(255,50,50),OutlineColor=Color3.new(0,0,0),OffsetY=3.5}
local CONFIG_EVASIVE={TextSize=20,Font=3,Outline=true,ColorReady=Color3.fromRGB(100,200,255),ColorCooldown=Color3.fromRGB(255,100,255),OutlineColor=Color3.new(0,0,0),OffsetY=5.5}
local EVASIVE_BASE=25

local function getColorFromProgress(p) if p>0.5 then return CONFIG_RAGDOLL.ColorMid:Lerp(CONFIG_RAGDOLL.ColorHigh,(p-0.5)*2) else return CONFIG_RAGDOLL.ColorLow:Lerp(CONFIG_RAGDOLL.ColorMid,p*2) end end
local function createRagdollESP(player) if player==LocalPlayer then return end; local text=Drawing.new("Text"); text.Center=true;text.Size=CONFIG_RAGDOLL.TextSize;text.Outline=CONFIG_RAGDOLL.TextOutline;text.OutlineColor=CONFIG_RAGDOLL.OutlineColor;text.Font=CONFIG_RAGDOLL.TextFont;text.Visible=false; ragdollESPData[player]={Text=text} end
local function removeRagdollESP(player) local d=ragdollESPData[player]; if d then d.Text:Remove();ragdollESPData[player]=nil end end
local function startRagdollESP()
    for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then createRagdollESP(p) end end
    ragdollAddedConn=Players.PlayerAdded:Connect(createRagdollESP)
    ragdollRemovingConn=Players.PlayerRemoving:Connect(removeRagdollESP)
    ragdollRenderConn=RunService.RenderStepped:Connect(function()
        for player,data in pairs(ragdollESPData) do
            local char=player.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp and typeof(char:GetAttribute("Ragdoll"))=="number" then
                local sp,on=workspace.CurrentCamera:WorldToViewportPoint(hrp.Position+Vector3.new(0,CONFIG_RAGDOLL.OffsetY,0))
                if on then data.Text.Text="RAGDOLL";data.Text.Color=CONFIG_RAGDOLL.ColorHigh;data.Text.Position=Vector2.new(sp.X,sp.Y);data.Text.Visible=true
                else data.Text.Visible=false end
            else data.Text.Visible=false end
        end
    end)
end
local function stopRagdollESP()
    if ragdollRenderConn then ragdollRenderConn:Disconnect();ragdollRenderConn=nil end
    if ragdollAddedConn  then ragdollAddedConn:Disconnect();ragdollAddedConn=nil end
    if ragdollRemovingConn then ragdollRemovingConn:Disconnect();ragdollRemovingConn=nil end
    for p in pairs(ragdollESPData) do removeRagdollESP(p) end
end

local function getEvasiveMultiplier() local settings=RS:FindFirstChild("Settings"); if not settings then return 1 end; local cds=settings:FindFirstChild("Cooldowns"); if not cds then return 1 end; local v=cds:FindFirstChild("Evasive") or cds:FindFirstChild("Ragdoll"); return (v and v.Value/100) or 1 end
local function startEvasiveCooldown(player) evasiveCooldowns[player]={start=os.clock(),duration=EVASIVE_BASE*getEvasiveMultiplier()} end
local function getEvasiveRemaining(player) local d=evasiveCooldowns[player]; if not d then return 0 end; local t=d.duration-(os.clock()-d.start); if t<=0 then evasiveCooldowns[player]=nil;return 0 end; return t end
local function monitorEvasivePlayer(player)
    evasiveStates[player]={wasRagdoll=false,wasDash=false}
    local function onChar(char)
        local function update()
            local ragdoll=char:GetAttribute("Ragdoll"); local dash=char:GetAttribute("Dash"); local s=evasiveStates[player]; if not s then return end
            if s.wasRagdoll and dash and not s.wasDash then startEvasiveCooldown(player) end
            s.wasRagdoll=ragdoll;s.wasDash=dash
        end
        char:GetAttributeChangedSignal("Ragdoll"):Connect(update); char:GetAttributeChangedSignal("Dash"):Connect(update); update()
    end
    if player.Character then onChar(player.Character) end; player.CharacterAdded:Connect(onChar)
end
local function createEvasiveESP(player) local text=Drawing.new("Text"); text.Center=true;text.Size=CONFIG_EVASIVE.TextSize;text.Font=CONFIG_EVASIVE.Font;text.Outline=CONFIG_EVASIVE.Outline;text.OutlineColor=CONFIG_EVASIVE.OutlineColor;text.Visible=false; evasiveESPData[player]={Text=text} end
local function removeEvasiveESP(player) local d=evasiveESPData[player]; if d then d.Text:Remove();evasiveESPData[player]=nil end; evasiveCooldowns[player]=nil;evasiveStates[player]=nil end
local function startEvasiveESP()
    for _,p in pairs(Players:GetPlayers()) do monitorEvasivePlayer(p);createEvasiveESP(p) end
    evasiveAddedConn=Players.PlayerAdded:Connect(function(p) monitorEvasivePlayer(p);createEvasiveESP(p) end)
    evasiveRemovingConn=Players.PlayerRemoving:Connect(removeEvasiveESP)
    evasiveRenderConn=RunService.RenderStepped:Connect(function()
        for player,ui in pairs(evasiveESPData) do
            local char=player.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then ui.Text.Visible=false;continue end
            local remaining=getEvasiveRemaining(player)
            local sp,on=workspace.CurrentCamera:WorldToViewportPoint(hrp.Position+Vector3.new(0,CONFIG_EVASIVE.OffsetY,0))
            if not on then ui.Text.Visible=false;continue end
            ui.Text.Text=remaining>0 and string.format("%.1fs",remaining) or "EVASIVE: READY"
            ui.Text.Color=remaining>0 and CONFIG_EVASIVE.ColorCooldown or CONFIG_EVASIVE.ColorReady
            ui.Text.Position=Vector2.new(sp.X,sp.Y);ui.Text.Visible=true
        end
    end)
end
local function stopEvasiveESP()
    if evasiveRenderConn then evasiveRenderConn:Disconnect();evasiveRenderConn=nil end
    if evasiveAddedConn  then evasiveAddedConn:Disconnect();evasiveAddedConn=nil end
    if evasiveRemovingConn then evasiveRemovingConn:Disconnect();evasiveRemovingConn=nil end
    for p in pairs(evasiveESPData) do removeEvasiveESP(p) end
end

-- =====================================================
-- [17] MISC FUNCTIONS
-- =====================================================
local InstantRespawnEnabled = false
local AutoResetEnabled      = false
local RespawnAtDeathEnabled = false
local deathPosition         = nil
local AntiGrabEnabled       = false
local antiGrabThread        = nil
local AntiLagEnabled        = false
local antiLagThread         = nil

local function resetCharacterForced()
    local character=LocalPlayer.Character; if not character then return end
    local humanoid=character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Dead) else character:BreakJoints() end
end

local function startAntiGrab()
    if antiGrabThread then return end
    antiGrabThread = task.spawn(function()
        while AntiGrabEnabled do
            pcall(function()
                local char=LocalPlayer.Character; if not char then return end
                local grabbed=char:GetAttribute("Grabbed")
                if grabbed and grabbed~="" and grabbed~=LocalPlayer.Name then
                    if RemoteCache.DashRemote then RemoteCache.DashRemote:FireServer() end
                    pcall(function() char:SetAttribute("Grabbed",nil) end)
                end
            end)
            task.wait(0.05)
        end
    end)
end
local function stopAntiGrab()
    AntiGrabEnabled=false
    if antiGrabThread then pcall(function() task.cancel(antiGrabThread) end); antiGrabThread=nil end
end

local function enableAntiLag()
    if antiLagThread then return end
    antiLagThread = task.spawn(function()
        while AntiLagEnabled do
            pcall(function()
                for _,obj in ipairs(workspace:GetDescendants()) do
                    if not AntiLagEnabled then break end
                    local t=obj.ClassName
                    if t=="Script" or t=="LocalScript" then pcall(function() obj:Destroy() end)
                    elseif t=="Sound" then pcall(function() obj.Volume=0;obj:Stop() end) end
                end
            end)
            task.wait(1)
        end
    end)
end
local function disableAntiLag()
    AntiLagEnabled=false
    if antiLagThread then pcall(function() task.cancel(antiLagThread) end); antiLagThread=nil end
end

local function monitorHumanoid(humanoid)
    if not humanoid then return end
    humanoid:GetAttributeChangedSignal("Health"):Connect(function()
        local health=humanoid:GetAttribute("Health"); if not health or health>0 then return end
        if AutoResetEnabled then resetCharacterForced() end
        if RespawnAtDeathEnabled then
            local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then deathPosition=hrp.CFrame end
        end
        if InstantRespawnEnabled then task.spawn(function() task.wait(); pcall(function() LocalPlayer:LoadCharacter() end) end) end
    end)
end
local function connectCharacter(character)
    local humanoid=character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then monitorHumanoid(humanoid) end
    if RespawnAtDeathEnabled and deathPosition then
        task.spawn(function() local hrp=character:WaitForChild("HumanoidRootPart"); task.wait(0.2); hrp.CFrame=deathPosition end)
    end
end
if LocalPlayer.Character then connectCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(connectCharacter)

-- Farm helpers
local function getPlayerList()
    local list={}
    for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(list,p.Name) end end
    if #list==0 then table.insert(list,"(ninguno)") end
    return list
end
local function getPlayerByName(name)
    for _,p in ipairs(Players:GetPlayers()) do if p.Name==name then return p end end
end
local function teleportExact(player)
    if not player or not player.Character then return end
    local tHRP=player.Character:FindFirstChild("HumanoidRootPart")
    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP or not myHRP then return end
    myHRP.CFrame=tHRP.CFrame;myHRP.AssemblyLinearVelocity=Vector3.zero;myHRP.AssemblyAngularVelocity=Vector3.zero
end

-- Emotes
local EmotesConfg = { isSpammingRandomKillEmote=false, isSpammingSelectedKillEmote=false, selectedKillEmoteForSpam="None", randomSpamDelay=0.05, selectedSpamDelay=0.05 }
local SelectedKillEmote="None"; local SelectedKillEmoteSlot=1
local SelectedAccessory="None"; local SelectedAura="None"; local SelectedCape="None"

local function ApplyCosmetic(cosmeticType)
    local selectedItem = cosmeticType=="Accessories" and SelectedAccessory or cosmeticType=="Auras" and SelectedAura or SelectedCape
    if selectedItem=="None" then selectedItem=nil end
    local dataFolder=LocalPlayer:WaitForChild("Data"); local valueName=cosmeticType.."Equipped"
    local valueObject=dataFolder:FindFirstChild(valueName)
    if not valueObject then valueObject=Instance.new("StringValue");valueObject.Name=valueName;valueObject.Parent=dataFolder end
    valueObject.Value=HttpService:JSONEncode(selectedItem and {selectedItem} or {})
end

local function useKillEmote(emoteName)
    if not emoteName or emoteName=="None" then return end
    local emoteModule=RS.Cosmetics.KillEmote:FindFirstChild(emoteName); if not emoteModule then return end
    local Character=LocalPlayer.Character; if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local closestTarget,closestDist=nil,math.huge
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LocalPlayer and player.Character then
            local tr=player.Character:FindFirstChild("HumanoidRootPart")
            if tr then local d=(Character.HumanoidRootPart.Position-tr.Position).Magnitude; if d<closestDist then closestDist=d;closestTarget=player.Character end end
        end
    end
    if closestTarget then
        task.spawn(function()
            _G.KillEmote=true
            pcall(function()
                pcall(function() setthreadidentity(2) end)
                if Core then Core.Get("Combat","Ability").Activate(emoteModule,closestTarget) end
            end)
            _G.KillEmote=false
        end)
    end
end
local function useRandomKillEmote()
    local list={}
    pcall(function() for _,e in pairs(RS.Cosmetics.KillEmote:GetChildren()) do table.insert(list,e.Name) end end)
    if #list>0 then useKillEmote(list[math.random(1,#list)]) end
end

RunService.Heartbeat:Connect(function()
    local now=tick()
    if EmotesConfg.isSpammingRandomKillEmote and now-((EmotesConfg._lastRandom or 0))>=EmotesConfg.randomSpamDelay then
        useRandomKillEmote();EmotesConfg._lastRandom=now
    end
    if EmotesConfg.isSpammingSelectedKillEmote and EmotesConfg.selectedKillEmoteForSpam~="None" and now-((EmotesConfg._lastSelected or 0))>=EmotesConfg.selectedSpamDelay then
        useKillEmote(EmotesConfg.selectedKillEmoteForSpam);EmotesConfg._lastSelected=now
    end
    if AutoClaimEmote then pcall(function() RS.Remotes.Combat.EmoteClaim:FireServer() end) end
end)



-- =====================================================
-- KZ MODULES
-- =====================================================
if not _G.KZ_GodModeModules then _G.KZ_GodModeModules = {} end
if not _G.KZ_AntiGodModules  then _G.KZ_AntiGodModules  = {} end
if not _G.KZ_LagModules       then _G.KZ_LagModules       = {} end
if not _G.KZ_ExploitModules   then _G.KZ_ExploitModules   = {} end
if not _G.KZ_ExploitConfig    then _G.KZ_ExploitConfig    = {} end

if not _G.KZ_GodModeModules then _G.KZ_GodModeModules = {} end

_G.KZ_GodModeModules.GodModeV3 = {
    enabled = false,
    taskClosest = nil,
    taskSelf = nil,
    delayClosest = 0.03,
    delaySelf = 0.01
}

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- GET CLOSEST PLAYER
-- =========================
function _G.KZ_GodModeModules.GodModeV3:GetClosestPlayer()
    local closest
    local shortest = math.huge
    local lpChar = LocalPlayer.Character
    local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    if not lpHRP then return nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local dist = (hrp.Position - lpHRP.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- =========================
-- LOOP 1: Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚ÂNH PLAYER GÃƒÂ¡Ã‚ÂºÃ‚Â¦N NHÃƒÂ¡Ã‚ÂºÃ‚Â¤T
-- =========================
function _G.KZ_GodModeModules.GodModeV3:LoopClosest()
    while self.enabled do
        task.wait(self.delayClosest)

        local target = self:GetClosestPlayer()
        if target and target.Character and LocalPlayer.Character then
            pcall(function()
                ReplicatedStorage.Remotes.Abilities.Ability:FireServer(
                    ReplicatedStorage.Characters.Gon.WallCombo,
                    33036,
                    nil,
                    target.Character,
                    target.Character.HumanoidRootPart.Position
                )

                ReplicatedStorage.Remotes.Combat.Action:FireServer(
                    ReplicatedStorage.Characters.Gon.WallCombo,
                    "Characters:Gon:WallCombo",
                    1,
                    33036,
                    {
                        HitboxCFrames = {},
                        BestHitCharacter = target.Character,
                        HitCharacters = {target.Character},
                        Ignore = {},
                        DeathInfo = {},
                        Actions = {},
                        HitInfo = {IsFacing = true, IsInFront = true},
                        BlockedCharacters = {},
                        ServerTime = os.clock(),
                        FromCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    },
                    "Action651",
                    0
                )
            end)
        end
    end
end

-- =========================
-- LOOP 2: SELF WALL COMBO
-- =========================
function _G.KZ_GodModeModules.GodModeV3:LoopSelf()
    while self.enabled do
        task.wait(self.delaySelf)

        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end

            local data = LocalPlayer:FindFirstChild("Data")
            local charName = data and data:FindFirstChild("Character") and data.Character.Value
            if not charName then return end

            local wallCombo = ReplicatedStorage.Characters
                :FindFirstChild(charName)
                :FindFirstChild("WallCombo")

            if not wallCombo then return end

            local actionId = "Action" .. math.random(1000,9999)
            local randomId = math.random(100000,999999)

            ReplicatedStorage.Remotes.Abilities.Ability:FireServer(
                wallCombo,
                randomId
            )

            ReplicatedStorage.Remotes.Combat.Action:FireServer(
                wallCombo,
                "Characters:" .. charName .. ":WallCombo",
                1,
                randomId,
                {
                    HitboxCFrames = {nil},
                    BestHitCharacter = char,
                    HitCharacters = {char},
                    Ignore = {[actionId] = {char}},
                    DeathInfo = {},
                    Actions = {[actionId] = {}},
                    HitInfo = {Blocked = false, IsFacing = true, IsInFront = true},
                    BlockedCharacters = {},
                    ServerTime = tick(),
                    FromCFrame = nil
                },
                actionId
            )
        end)
    end
end

-- =========================
-- START GOD MODE V3
-- =========================
function _G.KZ_GodModeModules.GodModeV3:Start()
    if self.enabled then return end
    
    self.enabled = true
    
    -- Start both loops
    self.taskClosest = task.spawn(function()
        self:LoopClosest()
    end)
    
    self.taskSelf = task.spawn(function()
        self:LoopSelf()
    end)
    
    print("God Mode V3: ON")
    Library:Notify("God Mode V3: Activated", 3)
end

-- =========================
-- STOP GOD MODE V3
-- =========================
function _G.KZ_GodModeModules.GodModeV3:Stop()
    if not self.enabled then return end
    
    self.enabled = false
    
    -- Cancel tasks
    if self.taskClosest then
        task.cancel(self.taskClosest)
        self.taskClosest = nil
    end
    
    if self.taskSelf then
        task.cancel(self.taskSelf)
        self.taskSelf = nil
    end
    
    print("God Mode V3: OFF")
    Library:Notify("God Mode V3: Deactivated", 3)
end

-- =========================
-- =====================================================
-- KZ STUCK MODE + TARGET LOCK
-- =====================================================
if not _G.KZ_EmoteStuckModules then _G.KZ_EmoteStuckModules = {} end

_G.KZ_EmoteStuckModules.StuckMode = {
    HitboxToggle = false,
    HitboxX = 50,  -- Size mÃƒÂ¡Ã‚ÂºÃ‚Â·c Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹nh 50
    HitboxY = 50,  -- Size mÃƒÂ¡Ã‚ÂºÃ‚Â·c Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹nh 50
    HitboxZ = 50,  -- Size mÃƒÂ¡Ã‚ÂºÃ‚Â·c Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹nh 50
    EnhancerToggle = false,
    EnhancerMultiplier = 5,
    DashMethod = false,
    BasicHitbox = false,
    BasicSize = 18
}

-- BIÃƒÂ¡Ã‚ÂºÃ‚Â¾N GLOBAL
_G.KZ_EmoteStuckModules.HitboxCache = {
    OriginalBox = nil,
    OriginalProcess = nil,
    DashConnection = nil,
    LastDash = 0,
    BasicOriginal = nil
}

-- BIÃƒÂ¡Ã‚ÂºÃ‚Â¾N GLOBAL
_G.KZ_EmoteStuckModules.HitboxEnabled = false

local function HRP()
    return localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- HÃƒÆ’Ã‚Â m toggle hitbox
local function toggleHitbox(state)
    _G.KZ_EmoteStuckModules.HitboxEnabled = state
    _G.KZ_EmoteStuckModules.StuckMode.HitboxToggle = state

    local ok, core = pcall(function()
        return require(RS:WaitForChild("Core"))
    end)
    if not ok then return end

    local hit = core.Get and core.Get("Combat", "Hit")
    if not hit or not hit.Box then return end

    if state then
        if not _G.KZ_EmoteStuckModules.HitboxCache.OriginalBox then 
            _G.KZ_EmoteStuckModules.HitboxCache.OriginalBox = hit.Box 
        end
        hit.Box = function(_, char, data)
            data = data or {}
            data.Size = Vector3.new(
                _G.KZ_EmoteStuckModules.StuckMode.HitboxX, 
                _G.KZ_EmoteStuckModules.StuckMode.HitboxY, 
                _G.KZ_EmoteStuckModules.StuckMode.HitboxZ
            )
            return _G.KZ_EmoteStuckModules.HitboxCache.OriginalBox(nil, char, data)
        end
    else
        if _G.KZ_EmoteStuckModules.HitboxCache.OriginalBox then
            hit.Box = _G.KZ_EmoteStuckModules.HitboxCache.OriginalBox
        end
    end
end

-- HÃƒÆ’Ã‚Â m dash vÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºi cooldown
local DASH_CD = 0.18
local function dash()
    if tick() - _G.KZ_EmoteStuckModules.HitboxCache.LastDash < DASH_CD then return end
    _G.KZ_EmoteStuckModules.HitboxCache.LastDash = tick()

    local hrp = HRP()
    if hrp then
        pcall(function()
            require(RS.Core)
                .Library("Remote")
                .Send("Dash", hrp.CFrame, "L", 1)
        end)
    end
end

-- HÃƒÆ’Ã‚Â m bÃƒÂ¡Ã‚ÂºÃ‚Â­t/tÃƒÂ¡Ã‚ÂºÃ‚Â¯t enhancer
local function toggleEnhancer(state)
    _G.KZ_EmoteStuckModules.StuckMode.EnhancerToggle = state
    
    local ok, hit = pcall(function()
        return require(localPlayer.PlayerScripts.Combat.Hit)
    end)
    if not ok or not hit.Process then return end

    if state then
        if not _G.KZ_EmoteStuckModules.HitboxCache.OriginalProcess then
            _G.KZ_EmoteStuckModules.HitboxCache.OriginalProcess = hit.Process
        end
        hit.Process = function(...)
            local best, targets, blocked = _G.KZ_EmoteStuckModules.HitboxCache.OriginalProcess(...)
            if targets and #targets > 0 then
                dash()
                for i = 1, _G.KZ_EmoteStuckModules.StuckMode.EnhancerMultiplier do
                    RS.Remotes.Combat.Action:FireServer(
                        nil, "", 4, 69,
                        {BestHitCharacter=nil, HitCharacters=targets, Ignore={}, Actions={}}
                    )
                end
            end
            return best, targets, blocked
        end
    else
        if _G.KZ_EmoteStuckModules.HitboxCache.OriginalProcess then
            hit.Process = _G.KZ_EmoteStuckModules.HitboxCache.OriginalProcess
        end
    end
end

-- HÃƒÆ’Ã‚Â m bÃƒÂ¡Ã‚ÂºÃ‚Â­t/tÃƒÂ¡Ã‚ÂºÃ‚Â¯t dash method
local function toggleDashMethod(state)
    _G.KZ_EmoteStuckModules.StuckMode.DashMethod = state
    
    if state then
        if _G.KZ_EmoteStuckModules.HitboxCache.DashConnection then return end
        _G.KZ_EmoteStuckModules.HitboxCache.DashConnection = RunService.Heartbeat:Connect(function()
            local hrp = HRP()
            if hrp then
                pcall(function()
                    require(RS.Core)
                        .Library("Remote")
                        .Send("Dash", hrp.CFrame, "L", 1)
                end)
            end
        end)
    else
        if _G.KZ_EmoteStuckModules.HitboxCache.DashConnection then
            _G.KZ_EmoteStuckModules.HitboxCache.DashConnection:Disconnect()
            _G.KZ_EmoteStuckModules.HitboxCache.DashConnection = nil
        end
    end
end

-- ThÃƒÆ’Ã‚Âªm GroupBox cho Stuck Mode trong tab Emote Spam bÃƒÆ’Ã‚Âªn phÃƒÂ¡Ã‚ÂºÃ‚Â£i


local BEHIND_DISTANCE = 5
local followEnabled = false
local circleEnabled = false
local lookEnabled = false
local selectedTargetName = nil
local followConnection, circleConnection, lookConnection
local circleRadius, circleSpeed, circleAngle = 6, 13, 0

local function getHRP(plr)
    return plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerByName(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name == name then return p end
    end
end

local function startFollow()
    followConnection = RunService.RenderStepped:Connect(function()
        if not followEnabled then return end
        local my = getHRP(localPlayer)
        local t = getHRP(getPlayerByName(selectedTargetName))
        if my and t then
            local pos = t.Position - t.CFrame.LookVector * BEHIND_DISTANCE
            my.CFrame = CFrame.new(pos.X, t.Position.Y, pos.Z)
        end
    end)
end

local function startCircle()
    circleConnection = RunService.RenderStepped:Connect(function(dt)
        if not circleEnabled then return end
        local my = getHRP(localPlayer)
        local t = getHRP(getPlayerByName(selectedTargetName))
        if my and t then
            circleAngle = circleAngle + circleSpeed * dt
            local x = math.cos(circleAngle) * circleRadius
            local z = math.sin(circleAngle) * circleRadius
            my.CFrame = CFrame.new(t.Position.X + x, t.Position.Y, t.Position.Z + z)
        end
    end)
end

local function startLook()
    lookConnection = RunService.RenderStepped:Connect(function()
        if not lookEnabled then return end
        local my = getHRP(localPlayer)
        local t = getHRP(getPlayerByName(selectedTargetName))
        if my and t then
            my.CFrame = CFrame.new(my.Position, Vector3.new(t.Position.X, my.Position.Y, t.Position.Z))
        end
    end)
end

local function stopConnections()
    if followConnection then followConnection:Disconnect() end
    if circleConnection then circleConnection:Disconnect() end
    if lookConnection then lookConnection:Disconnect() end
    followConnection, circleConnection, lookConnection = nil, nil, nil
    circleAngle = 0
end

local function updatePlayerListForTarget()
    local playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            table.insert(playerNames, p.Name)
        end
    end
    return playerNames
end

-- =====================================================
-- JOSHLIB v2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â DARK MINIMAL
-- =====================================================
-- =====================================================
-- JOSHLIB v2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â by Jos
-- Dark Minimal Ãƒâ€šÃ‚Â· Monochrome Ãƒâ€šÃ‚Â· Clean
-- =====================================================
-- API:
--   local Lib = JoshLib.new({ title="JOSHUB", subtitle="v4" })
--   local tab = Lib:AddTab("Combat", icon?)
--   local left  = tab:AddLeftGroupbox("Kill Aura")
--   local right = tab:AddRightGroupbox("WallCombo")
--   left:AddToggle("id", { Text="...", Default=false, Callback=fn })
--   left:AddSlider("id", { Text="...", Min=0, Max=100, Default=50, Rounding=0, Callback=fn })
--   left:AddDropdown("id", { Text="...", Values={...}, Default="...", Callback=fn })
--   left:AddButton("text", fn)
--   left:AddLabel("text")
--   left:AddDivider()
--   left:AddInput("id", { Text="...", Default="", Placeholder="...", Callback=fn })
--   Lib:Notify("text", duration)
--   Lib:SetWatermark("text")
--   Lib.Toggles["id"]:SetValue(true/false)
-- =====================================================

local JoshLib = {}
JoshLib.__index = JoshLib

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

-- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ PALETTE ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
local C = {
    -- Backgrounds
    BG        = Color3.fromRGB(18,  18,  24),
    BG2       = Color3.fromRGB(24,  24,  32),
    BG3       = Color3.fromRGB(30,  30,  42),
    BG4       = Color3.fromRGB(38,  38,  52),
    BG5       = Color3.fromRGB(50,  50,  68),

    -- Violet accent
    ACC       = Color3.fromRGB(125, 85,  245),
    ACC2      = Color3.fromRGB(90,  58,  185),
    ACC3      = Color3.fromRGB(165, 125, 255),

    -- Text
    TXT       = Color3.fromRGB(235, 235, 248),
    TXT2      = Color3.fromRGB(148, 148, 170),
    TXT3      = Color3.fromRGB(78,  78,  100),

    -- Borders
    BORDER    = Color3.fromRGB(48,  48,  66),
    BORDER2   = Color3.fromRGB(68,  68,  90),
    SEP       = Color3.fromRGB(38,  38,  52),

    -- Toggle
    TOG_OFF   = Color3.fromRGB(48,  48,  62),
    TOG_ON    = Color3.fromRGB(125, 85,  245),
    KNOB_OFF  = Color3.fromRGB(120, 120, 145),
    KNOB_ON   = Color3.fromRGB(240, 240, 252),

    SIDEBAR_W = 190,
    WIN_W     = 720,
    WIN_H     = 540,
}

local FB = Enum.Font.GothamBold
local FM = Enum.Font.GothamMedium
local F  = Enum.Font.Gotham

local function N(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do
        pcall(function()
            o[k] = v
        end)
    end
    if parent then o.Parent = parent end
    return o
end
local function corner(r, p)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p
end
local function stroke(col, th, p, trans)
    local s = Instance.new("UIStroke")
    s.Color = col; s.Thickness = th or 1
    s.Transparency = trans or 0
    s.Parent = p; return s
end
local function pad(l, r, t, b, p)
    local x = Instance.new("UIPadding")
    x.PaddingLeft   = UDim.new(0, l or 0)
    x.PaddingRight  = UDim.new(0, r or 0)
    x.PaddingTop    = UDim.new(0, t or 0)
    x.PaddingBottom = UDim.new(0, b or 0)
    x.Parent = p
end
local function tw(o, props, t, es)
    TweenService:Create(o,
        TweenInfo.new(t or 0.15, es or Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        props):Play()
end
local function listLayout(p, gap, sort)
    local l = Instance.new("UIListLayout")
    l.Padding   = UDim.new(0, gap or 0)
    l.SortOrder = sort or Enum.SortOrder.LayoutOrder
    l.Parent    = p; return l
end

-- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ CONSTRUCTOR ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
function JoshLib.new(cfg)
    cfg = cfg or {}
    local self      = setmetatable({}, JoshLib)
    self.Toggles    = {}
    self.Sliders    = {}
    self.Dropdowns  = {}
    self._tabs      = {}
    self._activeTab = nil
    self._visible   = true

    pcall(function()
        local old = CoreGui:FindFirstChild("__JoshLib")
        if old then old:Destroy() end
    end)

    local sg = N("ScreenGui", {
        Name             = "__JoshLib",
        ResetOnSpawn     = false,
        ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
        DisplayOrder     = 999,
        IgnoreGuiInset   = true,
    }, CoreGui)
    self._sg = sg

    -- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ WINDOW ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    local win = N("Frame", {
        Name              = "Window",
        Size              = UDim2.new(0, C.WIN_W, 0, C.WIN_H),
        Position          = UDim2.new(0.5, -C.WIN_W/2, 0.5, -C.WIN_H/2),
        BackgroundColor3  = C.BG,
        BorderSizePixel   = 0,
        Active            = true,
        Draggable         = false,
        ClipsDescendants  = false,
    }, sg)
    corner(4, win)
    stroke(C.BORDER2, 1, win)
    self._win = win

    -- Thin accent line at top
    local topLine = N("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.ACC2,
        BorderSizePixel  = 0,
        ZIndex           = 10,
    }, win)

    -- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ SIDEBAR ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    local sidebar = N("Frame", {
        Size             = UDim2.new(0, C.SIDEBAR_W, 1, 0),
        BackgroundColor3 = C.BG2,
        BorderSizePixel  = 0,
    }, win)
    corner(4, sidebar)
    -- cover right corners
    N("Frame", {
        Size             = UDim2.new(0, 8, 1, 0),
        Position         = UDim2.new(1, -8, 0, 0),
        BackgroundColor3 = C.BG2,
        BorderSizePixel  = 0,
    }, sidebar)

    -- Right border of sidebar
    N("Frame", {
        Size             = UDim2.new(0, 1, 1, -1),
        Position         = UDim2.new(1, -1, 0, 1),
        BackgroundColor3 = C.BORDER,
        BorderSizePixel  = 0,
    }, sidebar)

    -- Logo / title area
    local logoArea = N("Frame", {
        Size             = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1,
    }, sidebar)

    N("TextLabel", {
        Size             = UDim2.new(1, -16, 0, 22),
        Position         = UDim2.new(0, 14, 0, 12),
        BackgroundTransparency = 1,
        Text             = cfg.title or "JOSHUB",
        TextColor3       = C.ACC3,
        Font             = FB,
        TextSize         = 16,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, logoArea)

    N("TextLabel", {
        Size             = UDim2.new(1, -16, 0, 14),
        Position         = UDim2.new(0, 14, 0, 33),
        BackgroundTransparency = 1,
        Text             = cfg.subtitle or "script hub",
        TextColor3       = C.TXT3,
        Font             = F,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, logoArea)

    -- Separator under logo
    N("Frame", {
        Size             = UDim2.new(1, -20, 0, 1),
        Position         = UDim2.new(0, 10, 0, 52),
        BackgroundColor3 = C.SEP,
        BorderSizePixel  = 0,
    }, sidebar)

    -- Tab list
    local tabList = N("ScrollingFrame", {
        Size                 = UDim2.new(1, 0, 1, -100),
        Position             = UDim2.new(0, 0, 0, 58),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ScrollBarThickness   = 0,
        CanvasSize           = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
    }, sidebar)
    pad(8, 8, 6, 6, tabList)
    listLayout(tabList, 2)
    self._tabList = tabList

    -- Watermark bottom
    local wm = N("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 18),
        Position         = UDim2.new(0, 0, 1, -24),
        BackgroundTransparency = 1,
        Text             = "Ãƒâ€šÃ‚Â· joshub Ãƒâ€šÃ‚Â·",
        TextColor3       = C.TXT3,
        Font             = F,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Center,
    }, sidebar)
    self._watermark = wm

    -- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ CONTENT AREA ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    local contentArea = N("Frame", {
        Size             = UDim2.new(1, -C.SIDEBAR_W, 1, -1),
        Position         = UDim2.new(0, C.SIDEBAR_W, 0, 1),
        BackgroundColor3 = C.BG,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, win)
    corner(4, contentArea)
    self._contentArea = contentArea

    -- Close btn (top-right corner of window)
    local closeBtn = N("TextButton", {
        Size             = UDim2.new(0, 22, 0, 22),
        Position         = UDim2.new(1, -28, 0, 5),
        BackgroundColor3 = C.BG4,
        Text             = "ÃƒÆ’Ã¢â‚¬â€",
        TextColor3       = C.TXT3,
        Font             = FB,
        TextSize         = 16,
        BorderSizePixel  = 0,
        ZIndex           = 20,
    }, win)
    corner(4, closeBtn)
    closeBtn.MouseButton1Click:Connect(function()
        self._visible = false; win.Visible = false
    end)
    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, {TextColor3=Color3.fromRGB(220,80,80)}, 0.1)
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, {TextColor3=C.TXT3}, 0.1)
    end)

    local draggingWindow = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local function stopWindowDrag()
        draggingWindow = false
        dragInput = nil
        dragStart = nil
        startPos = nil
    end

    local function updateWindowDrag(input)
        if not draggingWindow or not dragStart or not startPos then return end
        local delta = input.Position - dragStart
        win.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    win.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = true
            dragInput = input
            dragStart = input.Position
            startPos = win.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    stopWindowDrag()
                end
            end)
        end
    end)

    win.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput then
            updateWindowDrag(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            stopWindowDrag()
        end
    end)

    pcall(function()
        local GuiService = game:GetService("GuiService")
        if GuiService and GuiService.MenuOpened then
            GuiService.MenuOpened:Connect(stopWindowDrag)
        end
    end)

    -- Toggle visibility: RightShift key
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if not gpe and inp.KeyCode == Enum.KeyCode.RightShift then
            self._visible = not self._visible
            win.Visible   = self._visible
            if not self._visible then
                stopWindowDrag()
            end
        end
    end)

    return self
end

-- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ ADD TAB ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
function JoshLib:AddTab(name)
    local tdata = { name=name, groupboxes={} }

    -- Sidebar button
    local btn = N("TextButton", {
        Size             = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = C.BG2,
        BorderSizePixel  = 0,
        Text             = "",
        AutoButtonColor  = false,
    }, self._tabList)
    corner(3, btn)

    -- Left indicator bar
    local bar = N("Frame", {
        Size             = UDim2.new(0, 2, 0, 14),
        Position         = UDim2.new(0, 0, 0.5, -7),
        BackgroundColor3 = C.BG2,
        BorderSizePixel  = 0,
    }, btn)
    corner(1, bar)

    N("TextLabel", {
        Size             = UDim2.new(1, -16, 1, 0),
        Position         = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text             = name,
        TextColor3       = C.TXT3,
        Font             = FM,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, btn)
    tdata._btn = btn; tdata._bar = bar

    -- Content scroll frame
    local frame = N("ScrollingFrame", {
        Name                 = "Tab_" .. name,
        Size                 = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ScrollBarThickness   = 2,
        ScrollBarImageColor3 = C.BORDER2,
        CanvasSize           = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        Visible              = false,
    }, self._contentArea)
    pad(10, 10, 10, 10, frame)
    tdata.frame = frame

    -- Two-column layout
    local cols = N("Frame", {
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, frame)

    local leftCol = N("Frame", {
        Size             = UDim2.new(0.5, -5, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, cols)
    listLayout(leftCol, 6)

    local rightCol = N("Frame", {
        Size             = UDim2.new(0.5, -5, 0, 0),
        Position         = UDim2.new(0.5, 5, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, cols)
    listLayout(rightCol, 6)

    tdata._leftCol  = leftCol
    tdata._rightCol = rightCol

    btn.MouseButton1Click:Connect(function()
        self:_selectTab(name)
    end)
    btn.MouseEnter:Connect(function()
        if self._activeTab ~= name then
            tw(btn, {BackgroundColor3=C.BG4}, 0.1)
        end
    end)
    btn.MouseLeave:Connect(function()
        if self._activeTab ~= name then
            tw(btn, {BackgroundColor3=C.BG2}, 0.1)
        end
    end)

    self._tabs[name] = tdata
    if not self._activeTab then self:_selectTab(name) end

    local tabAPI = { _lib=self, _name=name }
    function tabAPI:AddLeftGroupbox(title)
        return JoshLib._makeGroupbox(self._lib, name, title, "left")
    end
    function tabAPI:AddRightGroupbox(title)
        return JoshLib._makeGroupbox(self._lib, name, title, "right")
    end
    return tabAPI
end

function JoshLib:_selectTab(name)
    for tname, tdata in pairs(self._tabs) do
        tdata.frame.Visible = false
        tw(tdata._btn, {BackgroundColor3=C.BG2}, 0.12)
        tdata._btn:FindFirstChildOfClass("TextLabel").TextColor3 = C.TXT3
        tw(tdata._bar, {BackgroundColor3=C.BG2}, 0.12)
    end
    local td = self._tabs[name]; if not td then return end
    td.frame.Visible = true
    tw(td._btn, {BackgroundColor3=C.BG4}, 0.12)
    td._btn:FindFirstChildOfClass("TextLabel").TextColor3 = C.TXT
    tw(td._bar, {BackgroundColor3=C.ACC}, 0.15)
    self._activeTab = name
end

-- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ GROUPBOX ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
function JoshLib._makeGroupbox(lib, tabName, title, side)
    local td  = lib._tabs[tabName]; if not td then return end
    local col = side=="right" and td._rightCol or td._leftCol

    local gbData = { elements={} }
    local gb = N("Frame", {
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.BG3,
        BorderSizePixel  = 0,
    }, col)
    corner(4, gb)
    stroke(C.BORDER, 1, gb)

    -- Title strip
    local titleBar = N("Frame", {
        Size             = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = C.BG4,
        BorderSizePixel  = 0,
    }, gb)
    corner(4, titleBar)
    N("Frame", {
        Size             = UDim2.new(1, 0, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.BG4,
        BorderSizePixel  = 0,
    }, titleBar)

    -- Tiny accent dot
    N("Frame", {
        Size             = UDim2.new(0, 3, 0, 3),
        Position         = UDim2.new(0, 10, 0.5, -2),
        BackgroundColor3 = C.ACC2,
        BorderSizePixel  = 0,
    }, titleBar)

    N("TextLabel", {
        Size             = UDim2.new(1, -22, 1, 0),
        Position         = UDim2.new(0, 20, 0, 2),
        BackgroundTransparency = 1,
        Text             = title:upper(),
        TextColor3       = C.TXT2,
        Font             = FB,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextYAlignment   = Enum.TextYAlignment.Center,
    }, titleBar)

    local content = N("Frame", {
        Size             = UDim2.new(1, 0, 0, 0),
        Position         = UDim2.new(0, 0, 0, 34),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, gb)
    pad(10, 10, 8, 10, content)
    listLayout(content, 1)
    gbData._content = content
    table.insert(td.groupboxes, gbData)

    local gbAPI = { _lib=lib, _gbd=gbData, _c=content }

    -- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ TOGGLE ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    function gbAPI:AddToggle(id, cfg)
        cfg = cfg or {}
        local val = cfg.Default or false
        local elem = { label=cfg.Text or id }

        local row = N("TextButton", {
            Size             = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Text             = "",
            AutoButtonColor  = false,
        }, content)
        elem.frame = row

        N("TextLabel", {
            Size             = UDim2.new(1, -46, 1, 0),
            BackgroundTransparency = 1,
            Text             = cfg.Text or id,
            TextColor3       = C.TXT,
            Font             = F,
            TextSize         = 12,
            TextXAlignment   = Enum.TextXAlignment.Left,
        }, row)

        -- Toggle track
        local track = N("Frame", {
            Size             = UDim2.new(0, 32, 0, 16),
            Position         = UDim2.new(1, -34, 0.5, -8),
            BackgroundColor3 = val and C.TOG_ON or C.TOG_OFF,
            BorderSizePixel  = 0,
        }, row)
        corner(8, track)
        stroke(C.BORDER2, 1, track)

        local knob = N("Frame", {
            Size             = UDim2.new(0, 11, 0, 11),
            Position         = val and UDim2.new(1,-13,0.5,-5.5) or UDim2.new(0,2,0.5,-5.5),
            BackgroundColor3 = val and C.KNOB_ON or C.KNOB_OFF,
            BorderSizePixel  = 0,
        }, track)
        corner(6, knob)

        local togObj = { Value=val }
        function togObj:SetValue(v)
            self.Value = v
            tw(track, {BackgroundColor3 = v and C.TOG_ON or C.TOG_OFF}, 0.12)
            tw(knob, {
                Position         = v and UDim2.new(1,-13,0.5,-5.5) or UDim2.new(0,2,0.5,-5.5),
                BackgroundColor3 = v and C.KNOB_ON or C.KNOB_OFF
            }, 0.12)
            if cfg.Callback then pcall(cfg.Callback, v) end
        end

        row.MouseButton1Click:Connect(function() togObj:SetValue(not togObj.Value) end)
        row.MouseEnter:Connect(function() end)
        row.MouseLeave:Connect(function() end)

        if val and cfg.Callback then pcall(cfg.Callback, val) end
        lib.Toggles[id] = togObj
        table.insert(gbData.elements, elem)
        return togObj
    end

    -- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ SLIDER ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    function gbAPI:AddSlider(id, cfg)
        cfg = cfg or {}
        local min  = cfg.Min or 0
        local max  = cfg.Max or 100
        local cur  = math.clamp(cfg.Default or min, min, max)
        local rnd  = cfg.Rounding or 0
        local elem = { label=cfg.Text or id }

        local container = N("Frame", {
            Size             = UDim2.new(1, 0, 0, 44),
            BackgroundTransparency = 1,
        }, content)
        elem.frame = container

        N("TextLabel", {
            Size             = UDim2.new(0.65, 0, 0, 16),
            BackgroundTransparency = 1,
            Text             = cfg.Text or id,
            TextColor3       = C.TXT2,
            Font             = F,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Left,
        }, container)

        local function fmt(v)
            if rnd == 0 then return tostring(math.floor(v+0.5))
            else return string.format("%." .. rnd .. "f", v) end
        end

        local valLbl = N("TextLabel", {
            Size             = UDim2.new(0.35, 0, 0, 16),
            Position         = UDim2.new(0.65, 0, 0, 0),
            BackgroundTransparency = 1,
            Text             = fmt(cur) .. " / " .. fmt(max),
            TextColor3       = C.TXT3,
            Font             = Enum.Font.Code,
            TextSize         = 10,
            TextXAlignment   = Enum.TextXAlignment.Right,
        }, container)

        local track = N("Frame", {
            Size             = UDim2.new(1, 0, 0, 3),
            Position         = UDim2.new(0, 0, 0, 26),
            BackgroundColor3 = C.BG5,
            BorderSizePixel  = 0,
        }, container)
        corner(2, track)

        local pct  = (cur - min) / (max - min)
        local fill = N("Frame", {
            Size             = UDim2.new(pct, 0, 1, 0),
            BackgroundColor3 = C.ACC,
            BorderSizePixel  = 0,
        }, track)
        corner(2, fill)

        local knobDot = N("Frame", {
            Size             = UDim2.new(0, 8, 0, 8),
            Position         = UDim2.new(pct, -4, 0.5, -4),
            BackgroundColor3 = C.ACC3,
            BorderSizePixel  = 0,
        }, track)
        corner(4, knobDot)

        local dragging = false
        local function update(x)
            local p = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X,1), 0, 1)
            local raw = min + (max-min)*p
            local v
            if rnd==0 then v=math.floor(raw+0.5)
            else v=math.floor(raw*(10^rnd)+0.5)/(10^rnd) end
            cur = v
            local np = (v-min)/(max-min)
            fill.Size        = UDim2.new(np,0,1,0)
            knobDot.Position = UDim2.new(np,-4,0.5,-4)
            valLbl.Text      = fmt(v) .. " / " .. fmt(max)
            if cfg.Callback then pcall(cfg.Callback, v) end
        end

        local hitbox = N("TextButton",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,18),BackgroundTransparency=1,Text=""},container)
        hitbox.MouseButton1Down:Connect(function() dragging=true; update(UserInputService:GetMouseLocation().X) end)
        UserInputService.InputChanged:Connect(function(inp) if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then update(inp.Position.X) end end)
        UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

        local slObj = { Value=cur }
        function slObj:SetValue(v)
            cur = math.clamp(v,min,max)
            local np=(cur-min)/(max-min)
            fill.Size=UDim2.new(np,0,1,0); knobDot.Position=UDim2.new(np,-4,0.5,-4)
            valLbl.Text=fmt(cur).." / "..fmt(max)
            if cfg.Callback then pcall(cfg.Callback,cur) end
        end

        if cfg.Callback then pcall(cfg.Callback, cur) end
        lib.Sliders[id] = slObj
        table.insert(gbData.elements, elem)
        return slObj
    end

    -- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ DROPDOWN ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    function gbAPI:AddDropdown(id, cfg)
        cfg = cfg or {}
        local vals  = cfg.Values or {}
        local cur   = cfg.Default or (vals[1] or "")
        local open  = false
        local elem  = { label=cfg.Text or id }

        local container = N("Frame", {
            Size             = UDim2.new(1, 0, 0, 48),
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            ZIndex           = 5,
        }, content)
        elem.frame = container

        N("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text             = cfg.Text or id,
            TextColor3       = C.TXT2,
            Font             = F,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 5,
        }, container)

        local dropBtn = N("TextButton", {
            Size             = UDim2.new(1, 0, 0, 28),
            Position         = UDim2.new(0, 0, 0, 18),
            BackgroundColor3 = C.BG4,
            BorderSizePixel  = 0,
            Text             = "",
            ZIndex           = 5,
        }, container)
        corner(3, dropBtn)
        stroke(C.BORDER, 1, dropBtn)

        local selLbl = N("TextLabel", {
            Size             = UDim2.new(1, -26, 1, 0),
            Position         = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text             = tostring(cur),
            TextColor3       = C.TXT,
            Font             = F,
            TextSize         = 12,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 5,
        }, dropBtn)

        local arrow = N("TextLabel", {
            Size             = UDim2.new(0, 18, 1, 0),
            Position         = UDim2.new(1, -20, 0, 0),
            BackgroundTransparency = 1,
            Text             = "v",
            TextColor3       = C.TXT3,
            Font             = FB,
            TextSize         = 11,
            ZIndex           = 5,
        }, dropBtn)

        local list = N("Frame", {
            Size             = UDim2.new(1, 0, 0, 0),
            Position         = UDim2.new(0, 0, 1, 2),
            BackgroundColor3 = C.BG4,
            BorderSizePixel  = 0,
            Visible          = false,
            ZIndex           = 50,
            ClipsDescendants = true,
        }, dropBtn)
        corner(3, list)
        stroke(C.BORDER2, 1, list)
        local ll = Instance.new("UIListLayout"); ll.Parent=list; ll.SortOrder=Enum.SortOrder.LayoutOrder
        pad(3,3,3,3,list)

        local dropObj = { Value=cur }

        local function buildList()
            for _,c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _, v in ipairs(vals) do
                local item = N("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 24),
                    BackgroundColor3 = v==cur and C.BG5 or C.BG4,
                    Text             = tostring(v),
                    TextColor3       = v==cur and C.TXT or C.TXT2,
                    Font             = F,
                    TextSize         = 12,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    BorderSizePixel  = 0,
                    ZIndex           = 51,
                }, list)
                corner(2, item); pad(8,4,0,0,item)
                item.MouseButton1Click:Connect(function()
                    cur=v; dropObj.Value=v; selLbl.Text=tostring(v)
                    open=false; list.Visible=false; arrow.Text="v"
                    tw(container,{Size=UDim2.new(1,0,0,48)},0.1)
                    if cfg.Callback then pcall(cfg.Callback, v) end
                    buildList()
                end)
                item.MouseEnter:Connect(function() if v~=cur then tw(item,{BackgroundColor3=C.BG5},0.08) end end)
                item.MouseLeave:Connect(function() if v~=cur then tw(item,{BackgroundColor3=C.BG4},0.08) end end)
            end
            local h = math.min(#vals*24+6, 150)
            list.Size = UDim2.new(1,0,0,h)
        end

        dropBtn.MouseButton1Click:Connect(function()
            open=not open
            if open then
                buildList(); list.Visible=true; arrow.Text="^"
                local lh=math.min(#vals*24+6,150)
                tw(container,{Size=UDim2.new(1,0,0,48+lh+4)},0.12)
            else
                list.Visible=false; arrow.Text="v"
                tw(container,{Size=UDim2.new(1,0,0,48)},0.12)
            end
        end)

        function dropObj:SetValue(v) cur=v; dropObj.Value=v; selLbl.Text=tostring(v); if cfg.Callback then pcall(cfg.Callback,v) end end
        function dropObj:SetValues(v) vals=v end

        if cfg.Callback then pcall(cfg.Callback, cur) end
        lib.Dropdowns[id] = dropObj
        table.insert(gbData.elements, elem)
        return dropObj
    end

    -- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ BUTTON ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    function gbAPI:AddButton(text, cb)
        local elem = { label=text }
        local btn = N("TextButton", {
            Size             = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = C.BG4,
            Text             = text,
            TextColor3       = C.TXT2,
            Font             = FM,
            TextSize         = 11,
            BorderSizePixel  = 0,
        }, content)
        corner(3, btn)
        stroke(C.BORDER, 1, btn)
        elem.frame = btn
        btn.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
        btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=C.BG5,TextColor3=C.TXT},0.1) end)
        btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=C.BG4,TextColor3=C.TXT2},0.1) end)
        table.insert(gbData.elements, elem)
        return btn
    end

    -- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ LABEL ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    function gbAPI:AddLabel(text)
        local elem = { label=text }
        local lbl = N("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text             = text,
            TextColor3       = C.TXT3,
            Font             = F,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
        }, content)
        elem.frame = lbl
        table.insert(gbData.elements, elem)
        return lbl
    end

    -- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ DIVIDER ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    function gbAPI:AddDivider()
        local div = N("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = C.SEP,
            BorderSizePixel  = 0,
        }, content)
        table.insert(gbData.elements, { frame=div, label="" })
        return div
    end

    -- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ INPUT ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
    function gbAPI:AddInput(id, cfg)
        cfg = cfg or {}
        local elem = { label=cfg.Text or id }
        local container = N("Frame", {
            Size             = UDim2.new(1, 0, 0, 46),
            BackgroundTransparency = 1,
        }, content)
        elem.frame = container
        N("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text             = cfg.Text or id,
            TextColor3       = C.TXT2, Font=F, TextSize=11,
            TextXAlignment   = Enum.TextXAlignment.Left,
        }, container)
        local box = N("TextBox", {
            Size             = UDim2.new(1, 0, 0, 30),
            Position         = UDim2.new(0, 0, 0, 18),
            BackgroundColor3 = C.BG4,
            Text             = cfg.Default or "",
            PlaceholderText  = cfg.Placeholder or "",
            PlaceholderColor3= C.TXT3,
            TextColor3       = C.TXT, Font=F, TextSize=12,
            TextXAlignment   = Enum.TextXAlignment.Left,
            BorderSizePixel  = 0,
            ClearTextOnFocus = false,
        }, container)
        corner(3, box); stroke(C.BORDER,1,box); pad(8,4,0,0,box)
        box.FocusLost:Connect(function()
            if cfg.Callback then pcall(cfg.Callback, box.Text) end
        end)
        table.insert(gbData.elements, elem)
        return box
    end

    return gbAPI
end

-- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ NOTIFY ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
function JoshLib:Notify(text, duration)
    duration = duration or 3
    local notif = N("Frame", {
        Size             = UDim2.new(0, 240, 0, 36),
        Position         = UDim2.new(1, -250, 1, 10),
        BackgroundColor3 = C.BG3,
        BorderSizePixel  = 0,
        ZIndex           = 300,
    }, self._sg)
    corner(3, notif)
    stroke(C.BORDER2, 1, notif)

    -- Left accent
    N("Frame", {
        Size             = UDim2.new(0, 2, 1, -8),
        Position         = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = C.ACC2,
        BorderSizePixel  = 0,
        ZIndex           = 301,
    }, notif)

    N("TextLabel", {
        Size             = UDim2.new(1, -16, 1, 0),
        Position         = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text             = text,
        TextColor3       = C.TXT,
        Font             = F,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 301,
    }, notif)

    tw(notif, {Position=UDim2.new(1,-250,1,-46)}, 0.25)
    task.delay(duration, function()
        tw(notif, {Position=UDim2.new(1,-250,1,10)}, 0.25)
        task.delay(0.3, function() notif:Destroy() end)
    end)
end

-- ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ WATERMARK ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
function JoshLib:SetWatermark(text)
    if self._watermark then self._watermark.Text = text end
end
function JoshLib:SetWatermarkVisibility(v)
    if self._watermark then self._watermark.Visible = v end
end


local Lib = JoshLib.new({ title = "JOSHHUB V4" })
local Library = Lib

Library.Options = {}
Library.Toggles = Library.Toggles or {}
Library.KeybindFrame = { Visible = false }
Library.ShowCustomCursor = true
Library._notifySide = "Right"
Library._dpiScale = 100

local ThemeManager = setmetatable({}, {
    __index = function()
        return function() end
    end
})

local SaveManager = setmetatable({}, {
    __index = function()
        return function() end
    end
})

function Library:SetNotifySide(value)
    self._notifySide = value
end

function Library:SetDPIScale(value)
    self._dpiScale = tonumber(value) or 100
end

function Library:Unload()
    if self._sg then
        self._sg:Destroy()
    end
end

local function wrapLabel(labelObj)
    local api = {}

    function api:AddKeyPicker(id, cfg)
        cfg = cfg or {}
        Library.Options[id] = {
            Value = cfg.Default or "RightShift",
            NoUI = cfg.NoUI or false,
            Text = cfg.Text or id,
            SetValue = function(self, value)
                self.Value = value
            end
        }
        return api
    end

    return api
end

local function wrapGroupbox(realGroupbox)
    local api = {}

    function api:AddToggle(id, cfg)
        local obj = realGroupbox:AddToggle(id, cfg)
        Library.Options[id] = obj
        Library.Toggles[id] = obj
        return obj
    end

    function api:AddSlider(id, cfg)
        local obj = realGroupbox:AddSlider(id, cfg)
        Library.Options[id] = obj
        return obj
    end

    function api:AddDropdown(id, cfg)
        local obj = realGroupbox:AddDropdown(id, cfg)
        Library.Options[id] = obj
        return obj
    end

    function api:AddButton(arg1, arg2)
        if type(arg1) == "table" then
            local text = arg1.Text or arg1.Name or "Button"
            local func = arg1.Func or arg1.Callback
            return realGroupbox:AddButton(text, func)
        end
        return realGroupbox:AddButton(arg1, arg2)
    end

    function api:AddLabel(text)
        realGroupbox:AddLabel(text)
        return wrapLabel()
    end

    function api:AddDivider()
        return realGroupbox:AddDivider()
    end

    return api
end

function Library:CreateWindow(_cfg)
    local win = {}

    function win:AddTab(name, _icon)
        local realTab = Lib:AddTab(name)
        local tabApi = {}

        function tabApi:AddLeftGroupbox(title, _iconName)
            return wrapGroupbox(realTab:AddLeftGroupbox(title))
        end

        function tabApi:AddRightGroupbox(title, _iconName)
            return wrapGroupbox(realTab:AddRightGroupbox(title))
        end

        return tabApi
    end

    return win
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Window = Library:CreateWindow({
	Title = "JOSHHUB V4",
	Footer = "version: PAID",
	Icon = 72712527886064,
	NotifySide = "Right",
	ShowCustomCursor = true
})

getgenv().JoshubMainGroups = getgenv().JoshubMainGroups or {}
local Tabs = {
	Main = Window:AddTab("Main", "user"),
	Exploit = Window:AddTab("exploit", "skull"), 
	EmoteSpam = Window:AddTab("Other Exploit", "smile"),
	UI = Window:AddTab("UI Settings", "settings")
}

getgenv().JoshubTabs = Tabs


local ExploitBox = Tabs.Exploit:AddLeftGroupbox("God Mode Control")


local godNormal = false
local godNormalThread = nil
local godRank = false
local godRankThread = nil

local targets = {"The Ultimate Bum","Blocking Bum","Attacking Bum"}

-- Helper: LÃƒÂ¡Ã‚ÂºÃ‚Â¥y NPC mÃƒÂ¡Ã‚Â»Ã‚Â¥c tiÃƒÆ’Ã‚Âªu
local function getBums()
    local list = {}
    local folder = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild("NPCs")
    if not folder then return list end
    for _,name in ipairs(targets) do
        local npc = folder:FindFirstChild(name)
        if npc and npc:FindFirstChild("HumanoidRootPart") then
            table.insert(list,npc)
        end
    end
    return list
end

-- Helper: TÃƒÂ¡Ã‚ÂºÃ‚Â¡o combatArgs cho God Normal
local function createGodNormalArgs(bum, hrp)
    return {
        [1] = RS.Characters.Gon.WallCombo,
        [2] = "Characters:Gon:WallCombo",
        [3] = 1,
        [4] = 33036,
        [5] = {
            HitboxCFrames = {},
            BestHitCharacter = bum,
            HitCharacters = {bum},
            Ignore = {},
            DeathInfo = {},
            Actions = {},
            HitInfo = {IsFacing=true, IsInFront=true},
            BlockedCharacters = {},
            ServerTime = os.clock(),
            FromCFrame = hrp.CFrame
        },
        [6] = "Action651",
        [7] = 0
    }
end

local function startGodNormal()
    if godNormalThread then return end
    godNormalThread = task.spawn(function()
        while godNormal do
            local char = Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _,bum in ipairs(getBums()) do
                    local combatArgs = createGodNormalArgs(bum, hrp)
                    local abilityArgs = {RS.Characters.Gon.WallCombo, 33036, nil, bum, bum.HumanoidRootPart.Position}
                    pcall(function()
                        RS.Remotes.Abilities.Ability:FireServer(unpack(abilityArgs))
                        RS.Remotes.Combat.Action:FireServer(unpack(combatArgs))
                    end)
                end
            end
            task.wait(0.1)
        end
        godNormalThread=nil
    end)
end

-- Helper: TÃƒÂ¡Ã‚ÂºÃ‚Â¡o remoteArgs cho God Rank
local function createGodRankArgs(playerChar, wallComboAbility)
    local actionNumber = "Action"..math.random(1000,9999)
    local serverTime = tick()
    local randomId = math.random(100000,999999)
    return {
        wallComboAbility,
        "Characters:"..playerChar.Name..":WallCombo",
        1,
        randomId,
        {
            HitboxCFrames = {nil},
            BestHitCharacter = playerChar,
            HitCharacters = {playerChar},
            Ignore = {[actionNumber]={playerChar}},
            DeathInfo = {},
            Actions = {[actionNumber]={}},
            HitInfo = {Blocked=false, IsFacing=true, IsInFront=true},
            BlockedCharacters = {},
            ServerTime = serverTime,
            FromCFrame = nil
        },
        actionNumber
    }
end

-- Start God Rank
local function startGodRank()
    if godRankThread then return end
    godRankThread = task.spawn(function()
        while godRank do
            pcall(function()
                local playerChar = Players.LocalPlayer.Character
                if not playerChar then return end
                local charData = Players.LocalPlayer:FindFirstChild("Data")
                local charValue = charData and charData:FindFirstChild("Character") and charData.Character.Value
                if not charValue then return end
                local charsFolder = RS:FindFirstChild("Characters")
                if not charsFolder or not charsFolder:FindFirstChild(charValue) then return end
                local wallComboAbility = charsFolder[charValue]:FindFirstChild("WallCombo")
                if not wallComboAbility then return end

                local remoteArgs = createGodRankArgs(playerChar, wallComboAbility)
                RS.Remotes.Abilities.Ability:FireServer(wallComboAbility, remoteArgs[4])
                RS.Remotes.Combat.Action:FireServer(unpack(remoteArgs))
            end)
            task.wait(0.01)
        end
        godRankThread=nil
    end)
end

-- ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â¢ UI Toggle trong GroupBox Exploit
ExploitBox:AddToggle("GodNormal", {
    Text = "God Mode Dummy",
    Callback = function(v)
        godNormal = v
        if v then startGodNormal() end
    end
})

ExploitBox:AddToggle("GodRank", {
    Text = "God Mode Rank x Normal",
    Callback = function(v)
        godRank = v
        if v then startGodRank() end
    end
})

-- ==================== GOD MODE V3 ====================
-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n global cho God Mode V3
if not _G.KZ_GodModeModules then _G.KZ_GodModeModules = {} end

_G.KZ_GodModeModules.GodModeV3 = {
    enabled = false,
    taskClosest = nil,
    taskSelf = nil,
    delayClosest = 0.03,
    delaySelf = 0.01
}

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- GET CLOSEST PLAYER
-- =========================
function _G.KZ_GodModeModules.GodModeV3:GetClosestPlayer()
    local closest
    local shortest = math.huge
    local lpChar = LocalPlayer.Character
    local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    if not lpHRP then return nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local dist = (hrp.Position - lpHRP.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- =========================
-- LOOP 1: Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚ÂNH PLAYER GÃƒÂ¡Ã‚ÂºÃ‚Â¦N NHÃƒÂ¡Ã‚ÂºÃ‚Â¤T
-- =========================
function _G.KZ_GodModeModules.GodModeV3:LoopClosest()
    while self.enabled do
        task.wait(self.delayClosest)

        local target = self:GetClosestPlayer()
        if target and target.Character and LocalPlayer.Character then
            pcall(function()
                ReplicatedStorage.Remotes.Abilities.Ability:FireServer(
                    ReplicatedStorage.Characters.Gon.WallCombo,
                    33036,
                    nil,
                    target.Character,
                    target.Character.HumanoidRootPart.Position
                )

                ReplicatedStorage.Remotes.Combat.Action:FireServer(
                    ReplicatedStorage.Characters.Gon.WallCombo,
                    "Characters:Gon:WallCombo",
                    1,
                    33036,
                    {
                        HitboxCFrames = {},
                        BestHitCharacter = target.Character,
                        HitCharacters = {target.Character},
                        Ignore = {},
                        DeathInfo = {},
                        Actions = {},
                        HitInfo = {IsFacing = true, IsInFront = true},
                        BlockedCharacters = {},
                        ServerTime = os.clock(),
                        FromCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    },
                    "Action651",
                    0
                )
            end)
        end
    end
end

-- =========================
-- LOOP 2: SELF WALL COMBO
-- =========================
function _G.KZ_GodModeModules.GodModeV3:LoopSelf()
    while self.enabled do
        task.wait(self.delaySelf)

        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end

            local data = LocalPlayer:FindFirstChild("Data")
            local charName = data and data:FindFirstChild("Character") and data.Character.Value
            if not charName then return end

            local wallCombo = ReplicatedStorage.Characters
                :FindFirstChild(charName)
                :FindFirstChild("WallCombo")

            if not wallCombo then return end

            local actionId = "Action" .. math.random(1000,9999)
            local randomId = math.random(100000,999999)

            ReplicatedStorage.Remotes.Abilities.Ability:FireServer(
                wallCombo,
                randomId
            )

            ReplicatedStorage.Remotes.Combat.Action:FireServer(
                wallCombo,
                "Characters:" .. charName .. ":WallCombo",
                1,
                randomId,
                {
                    HitboxCFrames = {nil},
                    BestHitCharacter = char,
                    HitCharacters = {char},
                    Ignore = {[actionId] = {char}},
                    DeathInfo = {},
                    Actions = {[actionId] = {}},
                    HitInfo = {Blocked = false, IsFacing = true, IsInFront = true},
                    BlockedCharacters = {},
                    ServerTime = tick(),
                    FromCFrame = nil
                },
                actionId
            )
        end)
    end
end

-- =========================
-- START GOD MODE V3
-- =========================
function _G.KZ_GodModeModules.GodModeV3:Start()
    if self.enabled then return end
    
    self.enabled = true
    
    -- Start both loops
    self.taskClosest = task.spawn(function()
        self:LoopClosest()
    end)
    
    self.taskSelf = task.spawn(function()
        self:LoopSelf()
    end)
    
    print("God Mode V3: ON")
    Library:Notify("God Mode V3: Activated", 3)
end

-- =========================
-- STOP GOD MODE V3
-- =========================
function _G.KZ_GodModeModules.GodModeV3:Stop()
    if not self.enabled then return end
    
    self.enabled = false
    
    -- Cancel tasks
    if self.taskClosest then
        task.cancel(self.taskClosest)
        self.taskClosest = nil
    end
    
    if self.taskSelf then
        task.cancel(self.taskSelf)
        self.taskSelf = nil
    end
    
    print("God Mode V3: OFF")
    Library:Notify("God Mode V3: Deactivated", 3)
end

-- =========================
-- ADD TO GOD MODE CONTROL GROUP BOX
-- =========================
-- UI Toggle cho God Mode V3
ExploitBox:AddToggle("GodModeV3", {
    Text = "God Mode V3",
    Callback = function(v)
        if v then
            _G.KZ_GodModeModules.GodModeV3:Start()
        else
            _G.KZ_GodModeModules.GodModeV3:Stop()
        end
    end
})

-- Slider cho delay Ãƒâ€žÃ¢â‚¬ËœÃƒÆ’Ã‚Â¡nh player gÃƒÂ¡Ã‚ÂºÃ‚Â§n nhÃƒÂ¡Ã‚ÂºÃ‚Â¥t
ExploitBox:AddSlider("GodModeV3DelayClosest", {
    Text = "V3 Target Delay",
    Default = 0.03,
    Min = 0.001,
    Max = 0.1,
    Rounding = 3,
    Callback = function(value)
        _G.KZ_GodModeModules.GodModeV3.delayClosest = value
        print("God Mode V3 Target Delay:", value)
    end
})

-- Slider cho delay self wall combo
ExploitBox:AddSlider("GodModeV3DelaySelf", {
    Text = "V3 Self Delay",
    Default = 0.01,
    Min = 0.01,
    Max = 0.1,
    Rounding = 3,
    Callback = function(value)
        _G.KZ_GodModeModules.GodModeV3.delaySelf = value
        print("God Mode V3 Self Delay:", value)
    end
})

-- ==================== ANTI GOD MODE ====================
-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n global cho Anti God Mode
if not _G.KZ_AntiGodModules then _G.KZ_AntiGodModules = {} end

_G.KZ_AntiGodModules.AntiGodMode = {
    enabled = false,
    distance = 15,
    connections = {},
    config = {
        DashInterval = 0.7,
        LastDash = 0,
        Running = false
    }
}

-- HÃƒÆ’Ã‚Â m kiÃƒÂ¡Ã‚Â»Ã†â€™m tra player dead
function _G.KZ_AntiGodModules.AntiGodMode:isPlayerDead(targetPlayer)
    if not targetPlayer.Character then return true end
    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not targetHumanoid then return true end
    local health = targetHumanoid:GetAttribute("Health")
    if health and health <= 0 then return true end
    if targetHumanoid.Health <= 0 then return true end
    return false
end

-- HÃƒÆ’Ã‚Â m trigger dash
function _G.KZ_AntiGodModules.AntiGodMode:triggerDash()
    if tick() - self.config.LastDash < self.config.DashInterval then return end
    self.config.LastDash = tick()
    
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local dashArgs = {
        [1] = hrp.CFrame,
        [2] = "L",
        [3] = hrp.CFrame.LookVector,
        [5] = tick()
    }
    
    local dashRemote = RS.Remotes.Character:FindFirstChild("Dash")
    if dashRemote then 
        pcall(function() 
            dashRemote:FireServer(unpack(dashArgs)) 
        end) 
    end
end

-- HÃƒÆ’Ã‚Â m tÃƒÂ¡Ã‚ÂºÃ‚Â¥n cÃƒÆ’Ã‚Â´ng player gÃƒÂ¡Ã‚ÂºÃ‚Â§n nhÃƒÂ¡Ã‚ÂºÃ‚Â¥t
function _G.KZ_AntiGodModules.AntiGodMode:attackNearest()
    if not self.config.Running then return end
    if not localPlayer.Character then return end
    if not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local localRoot = localPlayer.Character.HumanoidRootPart
    local closestPlayer = nil
    local closestDistance = self.distance
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == localPlayer then continue end
        if not player.Character then continue end
        if not player.Character:FindFirstChild("HumanoidRootPart") then continue end
        if not player.Character:FindFirstChild("Humanoid") then continue end
        
        if self:isPlayerDead(player) then continue end
        if player.Character.Humanoid.Health <= 0 then continue end
        
        local targetRoot = player.Character.HumanoidRootPart
        local dist = (localRoot.Position - targetRoot.Position).Magnitude
        
        if dist < closestDistance then
            closestDistance = dist
            closestPlayer = player
        end
    end
    
    if closestPlayer then
        self:triggerDash()
        
        local CharactersFolder = RS:FindFirstChild("Characters")
        local RemotesFolder = RS:FindFirstChild("Remotes")
        if not CharactersFolder or not RemotesFolder then return end
        
        local AbilitiesRemote = RemotesFolder:FindFirstChild("Abilities")
        local CombatRemote = RemotesFolder:FindFirstChild("Combat")
        if AbilitiesRemote then AbilitiesRemote = AbilitiesRemote:FindFirstChild("Ability") end
        if CombatRemote then CombatRemote = CombatRemote:FindFirstChild("Action") end
        if not AbilitiesRemote or not CombatRemote then return end
        
        local CharacterName = localPlayer:FindFirstChild("Data")
            and localPlayer.Data:FindFirstChild("Character")
            and localPlayer.Data.Character.Value
        if not CharacterName then return end
        
        local WallCombo = CharactersFolder:FindFirstChild(CharacterName)
        if not WallCombo then return end
        WallCombo = WallCombo:FindFirstChild("WallCombo")
        if not WallCombo then return end
        
        local targetRoot = closestPlayer.Character.HumanoidRootPart
        
        pcall(function()
            AbilitiesRemote:FireServer(WallCombo, 1, {}, targetRoot.Position)
        end)
        
        local startCFrameStr = tostring(localRoot.CFrame)
        pcall(function()
            CombatRemote:FireServer(
                WallCombo, CharacterName..":WallCombo", 2, 1,
                {
                    HitboxCFrames = {targetRoot.CFrame, targetRoot.CFrame},
                    BestHitCharacter = closestPlayer.Character,
                    HitCharacters = {closestPlayer.Character},
                    Ignore = {},
                    DeathInfo = {},
                    BlockedCharacters = {},
                    HitInfo = {IsFacing = false, IsInFront = true},
                    ServerTime = os.time(),
                    Actions = {
                        ActionNumber1 = {
                            [closestPlayer.Name] = {
                                StartCFrameStr = startCFrameStr,
                                Local = true,
                                Collision = false,
                                Animation = "Punch1Hit",
                                Preset = "Punch",
                                Velocity = Vector3.zero,
                                FromPosition = targetRoot.Position,
                                Seed = math.random(1,999999)
                            }
                        }
                    },
                    FromCFrame = targetRoot.CFrame
                },
                "Action150", 0
            )
        end)
    end
end

-- HÃƒÆ’Ã‚Â m bÃƒÂ¡Ã‚ÂºÃ‚Â¯t Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚ÂºÃ‚Â§u Anti God Mode
function _G.KZ_AntiGodModules.AntiGodMode:start()
    if #self.connections > 0 then return end
    
    self.config.Running = true
    
    for i = 1, 12 do
        local conn = RunService.Heartbeat:Connect(function()
            if self.config.Running then
                self:attackNearest()
                task.wait(0.02)
            end
        end)
        table.insert(self.connections, conn)
    end
    
    print("Anti God Mode: ON")
    Library:Notify("Anti God Mode: Activated", 3)
end

-- HÃƒÆ’Ã‚Â m dÃƒÂ¡Ã‚Â»Ã‚Â«ng Anti God Mode
function _G.KZ_AntiGodModules.AntiGodMode:stop()
    self.config.Running = false
    
    for _, conn in ipairs(self.connections) do
        if conn then 
            conn:Disconnect() 
        end
    end
    self.connections = {}
    
    print("Anti God Mode: OFF")
    Library:Notify("Anti God Mode: Deactivated", 3)
end

-- =========================
-- ADD ANTI GOD MODE TO GOD MODE CONTROL GROUP BOX
-- =========================
-- UI Toggle Anti God Mode
ExploitBox:AddToggle("AntiGodMode", {
    Text = "Anti God Mode V1",
    Default = false,
    Callback = function(v)
        if v then
            _G.KZ_AntiGodModules.AntiGodMode:start()
        else
            _G.KZ_AntiGodModules.AntiGodMode:stop()
        end
    end
})

-- UI Slider Distance
ExploitBox:AddSlider("AntiGodDistance", {
    Text = "Anti God Distance",
    Default = 15,
    Min = 5,
    Max = 20,
    Rounding = 0,
    Callback = function(v)
        _G.KZ_AntiGodModules.AntiGodMode.distance = v
        print("Anti God Distance:", v)
    end
})

-- UI Slider Dash Interval
ExploitBox:AddSlider("AntiGodDashInterval", {
    Text = "Anti God Dash Interval",
    Default = 0.7,
    Min = 0.1,
    Max = 2.0,
    Rounding = 1,
    Callback = function(v)
        _G.KZ_AntiGodModules.AntiGodMode.config.DashInterval = v
        print("Anti God Dash Interval:", v)
    end
})

if not _G.KZ_AntiGodModules then _G.KZ_AntiGodModules = {} end

_G.KZ_AntiGodModules.AntiGodModeV2 = {
    enabled = false,
    connection = nil,
    supportedCharacters = {"Mob", "Gon", "Sukuna", "Nanami"},
    selectedCharacter = "Gon"
}

function _G.KZ_AntiGodModules.AntiGodModeV2:GetCurrentCharacter()
    local ok, res = pcall(function()
        return localPlayer.Data.Character.Value
    end)
    if ok and res then return res end
    local char = localPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum:GetAttribute("CharacterName") or "Unknown"
end

function _G.KZ_AntiGodModules.AntiGodModeV2:HasAbility4(characterName)
    local ok, res = pcall(function()
        local chars = RS:WaitForChild("Characters")
        local folder = chars:FindFirstChild(characterName)
        local ab = folder and folder:FindFirstChild("Abilities")
        return ab and ab:FindFirstChild("4") ~= nil
    end)
    return ok and res
end

function _G.KZ_AntiGodModules.AntiGodModeV2:FindNearestPlayer()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local th = p.Character:FindFirstChild("Humanoid")
            if tr and th then
                local hp = th:GetAttribute("Health")
                if hp and hp > 0 then
                    local d = (hrp.Position - tr.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = p
                    end
                end
            end
        end
    end
    return nearest
end

function _G.KZ_AntiGodModules.AntiGodModeV2:GetNearestPlayerCFrame()
    local p = self:FindNearestPlayer()
    return p and p.Character and p.Character.HumanoidRootPart and p.Character.HumanoidRootPart.CFrame or CFrame.new()
end

function _G.KZ_AntiGodModules.AntiGodModeV2:UseAbility4()
    local charName = self:GetCurrentCharacter()
    if not self:HasAbility4(charName) then return end

    local target = self:FindNearestPlayer()
    if not target then return end

    local targetChar = target.Character
    local targetCF = self:GetNearestPlayerCFrame()

    pcall(function()
        local ability = RS.Characters[charName].Abilities["4"]
        RS.Remotes.Abilities.Ability:FireServer(ability, 9000000)

        local actions = {377, 380, 383, 384, 385, 387, 389}
        for i = 1, 7 do
            local args = {
                ability,
                charName .. ":Abilities:4",
                i,
                9000000,
                {
                    HitboxCFrames = {targetCF, targetCF},
                    BestHitCharacter = targetChar,
                    HitCharacters = {targetChar},
                    Ignore = i > 2 and {ActionNumber1 = {targetChar}} or {},
                    DeathInfo = {},
                    BlockedCharacters = {},
                    HitInfo = {
                        IsFacing = not (i == 1 or i == 2),
                        IsInFront = i <= 2,
                        Blocked = i > 2 and false or nil
                    },
                    ServerTime = tick(),
                    Actions = i > 2 and {ActionNumber1 = {}} or {},
                    FromCFrame = targetCF
                },
                "Action" .. actions[i],
                i == 2 and 0.1 or nil
            }

            if i == 7 then
                args[5].RockCFrame = targetCF
                args[5].Actions = {
                    ActionNumber1 = {
                        [target.Name] = {
                            StartCFrameStr = tostring(targetCF.X) .. "," .. tostring(targetCF.Y) .. "," .. tostring(targetCF.Z) .. ",0,0,0,0,0,0,0,0,0",
                            ImpulseVelocity = Vector3.new(1901, -25000, 291),
                            AbilityName = "4",
                            RotVelocityStr = "0,0,0",
                            VelocityStr = "1.900635,0.010867,0.291061",
                            Duration = 2,
                            RotImpulseVelocity = Vector3.new(5868, -6649, -7414),
                            Seed = math.random(1, 1e6),
                            LookVectorStr = "0.988493,0,0.151268"
                        }
                    }
                }
            end

            RS.Remotes.Combat.Action:FireServer(unpack(args))
        end
    end)
end

function _G.KZ_AntiGodModules.AntiGodModeV2:SwitchToCharacter(characterName)
    if table.find(self.supportedCharacters, characterName) then
        local currentChar = self:GetCurrentCharacter()
        if currentChar ~= characterName then
            local mobRemote = RS:WaitForChild("Remotes"):WaitForChild("Character"):WaitForChild("ChangeCharacter")
            mobRemote:FireServer(characterName)
            task.wait(0.5)
        end
    end
end

function _G.KZ_AntiGodModules.AntiGodModeV2:Start()
    if self.connection then return end
    
    self.enabled = true
    
    local currentChar = self:GetCurrentCharacter()
    if currentChar ~= self.selectedCharacter then
        local mobRemote = RS:WaitForChild("Remotes"):WaitForChild("Character"):WaitForChild("ChangeCharacter")
        mobRemote:FireServer(self.selectedCharacter)
        task.wait(0.5)
    end
    
    self.connection = RunService.Heartbeat:Connect(function()
        if not self.enabled then return end
        self:UseAbility4()
        task.wait(0.5)
        if self.enabled then
            pcall(function()
                local c = self:GetCurrentCharacter()
                RS.Remotes.Abilities.AbilityCanceled:FireServer(
                    RS.Characters[c].Abilities["4"]
                )
            end)
        end
        task.wait(0.001)
    end)
end

function _G.KZ_AntiGodModules.AntiGodModeV2:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self.enabled = false
end

function _G.KZ_AntiGodModules.AntiGodModeV2:SetCharacter(char)
    if table.find(self.supportedCharacters, char) then
        self.selectedCharacter = char
        if self.enabled then
            self:SwitchToCharacter(char)
        end
    end
end

ExploitBox:AddToggle("AntiGodModeV2", {
    Text = "Anti God Mode V2",
    Default = false,
    Callback = function(v)
        if v then
            _G.KZ_AntiGodModules.AntiGodModeV2:Start()
        else
            _G.KZ_AntiGodModules.AntiGodModeV2:Stop()
        end
    end
})

ExploitBox:AddDropdown("AntiGodV2Character", {
    Values = {"Gon", "Mob", "Sukuna", "Nanami"},
    Default = "Gon",
    Multi = false,
    Text = "Select Character",
    Callback = function(value)
        _G.KZ_AntiGodModules.AntiGodModeV2:SetCharacter(value)
    end
})


-- ThÃƒÆ’Ã‚Âªm label thÃƒÆ’Ã‚Â´ng tin
ExploitBox:AddLabel("Attacks nearby god mode users")

-- ==================== LAG SERVER CONTROL ====================
task.spawn(function()
    repeat task.wait() until getgenv().JoshubTabs and getgenv().JoshubTabs.Exploit
    local Tabs = getgenv().JoshubTabs
    getgenv().JoshubExploitGroups = getgenv().JoshubExploitGroups or {}
getgenv().JoshubExploitGroups.LagControlBox = Tabs.Exploit:AddLeftGroupbox("Lag Server Control")

-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n toÃƒÆ’Ã‚Â n cÃƒÂ¡Ã‚Â»Ã‚Â¥c cho Lag Server
getgenv().JoshubLagState.lagNormalEnabled, getgenv().JoshubLagState.antiLagNormalEnabled, getgenv().JoshubLagState.lagRankEnabled, getgenv().JoshubLagState.antiLagRankEnabled = false, false, false, false
getgenv().JoshubLagState.lagServerV1Running, getgenv().JoshubLagState.antiLagServerRunning, getgenv().JoshubLagState.lagServerV2Running, getgenv().JoshubLagState.antiLagCrackRunning = false, false, false, false
getgenv().JoshubLagState.lagSeverNormalConnections, getgenv().JoshubLagState.antiLagConnections, getgenv().JoshubLagState.lagSeverRankConnections, getgenv().JoshubLagState.antiLagRankConnections = {}, {}, {}, {}

-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n cho V3
getgenv().JoshubLagState.lagServerV3Running, getgenv().JoshubLagState.antiLagV3Running = false, false
getgenv().JoshubLagState.lagServerV3Connections, getgenv().JoshubLagState.antiLagV3Connections = {}, {}
getgenv().JoshubLagState.lagServerV3State = getgenv().JoshubLagState.lagServerV3State or {
    session = 0,
    loopThread = nil
}

-- HÃƒÆ’Ã‚Â m Anti Lag Server Cleanup
local function AntiLagServerCleanup()
    pcall(function()
        local effectsFolder = workspace:WaitForChild("Misc"):WaitForChild("Effects")
        local children = effectsFolder:GetChildren()
        local destroyedCount = 0
        
        for _, effect in pairs(children) do
            if effect:IsA("Model") and effect.Name:match("WallCombo$") then
                effect:Destroy()
                destroyedCount = destroyedCount + 1
            end
        end
        
        local LAGGY_EFFECTS = {
            "Explosion", "Smoke", "Fire", "Sparkles", "Particle"
        }
        
        for _, effect in pairs(children) do
            if effect:IsA("Model") or effect:IsA("Part") then
                for _, pattern in ipairs(LAGGY_EFFECTS) do
                    if effect.Name:match(pattern) then
                        effect:Destroy()
                        break
                    end
                end
            end
        end
        
        if math.random(1, 100) <= 20 then
            collectgarbage("collect")
        end
    end)
end

-- HÃƒÆ’Ã‚Â m Start Anti Lag Server
local function StartAntiLagServer()
    if #getgenv().JoshubLagState.antiLagConnections > 0 then return end
    
    table.insert(getgenv().JoshubLagState.antiLagConnections, workspace.Misc.Effects.ChildAdded:Connect(function(child)
        task.wait(0.1)
        if child and (child:IsA("Model") or child:IsA("Part")) then
            if child.Name:match("WallCombo$") or child.Name:match("Explosion") then
                child:Destroy()
            end
        end
    end))
    
    table.insert(getgenv().JoshubLagState.antiLagConnections, RunService.Heartbeat:Connect(function()
        if getgenv().JoshubLagState.antiLagServerRunning then
            AntiLagServerCleanup()
        end
    end))
end

-- HÃƒÆ’Ã‚Â m Stop Anti Lag Server
local function StopAntiLagServer()
    for _, conn in ipairs(getgenv().JoshubLagState.antiLagConnections) do
        if conn then 
            conn:Disconnect() 
        end
    end
    getgenv().JoshubLagState.antiLagConnections = {}
end

-- UI: Lag Server Normal
getgenv().JoshubExploitGroups.LagControlBox:AddToggle("LagServerNormal", {
    Text = "Lag Server Wallcombo",
    Default = false,
    Callback = function(v)
        getgenv().JoshubLagState.lagServerV1Running = v
        getgenv().JoshubLagState.lagNormalEnabled = v
        
        if v then
            table.insert(getgenv().JoshubLagState.lagSeverNormalConnections, task.spawn(function()
                while getgenv().JoshubLagState.lagServerV1Running do
                    pcall(function()
                        local combatArgs = {
                            [1] = RS.Characters.Gon.WallCombo,
                            [2] = "Characters:Gon:WallCombo",
                            [3] = 1,
                            [4] = 33036,
                            [5] = {
                                ["HitboxCFrames"] = {},
                                ["BestHitCharacter"] = workspace.Characters.NPCs:FindFirstChild("The Ultimate Bum"),
                                ["HitCharacters"] = {workspace.Characters.NPCs:FindFirstChild("The Ultimate Bum")},
                                ["Ignore"] = {},
                                ["DeathInfo"] = {},
                                ["Actions"] = {},
                                ["HitInfo"] = {["IsFacing"] = true,["IsInFront"] = true},
                                ["BlockedCharacters"] = {},
                                ["ServerTime"] = os.clock(),
                                ["FromCFrame"] = CFrame.new(534.693, 5.532, 79.486)
                            },
                            [6] = "Action651",
                            [7] = 0
                        }
                        
                        local abilityArgs = {
                            [1] = RS.Characters.Gon.WallCombo,
                            [2] = 33036,
                            [4] = workspace.Characters.NPCs:FindFirstChild("The Ultimate Bum"),
                            [5] = Vector3.new(527.693, 4.532, 79.978)
                        }
                        
                        for i = 1, 5 do
                            RS.Remotes.Abilities.Ability:FireServer(unpack(abilityArgs))
                            RS.Remotes.Combat.Action:FireServer(unpack(combatArgs))
                        end
                    end)
                    task.wait()
                end
            end))
        else
            for _, thread in ipairs(getgenv().JoshubLagState.lagSeverNormalConnections) do
                task.cancel(thread)
            end
            getgenv().JoshubLagState.lagSeverNormalConnections = {}
        end
    end
})

-- UI: Anti Lag Server
getgenv().JoshubExploitGroups.LagControlBox:AddToggle("AntiLagServerNormal", {
    Text = "Anti Lag Wallcombo",
    Default = false,
    Callback = function(v)
        getgenv().JoshubLagState.antiLagServerRunning = v
        getgenv().JoshubLagState.antiLagNormalEnabled = v
        if v then
            StartAntiLagServer()
        else
            StopAntiLagServer()
        end
    end
})

-- UI: Lag Server Rank
getgenv().JoshubExploitGroups.LagControlBox:AddToggle("LagServerRank", {
    Text = "Lag Server Kill Emote",
    Default = false,
    Callback = function(v)
        getgenv().JoshubLagState.lagServerV2Running = v
        getgenv().JoshubLagState.lagRankEnabled = v
        
        if v then
            local crackActive, autoUseEnabled = true, true
            local lastUseTime, useCooldown, spamCounter = 0, 0.0000000000000000001, 0
            local KILL_EMOTE_NAME = "Pollen Overload"
            local killEmoteObject = RS:WaitForChild("Cosmetics"):WaitForChild("KillEmote"):WaitForChild(KILL_EMOTE_NAME)
            local AbilityRemote = RS:WaitForChild("Remotes"):WaitForChild("Abilities"):WaitForChild("Ability")
            local CombatRemote = RS:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("Action")
            local ActionIDCounter, cachedTarget, lastTargetCheck = 0, nil, 0

            local function generateActionID()
                ActionIDCounter = ActionIDCounter + 1
                return ActionIDCounter + math.random(10000, 50000)
            end

            local function generateActionName()
                return "UltraAction" .. math.random(10000, 99999)
            end

            local function findNearestPlayerUltra()
                local now = tick()
                if cachedTarget and now - lastTargetCheck < 0.5 then
                    if cachedTarget.Character and cachedTarget.Character:FindFirstChild("HumanoidRootPart") then
                        return cachedTarget
                    end
                end
                
                local character = localPlayer.Character
                if not character then return nil end
                
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if not humanoidRootPart then return nil end
                
                local localPos = humanoidRootPart.Position
                local nearestPlayer = nil
                local shortestDistance = 50
                
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= localPlayer and player.Character then
                        local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            local distance = (localPos - targetRoot.Position).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                nearestPlayer = player
                            end
                        end
                    end
                end
                
                cachedTarget = nearestPlayer
                lastTargetCheck = now
                return nearestPlayer
            end

            local function generateKillEmoteCFramesFast(localChar, targetChar)
                local localRoot = localChar:FindFirstChild("HumanoidRootPart")
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                
                if not localRoot or not targetRoot then return nil end
                
                local localPos = localRoot.Position
                local targetPos = targetRoot.Position
                
                return {
                    fromCFrame = CFrame.new(localPos, targetPos),
                    targetCFrame = CFrame.new(targetPos),
                    phase1Vector = Vector3.new(0, 1, 0),
                    phase2Vector = Vector3.new(0, 0, -1),
                    lookVector = (targetPos - localPos).Unit
                }
            end

            local function usePollenOverloadUltra()
                local targetPlayer = findNearestPlayerUltra()
                if not targetPlayer or not targetPlayer.Character then
                    return false
                end
                
                local localChar = localPlayer.Character
                if not localChar then return false end
                
                local cframes = generateKillEmoteCFramesFast(localChar, targetPlayer.Character)
                if not cframes then return false end
                
                local actionId = generateActionID()
                local serverTime = tick()
                
                local abilityArgs = {
                    killEmoteObject,
                    actionId,
                    [4] = targetPlayer.Character
                }
                
                local combatArgs1 = {
                    killEmoteObject,
                    "Cosmetics:KillEmote:" .. KILL_EMOTE_NAME,
                    1,
                    actionId,
                    {
                        HitboxCFrames = {},
                        BestHitCharacter = targetPlayer.Character,
                        HitCharacters = {targetPlayer.Character},
                        Ignore = {},
                        DeathInfo = {
                            {
                                targetPlayer.Character,
                                cframes.targetCFrame,
                                cframes.phase1Vector,
                                false
                            }
                        },
                        BlockedCharacters = {},
                        HitInfo = {
                            IsFacing = true,
                            GetUp = true,
                            IsInFront = true,
                            Blocked = false
                        },
                        ServerTime = serverTime,
                        Actions = {},
                        FromCFrame = cframes.fromCFrame
                    },
                    generateActionName(),
                    0.01
                }
                
                local combatArgs2 = {
                    killEmoteObject,
                    "Cosmetics:KillEmote:" .. KILL_EMOTE_NAME,
                    2,
                    actionId,
                    {
                        HitboxCFrames = {},
                        BestHitCharacter = targetPlayer.Character,
                        HitCharacters = {targetPlayer.Character},
                        Ignore = {},
                        DeathInfo = {
                            {
                                targetPlayer.Character,
                                cframes.targetCFrame,
                                cframes.phase2Vector,
                                false
                            }
                        },
                        BlockedCharacters = {},
                        HitInfo = {
                            IsFacing = true,
                            IsInFront = false,
                            Blocked = false
                        },
                        ServerTime = serverTime + 1,
                        Actions = {
                            ActionNumber1 = {
                                [targetPlayer.Name] = {
                                    StartCFrameStr = tostring(cframes.targetCFrame),
                                    Finished = true,
                                    AbilityName = KILL_EMOTE_NAME,
                                    RotVelocityStr = "0,0,0",
                                    VelocityStr = "0,0,0",
                                    Duration = 1,
                                    RotImpulseVelocity = Vector3.new(0, 0, 0),
                                    Seed = math.random(100000000, 999999999),
                                    LookVectorStr = tostring(cframes.lookVector),
                                    NoCollisions = true,
                                    ImpulseVelocity = Vector3.new(0, 100000, 0)
                                }
                            }
                        },
                        FromCFrame = cframes.fromCFrame
                    },
                    generateActionName(),
                    0.01
                }
                
                AbilityRemote:FireServer(unpack(abilityArgs))
                CombatRemote:FireServer(unpack(combatArgs1))
                CombatRemote:FireServer(unpack(combatArgs2))
                
                spamCounter = spamCounter + 1
                return true
            end

            table.insert(getgenv().JoshubLagState.lagSeverRankConnections, RunService.Heartbeat:Connect(function()
                if autoUseEnabled and crackActive then
                    local currentTime = tick()
                    if currentTime - lastUseTime >= useCooldown then
                        for i = 1, 3 do
                            local success = usePollenOverloadUltra()
                            if success then
                                lastUseTime = currentTime
                            end
                        end
                    end
                end
            end))
            
        else
            for _, conn in ipairs(getgenv().JoshubLagState.lagSeverRankConnections) do
                conn:Disconnect()
            end
            getgenv().JoshubLagState.lagSeverRankConnections = {}
        end
    end
})

-- UI: Anti Lag Server Rank
getgenv().JoshubExploitGroups.LagControlBox:AddToggle("AntiLagServerRank", {
    Text = "Anti lag Kill Emote",
    Default = false,
    Callback = function(v)
        getgenv().JoshubLagState.antiLagCrackRunning = v
        getgenv().JoshubLagState.antiLagRankEnabled = v
        if v then
            table.insert(getgenv().JoshubLagState.antiLagRankConnections, task.spawn(function()
                while getgenv().JoshubLagState.antiLagCrackRunning do
                    pcall(function()
                        local effectsFolder = workspace:WaitForChild("Misc"):WaitForChild("Effects")
                        for _, effect in pairs(effectsFolder:GetChildren()) do
                            if effect:IsA("Model") and effect.Name:match("WallCombo$") then
                                effect:Destroy()
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end))
        else
            for _, thread in ipairs(getgenv().JoshubLagState.antiLagRankConnections) do
                task.cancel(thread)
            end
            getgenv().JoshubLagState.antiLagRankConnections = {}
        end
    end
})

-- UI: Lag Server V3 (Dash Teleport)
getgenv().JoshubExploitGroups.LagControlBox:AddToggle("LagServerV3", {
    Text = "Public V4",
    Default = false,
    Callback = function(v)
        getgenv().JoshubLagState.lagServerV3Running = v
        getgenv().JoshubLagState.lagServerV3State.session = getgenv().JoshubLagState.lagServerV3State.session + 1
        local currentSession = getgenv().JoshubLagState.lagServerV3State.session

        if getgenv().JoshubLagState.lagServerV3State.loopThread then
            pcall(function()
                task.cancel(getgenv().JoshubLagState.lagServerV3State.loopThread)
            end)
            getgenv().JoshubLagState.lagServerV3State.loopThread = nil
        end

        for _, conn in ipairs(getgenv().JoshubLagState.lagServerV3Connections) do
            if conn then
                conn:Disconnect()
            end
        end
        getgenv().JoshubLagState.lagServerV3Connections = {}

        if v then
            local RS = game:GetService("ReplicatedStorage")
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer

            local function bypass(name)
                for _, fn in pairs(getgc(true)) do
                    local info = typeof(fn) == "function" and debug.getinfo(fn)
                    if info and info.name == name then
                        hookfunction(fn, function(...)
                            return true
                        end)
                    end
                end
            end

            bypass("validateVelocity")
            bypass("validateCollision")
            bypass("validateMovement")

            local function run()
                if currentSession ~= getgenv().JoshubLagState.lagServerV3State.session or not getgenv().JoshubLagState.lagServerV3Running then
                    return
                end

                local char = LocalPlayer.Character
                if not char then
                    return
                end

                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then
                    return
                end

                if getgenv().JoshubLagState.lagServerV3State.loopThread then
                    pcall(function()
                        task.cancel(getgenv().JoshubLagState.lagServerV3State.loopThread)
                    end)
                end

                pcall(function()
                    hrp.CollisionGroup = "None"
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end)

                getgenv().JoshubLagState.lagServerV3State.loopThread = task.spawn(function()
                    while currentSession == getgenv().JoshubLagState.lagServerV3State.session and getgenv().JoshubLagState.lagServerV3Running and char.Parent and hrp.Parent do
                        pcall(function()
                            RS.Remotes.Character.Dash:FireServer(
                                CFrame.new(0, 0, 0),
                                "R",
                                nil,
                                nil
                            )
                        end)
                        task.wait()
                        pcall(function()
                            hrp.CFrame = CFrame.new(870, 4.6, 460)
                        end)
                        task.wait()
                        pcall(function()
                            hrp.CFrame = CFrame.new(9e9, 4.6, 9e9)
                        end)
                    end
                end)
            end

            table.insert(getgenv().JoshubLagState.lagServerV3Connections, LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1)
                if currentSession == getgenv().JoshubLagState.lagServerV3State.session and getgenv().JoshubLagState.lagServerV3Running then
                    run()
                end
            end))

            task.wait(1)
            run()
        end
    end
})

-- UI: Anti Lag Server V3
getgenv().JoshubExploitGroups.LagControlBox:AddToggle("AntiLagServerV3", {
    Text = "Anti Lag Server Rank",
    Default = false,
    Callback = function(v)
        getgenv().JoshubLagState.antiLagV3Running = v
        
        if v then
            -- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n cÃƒÂ¡Ã‚Â»Ã‚Â¥c bÃƒÂ¡Ã‚Â»Ã¢â€žÂ¢ cho Anti Lag V3
            local RunService = game:GetService("RunService")
            local Players = game:GetService("Players")
            local RS = game:GetService("ReplicatedStorage")
            local LocalPlayer = Players.LocalPlayer
            
            -- CÃƒÆ’Ã‚Â i Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚ÂºÃ‚Â·t
            local MAX_DISTANCE = 20000
            
            -- TrÃƒÂ¡Ã‚ÂºÃ‚Â¡ng thÃƒÆ’Ã‚Â¡i
            local antiSLEnabled = true
            local PlayerCache = {}
            local savedEffects = {}
            
            -- Objects Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã†â€™ xÃƒÆ’Ã‚Â³a effects
            local antiSLObjects = {
                RS.Characters.Gon.WallCombo.GonWallCombo.Explosion,
                RS.Characters.Gon.WallCombo.GonWallCombo.Center,
                RS.Characters.Gon.WallCombo.GonIntroHands,
                RS.Characters.Mob.WallCombo.MobWallCombo.Center,
                RS.Characters.Nanami.WallCombo.NanamiWallCombo.Center,
                RS.Characters.Stark.WallCombo.StarkWallCombo.Center,
                RS.Characters.Sukuna.WallCombo.SukunaTransformWallCombo.BlackFlash,
                RS.Characters.Sukuna.WallCombo.SukunaTransformWallCombo.Center,
                RS.Characters.Sukuna.WallCombo.SukunaTransformWallCombo.Dash1,
                RS.Characters.Sukuna.WallCombo.SukunaTransformWallCombo.Dash2,
                RS.Characters.Sukuna.WallCombo.SukunaWallCombo.BlackFlash,
                RS.Characters.Sukuna.WallCombo.SukunaWallCombo.Center,
                RS.Characters.Sukuna.WallCombo.SukunaWallCombo.Dash1,
                RS.Characters.Sukuna.WallCombo.SukunaWallCombo.Dash2
            }
            
            -- HÃƒÆ’Ã‚Â m Phantom Mode
            local function MakePlayerPhantom(player, character)
                if not antiSLEnabled then return end

                local data = PlayerCache[player]
                if not data or data.IsPhantom then return end
                data.IsPhantom = true

                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                end

                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Anchored = true
                end

                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        data.OriginalTransparencies[part] = part.Transparency
                        part.Transparency = 1
                    end
                end
            end

            local function RestorePlayerFromPhantom(player, character)
                local data = PlayerCache[player]
                if not data or not data.IsPhantom then return end
                data.IsPhantom = false

                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Anchored = false
                end

                for part, transparency in pairs(data.OriginalTransparencies) do
                    if part and part.Parent then
                        part.Transparency = transparency
                    end
                end

                data.OriginalTransparencies = {}
            end
            
            -- CÃƒÂ¡Ã‚ÂºÃ‚Â­p nhÃƒÂ¡Ã‚ÂºÃ‚Â­t visibility
            local function UpdatePlayerVisibility()
                if not antiSLEnabled then return end
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

                local myPos = LocalPlayer.Character.HumanoidRootPart.Position

                for player, data in pairs(PlayerCache) do
                    local character = player.Character
                    if not character or not character:FindFirstChild("HumanoidRootPart") then
                        if data.IsPhantom then
                            RestorePlayerFromPhantom(player, character)
                        end
                        continue
                    end

                    local distance = (myPos - character.HumanoidRootPart.Position).Magnitude

                    if distance > MAX_DISTANCE then
                        MakePlayerPhantom(player, character)
                    else
                        RestorePlayerFromPhantom(player, character)
                    end
                end
            end
            
            -- Force restore
            local function ForceShowAllPlayers()
                for player, data in pairs(PlayerCache) do
                    if data.IsPhantom and player.Character then
                        RestorePlayerFromPhantom(player, player.Character)
                    end
                end
            end
            
            -- XÃƒÂ¡Ã‚Â»Ã‚Â­ lÃƒÆ’Ã‚Â½ player
            local function OnPlayerAdded(player)
                if player == LocalPlayer then return end

                PlayerCache[player] = {
                    IsPhantom = false,
                    OriginalTransparencies = {}
                }

                table.insert(getgenv().JoshubLagState.antiLagV3Connections, player.CharacterAdded:Connect(function()
                    task.wait(1)
                    PlayerCache[player] = {
                        IsPhantom = false,
                        OriginalTransparencies = {}
                    }
                end))
            end

            local function OnPlayerRemoving(player)
                PlayerCache[player] = nil
            end
            
            -- XÃƒÂ¡Ã‚Â»Ã‚Â­ lÃƒÆ’Ã‚Â½ effects
            local function saveEffectsAntiSL()
                for _, object in ipairs(antiSLObjects) do
                    savedEffects[object] = {}
                    for _, d in ipairs(object:GetDescendants()) do
                        if d:IsA("ParticleEmitter")
                        or d:IsA("Light")
                        or d:IsA("Sound")
                        or d:IsA("Beam")
                        or d:IsA("Fire")
                        or d:IsA("Smoke")
                        or d:IsA("Trail") then
                            savedEffects[object][d] = {
                                clone = d:Clone(),
                                parent = d.Parent,
                                name = d.Name
                            }
                        end
                    end
                end
            end

            local function removeEffectsAntiSL()
                for _, object in ipairs(antiSLObjects) do
                    for _, d in ipairs(object:GetDescendants()) do
                        if d:IsA("ParticleEmitter")
                        or d:IsA("Light")
                        or d:IsA("Sound")
                        or d:IsA("Beam")
                        or d:IsA("Fire")
                        or d:IsA("Smoke")
                        or d:IsA("Trail") then
                            d:Destroy()
                        end
                    end
                end
            end

            local function restoreEffectsAntiSL()
                for _, effects in pairs(savedEffects) do
                    for _, info in pairs(effects) do
                        if info.parent and info.parent.Parent then
                            if not info.parent:FindFirstChild(info.name) then
                                local newEffect = info.clone:Clone()
                                newEffect.Parent = info.parent
                            end
                        end
                    end
                end
            end
            
            -- KhÃƒÂ¡Ã‚Â»Ã…Â¸i Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â€žÂ¢ng Anti Lag V3
            pcall(saveEffectsAntiSL)
            pcall(removeEffectsAntiSL)
            
            table.insert(getgenv().JoshubLagState.antiLagV3Connections, Players.PlayerAdded:Connect(OnPlayerAdded))
            table.insert(getgenv().JoshubLagState.antiLagV3Connections, Players.PlayerRemoving:Connect(OnPlayerRemoving))

            for _, p in ipairs(Players:GetPlayers()) do
                OnPlayerAdded(p)
            end

            table.insert(getgenv().JoshubLagState.antiLagV3Connections, RunService.RenderStepped:Connect(UpdatePlayerVisibility))
            
        else
            -- DÃƒÂ¡Ã‚Â»Ã‚Â«ng Anti Lag V3
            if not getgenv().JoshubLagState.antiLagV3Running then return end
            
            -- Restore effects
            local RS = game:GetService("ReplicatedStorage")
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer
            
            -- Force restore all players
            for player, data in pairs(PlayerCache or {}) do
                if data.IsPhantom and player.Character then
                    local function Restore()
                        data.IsPhantom = false
                        local character = player.Character
                        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            rootPart.Anchored = false
                        end
                        for part, transparency in pairs(data.OriginalTransparencies or {}) do
                            if part and part.Parent then
                                part.Transparency = transparency
                            end
                        end
                        data.OriginalTransparencies = {}
                    end
                    pcall(Restore)
                end
            end
            
            -- Restore effects
            local savedEffects = savedEffects or {}
            for _, effects in pairs(savedEffects) do
                for _, info in pairs(effects) do
                    if info.parent and info.parent.Parent then
                        if not info.parent:FindFirstChild(info.name) then
                            local newEffect = info.clone:Clone()
                            newEffect.Parent = info.parent
                        end
                    end
                end
            end
            
            -- Disconnect connections
            for _, conn in ipairs(getgenv().JoshubLagState.antiLagV3Connections) do
                if conn then
                    conn:Disconnect()
                end
            end
            getgenv().JoshubLagState.antiLagV3Connections = {}
            PlayerCache = {}
            savedEffects = {}
        end
    end
})

end)
if not _G.KZ_LagModules then _G.KZ_LagModules = {} end

_G.KZ_LagModules.AntiGodModeV2 = {
    enabled = false,
    connection = nil,
    originalCharacter = nil
}

function _G.KZ_LagModules.AntiGodModeV2:GetCurrentCharacter()
    local ok, res = pcall(function()
        return localPlayer.Data.Character.Value
    end)
    if ok and res then return res end
    local char = localPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum:GetAttribute("CharacterName") or "Unknown"
end

function _G.KZ_LagModules.AntiGodModeV2:HasAbility4(characterName)
    local ok, res = pcall(function()
        local chars = RS:WaitForChild("Characters")
        local folder = chars:FindFirstChild(characterName)
        local ab = folder and folder:FindFirstChild("Abilities")
        return ab and ab:FindFirstChild("4") ~= nil
    end)
    return ok and res
end

function _G.KZ_LagModules.AntiGodModeV2:FindNearestPlayer()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local th = p.Character:FindFirstChild("Humanoid")
            if tr and th then
                local hp = th:GetAttribute("Health")
                if hp and hp > 0 then
                    local d = (hrp.Position - tr.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = p
                    end
                end
            end
        end
    end
    return nearest
end

function _G.KZ_LagModules.AntiGodModeV2:GetNearestPlayerCFrame()
    local p = self:FindNearestPlayer()
    return p and p.Character and p.Character.HumanoidRootPart and p.Character.HumanoidRootPart.CFrame or CFrame.new()
end

function _G.KZ_LagModules.AntiGodModeV2:UseAbility4()
    local charName = self:GetCurrentCharacter()
    if not self:HasAbility4(charName) then return end

    local target = self:FindNearestPlayer()
    if not target then return end

    local targetChar = target.Character
    local targetCF = self:GetNearestPlayerCFrame()

    pcall(function()
        local ability = RS.Characters[charName].Abilities["4"]
        RS.Remotes.Abilities.Ability:FireServer(ability, 9000000)

        local actions = {377, 380, 383, 384, 385, 387, 389}
        for i = 1, 7 do
            local args = {
                ability,
                charName .. ":Abilities:4",
                i,
                9000000,
                {
                    HitboxCFrames = {targetCF, targetCF},
                    BestHitCharacter = targetChar,
                    HitCharacters = {targetChar},
                    Ignore = i > 2 and {ActionNumber1 = {targetChar}} or {},
                    DeathInfo = {},
                    BlockedCharacters = {},
                    HitInfo = {
                        IsFacing = not (i == 1 or i == 2),
                        IsInFront = i <= 2,
                        Blocked = i > 2 and false or nil
                    },
                    ServerTime = tick(),
                    Actions = i > 2 and {ActionNumber1 = {}} or {},
                    FromCFrame = targetCF
                },
                "Action" .. actions[i],
                i == 2 and 0.1 or nil
            }

            if i == 7 then
                args[5].RockCFrame = targetCF
                args[5].Actions = {
                    ActionNumber1 = {
                        [target.Name] = {
                            StartCFrameStr = tostring(targetCF.X) .. "," .. tostring(targetCF.Y) .. "," .. tostring(targetCF.Z) .. ",0,0,0,0,0,0,0,0,0",
                            ImpulseVelocity = Vector3.new(1901, -25000, 291),
                            AbilityName = "4",
                            RotVelocityStr = "0,0,0",
                            VelocityStr = "1.900635,0.010867,0.291061",
                            Duration = 2,
                            RotImpulseVelocity = Vector3.new(5868, -6649, -7414),
                            Seed = math.random(1, 1e6),
                            LookVectorStr = "0.988493,0,0.151268"
                        }
                    }
                }
            end

            RS.Remotes.Combat.Action:FireServer(unpack(args))
        end
    end)
end

function _G.KZ_LagModules.AntiGodModeV2:SwitchToMob()
    local currentChar = self:GetCurrentCharacter()
    if currentChar ~= "Mob" then
        self.originalCharacter = currentChar
        local mobRemote = RS:WaitForChild("Remotes"):WaitForChild("Character"):WaitForChild("ChangeCharacter")
        mobRemote:FireServer("Mob")
        task.wait(0.5)
    end
end

function _G.KZ_LagModules.AntiGodModeV2:Start()
    if self.connection then return end
    
    self.enabled = true
    self:SwitchToMob()
    
    self.connection = RunService.Heartbeat:Connect(function()
        if not self.enabled then return end
        
        local currentChar = self:GetCurrentCharacter()
        if currentChar ~= "Mob" then
            local mobRemote = RS:WaitForChild("Remotes"):WaitForChild("Character"):WaitForChild("ChangeCharacter")
            mobRemote:FireServer("Mob")
        end
        
        self:UseAbility4()
        task.wait(0.5)
        
        if self.enabled then
            pcall(function()
                local c = self:GetCurrentCharacter()
                if c ~= "Unknown" then
                    RS.Remotes.Abilities.AbilityCanceled:FireServer(
                        RS.Characters[c].Abilities["4"]
                    )
                end
            end)
        end
        task.wait(0.001)
    end)
end

function _G.KZ_LagModules.AntiGodModeV2:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self.enabled = false
    
    if self.originalCharacter and self.originalCharacter ~= "Mob" then
        local mobRemote = RS:WaitForChild("Remotes"):WaitForChild("Character"):WaitForChild("ChangeCharacter")
        mobRemote:FireServer(self.originalCharacter)
        self.originalCharacter = nil
    end
end

task.spawn(function()
    repeat task.wait() until getgenv().JoshubExploitGroups and getgenv().JoshubExploitGroups.LagControlBox

    getgenv().JoshubExploitGroups.LagControlBox:AddToggle("RankedLagger", {
        Text = "Lag Server Rank",
        Default = false,
        Callback = function(v)
            if v then
                startRankedLagger()
            else
                stopRankedLagger()
            end
        end
    })

    getgenv().JoshubExploitGroups.LagControlBox:AddDropdown("LaggerIntensity", {
        Values = {
            "1 - Normal (4 threads)",
            "2 - Fuerte (6 threads)",
            "3 - Maximo (8 threads)"
        },
        Default = 3,
        Multi = false,
        Text = "Public V4",
        Callback = function(value)
            RankedLagger.Intensity = tonumber(tostring(value):sub(1, 1)) or 3
        end
    })

    getgenv().JoshubExploitGroups.LagControlBox:AddToggle("RankedLaggerEnemies", {
        Text = "Solo Enemigos (V3)",
        Default = false,
        Callback = function(v)
            RankedLagger.FriendOnly = v
        end
    })
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode ~= Enum.KeyCode.Five then return end

    local nextState = not RankedLagger.Enabled

    if Library and Library.Toggles and Library.Toggles.RankedLagger and Library.Toggles.RankedLagger.SetValue then
        Library.Toggles.RankedLagger:SetValue(nextState)
    else
        if nextState then
            startRankedLagger()
        else
            stopRankedLagger()
        end
    end

    if Library and Library.Notify then
        Library:Notify(nextState and "Lag Server Rank ON" or "Lag Server Rank OFF", 2)
    end
end)

if not _G.KZ_LagModules then _G.KZ_LagModules = {} end

_G.KZ_LagModules.AntiLagAbilityOnlyMob = {
    enabled = false,
    connections = {}
}

local ALL_KEYWORDS = {
    "MobAwakeningGrab",
    "LandingSmall",
    "LandingLarge",
    "Fall",
    "Leap",
    "Beams",
    "BeamsSmoke",
    "BeamsFire",
    "DustBig",
    "MobAirstrike",
    "Projectile",
    "Ring",
    "MobCutscene",
    "MobUltRocks",
    "RockShatter",
    "MobWall",
    "MobSeismic",
    "LeftBeam",
    "RightBeam",
    "WallHit",
    "MobWalFinisher",
    "Summon",
    "Explosion",
    "Aura",
    "Dust",
    "Rocks",
    "CCBlack",
    "CCWhite"
}

local function shouldDestroy(obj)
    for _, keyword in ipairs(ALL_KEYWORDS) do
        if obj.Name:find(keyword) then
            return true
        end
    end
    return false
end

function _G.KZ_LagModules.AntiLagAbilityOnlyMob:Start()
    if #self.connections > 0 then return end
    
    self.enabled = true
    
    -- Hook Camera Shake
    pcall(function()
        local Core = require(RS:WaitForChild("Core"))
        local CameraShake = Core.Get("Camera","Shake")
        if CameraShake then
            CameraShake.Shake = function()
                return {
                    StopSustain = function() end
                }
            end
        end
    end)
    
    -- Hook Rocks
    pcall(function()
        local Core = require(RS:WaitForChild("Core"))
        local Rocks = Core.Get("Map","Rocks")
        if Rocks then
            Rocks.Constant = function() return nil end
            Rocks.CreateRock = function() return nil end
            Rocks.Launch = function() return nil end
        end
    end)
    
    -- Hook Destruction
    pcall(function()
        local Core = require(RS:WaitForChild("Core"))
        local Destruction = Core.Get("Map","Destruction")
        if Destruction then
            Destruction.Process = function() return nil end
            Destruction.Destroy = function() return nil end
        end
    end)
    
    -- Hook VFX
    pcall(function()
        local VFX = require(RS.Assets.VFXHelp)
        if VFX then
            VFX.CreateShowcaseVFX = function()
                return {
                    PrimaryPart = Instance.new("Part")
                }
            end
        end
    end)
    
    -- Connect DescendantAdded
    table.insert(self.connections, workspace.DescendantAdded:Connect(function(obj)
        if not self.enabled then return end
        if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Beam") then
            if shouldDestroy(obj) then
                task.wait()
                if obj and obj.Parent then
                    obj:Destroy()
                end
            end
        end
    end))
    
    -- Connect Lighting ChildAdded
    table.insert(self.connections, Lighting.ChildAdded:Connect(function(obj)
        if not self.enabled then return end
        if obj.Name == "CCBlack" or obj.Name == "CCWhite" then
            obj:Destroy()
        end
    end))
    
    -- Cleanup existing objects
    task.spawn(function()
        if not self.enabled then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Beam") then
                if shouldDestroy(obj) then
                    pcall(function()
                        obj:Destroy()
                    end)
                end
            end
        end
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj.Name == "CCBlack" or obj.Name == "CCWhite" then
                pcall(function()
                    obj:Destroy()
                end)
            end
        end
    end)
end

function _G.KZ_LagModules.AntiLagAbilityOnlyMob:Stop()
    self.enabled = false
    for _, conn in ipairs(self.connections) do
        conn:Disconnect()
    end
    self.connections = {}
end

task.spawn(function()
    repeat task.wait() until getgenv().JoshubExploitGroups and getgenv().JoshubExploitGroups.LagControlBox
    getgenv().JoshubExploitGroups.LagControlBox:AddToggle("AntiLagAbilityOnlyMob", {
        Text = "Anti Lag Ability Only Mob",
        Default = false,
        Callback = function(v)
            if v then
                _G.KZ_LagModules.AntiLagAbilityOnlyMob:Start()
            else
                _G.KZ_LagModules.AntiLagAbilityOnlyMob:Stop()
            end
        end
    })
end)


task.spawn(function()
    repeat task.wait() until getgenv().JoshubTabs and getgenv().JoshubTabs.Exploit
    local Tabs = getgenv().JoshubTabs

local ExploitBasicRight = Tabs.Exploit:AddRightGroupbox("Exploit Basic")

-- SÃƒÂ¡Ã‚Â»Ã‚Â­ dÃƒÂ¡Ã‚Â»Ã‚Â¥ng bÃƒÂ¡Ã‚ÂºÃ‚Â£ng global Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã†â€™ trÃƒÆ’Ã‚Â¡nh giÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºi hÃƒÂ¡Ã‚ÂºÃ‚Â¡n biÃƒÂ¡Ã‚ÂºÃ‚Â¿n local
if not _G.KZ_ExploitModules then _G.KZ_ExploitModules = {} end
if not _G.KZ_ExploitConfig then _G.KZ_ExploitConfig = {} end

-- HideUsername Module
_G.KZ_ExploitModules.HideUsername = {
    enabled = false,
    connections = {},
    originalTexts = {}
}

function _G.KZ_ExploitModules.HideUsername:HideUsername()
    pcall(function()
        local playerGui = localPlayer:WaitForChild("PlayerGui")
        local playersGui = playerGui:FindFirstChild("Players")
        if not playersGui then return end
        local base = playersGui:FindFirstChild("Base")
        if not base then return end
        local players = base:FindFirstChild("Players")
        if not players then return end
        local scroll = players:FindFirstChild("Scroll")
        if scroll then
            for _, child in pairs(scroll:GetChildren()) do
                if child:IsA("Frame") then
                    local basePath = child:FindFirstChild("Base")
                    if basePath then
                        local framePath = basePath:FindFirstChild("Frame")
                        if framePath then
                            local offset = framePath:FindFirstChild("Offset")
                            if offset then
                                local user = offset:FindFirstChild("User")
                                if user and user:IsA("TextLabel") and user.Text:find(localPlayer.Name) then
                                    if not self.originalTexts[user] then self.originalTexts[user] = user.Text end
                                    user.Text = "JOSHHUB V4"
                                end
                            end
                        end
                    end
                end
            end
        end
        local expansion = players:FindFirstChild("Expansion")
        if expansion then
            local expand = expansion:FindFirstChild("Expand")
            if expand then
                local info = expand:FindFirstChild("Info")
                if info then
                    local display = info:FindFirstChild("Display")
                    local user = info:FindFirstChild("User")
                    if display and display:IsA("TextLabel") and display.Text == localPlayer.Name then
                        display.Visible = false
                    end
                    if user and user:IsA("TextLabel") and user.Text:find(localPlayer.Name) then
                        if not self.originalTexts[user] then self.originalTexts[user] = user.Text end
                        user.Text = "JOSHHUB V4"
                    end
                end
            end
        end
    end)
end

function _G.KZ_ExploitModules.HideUsername:RestoreUsername()
    pcall(function()
        for label, original in pairs(self.originalTexts) do
            if label and label:IsA("TextLabel") then
                label.Text = original
                if label.Name == "Display" then label.Visible = true end
            end
        end
        self.originalTexts = {}
    end)
end

function _G.KZ_ExploitModules.HideUsername:Start()
    if #self.connections > 0 then return end
    self.enabled = true
    table.insert(self.connections, RunService.Heartbeat:Connect(function()
        if self.enabled then self:HideUsername() end
    end))
end

function _G.KZ_ExploitModules.HideUsername:Stop()
    for _, conn in ipairs(self.connections) do if conn then conn:Disconnect() end end
    self.connections = {}
    self.enabled = false
    self:RestoreUsername()
end

-- FakePing Module
_G.KZ_ExploitModules.FakePing = {enabled = false, connection = nil}
function _G.KZ_ExploitModules.FakePing:Start()
    if self.connection then return end
    self.enabled = true
    self.connection = RunService.Heartbeat:Connect(function()
        pcall(function() RS:WaitForChild("Remotes"):WaitForChild("Services"):WaitForChild("Ping"):FireServer() end)
    end)
end

function _G.KZ_ExploitModules.FakePing:Stop()
    if self.connection then self.connection:Disconnect() self.connection = nil end
    self.enabled = false
end

-- Movement Config
_G.KZ_ExploitConfig.tpwalking = false
_G.KZ_ExploitConfig.tpwalkSpeed = 100
_G.KZ_ExploitConfig.dashSpeedValue = 100
_G.KZ_ExploitConfig.jumpPowerValue = 100
_G.KZ_ExploitConfig.meleeSpeedValue = 100
_G.KZ_ExploitConfig.dashCooldownValue = 100
_G.KZ_ExploitConfig.tpwalkConnection = nil
_G.KZ_ExploitConfig.dashSpeedToggled = false
_G.KZ_ExploitConfig.jumpPowerToggled = false
_G.KZ_ExploitConfig.meleeSpeedToggled = false
_G.KZ_ExploitConfig.dashNoCooldownEnabled = false
_G.KZ_ExploitConfig.originalDashSpeed = RS.Settings.Multipliers.DashSpeed.Value
_G.KZ_ExploitConfig.originalJumpHeight = RS.Settings.Multipliers.JumpHeight.Value
_G.KZ_ExploitConfig.originalMeleeSpeed = RS.Settings.Multipliers.MeleeSpeed.Value
_G.KZ_ExploitConfig.originalDashCooldown = RS.Settings.Cooldowns.Dash.Value

-- Movement Functions
function _G.KZ_ToggleTPWalk(state)
    _G.KZ_ExploitConfig.tpwalking = state
    if _G.KZ_ExploitConfig.tpwalkConnection then
        _G.KZ_ExploitConfig.tpwalkConnection:Disconnect()
        _G.KZ_ExploitConfig.tpwalkConnection = nil
    end
    if state then
        print("TP Walk: ON")
        _G.KZ_ExploitConfig.tpwalkConnection = RunService.Heartbeat:Connect(function()
            local chr = localPlayer.Character
            if not chr then return end
            local hrp = chr:FindFirstChild("HumanoidRootPart")
            local hum = chr:FindFirstChildWhichIsA("Humanoid")
            if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + (hum.MoveDirection * _G.KZ_ExploitConfig.tpwalkSpeed * 1/60)
            end
        end)
    else
        print("TP Walk: OFF")
    end
end

function _G.KZ_ToggleDashSpeed(state)
    _G.KZ_ExploitConfig.dashSpeedToggled = state
    if state then
        print("Dash Speed: ON - Value:", _G.KZ_ExploitConfig.dashSpeedValue)
        RS.Settings.Multipliers.DashSpeed.Value = _G.KZ_ExploitConfig.dashSpeedValue
    else
        print("Dash Speed: OFF")
        RS.Settings.Multipliers.DashSpeed.Value = _G.KZ_ExploitConfig.originalDashSpeed
    end
end

function _G.KZ_ToggleJumpPower(state)
    _G.KZ_ExploitConfig.jumpPowerToggled = state
    if state then
        print("Jump Power: ON - Value:", _G.KZ_ExploitConfig.jumpPowerValue)
        RS.Settings.Multipliers.JumpHeight.Value = _G.KZ_ExploitConfig.jumpPowerValue
    else
        print("Jump Power: OFF")
        RS.Settings.Multipliers.JumpHeight.Value = _G.KZ_ExploitConfig.originalJumpHeight
    end
end

function _G.KZ_ToggleMeleeSpeed(state)
    _G.KZ_ExploitConfig.meleeSpeedToggled = state
    if state then
        print("Melee Speed: ON - Value:", _G.KZ_ExploitConfig.meleeSpeedValue)
        RS.Settings.Multipliers.MeleeSpeed.Value = _G.KZ_ExploitConfig.meleeSpeedValue
    else
        print("Melee Speed: OFF")
        RS.Settings.Multipliers.MeleeSpeed.Value = _G.KZ_ExploitConfig.originalMeleeSpeed
    end
end

function _G.KZ_ToggleDashNoCooldown(state)
    _G.KZ_ExploitConfig.dashNoCooldownEnabled = state
    if state then
        print("Dash No Cooldown: ON - Value:", _G.KZ_ExploitConfig.dashCooldownValue)
        RS.Settings.Cooldowns.Dash.Value = _G.KZ_ExploitConfig.dashCooldownValue
    else
        print("Dash No Cooldown: OFF")
        RS.Settings.Cooldowns.Dash.Value = _G.KZ_ExploitConfig.originalDashCooldown
    end
end

-- Anti Lag Function
function _G.KZ_ToggleAntiLag(state)
    if not _G.KZ_ExploitConfig.antiLagData then _G.KZ_ExploitConfig.antiLagData = {} end
    if state then
        print("Anti Lag: ON")
        _G.KZ_ExploitConfig.antiLagData = {}
        local skyBackup = nil
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Explosion") then
                _G.KZ_ExploitConfig.antiLagData[v] = v.Enabled
                v.Enabled = false
            elseif v:IsA("Decal") or v:IsA("Texture") then
                _G.KZ_ExploitConfig.antiLagData[v] = v.Transparency
                v.Transparency = 1
            elseif v:IsA("MeshPart") or v:IsA("UnionOperation") or v:IsA("Part") and v.Name ~= "HumanoidRootPart" then
                _G.KZ_ExploitConfig.antiLagData[v] = v.Material
                v.Material = Enum.Material.SmoothPlastic
            elseif v:IsA("SurfaceGui") or v:IsA("BillboardGui") or v:IsA("Beam") then
                if v:IsA("Beam") then
                    _G.KZ_ExploitConfig.antiLagData[v] = v.Enabled
                    v.Enabled = false
                elseif v.Enabled ~= nil then
                    _G.KZ_ExploitConfig.antiLagData[v] = v.Enabled
                    v.Enabled = false
                end
            end
        end
        _G.KZ_ExploitConfig.antiLagData["GlobalShadows"] = game.Lighting.GlobalShadows
        _G.KZ_ExploitConfig.antiLagData["FogEnd"] = game.Lighting.FogEnd
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 9e9
        local sky = game.Lighting:FindFirstChildOfClass("Sky")
        if sky then
            skyBackup = sky:Clone()
            sky:Destroy()
        end
        local newSky = Instance.new("Sky")
        newSky.SkyboxBk = "" newSky.SkyboxDn = "" newSky.SkyboxFt = ""
        newSky.SkyboxLf = "" newSky.SkyboxRt = "" newSky.SkyboxUp = ""
        newSky.SunAngularSize = 0 newSky.MoonAngularSize = 0
        newSky.Parent = game.Lighting
        game.Lighting.Ambient = Color3.fromRGB(128,128,128)
        game.Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        _G.KZ_ExploitConfig.antiLagData.skyBackup = skyBackup
    else
        print("Anti Lag: OFF")
        for obj, value in pairs(_G.KZ_ExploitConfig.antiLagData) do
            if type(obj) == "userdata" and obj.Parent then
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Explosion") then
                    obj.Enabled = value
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = value
                elseif obj:IsA("MeshPart") or obj:IsA("UnionOperation") or obj:IsA("Part") then
                    obj.Material = value
                elseif obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") or obj:IsA("Beam") then
                    if obj:IsA("Beam") then obj.Enabled = value
                    elseif obj.Enabled ~= nil then obj.Enabled = value end
                end
            elseif obj == "GlobalShadows" then game.Lighting.GlobalShadows = value
            elseif obj == "FogEnd" then game.Lighting.FogEnd = value
            end
        end
        if _G.KZ_ExploitConfig.antiLagData.skyBackup then
            local currentSky = game.Lighting:FindFirstChildOfClass("Sky")
            if currentSky then currentSky:Destroy() end
            _G.KZ_ExploitConfig.antiLagData.skyBackup.Parent = game.Lighting
        end
        _G.KZ_ExploitConfig.antiLagData = {}
    end
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActionRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("Action")

local EnhancerEnabled = false
local EnhancerValue = 100

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if self == ActionRemote and method == "FireServer" and EnhancerEnabled then
        for _, arg in pairs(args) do
            if type(arg) == "table" and arg.HitCharacters then
                local newTargets = {}
                for _, char in pairs(arg.HitCharacters) do
                    for i = 1, EnhancerValue do
                        table.insert(newTargets, char)
                    end
                end
                arg.HitCharacters = newTargets
            end
        end
    end

    return oldNamecall(self, unpack(args))
end)

ExploitBasicRight:AddToggle("DamageBuffBasic", {
    Text = "buff damage ability",
    Default = false,
    Callback = function(v)
        EnhancerEnabled = v
    end
})



_G.KZ_ExploitModules.AbilitySpam = _G.KZ_ExploitModules.AbilitySpam or {
    enabled = false,
    delay = 0.01,
    selectedAbility = "All",
    ignoreAllies = false,
    thread = nil
}

function _G.KZ_ExploitModules.AbilitySpam:Start()
    if self.thread then return end

    self.enabled = true
    self.thread = task.spawn(function()
        while self.enabled do
            pcall(function()
                local dataFolder = localPlayer:FindFirstChild("Data")
                local characterValue = dataFolder and dataFolder:FindFirstChild("Character")
                local characterName = characterValue and characterValue.Value
                if not characterName then return end

                local charactersFolder = RS:FindFirstChild("Characters")
                local characterFolder = charactersFolder and charactersFolder:FindFirstChild(characterName)
                local abilitiesFolder = characterFolder and characterFolder:FindFirstChild("Abilities")
                if not abilitiesFolder then return end

                local abilitiesToUse = {}
                local selectedAbility = tostring(self.selectedAbility or "All")

                if selectedAbility == "All" then
                    for _, ability in ipairs(abilitiesFolder:GetChildren()) do
                        if tonumber(ability.Name) then
                            table.insert(abilitiesToUse, ability.Name)
                        end
                    end
                    table.sort(abilitiesToUse, function(a, b)
                        return tonumber(a) < tonumber(b)
                    end)
                else
                    if abilitiesFolder:FindFirstChild(selectedAbility) then
                        table.insert(abilitiesToUse, selectedAbility)
                    end
                end

                AbilitySpamCustom.ignoreAllies = self.ignoreAllies

                for _, abilityNum in ipairs(abilitiesToUse) do
                    if not self.enabled then break end
                    AbilitySpamCustom.abilityNum = tostring(abilityNum)
                    spamCustomAbility()
                end
            end)

            task.wait(self.delay)
        end

        self.thread = nil
    end)
end

function _G.KZ_ExploitModules.AbilitySpam:Stop()
    self.enabled = false

    if self.thread then
        pcall(function()
            task.cancel(self.thread)
        end)
        self.thread = nil
    end
end

ExploitBasicRight:AddToggle("AbilitySpamToggle", {
    Text = "Ability Spam",
    Default = false,
    Callback = function(state)
        if state then
            _G.KZ_ExploitModules.AbilitySpam:Start()
        else
            _G.KZ_ExploitModules.AbilitySpam:Stop()
        end
    end
})

ExploitBasicRight:AddSlider("AbilitySpamSpeed", {
    Text = "Ability Spam Speed",
    Default = 0.01,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        _G.KZ_ExploitModules.AbilitySpam.delay = value
    end
})

ExploitBasicRight:AddDropdown("AbilitySpamAbility", {
    Values = { "All", "1", "2", "3", "4" },
    Default = "All",
    Multi = false,
    Text = "Ability Select",
    Callback = function(value)
        _G.KZ_ExploitModules.AbilitySpam.selectedAbility = tostring(value)
    end
})

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode ~= Enum.KeyCode.Six then return end

    local currentToggle = Library and Library.Toggles and Library.Toggles.AbilitySpamToggle
    local nextState = true
    
    if currentToggle then
        nextState = not currentToggle.Value
        currentToggle:SetValue(nextState)
    else
        nextState = not (_G.KZ_ExploitModules and _G.KZ_ExploitModules.AbilitySpam and _G.KZ_ExploitModules.AbilitySpam.enabled)
        if nextState then
            _G.KZ_ExploitModules.AbilitySpam:Start()
        else
            _G.KZ_ExploitModules.AbilitySpam:Stop()
        end
    end

    if Library and Library.Notify then
        Library:Notify(nextState and "Ability Spam ON" or "Ability Spam OFF", 2)
    end
end)
-- Invisible Function
function _G.KZ_ToggleInvisible(state)
    if state then
        print("Invisible: ON")
        local Remote = RS:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("FullCustomReplicationUnreliable")
        local Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local HRP = Character:WaitForChild("HumanoidRootPart")
        if not _G.KZ_ExploitConfig.invisibleHooked then
            _G.KZ_ExploitConfig.invisibleHooked = true
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            local old = mt.__namecall
            mt.__namecall = function(self, ...)
                if self == Remote and getnamecallmethod() == "FireServer" and _G.KZ_ExploitConfig.blockRemote then
                    return nil
                end
                return old(self, ...)
            end
            setreadonly(mt, true)
        end
        local originalCF = HRP.CFrame
        local flyingCF = originalCF + Vector3.new(0, 50000, 0)
        task.spawn(function()
            for i = 1, 10 do
                HRP.CFrame = flyingCF
                Remote:FireServer()
                task.wait(0.1)
            end
            _G.KZ_ExploitConfig.blockRemote = true
            HRP.CFrame = originalCF
        end)
    else
        print("Invisible: OFF")
        _G.KZ_ExploitConfig.blockRemote = false
    end
end

-- ==================== INVISIBLE V2 FUNCTION ====================
function _G.KZ_ToggleInvisibleV2(state)
    if state then
        print("Invisible V2: ON")
        
        -- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n global cho Invisible V2
        if not _G.KZ_ExploitModules.InvisibleV2 then
            _G.KZ_ExploitModules.InvisibleV2 = {
                enabled = false,
                platform = nil,
                mirrorModel = nil,
                mirrorPart = nil,
                originalCameraSubject = nil,
                movementConnection = nil,
                lastJumpHeight = 0,
                connections = {}
            }
        end
        
        local InvisibleV2 = _G.KZ_ExploitModules.InvisibleV2
        
        if InvisibleV2.enabled then return end
        
        local playerCharacter = localPlayer.Character
        if not playerCharacter then return end
        
        -- TÃƒÂ¡Ã‚ÂºÃ‚Â¡o platform
        local groundUnion = Workspace.Map.Structural.Ground.Union
        if not groundUnion then return end
        
        local platformPart = Instance.new("Part")
        platformPart.Name = "InvisibilityPlatform"
        platformPart.Size = Vector3.new(2000, 1, 2000)
        platformPart.Position = Vector3.new(
            playerCharacter.HumanoidRootPart.Position.X,
            groundUnion.Position.Y - 20,
            playerCharacter.HumanoidRootPart.Position.Z
        )
        platformPart.Anchored = true
        platformPart.Transparency = 0.5
        platformPart.BrickColor = BrickColor.new("Bright blue")
        platformPart.Parent = Workspace
        
        InvisibleV2.platform = platformPart
        
        -- TÃƒÂ¡Ã‚ÂºÃ‚Â¡o mirror clone
        if not playerCharacter.Archivable then
            playerCharacter.Archivable = true
        end

        local clone = playerCharacter:Clone()
        clone.Name = "MirrorClone"
        clone.Parent = Workspace

        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") then
                d:Destroy()
            end
        end

        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then
                d.CanCollide = false
                d.Massless = true
                d.Anchored = false
            end
        end

        local hrp = clone:FindFirstChild("HumanoidRootPart") or clone.PrimaryPart
        if not hrp then
            clone:Destroy()
            if platformPart then platformPart:Destroy() end
            return
        end
        clone.PrimaryPart = hrp

        local humanoid = clone:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
            humanoid.AutoRotate = false
        end

        local srcHRP = playerCharacter:FindFirstChild("HumanoidRootPart")
        if srcHRP then
            clone:PivotTo(srcHRP.CFrame)
        end

        InvisibleV2.mirrorModel = clone
        InvisibleV2.mirrorPart = hrp
        InvisibleV2.originalCameraSubject = workspace.CurrentCamera.CameraSubject
        
        -- Ãƒâ€žÃ‚ÂÃƒÂ¡Ã‚ÂºÃ‚Â·t character khÃƒÆ’Ã‚Â´ng va chÃƒÂ¡Ã‚ÂºÃ‚Â¡m
        for _, part in pairs(playerCharacter:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        -- Teleport character lÃƒÆ’Ã‚Âªn platform
        local humanoidRootPart = playerCharacter.HumanoidRootPart
        local originalPosition = humanoidRootPart.Position
        
        local hum = playerCharacter:FindFirstChildOfClass("Humanoid")
        local hip = hum and hum.HipHeight or 2
        local hrpHalf = humanoidRootPart.Size.Y * 0.5
        local platformTopY = platformPart.Position.Y + (platformPart.Size.Y * 0.5)
        
        local targetCFrame = CFrame.new(
            originalPosition.X,
            platformTopY + hip + hrpHalf,
            originalPosition.Z
        )
        
        pcall(function()
            require(localPlayer.PlayerScripts.Character.FullCustomReplication).Override(playerCharacter, targetCFrame)
        end)
        
        -- ChuyÃƒÂ¡Ã‚Â»Ã†â€™n camera sang mirror
        local mirrorHum = clone:FindFirstChildOfClass("Humanoid")
        workspace.CurrentCamera.CameraSubject = mirrorHum or hrp
        
        -- KÃƒÂ¡Ã‚ÂºÃ‚Â¿t nÃƒÂ¡Ã‚Â»Ã¢â‚¬Ëœi cÃƒÂ¡Ã‚ÂºÃ‚Â­p nhÃƒÂ¡Ã‚ÂºÃ‚Â­t vÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹ trÃƒÆ’Ã‚Â­
        InvisibleV2.movementConnection = RunService.Heartbeat:Connect(function(dt)
            if not InvisibleV2.enabled then return end
            
            local currentChar = localPlayer.Character
            if not currentChar or not hrp then return end
            
            local currentHRP = currentChar:FindFirstChild("HumanoidRootPart")
            if not currentHRP then return end

            local groundY = Workspace.Map.Structural.Ground.Union.Position.Y

            local platformTopY2 = platformPart and (platformPart.Position.Y + platformPart.Size.Y * 0.5) or groundY
            local targetJumpHeight = math.max(0, (currentHRP.Position.Y - platformTopY2) * 0.5)
            targetJumpHeight = math.min(targetJumpHeight, 20)

            dt = typeof(dt) == "number" and dt or 1/60
            local smoothing = math.clamp(dt * 10, 0, 1)
            InvisibleV2.lastJumpHeight = InvisibleV2.lastJumpHeight + (targetJumpHeight - InvisibleV2.lastJumpHeight) * smoothing

            local halfHeight = 3
            local newPos = Vector3.new(currentHRP.Position.X, groundY + halfHeight + InvisibleV2.lastJumpHeight, currentHRP.Position.Z)

            local look = currentHRP.CFrame.LookVector
            local flatLook = Vector3.new(look.X, 0, look.Z).Unit
            local targetCFrame
            if flatLook.Magnitude > 0 then
                targetCFrame = CFrame.new(newPos, newPos + flatLook)
            else
                targetCFrame = CFrame.new(newPos)
            end

            if clone and clone.PrimaryPart then
                clone:PivotTo(targetCFrame)
            else
                hrp.CFrame = targetCFrame
            end
        end)
        
        table.insert(InvisibleV2.connections, InvisibleV2.movementConnection)
        
        -- KÃƒÂ¡Ã‚ÂºÃ‚Â¿t nÃƒÂ¡Ã‚Â»Ã¢â‚¬Ëœi reset khi character chÃƒÂ¡Ã‚ÂºÃ‚Â¿t
        local deathConn = localPlayer.CharacterAdded:Connect(function()
            if InvisibleV2.enabled then
                _G.KZ_ToggleInvisibleV2(false)
            end
        end)
        table.insert(InvisibleV2.connections, deathConn)
        
        InvisibleV2.enabled = true
        
    else
        print("Invisible V2: OFF")
        
        if not _G.KZ_ExploitModules.InvisibleV2 then return end
        local InvisibleV2 = _G.KZ_ExploitModules.InvisibleV2
        
        if not InvisibleV2.enabled then return end
        
        local playerCharacter = localPlayer.Character
        
        if playerCharacter then
            -- Teleport trÃƒÂ¡Ã‚Â»Ã…Â¸ lÃƒÂ¡Ã‚ÂºÃ‚Â¡i vÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹ trÃƒÆ’Ã‚Â­ mirror
            if InvisibleV2.mirrorModel and InvisibleV2.mirrorModel.PrimaryPart then
                local humanoidRootPart = playerCharacter.HumanoidRootPart
                local humanoid = playerCharacter:FindFirstChildOfClass("Humanoid")
                local hip = humanoid and humanoid.HipHeight or 2
                local hrpHalf = humanoidRootPart.Size.Y * 0.5
                local groundY = Workspace.Map.Structural.Ground.Union.Position.Y
                
                local targetCFrame = CFrame.new(
                    InvisibleV2.mirrorModel.PrimaryPart.Position.X,
                    groundY + hip + hrpHalf,
                    InvisibleV2.mirrorModel.PrimaryPart.Position.Z
                )
                
                pcall(function()
                    require(localPlayer.PlayerScripts.Character.FullCustomReplication).Override(playerCharacter, targetCFrame)
                end)
            end
            
            -- KhÃƒÆ’Ã‚Â´i phÃƒÂ¡Ã‚Â»Ã‚Â¥c va chÃƒÂ¡Ã‚ÂºÃ‚Â¡m
            for _, part in pairs(playerCharacter:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
            
            -- KhÃƒÆ’Ã‚Â´i phÃƒÂ¡Ã‚Â»Ã‚Â¥c camera
            workspace.CurrentCamera.CameraSubject = playerCharacter:FindFirstChildOfClass("Humanoid") or 
                                                   playerCharacter:FindFirstChild("HumanoidRootPart")
        end
        
        -- DÃƒÂ¡Ã‚Â»Ã‚Ân dÃƒÂ¡Ã‚ÂºÃ‚Â¹p
        if InvisibleV2.platform then
            InvisibleV2.platform:Destroy()
            InvisibleV2.platform = nil
        end
        
        if InvisibleV2.mirrorModel then
            InvisibleV2.mirrorModel:Destroy()
            InvisibleV2.mirrorModel = nil
            InvisibleV2.mirrorPart = nil
        end
        
        -- NgÃƒÂ¡Ã‚ÂºÃ‚Â¯t kÃƒÂ¡Ã‚ÂºÃ‚Â¿t nÃƒÂ¡Ã‚Â»Ã¢â‚¬Ëœi
        for _, conn in ipairs(InvisibleV2.connections) do
            if conn then
                conn:Disconnect()
            end
        end
        InvisibleV2.connections = {}
        InvisibleV2.movementConnection = nil
        
        InvisibleV2.lastJumpHeight = 0
        InvisibleV2.enabled = false
    end
end

-- ==================== ANTI COUNTER FUNCTION ====================
function _G.KZ_ToggleAntiCounter(state)
    if state then
        print("Anti Counter: ON")
        
        -- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n global cho Anti Counter
        if not _G.KZ_ExploitModules.AntiCounter then
            _G.KZ_ExploitModules.AntiCounter = {
                enabled = false,
                counteringPlayers = {},
                connections = {},
                hookApplied = false
            }
        end
        
        local AntiCounter = _G.KZ_ExploitModules.AntiCounter
        
        if AntiCounter.enabled then return end
        
        local counter_anims = {
            ["rbxassetid://15853335966"] = true,
            ["rbxassetid://17561546657"] = true,
            ["rbxassetid://15853335967"] = true,
            ["rbxassetid://17561546658"] = true,
        }
        
        -- HÃƒÆ’Ã‚Â m filter targets
        local function filterTargets(targets)
            if not targets then return targets end
            
            local filtered = {}
            for _, target in ipairs(targets) do
                local player = Players:GetPlayerFromCharacter(target)
                if not player or not AntiCounter.counteringPlayers[player] then
                    table.insert(filtered, target)
                end
            end
            return filtered
        end
        
        -- Hook vÃƒÆ’Ã‚Â o combat system
        if not AntiCounter.hookApplied then
            pcall(function()
                local hitModule = require(localPlayer.PlayerScripts.Combat.Hit)
                
                if hitModule and hitModule.Box then
                    local oldBox = hitModule.Box
                    hitModule.Box = function(...)
                        local bestChar, hitChars, blockedChars, hitInfo = oldBox(...)
                        
                        if AntiCounter.enabled then
                            hitChars = filterTargets(hitChars)
                            
                            if bestChar then
                                local player = Players:GetPlayerFromCharacter(bestChar)
                                if player and AntiCounter.counteringPlayers[player] then
                                    bestChar = nil
                                end
                            end
                        end
                        
                        return bestChar, hitChars, blockedChars, hitInfo
                    end
                    AntiCounter.hookApplied = true
                end
            end)
        end
        
        -- Theo dÃƒÆ’Ã‚Âµi animations
        local function trackPlayer(player)
            if AntiCounter.connections[player] then return end
            
            local function hookCharacter(char)
                local hum = char:WaitForChild("Humanoid", 5)
                if not hum then return end
                
                local conn = hum.AnimationPlayed:Connect(function(track)
                    if not AntiCounter.enabled then return end
                    
                    local animId = track.Animation and track.Animation.AnimationId
                    if animId and counter_anims[animId] then
                        AntiCounter.counteringPlayers[player] = true
                        
                        track.Stopped:Connect(function()
                            AntiCounter.counteringPlayers[player] = nil
                        end)
                    end
                end)
                
                AntiCounter.connections[player] = conn
            end
            
            if player.Character then
                hookCharacter(player.Character)
            end
            
            local conn = player.CharacterAdded:Connect(hookCharacter)
            AntiCounter.connections[player] = conn
        end
        
        -- Theo dÃƒÆ’Ã‚Âµi tÃƒÂ¡Ã‚ÂºÃ‚Â¥t cÃƒÂ¡Ã‚ÂºÃ‚Â£ players
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                trackPlayer(player)
            end
        end
        
        -- Theo dÃƒÆ’Ã‚Âµi player mÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºi
        local newPlayerConn = Players.PlayerAdded:Connect(function(player)
            if player ~= localPlayer then
                trackPlayer(player)
            end
        end)
        AntiCounter.connections["newPlayer"] = newPlayerConn
        
        AntiCounter.enabled = true
        
    else
        print("Anti Counter: OFF")
        
        if not _G.KZ_ExploitModules.AntiCounter then return end
        local AntiCounter = _G.KZ_ExploitModules.AntiCounter
        
        if not AntiCounter.enabled then return end
        
        AntiCounter.enabled = false
        AntiCounter.counteringPlayers = {}
        
        -- NgÃƒÂ¡Ã‚ÂºÃ‚Â¯t kÃƒÂ¡Ã‚ÂºÃ‚Â¿t nÃƒÂ¡Ã‚Â»Ã¢â‚¬Ëœi
        for player, conn in pairs(AntiCounter.connections) do
            if conn then
                conn:Disconnect()
            end
        end
        AntiCounter.connections = {}
        
        -- Reset hook
        AntiCounter.hookApplied = false
    end
end



-- UI Controls
ExploitBasicRight:AddToggle("FakeUsername", {
    Text = "Fake Username",
    Default = false,
    Callback = function(state)
        if state then _G.KZ_ExploitModules.HideUsername:Start() print("Fake Username: ON")
        else _G.KZ_ExploitModules.HideUsername:Stop() print("Fake Username: OFF") end
    end
})

ExploitBasicRight:AddToggle("FakePing", {
    Text = "Fake Ping",
    Default = false,
    Callback = function(state)
        if state then _G.KZ_ExploitModules.FakePing:Start() print("Fake Ping: ON")
        else _G.KZ_ExploitModules.FakePing:Stop() print("Fake Ping: OFF") end
    end
})

ExploitBasicRight:AddToggle("InfinityUltimate", {
    Text = "Infinity Ultimate",
    Default = false,
    Callback = function(state)
        pcall(function()
            RS:WaitForChild("Settings"):WaitForChild("Toggles").Endless.Value = state
            print("Infinity Ultimate:", state and "ON" or "OFF")
        end)
    end
})

ExploitBasicRight:AddToggle("NoStun", {
    Text = "No Stun",
    Default = false,
    Callback = function(state)
        pcall(function()
            RS:WaitForChild("Settings"):WaitForChild("Toggles").NoStunOnMiss.Value = state
            print("No Stun:", state and "ON" or "OFF")
        end)
    end
})

ExploitBasicRight:AddToggle("NoSlowdown", {
    Text = "No Slowdown",
    Default = false,
    Callback = function(state)
        pcall(function()
            RS:WaitForChild("Settings"):WaitForChild("Toggles").NoSlowdowns.Value = state
            print("No Slowdown:", state and "ON" or "OFF")
        end)
    end
})

ExploitBasicRight:AddToggle("Invisible", {
    Text = "Invisible",
    Default = false,
    Callback = function(state) _G.KZ_ToggleInvisible(state) end
})

ExploitBasicRight:AddToggle("InvisibleV2", {
    Text = "Invisible V2",
    Default = false,
    Callback = function(state) _G.KZ_ToggleInvisibleV2(state) end
})

ExploitBasicRight:AddToggle("AntiCounter", {
    Text = "Anti Counter",
    Default = false,
    Callback = function(state) _G.KZ_ToggleAntiCounter(state) end
})

ExploitBasicRight:AddToggle("AntiLag", {
    Text = "Anti Lag",
    Default = false,
    Callback = function(state) _G.KZ_ToggleAntiLag(state) end
})

ExploitBasicRight:AddDivider()

ExploitBasicRight:AddToggle("TPWalk", {
    Text = "TP Walk",
    Default = false,
    Callback = function(state) _G.KZ_ToggleTPWalk(state) end
})

ExploitBasicRight:AddSlider("TPWalkSpeed", {
    Text = "TP Walk Speed",
    Default = 100,
    Min = 0,
    Max = 250,
    Rounding = 0,
    Callback = function(value)
        _G.KZ_ExploitConfig.tpwalkSpeed = value
        print("TP Walk Speed:", value)
    end
})

ExploitBasicRight:AddToggle("DashSpeedToggle", {
    Text = "Dash Speed",
    Default = false,
    Callback = function(state) _G.KZ_ToggleDashSpeed(state) end
})

ExploitBasicRight:AddSlider("DashSpeed", {
    Text = "Dash Speed Value",
    Default = 100,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        _G.KZ_ExploitConfig.dashSpeedValue = value
        if _G.KZ_ExploitConfig.dashSpeedToggled then
            RS.Settings.Multipliers.DashSpeed.Value = value
        end
        print("Dash Speed Value:", value)
    end
})

ExploitBasicRight:AddToggle("JumpPowerToggle", {
    Text = "Jump Power",
    Default = false,
    Callback = function(state) _G.KZ_ToggleJumpPower(state) end
})

ExploitBasicRight:AddSlider("JumpPower", {
    Text = "Jump Power Value",
    Default = 100,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        _G.KZ_ExploitConfig.jumpPowerValue = value
        if _G.KZ_ExploitConfig.jumpPowerToggled then
            RS.Settings.Multipliers.JumpHeight.Value = value
        end
        print("Jump Power Value:", value)
    end
})

ExploitBasicRight:AddToggle("MeleeSpeedToggle", {
    Text = "Melee Speed",
    Default = false,
    Callback = function(state) _G.KZ_ToggleMeleeSpeed(state) end
})

ExploitBasicRight:AddSlider("MeleeSpeed", {
    Text = "Melee Speed Value",
    Default = 100,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        _G.KZ_ExploitConfig.meleeSpeedValue = value
        if _G.KZ_ExploitConfig.meleeSpeedToggled then
            RS.Settings.Multipliers.MeleeSpeed.Value = value
        end
        print("Melee Speed Value:", value)
    end
})

ExploitBasicRight:AddToggle("DashNoCooldownToggle", {
    Text = "Dash No Cooldown",
    Default = false,
    Callback = function(state) _G.KZ_ToggleDashNoCooldown(state) end
})

ExploitBasicRight:AddSlider("DashCooldownValue", {
    Text = "Dash Cooldown Value",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        _G.KZ_ExploitConfig.dashCooldownValue = value
        if _G.KZ_ExploitConfig.dashNoCooldownEnabled then
            RS.Settings.Cooldowns.Dash.Value = value
        end
        print("Dash Cooldown Value:", value)
    end
})


end)
-- ==================== KILL EMOTE SPAM MODULE ====================
if not _G.KZ_EmoteModules then _G.KZ_EmoteModules = {} end

_G.KZ_EmoteModules.KillEmoteSpam = {
    spamRandom = false,
    spamSelected = false,
    selectedEmote = "",
    lastUse = 0,
    delayUse = 0.01,
    allEmotes = {},
    emoteDropdownValues = {"Random"}
}

-- Get all emotes
local function getAllKillEmotes()
    local emotes = {}
    local killEmoteFolder = RS:WaitForChild("Cosmetics"):WaitForChild("KillEmote")
    
    for _, emote in pairs(killEmoteFolder:GetChildren()) do
        if emote:IsA("ModuleScript") then
            table.insert(emotes, emote.Name)
        end
    end
    
    table.sort(emotes)
    return emotes
end

-- Initialize emotes
_G.KZ_EmoteModules.allEmotes = getAllKillEmotes()
for _, emote in ipairs(_G.KZ_EmoteModules.allEmotes) do
    table.insert(_G.KZ_EmoteModules.KillEmoteSpam.emoteDropdownValues, emote)
end

-- UTILS
local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getNearestTarget()
    local myChar = localPlayer.Character
    local myRoot = getRoot(myChar)
    if not myRoot then return end

    local nearest, dist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local r = getRoot(p.Character)
            if r then
                local d = (myRoot.Position - r.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = p.Character
                end
            end
        end
    end
    return nearest
end

-- KILL EMOTE FUNCTION
local function useKillEmote(emoteName)
    local target = getNearestTarget()
    if not target then return false end

    if emoteName == "Random" then
        emoteName = _G.KZ_EmoteModules.allEmotes[math.random(#_G.KZ_EmoteModules.allEmotes)]
    end

    local emoteModule = RS
        :WaitForChild("Cosmetics")
        :WaitForChild("KillEmote")
        :FindFirstChild(emoteName)

    if not emoteModule then return false end

    local success = pcall(function()
        setthreadcontext(5)
        require(RS:WaitForChild("Core")).Get("Combat","Ability").Activate(emoteModule, target)
    end)
    
    return success
end

-- LOOP
RunService.RenderStepped:Connect(function()
    local spam = _G.KZ_EmoteModules.KillEmoteSpam
    
    if not spam.spamRandom and not spam.spamSelected then return end
    if tick() - spam.lastUse < spam.delayUse then return end

    spam.lastUse = tick()
    
    if spam.spamRandom then
        useKillEmote("Random")
    elseif spam.spamSelected and spam.selectedEmote ~= "" then
        useKillEmote(spam.selectedEmote)
    end
end)

-- UI Controls
task.spawn(function()
    repeat task.wait() until getgenv().JoshubTabs and getgenv().JoshubTabs.EmoteSpam
    local Tabs = getgenv().JoshubTabs
local EmoteSpamBox = Tabs.EmoteSpam:AddLeftGroupbox("Kill Emote Spam")

-- Dropdown chÃƒÂ¡Ã‚Â»Ã‚Ân emote
EmoteSpamBox:AddDropdown("SelectKillEmote", {
    Values = _G.KZ_EmoteModules.KillEmoteSpam.emoteDropdownValues,
    Default = "All",
    Multi = false,
    Text = "Select Kill Emote",
    Callback = function(value)
        _G.KZ_EmoteModules.KillEmoteSpam.selectedEmote = value
        print("Selected Emote:", value)
    end
})

-- Spam Random
EmoteSpamBox:AddToggle("SpamRandomKillEmote", {
    Text = "Spam Random Kill Emote",
    Default = false,
    Callback = function(state)
        _G.KZ_EmoteModules.KillEmoteSpam.spamRandom = state
        if state then
            _G.KZ_EmoteModules.KillEmoteSpam.spamSelected = false
        end
        print("Random Kill Emote Spam:", state and "ON" or "OFF")
    end
})

-- Spam Selected
EmoteSpamBox:AddToggle("SpamSelectedKillEmote", {
    Text = "Spam Selected Kill Emote",
    Default = false,
    Callback = function(state)
        _G.KZ_EmoteModules.KillEmoteSpam.spamSelected = state
        if state then
            _G.KZ_EmoteModules.KillEmoteSpam.spamRandom = false
            if _G.KZ_EmoteModules.KillEmoteSpam.selectedEmote == "" then
                _G.KZ_EmoteModules.KillEmoteSpam.selectedEmote = _G.KZ_EmoteModules.KillEmoteSpam.emoteDropdownValues[2] or "Random"
            end
        end
        print("Selected Kill Emote Spam:", state and "ON" or "OFF")
    end
})

-- Spam Speed
EmoteSpamBox:AddSlider("KillEmoteSpeed", {
    Text = "Spam Speed",
    Default = 0.01,
    Min = 0.001,
    Max = 1,
    Rounding = 3,
    Callback = function(value)
        _G.KZ_EmoteModules.KillEmoteSpam.delayUse = value
        print("Kill Emote Spam Speed:", value)
    end
})

-- NÃƒÆ’Ã‚Âºt refresh emotes
EmoteSpamBox:AddButton({
    Text = "Refresh Emotes List",
    Func = function()
        _G.KZ_EmoteModules.allEmotes = getAllKillEmotes()
        _G.KZ_EmoteModules.KillEmoteSpam.emoteDropdownValues = {"Random"}
        
        for _, emote in ipairs(_G.KZ_EmoteModules.allEmotes) do
            table.insert(_G.KZ_EmoteModules.KillEmoteSpam.emoteDropdownValues, emote)
        end
        
        -- Update dropdown
        local dropdown = Options.SelectKillEmote
        if dropdown then
            dropdown:SetValues(_G.KZ_EmoteModules.KillEmoteSpam.emoteDropdownValues)
        end
        
        print("Refreshed emotes list. Found " .. #_G.KZ_EmoteModules.allEmotes .. " emotes")
    end,
    DoubleClick = false
})

-- Cosmetic System
local COSMETICS_DATA = {
    AccessoriesEquipped = {"Chunin Exam Vest", "Halo","Frozen Gloves","Devil's Eye","Devil's Tail","Devil's Wings","Flower Wings","Frozen Crown","Frozen Tail","Frozen Wings","Garland Scarf","Hades Helmet","Holiday Scarf","Krampus Hat","Red Kagune","Rudolph Antlers","Snowflake Wings","Sorting Hat","VIP Crown"},
    AurasEquipped = {"Butterflies", "Northern Lights","Ki","Blue Lightning","Green Lightning","Purple Lightning","Yellow Lightning"},
    CapesEquipped = {"Ice Lord", "Viking","Christmas Lights","Dracula","Krampus","Krampus Supreme","Santa","VIP","Webbed"}
}

local isInitialized = false

local function initialize()
    if isInitialized then return end
    
    pcall(function()
        local passesFolder = localPlayer:FindFirstChild("Passes")
        if passesFolder then
            for _, passValue in passesFolder:GetChildren() do
                if passValue:IsA("BoolValue") then
                    passValue.Value = true
                elseif passValue:IsA("NumberValue") then
                    passValue.Value = 1
                end
            end
        end
    end)
    
    isInitialized = true
end

local function updateDataValue(valueName, dataTable)
    pcall(function()
        local dataFolder = localPlayer:FindFirstChild("Data")
        if not dataFolder then
            dataFolder = Instance.new("Folder")
            dataFolder.Name = "Data"
            dataFolder.Parent = localPlayer
        end

        local valueObject = dataFolder:FindFirstChild(valueName)
        if not valueObject then
            valueObject = Instance.new("StringValue")
            valueObject.Name = valueName
            valueObject.Parent = dataFolder
        end

        local encodedData = game:GetService("HttpService"):JSONEncode(dataTable)
        valueObject.Value = encodedData
    end)
end

-- Initialize
task.wait(0.5)
initialize()

-- UI for Emote Tab
local EmoteBoxRight = Tabs.EmoteSpam:AddRightGroupbox("Cosmetic")

-- Accessories Dropdown
EmoteBoxRight:AddDropdown("Accessories", {
    Values = COSMETICS_DATA.AccessoriesEquipped,
    Default = "All",
    Multi = false,
    Text = "Accessories",
    Callback = function(value)
        pcall(function()
            updateDataValue("AccessoriesEquipped", {value})
            print("Accessory equipped:", value)
        end)
    end
})

-- Auras Dropdown
EmoteBoxRight:AddDropdown("Auras", {
    Values = COSMETICS_DATA.AurasEquipped,
    Default = "All",
    Multi = false,
    Text = "Auras",
    Callback = function(value)
        pcall(function()
            updateDataValue("AurasEquipped", {value})
            print("Aura equipped:", value)
        end)
    end
})

-- Capes Dropdown
EmoteBoxRight:AddDropdown("Capes", {
    Values = COSMETICS_DATA.CapesEquipped,
    Default = "All",
    Multi = false,
    Text = "Capes",
    Callback = function(value)
        pcall(function()
            updateDataValue("CapesEquipped", {value})
            print("Cape equipped:", value)
        end)
    end
})

-- Apply All Button
EmoteBoxRight:AddButton({
    Text = "Apply All Cosmetics",
    Func = function()
        pcall(function()
            updateDataValue("AccessoriesEquipped", {Options.Accessories.Value or COSMETICS_DATA.AccessoriesEquipped[1]})
            updateDataValue("AurasEquipped", {Options.Auras.Value or COSMETICS_DATA.AurasEquipped[1]})
            updateDataValue("CapesEquipped", {Options.Capes.Value or COSMETICS_DATA.CapesEquipped[1]})
            print("All cosmetics applied")
        end)
    end,
    DoubleClick = false
})

-- ==================== CHARACTER SWITCHER ====================
local CharacterSwitcherBox = Tabs.EmoteSpam:AddLeftGroupbox("Character Switcher")

-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n lÃƒâ€ Ã‚Â°u vÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹ trÃƒÆ’Ã‚Â­ cuÃƒÂ¡Ã‚Â»Ã¢â‚¬Ëœi
local lastSwitchPosition = nil

-- HÃƒÆ’Ã‚Â m lÃƒÂ¡Ã‚ÂºÃ‚Â¥y RootPart
local function getHumanoidRootPart()
    local character = localPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- HÃƒÆ’Ã‚Â m lÃƒâ€ Ã‚Â°u vÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹ trÃƒÆ’Ã‚Â­ hiÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¡n tÃƒÂ¡Ã‚ÂºÃ‚Â¡i
local function saveCurrentPosition()
    local rootPart = getHumanoidRootPart()
    if rootPart then
        lastSwitchPosition = rootPart.CFrame
    end
end

-- HÃƒÆ’Ã‚Â m xÃƒÂ¡Ã‚Â»Ã‚Â­ lÃƒÆ’Ã‚Â½ chuyÃƒÂ¡Ã‚Â»Ã†â€™n Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¢i nhÃƒÆ’Ã‚Â¢n vÃƒÂ¡Ã‚ÂºÃ‚Â­t
local function switchCharacter(characterName)
    -- LÃƒâ€ Ã‚Â°u vÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹ trÃƒÆ’Ã‚Â­ hiÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¡n tÃƒÂ¡Ã‚ÂºÃ‚Â¡i
    saveCurrentPosition()
    
    -- Teleport Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚ÂºÃ‚Â¿n vÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹ trÃƒÆ’Ã‚Â­ an toÃƒÆ’Ã‚Â n Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã†â€™ chuyÃƒÂ¡Ã‚Â»Ã†â€™n nhÃƒÆ’Ã‚Â¢n vÃƒÂ¡Ã‚ÂºÃ‚Â­t
    local rootPart = getHumanoidRootPart()
    if rootPart then
        rootPart.CFrame = CFrame.new(
            1011.1289672851562,
            -1009.359588623046875,
            116.37605285644531
        )
    end
    
    -- GÃƒÂ¡Ã‚Â»Ã‚Â­i yÃƒÆ’Ã‚Âªu cÃƒÂ¡Ã‚ÂºÃ‚Â§u chuyÃƒÂ¡Ã‚Â»Ã†â€™n nhÃƒÆ’Ã‚Â¢n vÃƒÂ¡Ã‚ÂºÃ‚Â­t
    RS.Remotes.Character.ChangeCharacter:FireServer(characterName)
    
    -- ChÃƒÂ¡Ã‚Â»Ã‚Â cho Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚ÂºÃ‚Â¿n khi nhÃƒÆ’Ã‚Â¢n vÃƒÂ¡Ã‚ÂºÃ‚Â­t mÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºi spawn
    local groundY = workspace.Map.Structural.Ground:GetChildren()[21].Position.Y
    repeat 
        task.wait()
    until getHumanoidRootPart() and getHumanoidRootPart().Position.Y > groundY
    
    -- ChÃƒÂ¡Ã‚Â»Ã‚Â thÃƒÆ’Ã‚Âªm mÃƒÂ¡Ã‚Â»Ã¢â€žÂ¢t chÃƒÆ’Ã‚Âºt Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã†â€™ Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚ÂºÃ‚Â£m bÃƒÂ¡Ã‚ÂºÃ‚Â£o
    task.wait(0.15)
    
    -- Teleport trÃƒÂ¡Ã‚Â»Ã…Â¸ lÃƒÂ¡Ã‚ÂºÃ‚Â¡i vÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹ trÃƒÆ’Ã‚Â­ cÃƒâ€¦Ã‚Â©
    local newRootPart = getHumanoidRootPart()
    if newRootPart and lastSwitchPosition then
        repeat
            newRootPart.CFrame = lastSwitchPosition
            task.wait(0.1)
        until (newRootPart.Position - lastSwitchPosition.Position).Magnitude < 10
    end
    
    Library:Notify("Switched to " .. characterName, 3)
end

-- ThÃƒÆ’Ã‚Âªm nÃƒÆ’Ã‚Âºt chuyÃƒÂ¡Ã‚Â»Ã†â€™n Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¢i nhÃƒÆ’Ã‚Â¢n vÃƒÂ¡Ã‚ÂºÃ‚Â­t
CharacterSwitcherBox:AddButton({
    Text = "Switch ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ Gon",
    Func = function()
        switchCharacter("Gon")
    end,
    DoubleClick = false
})

CharacterSwitcherBox:AddButton({
    Text = "Switch ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ Nanami",
    Func = function()
        switchCharacter("Nanami")
    end,
    DoubleClick = false
})

CharacterSwitcherBox:AddButton({
    Text = "Switch ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ Mob",
    Func = function()
        switchCharacter("Mob")
    end,
    DoubleClick = false
})

-- ==================== VISUAL MAP PRESET ====================
-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n global cho Visual Map
if not _G.KZ_VisualModules then _G.KZ_VisualModules = {} end

_G.KZ_VisualModules.VisualMap = {
    enabled = false,
    selectedPreset = nil,
    originalAmbient = game.Lighting.Ambient,
    originalOutdoorAmbient = game.Lighting.OutdoorAmbient,
    effects = {}
}

-- Danh sÃƒÆ’Ã‚Â¡ch preset hiÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¡u ÃƒÂ¡Ã‚Â»Ã‚Â©ng hÃƒÆ’Ã‚Â¬nh ÃƒÂ¡Ã‚ÂºÃ‚Â£nh
local visualPresets = {
    ["Nature Green"] = {
        Ambient = Color3.fromRGB(70,255,150),
        OutdoorAmbient = Color3.fromRGB(40,200,120),
        Tint = Color3.fromRGB(140,255,180),
        Saturation = 0.25,
        Contrast = 0.18,
        Bloom = 2.2
    },
    ["Ocean Blue"] = {
        Ambient = Color3.fromRGB(80,110,255),
        OutdoorAmbient = Color3.fromRGB(50,80,255),
        Tint = Color3.fromRGB(180,200,255),
        Saturation = 0.3,
        Contrast = 0.2,
        Bloom = 3
    },
    ["Pink Love"] = {
        Ambient = Color3.fromRGB(255,150,200),
        OutdoorAmbient = Color3.fromRGB(255,120,180),
        Tint = Color3.fromRGB(255,170,210),
        Saturation = 0.35,
        Contrast = 0.15,
        Bloom = 2.5
    },
    ["Purple Dream"] = {
        Ambient = Color3.fromRGB(170,90,255),
        OutdoorAmbient = Color3.fromRGB(120,50,255),
        Tint = Color3.fromRGB(200,140,255),
        Saturation = 0.35,
        Contrast = 0.25,
        Bloom = 3.2
    },
    ["Sunset Orange"] = {
        Ambient = Color3.fromRGB(255,180,100),
        OutdoorAmbient = Color3.fromRGB(255,140,70),
        Tint = Color3.fromRGB(255,200,150),
        Saturation = 0.4,
        Contrast = 0.2,
        Bloom = 2.7
    },
    ["Cyan Sky"] = {
        Ambient = Color3.fromRGB(60,255,255),
        OutdoorAmbient = Color3.fromRGB(30,200,255),
        Tint = Color3.fromRGB(150,255,255),
        Saturation = 0.4,
        Contrast = 0.22,
        Bloom = 3.5
    }
}

-- HÃƒÆ’Ã‚Â m xÃƒÆ’Ã‚Â³a hiÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¡u ÃƒÂ¡Ã‚Â»Ã‚Â©ng
local function clearVisualEffects()
    pcall(function()
        for _, effect in ipairs(_G.KZ_VisualModules.VisualMap.effects) do
            if effect and effect.Parent then
                effect:Destroy()
            end
        end
        _G.KZ_VisualModules.VisualMap.effects = {}
    end)
end

-- HÃƒÆ’Ã‚Â m ÃƒÆ’Ã‚Â¡p dÃƒÂ¡Ã‚Â»Ã‚Â¥ng preset
local function applyVisualPreset(presetName)
    if not presetName or not visualPresets[presetName] then return end
    
    clearVisualEffects()
    
    local preset = visualPresets[presetName]
    local Lighting = game:GetService("Lighting")
    
    -- LÃƒâ€ Ã‚Â°u giÃƒÆ’Ã‚Â¡ trÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹ gÃƒÂ¡Ã‚Â»Ã¢â‚¬Ëœc nÃƒÂ¡Ã‚ÂºÃ‚Â¿u chÃƒâ€ Ã‚Â°a lÃƒâ€ Ã‚Â°u
    if not _G.KZ_VisualModules.VisualMap.originalAmbient then
        _G.KZ_VisualModules.VisualMap.originalAmbient = Lighting.Ambient
    end
    if not _G.KZ_VisualModules.VisualMap.originalOutdoorAmbient then
        _G.KZ_VisualModules.VisualMap.originalOutdoorAmbient = Lighting.OutdoorAmbient
    end
    
    -- TÃƒÂ¡Ã‚ÂºÃ‚Â¡o hiÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¡u ÃƒÂ¡Ã‚Â»Ã‚Â©ng ColorCorrection
    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "KZ_VisualMap_ColorCorrection"
    colorCorrection.TintColor = preset.Tint
    colorCorrection.Saturation = preset.Saturation
    colorCorrection.Contrast = preset.Contrast
    colorCorrection.Enabled = true
    colorCorrection.Parent = Lighting
    table.insert(_G.KZ_VisualModules.VisualMap.effects, colorCorrection)
    
    -- TÃƒÂ¡Ã‚ÂºÃ‚Â¡o hiÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¡u ÃƒÂ¡Ã‚Â»Ã‚Â©ng Bloom
    local bloom = Instance.new("BloomEffect")
    bloom.Name = "KZ_VisualMap_Bloom"
    bloom.Intensity = preset.Bloom
    bloom.Size = 40
    bloom.Threshold = 0.9
    bloom.Enabled = true
    bloom.Parent = Lighting
    table.insert(_G.KZ_VisualModules.VisualMap.effects, bloom)
    
    -- ÃƒÆ’Ã‚Âp dÃƒÂ¡Ã‚Â»Ã‚Â¥ng ambient lighting
    Lighting.Ambient = preset.Ambient
    Lighting.OutdoorAmbient = preset.OutdoorAmbient
    
    -- LÃƒâ€ Ã‚Â°u preset Ãƒâ€žÃ¢â‚¬Ëœang chÃƒÂ¡Ã‚Â»Ã‚Ân
    _G.KZ_VisualModules.VisualMap.selectedPreset = presetName
    
    print("Visual Map: Applied " .. presetName)
end

-- HÃƒÆ’Ã‚Â m reset vÃƒÂ¡Ã‚Â»Ã‚Â mÃƒÂ¡Ã‚ÂºÃ‚Â·c Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹nh
local function resetVisualEffects()
    clearVisualEffects()
    
    local Lighting = game:GetService("Lighting")
    
    -- KhÃƒÆ’Ã‚Â´i phÃƒÂ¡Ã‚Â»Ã‚Â¥c ambient lighting
    if _G.KZ_VisualModules.VisualMap.originalAmbient then
        Lighting.Ambient = _G.KZ_VisualModules.VisualMap.originalAmbient
    else
        Lighting.Ambient = Color3.fromRGB(127,127,127)
    end
    
    if _G.KZ_VisualModules.VisualMap.originalOutdoorAmbient then
        Lighting.OutdoorAmbient = _G.KZ_VisualModules.VisualMap.originalOutdoorAmbient
    else
        Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
    end
    
    _G.KZ_VisualModules.VisualMap.selectedPreset = nil
    _G.KZ_VisualModules.VisualMap.enabled = false
    
    print("Visual Map: Reset to default")
end

-- TÃƒÂ¡Ã‚ÂºÃ‚Â¡o GroupBox trong tab Emote Spam bÃƒÆ’Ã‚Âªn phÃƒÂ¡Ã‚ÂºÃ‚Â£i
local VisualMapBox = Tabs.EmoteSpam:AddRightGroupbox("Visual Map Preset")

-- Dropdown chÃƒÂ¡Ã‚Â»Ã‚Ân preset
VisualMapBox:AddDropdown("VisualPresetDropdown", {
    Values = {"Nature Green", "Ocean Blue", "Pink Love", "Purple Dream", "Sunset Orange", "Cyan Sky"},
    Default = "All",
    Multi = false,
    Text = "Visual Preset",
    Callback = function(value)
        _G.KZ_VisualModules.VisualMap.selectedPreset = value
        
        -- NÃƒÂ¡Ã‚ÂºÃ‚Â¿u Ãƒâ€žÃ¢â‚¬Ëœang bÃƒÂ¡Ã‚ÂºÃ‚Â­t visual map, ÃƒÆ’Ã‚Â¡p dÃƒÂ¡Ã‚Â»Ã‚Â¥ng ngay
        if _G.KZ_VisualModules.VisualMap.enabled then
            applyVisualPreset(value)
        end
    end
})

-- Toggle bÃƒÂ¡Ã‚ÂºÃ‚Â­t/tÃƒÂ¡Ã‚ÂºÃ‚Â¯t visual map
VisualMapBox:AddToggle("EnableVisualMap", {
    Text = "Enable Visual Map",
    Default = false,
    Callback = function(state)
        _G.KZ_VisualModules.VisualMap.enabled = state
        
        if state then
            if _G.KZ_VisualModules.VisualMap.selectedPreset then
                applyVisualPreset(_G.KZ_VisualModules.VisualMap.selectedPreset)
            else
                -- NÃƒÂ¡Ã‚ÂºÃ‚Â¿u chÃƒâ€ Ã‚Â°a chÃƒÂ¡Ã‚Â»Ã‚Ân preset, dÃƒÆ’Ã‚Â¹ng preset Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚ÂºÃ‚Â§u tiÃƒÆ’Ã‚Âªn
                _G.KZ_VisualModules.VisualMap.selectedPreset = "Nature Green"
                applyVisualPreset("Nature Green")
            end
            Library:Notify("Visual Map: ON", 3)
        else
            resetVisualEffects()
            Library:Notify("Visual Map: OFF", 3)
        end
    end
})

-- NÃƒÆ’Ã‚Âºt reset lighting
VisualMapBox:AddButton({
    Text = "Reset Lighting",
    Func = function()
        resetVisualEffects()
        Library:Notify("Lighting reset to default", 3)
    end,
    DoubleClick = false
})

-- NÃƒÆ’Ã‚Âºt apply preset (dÃƒÆ’Ã‚Â¹ng khi Ãƒâ€žÃ¢â‚¬ËœÃƒÆ’Ã‚Â£ chÃƒÂ¡Ã‚Â»Ã‚Ân preset nhÃƒâ€ Ã‚Â°ng chÃƒâ€ Ã‚Â°a bÃƒÂ¡Ã‚ÂºÃ‚Â­t toggle)
VisualMapBox:AddButton({
    Text = "Apply Selected Preset",
    Func = function()
        if _G.KZ_VisualModules.VisualMap.selectedPreset then
            applyVisualPreset(_G.KZ_VisualModules.VisualMap.selectedPreset)
            _G.KZ_VisualModules.VisualMap.enabled = true
            Library:Notify("Applied " .. _G.KZ_VisualModules.VisualMap.selectedPreset, 3)
        else
            Library:Notify("Please select a preset first", 3)
        end
    end,
    DoubleClick = false
})

-- ==================== ULTIMATE VFX COLOR MODULE ====================
-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n global cho VFX Color
if not _G.KZ_VFXModules then _G.KZ_VFXModules = {} end

_G.KZ_VFXModules.UltimateVFX = {
    enabled = false,
    trackingThread = nil,
    foundVFX = {},
    vfxColor = Color3.fromRGB(255, 0, 0), -- MÃƒÆ’Ã‚Â u Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã‚Â mÃƒÂ¡Ã‚ÂºÃ‚Â·c Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹nh
    vfxColorName = "Red",
    colorList = {
        -- MÃƒÆ’Ã‚Â u cÃƒâ€ Ã‚Â¡ bÃƒÂ¡Ã‚ÂºÃ‚Â£n
        ["Red"] = Color3.fromRGB(255, 0, 0),
        ["Green"] = Color3.fromRGB(0, 255, 0),
        ["Blue"] = Color3.fromRGB(0, 0, 255),
        ["Yellow"] = Color3.fromRGB(255, 255, 0),
        ["Purple"] = Color3.fromRGB(128, 0, 128),
        ["Cyan"] = Color3.fromRGB(0, 255, 255),
        ["Pink"] = Color3.fromRGB(255, 105, 180),
        
        -- MÃƒÆ’Ã‚Â u neon
        ["Neon Green"] = Color3.fromRGB(57, 255, 20),
        ["Neon Blue"] = Color3.fromRGB(0, 191, 255),
        ["Neon Pink"] = Color3.fromRGB(255, 20, 147),
        ["Neon Purple"] = Color3.fromRGB(186, 85, 211),
        ["Neon Yellow"] = Color3.fromRGB(255, 255, 0),
        ["Neon Orange"] = Color3.fromRGB(255, 69, 0),
        
        -- MÃƒÆ’Ã‚Â u RGB
        ["RGB Red"] = Color3.fromRGB(255, 0, 0),
        ["RGB Green"] = Color3.fromRGB(0, 255, 0),
        ["RGB Blue"] = Color3.fromRGB(0, 0, 255),
        ["RGB Yellow"] = Color3.fromRGB(255, 255, 0),
        ["RGB Cyan"] = Color3.fromRGB(0, 255, 255),
        ["RGB Magenta"] = Color3.fromRGB(255, 0, 255),
        
        -- MÃƒÆ’Ã‚Â u custom
        ["Gold"] = Color3.fromRGB(255, 215, 0),
        ["Silver"] = Color3.fromRGB(192, 192, 192),
        ["Hot Pink"] = Color3.fromRGB(255, 0, 127),
        ["Lime"] = Color3.fromRGB(50, 205, 50),
        ["Aqua"] = Color3.fromRGB(0, 255, 255),
        ["Coral"] = Color3.fromRGB(255, 127, 80),
        ["Violet"] = Color3.fromRGB(138, 43, 226),
        ["Teal"] = Color3.fromRGB(0, 128, 128),
        ["Orange"] = Color3.fromRGB(255, 165, 0),
        ["Rose"] = Color3.fromRGB(255, 0, 127),
        ["Sky Blue"] = Color3.fromRGB(135, 206, 235),
        ["Emerald"] = Color3.fromRGB(80, 200, 120),
        
        -- Rainbow colors
        ["Rainbow Red"] = Color3.fromRGB(255, 0, 0),
        ["Rainbow Orange"] = Color3.fromRGB(255, 127, 0),
        ["Rainbow Yellow"] = Color3.fromRGB(255, 255, 0),
        ["Rainbow Green"] = Color3.fromRGB(0, 255, 0),
        ["Rainbow Blue"] = Color3.fromRGB(0, 0, 255),
        ["Rainbow Indigo"] = Color3.fromRGB(75, 0, 130),
        ["Rainbow Violet"] = Color3.fromRGB(148, 0, 211),
        
        -- Gradient colors
        ["Gradient Pink"] = Color3.fromRGB(255, 105, 180),
        ["Gradient Blue"] = Color3.fromRGB(30, 144, 255),
        ["Gradient Purple"] = Color3.fromRGB(147, 112, 219),
        ["Gradient Teal"] = Color3.fromRGB(64, 224, 208),
        
        -- Special effects
        ["Fire Red"] = Color3.fromRGB(255, 69, 0),
        ["Ice Blue"] = Color3.fromRGB(173, 216, 230),
        ["Poison Green"] = Color3.fromRGB(0, 255, 127),
        ["Dark Purple"] = Color3.fromRGB(75, 0, 130),
        ["Light Gold"] = Color3.fromRGB(255, 223, 0),
        
        -- Custom VFX colors
        ["VFX White"] = Color3.fromRGB(255, 255, 255),
        ["VFX Black"] = Color3.fromRGB(0, 0, 0),
        ["VFX Gray"] = Color3.fromRGB(128, 128, 128),
        ["VFX Maroon"] = Color3.fromRGB(128, 0, 0),
        ["VFX Olive"] = Color3.fromRGB(128, 128, 0),
        ["VFX Navy"] = Color3.fromRGB(0, 0, 128),
    }
}

-- HÃƒÆ’Ã‚Â m tÃƒÆ’Ã‚Â¬m VFX
function _G.KZ_VFXModules.UltimateVFX:FindVFX()
    table.clear(self.foundVFX)
    local count = 0
    
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst.Name == "TransformationVFX" then
            if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
                table.insert(self.foundVFX, inst)
                count = count + 1
            end
        end
    end
    
    return count
end

-- HÃƒÆ’Ã‚Â m ÃƒÆ’Ã‚Â¡p dÃƒÂ¡Ã‚Â»Ã‚Â¥ng mÃƒÆ’Ã‚Â u cho tÃƒÂ¡Ã‚ÂºÃ‚Â¥t cÃƒÂ¡Ã‚ÂºÃ‚Â£ VFX
function _G.KZ_VFXModules.UltimateVFX:ApplyColorToAll()
    if #self.foundVFX == 0 then return end
    
    local seq = ColorSequence.new(self.vfxColor)
    for _, effect in ipairs(self.foundVFX) do
        if effect and effect.Parent then
            pcall(function()
                if effect:IsA("ParticleEmitter") then
                    effect.Color = seq
                elseif effect:IsA("Trail") then
                    effect.Color = seq
                elseif effect:IsA("Beam") then
                    for i = 0, 1 do
                        effect[i] = self.vfxColor
                    end
                end
            end)
        end
    end
end

-- HÃƒÆ’Ã‚Â m Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚ÂºÃ‚Â·t mÃƒÆ’Ã‚Â u
function _G.KZ_VFXModules.UltimateVFX:SetColor(colorName)
    if self.colorList[colorName] then
        self.vfxColor = self.colorList[colorName]
        self.vfxColorName = colorName
        if self.enabled then
            self:FindVFX()
            self:ApplyColorToAll()
        end
        print("VFX Color changed to: " .. colorName)
        return true
    end
    return false
end

-- HÃƒÆ’Ã‚Â m bÃƒÂ¡Ã‚ÂºÃ‚Â¯t Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚ÂºÃ‚Â§u
function _G.KZ_VFXModules.UltimateVFX:Start()
    if self.trackingThread then return end
    self.enabled = true
    
    self.trackingThread = task.spawn(function()
        while self.enabled do
            self:FindVFX()
            self:ApplyColorToAll()
            task.wait(0.5) -- KiÃƒÂ¡Ã‚Â»Ã†â€™m tra nhanh hÃƒâ€ Ã‚Â¡n mÃƒÂ¡Ã‚Â»Ã¢â‚¬â€i 0.5 giÃƒÆ’Ã‚Â¢y
        end
    end)
    
    Library:Notify("Ultimate VFX: ON", 3)
    print("Ultimate VFX Color Module: Enabled")
end

-- HÃƒÆ’Ã‚Â m dÃƒÂ¡Ã‚Â»Ã‚Â«ng
function _G.KZ_VFXModules.UltimateVFX:Stop()
    self.enabled = false
    if self.trackingThread then
        task.cancel(self.trackingThread)
        self.trackingThread = nil
    end
    table.clear(self.foundVFX)
    Library:Notify("Ultimate VFX: OFF", 3)
    print("Ultimate VFX Color Module: Disabled")
end

-- TÃƒÂ¡Ã‚ÂºÃ‚Â¡o GroupBox trong tab Emote Spam bÃƒÆ’Ã‚Âªn trÃƒÆ’Ã‚Â¡i
local VFXColorBox = Tabs.EmoteSpam:AddLeftGroupbox("Ultimate VFX Color")

-- LÃƒÂ¡Ã‚ÂºÃ‚Â¥y danh sÃƒÆ’Ã‚Â¡ch mÃƒÆ’Ã‚Â u cho dropdown
local colorNames = {}
for name, _ in pairs(_G.KZ_VFXModules.UltimateVFX.colorList) do
    table.insert(colorNames, name)
end
table.sort(colorNames) -- SÃƒÂ¡Ã‚ÂºÃ‚Â¯p xÃƒÂ¡Ã‚ÂºÃ‚Â¿p theo thÃƒÂ¡Ã‚Â»Ã‚Â© tÃƒÂ¡Ã‚Â»Ã‚Â± alphabet

-- Dropdown chÃƒÂ¡Ã‚Â»Ã‚Ân mÃƒÆ’Ã‚Â u VFX
VFXColorBox:AddDropdown("VFXColorDropdown", {
    Values = colorNames,
    Default = "Red",
    Multi = false,
    Text = "VFX Color",
    Callback = function(value)
        _G.KZ_VFXModules.UltimateVFX:SetColor(value)
    end
})

-- Toggle bÃƒÂ¡Ã‚ÂºÃ‚Â­t/tÃƒÂ¡Ã‚ÂºÃ‚Â¯t VFX Color
VFXColorBox:AddToggle("EnableVFXColor", {
    Text = "Enable VFX Color",
    Default = false,
    Callback = function(state)
        if state then
            _G.KZ_VFXModules.UltimateVFX:Start()
        else
            _G.KZ_VFXModules.UltimateVFX:Stop()
        end
    end
})

-- NÃƒÆ’Ã‚Âºt Refresh VFX (tÃƒÆ’Ã‚Â¬m lÃƒÂ¡Ã‚ÂºÃ‚Â¡i VFX)
VFXColorBox:AddButton({
    Text = "Refresh VFX",
    Func = function()
        local count = _G.KZ_VFXModules.UltimateVFX:FindVFX()
        Library:Notify("Found " .. count .. " VFX objects", 3)
        print("VFX Refresh: Found " .. count .. " objects")
        
        if _G.KZ_VFXModules.UltimateVFX.enabled then
            _G.KZ_VFXModules.UltimateVFX:ApplyColorToAll()
        end
    end,
    DoubleClick = false
})

-- NÃƒÆ’Ã‚Âºt Preview Color (xem trÃƒâ€ Ã‚Â°ÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºc mÃƒÆ’Ã‚Â u)
VFXColorBox:AddButton({
    Text = "Preview Color",
    Func = function()
        local color = _G.KZ_VFXModules.UltimateVFX.vfxColor
        local colorName = _G.KZ_VFXModules.UltimateVFX.vfxColorName
        
        -- TÃƒÂ¡Ã‚ÂºÃ‚Â¡o mÃƒÂ¡Ã‚Â»Ã¢â€žÂ¢t part Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã†â€™ preview mÃƒÆ’Ã‚Â u
        local previewPart = Instance.new("Part")
        previewPart.Size = Vector3.new(2, 2, 2)
        previewPart.Position = Vector3.new(0, 5, 0)
        previewPart.Anchored = true
        previewPart.CanCollide = false
        previewPart.Material = Enum.Material.Neon
        previewPart.Color = color
        previewPart.Parent = workspace
        
        -- ThÃƒÆ’Ã‚Âªm light Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã†â€™ highlight
        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = 5
        pointLight.Range = 10
        pointLight.Color = color
        pointLight.Parent = previewPart
        
        Library:Notify("Preview: " .. colorName, 3)
        
        -- TÃƒÂ¡Ã‚Â»Ã‚Â± Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â€žÂ¢ng xÃƒÆ’Ã‚Â³a sau 3 giÃƒÆ’Ã‚Â¢y
        task.delay(3, function()
            if previewPart and previewPart.Parent then
                previewPart:Destroy()
            end
        end)
    end,
    DoubleClick = false
})

-- Label hiÃƒÂ¡Ã‚Â»Ã†â€™n thÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹ thÃƒÆ’Ã‚Â´ng tin
VFXColorBox:AddLabel("Changes Transformation VFX colors")
VFXColorBox:AddLabel("Works on ParticleEmitter/Trail/Beam")

-- ThÃƒÆ’Ã‚Âªm rainbow mode (tÃƒÂ¡Ã‚Â»Ã‚Â± Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â€žÂ¢ng thay Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¢i mÃƒÆ’Ã‚Â u)
VFXColorBox:AddToggle("RainbowMode", {
    Text = "Rainbow Mode",
    Default = false,
    Callback = function(state)
        if state then
            local rainbowThread = task.spawn(function()
                local rainbowColors = {
                    "Rainbow Red", "Rainbow Orange", "Rainbow Yellow",
                    "Rainbow Green", "Rainbow Blue", "Rainbow Indigo", "Rainbow Violet"
                }
                local index = 1
                
                while _G.KZ_VFXModules.UltimateVFX.enabled and state do
                    _G.KZ_VFXModules.UltimateVFX:SetColor(rainbowColors[index])
                    index = index + 1
                    if index > #rainbowColors then index = 1 end
                    task.wait(0.5) -- Thay Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¢i mÃƒÆ’Ã‚Â u mÃƒÂ¡Ã‚Â»Ã¢â‚¬â€i 0.5 giÃƒÆ’Ã‚Â¢y
                end
            end)
            _G.KZ_VFXModules.UltimateVFX.rainbowThread = rainbowThread
        else
            if _G.KZ_VFXModules.UltimateVFX.rainbowThread then
                task.cancel(_G.KZ_VFXModules.UltimateVFX.rainbowThread)
                _G.KZ_VFXModules.UltimateVFX.rainbowThread = nil
            end
        end
    end
})

-- ==================== STUCK MODE (EMOTE TAB) ====================
-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n global cho Stuck Mode trong Emote tab
if not _G.KZ_EmoteStuckModules then _G.KZ_EmoteStuckModules = {} end

_G.KZ_EmoteStuckModules.StuckMode = {
    HitboxToggle = false,
    HitboxX = 50,  -- Size mÃƒÂ¡Ã‚ÂºÃ‚Â·c Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹nh 50
    HitboxY = 50,  -- Size mÃƒÂ¡Ã‚ÂºÃ‚Â·c Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹nh 50
    HitboxZ = 50,  -- Size mÃƒÂ¡Ã‚ÂºÃ‚Â·c Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹nh 50
    EnhancerToggle = false,
    EnhancerMultiplier = 5,
    DashMethod = false,
    BasicHitbox = false,
    BasicSize = 18
}

-- BIÃƒÂ¡Ã‚ÂºÃ‚Â¾N GLOBAL
_G.KZ_EmoteStuckModules.HitboxCache = {
    OriginalBox = nil,
    OriginalProcess = nil,
    DashConnection = nil,
    LastDash = 0,
    BasicOriginal = nil
}

-- BIÃƒÂ¡Ã‚ÂºÃ‚Â¾N GLOBAL
_G.KZ_EmoteStuckModules.HitboxEnabled = false

local function HRP()
    return localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- HÃƒÆ’Ã‚Â m toggle hitbox
local function toggleHitbox(state)
    _G.KZ_EmoteStuckModules.HitboxEnabled = state
    _G.KZ_EmoteStuckModules.StuckMode.HitboxToggle = state

    local ok, core = pcall(function()
        return require(RS:WaitForChild("Core"))
    end)
    if not ok then return end

    local hit = core.Get and core.Get("Combat", "Hit")
    if not hit or not hit.Box then return end

    if state then
        if not _G.KZ_EmoteStuckModules.HitboxCache.OriginalBox then 
            _G.KZ_EmoteStuckModules.HitboxCache.OriginalBox = hit.Box 
        end
        hit.Box = function(_, char, data)
            data = data or {}
            data.Size = Vector3.new(
                _G.KZ_EmoteStuckModules.StuckMode.HitboxX, 
                _G.KZ_EmoteStuckModules.StuckMode.HitboxY, 
                _G.KZ_EmoteStuckModules.StuckMode.HitboxZ
            )
            return _G.KZ_EmoteStuckModules.HitboxCache.OriginalBox(nil, char, data)
        end
    else
        if _G.KZ_EmoteStuckModules.HitboxCache.OriginalBox then
            hit.Box = _G.KZ_EmoteStuckModules.HitboxCache.OriginalBox
        end
    end
end

-- HÃƒÆ’Ã‚Â m dash vÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºi cooldown
local DASH_CD = 0.18
local function dash()
    if tick() - _G.KZ_EmoteStuckModules.HitboxCache.LastDash < DASH_CD then return end
    _G.KZ_EmoteStuckModules.HitboxCache.LastDash = tick()

    local hrp = HRP()
    if hrp then
        pcall(function()
            require(RS.Core)
                .Library("Remote")
                .Send("Dash", hrp.CFrame, "L", 1)
        end)
    end
end

-- HÃƒÆ’Ã‚Â m bÃƒÂ¡Ã‚ÂºÃ‚Â­t/tÃƒÂ¡Ã‚ÂºÃ‚Â¯t enhancer
local function toggleEnhancer(state)
    _G.KZ_EmoteStuckModules.StuckMode.EnhancerToggle = state
    
    local ok, hit = pcall(function()
        return require(localPlayer.PlayerScripts.Combat.Hit)
    end)
    if not ok or not hit.Process then return end

    if state then
        if not _G.KZ_EmoteStuckModules.HitboxCache.OriginalProcess then
            _G.KZ_EmoteStuckModules.HitboxCache.OriginalProcess = hit.Process
        end
        hit.Process = function(...)
            local best, targets, blocked = _G.KZ_EmoteStuckModules.HitboxCache.OriginalProcess(...)
            if targets and #targets > 0 then
                dash()
                for i = 1, _G.KZ_EmoteStuckModules.StuckMode.EnhancerMultiplier do
                    RS.Remotes.Combat.Action:FireServer(
                        nil, "", 4, 69,
                        {BestHitCharacter=nil, HitCharacters=targets, Ignore={}, Actions={}}
                    )
                end
            end
            return best, targets, blocked
        end
    else
        if _G.KZ_EmoteStuckModules.HitboxCache.OriginalProcess then
            hit.Process = _G.KZ_EmoteStuckModules.HitboxCache.OriginalProcess
        end
    end
end

-- HÃƒÆ’Ã‚Â m bÃƒÂ¡Ã‚ÂºÃ‚Â­t/tÃƒÂ¡Ã‚ÂºÃ‚Â¯t dash method
local function toggleDashMethod(state)
    _G.KZ_EmoteStuckModules.StuckMode.DashMethod = state
    
    if state then
        if _G.KZ_EmoteStuckModules.HitboxCache.DashConnection then return end
        _G.KZ_EmoteStuckModules.HitboxCache.DashConnection = RunService.Heartbeat:Connect(function()
            local hrp = HRP()
            if hrp then
                pcall(function()
                    require(RS.Core)
                        .Library("Remote")
                        .Send("Dash", hrp.CFrame, "L", 1)
                end)
            end
        end)
    else
        if _G.KZ_EmoteStuckModules.HitboxCache.DashConnection then
            _G.KZ_EmoteStuckModules.HitboxCache.DashConnection:Disconnect()
            _G.KZ_EmoteStuckModules.HitboxCache.DashConnection = nil
        end
    end
end

-- ThÃƒÆ’Ã‚Âªm GroupBox cho Stuck Mode trong tab Emote Spam bÃƒÆ’Ã‚Âªn phÃƒÂ¡Ã‚ÂºÃ‚Â£i
local EmoteStuckModeBox = Tabs.EmoteSpam:AddRightGroupbox("Stuck Mode")

-- Toggle Hitbox
EmoteStuckModeBox:AddToggle("StuckModeToggle", {
    Text = "Stuck Mode",
    Default = false,
    Callback = function(v)
        toggleHitbox(v)
        print("Stuck Mode: " .. (v and "ON" or "OFF"))
    end
})

-- Toggle Hitbox Legit (Enhancer)
EmoteStuckModeBox:AddToggle("StuckModeLegit", {
    Text = "Stuck Mode Legit",
    Default = false,
    Callback = function(v)
        toggleEnhancer(v)
        print("Stuck Mode Legit: " .. (v and "ON" or "OFF"))
    end
})

-- Toggle Dash Method
EmoteStuckModeBox:AddToggle("StuckModeMethod", {
    Text = "Stuck Mode Method",
    Default = false,
    Callback = function(v)
        toggleDashMethod(v)
        print("Stuck Mode Method: " .. (v and "ON" or "OFF"))
    end
})
-- TARGET LOCK MODULE
local TargetLockGroup = Tabs.EmoteSpam:AddRightGroupbox("Target Player")

local BEHIND_DISTANCE = 5
local followEnabled = false
local circleEnabled = false
local lookEnabled = false
local selectedTargetName = nil
local followConnection, circleConnection, lookConnection
local circleRadius, circleSpeed, circleAngle = 6, 13, 0

local function getHRP(plr)
    return plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerByName(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name == name then return p end
    end
end

local function startFollow()
    followConnection = RunService.RenderStepped:Connect(function()
        if not followEnabled then return end
        local my = getHRP(localPlayer)
        local t = getHRP(getPlayerByName(selectedTargetName))
        if my and t then
            local pos = t.Position - t.CFrame.LookVector * BEHIND_DISTANCE
            my.CFrame = CFrame.new(pos.X, t.Position.Y, pos.Z)
        end
    end)
end

local function startCircle()
    circleConnection = RunService.RenderStepped:Connect(function(dt)
        if not circleEnabled then return end
        local my = getHRP(localPlayer)
        local t = getHRP(getPlayerByName(selectedTargetName))
        if my and t then
            circleAngle = circleAngle + circleSpeed * dt
            local x = math.cos(circleAngle) * circleRadius
            local z = math.sin(circleAngle) * circleRadius
            my.CFrame = CFrame.new(t.Position.X + x, t.Position.Y, t.Position.Z + z)
        end
    end)
end

local function startLook()
    lookConnection = RunService.RenderStepped:Connect(function()
        if not lookEnabled then return end
        local my = getHRP(localPlayer)
        local t = getHRP(getPlayerByName(selectedTargetName))
        if my and t then
            my.CFrame = CFrame.new(my.Position, Vector3.new(t.Position.X, my.Position.Y, t.Position.Z))
        end
    end)
end

local function stopConnections()
    if followConnection then followConnection:Disconnect() end
    if circleConnection then circleConnection:Disconnect() end
    if lookConnection then lookConnection:Disconnect() end
    followConnection, circleConnection, lookConnection = nil, nil, nil
    circleAngle = 0
end

local function updatePlayerListForTarget()
    local playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            table.insert(playerNames, p.Name)
        end
    end
    return playerNames
end

local targetDropdown = TargetLockGroup:AddDropdown("TL_PlayerList", {
    Text = "Select Target",
    Multi = false,
    Values = updatePlayerListForTarget(),
    Callback = function(v)
        selectedTargetName = v
        print("Target selected:", v)
    end
})

TargetLockGroup:AddButton("Refresh Player List", function()
    targetDropdown:SetValues(updatePlayerListForTarget())
    Library:Notify("Player list refreshed", 2)
end)

TargetLockGroup:AddSlider("TL_Distance", {
    Text = "Behind Distance",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Callback = function(v)
        BEHIND_DISTANCE = v
        print("Behind distance set to:", v)
    end
})

TargetLockGroup:AddSlider("TL_CircleRadius", {
    Text = "Circle Radius",
    Default = 6,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Callback = function(v)
        circleRadius = v
        print("Circle radius set to:", v)
    end
})

TargetLockGroup:AddSlider("TL_CircleSpeed", {
    Text = "Circle Speed",
    Default = 13,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(v)
        circleSpeed = v
        print("Circle speed set to:", v)
    end
})

TargetLockGroup:AddToggle("TL_Follow", {
    Text = "Behind Lock",
    Default = false,
    Callback = function(state)
        followEnabled = state
        if state then 
            if selectedTargetName then
                stopConnections()
                startFollow()
                Library:Notify("Behind Lock: ON - " .. selectedTargetName, 2)
            else
                Library:Notify("Please select a target first", 2)
                Toggles.TL_Follow:SetValue(false)
            end
        else 
            stopConnections()
            Library:Notify("Behind Lock: OFF", 2)
        end
    end
})

TargetLockGroup:AddToggle("TL_Circle", {
    Text = "Circle Player",
    Default = false,
    Callback = function(state)
        circleEnabled = state
        if state then 
            if selectedTargetName then
                stopConnections()
                startCircle()
                Library:Notify("Circle Player: ON - " .. selectedTargetName, 2)
            else
                Library:Notify("Please select a target first", 2)
                Toggles.TL_Circle:SetValue(false)
            end
        else 
            stopConnections()
            Library:Notify("Circle Player: OFF", 2)
        end
    end
})

TargetLockGroup:AddToggle("TL_Look", {
    Text = "Look At Player",
    Default = false,
    Callback = function(state)
        lookEnabled = state
        if state then 
            if selectedTargetName then
                stopConnections()
                startLook()
                Library:Notify("Look At Player: ON - " .. selectedTargetName, 2)
            else
                Library:Notify("Please select a target first", 2)
                Toggles.TL_Look:SetValue(false)
            end
        else 
            stopConnections()
            Library:Notify("Look At Player: OFF", 2)
        end
    end
})

TargetLockGroup:AddButton("Reset All", function()
    followEnabled = false
    circleEnabled = false
    lookEnabled = false
    stopConnections()
    
    Toggles.TL_Follow:SetValue(false)
    Toggles.TL_Circle:SetValue(false)
    Toggles.TL_Look:SetValue(false)
    
    Library:Notify("Target Lock reset", 2)
end)

TargetLockGroup:AddLabel("Select target then toggle a mode")
TargetLockGroup:AddLabel("Modes are mutually exclusive")



end)
task.spawn(function()
    repeat task.wait() until getgenv().JoshubTabs and getgenv().JoshubTabs.UI
    local Tabs = getgenv().JoshubTabs

local MenuGroup = Tabs.UI:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})
MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",

    Text = "Notification Side",

    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})
MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",

    Text = "DPI Scale",

    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)

        Library:SetDPIScale(DPI)
    end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place")

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs.UI)
end)


-- GLOBAL VARIABLES
_G.KA = {
    V1 = {Running = false, Conn = nil},
    V2 = {Running = false, Connections = {}, AutoToggleConn = nil},
    Circle = {Parts = {}, Conn = nil},
    Farm = {Running = false, Connections = {}}
}

_G.KA_Config = {
    V1 = {IgnoreFriends = false, MaxDistance = 50, Damage = 1, HealthLimit = 0, DashInterval = 0.7, LastDash = 0},
    V2 = {IgnoreFriends = false, IgnoreDeadPlayers = true, Distance = 50, LastDash = 0, DashInterval = 0.7, AutoToggleEnabled = false},
    Farm = {IgnoreFriends = false, Range = 67.5, TargetSelection = "Closest", Enabled = false}
}

-- KILL AURA V1 FUNCTIONS
_G.KA_triggerDash = function()
    if tick() - _G.KA_Config.V1.LastDash < _G.KA_Config.V1.DashInterval then return end
    _G.KA_Config.V1.LastDash = tick()
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local dashArgs = {[1]=hrp.CFrame,[2]="L",[3]=hrp.CFrame.LookVector,[5]=tick()}
    local dashRemote = RS.Remotes.Character:FindFirstChild("Dash")
    if dashRemote then pcall(function() dashRemote:FireServer(unpack(dashArgs)) end) end
end

_G.KA_sendKillAura = function()
    local Character = localPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    
    local CharactersFolder = RS:FindFirstChild("Characters")
    local RemotesFolder = RS:FindFirstChild("Remotes")
    if not CharactersFolder or not RemotesFolder then return end
    
    local AbilitiesRemote = RemotesFolder:FindFirstChild("Abilities")
    local CombatRemote = RemotesFolder:FindFirstChild("Combat")
    
    if AbilitiesRemote then AbilitiesRemote = AbilitiesRemote:FindFirstChild("Ability") end
    if CombatRemote then CombatRemote = CombatRemote:FindFirstChild("Action") end
    if not AbilitiesRemote or not CombatRemote then return end
    
    local CharacterName = localPlayer:FindFirstChild("Data") and localPlayer.Data:FindFirstChild("Character") and localPlayer.Data.Character.Value or "DefaultCharacter"
    local WallCombo = CharactersFolder:FindFirstChild(CharacterName)
    if not WallCombo then return end
    WallCombo = WallCombo:FindFirstChild("WallCombo") or "WallCombo"
    
    local localRootPart = Character.HumanoidRootPart
    pcall(function() _G.KA_triggerDash() end)
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer == localPlayer then continue end
        if not targetPlayer.Character then continue end
        if not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then continue end
        
        -- IGNORE FRIENDS (DÃƒÆ’Ã¢â€žÂ¢NG CHUNG CHO CÃƒÂ¡Ã‚ÂºÃ‚Â¢ V1 VÃƒÆ’Ã¢â€šÂ¬ V2)
        if _G.KA_Config.V1.IgnoreFriends then
            local success, isFriend = pcall(function() return localPlayer:IsFriendsWith(targetPlayer.UserId) end)
            if success and isFriend then continue end
        end
        
        local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        local targetRootPart = targetPlayer.Character.HumanoidRootPart
        
        if not targetHumanoid then continue end
        local targetHealth = targetHumanoid.Health or targetHumanoid:GetAttribute("Health") or 100
        if targetHealth <= _G.KA_Config.V1.HealthLimit then continue end
        
        local distanceToTarget = (localRootPart.Position - targetRootPart.Position).Magnitude
        if distanceToTarget > _G.KA_Config.V1.MaxDistance then continue end
        
        pcall(function() AbilitiesRemote:FireServer(WallCombo, _G.KA_Config.V1.Damage, {}, targetRootPart.Position) end)
        pcall(function()
            local combatArgs = {
                WallCombo, CharacterName..":WallCombo", 2, _G.KA_Config.V1.Damage,
                {
                    HitboxCFrames = {targetRootPart.CFrame, targetRootPart.CFrame},
                    BestHitCharacter = targetPlayer.Character,
                    HitCharacters = {targetPlayer.Character},
                    Ignore = {},
                    DeathInfo = {},
                    BlockedCharacters = {},
                    HitInfo = {IsFacing = false, IsInFront = true},
                    ServerTime = os.time(),
                    Actions = {
                        ActionNumber1 = {
                            [targetPlayer.Name] = {
                                StartCFrameStr = tostring(localRootPart.CFrame),
                                Local = true,
                                Collision = false,
                                Animation = "Punch1Hit",
                                Preset = "Punch",
                                Velocity = Vector3.zero,
                                FromPosition = targetRootPart.Position,
                                Seed = math.random(1, 999999)
                            }
                        }
                    },
                    FromCFrame = targetRootPart.CFrame
                },
                "Action150",0
            }
            CombatRemote:FireServer(unpack(combatArgs))
        end)
    end
end

_G.KA_startKillAuraV1 = function()
    if _G.KA.V1.Conn then _G.KA.V1.Conn:Disconnect() end
    _G.KA.V1.Conn = RunService.Heartbeat:Connect(function()
        if _G.KA.V1.Running then _G.KA_sendKillAura() end
    end)
end

-- KILL AURA V2 FUNCTIONS
_G.KA_isPlayerDead = function(targetPlayer)
    if not targetPlayer.Character then return true end
    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not targetHumanoid then return true end
    local health = targetHumanoid:GetAttribute("Health")
    if health and health <= 0 then return true end
    if targetHumanoid.Health <= 0 then return true end
    return false
end

_G.KA_attackNearestPlayerV2 = function()
    if not _G.KA.V2.Running then return end
    if not localPlayer.Character then return end
    if not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local localRoot = localPlayer.Character.HumanoidRootPart
    local closestPlayer, closestDistance = nil, _G.KA_Config.V2.Distance
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == localPlayer then continue end
        if not player.Character then continue end
        if not player.Character:FindFirstChild("HumanoidRootPart") then continue end
        if not player.Character:FindFirstChild("Humanoid") then continue end
        
        -- IGNORE DEAD PLAYERS V2
        if _G.KA_Config.V2.IgnoreDeadPlayers and _G.KA_isPlayerDead(player) then continue end
        
        -- IGNORE FRIENDS (DÃƒÆ’Ã¢â€žÂ¢NG CHUNG CHO CÃƒÂ¡Ã‚ÂºÃ‚Â¢ V1 VÃƒÆ’Ã¢â€šÂ¬ V2)
        if _G.KA_Config.V1.IgnoreFriends then
            local success, isFriend = pcall(function() return localPlayer:IsFriendsWith(player.UserId) end)
            if success and isFriend then continue end
        end
        
        if player.Character.Humanoid.Health <= 0 then continue end
        
        local targetRoot = player.Character.HumanoidRootPart
        local dist = (localRoot.Position - targetRoot.Position).Magnitude
        if dist < closestDistance then closestDistance, closestPlayer = dist, player end
    end
    
    if closestPlayer then
        if tick() - _G.KA_Config.V2.LastDash >= _G.KA_Config.V2.DashInterval then
            _G.KA_Config.V2.LastDash = tick()
            local hrp = localPlayer.Character.HumanoidRootPart
            local dashRemote = RS.Remotes.Character:FindFirstChild("Dash")
            if dashRemote then pcall(function() dashRemote:FireServer(hrp.CFrame, "L", hrp.CFrame.LookVector, tick()) end) end
        end
        
        local CharactersFolder = RS:FindFirstChild("Characters")
        local RemotesFolder = RS:FindFirstChild("Remotes")
        if not CharactersFolder or not RemotesFolder then return end
        
        local AbilitiesRemote = RemotesFolder:FindFirstChild("Abilities")
        local CombatRemote = RemotesFolder:FindFirstChild("Combat")
        if AbilitiesRemote then AbilitiesRemote = AbilitiesRemote:FindFirstChild("Ability") end
        if CombatRemote then CombatRemote = CombatRemote:FindFirstChild("Action") end
        if not AbilitiesRemote or not CombatRemote then return end
        
        local CharacterName = localPlayer:FindFirstChild("Data") and localPlayer.Data:FindFirstChild("Character") and localPlayer.Data.Character.Value
        if not CharacterName then return end
        
        local WallCombo = CharactersFolder:FindFirstChild(CharacterName)
        if not WallCombo then return end
        WallCombo = WallCombo:FindFirstChild("WallCombo")
        if not WallCombo then return end
        
        local targetRoot = closestPlayer.Character.HumanoidRootPart
        
        pcall(function() AbilitiesRemote:FireServer(WallCombo, 1, {}, targetRoot.Position) end)
        pcall(function()
            local combatArgs = {
                WallCombo, CharacterName..":WallCombo", 2, 1,
                {
                    HitboxCFrames={targetRoot.CFrame, targetRoot.CFrame},
                    BestHitCharacter=closestPlayer.Character,
                    HitCharacters={closestPlayer.Character},
                    Ignore={},
                    DeathInfo={},
                    BlockedCharacters={},
                    HitInfo={IsFacing=false,IsInFront=true},
                    ServerTime=os.time(),
                    Actions={
                        ActionNumber1={
                            [closestPlayer.Name]={
                                StartCFrameStr=tostring(localRoot.CFrame),
                                Local=true,
                                Collision=false,
                                Animation="Punch1Hit",
                                Preset="Punch",
                                Velocity=Vector3.zero,
                                FromPosition=targetRoot.Position,
                                Seed=math.random(1,999999)
                            }
                        }
                    },
                    FromCFrame=targetRoot.CFrame
                },
                "Action150",0
            }
            CombatRemote:FireServer(unpack(combatArgs))
        end)
    end
end

_G.KA_startKillAurasV2 = function()
    for i = 1, 9 do
        local conn = RunService.Heartbeat:Connect(function()
            if _G.KA.V2.Running then
                _G.KA_attackNearestPlayerV2()
                task.wait(0.02)
            end
        end)
        table.insert(_G.KA.V2.Connections, conn)
    end
end



_G.KA_stopKillAurasV2 = function()
    for _, conn in ipairs(_G.KA.V2.Connections) do conn:Disconnect() end
    _G.KA.V2.Connections = {}
end

_G.KA_startAutoToggleV2 = function()
    _G.KA.V2.AutoToggleConn = RunService.Heartbeat:Connect(function()
        if not _G.KA.V2.Running then return end
        if not _G.KA_Config.V2.AutoToggleEnabled then return end
        
        local hasTargets = false
        if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local localRoot = localPlayer.Character.HumanoidRootPart
            for _, player in ipairs(Players:GetPlayers()) do
                if player == localPlayer then continue end
                if not player.Character then continue end
                if not player.Character:FindFirstChild("HumanoidRootPart") then continue end
                if not player.Character:FindFirstChild("Humanoid") then continue end
                
                if _G.KA_Config.V2.IgnoreDeadPlayers and _G.KA_isPlayerDead(player) then continue end
                
                -- IGNORE FRIENDS (DÃƒÆ’Ã¢â€žÂ¢NG CHUNG)
                if _G.KA_Config.V1.IgnoreFriends then
                    local success, isFriend = pcall(function() return localPlayer:IsFriendsWith(player.UserId) end)
                    if success and isFriend then continue end
                end
                
                if player.Character.Humanoid.Health <= 0 then continue end
                
                local targetRoot = player.Character.HumanoidRootPart
                local dist = (localRoot.Position - targetRoot.Position).Magnitude
                if dist <= _G.KA_Config.V2.Distance then hasTargets = true break end
            end
        end
        
        if hasTargets and #_G.KA.V2.Connections == 0 then
            _G.KA_startKillAurasV2()
        elseif not hasTargets and #_G.KA.V2.Connections > 0 then
            _G.KA_stopKillAurasV2()
        end
    end)
end

_G.KA_stopAutoToggleV2 = function()
    if _G.KA.V2.AutoToggleConn then
        _G.KA.V2.AutoToggleConn:Disconnect()
        _G.KA.V2.AutoToggleConn = nil
    end
end

-- KILL FARMING FUNCTIONS
_G.KA_isFriend = function(p)
    return p and p ~= localPlayer and localPlayer:IsFriendsWith(p.UserId)
end

_G.KA_getRandomAlivePlayer = function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            if _G.KA_Config.Farm.IgnoreFriends and _G.KA_isFriend(p) then continue end
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and (hum:GetAttribute("Health") or 0) > 0 then
                table.insert(list,p)
            end
        end
    end
    if #list > 0 then
        return list[math.random(#list)]
    end
end

_G.KA_teleportUnderPlayer = function(p)
    local hrp = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if hrp and localPlayer.Character then
        pcall(function()
            require(localPlayer.PlayerScripts.Character.FullCustomReplication)
                .Override(localPlayer.Character, CFrame.new(hrp.Position - Vector3.new(0,30,0)))
        end)
    end
end

_G.KA_spectatePlayer = function(p)
    local cam = Workspace.CurrentCamera
    local hum = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if cam and hum then
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = hum
    end
end

_G.KA_farmLoop = function()
    local p = _G.KA_getRandomAlivePlayer()
    if p then
        _G.KA_teleportUnderPlayer(p)
        _G.KA_spectatePlayer(p)
    end
end

_G.KA_lpdash = function()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            require(RS:WaitForChild("Core"))
                .Library("Remote")
                .Send("Dash", hrp.CFrame, "L", 1)
        end)
    end
end

_G.KA_KillFarmAura = function(n)
    if not (localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")) then return end
    
    local PlayersList = {}
    local index = 1
    local hrp = localPlayer.Character.HumanoidRootPart
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            if _G.KA_Config.Farm.IgnoreFriends and _G.KA_isFriend(p) then continue end
            local hum = p.Character:FindFirstChild("Humanoid")
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and not p.Character:GetAttribute("Invincible") then
                local dist = (root.Position - hrp.Position).Magnitude
                if dist <= _G.KA_Config.Farm.Range then
                    local health = hum:GetAttribute("Health") or hum.Health or 0
                    if health > 0 then
                        for i = 1, n do
                            PlayersList[index] = p.Character
                            index = index + 1
                        end
                    end
                end
            end
        end
    end
    
    if index > 1 then
        pcall(function()
            local wc = RS.Characters[localPlayer.Data.Character.Value].WallCombo
            RS.Remotes.Abilities.Ability:FireServer(wc,69)
            RS.Remotes.Combat.Action:FireServer(wc,"",4,69,{
                BestHitCharacter=nil,
                HitCharacters=PlayersList,
                Ignore={},
                Actions={}
            })
        end)
    end
end

_G.KA_setGravity = function(state)
    local char = localPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = not state
            v.AssemblyLinearVelocity = Vector3.zero
            v.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

_G.KA_startKillFarming = function()
    _G.KA_setGravity(false)
    
    table.insert(_G.KA.Farm.Connections, RunService.Heartbeat:Connect(_G.KA_farmLoop))
    table.insert(_G.KA.Farm.Connections, RunService.Heartbeat:Connect(function()
        _G.KA_lpdash()
        local c = localPlayer.Data.Character.Value
        _G.KA_KillFarmAura(c == "Gon" and 20 or 50)
    end))
end

_G.KA_stopKillFarming = function()
    for _, conn in ipairs(_G.KA.Farm.Connections) do
        conn:Disconnect()
    end
    _G.KA.Farm.Connections = {}
    
    _G.KA_setGravity(true)
    
    -- Reset camera
    local cam = Workspace.CurrentCamera
    if cam then
        cam.CameraType = Enum.CameraType.Custom
        if localPlayer.Character then
            local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then cam.CameraSubject = hum end
        end
    end
end

-- AUTO CLAIM EMOTE FUNCTIONS
_G.EC = {Running = false, Conn = nil}

_G.EC_start = function()
    if _G.EC.Conn then _G.EC.Conn:Disconnect() end
    
    local CombatFolder = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Combat")
    if not CombatFolder then return end
    
    local EmoteClaimRemote = CombatFolder:FindFirstChild("EmoteClaim")
    if not EmoteClaimRemote then return end
    
    _G.EC.Conn = RunService.Heartbeat:Connect(function()
        if _G.EC.Running then
            pcall(function()
                EmoteClaimRemote:FireServer()
            end)
        end
    end)
end

_G.EC_stop = function()
    if _G.EC.Conn then
        _G.EC.Conn:Disconnect()
        _G.EC.Conn = nil
    end
end

-- CIRCLE FUNCTIONS
_G.KA_CreateCircle = function(radius, segments, thickness)
    local parts = {}
    for i = 1, segments do
        local part = Instance.new("Part")
        part.Anchored, part.CanCollide, part.Material = true, false, Enum.Material.Neon
        part.Size = Vector3.new(thickness, 0.2, radius * 2 * math.pi / segments)
        part.Color = Color3.fromRGB(180,180,180)
        part.Parent = workspace
        parts[i] = part
    end
    return parts
end

_G.KA_DestroyCircle = function()
    if _G.KA.Circle.Conn then _G.KA.Circle.Conn:Disconnect() _G.KA.Circle.Conn = nil end
    for _, part in ipairs(_G.KA.Circle.Parts) do
        if part and part.Parent then part:Destroy() end
    end
    _G.KA.Circle.Parts = {}
end

_G.KA_StartCircle = function()
    _G.KA_DestroyCircle()
    local radius, segments, thickness = 60, 60, 0.2
    _G.KA.Circle.Parts = _G.KA_CreateCircle(radius, segments, thickness)
    
    _G.KA.Circle.Conn = game:GetService("RunService").RenderStepped:Connect(function()
        if #_G.KA.Circle.Parts == 0 then return end
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local rootPos = char.HumanoidRootPart.Position
            local humanoid = char:FindFirstChild("Humanoid")
            local heightOffset = humanoid and humanoid.HipHeight / 2 + 0.1 or 0.9
            local pos = rootPos - Vector3.new(0, heightOffset, 0)
            local time = tick()
            
            for i, part in ipairs(_G.KA.Circle.Parts) do
                local angle = (i / #_G.KA.Circle.Parts) * 2 * math.pi
                local x, z = pos.X + math.cos(angle) * radius, pos.Z + math.sin(angle) * radius
                part.Position = Vector3.new(x, pos.Y, z)
                part.Orientation = Vector3.new(0, -math.deg(angle), 90)
                local r, g, b = math.sin(time + i * 0.1) * 40 + 180, math.sin(time + i * 0.1 + 2) * 40 + 180, math.sin(time + i * 0.1 + 4) * 40 + 180
                part.Color = Color3.fromRGB(r, g, b)
            end
        end
    end)
end

-- UI CONTROLS - KILL AURA
task.spawn(function()
    repeat task.wait() until getgenv().JoshubTabs and getgenv().JoshubTabs.Main
    local Tabs = getgenv().JoshubTabs
    getgenv().JoshubMainGroups = getgenv().JoshubMainGroups or {}

getgenv().JoshubMainGroups.Left = Tabs.Main:AddLeftGroupbox("Kill Aura")

getgenv().JoshubMainGroups.Left:AddToggle("KA1", {
	Text = "Kill Aura block respawn",
	Default = false,
	Callback = function(v)
		_G.KA.V1.Running = v
		if v then _G.KA_startKillAuraV1()
		elseif _G.KA.V1.Conn then _G.KA.V1.Conn:Disconnect() _G.KA.V1.Conn = nil end
	end
})

getgenv().JoshubMainGroups.Left:AddToggle("KA2", {
	Text = "Kill Aura Anti God Mode",
	Default = false,
	Callback = function(v)
		_G.KA.V2.Running = v
		if v then 
            _G.KA_Config.V2.AutoToggleEnabled = true 
            _G.KA_startAutoToggleV2()
        else 
            _G.KA_Config.V2.AutoToggleEnabled = false 
            _G.KA_stopKillAurasV2() 
            _G.KA_stopAutoToggleV2() 
        end
	end
})

getgenv().JoshubMainGroups.Left:AddToggle("KillFarm", {
	Text = "Kill Farming",
	Default = false,
	Callback = function(v)
		_G.KA_Config.Farm.Enabled = v
		if v then 
            _G.KA_startKillFarming()
        else 
            _G.KA_stopKillFarming()
        end
	end
})

getgenv().JoshubMainGroups.Left:AddToggle("AutoClaimEmote", {
	Text = "Auto Claim Emote",
	Default = false,
	Callback = function(v)
		_G.EC.Running = v
		if v then 
            _G.EC_start()
        else 
            _G.EC_stop()
        end
	end
})

getgenv().JoshubMainGroups.Left:AddSlider("KillAuraDistance", {
	Text = "Kill Aura Distance",
	Default = 50,
	Min = 1,
	Max = 100,
	Rounding = 0,
	Callback = function(v)
		_G.KA_Config.V1.MaxDistance = v
		_G.KA_Config.V2.Distance = v
        _G.KA_Config.Farm.Range = v
	end
})



getgenv().JoshubMainGroups.Left:AddToggle("IgnoreFriends", {
	Text = "Ignore Friends (All)",
	Default = false,
	Callback = function(v) 
        _G.KA_Config.V1.IgnoreFriends = v
        _G.KA_Config.V2.IgnoreFriends = v
        _G.KA_Config.Farm.IgnoreFriends = v
    end
})
-- ==================== IMPROVED KILL AURA MODULE ====================
-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n global cho Kill Aura mÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºi
_G.KA_Improved = {
    Enabled = false,
    Range = 50,
    IgnoreFriends = true,
    TargetSelection = "Closest",
    AttackDelay = 0.05,
    Connection = nil,
    LastAttack = 0,
    PlayersList = {},
    Index = 1
}

-- HÃƒÆ’Ã‚Â m dash local
_G.KA_lpdashImproved = function()
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            require(RS:WaitForChild("Core"))
                .Library("Remote")
                .Send("Dash", hrp.CFrame, "L", 1)
        end)
    end
end

-- HÃƒÆ’Ã‚Â m kiÃƒÂ¡Ã‚Â»Ã†â€™m tra friend
_G.KA_isFriendImproved = function(p)
    if not p or p == localPlayer then return false end
    local success, isFriend = pcall(function()
        return localPlayer:IsFriendsWith(p.UserId)
    end)
    return success and isFriend
end

-- HÃƒÆ’Ã‚Â m lÃƒÂ¡Ã‚ÂºÃ‚Â¥y targets
_G.KA_getTargetsImproved = function()
    local targets = {}
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return targets end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            -- KiÃƒÂ¡Ã‚Â»Ã†â€™m tra ignore friends
            if _G.KA_Improved.IgnoreFriends and _G.KA_isFriendImproved(p) then
                continue
            end
            
            local hum = p.Character:FindFirstChild("Humanoid")
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            
            if hum and root and not p.Character:GetAttribute("Invincible") then
                local dist = (root.Position - hrp.Position).Magnitude
                if dist <= _G.KA_Improved.Range then
                    local health = hum:GetAttribute("Health") or hum.Health or 0
                    if health > 0 then
                        table.insert(targets, {
                            character = p.Character,
                            distance = dist,
                            health = health
                        })
                    end
                end
            end
        end
    end

    -- SÃƒÂ¡Ã‚ÂºÃ‚Â¯p xÃƒÂ¡Ã‚ÂºÃ‚Â¿p theo mode
    if _G.KA_Improved.TargetSelection == "Closest" then
        table.sort(targets, function(a, b) return a.distance < b.distance end)
    elseif _G.KA_Improved.TargetSelection == "Lowest" then
        table.sort(targets, function(a, b) return a.health < b.health end)
    end

    return targets
end

-- HÃƒÆ’Ã‚Â m Kill Aura chÃƒÆ’Ã‚Â­nh
_G.KA_killAuraImproved = function()
    if not _G.KA_Improved.Enabled then return end
    
    _G.KA_lpdashImproved()
    
    local targets = _G.KA_getTargetsImproved()
    if #targets == 0 then return end

    local n = 20
    local charName = localPlayer.Data.Character.Value
    if charName and charName ~= "Gon" then
        n = 50
    end

    -- Reset danh sÃƒÆ’Ã‚Â¡ch
    _G.KA_Improved.PlayersList = {}
    _G.KA_Improved.Index = 1

    for _, t in ipairs(targets) do
        for i = 1, n do
            _G.KA_Improved.PlayersList[_G.KA_Improved.Index] = t.character
            _G.KA_Improved.Index = _G.KA_Improved.Index + 1
        end
    end

    if _G.KA_Improved.Index > 1 then
        pcall(function()
            local wc = RS.Characters[localPlayer.Data.Character.Value].WallCombo
            RS.Remotes.Abilities.Ability:FireServer(wc, 69)
            RS.Remotes.Combat.Action:FireServer(
                wc, "", 4, 69, {
                    BestHitCharacter = nil,
                    HitCharacters = _G.KA_Improved.PlayersList,
                    Ignore = {},
                    Actions = {}
                }
            )
        end)
    end
end

-- HÃƒÆ’Ã‚Â m bÃƒÂ¡Ã‚ÂºÃ‚Â¯t Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚ÂºÃ‚Â§u Kill Aura
_G.KA_startImproved = function()
    if _G.KA_Improved.Connection then return end
    
    _G.KA_Improved.Connection = RunService.Heartbeat:Connect(function()
        if not _G.KA_Improved.Enabled then return end
        
        local currentTime = tick()
        if currentTime - _G.KA_Improved.LastAttack >= _G.KA_Improved.AttackDelay then
            _G.KA_Improved.LastAttack = currentTime
            _G.KA_killAuraImproved()
        end
    end)
end

-- HÃƒÆ’Ã‚Â m dÃƒÂ¡Ã‚Â»Ã‚Â«ng Kill Aura
_G.KA_stopImproved = function()
    if _G.KA_Improved.Connection then
        _G.KA_Improved.Connection:Disconnect()
        _G.KA_Improved.Connection = nil
    end
    _G.KA_Improved.PlayersList = {}
    _G.KA_Improved.Index = 1
end

-- ==================== UI CONTROLS - IMPROVED KILL AURA ====================
-- ThÃƒÆ’Ã‚Âªm vÃƒÆ’Ã‚Â o group box Kill Aura (sau cÃƒÆ’Ã‚Â¡c phÃƒÂ¡Ã‚ÂºÃ‚Â§n Ãƒâ€žÃ¢â‚¬ËœÃƒÆ’Ã‚Â£ cÃƒÆ’Ã‚Â³)

-- Toggle Improved Kill Aura
getgenv().JoshubMainGroups.Left:AddToggle("KillAuraImproved", {
    Text = "Instant kill",
    Default = false,
    Callback = function(v)
        _G.KA_Improved.Enabled = v
        if v then
            _G.KA_startImproved()
        else
            _G.KA_stopImproved()
        end
    end
})

-- Slider Range (10-110, mÃƒÂ¡Ã‚ÂºÃ‚Â·c Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹nh 50)
getgenv().JoshubMainGroups.Left:AddSlider("KillAuraImprovedRange", {
    Text = "Kill aura V3 Range",
    Default = 50,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Callback = function(v)
        _G.KA_Improved.Range = v
        print("Improved Kill Aura Range: " .. v)
    end
})

-- Slider Attack Delay
getgenv().JoshubMainGroups.Left:AddSlider("KillAuraImprovedDelay", {
    Text = "Kill Aura Delay V3",
    Default = 0.05,
    Min = 0.005,
    Max = 0.2,
    Rounding = 3,
    Callback = function(v)
        _G.KA_Improved.AttackDelay = v
        print("Improved Kill Aura Delay: " .. v .. "s")
    end
})

-- Toggle Ignore Friends cho Improved Kill Aura
getgenv().JoshubMainGroups.Left:AddToggle("IgnoreFriendsImproved", {
    Text = "Ignore Friend V3",
    Default = true,
    Callback = function(v)
        _G.KA_Improved.IgnoreFriends = v
    end
})

-- Dropdown Target Selection
getgenv().JoshubMainGroups.Left:AddDropdown("TargetSelectionImproved", {
    Values = {"Faster", "Slower"},
    Default = "Faster",
    Multi = false,
    Text = "Target Selection",
    Callback = function(v)
        _G.KA_Improved.TargetSelection = v
    end
})

-- ThÃƒÆ’Ã‚Âªm dÃƒÆ’Ã‚Â²ng phÃƒÆ’Ã‚Â¢n cÃƒÆ’Ã‚Â¡ch
getgenv().JoshubMainGroups.Left:AddDivider()


getgenv().JoshubMainGroups.Left:AddToggle("KillAuraShow", {
	Text = "Kill Aura Show",
	Default = false,
	Callback = function(v)
		if v then _G.KA_StartCircle() else _G.KA_DestroyCircle() end
	end
})

-- SPAM WALL COMBO
getgenv().JoshubMainGroups.Right = Tabs.Main:AddRightGroupbox("Spam Wall Combo V1")

-- Global variables cho WC
_G.WC_Enabled = false
_G.WC_Speed = 0.1

-- Load WC system
spawn(function()
    wait(2)
    loadstring([[
        setthreadcontext(2)
        local rs = game:GetService("RunService")
        local plr = game.Players.LocalPlayer
        local rep = game:GetService("ReplicatedStorage")
        
        local core = require(rep.Core)
        local chars = rep.Characters
        
        local lastSpam = 0
        
        rs:BindToRenderStep("WCSpam", 1, function()
            if _G.WC_Enabled and tick() - lastSpam >= _G.WC_Speed then
                lastSpam = tick()
                
                if not plr.Character then return end
                local head = plr.Character:FindFirstChild("Head")
                if not head then return end
                
                local charValue = plr.Data.Character.Value
                local charFolder = chars:FindFirstChild(charValue)
                if not charFolder then return end
                
                local wallCombo = charFolder:FindFirstChild("WallCombo")
                if not wallCombo then return end
                
                local res = core.Get("Combat","Hit").Box(nil, plr.Character, {Size = Vector3.new(50,50,50)})
                if res then
                    pcall(function()
                        core.Get("Combat","Ability").Activate(wallCombo, res, head.Position + Vector3.new(0,0,2.5))
                    end)
                end
            end
        end)
    ]])()
end)

-- Toggle Spam WC
getgenv().JoshubMainGroups.Right:AddToggle("WCSpamToggle", {
    Text = "Spam Wall Combo",
    Default = false,
    Callback = function(v) _G.WC_Enabled = v end
})

-- Slider tÃƒÂ¡Ã‚Â»Ã¢â‚¬Ëœc Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â€žÂ¢ WC
getgenv().JoshubMainGroups.Right:AddSlider("Wall Combo Slider", {
    Text = "Wall Combo Speed",
    Default = 0.1,
    Min = 0.01,
    Max = 0.5,
    Rounding = 2,
    Callback = function(v) _G.WC_Speed = v end
})

-- THÃƒÆ’Ã…Â M GROUP BOX LEGIT COMBAT
getgenv().JoshubMainGroups.LegitCombatBox = Tabs.Main:AddRightGroupbox("Legit Combat")

-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n global cho Dash Patcher
_G.DashPatcher = {
    Enabled = false,
    Hooked = false,
    OriginalFunction = nil,
    TargetFunction = nil
}

-- HÃƒÆ’Ã‚Â m scanner Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã†â€™ tÃƒÆ’Ã‚Â¬m function
local function DP_scanner(funcname)
    if not getgc then 
        warn("Executor khÃƒÆ’Ã‚Â´ng hÃƒÂ¡Ã‚Â»Ã¢â‚¬â€ trÃƒÂ¡Ã‚Â»Ã‚Â£ getgc")
        return nil 
    end
    
    local targetScript = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Combat"):WaitForChild("Dash")
    for i, v in pairs(getgc(true)) do
        if typeof(v) == "function" then
            local scr = getfenv(v).script
            if scr == targetScript and debug.getinfo(v).name == funcname then
                return v
            end
        end
    end
    return nil
end

-- TÃƒÆ’Ã‚Â¬m cÃƒÆ’Ã‚Â¡c hÃƒÆ’Ã‚Â m cÃƒÂ¡Ã‚ÂºÃ‚Â§n thiÃƒÂ¡Ã‚ÂºÃ‚Â¿t
local punchAnimation = DP_scanner("punchAnimation")
local vfx = DP_scanner("vfx")

-- HÃƒÆ’Ã‚Â m runAttack chÃƒÆ’Ã‚Â­nh
function _G.DP_runAttack(p_u_105, p_u_106, p107, p108)
    local v_u_1 = require(game.ReplicatedStorage:WaitForChild("Core"))
    local v109 = v_u_1.Services.Camera.CFrame
    local v110 = os.clock()
    local v_u_111 = tostring(v110)
    local v112 = 0
    local v_u_113 = 0
    local v_u_114 = 0
    local v_u_115 = 0
    local v_u_116, v_u_117, v_u_118, v_u_119, v_u_120
    local v121, v122
    local v_u_13, v_u_12 = false, false

    local function v_u_135(p123, p124, p125, p126, p127)
        local v128 = v_u_1.Get("Combat", "Ragdoll").GetRagdollFrame(p123)
        local v129 = v_u_1.Get("Character", "FullCustomReplication").GetCFrame(p_u_105)
        local v130 = v_u_1.Get("Character", "FullCustomReplication").GetCFrame(p123)
        local v131 = not p125
        if not v131 then
            if v129 and v130 then
                local v132 = p124 + v129.Position.Y - v130.Position.Y
                v131 = math.abs(v132) < p125
            end
        end
        local v133 = not p126
        if v133 then
            v128 = v133
        elseif v128 then
            v128 = v128.Velocity.Y < 0
        end
        local v134 = not p127
        if v134 then
            v130 = v134
        elseif v129 and v130 then
            v130 = v130.Position.Y > v129.Position.Y
        end
        if v131 then
            if not v128 then
                v130 = v128
            end
        else
            v130 = v131
        end
        v_u_120 = v130
        return v_u_120
    end

    local function v140(p136, p137)
        local v138 = v_u_1.Get("Combat", "Ragdoll").GetRagdollFrame(p136)
        local v139 = v_u_1.Get("Combat", "Ragdoll").UpVelocities[p136]
        if v138 then
            if v138.Velocity.Y < 0 and v139 then
                v139 = v139 > 1 and p137.CollisionGroup ~= "NoCharacterCollisions"
            else
                v139 = false
            end
        end
        return v139
    end

    local function v148(p141, p142, p143)
        if v_u_1.Library("Instance").Exists(p_u_106) then
            local v144, v145 = v_u_1.Get("Combat", "Hit").Box(nil, p_u_105, {
                Size = p141,
                Offset = p142,
                IgnoreJump = true,
                IgnoreRagdolls = "Ground",
                IgnoreKnockback = true,
                NoBaseValidation = true,
                RequireInFront = true,
                BlockHitsThroughWalls = true,
                CustomValidation = p143
            })
            v_u_117, v_u_116 = v144, v145
            local v146, v147 = v_u_1.Get("Combat", "Hit").Box(nil, p_u_105, {
                Size = p141,
                Offset = p142,
                IgnoreJump = true,
                IgnoreRagdolls = "Ground",
                IgnoreKnockback = true,
                RequireInFront = true,
                BlockHitsThroughWalls = true,
                CustomValidation = p143
            })
            v_u_119, v_u_118 = v146, v147
            return #v_u_116 > 0
        end
    end

    local v_u_149, v150, v151, v152 = v_u_119, v_u_114, v_u_113, v122
    local v_u_153, v_u_154, v155 = v_u_120, v121, nil
    
    local function v159(p156, p157)
        local v158 = not p156:GetAttribute("Ragdoll") or v_u_135(p156, 2, 0.25, true)
        if v158 then
            v158 = p157.CollisionGroup ~= "NoCharacterCollisions"
        end
        return v158
    end

    while true do
        task.wait()
        local v160 = v_u_1.Services.Camera.CFrame
        local _, v161, _ = v109:ToOrientation()
        local _, v162, _ = v160:ToOrientation()
        local v163 = v161 - v162
        local v164 = math.deg(v163)
        if v164 > 180 then
            v164 = v164 - 360
        elseif v164 < -180 then
            v164 = v164 + 360
        end

        v112 += v164
        v_u_113 = math.max(v151, v112)
        v_u_114 = math.min(v150, v112)
        v_u_115 = os.clock() - v110
        local v165 = p107 - v_u_115

        if v_u_115 > 0.2125 then
            v121 = v148(Vector3.new(1, 1, 1), CFrame.new(0, 7.5, -0.5), v140)
            v155 = v121 or v148(Vector3.new(5, 5, 4.5), CFrame.new(0, 0, -2), v159)
            v_u_154 = v121
        end

        if v155 or p108 < v_u_115 then
            local v_u_166 = v165 > 0 and true or v152
            local v167 = v155 or v148(Vector3.new(7.5, 5, 7), CFrame.new(0, 0, -2.75), v159)
            if v167 then
                v_u_1.Get("Character", "Move").SetJumpOverride("DashPunch", 0)
                task.delay(0.5, v_u_1.Get("Character", "Move").SetJumpOverride, "DashPunch", nil)
            end

            local function v188()
                local v182 = {
                    Guarantees = v_u_149,
                    Replace = function(p168)
                        local v169 = v_u_1.Get("Combat", "Knockback").CharacterPresets[p168] == "Uppercut" and 0.375 or 0.2625

                        local ok1, v170 = pcall(function() return v_u_1.Get("Combat", "Ragdoll").GetRagdoll(p168) end)
                        if not ok1 then v170 = nil end
                        local ok2, v170Frame = pcall(function() return v_u_1.Get("Combat", "Ragdoll").GetRagdollFrame(p168) end)
                        if not ok2 then v170Frame = nil end

                        local attrRagdoll = false
                        if p168 and p168.GetAttribute then
                            pcall(function() attrRagdoll = p168:GetAttribute("Ragdoll") end)
                        end

                        local isRagdolled = (v170 ~= nil) or (v170Frame ~= nil) or (attrRagdoll == true)

                        local v172 = nil
                        local ok4, gotCFrame = pcall(function() return p168 and v_u_1.Get("Character", "FullCustomReplication").GetCFrame(p168) end)
                        if ok4 and gotCFrame then
                            local tmp = p_u_106.CFrame:PointToObjectSpace(gotCFrame.Position)
                            local v174 = tmp.X * 180 / 2
                            v172 = p_u_106.CFrame * CFrame.Angles(0, math.rad(-math.clamp(v174, -180, 180)), 0)
                        end

                        local hasKB = false
                        if p168 and p168.GetAttribute then
                            local okKB, kbVal = pcall(function() return p168:GetAttribute("Knockback") end)
                            if okKB and kbVal then hasKB = true end
                        end

                        if isRagdolled then
                            return { ActionNumbers = {2, 6}, ForceDirection = v172 }
                        end

                        if v_u_115 < v169 then
                            if p168 and p168.SetAttribute then
                                pcall(function() p168:SetAttribute("Knockback", false) end)
                            end
                            return { ActionNumbers = {1, 6}, ForceDirection = nil }
                        end

                        local v179
                        if v_u_113 - v_u_114 > 180 then
                            v179 = not v170 or v_u_135(p168, 0, 2, nil, true)
                        else
                            v179 = false
                        end
                        local v180 = false
                        local v181 = v_u_166
                        if v181 then v181 = not v170 end

                        if v180 then
                            if v170 then v170 = v_u_154 end
                        else
                            v170 = v180
                        end
                        if v180 then v180 = not v170 end

                        if v_u_115 >= v169 then
                            pcall(function()
                                if p168 and p168.SetAttribute then p168:SetAttribute("Knockback", false) end
                            end)
                        end

                        local pick = 1
                        if hasKB then pick = 5
                        elseif v181 then pick = 4
                        elseif v180 then pick = 3
                        elseif v170 then pick = 2
                        else pick = 1
                        end

                        return { ActionNumbers = { pick, 6 }, ForceDirection = v181 and v172 }
                    end,
                    UseFromCFrame = v_u_166 and p_u_106.CFrame * CFrame.new(0, 0, -2) or nil
                }

                task.wait(0.15)
                v_u_12 = true
                local v183, v184, _, _, v185 = v_u_1.Get("Combat", "Action").Event(nil, p_u_105, "PunchDash", v_u_111, v182, 0)
                if v183 then
                    if vfx then
                        vfx("DashHit", v183, p_u_106.Position)
                    end
                    v_u_1.Get("Camera", "Shake").Shake(nil, nil, {
                        Amplitude = 1.25,
                        Frequency = 0.0875,
                        FadeInTime = 0.025,
                        FadeOutTime = 0.5
                    }, nil, p_u_105, table.unpack(v184))
                end
                local v186 = false
                for _, v187 in v185 and (v185.BlockedCharacters or {}) or {} do
                    if not table.find(v185.HitCharacters, v187) then
                        v186 = true
                    end
                end
                v_u_13 = v186
                v_u_12 = false
            end

            task.spawn(v188)
            if v165 > 0 then
                v_u_1.Services.Run.Heartbeat:Wait()
                task.wait(v165 + 0.025)
            end
            if punchAnimation then
                task.spawn(punchAnimation, p_u_105, v_u_111)
            end
            return v165 > 0, v167
        end
        v150, v151, v109 = v_u_114, v_u_113, v160
    end
end

-- HÃƒÆ’Ã‚Â m bÃƒÂ¡Ã‚ÂºÃ‚Â­t/tÃƒÂ¡Ã‚ÂºÃ‚Â¯t Dash Patcher
local function DP_toggle()
    if not hookfunction then
        warn("Executor khÃƒÆ’Ã‚Â´ng hÃƒÂ¡Ã‚Â»Ã¢â‚¬â€ trÃƒÂ¡Ã‚Â»Ã‚Â£ hookfunction")
        return
    end
    
    if _G.DashPatcher.Enabled then
        -- TÃƒÂ¡Ã‚ÂºÃ‚Â¯t Dash Patcher
        if _G.DashPatcher.Hooked and _G.DashPatcher.OriginalFunction and _G.DashPatcher.TargetFunction then
            hookfunction(_G.DashPatcher.TargetFunction, _G.DashPatcher.OriginalFunction)
            _G.DashPatcher.Hooked = false
            _G.DashPatcher.TargetFunction = nil
            _G.DashPatcher.OriginalFunction = nil
            _G.DashPatcher.Enabled = false
            print("Dash Patcher: Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ tÃƒÂ¡Ã‚ÂºÃ‚Â¯t")
        end
    else
        -- BÃƒÂ¡Ã‚ÂºÃ‚Â­t Dash Patcher
        if _G.DashPatcher.Hooked then return end
        
        local targetScript = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Combat"):WaitForChild("Dash")
        local found = false
        
        if not getgc then
            print("Dash Patcher: KhÃƒÆ’Ã‚Â´ng hÃƒÂ¡Ã‚Â»Ã¢â‚¬â€ trÃƒÂ¡Ã‚Â»Ã‚Â£ getgc")
            return
        end
        
        for i, v in pairs(getgc(true)) do
            if typeof(v) == "function" then
                local scr = getfenv(v).script
                if scr == targetScript and debug.getinfo(v).name == "runAttack" then
                    _G.DashPatcher.TargetFunction = v
                    _G.DashPatcher.OriginalFunction = hookfunction(v, _G.DP_runAttack)
                    _G.DashPatcher.Hooked = true
                    _G.DashPatcher.Enabled = true
                    found = true
                    print("Dash Patcher: Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ bÃƒÂ¡Ã‚ÂºÃ‚Â­t")
                    break
                end
            end
        end
        
        if not found then
            print("Dash Patcher: KhÃƒÆ’Ã‚Â´ng tÃƒÆ’Ã‚Â¬m thÃƒÂ¡Ã‚ÂºÃ‚Â¥y hÃƒÆ’Ã‚Â m runAttack")
        end
    end
end

-- ThÃƒÆ’Ã‚Âªm toggle Dash Patcher vÃƒÆ’Ã‚Â o UI
getgenv().JoshubMainGroups.LegitCombatBox:AddToggle("DashPatcherToggle", {
    Text = "Dash Anti Knockback",
    Default = false,
    Callback = function(v)
        DP_toggle()
    end
})

-- ==================== AUTO BLOCK ====================
-- BiÃƒÂ¡Ã‚ÂºÃ‚Â¿n global cho Auto Block
_G.AutoBlock = {
    Enabled = false,
    DetectRange = 18
}

-- Auto Block Functions
_G.AB_safe_pcall = function(f, ...)
    local ok, res = pcall(f, ...)
    return ok, res
end

_G.AB_Config = {
    BlockEnabled = false,
    DetectRange = 18,
    AimRenderPriority = Enum.RenderPriority.Camera.Value + 1,
}

_G.AB_AbilityAnimations = {
    ["rbxassetid://15264723185"]=true,["rbxassetid://15367882043"]=true,["rbxassetid://15264724956"]=true,
    ["rbxassetid://15264726664"]=true,["rbxassetid://15264728589"]=true,["rbxassetid://15149724716"]=true,
    ["rbxassetid://14964097240"]=true,["rbxassetid://14990027290"]=true,["rbxassetid://14964164848"]=true,
    ["rbxassetid://14964173880"]=true,["rbxassetid://14964163956"]=true,["rbxassetid://16348996987"]=true,
    ["rbxassetid://16348998201"]=true,["rbxassetid://16348999613"]=true,["rbxassetid://16349001071"]=true,
    ["rbxassetid://17358462625"]=true,["rbxassetid://17358464854"]=true,["rbxassetid://17358465981"]=true,
    ["rbxassetid://17358467074"]=true,["rbxassetid://19001385862"]=true,["rbxassetid://19001387048"]=true,
    ["rbxassetid://19001388467"]=true,["rbxassetid://19001389751"]=true,["rbxassetid://93077762063817"]=true,
    ["rbxassetid://91933199624121"]=true,["rbxassetid://139181088940711"]=true,["rbxassetid://96297927444888"]=true,
}

_G.AB_NoTurnAnimations = {
    ["rbxassetid://17827546062"]=true,["rbxassetid://15139727493"]=true,
    ["rbxassetid://15139729788"]=true,["rbxassetid://15564404362"]=true,["rbxassetid://15027653191"]=true,
}

-- TÃƒÆ’Ã‚Â¬m remote block
_G.AB_getBlockRemote = function()
    local cur = game:GetService("ReplicatedStorage")
    for _,p in ipairs({"Remotes","Combat","Block"}) do
        cur = cur and cur:FindFirstChild(p)
    end
    return cur
end

_G.AB_fireRemote = function(remote, ...)
    if not remote then return false end
    local args = table.pack(...)
    return pcall(function()
        remote:FireServer(table.unpack(args,1,args.n))
    end)
end

-- State cho Auto Block
_G.AB_state = {
    localNoTurnAnimData = {track=nil, endsAt=0},
    blockTimer = 0,
    animBlockCache = {},
    lastBlockFire = 0
}

-- Helper functions
_G.AB_IsEnemy = function(p)
    return p ~= game.Players.LocalPlayer and p.Character and p.Character.Parent
end

_G.AB_IsAbilityAnim = function(track)
    return track and track.Animation and _G.AB_AbilityAnimations[track.Animation.AnimationId]
end

_G.AB_EnsureAbilityAttribute = function()
    local c = game.Players.LocalPlayer.Character
    if c and c:GetAttribute("Ability") == nil then
        _G.AB_safe_pcall(function()
            c:SetAttribute("Ability","")
        end)
    end
end

_G.AB_UpdateLocalNoTurnAnim = function()
    local c = game.Players.LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    for _,t in ipairs(h:GetPlayingAnimationTracks()) do
        if t.IsPlaying and _G.AB_NoTurnAnimations[t.Animation.AnimationId] then
            _G.AB_state.localNoTurnAnimData.track = t
            _G.AB_state.localNoTurnAnimData.endsAt = tick() + (t.Length or 0.7)
            return
        end
    end
    _G.AB_state.localNoTurnAnimData.track=nil
    _G.AB_state.localNoTurnAnimData.endsAt=0
end

_G.AB_IsLocalAttacking = function()
    local c = game.Players.LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h then return false end
    for _,t in ipairs(h:GetPlayingAnimationTracks()) do
        if t.IsPlaying and _G.AB_IsAbilityAnim(t) then
            return true
        end
    end
    local abilityValue = c:GetAttribute("Ability")
    return type(abilityValue)=="string" and abilityValue ~= ""
end

_G.AB_getClosestEnemyRoot = function()
    local c = game.Players.LocalPlayer.Character
    local myRoot = c and c:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local bestRoot, bestDist = nil, math.huge
    for _,p in ipairs(game.Players:GetPlayers()) do
        if _G.AB_IsEnemy(p) then
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (myRoot.Position - r.Position).Magnitude
                if d <= _G.AB_Config.DetectRange and d < bestDist then
                    bestRoot, bestDist = r, d
                end
            end
        end
    end
    return bestRoot
end

_G.AB_getThreatAnims = function()
    local c = game.Players.LocalPlayer.Character
    local myRoot = c and c:FindFirstChild("HumanoidRootPart")
    if not myRoot then return {} end
    local t = {}
    for _,p in ipairs(game.Players:GetPlayers()) do
        if _G.AB_IsEnemy(p) then
            local ch = p.Character
            local r = ch and ch:FindFirstChild("HumanoidRootPart")
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            if r and h then
                local d = (myRoot.Position - r.Position).Magnitude
                if d <= _G.AB_Config.DetectRange then
                    for _,tr in ipairs(h:GetPlayingAnimationTracks()) do
                        if tr.IsPlaying and _G.AB_IsAbilityAnim(tr) then
                            table.insert(t,{root=r, anim=tr})
                            break
                        end
                    end
                end
            end
        end
    end
    return t
end

-- Core Auto Block function
_G.AB_predictiveAimAndBlock = function()
    local c = game.Players.LocalPlayer.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")

    -- Force unblock when off
    if not _G.AB_Config.BlockEnabled then
        if c then
            local blockRemote = _G.AB_getBlockRemote()
            if blockRemote then
                _G.AB_fireRemote(blockRemote, false)
            end
            _G.AB_safe_pcall(function()
                c:SetAttribute("LocalBlock", false)
            end)
        end
        _G.AB_state.blockTimer = 0
        _G.AB_state.animBlockCache = {}
        return
    end

    if not root then return end

    _G.AB_EnsureAbilityAttribute()
    _G.AB_UpdateLocalNoTurnAnim()

    if _G.AB_state.localNoTurnAnimData.endsAt > tick() or _G.AB_IsLocalAttacking() then
        local blockRemote = _G.AB_getBlockRemote()
        if blockRemote then
            _G.AB_fireRemote(blockRemote, false)
        end
        _G.AB_safe_pcall(function()
            c:SetAttribute("LocalBlock", false)
        end)
        _G.AB_state.animBlockCache = {}
        return
    end

    local targetRoot = _G.AB_getClosestEnemyRoot()
    if targetRoot then
        local dir = (targetRoot.Position - root.Position)
        dir = Vector3.new(dir.X,0,dir.Z)
        if dir.Magnitude > 0.001 then
            root.CFrame = CFrame.lookAt(root.Position, root.Position + dir.Unit)
        end
    end

    local threats = _G.AB_getThreatAnims()
    if #threats == 0 then
        if targetRoot then
            _G.AB_state.blockTimer = math.max(_G.AB_state.blockTimer, tick() + 0.15)
        end
    else
        for _,t in ipairs(threats) do
            if not _G.AB_state.animBlockCache[t.anim] then
                _G.AB_state.animBlockCache[t.anim] = true
                _G.AB_state.blockTimer = math.max(_G.AB_state.blockTimer, tick() + (t.anim.Length or 0.2) + 0.85)
            end
        end
    end

    if tick() <= _G.AB_state.blockTimer then
        if tick() - _G.AB_state.lastBlockFire >= 0.045 then
            local blockRemote = _G.AB_getBlockRemote()
            if blockRemote then
                _G.AB_fireRemote(blockRemote, true)
            end
            _G.AB_safe_pcall(function()
                c:SetAttribute("LocalBlock", true)
            end)
            _G.AB_state.lastBlockFire = tick()
        end
    else
        local blockRemote = _G.AB_getBlockRemote()
        if blockRemote then
            _G.AB_fireRemote(blockRemote, false)
        end
        _G.AB_safe_pcall(function()
            c:SetAttribute("LocalBlock", false)
        end)
        _G.AB_state.animBlockCache = {}
    end
end

-- KÃƒÂ¡Ã‚ÂºÃ‚Â¿t nÃƒÂ¡Ã‚Â»Ã¢â‚¬Ëœi RenderStep cho Auto Block
_G.AB_connection = nil

local function AB_start()
    if _G.AB_connection then
        _G.AB_connection:Disconnect()
        _G.AB_connection = nil
    end
    
    _G.AB_connection = game:GetService("RunService"):BindToRenderStep("AutoBlock360_Fixed", _G.AB_Config.AimRenderPriority, _G.AB_predictiveAimAndBlock)
end

local function AB_stop()
    if _G.AB_connection then
        _G.AB_connection:Disconnect()
        _G.AB_connection = nil
    end
    
    -- Force unblock khi tÃƒÂ¡Ã‚ÂºÃ‚Â¯t
    local c = game.Players.LocalPlayer.Character
    if c then
        local blockRemote = _G.AB_getBlockRemote()
        if blockRemote then
            _G.AB_fireRemote(blockRemote, false)
        end
        _G.AB_safe_pcall(function()
            c:SetAttribute("LocalBlock", false)
        end)
    end
    _G.AB_state.blockTimer = 0
    _G.AB_state.animBlockCache = {}
end

-- ThÃƒÆ’Ã‚Âªm toggle Auto Block
getgenv().JoshubMainGroups.LegitCombatBox:AddToggle("AutoBlockToggle", {
    Text = "Auto Block Method",
    Default = false,
    Callback = function(v)
        _G.AB_Config.BlockEnabled = v
        _G.AutoBlock.Enabled = v
        
        if v then
            AB_start()
        else
            AB_stop()
        end
    end
})

-- ThÃƒÆ’Ã‚Âªm slider Detect Range
getgenv().JoshubMainGroups.LegitCombatBox:AddSlider("AutoBlockRange", {
    Text = "Block Range",
    Default = 18,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Callback = function(v)
        _G.AB_Config.DetectRange = v
        _G.AutoBlock.DetectRange = v
    end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- BIÃƒÂ¡Ã‚ÂºÃ‚Â¾N GLOBAL
_G.HitboxConfig = {
    HitboxToggle = false,
    HitboxX = 20,
    HitboxY = 20,
    HitboxZ = 20,
    EnhancerToggle = false,
    EnhancerMultiplier = 5,
    DashMethod = false,
    BasicHitbox = false,
    BasicSize = 18
}

-- BIÃƒÂ¡Ã‚ÂºÃ‚Â¾N GLOBAL
_G.HitboxCache = {
    OriginalBox = nil,
    OriginalProcess = nil,
    DashConnection = nil,
    LastDash = 0,
    BasicOriginal = nil
}

-- BIÃƒÂ¡Ã‚ÂºÃ‚Â¾N GLOBAL
_G.HitboxEnabled = false

local function HRP()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- HÃƒÆ’Ã‚Â m toggle hitbox
local function toggleHitbox(state)
    _G.HitboxEnabled = state
    _G.HitboxConfig.HitboxToggle = state

    local ok, core = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Core"))
    end)
    if not ok then return end

    local hit = core.Get and core.Get("Combat", "Hit")
    if not hit or not hit.Box then return end

    if state then
        if not _G.HitboxCache.OriginalBox then 
            _G.HitboxCache.OriginalBox = hit.Box 
        end
        hit.Box = function(_, char, data)
            data = data or {}
            data.Size = Vector3.new(
                _G.HitboxConfig.HitboxX, 
                _G.HitboxConfig.HitboxY, 
                _G.HitboxConfig.HitboxZ
            )
            return _G.HitboxCache.OriginalBox(nil, char, data)
        end
    else
        if _G.HitboxCache.OriginalBox then
            hit.Box = _G.HitboxCache.OriginalBox
        end
    end
end

-- HÃƒÆ’Ã‚Â m dash vÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºi cooldown
local DASH_CD = 0.18
local function dash()
    if tick() - _G.HitboxCache.LastDash < DASH_CD then return end
    _G.HitboxCache.LastDash = tick()

    local hrp = HRP()
    if hrp then
        pcall(function()
            require(ReplicatedStorage.Core)
                .Library("Remote")
                .Send("Dash", hrp.CFrame, "L", 1)
        end)
    end
end

-- HÃƒÆ’Ã‚Â m bÃƒÂ¡Ã‚ÂºÃ‚Â­t/tÃƒÂ¡Ã‚ÂºÃ‚Â¯t enhancer
local function toggleEnhancer(state)
    _G.HitboxConfig.EnhancerToggle = state
    
    local ok, hit = pcall(function()
        return require(LocalPlayer.PlayerScripts.Combat.Hit)
    end)
    if not ok or not hit.Process then return end

    if state then
        if not _G.HitboxCache.OriginalProcess then
            _G.HitboxCache.OriginalProcess = hit.Process
        end
        hit.Process = function(...)
            local best, targets, blocked = _G.HitboxCache.OriginalProcess(...)
            if targets and #targets > 0 then
                dash()
                for i = 1, _G.HitboxConfig.EnhancerMultiplier do
                    ReplicatedStorage.Remotes.Combat.Action:FireServer(
                        nil, "", 4, 69,
                        {BestHitCharacter=nil, HitCharacters=targets, Ignore={}, Actions={}}
                    )
                end
            end
            return best, targets, blocked
        end
    else
        if _G.HitboxCache.OriginalProcess then
            hit.Process = _G.HitboxCache.OriginalProcess
        end
    end
end

-- HÃƒÆ’Ã‚Â m bÃƒÂ¡Ã‚ÂºÃ‚Â­t/tÃƒÂ¡Ã‚ÂºÃ‚Â¯t dash method
local function toggleDashMethod(state)
    _G.HitboxConfig.DashMethod = state
    
    if state then
        if _G.HitboxCache.DashConnection then return end
        _G.HitboxCache.DashConnection = RunService.Heartbeat:Connect(function()
            local hrp = HRP()
            if hrp then
                pcall(function()
                    require(ReplicatedStorage.Core)
                        .Library("Remote")
                        .Send("Dash", hrp.CFrame, "L", 1)
                end)
            end
        end)
    else
        if _G.HitboxCache.DashConnection then
            _G.HitboxCache.DashConnection:Disconnect()
            _G.HitboxCache.DashConnection = nil
        end
    end
end

-- HÃƒÆ’Ã‚Â m toggle basic hitbox
local function toggleBasicHitbox(state)
    _G.HitboxConfig.BasicHitbox = state
    
    local rep = cloneref(game:GetService("ReplicatedStorage"))
    
    local success, core = pcall(function()
        return require(rep:WaitForChild("Core", 96e8))
    end)
    
    if not success then
        local old; old = hookfunction(require, newcclosure(function(...)
            if checkcaller() then
                setthreadidentity(4)
                local result = old(...)
                setthreadidentity(8)
                return result
            end
            return old(...)
        end))
    end
    
    if state then
        if core and core.Get and core.Get("Combat", "Hit") then
            if not _G.HitboxCache.BasicOriginal then
                _G.HitboxCache.BasicOriginal = core.Get("Combat", "Hit").Box
            end
            core.Get("Combat", "Hit").Box = function(...)
                local args = {...}
                return _G.HitboxCache.BasicOriginal(
                    nil, 
                    args[2], 
                    {Size = Vector3.new(
                        _G.HitboxConfig.BasicSize, 
                        _G.HitboxConfig.BasicSize, 
                        _G.HitboxConfig.BasicSize
                    )}
                )
            end
        end
    else
        if _G.HitboxCache.BasicOriginal then
            if core and core.Get and core.Get("Combat", "Hit") then
                core.Get("Combat", "Hit").Box = _G.HitboxCache.BasicOriginal
            end
        end
    end
end

-- UI CONTROLS - HITBOX CONTROL GROUP BOX
getgenv().JoshubMainGroups.HitboxGroup = Tabs.Main:AddLeftGroupbox("Hitbox Control")

-- Toggle Hitbox
getgenv().JoshubMainGroups.HitboxGroup:AddToggle("HitboxToggle", {
    Text = "Hitbox Expander",
    Default = false,
    Callback = function(v)
        toggleHitbox(v)
    end
})

-- Slider Hitbox X
getgenv().JoshubMainGroups.HitboxGroup:AddSlider("HitboxX", {
    Text = "Hitbox X",
    Default = 20,
    Min = 5,
    Max = 120,
    Rounding = 0,
    Callback = function(v)
        _G.HitboxConfig.HitboxX = v
        if _G.HitboxConfig.HitboxToggle then
            toggleHitbox(true) -- Refresh
        end
    end
})

-- Slider Hitbox Y
getgenv().JoshubMainGroups.HitboxGroup:AddSlider("HitboxY", {
    Text = "Hitbox Y",
    Default = 20,
    Min = 5,
    Max = 120,
    Rounding = 0,
    Callback = function(v)
        _G.HitboxConfig.HitboxY = v
        if _G.HitboxConfig.HitboxToggle then
            toggleHitbox(true) -- Refresh
        end
    end
})

-- Slider Hitbox Z
getgenv().JoshubMainGroups.HitboxGroup:AddSlider("HitboxZ", {
    Text = "Hitbox Z",
    Default = 20,
    Min = 5,
    Max = 120,
    Rounding = 0,
    Callback = function(v)
        _G.HitboxConfig.HitboxZ = v
        if _G.HitboxConfig.HitboxToggle then
            toggleHitbox(true) -- Refresh
        end
    end
})

-- Toggle Hitbox Legit (Enhancer)
getgenv().JoshubMainGroups.HitboxGroup:AddToggle("HitboxEnhancer", {
    Text = "Hitbox Legit",
    Default = false,
    Callback = function(v)
        toggleEnhancer(v)
    end
})

-- Slider Enhancer Multiplier
getgenv().JoshubMainGroups.HitboxGroup:AddSlider("EnhancerMultiplier", {
    Text = "Enhancer Multiplier",
    Default = 5,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(v)
        _G.HitboxConfig.EnhancerMultiplier = v
        if _G.HitboxConfig.EnhancerToggle then
            toggleEnhancer(true) -- Refresh
        end
    end
})

-- Toggle Dash Method
getgenv().JoshubMainGroups.HitboxGroup:AddToggle("DashMethod", {
    Text = "Hitbox Method",
    Default = false,
    Callback = function(v)
        toggleDashMethod(v)
    end
})

-- DÃƒÆ’Ã‚Â²ng phÃƒÆ’Ã‚Â¢n cÃƒÆ’Ã‚Â¡ch
getgenv().JoshubMainGroups.HitboxGroup:AddDivider()

-- Toggle Basic Hitbox
getgenv().JoshubMainGroups.HitboxGroup:AddToggle("BasicHitbox", {
    Text = "Hitbox Basic",
    Default = false,
    Callback = function(v)
        toggleBasicHitbox(v)
    end
})

-- Slider Basic Hitbox Size
getgenv().JoshubMainGroups.HitboxGroup:AddSlider("BasicHitboxSize", {
    Text = "Basic Hitbox Size",
    Default = 18,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Callback = function(v)
        _G.HitboxConfig.BasicSize = v
        if _G.HitboxConfig.BasicHitbox then
            toggleBasicHitbox(true) -- Refresh
        end
    end
})



-- UI CONTROLS - HOW TO USE HITBOX GROUP BOX
getgenv().JoshubMainGroups.HowToUseGroup = Tabs.Main:AddRightGroupbox("How To Use Script")

-- Labels hÃƒâ€ Ã‚Â°ÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºng dÃƒÂ¡Ã‚ÂºÃ‚Â«n
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("Hitbox Expander needs 5 minutes to load.")
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("During this time you can use Basic Hitbox.")

getgenv().JoshubMainGroups.HowToUseGroup:AddDivider()

getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("If Hitbox Expander doesn't work,")
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("please turn ON all EXCEPT Basic Hitbox:")

getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("- Hitbox (Toggle ON)")
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("- Hitbox Legit (Toggle ON)")
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("- Hitbox Method (Toggle ON)")
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("- Hitbox Basic (Toggle OFF)")

getgenv().JoshubMainGroups.HowToUseGroup:AddDivider()

getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("Anti Knockback Guide:")
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("- Helps you bonedash & loopdash easier")
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("- Reduces pushback when hitting enemies")

getgenv().JoshubMainGroups.HowToUseGroup:AddDivider()

getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("Auto Block Method:")
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("- You must turn OFF Shift Lock to use")
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("- Mobile support: unknown / not tested")

getgenv().JoshubMainGroups.HowToUseGroup:AddDivider()

getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("Note: Wait 5 minutes for full functionality.")
getgenv().JoshubMainGroups.HowToUseGroup:AddLabel("Game may require rejoining after loading.")

-- Button Copy Instructions
getgenv().JoshubMainGroups.HowToUseGroup:AddButton({
    Text = "Copy Instructions",
    Func = function()
        local instructions =
            "Hitbox Expander needs 5 minutes to load.\n" ..
            "During this time you can use Basic Hitbox.\n\n" ..
            "If Hitbox Expander doesn't work:\n" ..
            "1. Turn ON Hitbox\n" ..
            "2. Turn ON Hitbox Legit\n" ..
            "3. Turn ON Hitbox Method\n" ..
            "4. Turn OFF Hitbox Basic\n" ..
            "5. Wait 5 minutes\n" ..
            "6. Rejoin if needed\n\n" ..
            "Anti Knockback:\n" ..
            "- Helps bonedash & loopdash easier\n" ..
            "- Reduces knockback when attacking\n\n" ..
            "Auto Block Method:\n" ..
            "- Turn OFF Shift Lock to use\n" ..
            "- Mobile support: unknown"

        setclipboard(instructions)
        Library:Notify("Instructions copied to clipboard!", 3)
    end,
    DoubleClick = false
})


end)
print("[JOSHHUB V4] Loading migrated UI settings...")









