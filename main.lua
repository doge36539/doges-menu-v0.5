--// Doge's Menu v3.9 (Dark Kavo, stable, enemy-only ESP + fixes) --

--// Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Doge's Menu v3.9", "DarkTheme")

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
    -- Enemy-only logic; if no teams are present, treat everyone as enemy
    if LocalPlayer.Team and plr.Team then
        return plr.Team ~= LocalPlayer.Team
    end
    return plr ~= LocalPlayer
end

local function getHumanoid(char)
    return char and (char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid"))
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

VisualsSection:NewToggle("Health ESP (Enemies)", "Enemy health bars", function(s) ESP.Enabled.Health = s end)
VisualsSection:NewSlider("Health Opacity", "Opacity for health bars", 100, 0, function(v) ESP.Opacity.Health = v/100 end)

VisualsSection:NewToggle("Chams ESP (Enemies)", "Full-body highlight for enemies", function(s) ESP.Enabled.Chams = s end)
VisualsSection:NewSlider("Chams Opacity", "Opacity for chams", 100, 0, function(v) ESP.Opacity.Chams = v/100 end)

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
        pcall(function() obj.Visible = false obj:Remove() end)
    end
    Drawings[plr] = nil
end

local function getDrawing(plr)
    if not Drawings[plr] then
        local okText, nameObj = pcall(function() return Drawing.new("Text") end)
        local okBox, boxObj = pcall(function() return Drawing.new("Square") end)
        local okLine, hpObj = pcall(function() return Drawing.new("Line") end)

        Drawings[plr] = {
            Name = okText and nameObj or nil,
            Box = okBox and boxObj or nil,
            Health = okLine and hpObj or nil
        }
        local d = Drawings[plr]
        if d.Name then d.Name.Size = 16; d.Name.Center = true; d.Name.Outline = true end
        if d.Box then d.Box.Thickness = 1.5; d.Box.Filled = false end
        if d.Health then d.Health.Thickness = 3 end
    end
    return Drawings[plr]
end

-- Cleanup when players leave
Players.PlayerRemoving:Connect(function(plr)
    destroyDrawingFor(plr)
end)

-- Also clear highlights on character remove
local function onCharacterAdded(plr, char)
    if not char then return end
    -- When character respawns and Chams are enabled, the highlight will be re-created in the main loop
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

-- Prime existing players
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        if plr.Character then onCharacterAdded(plr, plr.Character) end
        plr.CharacterAdded:Connect(function(char) onCharacterAdded(plr, char) end)
    end
end

-- ESP update loop (every frame, enemy-only, auto for new joiners, cleanup-safe)
RunService.RenderStepped:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local drawings = getDrawing(plr)
            local visibleAny = false

            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = getHumanoid(char)

            if char and hrp and hum and hum.Health > 0 and isEnemy(plr) then
                local pos, onscreen = Camera:WorldToViewportPoint(hrp.Position)
                if onscreen then
                    -- Compute box size from depth for more stable ESP
                    local scale = math.clamp(2 / math.max(pos.Z, 0.1), 0, 4)
                    local w, h = 1000 * scale, 2000 * scale
                    local boxPos = Vector2.new(pos.X - w/2, pos.Y - h/2)

                    -- Name ESP
                    if ESP.Enabled.Name and drawings.Name then
                        drawings.Name.Visible = true; visibleAny = true
                        drawings.Name.Text = plr.Name
                        drawings.Name.Color = CustomColor
                        drawings.Name.Transparency = ESP.Opacity.Name
                        drawings.Name.Position = Vector2.new(pos.X, boxPos.Y - 12)
                    else
                        if drawings.Name then drawings.Name.Visible = false end
                    end

                    -- Box ESP
                    if ESP.Enabled.Box and drawings.Box then
                        drawings.Box.Visible = true; visibleAny = true
                        drawings.Box.Size = Vector2.new(w, h)
                        drawings.Box.Position = boxPos
                        drawings.Box.Color = CustomColor
                        drawings.Box.Transparency = ESP.Opacity.Box
                    else
                        if drawings.Box then drawings.Box.Visible = false end
                    end

                    -- Health ESP (green bar along left of box)
                    if ESP.Enabled.Health and drawings.Health then
                        drawings.Health.Visible = true; visibleAny = true
                        local hpFrac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        drawings.Health.From = Vector2.new(boxPos.X - 6, boxPos.Y + h)
                        drawings.Health.To = Vector2.new(boxPos.X - 6, boxPos.Y + h - (h * hpFrac))
                        drawings.Health.Color = Color3.fromRGB(0,255,0)
                        drawings.Health.Transparency = ESP.Opacity.Health
                    else
                        if drawings.Health then drawings.Health.Visible = false end
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
                    if drawings.Name then drawings.Name.Visible = false end
                    if drawings.Box then drawings.Box.Visible = false end
                    if drawings.Health then drawings.Health.Visible = false end
                    local hlt = char and char:FindFirstChild("ChamHighlight")
                    if hlt and not ESP.Enabled.Chams then hlt:Destroy() end
                end
            else
                -- Not valid or teammate: hide drawings and remove highlight
                if drawings.Name then drawings.Name.Visible = false end
                if drawings.Box then drawings.Box.Visible = false end
                if drawings.Health then drawings.Health.Visible = false end
                if char then
                    local hlt = char:FindFirstChild("ChamHighlight")
                    if hlt then hlt:Destroy() end
                end
            end

            -- If none visible, keep them hidden (already handled above)
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
