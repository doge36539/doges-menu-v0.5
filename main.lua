--// Doge's Menu v3.9 (Dark Kavo, enemy-only ESP, dynamic HP bar, X=toggle) --

--// Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Doge's Menu v3.9", "DarkTheme")

-- Hook the library's close/X to toggle instead of unload/hard close
local Hooked = setmetatable({}, {__mode = "k"})
local function hookCloseButtons(root)
    root = root or CoreGui
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextButton") then
            local okText = pcall(function() return obj.Text end)
            local t = okText and (obj.Text or "") or ""
            local name = obj.Name and string.lower(obj.Name) or ""
            if (t == "X" or name:find("close") or name:find("exit")) and not Hooked[obj] then
                Hooked[obj] = true
                obj.MouseButton1Click:Connect(function()
                    pcall(function() Library:ToggleUI() end)
                end)
            end
        end
    end
end
hookCloseButtons(CoreGui)
CoreGui.DescendantAdded:Connect(function(inst)
    if inst:IsA("TextButton") then hookCloseButtons(inst) end
end)

--// Tabs + Sections
local MovementTab = Window:NewTab("Movement")
local CombatTab = Window:NewTab("Combat")
local VisualsTab = Window:NewTab("Visuals")
local UtilitiesTab = Window:NewTab("Utilities")
local SettingsTab = Window:NewTab("Settings")

local MovementSection = MovementTab:NewSection("Player Movement")
local VerticalSection = MovementTab:NewSection("Vertical Movement")
local CombatSection = CombatTab:NewSection("Aimbot")
local VisualsSection = VisualsTab:NewSection("ESP / Chams")
local UtilsSection = UtilitiesTab:NewSection("Utilities")
local SettingsSection = SettingsTab:NewSection("UI / Options")

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function isEnemy(plr)
    if LocalPlayer.Team and plr.Team then
        return plr.Team ~= LocalPlayer.Team
    end
    return plr ~= LocalPlayer
end

local function getHumanoid(char)
    return char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid"))
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function hpColor(frac)
    -- 0 -> red(1,0,0), 1 -> green(0,1,0)
    return Color3.new(1 - frac, frac, 0)
end

----------------------------------------------------------------
-- Movement
----------------------------------------------------------------
-- WalkSpeed (loop while on, reset on off)
local WalkEnabled = false
local WalkValue = 16
MovementSection:NewToggle("WalkSpeed", "Toggle WalkSpeed loop", function(state)
    WalkEnabled = state
    if not state and LocalPlayer.Character then
        local hum = getHumanoid(LocalPlayer.Character)
        if hum then hum.WalkSpeed = 16 end
    end
end)
MovementSection:NewSlider("WalkSpeed Value", "Set WalkSpeed", 200, 0, function(val)
    WalkValue = val
end)
RunService.RenderStepped:Connect(function()
    if WalkEnabled and LocalPlayer.Character then
        local hum = getHumanoid(LocalPlayer.Character)
        if hum and hum.WalkSpeed ~= WalkValue then
            hum.WalkSpeed = WalkValue
        end
    end
end)

-- Noclip (toggle + hold N)
local NoclipEnabled = false
MovementSection:NewToggle("Noclip (Hold N)", "Toggle on, then hold N to phase", function(state)
    NoclipEnabled = state
end)
RunService.Stepped:Connect(function()
    if NoclipEnabled and UIS:IsKeyDown(Enum.KeyCode.N) and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Vertical Up/Down
local UpStuds, DownStuds = 10, 10
VerticalSection:NewTextBox("Go Up Studs", "Studs to go up", tostring(UpStuds), function(v)
    local n = tonumber(v); if n then UpStuds = n end
end)
VerticalSection:NewButton("Go Up", "Moves you upward", function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, UpStuds, 0) end
end)
VerticalSection:NewTextBox("Go Down Studs", "Studs to go down", tostring(DownStuds), function(v)
    local n = tonumber(v); if n then DownStuds = n end
end)
VerticalSection:NewButton("Go Down", "Moves you downward", function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, -DownStuds, 0) end
end)

----------------------------------------------------------------
-- Combat: Aimbot + FOV Circle
----------------------------------------------------------------
local AimbotEnabled = false
local AimbotFOV = 100
local ShowFOVCircle = false
local CustomColor = Color3.fromRGB(255,255,255)

-- FOV circle via Drawing
local FOVCircle do
    local ok, obj = pcall(function() return Drawing.new("Circle") end)
    if ok and obj then
        FOVCircle = obj
        FOVCircle.Visible = false
        FOVCircle.Radius = AimbotFOV
        FOVCircle.Thickness = 1.5
        FOVCircle.NumSides = 64
        FOVCircle.Filled = false
        FOVCircle.Color = CustomColor
    else
        FOVCircle = nil
    end
end

CombatSection:NewToggle("Aimbot (Hold RMB)", "Enemy-only lock to closest head within FOV", function(state)
    AimbotEnabled = state
end)
CombatSection:NewSlider("FOV Radius", "Aimbot radius (px)", 500, 50, function(val)
    AimbotFOV = val
end)
CombatSection:NewToggle("Show FOV Circle", "Draw the aimbot radius on screen", function(state)
    ShowFOVCircle = state
    if FOVCircle then FOVCircle.Visible = state end
end)

local function getClosestEnemyInFOV(radius)
    local mouse = UIS:GetMouseLocation()
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isEnemy(plr) and plr.Character and plr.Character:FindFirstChild("Head") then
            local pos, vis = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if vis then
                local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                if d < bestDist and d <= radius then
                    best, bestDist = plr, d
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if FOVCircle then
        FOVCircle.Visible = ShowFOVCircle
        if ShowFOVCircle then
            FOVCircle.Position = UIS:GetMouseLocation()
            FOVCircle.Radius = AimbotFOV
            FOVCircle.Color = CustomColor
        end
    end

    if AimbotEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestEnemyInFOV(AimbotFOV)
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end
end)

----------------------------------------------------------------
-- Visuals: Enemy-only ESP (Name, Box, Health) + Chams
----------------------------------------------------------------
local ESP = {
    Enabled = {Name = false, Box = false, Health = false, Chams = false},
    Opacity = {Name = 1, Box = 1, Health = 1, Chams = 0.5}
}

-- Toggles + Sliders
VisualsSection:NewToggle("Name ESP (Enemies)", "Show enemy names", function(s) ESP.Enabled.Name = s end)
VisualsSection:NewSlider("Name Opacity", "Opacity for names", 100, 0, function(v) ESP.Opacity.Name = v/100 end)

VisualsSection:NewToggle("Box ESP (Enemies)", "Draw boxes around enemies", function(s) ESP.Enabled.Box = s end)
VisualsSection:NewSlider("Box Opacity", "Opacity for boxes", 100, 0, function(v) ESP.Opacity.Box = v/100 end)

VisualsSection:NewToggle("Health ESP (Enemies)", "Enemy health bars (dynamic color)", function(s) ESP.Enabled.Health = s end)
VisualsSection:NewSlider("Health Opacity", "Opacity for health bars", 100, 0, function(v) ESP.Opacity.Health = v/100 end)

VisualsSection:NewToggle("Chams ESP (Enemies)", "Full-body highlight for enemies", function(s) ESP.Enabled.Chams = s end)
VisualsSection:NewSlider("Chams Opacity", "Opacity for chams", 100, 0, function(v) ESP.Opacity.Chams = v/100 end)

-- Name color override lives in Settings (not Visuals)
local NameOverride = {Enabled = false, Color = Color3.fromRGB(255,255,255)}

-- Highlight system for Chams (enemy-only)
local function ensureHighlight(char)
    if not char then return nil end
    local h = char:FindFirstChild("ChamHighlight")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "ChamHighlight"
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = char
    end
    return h
end

-- Drawing cache for Name/Box/Health ESP
local Drawings = {}

local function destroyDrawingFor(plr)
    local t = Drawings[plr]
    if not t then return end
    for _, obj in pairs(t) do
        pcall(function() if obj then obj.Visible = false obj:Remove() end end)
    end
    Drawings[plr] = nil
end

local function getDrawing(plr)
    if not Drawings[plr] then
        local okText, nameObj = pcall(function() return Drawing.new("Text") end)
        local okBox, boxObj = pcall(function() return Drawing.new("Square") end)
        local okBG, hpBG = pcall(function() return Drawing.new("Square") end)
        local okFG, hpFG = pcall(function() return Drawing.new("Square") end)

        Drawings[plr] = {
            Name = okText and nameObj or nil,
            Box = okBox and boxObj or nil,
            HealthBG = okBG and hpBG or nil,
            HealthFG = okFG and hpFG or nil
        }
        local d = Drawings[plr]
        if d.Name then d.Name.Size = 32; d.Name.Center = true; d.Name.Outline = true end -- 2x size
        if d.Box then d.Box.Thickness = 3; d.Box.Filled = false end -- double thickness
        if d.HealthBG then d.HealthBG.Filled = true end
        if d.HealthFG then d.HealthFG.Filled = true end
    end
    return Drawings[plr]
end

-- Cleanup when players leave
Players.PlayerRemoving:Connect(function(plr)
    destroyDrawingFor(plr)
end)

-- Character lifecycle helper
local function onCharacterAdded(plr, char)
    if not char then return end
    char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            local h = char:FindFirstChild("ChamHighlight")
            if h then h:Destroy() end
        end
    end)
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        onCharacterAdded(plr, char)
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        if plr.Character then onCharacterAdded(plr, plr.Character) end
        plr.CharacterAdded:Connect(function(char) onCharacterAdded(plr, char) end)
    end
end

-- ESP update loop (every frame, enemy-only, new joiners handled, cleans up)
RunService.RenderStepped:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local drawings = getDrawing(plr)
            local char = plr.Character
            local head = char and char:FindFirstChild("Head")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = getHumanoid(char)

            -- Default hide
            if drawings.Name then drawings.Name.Visible = false end
            if drawings.Box then drawings.Box.Visible = false end
            if drawings.HealthBG then drawings.HealthBG.Visible = false end
            if drawings.HealthFG then drawings.HealthFG.Visible = false end

            if char and head and hrp and hum and hum.Health > 0 and isEnemy(plr) then
                local posH, onH = Camera:WorldToViewportPoint(head.Position)
                local posC, onC = Camera:WorldToViewportPoint(hrp.Position)
                if onH or onC then
                    -- Scale from depth
                    local z = math.max(posC.Z, 0.1)
                    local scale = math.clamp(2 / z, 0, 4)
                    local w, h = 1000 * scale * 1.3, 2000 * scale * 1.3 -- 1.3x box size
                    local boxPos = Vector2.new(posC.X - w/2, posC.Y - h/2)

                    -- Name color (global or override)
                    local nameColor = NameOverride.Enabled and NameOverride.Color or CustomColor

                    -- Name (2x size already set). Position just above head
                    if ESP.Enabled.Name and drawings.Name then
                        drawings.Name.Visible = true
                        drawings.Name.Text = plr.Name
                        drawings.Name.Color = nameColor
                        drawings.Name.Transparency = ESP.Opacity.Name
                        drawings.Name.Position = Vector2.new(posH.X, posH.Y - 20) -- just above head
                    end

                    -- Health bar (horizontal, 3x thickness) above the name
                    if ESP.Enabled.Health and drawings.HealthBG and drawings.HealthFG then
                        local hpFrac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        local barW = math.max(60, w) -- at least 60px, generally width of the box
                        local barH = 9 -- 3x size vs typical ~3px
                        local gap = 6 -- gap above name
                        local barX = posH.X - (barW/2)
                        local barY = (ESP.Enabled.Name and (posH.Y - 20 - gap - barH)) or (boxPos.Y - 12)

                        -- background
                        drawings.HealthBG.Visible = true
                        drawings.HealthBG.Size = Vector2.new(barW, barH)
                        drawings.HealthBG.Position = Vector2.new(barX, barY)
                        drawings.HealthBG.Color = Color3.new(0.1, 0.1, 0.1)
                        drawings.HealthBG.Transparency = math.clamp(ESP.Opacity.Health, 0, 1)

                        -- foreground (hp portion)
                        drawings.HealthFG.Visible = true
                        drawings.HealthFG.Size = Vector2.new(barW * hpFrac, barH)
                        drawings.HealthFG.Position = Vector2.new(barX, barY)
                        drawings.HealthFG.Color = hpColor(hpFrac)
                        drawings.HealthFG.Transparency = math.clamp(ESP.Opacity.Health, 0, 1)
                    end

                    -- Box ESP (double line thickness already set)
                    if ESP.Enabled.Box and drawings.Box then
                        drawings.Box.Visible = true
                        drawings.Box.Size = Vector2.new(w, h)
                        drawings.Box.Position = boxPos
                        drawings.Box.Color = CustomColor
                        drawings.Box.Transparency = ESP.Opacity.Box
                    end

                    -- Chams (enemy-only)
                    if ESP.Enabled.Chams then
                        local highlight = ensureHighlight(char)
                        if highlight then
                            highlight.FillColor = CustomColor
                            highlight.OutlineColor = Color3.new(0,0,0)
                            highlight.FillTransparency = 1 - ESP.Opacity.Chams
                            highlight.OutlineTransparency = 0
                        end
                    else
                        local hlt = char:FindFirstChild("ChamHighlight")
                        if hlt then hlt:Destroy() end
                    end
                else
                    -- off-screen: destroy chams if off
                    if char then
                        local hlt = char:FindFirstChild("ChamHighlight")
                        if hlt and not ESP.Enabled.Chams then hlt:Destroy() end
                    end
                end
            else
                -- teammate/dead/invalid: remove chams if present
                if char then
                    local hlt = char:FindFirstChild("ChamHighlight")
                    if hlt then hlt:Destroy() end
                end
            end
        end
    end
end)

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------
UtilsSection:NewButton("Rejoin", "Rejoin this server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

UtilsSection:NewButton("Force Kill", "Break your own Humanoid instantly", function()
    local hum = getHumanoid(LocalPlayer.Character)
    if hum then hum.Health = 0 end
end)

-- FPS Cap Slider (safe check)
UtilsSection:NewSlider("FPS Cap", "Set FPS limit", 240, 30, function(v)
    if typeof(setfpscap) == "function" then
        pcall(function() setfpscap(v) end)
    end
end)

-- Low Graphics
local LowGFX = false
UtilsSection:NewToggle("Low Graphics", "Potato mode", function(state)
    LowGFX = state
    if state then
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
    else
        pcall(function()
            Lighting.GlobalShadows = true
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end)
    end
end)

----------------------------------------------------------------
-- Settings
----------------------------------------------------------------
SettingsSection:NewKeybind("Toggle UI (F6)", "Show/Hide menu", Enum.KeyCode.F6, function()
    Library:ToggleUI()
end)

SettingsSection:NewColorPicker("Global ESP & FOV Color", "Set universal color", CustomColor, function(c)
    CustomColor = c
end)

-- Name ESP Override lives here (not in Visuals)
SettingsSection:NewToggle("Name Color Override", "Use a custom color for Name ESP instead of Global", function(s)
    NameOverride.Enabled = s
end)

SettingsSection:NewColorPicker("Name ESP Override Color", "Pick the Name ESP color (when override is ON)", NameOverride.Color, function(c)
    NameOverride.Color = c
end)
----------------------------------------------------------------
-- Utilities Upgrades
----------------------------------------------------------------

-- Anti-AFK
local vu = game:GetService("VirtualUser")
UtilsSection:NewToggle("Anti-AFK", "Prevents idle kick", function(state)
    if state then
        LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end
end)

-- Server Hop (finds lowest player server)
local HttpService = game:GetService("HttpService")
UtilsSection:NewButton("Server Hop", "Join a new server", function()
    local servers = {}
    local req = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        servers = HttpService:JSONDecode(game:HttpGet(url)).data
    end)
    if req and #servers > 0 then
        for _,srv in ipairs(servers) do
            if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                break
            end
        end
    end
end)

----------------------------------------------------------------
-- Movement Upgrade: Custom Gravity (Default → 0.1)
----------------------------------------------------------------
local GravityLoop = false
local GravityVal = workspace.Gravity
local DefaultGravity = 196.2

MovementSection:NewToggle("Gravity Loop", "Forces Gravity to stay set", function(state)
    GravityLoop = state
    if not state then
        workspace.Gravity = DefaultGravity
    end
end)

MovementSection:NewSlider("Custom Gravity", "Change world gravity", DefaultGravity, 0.1, function(val)
    GravityVal = val
    if GravityLoop then
        workspace.Gravity = GravityVal
    end
end)

RunService.RenderStepped:Connect(function()
    if GravityLoop and workspace.Gravity ~= GravityVal then
        workspace.Gravity = GravityVal
    end
end)

RunService.RenderStepped:Connect(function()
    if GravityLoop and workspace.Gravity ~= LowGravity then
        workspace.Gravity = LowGravity
    end
end)

----------------------------------------------------------------
-- Combat Upgrades: Smooth Aimbot + Priority + Toggle
----------------------------------------------------------------
local AimbotToggleKey = Enum.KeyCode.R -- can be changed in Settings
local AimbotToggled = false
local AimbotSmoothness = 0.25
local AimbotPriority = "Closest" -- "Closest" or "LowestHP"

CombatSection:NewSlider("Smoothness", "How smoothly aim follows (0=snappy)", 100, 0, function(val)
    AimbotSmoothness = val/100
end)

CombatSection:NewDropdown("Priority", "Target priority system", {"Closest", "LowestHP"}, function(opt)
    AimbotPriority = opt
end)

CombatSection:NewKeybind("Aimbot Toggle Key", "Keybind to toggle aimbot (on/off)", AimbotToggleKey, function()
    AimbotToggled = not AimbotToggled
end)

-- Modify target finder
local function getBestTarget(radius)
    local mouse = UIS:GetMouseLocation()
    local best, bestScore = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isEnemy(plr) and plr.Character and plr.Character:FindFirstChild("Head") then
            local pos, vis = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if vis then
                local dist2d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                if dist2d <= radius then
                    if AimbotPriority == "Closest" then
                        if dist2d < bestScore then
                            best, bestScore = plr, dist2d
                        end
                    elseif AimbotPriority == "LowestHP" then
                        local hum = getHumanoid(plr.Character)
                        if hum and hum.Health < bestScore then
                            best, bestScore = plr, hum.Health
                        end
                    end
                end
            end
        end
    end
    return best
end

-- Modify RenderStepped for aimbot
RunService.RenderStepped:Connect(function()
    if AimbotEnabled and (UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or AimbotToggled) then
        local target = getBestTarget(AimbotFOV)
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local headPos = target.Character.Head.Position
            local newCF = CFrame.new(Camera.CFrame.Position, headPos)
            if AimbotSmoothness > 0 then
                Camera.CFrame = Camera.CFrame:Lerp(newCF, AimbotSmoothness)
            else
                Camera.CFrame = newCF
            end
        end
    end
end)
----------------------------------------------------------------
-- Movement Upgrades: Fly, Air Walk, Infinite Jump
----------------------------------------------------------------

--// Fly
local FlyEnabled = false
local FlySpeed = 50
local flyVel, flyGyro

MovementSection:NewToggle("Fly (Toggle)", "Classic smooth fly", function(state)
    FlyEnabled = state
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        if state then
            flyVel = Instance.new("BodyVelocity")
            flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyVel.Velocity = Vector3.zero
            flyVel.Parent = hrp

            flyGyro = Instance.new("BodyGyro")
            flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyGyro.CFrame = hrp.CFrame
            flyGyro.Parent = hrp
        else
            if flyVel then flyVel:Destroy() end
            if flyGyro then flyGyro:Destroy() end
        end
    end
end)

MovementSection:NewSlider("Fly Speed", "Speed while flying", 200, 10, function(val)
    FlySpeed = val
end)

RunService.RenderStepped:Connect(function()
    if FlyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local camCF = Camera.CFrame
        flyVel.Velocity = ((camCF.LookVector * (UIS:IsKeyDown(Enum.KeyCode.W) and FlySpeed or 0))
            + (-camCF.LookVector * (UIS:IsKeyDown(Enum.KeyCode.S) and FlySpeed or 0))
            + (camCF.RightVector * (UIS:IsKeyDown(Enum.KeyCode.D) and FlySpeed or 0))
            + (-camCF.RightVector * (UIS:IsKeyDown(Enum.KeyCode.A) and FlySpeed or 0)))
            + (Vector3.new(0,FlySpeed,0) * (UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0))
            + (Vector3.new(0,-FlySpeed,0) * (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0))

        flyGyro.CFrame = camCF
    end
end)

--// Air Walk
local AirWalkEnabled = false
local platform

MovementSection:NewToggle("Air Walk", "Walk in midair", function(state)
    AirWalkEnabled = state
    if not state and platform then
        platform:Destroy()
        platform = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if AirWalkEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if not platform then
            platform = Instance.new("Part")
            platform.Size = Vector3.new(50,1,50)
            platform.Anchored = true
            platform.Transparency = 1
            platform.CanCollide = true
            platform.Name = "AirWalkPlatform"
            platform.Parent = workspace
        end
        platform.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 3, 0))
    end
end)

--// Infinite Jump
local InfJumpEnabled = false

MovementSection:NewToggle("Infinite Jump", "Jump infinitely by pressing space", function(state)
    InfJumpEnabled = state
end)

UIS.JumpRequest:Connect(function()
    if InfJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
