--[[
    Vortex - MM2 Christmas Edition (UI 3.0)
    Christmas themes, snow, twinkling lights, candy-cane border, click sounds,
    full config system (auto-save, named profiles, share codes, live load),
    role ESP, auto grab gun, SHERIFF AUTO SHOOT + HUD, movement, sky/time, rebindable keys.
    Default keys: RightShift = UI, K = ESP, G = grab gun, T = shoot murderer now,
                  F = fly, N = noclip, X = speed
]]
local HUB_NAME = "Vortex"

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

local function C(r, g, b) return Color3.fromRGB(r, g, b) end

------------------------------------------------------------------
-- CONFIG (auto-saved to your executor workspace)
------------------------------------------------------------------
local CONFIG_FILE = "Vortex_MM2_config.json"
local PROFILE_PREFIX = "Vortex_MM2_cfg_"
local Config = { Binds = {}, Opts = {}, Toggles = {}, Sliders = {} }

local function saveConfig()
    if writefile then pcall(writefile, CONFIG_FILE, HttpService:JSONEncode(Config)) end
end
local saveQueued = false
local function saveSoon()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.6, function() saveQueued = false; saveConfig() end)
end

if isfile and readfile and isfile(CONFIG_FILE) then
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if ok and type(data) == "table" then for k, v in pairs(data) do Config[k] = v end end
end
Config.Binds = Config.Binds or {}
Config.Opts = Config.Opts or {}
Config.Toggles = Config.Toggles or {}
Config.Sliders = Config.Sliders or {}

-- registry: every saved element registers a setter so a loaded config applies live
local registry = { toggles = {}, sliders = {}, cycles = {}, binds = {} }

-- base64 (for share codes, works on any executor)
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64enc(data)
    return ((data:gsub(".", function(x)
        local r, b = "", x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then return "" end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0) end
        return B64:sub(c + 1, c + 1)
    end) .. ({ "", "==", "=" })[#data % 3 + 1])
end
local function b64dec(data)
    data = data:gsub("[^" .. B64 .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (B64:find(x, 1, true) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

------------------------------------------------------------------
-- THEMES
------------------------------------------------------------------
local Themes = {
    Christmas = { Background = C(14, 24, 20), Topbar = C(20, 34, 28), Element = C(28, 46, 38), Hover = C(40, 66, 54), Stroke = C(86, 52, 56), Text = C(255, 245, 240), SubText = C(170, 200, 185) },
    Frostbite = { Background = C(12, 20, 34), Topbar = C(18, 30, 50), Element = C(26, 42, 66), Hover = C(38, 60, 92), Stroke = C(90, 130, 170), Text = C(240, 248, 255), SubText = C(150, 180, 210) },
    Candy     = { Background = C(26, 12, 16), Topbar = C(38, 16, 22), Element = C(54, 22, 30), Hover = C(78, 30, 42), Stroke = C(120, 50, 60), Text = C(255, 240, 242), SubText = C(200, 150, 160) },
    Gingerbread = { Background = C(28, 18, 12), Topbar = C(40, 26, 17), Element = C(56, 37, 24), Hover = C(78, 52, 33), Stroke = C(110, 74, 46), Text = C(255, 242, 228), SubText = C(196, 160, 128) },
    Midnight = { Background = C(16, 16, 24), Topbar = C(22, 22, 32), Element = C(30, 30, 42), Hover = C(42, 42, 58), Stroke = C(52, 52, 72), Text = C(240, 240, 248), SubText = C(140, 140, 160) },
    Obsidian = { Background = C(10, 10, 12), Topbar = C(16, 16, 18), Element = C(24, 24, 28), Hover = C(36, 36, 42), Stroke = C(44, 44, 50), Text = C(240, 240, 244), SubText = C(135, 135, 145) },
    Ocean    = { Background = C(11, 19, 30), Topbar = C(16, 27, 42), Element = C(22, 38, 56), Hover = C(32, 54, 78), Stroke = C(42, 72, 102), Text = C(236, 244, 252), SubText = C(130, 160, 188) },
    Crimson  = { Background = C(20, 12, 14), Topbar = C(28, 16, 19), Element = C(40, 24, 27), Hover = C(58, 34, 38), Stroke = C(78, 44, 50), Text = C(250, 238, 240), SubText = C(170, 135, 140) },
    Forest   = { Background = C(11, 20, 15), Topbar = C(16, 28, 21), Element = C(24, 40, 31), Hover = C(34, 58, 45), Stroke = C(46, 78, 60), Text = C(236, 250, 242), SubText = C(130, 170, 148) },
}
local ThemeNames = { "Christmas", "Frostbite", "Candy", "Gingerbread", "Midnight", "Obsidian", "Ocean", "Crimson", "Forest" }
local Accents = {
    ["Holly Red"] = C(214, 40, 57), Pine = C(34, 160, 90), Gold = C(255, 200, 60), Ice = C(140, 210, 255),
    Blurple = C(88, 101, 242), Emerald = C(46, 204, 113), Rose = C(235, 87, 125), Amber = C(241, 168, 40),
    Cyan = C(0, 190, 220), Violet = C(155, 89, 255), Orange = C(255, 128, 48),
}
local AccentNames = { "Holly Red", "Pine", "Gold", "Ice", "Blurple", "Emerald", "Rose", "Amber", "Cyan", "Violet", "Orange" }

local Theme = {}
for k, v in pairs(Themes[Config.Opts.theme] or Themes.Christmas) do Theme[k] = v end
Theme.Accent = Accents[Config.Opts.accent] or Accents["Holly Red"]

local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    return inst
end
local function corner(r) return create("UICorner", { CornerRadius = UDim.new(0, r or 8) }) end
local function tween(obj, props, t, style)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

-- theme registry: objects register a property + theme key and get repainted on theme/accent change
local bound, refreshers, gradients = {}, {}, {}
local function bind(obj, prop, key) obj[prop] = Theme[key]; table.insert(bound, { obj, prop, key }); return obj end
local function gradFor(c) return ColorSequence.new(c, c:Lerp(Color3.new(1, 1, 1), 0.3)) end
local function accentGradient(parent, rotation)
    local g = create("UIGradient", { Color = gradFor(Theme.Accent), Rotation = rotation or 0, Parent = parent })
    table.insert(gradients, g)
    return g
end
local function applyTheme()
    for _, b in ipairs(bound) do pcall(function() b[1][b[2]] = Theme[b[3]] end) end
    for _, g in ipairs(gradients) do pcall(function() g.Color = gradFor(Theme.Accent) end) end
    for _, r in ipairs(refreshers) do pcall(r) end
end
local function setTheme(name)
    local t = Themes[name]
    if not t then return end
    for k, v in pairs(t) do Theme[k] = v end
    applyTheme()
end
local function setAccent(color) Theme.Accent = color; applyTheme() end

-- festive switches (toggled from Settings)
local Fest = { Snow = true, Lights = true, Border = true, BindNotify = true }

local function xmasText()
    local now = os.date("*t")
    if now.month == 12 and now.day == 25 then return "It's Christmas Day! Merry Christmas!" end
    local y = now.year
    local target = os.time({ year = y, month = 12, day = 25, hour = 0 })
    if os.time() > target + 86400 then target = os.time({ year = y + 1, month = 12, day = 25, hour = 0 }) end
    local days = math.ceil((target - os.time()) / 86400)
    return days .. (days == 1 and " day" or " days") .. " until Christmas"
end

------------------------------------------------------------------
-- ROOT GUI
------------------------------------------------------------------
local host = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function() if host:FindFirstChild("Vortex") then host.Vortex:Destroy() end end)
local gui = create("ScreenGui", { Name = "Vortex", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = host

------------------------------------------------------------------
-- SOUNDS (click / hover). Swap IDs here if one does not play for you.
------------------------------------------------------------------
local SoundCfg = { On = true, Hover = false, Vol = 0.6 }
local SOUND_IDS = { click = "rbxassetid://6895079853", hover = "rbxassetid://6895079733" }
local function playSound(kind, pitch, vol)
    if not SoundCfg.On then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = SOUND_IDS[kind] or SOUND_IDS.click
        s.Volume = (vol or 1) * SoundCfg.Vol
        s.PlaybackSpeed = pitch or 1
        s.Parent = gui
        s:Play()
        Debris:AddItem(s, 3)
    end)
end
local function hookButton(b)
    if not b:IsA("TextButton") then return end
    b.MouseButton1Click:Connect(function()
        if not b:GetAttribute("NoSound") then playSound("click", 0.95 + math.random() * 0.15) end
    end)
    b.MouseEnter:Connect(function()
        if SoundCfg.Hover and not b:GetAttribute("NoSound") then playSound("hover", 1, 0.35) end
    end)
end
for _, d in ipairs(gui:GetDescendants()) do hookButton(d) end
connect(gui.DescendantAdded, hookButton)

------------------------------------------------------------------
-- NOTIFICATIONS (slide in, progress bar, kinds: info/success/error/warn)
------------------------------------------------------------------
local notify
do
    local holder = create("Frame", { Size = UDim2.new(0, 300, 1, -20), Position = UDim2.new(1, -312, 0, 10),
        BackgroundTransparency = 1, Parent = gui }, {
        create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    local KIND = { success = C(46, 204, 113), error = C(235, 87, 87), warn = C(241, 168, 40) }
    notify = function(title, text, duration, kind)
        duration = duration or 3
        local color = KIND[kind or ""] or Theme.Accent
        if kind == "success" then playSound("click", 1.3, 0.8) elseif kind == "error" or kind == "warn" then playSound("click", 0.75, 0.8) end
        local slot = create("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, Parent = holder })
        local card = create("Frame", { Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(330, 0),
            BackgroundColor3 = Theme.Topbar, BorderSizePixel = 0, ClipsDescendants = true, Parent = slot }, {
            corner(10), create("UIStroke", { Color = Theme.Stroke, Thickness = 1 }),
        })
        create("Frame", { Size = UDim2.new(0, 3, 1, -16), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = color,
            BorderSizePixel = 0, Parent = card }, { corner(2) })
        create("TextLabel", { Size = UDim2.new(1, -30, 0, 20), Position = UDim2.fromOffset(20, 9), BackgroundTransparency = 1,
            Text = title, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
        create("TextLabel", { Size = UDim2.new(1, -30, 0, 22), Position = UDim2.fromOffset(20, 29), BackgroundTransparency = 1,
            Text = text, TextColor3 = Theme.SubText, Font = Enum.Font.Gotham, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
        local bar = create("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = color,
            BorderSizePixel = 0, Parent = card })
        tween(card, { Position = UDim2.fromOffset(0, 0) }, 0.3, Enum.EasingStyle.Back)
        TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
        task.delay(duration, function()
            if card and card.Parent then
                tween(card, { Position = UDim2.fromOffset(330, 0) }, 0.25)
                task.wait(0.3)
                slot:Destroy()
            end
        end)
    end
end

------------------------------------------------------------------
-- WINDOW
------------------------------------------------------------------
local W, H = 660, 440
local root = create("Frame", { Name = "Root", Size = UDim2.fromOffset(W, H), Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2),
    BackgroundTransparency = 1, Parent = gui })
local shadow = create("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://6014261993", ImageColor3 = Color3.new(0, 0, 0),
    ImageTransparency = 0.4, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
    Size = UDim2.new(1, 50, 1, 50), Position = UDim2.fromOffset(-25, -18), ZIndex = 0, Parent = root })
local main = create("CanvasGroup", { Name = "Main", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 1, Parent = root },
    { corner(12), create("UIStroke", { Thickness = 1, Name = "S" }) })
bind(main, "BackgroundColor3", "Background")

local content, tabList, search, setStatus, setUI, toggleUI
local uiOpen = true
local bubble

do
    -- top bar
    local topbar = create("Frame", { Size = UDim2.new(1, 0, 0, 46), BorderSizePixel = 0, Parent = main })
    bind(topbar, "BackgroundColor3", "Topbar")
    local tline = create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BorderSizePixel = 0, Parent = topbar })
    bind(tline, "BackgroundColor3", "Stroke")

    local logo = create("Frame", { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(14, 11), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, Parent = topbar }, { corner(8) })
    accentGradient(logo, 45)
    create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "\u{1F384}", TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBlack, TextSize = 17, Parent = logo })
    local t1 = create("TextLabel", { Size = UDim2.fromOffset(160, 20), Position = UDim2.fromOffset(50, 7), BackgroundTransparency = 1,
        Text = HUB_NAME, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = topbar })
    bind(t1, "TextColor3", "Text")
    local t2 = create("TextLabel", { Size = UDim2.fromOffset(160, 14), Position = UDim2.fromOffset(50, 26), BackgroundTransparency = 1,
        Text = "MM2 Christmas Edition", Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = topbar })
    bind(t2, "TextColor3", "SubText")

    search = create("TextBox", { Size = UDim2.fromOffset(170, 28), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -84, 0, 11),
        PlaceholderText = "Search features...", PlaceholderColor3 = C(110, 130, 120), Text = "", Font = Enum.Font.Gotham, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, BorderSizePixel = 0, Parent = topbar },
        { corner(8), create("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
    bind(search, "BackgroundColor3", "Element")
    bind(search, "TextColor3", "Text")

    local function topBtn(text, x, hoverColor)
        local b = create("TextButton", { Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 11),
            Text = text, Font = Enum.Font.GothamBold, TextSize = 15, AutoButtonColor = false, BorderSizePixel = 0, Parent = topbar }, { corner(8) })
        bind(b, "BackgroundColor3", "Element")
        bind(b, "TextColor3", "Text")
        b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = hoverColor or Theme.Hover }, 0.12) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.Element }, 0.12) end)
        return b
    end
    topBtn("-", -46).MouseButton1Click:Connect(function() setUI(false) end)
    topBtn("X", -12, C(200, 70, 70)).MouseButton1Click:Connect(function()
        for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
    end)

    -- sidebar
    local sidebar = create("Frame", { Size = UDim2.new(0, 170, 1, -70), Position = UDim2.fromOffset(0, 46), BorderSizePixel = 0, Parent = main })
    bind(sidebar, "BackgroundColor3", "Topbar")
    local sline = create("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BorderSizePixel = 0, Parent = sidebar })
    bind(sline, "BackgroundColor3", "Stroke")
    tabList = create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -64), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = sidebar },
        { create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 10) }),
          create("UIListLayout", { Padding = UDim.new(0, 4) }) })

    local profile = create("Frame", { Size = UDim2.new(1, -18, 0, 48), Position = UDim2.new(0, 8, 1, -56), BorderSizePixel = 0, Parent = sidebar }, { corner(10) })
    bind(profile, "BackgroundColor3", "Element")
    create("ImageLabel", { Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(7, 7), BackgroundColor3 = C(40, 40, 50),
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150", Parent = profile }, { corner(17) })
    local pn = create("TextLabel", { Size = UDim2.new(1, -52, 0, 18), Position = UDim2.fromOffset(48, 7), BackgroundTransparency = 1,
        Text = LocalPlayer.DisplayName, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = profile })
    bind(pn, "TextColor3", "Text")
    local ps = create("TextLabel", { Size = UDim2.new(1, -52, 0, 14), Position = UDim2.fromOffset(48, 25), BackgroundTransparency = 1,
        Text = "@" .. LocalPlayer.Name, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = profile })
    bind(ps, "TextColor3", "SubText")

    -- content + status bar
    content = create("Frame", { Size = UDim2.new(1, -170, 1, -70), Position = UDim2.fromOffset(170, 46), BackgroundTransparency = 1,
        ClipsDescendants = true, Parent = main })
    local status = create("Frame", { Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -24), BorderSizePixel = 0, Parent = main })
    bind(status, "BackgroundColor3", "Topbar")
    local stline = create("Frame", { Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = status })
    bind(stline, "BackgroundColor3", "Stroke")
    local sl = create("TextLabel", { Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = "",
        Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = status })
    bind(sl, "TextColor3", "SubText")
    local sr = create("TextLabel", { Size = UDim2.new(0.4, -30, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1, Text = "",
        Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = status })
    bind(sr, "TextColor3", "SubText")
    setStatus = function(l, r) sl.Text = l or sl.Text; sr.Text = r or sr.Text end

    -- drag (title bar)
    do
        local dragging, ds, sp
        connect(topbar.InputBegan, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging, ds, sp = true, i.Position, root.Position
            end
        end)
        connect(UIS.InputChanged, function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                root.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        connect(UIS.InputEnded, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end

    -- resize grip (bottom-right)
    do
        local grip = create("TextButton", { Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1, Text = "", ZIndex = 8, Parent = main })
        grip:SetAttribute("NoSound", true)
        for _, p in ipairs({ { 13, 13 }, { 7, 13 }, { 13, 7 } }) do
            local d = create("Frame", { Size = UDim2.fromOffset(3, 3), Position = UDim2.fromOffset(p[1], p[2]), BorderSizePixel = 0, ZIndex = 8, Parent = grip }, { corner(2) })
            bind(d, "BackgroundColor3", "SubText")
        end
        local resizing, rs, rw, rh
        connect(grip.InputBegan, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                resizing, rs, rw, rh = true, i.Position, W, H
            end
        end)
        connect(UIS.InputChanged, function(i)
            if resizing and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - rs
                W = math.clamp(rw + d.X, 580, 980)
                H = math.clamp(rh + d.Y, 380, 680)
                root.Size = UDim2.fromOffset(W, H)
            end
        end)
        connect(UIS.InputEnded, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then resizing = false end
        end)
    end

    -- minimize bubble
    bubble = create("TextButton", { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(0, 18, 0.5, -24), BackgroundColor3 = Color3.new(1, 1, 1),
        Text = "\u{1F384}", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 22, AutoButtonColor = false, Visible = false, Parent = gui },
        { corner(24), create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.5, Thickness = 2 }) })
    accentGradient(bubble, 45)
    bubble.MouseButton1Click:Connect(function() setUI(true) end)
    bubble.MouseEnter:Connect(function() tween(bubble, { Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0, 15, 0.5, -27) }, 0.12) end)
    bubble.MouseLeave:Connect(function() tween(bubble, { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(0, 18, 0.5, -24) }, 0.12) end)

    setUI = function(open)
        if open == uiOpen then return end
        uiOpen = open
        local p = root.Position
        if open then
            bubble.Visible = false
            root.Visible = true
            main.GroupTransparency = 1
            shadow.ImageTransparency = 1
            root.Position = p + UDim2.fromOffset(0, 14)
            tween(main, { GroupTransparency = 0 }, 0.22)
            tween(shadow, { ImageTransparency = 0.4 }, 0.22)
            tween(root, { Position = p }, 0.22)
        else
            tween(main, { GroupTransparency = 1 }, 0.16)
            tween(shadow, { ImageTransparency = 1 }, 0.16)
            tween(root, { Position = p + UDim2.fromOffset(0, 14) }, 0.16)
            task.delay(0.17, function()
                if not uiOpen then root.Visible = false; root.Position = p; bubble.Visible = true end
            end)
        end
    end
    toggleUI = function() setUI(not uiOpen) end
end

------------------------------------------------------------------
-- CHRISTMAS DECOR: candy-cane border, snow, twinkling lights
------------------------------------------------------------------
do
    local RED, WHITE = C(214, 40, 57), C(255, 255, 255)

    -- candy-cane border (animated stripes)
    local keys, n = {}, 10
    for i = 0, n - 1 do
        local col = (i % 2 == 0) and RED or WHITE
        keys[#keys + 1] = ColorSequenceKeypoint.new(i == 0 and 0 or (i / n + 0.001), col)
        keys[#keys + 1] = ColorSequenceKeypoint.new(i == n - 1 and 1 or ((i + 1) / n), col)
    end
    local borderGrad = create("UIGradient", { Color = ColorSequence.new(keys), Parent = main.S })
    local function paintBorder()
        borderGrad.Enabled = Fest.Border
        main.S.Thickness = Fest.Border and 2 or 1
        main.S.Color = Fest.Border and WHITE or Theme.Stroke
    end
    table.insert(refreshers, paintBorder)
    paintBorder()

    -- snow inside the window
    local snowLayer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4, Active = false, Parent = main })
    local flakes = {}
    for i = 1, 40 do
        local s = math.random(3, 7)
        local f = create("Frame", { Size = UDim2.fromOffset(s, s), BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = math.random(30, 70) / 100, BorderSizePixel = 0, ZIndex = 4, Parent = snowLayer }, { corner(s) })
        flakes[i] = { f = f, x = math.random(), y = math.random(), v = math.random(8, 22) / 100, sway = math.random() * 6, sp = math.random(5, 15) / 10 }
    end

    -- garland lights along the top edge
    local lightColors = { C(255, 70, 70), C(80, 230, 120), C(255, 215, 90), C(120, 190, 255) }
    local garland = create("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, ZIndex = 7, Parent = main })
    local bulbs, N = {}, 34
    for i = 1, N do
        local frac = (i - 0.5) / N
        local sag = math.abs(math.sin(frac * math.pi * 5)) * 4
        bulbs[i] = create("Frame", { Size = UDim2.fromOffset(5, 6), Position = UDim2.new(frac, -2, 0, math.floor(sag)),
            BackgroundColor3 = lightColors[(i - 1) % 4 + 1], BorderSizePixel = 0, ZIndex = 7, Parent = garland }, { corner(3) })
    end

    connect(RunService.RenderStepped, function(dt)
        local t = os.clock()
        local showSnow = Fest.Snow and uiOpen
        snowLayer.Visible = showSnow
        if showSnow then
            for _, s in ipairs(flakes) do
                s.y += s.v * dt
                if s.y > 1.02 then s.y = -0.02; s.x = math.random() end
                s.f.Position = UDim2.new(s.x, math.sin(t * s.sp + s.sway) * 10, s.y, 0)
            end
        end
        garland.Visible = Fest.Lights
        if Fest.Lights then
            for i, b in ipairs(bulbs) do b.BackgroundTransparency = 0.35 + 0.35 * math.sin(t * 3 + i * 1.3) end
        end
        if Fest.Border then borderGrad.Rotation = (t * 40) % 360 end
    end)
end

------------------------------------------------------------------
-- TABS
------------------------------------------------------------------
local pages, tabBtns = {}, {}
local currentPage

local function applyFilter()
    if not currentPage then return end
    local q = search.Text:lower()
    for _, ch in ipairs(currentPage:GetChildren()) do
        local s = ch:GetAttribute("S")
        if s ~= nil then ch.Visible = (q == "") or (s:find(q, 1, true) ~= nil) end
        if ch:GetAttribute("H") then ch.Visible = (q == "") end
    end
end
connect(search:GetPropertyChangedSignal("Text"), applyFilter)

local function paintTabs()
    for name, t in pairs(tabBtns) do
        local active = (pages[name] == currentPage)
        t.btn.BackgroundTransparency = active and 0 or 1
        t.btn.BackgroundColor3 = Theme.Element
        t.ind.Visible = active
        t.lbl.TextColor3 = active and Theme.Text or Theme.SubText
    end
end
table.insert(refreshers, paintTabs)

local function selectTab(name)
    local page = pages[name]
    if not page then return end
    for _, p in pairs(pages) do p.Visible = false end
    currentPage = page
    search.Text = ""
    applyFilter()
    page.Position = UDim2.fromOffset(0, 12)
    page.Visible = true
    tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.2)
    paintTabs()
end

local function newTab(name, icon)
    local btn = create("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        BorderSizePixel = 0, Parent = tabList }, { corner(8) })
    local ind = create("Frame", { Size = UDim2.fromOffset(3, 18), Position = UDim2.new(0, 5, 0.5, -9), BorderSizePixel = 0, Visible = false, Parent = btn }, { corner(2) })
    bind(ind, "BackgroundColor3", "Accent")
    create("TextLabel", { Size = UDim2.fromOffset(20, 36), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1, Text = icon or "",
        Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), Parent = btn })
    local lbl = create("TextLabel", { Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(40, 0), BackgroundTransparency = 1, Text = name,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn })
    lbl.TextColor3 = Theme.SubText
    local page = create("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false, Parent = content },
        { create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14) }),
          create("UIListLayout", { Padding = UDim.new(0, 7) }) })
    bind(page, "ScrollBarImageColor3", "Accent")
    pages[name] = page
    tabBtns[name] = { btn = btn, ind = ind, lbl = lbl }
    btn.MouseEnter:Connect(function() if pages[name] ~= currentPage then tween(lbl, { TextColor3 = Theme.Text }, 0.12) end end)
    btn.MouseLeave:Connect(function() if pages[name] ~= currentPage then tween(lbl, { TextColor3 = Theme.SubText }, 0.12) end end)
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end

------------------------------------------------------------------
-- ELEMENTS
------------------------------------------------------------------
local function label(parent, text, o)
    o = o or {}
    local l = create("TextLabel", { BackgroundTransparency = 1, Text = text, Font = o.font or Enum.Font.Gotham, TextSize = o.size or 13,
        TextXAlignment = o.align or Enum.TextXAlignment.Left, Size = o.sz or UDim2.new(1, -24, 1, 0), Position = o.pos or UDim2.fromOffset(14, 0),
        RichText = true, Parent = parent })
    if o.color then l.TextColor3 = o.color else bind(l, "TextColor3", o.key or "Text") end
    return l
end

local function card(page, height, searchText)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, height or 40), BorderSizePixel = 0, Parent = page },
        { corner(9), create("UIStroke", { Thickness = 1, Name = "S" }) })
    bind(row, "BackgroundColor3", "Element")
    bind(row.S, "Color", "Stroke")
    row:SetAttribute("S", (searchText or ""):lower())
    return row
end

local function hoverable(row, hit)
    hit.MouseEnter:Connect(function() tween(row, { BackgroundColor3 = Theme.Hover }, 0.12) end)
    hit.MouseLeave:Connect(function() tween(row, { BackgroundColor3 = Theme.Element }, 0.12) end)
end

local function addBanner(page, title, sub)
    local f = create("Frame", { Size = UDim2.new(1, 0, 0, 74), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = page }, { corner(12) })
    accentGradient(f, 20)
    f:SetAttribute("H", true)
    label(f, title, { font = Enum.Font.GothamBold, size = 19, sz = UDim2.new(1, -90, 0, 28), pos = UDim2.fromOffset(18, 12), color = Color3.new(1, 1, 1) })
    label(f, sub, { size = 12, sz = UDim2.new(1, -90, 0, 20), pos = UDim2.fromOffset(18, 42), color = C(240, 240, 248) })
    label(f, "\u{1F384}", { size = 38, align = Enum.TextXAlignment.Center, sz = UDim2.fromOffset(60, 74), pos = UDim2.new(1, -70, 0, 0), color = Color3.new(1, 1, 1) })
end

local function addLabel(page, text)
    local f = create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = page })
    f:SetAttribute("H", true)
    local dot = create("Frame", { Size = UDim2.fromOffset(3, 12), Position = UDim2.new(0, 2, 0.5, -6), BorderSizePixel = 0, Parent = f }, { corner(2) })
    bind(dot, "BackgroundColor3", "Accent")
    label(f, text:upper(), { font = Enum.Font.GothamBold, size = 11, key = "SubText", pos = UDim2.fromOffset(12, 0) })
end

local function addInfo(page, text)
    local row = card(page, 32, text)
    return label(row, text)
end

local function addButton(page, text, callback)
    local row = card(page, 38, text)
    local hit = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row })
    label(row, text)
    label(row, ">", { sz = UDim2.fromOffset(20, 38), pos = UDim2.new(1, -28, 0, 0), font = Enum.Font.GothamBold, size = 14, key = "SubText" })
    hoverable(row, hit)
    hit.MouseButton1Click:Connect(function()
        row.BackgroundColor3 = Theme.Accent
        tween(row, { BackgroundColor3 = Theme.Hover }, 0.35)
        local ok, err = pcall(callback)
        if not ok then notify("Error", tostring(err), 4, "error") end
    end)
end

local function addTextBox(page, text, placeholder, default, onEnter)
    local row = card(page, 44, text)
    local box = create("TextBox", { Size = UDim2.new(1, -28, 0, 28), Position = UDim2.fromOffset(14, 8), Text = default or "",
        PlaceholderText = placeholder or "", PlaceholderColor3 = C(120, 140, 130), Font = Enum.Font.Gotham, TextSize = 12,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0, Parent = row }, { corner(6), create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
    bind(box, "BackgroundColor3", "Hover")
    bind(box, "TextColor3", "Text")
    if onEnter then box.FocusLost:Connect(function(enter) if enter then onEnter(box) end end) end
    return box
end

-- addToggle(page, text, default, callback, desc?)  -> state is auto-saved and live-loadable
local function addToggle(page, text, default, callback, desc)
    local def = default or false
    local state = def
    if Config.Toggles[text] ~= nil then state = Config.Toggles[text] and true or false end
    local row = card(page, desc and 54 or 40, text .. " " .. (desc or ""))
    local hit = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row })
    hit:SetAttribute("NoSound", true)
    if desc then
        label(row, text, { sz = UDim2.new(1, -80, 0, 22), pos = UDim2.fromOffset(14, 7) })
        local d = label(row, desc, { size = 11, key = "SubText", sz = UDim2.new(1, -80, 0, 16), pos = UDim2.fromOffset(14, 28) })
        d.TextTruncate = Enum.TextTruncate.AtEnd
    else
        label(row, text, { sz = UDim2.new(1, -80, 1, 0) })
    end
    local track = create("TextButton", { Size = UDim2.fromOffset(42, 22), Position = UDim2.new(1, -56, 0.5, -11), Text = "", AutoButtonColor = false,
        BorderSizePixel = 0, Parent = row }, { corner(11) })
    track:SetAttribute("NoSound", true)
    local knob = create("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, Parent = track }, { corner(8) })
    local function paint(animate)
        local c = state and Theme.Accent or Theme.Stroke
        local p = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
        if animate then tween(track, { BackgroundColor3 = c }, 0.18); tween(knob, { Position = p }, 0.18, Enum.EasingStyle.Back)
        else track.BackgroundColor3 = c; knob.Position = p end
    end
    paint(false)
    table.insert(refreshers, function() paint(false) end)
    local function set(v)
        state = v and true or false
        Config.Toggles[text] = state
        saveSoon()
        paint(true)
        local ok, err = pcall(callback, state)
        if not ok then notify("Error", tostring(err), 4, "error") end
    end
    local function userSet()
        playSound("click", (not state) and 1.2 or 0.85)
        set(not state)
    end
    hit.MouseButton1Click:Connect(userSet)
    track.MouseButton1Click:Connect(userSet)
    hoverable(row, hit)
    if state ~= def or state then pcall(callback, state) end
    registry.toggles[text] = function(v) set(v) end
    return { Set = set, Get = function() return state end }
end

local function addSlider(page, text, min, max, default, callback)
    local value = default or min
    local loaded = Config.Sliders[text]
    if type(loaded) == "number" then value = math.clamp(loaded, min, max) else loaded = nil end
    local row = card(page, 58, text)
    label(row, text, { sz = UDim2.new(1, -100, 0, 24), pos = UDim2.fromOffset(14, 6) })
    local box = create("TextBox", { Size = UDim2.fromOffset(54, 22), Position = UDim2.new(1, -68, 0, 7), Text = tostring(value),
        Font = Enum.Font.GothamMedium, TextSize = 12, ClearTextOnFocus = false, BorderSizePixel = 0, Parent = row }, { corner(6) })
    bind(box, "BackgroundColor3", "Hover")
    bind(box, "TextColor3", "Text")
    local bar = create("Frame", { Size = UDim2.new(1, -28, 0, 6), Position = UDim2.new(0, 14, 0, 40), BorderSizePixel = 0, Parent = row }, { corner(3) })
    bind(bar, "BackgroundColor3", "Stroke")
    local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = bar }, { corner(3) })
    accentGradient(fill, 0)
    local knob = create("Frame", { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = bar }, { corner(7), create("UIStroke", { Thickness = 2, Name = "S" }) })
    bind(knob.S, "Color", "Accent")
    local function setValue(v, fire)
        v = math.clamp(math.floor(v + 0.5), min, max)
        value = v
        local a = (v - min) / (max - min)
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        box.Text = tostring(v)
        if fire then
            Config.Sliders[text] = v
            saveSoon()
            pcall(callback, v)
        end
    end
    setValue(value, false)
    if loaded ~= nil then pcall(callback, value) end
    registry.sliders[text] = function(v) setValue(tonumber(v) or value, true) end
    local hit = create("TextButton", { Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 30), BackgroundTransparency = 1, Text = "", Parent = row })
    hit:SetAttribute("NoSound", true)
    local sliding = false
    local function fromX(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        setValue(min + (max - min) * a, true)
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true; fromX(i.Position.X) end
    end)
    connect(UIS.InputChanged, function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromX(i.Position.X) end
    end)
    connect(UIS.InputEnded, function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            sliding = false
            playSound("click", 1.1, 0.6)
        end
    end)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then setValue(n, true) else box.Text = tostring(value) end
    end)
end

local function addCycle(page, text, id, options, default, callback, swatches)
    local idx = table.find(options, Config.Opts[id] or default) or 1
    local row = card(page, 40, text)
    label(row, text, { sz = UDim2.new(1, -200, 1, 0) })
    local function arrow(t, x)
        local b = create("TextButton", { Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, x, 0.5, -12), Text = t, Font = Enum.Font.GothamBold,
            TextSize = 13, AutoButtonColor = false, BorderSizePixel = 0, Parent = row }, { corner(6) })
        bind(b, "BackgroundColor3", "Hover")
        bind(b, "TextColor3", "Text")
        return b
    end
    local prev, nxt = arrow("<", -176), arrow(">", -36)
    local sw
    if swatches then
        sw = create("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -144, 0.5, -6), BorderSizePixel = 0, Parent = row }, { corner(6) })
    end
    local val = create("TextLabel", { Size = UDim2.fromOffset(swatches and 80 or 100, 24), Position = UDim2.new(1, swatches and -128 or -146, 0.5, -12),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12, Text = "", Parent = row })
    bind(val, "TextColor3", "Text")
    local function show(fire)
        val.Text = options[idx]
        if sw then sw.BackgroundColor3 = swatches[options[idx]] or Color3.new(1, 1, 1) end
        Config.Opts[id] = options[idx]
        if fire then saveSoon() end
        pcall(callback, options[idx])
    end
    prev.MouseButton1Click:Connect(function() idx = (idx - 2) % #options + 1; show(true) end)
    nxt.MouseButton1Click:Connect(function() idx = idx % #options + 1; show(true) end)
    show(false)
    registry.cycles[id] = function(name)
        local i = table.find(options, name)
        if i then idx = i; show(true) end
    end
end

local binds, listening = {}, false
local function addKeybind(page, text, id, default, callback)
    local row = card(page, 40, text)
    label(row, text, { sz = UDim2.new(1, -130, 1, 0) })
    binds[id] = { key = Config.Binds[id] or default, cb = callback }
    local btn = create("TextButton", { Size = UDim2.fromOffset(100, 24), Position = UDim2.new(1, -112, 0.5, -12), Text = binds[id].key,
        Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, BorderSizePixel = 0, Parent = row }, { corner(6) })
    bind(btn, "BackgroundColor3", "Hover")
    bind(btn, "TextColor3", "Text")
    registry.binds[id] = function(k)
        binds[id].key = k
        Config.Binds[id] = k
        btn.Text = k
    end
    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        btn.Text = "press a key..."
        btn.TextColor3 = Theme.Accent
        local c
        c = UIS.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Keyboard then
                local k = (i.KeyCode == Enum.KeyCode.Escape) and "None" or i.KeyCode.Name
                binds[id].key = k
                Config.Binds[id] = k
                saveSoon()
                btn.Text = k
                btn.TextColor3 = Theme.Text
                listening = false
                c:Disconnect()
            end
        end)
    end)
end

connect(UIS.InputBegan, function(i, gp)
    if gp or listening or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    for _, b in pairs(binds) do
        if b.key == i.KeyCode.Name then pcall(b.cb) end
    end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

------------------------------------------------------------------
-- MM2 CORE: roles, gun drop
------------------------------------------------------------------
local PALETTE = {
    Red = Color3.fromRGB(255, 60, 60), Blue = Color3.fromRGB(70, 140, 255), Green = Color3.fromRGB(60, 255, 120),
    Yellow = Color3.fromRGB(255, 220, 60), Purple = Color3.fromRGB(170, 90, 255), Pink = Color3.fromRGB(255, 110, 190),
    Orange = Color3.fromRGB(255, 150, 50), White = Color3.fromRGB(255, 255, 255),
}
local PALETTE_NAMES = { "Red", "Blue", "Green", "Yellow", "Purple", "Pink", "Orange", "White" }

local ESP = {
    Enabled = false, Names = true, RoleText = true, Distance = true, Innocents = true, GunMarker = true,
    Fill = 0.6, MaxDist = 2000, Colors = { Murderer = "Red", Sheriff = "Blue", Innocent = "Green" },
}
local Roles = {} -- [playerName] = { Role = "Murderer"/"Sheriff"/"Hero"/"Innocent", Dead = bool }
local getDataRemote

local function toolRole(plr)
    local char, bp = plr.Character, plr:FindFirstChildOfClass("Backpack")
    if (char and char:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife")) then return "Murderer" end
    if (char and char:FindFirstChild("Gun")) or (bp and bp:FindFirstChild("Gun")) then return "Sheriff" end
    return "Innocent"
end

local function refreshRoles()
    local data
    if not (getDataRemote and getDataRemote.Parent) then
        local r = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
        if r and r:IsA("RemoteFunction") then getDataRemote = r end
    end
    if getDataRemote then
        local ok, res = pcall(function() return getDataRemote:InvokeServer() end)
        if ok and type(res) == "table" then data = res end
    end
    local new = {}
    if data then
        for name, info in pairs(data) do
            if type(info) == "table" then
                new[name] = { Role = info.Role or "Innocent", Dead = (info.Dead or info.Killed) and true or false }
            end
        end
    else -- fallback: read equipped tools
        for _, plr in ipairs(Players:GetPlayers()) do
            new[plr.Name] = { Role = toolRole(plr), Dead = false }
        end
    end
    Roles = new
end

local function roleKey(role)
    if role == "Murderer" then return "Murderer" end
    if role == "Sheriff" or role == "Hero" then return "Sheriff" end
    return "Innocent"
end
local function roleOf(plr) local i = Roles[plr.Name]; return i and i.Role or "Innocent" end

local function partOf(o)
    if not o then return nil end
    return o:IsA("BasePart") and o or o:FindFirstChildWhichIsA("BasePart", true)
end

local gunDrop
local AutoGun = { Enabled = false, Return = true, Notify = true }
local grabbing = false

local function grabGun()
    if grabbing or not gunDrop or not gunDrop.Parent then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end
    if roleKey(roleOf(LocalPlayer)) == "Murderer" then return false end
    local part = partOf(gunDrop)
    if not part then return false end
    grabbing = true
    local back = hrp.CFrame
    pcall(function()
        firetouchinterest(hrp, part, 0)
        firetouchinterest(hrp, part, 1)
    end)
    task.wait(0.25)
    if gunDrop and gunDrop.Parent and part.Parent then -- touch method did nothing, move there briefly
        hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.3)
        if AutoGun.Return then hrp.CFrame = back end
    end
    grabbing = false
    return true
end

for _, d in ipairs(workspace:GetDescendants()) do
    if d.Name == "GunDrop" then gunDrop = d break end
end
connect(workspace.DescendantAdded, function(d)
    if d.Name == "GunDrop" then
        gunDrop = d
        if AutoGun.Notify then notify("Gun dropped", "The sheriff's gun is on the ground") end
        if AutoGun.Enabled then task.delay(0.3, grabGun) end
    end
end)
connect(workspace.DescendantRemoving, function(d) if d == gunDrop then gunDrop = nil end end)

do -- retry loop while a gun is lying around
    local acc = 0
    connect(RunService.Heartbeat, function(dt)
        acc += dt
        if acc >= 0.5 then
            acc = 0
            if AutoGun.Enabled and gunDrop and gunDrop.Parent and not grabbing then task.spawn(grabGun) end
        end
    end)
end

------------------------------------------------------------------
-- ESP objects
------------------------------------------------------------------
local espObjects, gunObjs = {}, nil

local function clearESP(plr)
    local o = espObjects[plr]
    if o then
        pcall(function() o.hl:Destroy() end)
        pcall(function() o.bb:Destroy() end)
        espObjects[plr] = nil
    end
end

local function buildESP(plr)
    clearESP(plr)
    if plr == LocalPlayer or not ESP.Enabled then return end
    local char = plr.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
    if not root then return end
    local hl = create("Highlight", { Adornee = char, FillColor = PALETTE.Green, OutlineColor = Color3.new(1, 1, 1),
        FillTransparency = ESP.Fill, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Parent = gui })
    local bb = create("BillboardGui", { Adornee = root, Size = UDim2.fromOffset(200, 30),
        StudsOffset = Vector3.new(0, 3.4, 0), AlwaysOnTop = true, Parent = gui }, {
        create("TextLabel", { Name = "L", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.4, Font = Enum.Font.GothamBold, TextSize = 13 }),
    })
    espObjects[plr] = { hl = hl, bb = bb, root = root }
end

local function refreshESP()
    for plr in pairs(espObjects) do clearESP(plr) end
    if ESP.Enabled then
        for _, plr in ipairs(Players:GetPlayers()) do task.spawn(buildESP, plr) end
    end
end

local function hookPlayer(plr)
    connect(plr.CharacterAdded, function() task.wait(0.3); buildESP(plr) end)
end
for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
connect(Players.PlayerAdded, hookPlayer)
connect(Players.PlayerRemoving, clearESP)

local function updateGunMarker()
    local want = ESP.Enabled and ESP.GunMarker and gunDrop and gunDrop.Parent and partOf(gunDrop)
    if want and not gunObjs then
        local gold = Color3.fromRGB(255, 215, 0)
        gunObjs = {
            ref = gunDrop,
            hl = create("Highlight", { Adornee = gunDrop, FillColor = gold, OutlineColor = Color3.new(1, 1, 1),
                FillTransparency = 0.3, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Parent = gui }),
            bb = create("BillboardGui", { Adornee = want, Size = UDim2.fromOffset(120, 24),
                StudsOffset = Vector3.new(0, 2, 0), AlwaysOnTop = true, Parent = gui }, {
                create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "GUN",
                    TextColor3 = gold, Font = Enum.Font.GothamBold, TextSize = 15, TextStrokeTransparency = 0.4 }),
            }),
        }
    elseif gunObjs and (not want or gunObjs.ref ~= gunDrop) then
        pcall(function() gunObjs.hl:Destroy(); gunObjs.bb:Destroy() end)
        gunObjs = nil
    end
end

connect(RunService.Heartbeat, function()
    local cam = workspace.CurrentCamera
    for plr, o in pairs(espObjects) do
        if not o.root or not o.root.Parent then
            clearESP(plr)
        else
            local info = Roles[plr.Name]
            local key = roleKey(info and info.Role)
            local dist = (cam.CFrame.Position - o.root.Position).Magnitude
            local visible = ESP.Enabled and not (info and info.Dead) and dist <= ESP.MaxDist
                and (ESP.Innocents or key ~= "Innocent")
            o.hl.Enabled = visible
            o.bb.Enabled = visible
            if visible then
                local color = PALETTE[ESP.Colors[key]] or PALETTE.Green
                o.hl.FillColor = color
                o.hl.FillTransparency = ESP.Fill
                local parts = {}
                if ESP.Names then table.insert(parts, plr.DisplayName) end
                if ESP.RoleText and key ~= "Innocent" then table.insert(parts, "(" .. (info and info.Role or key) .. ")") end
                if ESP.Distance then table.insert(parts, "[" .. math.floor(dist) .. "m]") end
                o.bb.L.Text = table.concat(parts, " ")
                o.bb.L.TextColor3 = color
            end
        end
    end
    updateGunMarker()
end)

------------------------------------------------------------------
-- MOVEMENT STATE
------------------------------------------------------------------
local Move = { SpeedOn = false, Speed = 24, JumpOn = false, Jump = 60, InfJump = false, Noclip = false,
               Fly = false, FlySpeed = 60 }
local flyBV, flyBG, flyConn

local function getHum() local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local h = getHum()
    if h then h.PlatformStand = false end
end

local function startFly()
    stopFly()
    local hrp, hum = getRoot(), getHum()
    if not hrp or not hum then return end
    flyBV = create("BodyVelocity", { MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero, Parent = hrp })
    flyBG = create("BodyGyro", { MaxTorque = Vector3.new(1e9, 1e9, 1e9), P = 1e4, Parent = hrp })
    hum.PlatformStand = true
    flyConn = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if not UIS:GetFocusedTextBox() then
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
        end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * Move.FlySpeed or Vector3.zero
        flyBG.CFrame = cam.CFrame
    end)
end

connect(RunService.Heartbeat, function()
    local hum = getHum()
    if hum then
        if Move.SpeedOn then hum.WalkSpeed = Move.Speed end
        if Move.JumpOn then hum.UseJumpPower = true; hum.JumpPower = Move.Jump end
    end
end)
connect(RunService.Stepped, function()
    if Move.Noclip and LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end)
connect(UIS.JumpRequest, function()
    if Move.InfJump then
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
connect(LocalPlayer.CharacterAdded, function()
    stopFly()
    if Move.Fly then task.wait(1); if Move.Fly then startFly() end end
end)

------------------------------------------------------------------
-- VISUALS STATE (sky, time, fullbright, world snow)
------------------------------------------------------------------
local origLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
local Vis = { Fullbright = false, TimeLock = false, Time = 12 }
local atmo, atmoCreated, atmoOrig

local skyPresets = {
    ChristmasEve = { time = 0,  color = Color3.fromRGB(90, 130, 200),  decay = Color3.fromRGB(40, 60, 110),   density = 0.38, haze = 1.2, glare = 0 },
    SnowyDay = { time = 14,     color = Color3.fromRGB(220, 230, 245), decay = Color3.fromRGB(180, 195, 215), density = 0.55, haze = 2.4, glare = 0 },
    Sunset   = { time = 17.8, color = Color3.fromRGB(255, 150, 100), decay = Color3.fromRGB(255, 110, 60), density = 0.35, haze = 1.5, glare = 0.5 },
    Night    = { time = 0,    color = Color3.fromRGB(40, 50, 110),   decay = Color3.fromRGB(20, 20, 60),   density = 0.4,  haze = 1,   glare = 0 },
    Neon     = { time = 0,    color = Color3.fromRGB(170, 60, 255),  decay = Color3.fromRGB(255, 40, 170), density = 0.45, haze = 2,   glare = 1 },
    Dawn     = { time = 6,    color = Color3.fromRGB(255, 180, 200), decay = Color3.fromRGB(255, 140, 150), density = 0.3,  haze = 1.2, glare = 0.3 },
    Overcast = { time = 12,   color = Color3.fromRGB(170, 175, 185), decay = Color3.fromRGB(140, 145, 155), density = 0.5,  haze = 2,   glare = 0 },
}

local function applySky(name)
    if name == "Default" then
        if atmo and atmoOrig then
            if atmoCreated then atmo:Destroy(); atmo = nil; atmoCreated = false
            else for k, v in pairs(atmoOrig) do atmo[k] = v end end
            Lighting.ClockTime = origLighting.ClockTime
        end
        Vis.TimeLock = false
        return
    end
    local p = skyPresets[name]
    if not p then return end
    atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmo then atmo = Instance.new("Atmosphere"); atmo.Parent = Lighting; atmoCreated = true end
    atmoOrig = atmoOrig or { Color = atmo.Color, Decay = atmo.Decay, Density = atmo.Density, Haze = atmo.Haze, Glare = atmo.Glare }
    atmo.Color, atmo.Decay, atmo.Density, atmo.Haze, atmo.Glare = p.color, p.decay, p.density, p.haze, p.glare
    Vis.Time, Vis.TimeLock = p.time, true
end

connect(RunService.Heartbeat, function()
    if Vis.Fullbright then
        Lighting.Brightness = 2
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    end
    if Vis.TimeLock then Lighting.ClockTime = Vis.Time end
end)

local function restoreLighting()
    Vis.Fullbright, Vis.TimeLock = false, false
    for k, v in pairs(origLighting) do pcall(function() Lighting[k] = v end) end
    applySky("Default")
end

-- falling snow in the actual game world (follows your camera)
local WorldSnow = { Part = nil, Conn = nil }
local function setWorldSnow(on)
    if WorldSnow.Conn then WorldSnow.Conn:Disconnect(); WorldSnow.Conn = nil end
    if WorldSnow.Part then WorldSnow.Part:Destroy(); WorldSnow.Part = nil end
    if not on then return end
    local p = Instance.new("Part")
    p.Name = "VortexSnow"
    p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
    p.Transparency = 1
    p.Size = Vector3.new(90, 1, 90)
    local pe = Instance.new("ParticleEmitter")
    pe.Rate = 260
    pe.Lifetime = NumberRange.new(4, 6)
    pe.Speed = NumberRange.new(8, 12)
    pe.EmissionDirection = Enum.NormalId.Bottom
    pe.SpreadAngle = Vector2.new(12, 12)
    pe.Size = NumberSequence.new(0.3)
    pe.Color = ColorSequence.new(Color3.new(1, 1, 1))
    pe.LightEmission = 0.5
    pe.Transparency = NumberSequence.new(0.1)
    pe.RotSpeed = NumberRange.new(-40, 40)
    pe.Acceleration = Vector3.new(2, 0, 1)
    pe.Parent = p
    p.Parent = workspace.CurrentCamera
    WorldSnow.Part = p
    WorldSnow.Conn = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if p.Parent ~= cam then p.Parent = cam end
        p.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 35, 0))
    end)
end

------------------------------------------------------------------
-- MISC STATE
------------------------------------------------------------------
local AntiAFK = true
connect(LocalPlayer.Idled, function()
    if AntiAFK then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

local function serverHop()
    notify("Server Hop", "Searching for a server...")
    local ok, body = pcall(function()
        return game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId))
    end)
    if not ok then return notify("Server Hop", "Request failed") end
    local data = HttpService:JSONDecode(body)
    for _, s in ipairs(data.data or {}) do
        if s.id ~= game.JobId and s.playing < s.maxPlayers - 1 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
            return
        end
    end
    notify("Server Hop", "No suitable server found")
end

------------------------------------------------------------------
-- SHERIFF AUTO SHOOT + HUD
------------------------------------------------------------------
-- MM2 updates sometimes change the shoot remote's arguments. If shots stop landing after
-- a game update, this token is the first thing to check.
local SHOOT_TOKEN = "AH2"

local AutoShoot = {
    Enabled = false, AutoEquip = true, WallCheck = true, Predict = true, Notify = true, HUD = true,
    Range = 250, Reaction = 150, Cooldown = 2000, PredictAmount = 100,
    Shots = 0, Kills = 0, LastName = "-", LastShot = -1e4, SeenAt = nil, Downed = nil,
    Target = nil, Dist = 0, Method = "-", State = "off", Status = "Off", Busy = false,
}
local STATE_COLORS = {
    off = C(140, 140, 160), idle = C(140, 140, 160), lock = C(241, 168, 40),
    cool = C(241, 168, 40), blocked = C(235, 87, 87), ok = C(46, 204, 113),
}

local function hex(c)
    return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function roleColorHex(role)
    return hex(PALETTE[ESP.Colors[roleKey(role)]] or PALETTE.Green)
end
local function setState(key, text)
    AutoShoot.State, AutoShoot.Status = key, text
    return false
end

local function myRoleName()
    local info = Roles[LocalPlayer.Name]
    if info and info.Role then return info.Role, info.Dead end
    return toolRole(LocalPlayer), false
end

local function findGun()
    local char, bp = LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack")
    local g = (char and char:FindFirstChild("Gun")) or (bp and bp:FindFirstChild("Gun"))
    return (g and g:IsA("Tool")) and g or nil
end

local function getMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local info = Roles[plr.Name]
            if info and info.Role == "Murderer" and not info.Dead then return plr end
        end
    end
    return nil
end

local function predictedPos(troot)
    local pos = troot.Position
    if AutoShoot.Predict then
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        local t = ((ok and ping or 60) / 1000) + 0.05
        local vel = troot.AssemblyLinearVelocity
        pos = pos + Vector3.new(vel.X, 0, vel.Z) * t * (AutoShoot.PredictAmount / 100)
    end
    return pos
end

local function lineClear(hrp, aim, tchar)
    local char = LocalPlayer.Character
    local origin = ((char and char:FindFirstChild("Head")) or hrp).Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char, tchar }
    return workspace:Raycast(origin, aim - origin, params) == nil
end

local function fireGun(gun, pos)
    local kl = gun:FindFirstChild("KnifeLocal")
    local cb = kl and kl:FindFirstChild("CreateBeam")
    local rf = cb and cb:FindFirstChild("RemoteFunction")
    if rf then
        task.spawn(function() pcall(function() rf:InvokeServer(1, pos, SHOOT_TOKEN) end) end)
        return "remote"
    end
    -- fallback (best effort): face the target and activate the tool
    local cam = workspace.CurrentCamera
    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, pos)
    pcall(function() gun:Activate() end)
    return "click"
end

local function runShoot(manual)
    local A = AutoShoot
    A.Target = nil
    if not manual and not A.Enabled then A.SeenAt = nil; return setState("off", "Off") end
    local gun = findGun()
    if not gun then A.SeenAt = nil; return setState("idle", "Waiting - you have no gun") end
    local hrp, hum = getRoot(), getHum()
    if not hrp or not hum or hum.Health <= 0 then A.SeenAt = nil; return setState("idle", "You are dead") end
    local target = getMurderer()
    if not target then A.SeenAt = nil; return setState("idle", "No murderer found") end
    if A.Downed == target.Name then A.Downed = nil end
    local tchar = target.Character
    local troot = tchar and tchar:FindFirstChild("HumanoidRootPart")
    local thum = tchar and tchar:FindFirstChildOfClass("Humanoid")
    if not troot or not thum or thum.Health <= 0 then A.SeenAt = nil; return setState("idle", "Murderer not loaded") end

    A.Target = target
    local dist = (troot.Position - hrp.Position).Magnitude
    A.Dist = dist
    if dist > A.Range then
        A.SeenAt = nil
        return setState("blocked", string.format("Out of range (%dm / %dm)", math.floor(dist), A.Range))
    end
    local aim = predictedPos(troot)
    if A.WallCheck and not lineClear(hrp, aim, tchar) then
        A.SeenAt = nil
        return setState("blocked", "Behind cover")
    end

    local now = os.clock()
    if not manual then
        A.SeenAt = A.SeenAt or now
        if A.Reaction / 1000 - (now - A.SeenAt) > 0 then return setState("lock", "Locking on...") end
    end
    local cdLeft = A.Cooldown / 1000 - (now - A.LastShot)
    if cdLeft > 0 then return setState("cool", string.format("Cooling down (%.1fs)", cdLeft)) end

    if gun.Parent ~= LocalPlayer.Character then
        if not (A.AutoEquip or manual) then return setState("idle", "Equip your gun to shoot") end
        pcall(function() hum:EquipTool(gun) end)
        task.wait(0.2)
        if gun.Parent ~= LocalPlayer.Character then return setState("idle", "Could not equip gun") end
        aim = predictedPos(troot)
    end

    A.Method = fireGun(gun, aim)
    A.LastShot = os.clock()
    A.Shots += 1
    A.LastName = target.DisplayName
    setState("ok", "Shot fired")
    if A.Notify then
        notify("Auto Shoot", string.format("Fired at %s  [%dm]", target.DisplayName, math.floor(dist)), 2)
    end
    local name, display = target.Name, target.DisplayName
    task.delay(2, function()
        local info = Roles[name]
        if info and info.Dead and A.Downed ~= name then
            A.Downed = name
            A.Kills += 1
            if A.Notify then notify("Murderer down", display .. " was eliminated", 3, "success") end
        end
    end)
    return true
end

local function shootStep(manual)
    local A = AutoShoot
    if A.Busy then return false end
    A.Busy = true
    local fired = false
    local ok = pcall(function() fired = runShoot(manual) end)
    A.Busy = false
    return ok and fired
end

-- Sheriff HUD (small panel at top-center)
local hud = create("Frame", { Size = UDim2.fromOffset(250, 82), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12),
    BorderSizePixel = 0, Visible = false, Parent = gui }, { corner(10), create("UIStroke", { Thickness = 1, Name = "S" }) })
bind(hud, "BackgroundColor3", "Topbar")
bind(hud.S, "Color", "Stroke")
local function hudText(y, h, size, font, align, key)
    local t = create("TextLabel", { Size = UDim2.new(1, -28, 0, h), Position = UDim2.fromOffset(14, y), BackgroundTransparency = 1, Text = "",
        Font = font or Enum.Font.Gotham, TextSize = size, TextXAlignment = align or Enum.TextXAlignment.Left, RichText = true, Parent = hud })
    bind(t, "TextColor3", key or "Text")
    return t
end
local hudTitle = hudText(7, 14, 11, Enum.Font.GothamBold, nil, "SubText")
hudTitle.Text = "SHERIFF ASSIST"
local hudShots = hudText(7, 14, 11, Enum.Font.Gotham, Enum.TextXAlignment.Right, "SubText")
local hudTarget = hudText(24, 16, 13, Enum.Font.GothamMedium)
local hudStatus = hudText(43, 16, 12, Enum.Font.Gotham)
local hudCd = hudText(43, 16, 12, Enum.Font.Gotham, Enum.TextXAlignment.Right, "SubText")
local hudBar = create("Frame", { Size = UDim2.new(1, -28, 0, 5), Position = UDim2.fromOffset(14, 66), BorderSizePixel = 0, Parent = hud }, { corner(3) })
bind(hudBar, "BackgroundColor3", "Stroke")
local hudFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = hudBar }, { corner(3) })
accentGradient(hudFill, 0)

-- labels on the Home / MM2 tabs (assigned when those tabs are built)
local homeRole, homeShoot, homeTarget, homeShots, miStatus, miTarget

local function updateInfo()
    local A = AutoShoot
    local role, dead = myRoleName()
    local gun = findGun()
    local rtxt = string.format('<font color="%s">%s</font>%s', roleColorHex(role), role, dead and "  (dead)" or "")
    local sc = hex(STATE_COLORS[A.State] or STATE_COLORS.idle)
    local stxt = string.format('<font color="%s">%s</font>', sc, A.Status)
    local ttxt = A.Target and string.format("%s  [%dm]", A.Target.DisplayName, math.floor(A.Dist)) or "none"

    if homeRole then homeRole.Text = "Your role: " .. rtxt .. (gun and "   -   holding the gun" or "") end
    if homeShoot then homeShoot.Text = "Auto shoot: " .. (A.Enabled and "<b>ON</b>" or "off") .. "   -   " .. stxt end
    if homeTarget then homeTarget.Text = "Target: " .. ttxt end
    if homeShots then
        homeShots.Text = string.format("Shots: %d   |   Eliminations: %d   |   Last: %s", A.Shots, A.Kills, A.LastName)
    end
    if miStatus then miStatus.Text = "Status: " .. stxt .. "   (" .. A.Method .. ")" end
    if miTarget then miTarget.Text = "Target: " .. ttxt end

    hud.Visible = A.HUD and (A.Enabled or gun ~= nil)
    if hud.Visible then
        hudShots.Text = string.format("Shots %d  |  Down %d", A.Shots, A.Kills)
        hudTarget.Text = A.Target and string.format('<font color="%s">%s</font>  [%dm]', roleColorHex("Murderer"), A.Target.DisplayName, math.floor(A.Dist))
            or "Target: none"
        hudStatus.Text = stxt
        local cd = A.Cooldown / 1000
        local elapsed = os.clock() - A.LastShot
        local frac = math.clamp(elapsed / cd, 0, 1)
        hudFill.Size = UDim2.fromScale(frac, 1)
        hudCd.Text = frac >= 1 and "Ready" or string.format("%.1fs", cd - elapsed)
    end
end

task.spawn(function()
    local n = 0
    while gui.Parent do
        shootStep(false)
        n += 1
        if n % 2 == 0 then pcall(updateInfo) end
        task.wait(0.05)
    end
end)

------------------------------------------------------------------
-- TABS CONTENT
------------------------------------------------------------------
local fpsLabel, pingLabel, murdLabel, sherLabel, aliveLabel, gunLabel
local espToggle, autoGunToggle, autoShootToggle, speedToggle, flyToggle, noclipToggle, infJumpToggle

do -- HOME
    local home = newTab("Home", "\u{1F384}")
    addBanner(home, "Merry Christmas, " .. LocalPlayer.DisplayName, HUB_NAME .. " MM2 Christmas Edition  -  " .. xmasText())
    addLabel(home, "Round info")
    murdLabel = addInfo(home, "Murderer: ?")
    sherLabel = addInfo(home, "Sheriff / Hero: ?")
    aliveLabel = addInfo(home, "Alive: ?")
    gunLabel = addInfo(home, "Gun drop: none")
    addLabel(home, "You and combat")
    homeRole = addInfo(home, "Your role: ?")
    homeShoot = addInfo(home, "Auto shoot: off")
    homeTarget = addInfo(home, "Target: none")
    homeShots = addInfo(home, "Shots: 0")
    addLabel(home, "Session")
    addInfo(home, "User: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")")
    fpsLabel = addInfo(home, "FPS: --")
    pingLabel = addInfo(home, "Ping: --")
    addInfo(home, "Tip: use the search bar at the top, drag the corner to resize")
end

do -- MM2
    local mm2 = newTab("MM2", "\u{1F52A}")
    addLabel(mm2, "Player ESP")
    espToggle = addToggle(mm2, "Role ESP", false, function(on) ESP.Enabled = on; refreshESP() end,
        "Highlights murderer, sheriff and innocents")
    addToggle(mm2, "Show Names", true, function(on) ESP.Names = on end, "Display name above each player")
    addToggle(mm2, "Show Role Text", true, function(on) ESP.RoleText = on end, "Adds (Murderer) / (Sheriff) next to the name")
    addToggle(mm2, "Show Distance", true, function(on) ESP.Distance = on end, "Distance in studs from your camera")
    addToggle(mm2, "Show Innocents", true, function(on) ESP.Innocents = on end, "Turn off to only see murderer and sheriff")
    addToggle(mm2, "Mark Dropped Gun", true, function(on) ESP.GunMarker = on end, "Gold highlight on the gun drop")
    addSlider(mm2, "Max Distance", 100, 5000, 2000, function(v) ESP.MaxDist = v end)
    addSlider(mm2, "Fill Transparency %", 0, 100, 60, function(v) ESP.Fill = v / 100 end)
    addLabel(mm2, "ESP colors")
    addCycle(mm2, "Murderer", "col_murd", PALETTE_NAMES, "Red", function(c) ESP.Colors.Murderer = c end, PALETTE)
    addCycle(mm2, "Sheriff / Hero", "col_sher", PALETTE_NAMES, "Blue", function(c) ESP.Colors.Sheriff = c end, PALETTE)
    addCycle(mm2, "Innocent", "col_inno", PALETTE_NAMES, "Green", function(c) ESP.Colors.Innocent = c end, PALETTE)
    addLabel(mm2, "Gun")
    autoGunToggle = addToggle(mm2, "Auto Grab Gun", false, function(on) AutoGun.Enabled = on end,
        "Grabs the dropped gun as soon as it appears")
    addToggle(mm2, "Return to previous spot", true, function(on) AutoGun.Return = on end,
        "Teleports you back after picking the gun up")
    addToggle(mm2, "Notify when gun drops", true, function(on) AutoGun.Notify = on end, "Pop-up the moment the sheriff dies")
    addButton(mm2, "Grab Gun Now", function()
        if not gunDrop then notify("Gun", "No gun on the ground", 2.5, "warn") return end
        if not grabGun() then notify("Gun", "Could not grab it right now", 2.5, "warn") end
    end)
    addLabel(mm2, "Sheriff - auto shoot")
    autoShootToggle = addToggle(mm2, "Auto Shoot Murderer", false, function(on)
        AutoShoot.Enabled = on
        AutoShoot.SeenAt = nil
        if on and not findGun() then notify("Auto Shoot", "Armed - fires once you hold the gun", 3) end
    end, "Shoots the murderer when in range and visible")
    addToggle(mm2, "Auto Equip Gun", true, function(on) AutoShoot.AutoEquip = on end,
        "Pulls the gun from your backpack to shoot")
    addToggle(mm2, "Wall Check", true, function(on) AutoShoot.WallCheck = on end,
        "Only shoots when nothing blocks the line")
    addToggle(mm2, "Predict Movement", true, function(on) AutoShoot.Predict = on end,
        "Leads the shot using their speed and your ping")
    addToggle(mm2, "Shot Notifications", true, function(on) AutoShoot.Notify = on end,
        "Pop-ups for shots fired and eliminations")
    addToggle(mm2, "Sheriff HUD", true, function(on) AutoShoot.HUD = on end,
        "Panel with target, status and cooldown bar")
    addSlider(mm2, "Shoot Range (studs)", 25, 1000, 250, function(v) AutoShoot.Range = v end)
    addSlider(mm2, "Reaction Delay (ms)", 0, 1000, 150, function(v) AutoShoot.Reaction = v end)
    addSlider(mm2, "Shot Cooldown (ms)", 500, 5000, 2000, function(v) AutoShoot.Cooldown = v end)
    addSlider(mm2, "Prediction Strength %", 0, 200, 100, function(v) AutoShoot.PredictAmount = v end)
    miStatus = addInfo(mm2, "Status: off")
    miTarget = addInfo(mm2, "Target: none")
    addButton(mm2, "Shoot Murderer Now", function()
        task.spawn(function()
            if not shootStep(true) then notify("Sheriff", AutoShoot.Status, 2.5, "warn") end
        end)
    end)
end

do -- MOVEMENT
    local mv = newTab("Movement", "\u{1F98C}")
    addLabel(mv, "Speed and jump")
    speedToggle = addToggle(mv, "Custom WalkSpeed", false, function(on)
        Move.SpeedOn = on
        if not on then local h = getHum(); if h then h.WalkSpeed = 16 end end
    end, "Uses the WalkSpeed slider below")
    addSlider(mv, "WalkSpeed", 16, 120, 24, function(v) Move.Speed = v end)
    addToggle(mv, "Custom JumpPower", false, function(on)
        Move.JumpOn = on
        if not on then local h = getHum(); if h then h.JumpPower = 50 end end
    end, "Uses the JumpPower slider below")
    addSlider(mv, "JumpPower", 50, 200, 60, function(v) Move.Jump = v end)
    infJumpToggle = addToggle(mv, "Infinite Jump", false, function(on) Move.InfJump = on end, "Jump again while in the air")
    addLabel(mv, "Fly and noclip")
    flyToggle = addToggle(mv, "Fly", false, function(on)
        Move.Fly = on
        if on then startFly() else stopFly() end
    end, "WASD to move, Space up, Ctrl / Shift down")
    addSlider(mv, "Fly Speed", 20, 200, 60, function(v) Move.FlySpeed = v end)
    noclipToggle = addToggle(mv, "Noclip", false, function(on) Move.Noclip = on end, "Walk through walls and objects")
end

do -- VISUALS
    local vis = newTab("Visuals", "\u{2744}")
    addLabel(vis, "Winter wonderland")
    addToggle(vis, "World Snow", false, setWorldSnow, "Snow falling around you in the game world")
    addLabel(vis, "Sky")
    addCycle(vis, "Sky Preset", "sky", { "Default", "ChristmasEve", "SnowyDay", "Sunset", "Night", "Neon", "Dawn", "Overcast" }, "Default", applySky)
    addSlider(vis, "Time of Day", 0, 24, 12, function(v) Vis.Time = v; Vis.TimeLock = true end)
    addButton(vis, "Reset Sky and Time", function()
        applySky("Default"); Lighting.ClockTime = origLighting.ClockTime; Vis.TimeLock = false
    end)
    addLabel(vis, "Lighting and camera")
    addToggle(vis, "Fullbright", false, function(on)
        Vis.Fullbright = on
        if not on then
            for _, k in ipairs({ "Brightness", "FogEnd", "GlobalShadows", "Ambient", "OutdoorAmbient" }) do
                pcall(function() Lighting[k] = origLighting[k] end)
            end
        end
    end, "Removes shadows, fog and darkness")
    addSlider(vis, "Field of View", 40, 120, 70, function(v) workspace.CurrentCamera.FieldOfView = v end)
    addToggle(vis, "FPS Boost (low graphics)", false, function(on)
        pcall(function()
            settings().Rendering.QualityLevel = on and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
            Lighting.GlobalShadows = not on
        end)
    end, "Lowest render quality for more FPS")
end

do -- BINDS
    local bt = newTab("Binds", "\u{2328}")
    addLabel(bt, "Click a key box, then press a key (Esc = none)")
    addKeybind(bt, "Show / Hide UI", "ui", "RightShift", function() toggleUI() end)
    -- flips a toggle from a keybind and shows a pop-up with the new state
    local function flip(name, get)
        return function()
            local t = get()
            local on = not t.Get()
            t.Set(on)
            if Fest.BindNotify then notify(name, on and "Turned ON" or "Turned OFF", 1.8, on and "success" or "warn") end
        end
    end
    addKeybind(bt, "Toggle Role ESP", "esp", "K", flip("Role ESP", function() return espToggle end))
    addKeybind(bt, "Toggle Auto Grab Gun", "autogun", "None", flip("Auto Grab Gun", function() return autoGunToggle end))
    addKeybind(bt, "Grab Gun Now", "grab", "G", function() task.spawn(grabGun) end)
    addKeybind(bt, "Toggle Auto Shoot", "autoshoot", "None", flip("Auto Shoot", function() return autoShootToggle end))
    addKeybind(bt, "Shoot Murderer Now", "shootnow", "T", function()
        task.spawn(function()
            if not shootStep(true) then notify("Sheriff", AutoShoot.Status, 2.5, "warn") end
        end)
    end)
    addKeybind(bt, "Toggle Fly", "fly", "F", flip("Fly", function() return flyToggle end))
    addKeybind(bt, "Toggle Noclip", "noclip", "N", flip("Noclip", function() return noclipToggle end))
    addKeybind(bt, "Toggle Speed", "speed", "X", flip("Speed", function() return speedToggle end))
    addKeybind(bt, "Toggle Infinite Jump", "infjump", "None", flip("Infinite Jump", function() return infJumpToggle end))
end

do -- CONFIG
    local ct = newTab("Config", "\u{1F381}")
    local function copyTable(t) local n = {} for k, v in pairs(t or {}) do n[k] = v end return n end

    -- applies a config table to the running script, live
    local function applyData(data)
        if type(data) ~= "table" then return false end
        local opts, toggles, sliders, bnds = copyTable(data.Opts), copyTable(data.Toggles), copyTable(data.Sliders), copyTable(data.Binds)
        for k, v in pairs(opts) do
            local f = registry.cycles[k]
            if f then f(v) else Config.Opts[k] = v end
        end
        for k, v in pairs(toggles) do local f = registry.toggles[k]; if f then f(v) end end
        for k, v in pairs(sliders) do local f = registry.sliders[k]; if f then f(v) end end
        for k, v in pairs(bnds) do local f = registry.binds[k]; if f then f(v) end end
        saveSoon()
        return true
    end

    local function cleanName(box)
        local n = (box.Text or ""):gsub("[^%w_%-]", "")
        if n == "" then n = "default" end
        return n
    end

    addLabel(ct, "Profiles (saved in your executor workspace)")
    addInfo(ct, "Everything you change is auto-saved. Profiles are extra named slots.")
    local nameBox = addTextBox(ct, "profile name", "Profile name (letters, numbers, _ or -)", "default")
    addButton(ct, "Save Profile", function()
        if not writefile then return notify("Config", "Your executor has no writefile", 3, "error") end
        local n = cleanName(nameBox)
        writefile(PROFILE_PREFIX .. n .. ".json", HttpService:JSONEncode(Config))
        notify("Config", "Saved profile '" .. n .. "'", 2.5, "success")
    end)
    addButton(ct, "Load Profile", function()
        local n = cleanName(nameBox)
        local file = PROFILE_PREFIX .. n .. ".json"
        if not (isfile and readfile and isfile(file)) then return notify("Config", "No profile named '" .. n .. "'", 3, "warn") end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
        if ok and applyData(data) then notify("Config", "Loaded '" .. n .. "' (applied live)", 3, "success")
        else notify("Config", "That profile file is damaged", 3, "error") end
    end)
    addButton(ct, "Delete Profile", function()
        local n = cleanName(nameBox)
        local file = PROFILE_PREFIX .. n .. ".json"
        if delfile and isfile and isfile(file) then delfile(file); notify("Config", "Deleted '" .. n .. "'", 2.5, "success")
        else notify("Config", "Nothing to delete", 2.5, "warn") end
    end)
    addButton(ct, "List Saved Profiles", function()
        if not listfiles then return notify("Config", "Your executor has no listfiles", 3, "warn") end
        local names = {}
        local ok, files = pcall(listfiles, "")
        if not ok then ok, files = pcall(listfiles, ".") end
        if ok and type(files) == "table" then
            for _, f in ipairs(files) do
                local n = tostring(f):match(PROFILE_PREFIX .. "([%w_%-]+)%.json$")
                if n then table.insert(names, n) end
            end
        end
        notify("Profiles", #names > 0 and table.concat(names, ", ") or "No saved profiles yet", 5)
    end)

    addLabel(ct, "Share with friends")
    local shareBox
    shareBox = addTextBox(ct, "your share code", "Your share code appears here", "")
    addButton(ct, "Generate and Copy Share Code", function()
        local code = "VORTEX1:" .. b64enc(HttpService:JSONEncode(Config))
        shareBox.Text = code
        if setclipboard then
            setclipboard(code)
            notify("Config", "Share code copied. Send it to a friend", 3, "success")
        else
            notify("Config", "No clipboard here. Copy the code from the box", 4, "warn")
        end
    end)
    addTextBox(ct, "paste a share code", "Paste a share code here, press Enter to import", "", function(box)
        local raw = (box.Text or ""):gsub("%s", "")
        if raw == "" then return end
        local json
        if raw:sub(1, 8) == "VORTEX1:" then
            local ok, dec = pcall(b64dec, raw:sub(9))
            if ok then json = dec end
        else
            json = raw
        end
        local ok, data = pcall(function() return HttpService:JSONDecode(json or "") end)
        if ok and type(data) == "table" and applyData(data) then
            box.Text = ""
            notify("Config", "Imported and applied live", 3, "success")
        else
            notify("Config", "That is not a valid share code", 3, "error")
        end
    end)

    addLabel(ct, "Danger zone")
    addButton(ct, "Reset Saved Config (re-execute after)", function()
        Config.Binds, Config.Opts, Config.Toggles, Config.Sliders = {}, {}, {}, {}
        saveConfig()
        notify("Config", "Reset. Re-execute the script for defaults", 3.5, "warn")
    end)
end

do -- SETTINGS
    local st = newTab("Settings", "\u{2699}")
    addLabel(st, "Appearance")
    addCycle(st, "Theme", "theme", ThemeNames, "Christmas", setTheme)
    addCycle(st, "Accent", "accent", AccentNames, "Holly Red", function(n) setAccent(Accents[n]) end, Accents)
    addLabel(st, "Christmas decorations")
    addToggle(st, "Snowfall", true, function(on) Fest.Snow = on end, "Falling snow inside the window")
    addToggle(st, "Christmas Lights", true, function(on) Fest.Lights = on end, "Twinkling garland along the top")
    addToggle(st, "Candy-cane Border", true, function(on) Fest.Border = on; applyTheme() end, "Animated red and white window border")
    addLabel(st, "Notifications")
    addToggle(st, "Bind Notifications", true, function(on) Fest.BindNotify = on end, "Pop-up when a keybind turns something on or off")
    addLabel(st, "Sounds")
    addToggle(st, "UI Sounds", true, function(on) SoundCfg.On = on end, "Click sounds on buttons, toggles and sliders")
    addToggle(st, "Hover Sounds", false, function(on) SoundCfg.Hover = on end, "Soft tick when you hover a button")
    addSlider(st, "Sound Volume %", 0, 100, 60, function(v) SoundCfg.Vol = v / 100 end)
    addLabel(st, "Misc")
    addToggle(st, "Anti-AFK", true, function(on) AntiAFK = on end, "Stops Roblox from kicking you for idling")
    addButton(st, "Rejoin Server", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    addButton(st, "Server Hop", serverHop)
    addButton(st, "Copy Server Job ID", function()
        if setclipboard then setclipboard(game.JobId); notify("Copied", "Job ID copied", 2.5, "success")
        else notify("Unsupported", "Your executor has no setclipboard", 3, "warn") end
    end)
    addLabel(st, "Script")
    addButton(st, "Unload " .. HUB_NAME, function() gui:Destroy() end)
end

------------------------------------------------------------------
-- BACKGROUND LOOPS
------------------------------------------------------------------
do
    local frames, last = 0, os.clock()
    connect(RunService.RenderStepped, function()
        frames += 1
        if os.clock() - last >= 1 then
            local fps = frames
            frames, last = 0, os.clock()
            local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
            local pingText = ok and (math.floor(ping) .. " ms") or "n/a"
            fpsLabel.Text = "FPS: " .. fps
            pingLabel.Text = "Ping: " .. pingText
            setStatus("FPS " .. fps .. "   |   Ping " .. pingText .. "   |   Players " .. #Players:GetPlayers()
                .. "   |   Role " .. (myRoleName()),
                "Hide UI: " .. (binds.ui and binds.ui.key or "RightShift"))
        end
    end)
end

task.spawn(function()
    while gui.Parent do
        pcall(refreshRoles)
        local m, s, alive, total = "none", "none", 0, 0
        for name, info in pairs(Roles) do
            total += 1
            if not info.Dead then alive += 1 end
            if info.Role == "Murderer" then m = name elseif info.Role == "Sheriff" or info.Role == "Hero" then s = name end
        end
        murdLabel.Text = "Murderer: " .. m
        sherLabel.Text = "Sheriff / Hero: " .. s
        aliveLabel.Text = "Alive: " .. alive .. " / " .. total
        gunLabel.Text = "Gun drop: " .. ((gunDrop and gunDrop.Parent) and "ON THE GROUND" or "none")
        task.wait(1.5)
    end
end)

------------------------------------------------------------------
-- CLEANUP + START
------------------------------------------------------------------
gui.Destroying:Connect(function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    Move.SpeedOn, Move.JumpOn, Move.Noclip, Move.Fly = false, false, false, false
    AutoShoot.Enabled = false
    stopFly()
    pcall(setWorldSnow, false)
    local h = getHum()
    if h then h.WalkSpeed = 16; h.JumpPower = 50 end
    restoreLighting()
    pcall(function() bubble:Destroy() end)
end)

applyTheme()
selectTab("Home")
root.Position = root.Position + UDim2.fromOffset(0, 14)
main.GroupTransparency = 1
shadow.ImageTransparency = 1
tween(main, { GroupTransparency = 0 }, 0.3)
tween(shadow, { ImageTransparency = 0.4 }, 0.3)
tween(root, { Position = root.Position - UDim2.fromOffset(0, 14) }, 0.3, Enum.EasingStyle.Back)
notify("Merry Christmas! " .. HUB_NAME .. " loaded", "Press " .. (binds.ui and binds.ui.key or "RightShift") .. " to show or hide", 4, "success")
if game.PlaceId ~= 142823291 then
    task.delay(1.5, function() notify("Heads up", "This edition is built for Murder Mystery 2", 4, "warn") end)
end
