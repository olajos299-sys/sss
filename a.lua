-- ╔══════════════════════════════════════════════╗
-- ║           NEXLIB  —  by Jos                  ║
-- ║   UI Library  |  Estilo premium              ║
-- ╚══════════════════════════════════════════════╝

-- ══════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local TextService      = game:GetService("TextService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ══════════════════════════════════════════════
-- THEME  (cambia solo aquí para re-temaizar)
-- ══════════════════════════════════════════════
local SCHEME = {
    Background  = Color3.fromRGB(13,  13,  18),   -- fondo principal
    Surface     = Color3.fromRGB(20,  20,  28),   -- sidebar / groupbox header
    Elevated    = Color3.fromRGB(26,  26,  36),   -- groupbox body
    Input       = Color3.fromRGB(32,  32,  44),   -- inputs / sliders
    Hover       = Color3.fromRGB(38,  38,  52),   -- hover
    Accent      = Color3.fromRGB(125, 85,  245),  -- morado primario
    AccentDark  = Color3.fromRGB(85,  55,  185),  -- morado oscuro (toggle off hover)
    AccentLight = Color3.fromRGB(160, 120, 255),  -- morado claro
    Border      = Color3.fromRGB(45,  45,  62),   -- bordes
    BorderLight = Color3.fromRGB(62,  62,  85),   -- bordes hover
    Text        = Color3.fromRGB(240, 240, 250),  -- texto principal
    TextMuted   = Color3.fromRGB(145, 145, 170),  -- texto secundario
    TextDim     = Color3.fromRGB(75,  75,  100),  -- texto dim
    Red         = Color3.fromRGB(235, 65,  65),
    Dark        = Color3.fromRGB(0,   0,   0),
    White       = Color3.fromRGB(255, 255, 255),
}

-- ══════════════════════════════════════════════
-- GLOBALS
-- ══════════════════════════════════════════════
local NexLib = {
    Toggles  = {},
    Options  = {},
    Labels   = {},
    Buttons  = {},
    Signals  = {},
    _corners = {},
    _unload  = {},
    Toggled  = false,
    Unloaded = false,
    DPIScale = 1,
}

-- ══════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════
local TW   = TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWN  = TweenInfo.new(0.25, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

local function tween(obj, props, ti)
    TweenService:Create(obj, ti or TW, props):Play()
end

local function N(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = p
    table.insert(NexLib._corners, c)
    return c
end

local function stroke(col, th, p)
    local s = N("UIStroke", {Color=col, Thickness=th or 1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, p)
    return s
end

local function pad(l,r,t,b,p)
    N("UIPadding",{PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r),PaddingTop=UDim.new(0,t),PaddingBottom=UDim.new(0,b)},p)
end

local function listLayout(parent, spacing, dir)
    return N("UIListLayout",{
        Padding=UDim.new(0, spacing or 0),
        SortOrder=Enum.SortOrder.LayoutOrder,
        FillDirection=dir or Enum.FillDirection.Vertical,
    }, parent)
end

local function textBounds(text, font, size, width)
    local p = Instance.new("GetTextBoundsParams")
    p.Text = text; p.Font = font; p.Size = size
    p.Width = width or 9999; p.RichText = true
    local b = TextService:GetTextBoundsAsync(p)
    return b.X, b.Y
end

local function isClick(inp)
    return (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch)
        and inp.UserInputState == Enum.UserInputState.Begin
end

local function isHover(inp)
    return inp.UserInputType == Enum.UserInputType.MouseMovement
        or (inp.UserInputType == Enum.UserInputType.Touch and inp.UserInputState == Enum.UserInputState.Change)
end

local function isDrag(inp)
    return (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch)
        and (inp.UserInputState == Enum.UserInputState.Begin or inp.UserInputState == Enum.UserInputState.Change)
end

local function giveSignal(conn)
    table.insert(NexLib.Signals, conn)
    return conn
end

local FONT = Font.fromEnum(Enum.Font.GothamMedium)

-- ══════════════════════════════════════════════
-- BASE GROUPBOX (métodos compartidos)
-- ══════════════════════════════════════════════
local BaseGroupbox = {}
BaseGroupbox.__index = BaseGroupbox

function BaseGroupbox:_resize()
    local h = self._list.AbsoluteContentSize.Y / NexLib.DPIScale
    self._holder.Size = UDim2.new(1, 0, 0, h + 43)
end

-- ── AddToggle ──────────────────────────────────
function BaseGroupbox:AddToggle(idx, info)
    info = info or {}
    local val     = info.Default or false
    local text    = info.Text or idx
    local cb      = info.Callback or function() end
    local risky   = info.Risky or false

    local row = N("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Text = "",
        AutoButtonColor = false,
    }, self._container)

    local lbl = N("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -48, 1, 0),
        Text = text,
        TextColor3 = risky and SCHEME.Red or SCHEME.TextMuted,
        TextSize = 14,
        Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = val and 0 or 0.3,
    }, row)

    -- Switch pill
    local pill = N("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(34, 18),
        BackgroundColor3 = val and SCHEME.Accent or SCHEME.Input,
        BorderSizePixel = 0,
    }, row)
    corner(9, pill)
    stroke(val and SCHEME.Accent or SCHEME.Border, 1, pill)
    pad(2,2,2,2, pill)

    local ball = N("Frame", {
        Size = UDim2.fromScale(1,1),
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        AnchorPoint = Vector2.new(val and 1 or 0, 0),
        Position = UDim2.fromScale(val and 1 or 0, 0),
        BackgroundColor3 = SCHEME.Text,
        BorderSizePixel = 0,
    }, pill)
    corner(9, ball)

    local tog = { Value=val, Type="Toggle", Text=text }

    function tog:SetValue(v, silent)
        self.Value = v
        tween(pill, {BackgroundColor3 = v and SCHEME.Accent or SCHEME.Input})
        tween(ball, {AnchorPoint=Vector2.new(v and 1 or 0,0), Position=UDim2.fromScale(v and 1 or 0, 0)})
        tween(lbl,  {TextTransparency = v and 0 or 0.3})
        local st = N("UIStroke",{}, nil)
        pcall(function() pill:FindFirstChildOfClass("UIStroke").Color = v and SCHEME.Accent or SCHEME.Border end)
        if not silent then pcall(cb, v) end
    end

    function tog:SetText(t) text=t; lbl.Text=t end

    row.MouseButton1Click:Connect(function() tog:SetValue(not tog.Value) end)
    row.MouseEnter:Connect(function() tween(lbl, {TextColor3 = risky and SCHEME.Red or SCHEME.Text}) end)
    row.MouseLeave:Connect(function() tween(lbl, {TextColor3 = risky and SCHEME.Red or SCHEME.TextMuted}) end)

    self:_resize()
    NexLib.Toggles[idx] = tog
    return tog
end

-- ── AddSlider ──────────────────────────────────
function BaseGroupbox:AddSlider(idx, info)
    info = info or {}
    local min   = info.Min or 0
    local max   = info.Max or 100
    local val   = math.clamp(info.Default or min, min, max)
    local round = info.Rounding or 0
    local cb    = info.Callback or function() end
    local text  = info.Text or idx
    local suffix= info.Suffix or ""
    local prefix= info.Prefix or ""

    local holder = N("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
    }, self._container)

    -- Label row
    local topRow = N("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,16)}, holder)
    N("TextLabel",{
        BackgroundTransparency=1, Size=UDim2.new(0.6,0,1,0),
        Text=text, TextColor3=SCHEME.TextMuted, TextSize=13, Font=FONT,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, topRow)
    local valLbl = N("TextLabel",{
        AnchorPoint=Vector2.new(1,0), Position=UDim2.fromScale(1,0),
        BackgroundTransparency=1, Size=UDim2.new(0.4,0,1,0),
        Text="", TextColor3=SCHEME.Text, TextSize=13, Font=FONT,
        TextXAlignment=Enum.TextXAlignment.Right,
    }, topRow)

    -- Track
    local track = N("TextButton",{
        AnchorPoint=Vector2.new(0,1), Position=UDim2.fromScale(0,1),
        BackgroundColor3=SCHEME.Input, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,8), Text="", AutoButtonColor=false,
    }, holder)
    corner(4, track)
    stroke(SCHEME.Border, 1, track)

    local fill = N("Frame",{BackgroundColor3=SCHEME.Accent, BorderSizePixel=0, Size=UDim2.fromScale(0,1)}, track)
    corner(4, fill)

    local knob = N("Frame",{
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0,0.5),
        Size=UDim2.fromOffset(12,12), BackgroundColor3=SCHEME.Text, BorderSizePixel=0,
    }, track)
    corner(6, knob)

    local function fmt(v)
        if round == 0 then return math.floor(v+0.5) end
        return math.floor(v*(10^round)+0.5)/(10^round)
    end

    local sl = {Value=val, Type="Slider", Min=min, Max=max}

    local function apply(v)
        v = math.clamp(v, min, max)
        v = fmt(v)
        sl.Value = v
        local pct = (v-min)/(max-min)
        fill.Size  = UDim2.fromScale(pct, 1)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = prefix..tostring(v)..suffix.."/"..tostring(max)
        pcall(cb, v)
    end

    function sl:SetValue(v) apply(v) end
    apply(val)

    local dragging = false
    track.InputBegan:Connect(function(inp)
        if not isClick(inp) then return end
        dragging = true
        local tw = track.AbsoluteSize.X
        local tx = track.AbsolutePosition.X
        apply(min + ((Mouse.X - tx)/tw)*(max-min))
    end)
    giveSignal(UserInputService.InputChanged:Connect(function(inp)
        if not dragging or not isHover(inp) then return end
        local tw = track.AbsoluteSize.X
        local tx = track.AbsolutePosition.X
        apply(min + math.clamp((Mouse.X-tx)/tw,0,1)*(max-min))
    end))
    giveSignal(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end))

    self:_resize()
    NexLib.Options[idx] = sl
    return sl
end

-- ── AddDropdown ────────────────────────────────
function BaseGroupbox:AddDropdown(idx, info)
    info = info or {}
    local values  = info.Values or {}
    local multi   = info.Multi or false
    local cb      = info.Callback or function() end
    local text    = info.Text
    local current = multi and {} or (info.Default or (values[1] or nil))
    local isOpen  = false

    local totalH  = text and 40 or 22
    local holder  = N("Frame",{BackgroundTransparency=1, Size=UDim2.new(1,0,0,totalH), ClipsDescendants=false}, self._container)

    if text then
        N("TextLabel",{
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,16),
            Text=text, TextColor3=SCHEME.TextMuted, TextSize=13, Font=FONT,
            TextXAlignment=Enum.TextXAlignment.Left,
        }, holder)
    end

    local btn = N("TextButton",{
        AnchorPoint=Vector2.new(0,1), Position=UDim2.fromScale(0,1),
        BackgroundColor3=SCHEME.Input, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,22), Text="", AutoButtonColor=false, ZIndex=2,
    }, holder)
    corner(4, btn)
    stroke(SCHEME.Border, 1, btn)

    local dispLbl = N("TextLabel",{
        BackgroundTransparency=1, Position=UDim2.fromOffset(8,0),
        Size=UDim2.new(1,-28,1,0), TextColor3=SCHEME.Text, TextSize=13, Font=FONT,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
    }, btn)

    local arrow = N("TextLabel",{
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-6,0.5,0),
        BackgroundTransparency=1, Size=UDim2.fromOffset(16,16),
        Text="▾", TextColor3=SCHEME.TextDim, TextSize=13, Font=FONT, ZIndex=2,
    }, btn)

    -- Dropdown list
    local menuFrame = N("ScrollingFrame",{
        AnchorPoint=Vector2.new(0,0), Position=UDim2.new(0,0,1,2),
        BackgroundColor3=SCHEME.Elevated, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0), Visible=false, ZIndex=50,
        ScrollBarThickness=2, ScrollBarImageColor3=SCHEME.Accent,
        AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0),
    }, btn)
    corner(4, menuFrame)
    stroke(SCHEME.Border, 1, menuFrame)
    listLayout(menuFrame, 1)
    pad(4,4,4,4, menuFrame)

    local dd = {Value=current, Type="Dropdown", Multi=multi}

    local function getDisplay()
        if multi then
            local parts={}; for v,_ in pairs(dd.Value) do table.insert(parts,v) end
            return #parts>0 and table.concat(parts,", ") or "---"
        end
        return dd.Value and tostring(dd.Value) or "---"
    end

    local function buildMenu()
        for _,c in ipairs(menuFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, v in ipairs(values) do
            local selected = multi and dd.Value[v] or dd.Value==v
            local item = N("TextButton",{
                BackgroundColor3 = selected and SCHEME.AccentDark or SCHEME.Elevated,
                BackgroundTransparency = selected and 0 or 1,
                BorderSizePixel=0, Size=UDim2.new(1,0,0,22),
                Text="", AutoButtonColor=false, ZIndex=51,
            }, menuFrame)
            corner(3, item)
            N("TextLabel",{
                BackgroundTransparency=1, Position=UDim2.fromOffset(8,0),
                Size=UDim2.new(1,-16,1,0), Text=tostring(v),
                TextColor3 = selected and SCHEME.Text or SCHEME.TextMuted,
                TextSize=13, Font=FONT, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=51,
            }, item)
            item.MouseEnter:Connect(function()
                if not selected then tween(item,{BackgroundTransparency=0.7, BackgroundColor3=SCHEME.Hover}) end
            end)
            item.MouseLeave:Connect(function()
                if not selected then tween(item,{BackgroundTransparency=1}) end
            end)
            item.MouseButton1Click:Connect(function()
                if multi then
                    dd.Value[v] = not dd.Value[v] or nil
                else
                    dd.Value = (dd.Value==v and nil or v)
                    isOpen=false; menuFrame.Visible=false; arrow.Text="▾"
                    holder.Size = UDim2.new(1,0,0,totalH)
                end
                dispLbl.Text = getDisplay()
                buildMenu()
                pcall(cb, dd.Value)
            end)
        end
        local h = math.min(#values*23+8, 160)
        menuFrame.Size = UDim2.new(1,0,0,h)
    end

    btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        buildMenu()
        menuFrame.Visible = isOpen
        arrow.Text = isOpen and "▴" or "▾"
        holder.Size = UDim2.new(1,0,0, isOpen and totalH + menuFrame.Size.Y.Offset+4 or totalH)
    end)

    dispLbl.Text = getDisplay()

    function dd:SetValue(v)
        if multi then for k,_ in pairs(dd.Value) do dd.Value[k]=nil end; if type(v)=="table" then for _,x in ipairs(v) do dd.Value[x]=true end end
        else dd.Value=v end
        dispLbl.Text=getDisplay(); buildMenu(); pcall(cb, dd.Value)
    end
    function dd:SetValues(v) values=v; buildMenu() end

    self:_resize()
    NexLib.Options[idx] = dd
    return dd
end

-- ── AddButton ──────────────────────────────────
function BaseGroupbox:AddButton(text, callback, info)
    info = info or {}
    local btn = N("TextButton",{
        BackgroundColor3=SCHEME.Input, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,22), Text=text,
        TextColor3=SCHEME.TextMuted, TextSize=13, Font=FONT,
        AutoButtonColor=false,
    }, self._container)
    corner(4, btn)
    stroke(SCHEME.Border, 1, btn)
    if info.Risky then btn.TextColor3=SCHEME.Red end

    btn.MouseEnter:Connect(function() tween(btn,{BackgroundColor3=SCHEME.Hover, TextColor3=info.Risky and SCHEME.Red or SCHEME.Text}) end)
    btn.MouseLeave:Connect(function() tween(btn,{BackgroundColor3=SCHEME.Input, TextColor3=info.Risky and SCHEME.Red or SCHEME.TextMuted}) end)
    btn.MouseButton1Click:Connect(function() pcall(callback) end)

    local b = {Type="Button", Text=text}
    function b:SetText(t) btn.Text=t end
    function b:SetDisabled(d) btn.Active=not d; tween(btn,{TextColor3=d and SCHEME.TextDim or SCHEME.TextMuted}) end

    self:_resize()
    return b
end

-- ── AddInput ───────────────────────────────────
function BaseGroupbox:AddInput(idx, info)
    info = info or {}
    local text  = info.Text or idx
    local def   = info.Default or ""
    local ph    = info.Placeholder or ""
    local cb    = info.Callback or function() end
    local fin   = info.Finished ~= false

    local holder = N("Frame",{BackgroundTransparency=1, Size=UDim2.new(1,0,0,40)}, self._container)
    N("TextLabel",{
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,16),
        Text=text, TextColor3=SCHEME.TextMuted, TextSize=13, Font=FONT,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, holder)
    local box = N("TextBox",{
        AnchorPoint=Vector2.new(0,1), Position=UDim2.fromScale(0,1),
        BackgroundColor3=SCHEME.Input, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,22),
        Text=def, PlaceholderText=ph,
        PlaceholderColor3=SCHEME.TextDim,
        TextColor3=SCHEME.Text, TextSize=13, Font=FONT,
        TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=info.ClearTextOnFocus~=false,
    }, holder)
    corner(4, box)
    stroke(SCHEME.Border, 1, box)
    pad(8,8,0,0, box)

    box.Focused:Connect(function() tween(box:FindFirstChildOfClass("UIStroke"),{Color=SCHEME.Accent}) end)
    box.FocusLost:Connect(function(enter)
        tween(box:FindFirstChildOfClass("UIStroke"),{Color=SCHEME.Border})
        if fin and enter then pcall(cb, box.Text) end
    end)
    if not fin then
        box:GetPropertyChangedSignal("Text"):Connect(function() pcall(cb, box.Text) end)
    end

    local inp = {Value=def, Type="Input"}
    function inp:SetValue(v) box.Text=tostring(v); inp.Value=v end

    self:_resize()
    NexLib.Options[idx] = inp
    return inp
end

-- ── AddLabel ───────────────────────────────────
function BaseGroupbox:AddLabel(text, wrap)
    local lbl = N("TextLabel",{
        BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,wrap and 0 or 18),
        AutomaticSize=wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        Text=text, TextColor3=SCHEME.TextMuted,
        TextSize=13, Font=FONT,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=wrap or false,
    }, self._container)
    local l = {Type="Label"}
    function l:SetText(t) lbl.Text=t end
    function l:SetColor(c) lbl.TextColor3=c end
    self:_resize()
    return l
end

-- ── AddDivider ─────────────────────────────────
function BaseGroupbox:AddDivider(divText)
    local holder = N("Frame",{BackgroundTransparency=1, Size=UDim2.new(1,0,0,10)}, self._container)
    if divText then
        N("TextLabel",{
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
            BackgroundColor3=SCHEME.Elevated, BorderSizePixel=0,
            Size=UDim2.fromOffset(0,14), AutomaticSize=Enum.AutomaticSize.X,
            Text=" "..divText.." ", TextColor3=SCHEME.TextDim,
            TextSize=11, Font=FONT, ZIndex=2,
        }, holder)
    end
    N("Frame",{
        AnchorPoint=Vector2.new(0,0.5), Position=UDim2.fromScale(0,0.5),
        BackgroundColor3=SCHEME.Border, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,1),
    }, holder)
    self:_resize()
end

-- ══════════════════════════════════════════════
-- CREATE WINDOW
-- ══════════════════════════════════════════════
function NexLib:CreateWindow(cfg)
    cfg = cfg or {}
    local title     = cfg.Title    or "NexLib"
    local footer    = cfg.Footer   or ""
    local icon      = cfg.Icon     -- rbxassetid number or nil
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightControl
    local winW      = cfg.Width    or 720
    local winH      = cfg.Height   or 560
    local sideW     = cfg.SidebarWidth or 190

    -- Destroy old
    pcall(function()
        local old = CoreGui:FindFirstChild("NexLib_GUI")
        if old then old:Destroy() end
    end)

    -- ScreenGui
    local sg = N("ScreenGui",{
        Name="NexLib_GUI", DisplayOrder=999,
        ResetOnSpawn=false,
    })
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Modal (mouse lock while open)
    local modal = N("TextButton",{
        BackgroundTransparency=1, Modal=false,
        Size=UDim2.fromScale(0,0), Text="", ZIndex=-999,
    }, sg)

    -- Notification area
    local notifArea = N("Frame",{
        AnchorPoint=Vector2.new(1,0), BackgroundTransparency=1,
        Position=UDim2.new(1,-6,0,6), Size=UDim2.new(0,300,1,-6),
    }, sg)
    local notifList = N("UIListLayout",{
        HorizontalAlignment=Enum.HorizontalAlignment.Right,
        Padding=UDim.new(0,6),
    }, notifArea)

    -- ── Main Frame ──────────────────────────────
    local main = N("Frame",{
        Name="MainFrame", BackgroundColor3=SCHEME.Background,
        BorderSizePixel=0, Size=UDim2.fromOffset(winW, winH),
        Position=UDim2.new(0.5,-winW/2,0.5,-winH/2),
        Visible=false, Active=true,
        ClipsDescendants=false,
    }, sg)
    corner(8, main)
    stroke(SCHEME.Border, 1, main)

    -- Make draggable
    do
        local sp, fp, dragging, changed
        local topDrag = N("TextButton",{
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,42),
            Text="", AutoButtonColor=false, ZIndex=10,
        }, main)
        topDrag.InputBegan:Connect(function(inp)
            if not isClick(inp) then return end
            sp=inp.Position; fp=main.Position; dragging=true
            changed=inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then
                    dragging=false; if changed then changed:Disconnect() end
                end
            end)
        end)
        giveSignal(UserInputService.InputChanged:Connect(function(inp)
            if dragging and isHover(inp) then
                local d=inp.Position-sp
                main.Position=UDim2.new(fp.X.Scale, fp.X.Offset+d.X, fp.Y.Scale, fp.Y.Offset+d.Y)
            end
        end))
    end

    -- ── Header bar ──────────────────────────────
    local header = N("Frame",{
        BackgroundColor3=SCHEME.Surface, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,42),
    }, main)
    corner(8, header)
    -- Fix bottom corners
    N("Frame",{BackgroundColor3=SCHEME.Surface,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,8), Position=UDim2.new(0,0,1,-8)}, header)

    -- Thin accent line at very top
    N("Frame",{BackgroundColor3=SCHEME.Accent, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,2), CornerRadius=UDim.new(0,0)}, header)

    -- Icon
    local iconX = 10
    if icon then
        N("ImageLabel",{
            Size=UDim2.fromOffset(24,24),
            Position=UDim2.new(0,10,0.5,-12),
            BackgroundTransparency=1,
            Image="rbxassetid://"..tostring(icon),
        }, header)
        iconX = 40
    end

    -- Title
    N("TextLabel",{
        Position=UDim2.new(0,iconX,0,0),
        Size=UDim2.new(0,sideW-iconX-8,1,0),
        BackgroundTransparency=1,
        Text=title, TextColor3=SCHEME.Text,
        TextSize=15, Font=Font.fromEnum(Enum.Font.GothamBold),
        TextXAlignment=Enum.TextXAlignment.Left,
    }, header)

    -- Search bar
    local searchBox = N("TextBox",{
        Position=UDim2.new(0,sideW+8,0.5,-13),
        Size=UDim2.new(1,-sideW-70,0,26),
        BackgroundColor3=SCHEME.Input, BorderSizePixel=0,
        PlaceholderText="  Buscar...",
        PlaceholderColor3=SCHEME.TextDim,
        Text="", TextColor3=SCHEME.Text,
        TextSize=13, Font=FONT, ClearTextOnFocus=false,
    }, header)
    corner(5, searchBox)
    stroke(SCHEME.Border, 1, searchBox)

    -- Close btn
    local closeBtn = N("TextButton",{
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0),
        Size=UDim2.fromOffset(22,22), BackgroundColor3=SCHEME.Input,
        Text="✕", TextColor3=SCHEME.TextMuted, TextSize=12, Font=FONT,
        AutoButtonColor=false, BorderSizePixel=0,
    }, header)
    corner(5, closeBtn)
    closeBtn.MouseEnter:Connect(function() tween(closeBtn,{BackgroundColor3=SCHEME.Red, TextColor3=SCHEME.Text}) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn,{BackgroundColor3=SCHEME.Input, TextColor3=SCHEME.TextMuted}) end)
    closeBtn.MouseButton1Click:Connect(function()
        NexLib.Toggled=false; main.Visible=false; modal.Modal=false
    end)

    -- ── Sidebar ─────────────────────────────────
    local sidebar = N("Frame",{
        Position=UDim2.new(0,0,0,42), Size=UDim2.new(0,sideW,1,-62),
        BackgroundColor3=SCHEME.Surface, BorderSizePixel=0,
    }, main)
    -- Right edge fix
    N("Frame",{AnchorPoint=Vector2.new(1,0), Position=UDim2.fromScale(1,0),
        Size=UDim2.new(0,8,1,0), BackgroundColor3=SCHEME.Surface, BorderSizePixel=0}, sidebar)
    -- Divider line
    N("Frame",{AnchorPoint=Vector2.new(1,0), Position=UDim2.fromScale(1,0),
        Size=UDim2.new(0,1,1,0), BackgroundColor3=SCHEME.Border, BorderSizePixel=0}, sidebar)

    local sideScroll = N("ScrollingFrame",{
        Size=UDim2.new(1,0,1,-28), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=0,
        AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0),
    }, sidebar)
    listLayout(sideScroll, 2)
    pad(6,6,6,4, sideScroll)

    -- Watermark
    local watermark = N("TextLabel",{
        AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,8,1,-4),
        Size=UDim2.new(1,-16,0,16), BackgroundTransparency=1,
        Text=footer, TextColor3=SCHEME.TextDim,
        TextSize=11, Font=FONT, TextXAlignment=Enum.TextXAlignment.Left,
    }, sidebar)

    -- ── Content area ────────────────────────────
    local content = N("Frame",{
        Position=UDim2.new(0,sideW+1,0,42),
        Size=UDim2.new(1,-sideW-1,1,-62),
        BackgroundColor3=SCHEME.Background, BorderSizePixel=0,
        ClipsDescendants=true,
    }, main)

    -- ── Footer bar ──────────────────────────────
    local footerBar = N("Frame",{
        AnchorPoint=Vector2.new(0,1), Position=UDim2.fromScale(0,1),
        Size=UDim2.new(1,0,0,20), BackgroundColor3=SCHEME.Surface,
        BorderSizePixel=0,
    }, main)
    corner(8, footerBar)
    N("Frame",{Size=UDim2.new(1,0,0,8), BackgroundColor3=SCHEME.Surface, BorderSizePixel=0}, footerBar)
    N("Frame",{Size=UDim2.new(1,0,0,1), BackgroundColor3=SCHEME.Border, BorderSizePixel=0}, footerBar)
    local footerLbl = N("TextLabel",{
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text=footer, TextColor3=SCHEME.TextDim,
        TextSize=11, Font=FONT,
    }, footerBar)

    -- ══════════════════════════════════════════
    -- WINDOW API
    -- ══════════════════════════════════════════
    local Win = {}
    local activeTab = nil
    local tabList   = {}

    function Win:SetWatermark(text)
        watermark.Text = text
        footerLbl.Text = text
    end

    function Win:SetFooter(text) footerLbl.Text=text end

    -- ── AddTab ──────────────────────────────────
    function Win:AddTab(name, iconName)
        -- Sidebar button
        local btn = N("TextButton",{
            Size=UDim2.new(1,0,0,34), BackgroundColor3=SCHEME.Surface,
            BorderSizePixel=0, Text="", AutoButtonColor=false,
        }, sideScroll)
        corner(5, btn)

        -- Left accent bar (indicator)
        local bar = N("Frame",{
            Size=UDim2.new(0,2,0.6,0), Position=UDim2.new(0,0,0.2,0),
            BackgroundColor3=SCHEME.AccentDark, BorderSizePixel=0,
        }, btn)

        N("TextLabel",{
            Position=UDim2.new(0,14,0,0), Size=UDim2.new(1,-20,1,0),
            BackgroundTransparency=1, Text=name, TextColor3=SCHEME.TextMuted,
            TextSize=13, Font=FONT, TextXAlignment=Enum.TextXAlignment.Left,
        }, btn)

        -- Tab scroll content
        local tabFrame = N("ScrollingFrame",{
            Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
            BorderSizePixel=0, ScrollBarThickness=3,
            ScrollBarImageColor3=SCHEME.Accent,
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            CanvasSize=UDim2.new(0,0,0,0), Visible=false,
        }, content)

        -- Two-column layout
        local cols = N("Frame",{
            Size=UDim2.new(1,-12,0,0), Position=UDim2.new(0,6,0,6),
            AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1,
        }, tabFrame)

        local leftCol = N("Frame",{
            Size=UDim2.new(0.5,-4,0,0), BackgroundTransparency=1,
            AutomaticSize=Enum.AutomaticSize.Y,
        }, cols)
        listLayout(leftCol, 6)

        local rightCol = N("Frame",{
            AnchorPoint=Vector2.new(1,0), Position=UDim2.fromScale(1,0),
            Size=UDim2.new(0.5,-4,0,0), BackgroundTransparency=1,
            AutomaticSize=Enum.AutomaticSize.Y,
        }, cols)
        listLayout(rightCol, 6)

        local Tab = {_left=leftCol, _right=rightCol, _frame=tabFrame, _btn=btn, _bar=bar}
        setmetatable(Tab, {__index=function(t,k) return BaseGroupbox[k] end})

        local function select()
            -- Deselect all
            for _, t in ipairs(tabList) do
                t._frame.Visible=false
                tween(t._btn, {BackgroundColor3=SCHEME.Surface})
                tween(t._btn:FindFirstChildOfClass("TextLabel"), {TextColor3=SCHEME.TextMuted})
                tween(t._bar, {BackgroundColor3=SCHEME.AccentDark, Size=UDim2.new(0,2,0.5,0), Position=UDim2.new(0,0,0.25,0)})
            end
            -- Select this
            tabFrame.Visible=true
            tween(btn, {BackgroundColor3=SCHEME.Elevated})
            tween(btn:FindFirstChildOfClass("TextLabel"), {TextColor3=SCHEME.Text})
            tween(bar, {BackgroundColor3=SCHEME.Accent, Size=UDim2.new(0,3,0.7,0), Position=UDim2.new(0,0,0.15,0)})
            activeTab = Tab
        end

        btn.MouseButton1Click:Connect(select)
        btn.MouseEnter:Connect(function()
            if activeTab~=Tab then tween(btn,{BackgroundColor3=SCHEME.Hover}) end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab~=Tab then tween(btn,{BackgroundColor3=SCHEME.Surface}) end
        end)

        -- Groupbox factory
        function Tab:AddLeftGroupbox(gbName, iconN)
            return self:_makeGroupbox(gbName, leftCol, iconN)
        end
        function Tab:AddRightGroupbox(gbName, iconN)
            return self:_makeGroupbox(gbName, rightCol, iconN)
        end
        function Tab:_makeGroupbox(gbName, col, iconN)
            local boxHolder = N("Frame",{
                Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1,
            }, col)

            local box = N("Frame",{
                Size=UDim2.new(1,0,0,43), BackgroundColor3=SCHEME.Elevated,
                AutomaticSize=Enum.AutomaticSize.Y, BorderSizePixel=0,
            }, boxHolder)
            corner(6, box)
            stroke(SCHEME.Border, 1, box)

            -- Header
            local gbHeader = N("Frame",{
                Size=UDim2.new(1,0,0,32), BackgroundColor3=SCHEME.Surface,
                BorderSizePixel=0,
            }, box)
            corner(6, gbHeader)
            N("Frame",{Size=UDim2.new(1,0,0,8), Position=UDim2.new(0,0,1,-8),
                BackgroundColor3=SCHEME.Surface, BorderSizePixel=0}, gbHeader)
            N("Frame",{AnchorPoint=Vector2.new(0,1), Position=UDim2.fromScale(0,1),
                Size=UDim2.new(1,0,0,1), BackgroundColor3=SCHEME.Border, BorderSizePixel=0}, gbHeader)

            -- Accent dot
            N("Frame",{
                AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,10,0.5,0),
                Size=UDim2.fromOffset(5,5), BackgroundColor3=SCHEME.Accent,
                BorderSizePixel=0,
            }, gbHeader)
            corner(3, gbHeader:FindFirstChildOfClass("Frame"))

            N("TextLabel",{
                Position=UDim2.new(0,22,0,0), Size=UDim2.new(1,-28,1,0),
                BackgroundTransparency=1, Text=gbName:upper(),
                TextColor3=SCHEME.Text, TextSize=11,
                Font=Font.fromEnum(Enum.Font.GothamBold),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, gbHeader)

            -- Content
            local gbContent = N("Frame",{
                Position=UDim2.new(0,0,0,32), Size=UDim2.new(1,0,0,0),
                AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1,
            }, box)
            pad(8,8,6,8, gbContent)
            local gbList = listLayout(gbContent, 6)

            local gb = {
                _holder=box, _container=gbContent, _list=gbList,
                Type="Groupbox",
            }
            setmetatable(gb, BaseGroupbox)

            gbList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                gb:_resize()
            end)

            return gb
        end

        table.insert(tabList, Tab)
        if not activeTab then select() end
        return Tab
    end

    -- ── Notify ──────────────────────────────────
    function Win:Notify(info)
        if type(info)=="string" then info={Description=info, Time=3} end
        local time  = info.Time or 3
        local title = info.Title
        local desc  = info.Description or ""

        local notifFrame = N("Frame",{
            BackgroundColor3=SCHEME.Elevated, BorderSizePixel=0,
            Size=UDim2.fromOffset(260,0), AutomaticSize=Enum.AutomaticSize.Y,
            Position=UDim2.new(1,8,0,0), AnchorPoint=Vector2.new(0,0),
        }, notifArea)
        corner(6, notifFrame)
        stroke(SCHEME.Accent, 1, notifFrame)

        local inner = N("Frame",{BackgroundTransparency=1, Size=UDim2.new(1,0,0,0),
            AutomaticSize=Enum.AutomaticSize.Y}, notifFrame)
        pad(10,10,8,8, inner)
        listLayout(inner, 4)

        if title then
            N("TextLabel",{BackgroundTransparency=1, Size=UDim2.new(1,0,0,16),
                Text=title, TextColor3=SCHEME.Text, TextSize=13,
                Font=Font.fromEnum(Enum.Font.GothamBold),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, inner)
        end
        N("TextLabel",{BackgroundTransparency=1, Size=UDim2.new(1,0,0,0),
            AutomaticSize=Enum.AutomaticSize.Y,
            Text=desc, TextColor3=SCHEME.TextMuted, TextSize=12, Font=FONT,
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        }, inner)

        -- Timer bar
        local timerBg = N("Frame",{Size=UDim2.new(1,0,0,2), BackgroundColor3=SCHEME.Input, BorderSizePixel=0}, notifFrame)
        local timerFill = N("Frame",{Size=UDim2.fromScale(1,1), BackgroundColor3=SCHEME.Accent, BorderSizePixel=0}, timerBg)

        -- Animate in
        tween(notifFrame, {Position=UDim2.new(0,0,0,0)}, TWN)
        tween(timerFill, {Size=UDim2.fromScale(0,1)}, TweenInfo.new(time, Enum.EasingStyle.Linear))

        task.delay(time, function()
            tween(notifFrame, {Position=UDim2.new(1,8,0,0)}, TWN)
            task.delay(0.3, function() notifFrame:Destroy() end)
        end)

        return notifFrame
    end

    -- ── Toggle visibility ───────────────────────
    function Win:Toggle(v)
        if v==nil then NexLib.Toggled=not NexLib.Toggled
        else NexLib.Toggled=v end
        main.Visible=NexLib.Toggled
        modal.Modal=NexLib.Toggled
    end

    -- Keybind
    giveSignal(UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe or NexLib.Unloaded then return end
        if inp.KeyCode==toggleKey then Win:Toggle() end
    end))

    -- Search
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchBox.Text:lower()
        if activeTab then
            for _, col in ipairs({activeTab._left, activeTab._right}) do
                for _, box in ipairs(col:GetChildren()) do
                    if box:IsA("Frame") then
                        local gbContent = box:FindFirstChild("Frame") -- content
                        if gbContent then
                            for _, elem in ipairs(gbContent:GetChildren()) do
                                if elem:IsA("TextButton") or elem:IsA("Frame") then
                                    local lbl = elem:FindFirstChildOfClass("TextLabel")
                                    if lbl then
                                        elem.Visible = q=="" or lbl.Text:lower():find(q,1,true)~=nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Auto show
    task.defer(function() Win:Toggle(true) end)

    return Win
end

-- ══════════════════════════════════════════════
-- UNLOAD
-- ══════════════════════════════════════════════
function NexLib:Unload()
    NexLib.Unloaded = true
    for _, conn in ipairs(NexLib.Signals) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    local sg = CoreGui:FindFirstChild("NexLib_GUI")
    if sg then sg:Destroy() end
    getgenv().NexLib = nil
end

getgenv().NexLib = NexLib
return NexLib
