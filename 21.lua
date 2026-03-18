-- =====================================================
-- JOSHLIB v1.0 — UI Library
-- Estilo: Hacker / Matrix
-- RightShift: abrir/cerrar
-- Elementos: Tabs, Toggles, Sliders, Buttons, Dropdowns
-- =====================================================

local JoshLib = {}

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local LocalPlayer       = Players.LocalPlayer

-- =====================================================
-- COLORES Y CONSTANTES
-- =====================================================
local C = {
    bg          = Color3.fromRGB(8, 10, 8),
    bgPanel     = Color3.fromRGB(12, 15, 12),
    bgElem      = Color3.fromRGB(16, 20, 16),
    bgHover     = Color3.fromRGB(22, 28, 22),
    accent      = Color3.fromRGB(0, 255, 70),
    accentDim   = Color3.fromRGB(0, 140, 40),
    accentDark  = Color3.fromRGB(0, 40, 12),
    text        = Color3.fromRGB(180, 255, 190),
    textDim     = Color3.fromRGB(80, 120, 85),
    textOff     = Color3.fromRGB(50, 70, 52),
    border      = Color3.fromRGB(0, 80, 25),
    borderBright= Color3.fromRGB(0, 200, 60),
    red         = Color3.fromRGB(255, 60, 60),
    black       = Color3.fromRGB(0, 0, 0),
}

local FONT      = Enum.Font.Code
local FONT_BOLD = Enum.Font.Code

-- =====================================================
-- HELPERS
-- =====================================================
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(r, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 4)
    c.Parent = parent
    return c
end

local function stroke(color, thickness, parent)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

-- =====================================================
-- MATRIX RAIN (dentro del UI solamente)
-- =====================================================
local function createMatrixRain(parent, w, h)
    local canvas = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 1,
    }, parent)

    local COLS    = math.floor(w / 14)
    local chars   = "0123456789ABCDEF><$#@!%^&*|/\\"
    local columns = {}

    for i = 1, COLS do
        local col = {
            x     = (i - 1) * 14,
            y     = math.random(-h, 0),
            speed = math.random(60, 140),
            len   = math.random(4, 10),
            drops = {},
        }
        -- Crear labels para cada drop de la columna
        for j = 1, col.len do
            local lbl = make("TextLabel", {
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundTransparency = 1,
                TextSize = 10,
                Font = FONT,
                Text = string.sub(chars, math.random(1, #chars), math.random(1, #chars)),
                TextColor3 = j == 1 and Color3.fromRGB(180, 255, 200) or C.accentDim,
                TextTransparency = j == 1 and 0 or (j / col.len) * 0.85,
                ZIndex = 1,
            }, canvas)
            col.drops[j] = lbl
        end
        table.insert(columns, col)
    end

    -- Animacion
    local last = tick()
    local conn = RunService.Heartbeat:Connect(function()
        local now = tick()
        local dt  = now - last
        last = now

        for _, col in ipairs(columns) do
            col.y = col.y + col.speed * dt
            if col.y > h + col.len * 14 then
                col.y     = math.random(-80, -10)
                col.speed = math.random(60, 140)
            end
            for j, lbl in ipairs(col.drops) do
                local py = col.y - (j - 1) * 14
                lbl.Position = UDim2.new(0, col.x, 0, py)
                lbl.Visible = py > -14 and py < h
                -- Cambiar char aleatoriamente
                if math.random() < 0.03 then
                    lbl.Text = string.sub(chars, math.random(1, #chars), math.random(1, #chars))
                end
            end
        end
    end)

    return canvas, conn
end

-- =====================================================
-- CONSTRUCTOR PRINCIPAL
-- =====================================================
function JoshLib.new(config)
    config = config or {}
    local title   = config.title   or "JOSHLIB"
    local width   = config.width   or 420
    local height  = config.height  or 480

    local lib = {
        _tabs     = {},
        _activeTab = nil,
        _visible  = true,
        _conns    = {},
    }

    -- ScreenGui
    local gui = make("ScreenGui", {
        Name           = "JoshLib",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LocalPlayer.PlayerGui end

    -- Ventana principal
    local win = make("Frame", {
        Name              = "Window",
        Size              = UDim2.new(0, width, 0, height),
        Position          = UDim2.new(0.5, -width/2, 0.5, -height/2),
        BackgroundColor3  = C.bg,
        BorderSizePixel   = 0,
        ClipsDescendants  = true,
    }, gui)
    corner(6, win)
    stroke(C.border, 1, win)

    -- Matrix rain de fondo
    local _, matrixConn = createMatrixRain(win, width, height)
    table.insert(lib._conns, matrixConn)

    -- Overlay oscuro encima del matrix para no matar la legibilidad
    make("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.bg,
        BackgroundTransparency = 0.3,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, win)

    -- =====================================================
    -- HEADER
    -- =====================================================
    local header = make("Frame", {
        Size             = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = C.bgPanel,
        BorderSizePixel  = 0,
        ZIndex           = 10,
    }, win)
    stroke(C.border, 1, header)

    -- Línea accent izquierda
    make("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel  = 0,
        ZIndex           = 11,
    }, header)

    -- Titulo
    make("TextLabel", {
        Size             = UDim2.new(1, -20, 1, 0),
        Position         = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text             = "> "..title.."_",
        TextColor3       = C.accent,
        TextSize         = 13,
        Font             = FONT_BOLD,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 11,
    }, header)

    -- Badge RightShift
    make("TextLabel", {
        Size             = UDim2.new(0, 90, 0, 18),
        Position         = UDim2.new(1, -96, 0.5, -9),
        BackgroundColor3 = C.accentDark,
        Text             = "[RSHIFT] HIDE",
        TextColor3       = C.textDim,
        TextSize         = 9,
        Font             = FONT,
        ZIndex           = 11,
    }, header)
    corner(3, header:FindFirstChild("TextLabel") or header)
    -- fix: badge es el ultimo hijo
    local badge = header:GetChildren()[#header:GetChildren()]
    corner(3, badge)

    -- Drag
    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- =====================================================
    -- TAB BAR
    -- =====================================================
    local tabBar = make("Frame", {
        Size             = UDim2.new(1, 0, 0, 28),
        Position         = UDim2.new(0, 0, 0, 38),
        BackgroundColor3 = C.bgPanel,
        BorderSizePixel  = 0,
        ZIndex           = 10,
    }, win)
    stroke(C.border, 1, tabBar)

    local tabLayout = make("UIListLayout", {
        FillDirection    = Enum.FillDirection.Horizontal,
        SortOrder        = Enum.SortOrder.LayoutOrder,
        Padding          = UDim.new(0, 1),
    }, tabBar)

    -- =====================================================
    -- CONTENT AREA
    -- =====================================================
    local content = make("ScrollingFrame", {
        Size             = UDim2.new(1, -4, 1, -72),
        Position         = UDim2.new(0, 2, 0, 68),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accentDim,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex           = 10,
    }, win)

    local contentLayout = make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 4),
    }, content)

    make("UIPadding", {
        PaddingTop    = UDim.new(0, 4),
        PaddingLeft   = UDim.new(0, 6),
        PaddingRight  = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 4),
    }, content)

    -- =====================================================
    -- TOGGLE VISIBILIDAD
    -- =====================================================
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            lib._visible = not lib._visible
            win.Visible  = lib._visible
        end
    end)

    -- =====================================================
    -- METODO: AddTab
    -- =====================================================
    function lib:AddTab(name)
        local tab = {
            _elements = {},
            _frames   = {},
        }

        -- Boton del tab
        local tabBtn = make("TextButton", {
            Size             = UDim2.new(0, 80, 1, 0),
            BackgroundColor3 = C.bgElem,
            BorderSizePixel  = 0,
            Text             = name,
            TextColor3       = C.textDim,
            TextSize         = 10,
            Font             = FONT,
            ZIndex           = 11,
            LayoutOrder      = #self._tabs + 1,
        }, tabBar)
        stroke(C.border, 1, tabBtn)

        -- Frame de contenido del tab
        local tabFrame = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            Visible          = false,
            AutomaticSize    = Enum.AutomaticSize.Y,
            ZIndex           = 10,
        }, content)

        local frameLayout = make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 4),
        }, tabFrame)

        tab._btn   = tabBtn
        tab._frame = tabFrame

        local function activate()
            -- Desactivar todos
            for _, t in ipairs(self._tabs) do
                t._frame.Visible      = false
                t._btn.TextColor3     = C.textDim
                t._btn.BackgroundColor3 = C.bgElem
            end
            -- Activar este
            tabFrame.Visible          = true
            tabBtn.TextColor3         = C.accent
            tabBtn.BackgroundColor3   = C.accentDark
            self._activeTab           = tab
        end

        tabBtn.MouseButton1Click:Connect(activate)
        tabBtn.MouseEnter:Connect(function()
            if self._activeTab ~= tab then
                tabBtn.BackgroundColor3 = C.bgHover
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if self._activeTab ~= tab then
                tabBtn.BackgroundColor3 = C.bgElem
            end
        end)

        -- Activar primero
        if #self._tabs == 0 then
            activate()
        end

        table.insert(self._tabs, tab)

        -- =====================================================
        -- METODO: AddToggle
        -- =====================================================
        function tab:AddToggle(config)
            config = config or {}
            local lbl      = config.title or "Toggle"
            local default  = config.default or false
            local callback = config.callback or function() end

            local state = default

            local row = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = C.bgElem,
                BorderSizePixel  = 0,
                ZIndex           = 12,
                LayoutOrder      = #tab._elements + 1,
            }, tabFrame)
            corner(4, row)
            stroke(C.border, 1, row)

            -- Label
            make("TextLabel", {
                Size             = UDim2.new(1, -50, 1, 0),
                Position         = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text             = "> "..lbl,
                TextColor3       = state and C.text or C.textOff,
                TextSize         = 11,
                Font             = FONT,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 13,
            }, row)

            -- Switch
            local switchBg = make("Frame", {
                Size             = UDim2.new(0, 36, 0, 16),
                Position         = UDim2.new(1, -44, 0.5, -8),
                BackgroundColor3 = state and C.accentDim or C.bgHover,
                BorderSizePixel  = 0,
                ZIndex           = 13,
            }, row)
            corner(8, switchBg)

            local switchDot = make("Frame", {
                Size             = UDim2.new(0, 12, 0, 12),
                Position         = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
                BackgroundColor3 = state and C.accent or C.textDim,
                BorderSizePixel  = 0,
                ZIndex           = 14,
            }, switchBg)
            corner(6, switchDot)

            local textLbl = row:FindFirstChildOfClass("TextLabel")

            local function updateVisual()
                tween(switchBg, { BackgroundColor3 = state and C.accentDim or C.bgHover })
                tween(switchDot, {
                    BackgroundColor3 = state and C.accent or C.textDim,
                    Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
                })
                textLbl.TextColor3 = state and C.text or C.textOff
            end

            local btn = make("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 15,
            }, row)

            btn.MouseButton1Click:Connect(function()
                state = not state
                updateVisual()
                pcall(callback, state)
            end)

            btn.MouseEnter:Connect(function()
                tween(row, { BackgroundColor3 = C.bgHover })
            end)
            btn.MouseLeave:Connect(function()
                tween(row, { BackgroundColor3 = C.bgElem })
            end)

            if default then pcall(callback, true) end

            local elem = {
                SetValue = function(_, v)
                    state = v
                    updateVisual()
                    pcall(callback, state)
                end,
                GetValue = function() return state end,
            }
            table.insert(tab._elements, elem)
            return elem
        end

        -- =====================================================
        -- METODO: AddSlider
        -- =====================================================
        function tab:AddSlider(config)
            config = config or {}
            local lbl      = config.title or "Slider"
            local min      = config.min or 0
            local max      = config.max or 100
            local default  = config.default or min
            local suffix   = config.suffix or ""
            local callback = config.callback or function() end

            local value = math.clamp(default, min, max)

            local row = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = C.bgElem,
                BorderSizePixel  = 0,
                ZIndex           = 12,
                LayoutOrder      = #tab._elements + 1,
            }, tabFrame)
            corner(4, row)
            stroke(C.border, 1, row)

            -- Label + valor
            local topLabel = make("TextLabel", {
                Size             = UDim2.new(1, -10, 0, 18),
                Position         = UDim2.new(0, 10, 0, 4),
                BackgroundTransparency = 1,
                Text             = "> "..lbl.." : "..value..suffix,
                TextColor3       = C.text,
                TextSize         = 11,
                Font             = FONT,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 13,
            }, row)

            -- Track
            local track = make("Frame", {
                Size             = UDim2.new(1, -20, 0, 6),
                Position         = UDim2.new(0, 10, 0, 28),
                BackgroundColor3 = C.bgHover,
                BorderSizePixel  = 0,
                ZIndex           = 13,
            }, row)
            corner(3, track)

            -- Fill
            local pct  = (value - min) / (max - min)
            local fill = make("Frame", {
                Size             = UDim2.new(pct, 0, 1, 0),
                BackgroundColor3 = C.accentDim,
                BorderSizePixel  = 0,
                ZIndex           = 14,
            }, track)
            corner(3, fill)

            -- Knob
            local knob = make("Frame", {
                Size             = UDim2.new(0, 12, 0, 12),
                Position         = UDim2.new(pct, -6, 0.5, -6),
                BackgroundColor3 = C.accent,
                BorderSizePixel  = 0,
                ZIndex           = 15,
            }, track)
            corner(6, knob)

            -- Interaccion
            local sliding = false
            local function updateSlider(inputX)
                local abs = track.AbsolutePosition.X
                local wd  = track.AbsoluteSize.X
                local p   = math.clamp((inputX - abs) / wd, 0, 1)
                value     = math.floor(min + p * (max - min) + 0.5)
                local vp  = (value - min) / (max - min)
                fill.Size     = UDim2.new(vp, 0, 1, 0)
                knob.Position = UDim2.new(vp, -6, 0.5, -6)
                topLabel.Text = "> "..lbl.." : "..value..suffix
                pcall(callback, value)
            end

            local sliderBtn = make("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 16,
            }, row)

            sliderBtn.MouseButton1Down:Connect(function(x)
                sliding = true
                updateSlider(x)
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = false
                end
            end)

            row.MouseEnter:Connect(function()
                tween(row, { BackgroundColor3 = C.bgHover })
            end)
            row.MouseLeave:Connect(function()
                tween(row, { BackgroundColor3 = C.bgElem })
            end)

            pcall(callback, value)

            local elem = {
                SetValue = function(_, v)
                    value = math.clamp(v, min, max)
                    local vp = (value - min) / (max - min)
                    fill.Size     = UDim2.new(vp, 0, 1, 0)
                    knob.Position = UDim2.new(vp, -6, 0.5, -6)
                    topLabel.Text = "> "..lbl.." : "..value..suffix
                    pcall(callback, value)
                end,
                GetValue = function() return value end,
            }
            table.insert(tab._elements, elem)
            return elem
        end

        -- =====================================================
        -- METODO: AddButton
        -- =====================================================
        function tab:AddButton(config)
            config = config or {}
            local lbl      = config.title or "Button"
            local callback = config.callback or function() end

            local row = make("TextButton", {
                Size             = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = C.bgElem,
                BorderSizePixel  = 0,
                Text             = "> [ "..lbl.." ]",
                TextColor3       = C.accent,
                TextSize         = 11,
                Font             = FONT,
                ZIndex           = 12,
                LayoutOrder      = #tab._elements + 1,
            }, tabFrame)
            corner(4, row)
            stroke(C.border, 1, row)

            row.MouseButton1Click:Connect(function()
                tween(row, { BackgroundColor3 = C.accentDark })
                task.delay(0.1, function()
                    tween(row, { BackgroundColor3 = C.bgElem })
                end)
                pcall(callback)
            end)
            row.MouseEnter:Connect(function()
                tween(row, { BackgroundColor3 = C.bgHover })
                tween(row, { TextColor3 = Color3.fromRGB(255, 255, 255) })
            end)
            row.MouseLeave:Connect(function()
                tween(row, { BackgroundColor3 = C.bgElem })
                tween(row, { TextColor3 = C.accent })
            end)
        end

        -- =====================================================
        -- METODO: AddDropdown
        -- =====================================================
        function tab:AddDropdown(config)
            config = config or {}
            local lbl      = config.title or "Dropdown"
            local options  = config.options or {}
            local callback = config.callback or function() end

            local selected = options[1] or "---"
            local open     = false

            local container = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                ZIndex           = 12,
                LayoutOrder      = #tab._elements + 1,
                AutomaticSize    = Enum.AutomaticSize.Y,
                ClipsDescendants = false,
            }, tabFrame)

            local header2 = make("TextButton", {
                Size             = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = C.bgElem,
                BorderSizePixel  = 0,
                Text             = "",
                ZIndex           = 12,
            }, container)
            corner(4, header2)
            stroke(C.border, 1, header2)

            make("TextLabel", {
                Size             = UDim2.new(0.6, 0, 1, 0),
                Position         = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text             = "> "..lbl,
                TextColor3       = C.text,
                TextSize         = 11,
                Font             = FONT,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 13,
            }, header2)

            local valLabel = make("TextLabel", {
                Size             = UDim2.new(0.35, 0, 1, 0),
                Position         = UDim2.new(0.6, 0, 0, 0),
                BackgroundTransparency = 1,
                Text             = selected.." v",
                TextColor3       = C.accentDim,
                TextSize         = 10,
                Font             = FONT,
                TextXAlignment   = Enum.TextXAlignment.Right,
                ZIndex           = 13,
            }, header2)

            -- Lista desplegable
            local list = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 0, 32),
                BackgroundColor3 = C.bgPanel,
                BorderSizePixel  = 0,
                Visible          = false,
                ZIndex           = 20,
                AutomaticSize    = Enum.AutomaticSize.Y,
            }, container)
            corner(4, list)
            stroke(C.borderBright, 1, list)

            local listLayout = make("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 1),
            }, list)
            make("UIPadding", { PaddingTop = UDim.new(0,2), PaddingBottom = UDim.new(0,2) }, list)

            for i, opt in ipairs(options) do
                local optBtn = make("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 24),
                    BackgroundColor3 = C.bgElem,
                    BorderSizePixel  = 0,
                    Text             = "  "..opt,
                    TextColor3       = C.text,
                    TextSize         = 10,
                    Font             = FONT,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 21,
                    LayoutOrder      = i,
                }, list)

                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    valLabel.Text = opt.." v"
                    open = false
                    list.Visible = false
                    pcall(callback, opt)
                end)
                optBtn.MouseEnter:Connect(function()
                    tween(optBtn, { BackgroundColor3 = C.bgHover, TextColor3 = C.accent })
                end)
                optBtn.MouseLeave:Connect(function()
                    tween(optBtn, { BackgroundColor3 = C.bgElem, TextColor3 = C.text })
                end)
            end

            header2.MouseButton1Click:Connect(function()
                open = not open
                list.Visible = open
                valLabel.Text = selected..(open and " ^" or " v")
            end)
            header2.MouseEnter:Connect(function()
                tween(header2, { BackgroundColor3 = C.bgHover })
            end)
            header2.MouseLeave:Connect(function()
                tween(header2, { BackgroundColor3 = C.bgElem })
            end)

            pcall(callback, selected)

            local elem = {
                GetValue = function() return selected end,
                SetOptions = function(_, opts)
                    options = opts
                end,
            }
            table.insert(tab._elements, elem)
            return elem
        end

        -- =====================================================
        -- METODO: AddLabel
        -- =====================================================
        function tab:AddLabel(text)
            local lbl = make("TextLabel", {
                Size             = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text             = "// "..text,
                TextColor3       = C.textDim,
                TextSize         = 10,
                Font             = FONT,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 12,
                LayoutOrder      = #tab._elements + 1,
            }, tabFrame)
            make("UIPadding", { PaddingLeft = UDim.new(0, 6) }, lbl)
            return lbl
        end

        -- =====================================================
        -- METODO: AddSeparator
        -- =====================================================
        function tab:AddSeparator()
            local sep = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = C.border,
                BorderSizePixel  = 0,
                ZIndex           = 12,
                LayoutOrder      = #tab._elements + 1,
            }, tabFrame)
            table.insert(tab._elements, {})
            return sep
        end

        return tab
    end

    -- =====================================================
    -- METODO: Notify
    -- =====================================================
    function lib:Notify(text, duration)
        duration = duration or 3
        local notif = make("Frame", {
            Size             = UDim2.new(0, 240, 0, 36),
            Position         = UDim2.new(1, -250, 1, -50),
            BackgroundColor3 = C.bgPanel,
            BorderSizePixel  = 0,
            BackgroundTransparency = 0.1,
            ZIndex           = 100,
        }, gui)
        corner(4, notif)
        stroke(C.accent, 1, notif)

        make("TextLabel", {
            Size             = UDim2.new(1, -10, 1, 0),
            Position         = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text             = "> "..text,
            TextColor3       = C.accent,
            TextSize         = 11,
            Font             = FONT,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 101,
        }, notif)

        tween(notif, { Position = UDim2.new(1, -250, 1, -50) }, 0)
        task.delay(duration, function()
            tween(notif, { BackgroundTransparency = 1 }, 0.3)
            task.delay(0.35, function() notif:Destroy() end)
        end)
    end

    -- =====================================================
    -- METODO: Destroy
    -- =====================================================
    function lib:Destroy()
        for _, conn in ipairs(self._conns) do pcall(function() conn:Disconnect() end) end
        gui:Destroy()
    end

    return lib
end

return JoshLib
