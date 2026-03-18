-- =====================================================
-- NEXOR UI — Premium Library
-- Estilo: Dark Military / Tactical
-- Sin dependencias externas
-- RightShift: mostrar/ocultar
-- =====================================================

local NexorUI = {}

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer

-- =====================================================
-- PALETA
-- =====================================================
local P = {
    bg0      = Color3.fromRGB(6,   7,   9),
    bg1      = Color3.fromRGB(11,  13,  17),
    bg2      = Color3.fromRGB(16,  19,  25),
    bg3      = Color3.fromRGB(22,  26,  34),
    line     = Color3.fromRGB(35,  42,  55),
    accent   = Color3.fromRGB(82,  130, 255),
    accentLo = Color3.fromRGB(30,  55,  120),
    accentHi = Color3.fromRGB(140, 180, 255),
    white    = Color3.fromRGB(220, 225, 235),
    gray     = Color3.fromRGB(100, 110, 130),
    grayDim  = Color3.fromRGB(55,  62,  78),
    red      = Color3.fromRGB(220, 70,  70),
    green    = Color3.fromRGB(70,  200, 120),
}

local F  = Enum.Font.Gotham
local FB = Enum.Font.GothamBold

-- =====================================================
-- UTILS
-- =====================================================
local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = p
end

local function tw(o, props, t, style)
    TweenService:Create(o,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        props
    ):Play()
end

local function stroke(col, th, p)
    local s = Instance.new("UIStroke")
    s.Color     = col
    s.Thickness = th
    s.Parent    = p
    return s
end

local function shadow(parent)
    local sh = new("ImageLabel", {
        Size               = UDim2.new(1, 30, 1, 30),
        Position           = UDim2.new(0, -15, 0, -15),
        BackgroundTransparency = 1,
        Image              = "rbxassetid://6015897843",
        ImageColor3        = Color3.fromRGB(0,0,0),
        ImageTransparency  = 0.5,
        ScaleType          = Enum.ScaleType.Slice,
        SliceCenter        = Rect.new(49,49,450,450),
        ZIndex             = 0,
    }, parent)
    return sh
end

-- =====================================================
-- CONSTRUCTOR
-- =====================================================
function NexorUI.new(cfg)
    cfg = cfg or {}
    local TITLE = cfg.title or "NEXOR"
    local W     = cfg.width  or 440
    local H     = cfg.height or 520

    local lib = { _tabs = {}, _active = nil, _open = true, _conns = {} }

    -- ScreenGui
    local sg = new("ScreenGui", {
        Name           = "NexorUI",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder   = 999,
    })
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then sg.Parent = LocalPlayer.PlayerGui end

    -- =====================================================
    -- VENTANA
    -- =====================================================
    local win = new("Frame", {
        Name             = "Win",
        Size             = UDim2.new(0, W, 0, H),
        Position         = UDim2.new(0.5, -W/2, 0.5, -H/2),
        BackgroundColor3 = P.bg0,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, sg)
    corner(8, win)
    stroke(P.line, 1, win)
    shadow(win)

    -- Gradiente sutil de fondo
    local grad = new("UIGradient", {
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(14, 18, 26)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(6,  7,  9)),
        }),
        Rotation = 135,
    }, win)

    -- =====================================================
    -- BARRA LATERAL (tabs verticales)
    -- =====================================================
    local sidebar = new("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, 110, 1, 0),
        BackgroundColor3 = P.bg1,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, win)
    stroke(P.line, 1, sidebar)

    -- Logo / título en sidebar
    local logoFrame = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 72),
        BackgroundTransparency = 1,
        ZIndex           = 3,
    }, sidebar)

    -- Línea accent arriba
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = P.accent,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, logoFrame)

    -- Icono cuadrado decorativo
    local iconBox = new("Frame", {
        Size             = UDim2.new(0, 28, 0, 28),
        Position         = UDim2.new(0.5, -14, 0, 16),
        BackgroundColor3 = P.accentLo,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, logoFrame)
    corner(4, iconBox)
    stroke(P.accent, 1, iconBox)

    new("TextLabel", {
        Size             = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text             = "✦",
        TextColor3       = P.accent,
        TextSize         = 14,
        Font             = FB,
        ZIndex           = 4,
    }, iconBox)

    new("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 18),
        Position         = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        Text             = TITLE,
        TextColor3       = P.white,
        TextSize         = 11,
        Font             = FB,
        ZIndex           = 3,
    }, logoFrame)

    -- Lista de tabs en sidebar
    local tabList = new("Frame", {
        Size             = UDim2.new(1, 0, 1, -72),
        Position         = UDim2.new(0, 0, 0, 72),
        BackgroundTransparency = 1,
        ZIndex           = 3,
    }, sidebar)

    local tabLayout = new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 2),
    }, tabList)

    new("UIPadding", {
        PaddingLeft   = UDim.new(0, 6),
        PaddingRight  = UDim.new(0, 6),
        PaddingTop    = UDim.new(0, 6),
    }, tabList)

    -- Footer sidebar
    local footer = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 28),
        Position         = UDim2.new(0, 0, 1, -28),
        BackgroundTransparency = 1,
        ZIndex           = 3,
    }, sidebar)

    new("TextLabel", {
        Size             = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text             = "RShift · show/hide",
        TextColor3       = P.grayDim,
        TextSize         = 8,
        Font             = F,
        ZIndex           = 3,
    }, footer)

    -- =====================================================
    -- AREA DE CONTENIDO
    -- =====================================================
    local contentArea = new("Frame", {
        Name             = "Content",
        Size             = UDim2.new(1, -110, 1, -42),
        Position         = UDim2.new(0, 110, 0, 42),
        BackgroundTransparency = 1,
        ZIndex           = 2,
        ClipsDescendants = true,
    }, win)

    -- =====================================================
    -- HEADER DERECHO
    -- =====================================================
    local header = new("Frame", {
        Size             = UDim2.new(1, -110, 0, 42),
        Position         = UDim2.new(0, 110, 0, 0),
        BackgroundColor3 = P.bg1,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, win)
    stroke(P.line, 1, header)

    -- Breadcrumb
    local breadcrumb = new("TextLabel", {
        Size             = UDim2.new(1, -20, 1, 0),
        Position         = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text             = TITLE.." / —",
        TextColor3       = P.gray,
        TextSize         = 10,
        Font             = F,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 6,
    }, header)

    -- Indicador online
    local dot = new("Frame", {
        Size             = UDim2.new(0, 6, 0, 6),
        Position         = UDim2.new(1, -20, 0.5, -3),
        BackgroundColor3 = P.green,
        BorderSizePixel  = 0,
        ZIndex           = 6,
    }, header)
    corner(3, dot)

    -- Pulsar del dot
    task.spawn(function()
        while true do
            tw(dot, { BackgroundTransparency = 0.6 }, 0.8)
            task.wait(0.9)
            tw(dot, { BackgroundTransparency = 0 }, 0.8)
            task.wait(0.9)
        end
    end)

    -- =====================================================
    -- DRAG
    -- =====================================================
    local dragging, dstart, wstart = false, nil, nil
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dstart = i.Position; wstart = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dstart
            win.Position = UDim2.new(wstart.X.Scale, wstart.X.Offset + d.X,
                                     wstart.Y.Scale, wstart.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- RightShift toggle
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            lib._open = not lib._open
            if lib._open then
                win.Visible = true
                tw(win, { Position = UDim2.new(0.5, -W/2, 0.5, -H/2) }, 0.25)
            else
                tw(win, { Position = UDim2.new(0.5, -W/2, 0.5, -H/2 - 20) }, 0.2)
                task.delay(0.22, function() win.Visible = false end)
            end
        end
    end)

    -- =====================================================
    -- METODO: AddTab
    -- =====================================================
    function lib:AddTab(name, icon)
        local tab = { _elems = {}, _order = #self._tabs + 1 }

        -- Boton en sidebar
        local btn = new("TextButton", {
            Size             = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = P.bg2,
            BorderSizePixel  = 0,
            Text             = "",
            ZIndex           = 4,
            LayoutOrder      = tab._order,
        }, tabList)
        corner(5, btn)

        -- Indicador izquierdo
        local indicator = new("Frame", {
            Size             = UDim2.new(0, 2, 0.6, 0),
            Position         = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = P.accent,
            BorderSizePixel  = 0,
            BackgroundTransparency = 1,
            ZIndex           = 5,
        }, btn)
        corner(2, indicator)

        new("TextLabel", {
            Size             = UDim2.new(1, -8, 1, 0),
            Position         = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text             = name,
            TextColor3       = P.grayDim,
            TextSize         = 10,
            Font             = F,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 5,
        }, btn)

        -- Frame de contenido
        local frame = new("ScrollingFrame", {
            Size                = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel     = 0,
            ScrollBarThickness  = 2,
            ScrollBarImageColor3 = P.accentLo,
            CanvasSize          = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible             = false,
            ZIndex              = 3,
        }, contentArea)

        local fl = new("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 5),
        }, frame)

        new("UIPadding", {
            PaddingTop    = UDim.new(0, 10),
            PaddingLeft   = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
        }, frame)

        tab._btn   = btn
        tab._frame = frame
        tab._ind   = indicator
        tab._lbl   = btn:FindFirstChildOfClass("TextLabel")

        local function activate()
            for _, t in ipairs(self._tabs) do
                t._frame.Visible = false
                tw(t._btn,  { BackgroundColor3 = P.bg2 })
                tw(t._lbl,  { TextColor3 = P.grayDim })
                tw(t._ind,  { BackgroundTransparency = 1 })
            end
            frame.Visible = true
            tw(btn,       { BackgroundColor3 = P.bg3 })
            tw(tab._lbl,  { TextColor3 = P.white })
            tw(indicator, { BackgroundTransparency = 0 })
            breadcrumb.Text = TITLE.." / "..name
            self._active = tab
        end

        btn.MouseButton1Click:Connect(activate)
        btn.MouseEnter:Connect(function()
            if self._active ~= tab then
                tw(btn, { BackgroundColor3 = P.bg3 })
                tw(tab._lbl, { TextColor3 = P.gray })
            end
        end)
        btn.MouseLeave:Connect(function()
            if self._active ~= tab then
                tw(btn, { BackgroundColor3 = P.bg2 })
                tw(tab._lbl, { TextColor3 = P.grayDim })
            end
        end)

        if #self._tabs == 0 then activate() end
        table.insert(self._tabs, tab)

        -- --------------------------------------------------
        -- SECCION
        -- --------------------------------------------------
        function tab:AddSection(name)
            local sec = new("Frame", {
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                ZIndex           = 4,
                LayoutOrder      = #tab._elems + 1,
            }, frame)

            new("TextLabel", {
                Size             = UDim2.new(0, 0, 1, 0),
                AutomaticSize    = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text             = name:upper(),
                TextColor3       = P.accent,
                TextSize         = 9,
                Font             = FB,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 5,
            }, sec)

            new("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = P.line,
                BorderSizePixel  = 0,
                ZIndex           = 4,
            }, sec)

            table.insert(tab._elems, sec)
        end

        -- --------------------------------------------------
        -- TOGGLE
        -- --------------------------------------------------
        function tab:AddToggle(cfg2)
            cfg2 = cfg2 or {}
            local lbl  = cfg2.title    or "Toggle"
            local desc = cfg2.desc     or ""
            local def  = cfg2.default  or false
            local cb   = cfg2.callback or function() end
            local state = def

            local h = desc ~= "" and 48 or 32

            local row = new("Frame", {
                Size             = UDim2.new(1, 0, 0, h),
                BackgroundColor3 = P.bg2,
                BorderSizePixel  = 0,
                ZIndex           = 4,
                LayoutOrder      = #tab._elems + 1,
            }, frame)
            corner(6, row)
            stroke(P.line, 1, row)

            new("TextLabel", {
                Size             = UDim2.new(1, -60, 0, 18),
                Position         = UDim2.new(0, 12, 0, h/2 - (desc~="" and 12 or 9)),
                BackgroundTransparency = 1,
                Text             = lbl,
                TextColor3       = P.white,
                TextSize         = 11,
                Font             = FB,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 5,
            }, row)

            if desc ~= "" then
                new("TextLabel", {
                    Size             = UDim2.new(1, -60, 0, 14),
                    Position         = UDim2.new(0, 12, 0, h/2 + 2),
                    BackgroundTransparency = 1,
                    Text             = desc,
                    TextColor3       = P.gray,
                    TextSize         = 9,
                    Font             = F,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 5,
                }, row)
            end

            -- Switch track
            local track = new("Frame", {
                Size             = UDim2.new(0, 38, 0, 20),
                Position         = UDim2.new(1, -50, 0.5, -10),
                BackgroundColor3 = state and P.accentLo or P.bg3,
                BorderSizePixel  = 0,
                ZIndex           = 5,
            }, row)
            corner(10, track)
            stroke(state and P.accent or P.line, 1, track)

            local knob = new("Frame", {
                Size             = UDim2.new(0, 14, 0, 14),
                Position         = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                BackgroundColor3 = state and P.accent or P.grayDim,
                BorderSizePixel  = 0,
                ZIndex           = 6,
            }, track)
            corner(7, knob)

            local tStroke = track:FindFirstChildOfClass("UIStroke")

            local function refresh()
                tw(track, { BackgroundColor3 = state and P.accentLo or P.bg3 })
                tw(knob,  {
                    BackgroundColor3 = state and P.accent or P.grayDim,
                    Position = state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
                })
                if tStroke then
                    tw(tStroke, { Color = state and P.accent or P.line })
                end
            end

            local hitbox = new("TextButton", {
                Size             = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 7,
            }, row)

            hitbox.MouseButton1Click:Connect(function()
                state = not state
                refresh()
                pcall(cb, state)
            end)
            hitbox.MouseEnter:Connect(function()
                tw(row, { BackgroundColor3 = P.bg3 })
            end)
            hitbox.MouseLeave:Connect(function()
                tw(row, { BackgroundColor3 = P.bg2 })
            end)

            if def then pcall(cb, true) end

            local elem = {}
            function elem:Set(v) state = v; refresh(); pcall(cb, v) end
            function elem:Get() return state end
            table.insert(tab._elems, elem)
            return elem
        end

        -- --------------------------------------------------
        -- SLIDER
        -- --------------------------------------------------
        function tab:AddSlider(cfg2)
            cfg2 = cfg2 or {}
            local lbl  = cfg2.title    or "Slider"
            local mn   = cfg2.min      or 0
            local mx   = cfg2.max      or 100
            local def  = cfg2.default  or mn
            local suf  = cfg2.suffix   or ""
            local cb   = cfg2.callback or function() end
            local val  = math.clamp(def, mn, mx)

            local row = new("Frame", {
                Size             = UDim2.new(1, 0, 0, 52),
                BackgroundColor3 = P.bg2,
                BorderSizePixel  = 0,
                ZIndex           = 4,
                LayoutOrder      = #tab._elems + 1,
            }, frame)
            corner(6, row)
            stroke(P.line, 1, row)

            local topRow = new("Frame", {
                Size             = UDim2.new(1, -20, 0, 20),
                Position         = UDim2.new(0, 10, 0, 8),
                BackgroundTransparency = 1,
                ZIndex           = 5,
            }, row)

            new("TextLabel", {
                Size             = UDim2.new(0.65, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = lbl,
                TextColor3       = P.white,
                TextSize         = 11,
                Font             = FB,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 5,
            }, topRow)

            local valLbl = new("TextLabel", {
                Size             = UDim2.new(0.35, 0, 1, 0),
                Position         = UDim2.new(0.65, 0, 0, 0),
                BackgroundTransparency = 1,
                Text             = val..suf,
                TextColor3       = P.accent,
                TextSize         = 11,
                Font             = FB,
                TextXAlignment   = Enum.TextXAlignment.Right,
                ZIndex           = 5,
            }, topRow)

            -- Track
            local track = new("Frame", {
                Size             = UDim2.new(1, -20, 0, 4),
                Position         = UDim2.new(0, 10, 0, 36),
                BackgroundColor3 = P.bg3,
                BorderSizePixel  = 0,
                ZIndex           = 5,
            }, row)
            corner(2, track)

            local pct  = (val - mn) / (mx - mn)
            local fill = new("Frame", {
                Size             = UDim2.new(pct, 0, 1, 0),
                BackgroundColor3 = P.accent,
                BorderSizePixel  = 0,
                ZIndex           = 6,
            }, track)
            corner(2, fill)

            local knob = new("Frame", {
                Size             = UDim2.new(0, 14, 0, 14),
                Position         = UDim2.new(pct, -7, 0.5, -7),
                BackgroundColor3 = P.white,
                BorderSizePixel  = 0,
                ZIndex           = 7,
            }, track)
            corner(7, knob)
            stroke(P.accent, 2, knob)

            local sliding = false
            local function update(x)
                local p  = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                val      = math.floor(mn + p * (mx - mn) + 0.5)
                local vp = (val - mn) / (mx - mn)
                fill.Size     = UDim2.new(vp, 0, 1, 0)
                knob.Position = UDim2.new(vp, -7, 0.5, -7)
                valLbl.Text   = val..suf
                pcall(cb, val)
            end

            local hit = new("TextButton", {
                Size             = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 8,
            }, row)
            hit.MouseButton1Down:Connect(function(x) sliding = true; update(x) end)
            UserInputService.InputChanged:Connect(function(i)
                if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
                    update(i.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
            end)
            hit.MouseEnter:Connect(function() tw(row, { BackgroundColor3 = P.bg3 }) end)
            hit.MouseLeave:Connect(function() tw(row, { BackgroundColor3 = P.bg2 }) end)

            pcall(cb, val)

            local elem = {}
            function elem:Set(v)
                val = math.clamp(v, mn, mx)
                local vp = (val-mn)/(mx-mn)
                fill.Size = UDim2.new(vp,0,1,0)
                knob.Position = UDim2.new(vp,-7,0.5,-7)
                valLbl.Text = val..suf
                pcall(cb, val)
            end
            function elem:Get() return val end
            table.insert(tab._elems, elem)
            return elem
        end

        -- --------------------------------------------------
        -- BUTTON
        -- --------------------------------------------------
        function tab:AddButton(cfg2)
            cfg2 = cfg2 or {}
            local lbl = cfg2.title    or "Button"
            local cb  = cfg2.callback or function() end

            local btn2 = new("TextButton", {
                Size             = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = P.bg2,
                BorderSizePixel  = 0,
                Text             = "",
                ZIndex           = 4,
                LayoutOrder      = #tab._elems + 1,
            }, frame)
            corner(6, btn2)
            stroke(P.line, 1, btn2)

            -- accent line izq
            local acLine = new("Frame", {
                Size             = UDim2.new(0, 3, 0.5, 0),
                Position         = UDim2.new(0, 0, 0.25, 0),
                BackgroundColor3 = P.accent,
                BorderSizePixel  = 0,
                ZIndex           = 5,
            }, btn2)
            corner(2, acLine)

            new("TextLabel", {
                Size             = UDim2.new(1, -20, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text             = lbl,
                TextColor3       = P.white,
                TextSize         = 11,
                Font             = FB,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 5,
            }, btn2)

            new("TextLabel", {
                Size             = UDim2.new(0, 20, 1, 0),
                Position         = UDim2.new(1, -24, 0, 0),
                BackgroundTransparency = 1,
                Text             = "›",
                TextColor3       = P.accent,
                TextSize         = 14,
                Font             = FB,
                ZIndex           = 5,
            }, btn2)

            btn2.MouseButton1Click:Connect(function()
                tw(btn2, { BackgroundColor3 = P.accentLo }, 0.08)
                task.delay(0.12, function() tw(btn2, { BackgroundColor3 = P.bg2 }) end)
                pcall(cb)
            end)
            btn2.MouseEnter:Connect(function() tw(btn2, { BackgroundColor3 = P.bg3 }) end)
            btn2.MouseLeave:Connect(function() tw(btn2, { BackgroundColor3 = P.bg2 }) end)
        end

        -- --------------------------------------------------
        -- DROPDOWN
        -- --------------------------------------------------
        function tab:AddDropdown(cfg2)
            cfg2 = cfg2 or {}
            local lbl     = cfg2.title    or "Dropdown"
            local options = cfg2.options  or {}
            local cb      = cfg2.callback or function() end
            local sel     = options[1] or "—"
            local open    = false

            local container = new("Frame", {
                Size             = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                ZIndex           = 4,
                LayoutOrder      = #tab._elems + 1,
                AutomaticSize    = Enum.AutomaticSize.Y,
                ClipsDescendants = false,
            }, frame)

            local hdr = new("TextButton", {
                Size             = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = P.bg2,
                BorderSizePixel  = 0,
                Text             = "",
                ZIndex           = 4,
            }, container)
            corner(6, hdr)
            stroke(P.line, 1, hdr)

            new("TextLabel", {
                Size             = UDim2.new(0.55, 0, 1, 0),
                Position         = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text             = lbl,
                TextColor3       = P.white,
                TextSize         = 11,
                Font             = FB,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 5,
            }, hdr)

            local selLbl = new("TextLabel", {
                Size             = UDim2.new(0.4, 0, 1, 0),
                Position         = UDim2.new(0.55, 0, 0, 0),
                BackgroundTransparency = 1,
                Text             = sel,
                TextColor3       = P.accent,
                TextSize         = 10,
                Font             = F,
                TextXAlignment   = Enum.TextXAlignment.Right,
                ZIndex           = 5,
            }, hdr)

            local arrow = new("TextLabel", {
                Size             = UDim2.new(0, 20, 1, 0),
                Position         = UDim2.new(1, -22, 0, 0),
                BackgroundTransparency = 1,
                Text             = "∨",
                TextColor3       = P.gray,
                TextSize         = 10,
                Font             = FB,
                ZIndex           = 5,
            }, hdr)

            local list = new("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 0, 34),
                BackgroundColor3 = P.bg1,
                BorderSizePixel  = 0,
                Visible          = false,
                ZIndex           = 20,
                AutomaticSize    = Enum.AutomaticSize.Y,
                ClipsDescendants = false,
            }, container)
            corner(6, list)
            stroke(P.accent, 1, list)

            new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,1) }, list)
            new("UIPadding", { PaddingTop=UDim.new(0,3), PaddingBottom=UDim.new(0,3) }, list)

            for i, opt in ipairs(options) do
                local ob = new("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = P.bg2,
                    BorderSizePixel  = 0,
                    Text             = opt,
                    TextColor3       = P.gray,
                    TextSize         = 10,
                    Font             = F,
                    ZIndex           = 21,
                    LayoutOrder      = i,
                }, list)

                ob.MouseButton1Click:Connect(function()
                    sel = opt
                    selLbl.Text = opt
                    open = false
                    list.Visible = false
                    arrow.Text = "∨"
                    pcall(cb, opt)
                end)
                ob.MouseEnter:Connect(function()
                    tw(ob, { BackgroundColor3 = P.bg3, TextColor3 = P.white })
                end)
                ob.MouseLeave:Connect(function()
                    tw(ob, { BackgroundColor3 = P.bg2, TextColor3 = P.gray })
                end)
            end

            hdr.MouseButton1Click:Connect(function()
                open = not open
                list.Visible = open
                arrow.Text = open and "∧" or "∨"
            end)
            hdr.MouseEnter:Connect(function() tw(hdr, { BackgroundColor3 = P.bg3 }) end)
            hdr.MouseLeave:Connect(function() tw(hdr, { BackgroundColor3 = P.bg2 }) end)

            pcall(cb, sel)

            local elem = { Get = function() return sel end }
            table.insert(tab._elems, elem)
            return elem
        end

        return tab
    end

    -- =====================================================
    -- NOTIFY
    -- =====================================================
    function lib:Notify(msg, duration, type)
        duration = duration or 3
        local col = type == "error" and P.red or type == "success" and P.green or P.accent

        local notif = new("Frame", {
            Size             = UDim2.new(0, 260, 0, 44),
            Position         = UDim2.new(1, 10, 1, -60),
            BackgroundColor3 = P.bg1,
            BorderSizePixel  = 0,
            ZIndex           = 200,
        }, sg)
        corner(6, notif)
        stroke(col, 1, notif)

        new("Frame", {
            Size             = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = col,
            BorderSizePixel  = 0,
            ZIndex           = 201,
        }, notif)
        corner(6, notif:GetChildren()[#notif:GetChildren()])

        new("TextLabel", {
            Size             = UDim2.new(1, -16, 1, 0),
            Position         = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text             = msg,
            TextColor3       = P.white,
            TextSize         = 11,
            Font             = F,
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            ZIndex           = 201,
        }, notif)

        tw(notif, { Position = UDim2.new(1, -270, 1, -60) }, 0.3)
        task.delay(duration, function()
            tw(notif, { Position = UDim2.new(1, 10, 1, -60) }, 0.25)
            task.delay(0.3, function() notif:Destroy() end)
        end)
    end

    -- =====================================================
    -- DESTROY
    -- =====================================================
    function lib:Destroy()
        sg:Destroy()
    end

    lib:Notify("Cargado correctamente", 3, "success")
    return lib
end

return NexorUI
