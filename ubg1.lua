
-- ====================================================
-- ZETA HUB | OFFICIAL HYBRID LOADER (CLIENT-FIX VER.)
-- ====================================================
-- Toggle Key: RightShift

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- ── CONFIGURACIÓN DE ENLACES ────────────────────────
local DATABASE_URL = "https://gist.githubusercontent.com/d03703892-blip/bdc132957f818e01f42028a70420370c/raw/gistfile1.txt"
local SCRIPT_URL   = "https://gist.githubusercontent.com/d03703892-blip/523e82f4df67b7f24790411775a206b5/raw/gistfile1.txt"
local CONFIG_FILE  = "ZetaHub_Auth.json"

-- ── OBTENCIÓN DE HWID ───────────────────────────────
local success, hwid = pcall(function()
    return game:GetService("RbxAnalyticsService"):GetClientId()
end)

if not success or not hwid then
    LocalPlayer:Kick("Zeta Hub: Failed to retrieve hardware ID.")
    return
end

-- Normalizar HWID a mayúsculas para evitar errores
hwid = hwid:upper()

-- ── LIBRERÍA DE UI (OBSIDIAN) ───────────────────────
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

-- ── FUNCIONES DE CARGA ──────────────────────────────
local function loadMainScript()
    Library:Notify("Authentication successful! Loading Zeta Hub...", 3)
    
    pcall(function() 
        if Library.Unload then Library:Unload() end
    end)
    
    local finalScriptUrl = SCRIPT_URL .. "?t=" .. os.time()
    local loadSuccess, scriptContent = pcall(function()
        return game:HttpGet(finalScriptUrl)
    end)
    
    if loadSuccess and scriptContent then
        local func, err = loadstring(scriptContent)
        if func then
            task.spawn(func)
        else
            warn("Zeta Hub Error: " .. tostring(err))
        end
    else
        LocalPlayer:Kick("Zeta Hub: Failed to load main script.")
    end
end

local function verifyKey(enteredKey, isAutoLogin)
    -- Limpiar espacios y normalizar a mayúsculas
    enteredKey = enteredKey:gsub("^%s*(.-)%s*$", "%1"):upper()
    if enteredKey == "" then return false, "Please enter a key" end

    local finalDBUrl = DATABASE_URL .. "?t=" .. os.time()
    local fetchSuccess, response = pcall(function() return game:HttpGet(finalDBUrl) end)
    if not fetchSuccess then return false, "Server Connection Failed" end

    local dataSuccess, db = pcall(function() return HttpService:JSONDecode(response) end)
    if not dataSuccess or type(db) ~= "table" then return false, "Database Error" end

    -- 1. Verificar Llave Diaria
    local dailyKey = tostring(db["DailyKey"] or ""):upper()
    if enteredKey == dailyKey then
        if not isAutoLogin then
            pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode({key = enteredKey})) end)
        end
        loadMainScript()
        return true
    end

    -- 2. Verificar Llave VIP
    local vipKeys = db["VIP_Keys"] or {}
    for key, regHWID in pairs(vipKeys) do
        if key:upper() == enteredKey then
            regHWID = tostring(regHWID):upper()
            if regHWID == "UNBOUND" or regHWID == "" or regHWID == hwid then
                if not isAutoLogin then
                    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode({key = enteredKey})) end)
                end
                loadMainScript()
                return true
            else
                return false, "HWID Mismatch! Key locked to another PC."
            end
        end
    end

    return false, "Key not found in database."
end

-- ── AUTO-LOGIN ─────────────────────────────────────
if isfile and isfile(CONFIG_FILE) then
    local configData = readfile(CONFIG_FILE)
    local successDec, data = pcall(function() return HttpService:JSONDecode(configData) end)
    if successDec and data.key then
        local success, msg = verifyKey(data.key, true)
        if success then return end
    end
end

-- ── INTERFAZ DE LOGIN ──────────────
local Window = Library:CreateWindow({
    Title = "Zeta Hub | Secure Authentication",
    Center = true,
    AutoShow = true
})

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        Window:Toggle()
    end
end)

local Tab = Window:AddTab("Login")
local Group = Tab:AddLeftGroupbox("Verify License")

local enteredKeyInput = ""

Group:AddInput("KeyInput", {
    Text = "License / Daily Key",
    Default = "",
    Placeholder = "Enter key here...",
    Callback = function(v) enteredKeyInput = v end
})

Group:AddButton({
    Text = "Login & Save",
    Func = function()
        local success, msg = verifyKey(enteredKeyInput, false)
        if not success then
            Library:Notify(msg, 5)
            warn("Login Failed: " .. msg)
        end
    end
})

Group:AddButton({
    Text = "Copy My HWID",
    Func = function()
        setclipboard(hwid)
        Library:Notify("HWID copied! Send this to the owner.", 5)
        print("Your HWID: " .. hwid)
    end
})

Group:AddButton({
    Text = "Get Key / Discord",
    Func = function()
        setclipboard("https://gist.github.com/d03703892-blip/bdc132957f818e01f42028a70420370c")
        Library:Notify("Link copied!", 3)
    end
})

Library:Notify("Press RightShift to toggle UI", 5)
