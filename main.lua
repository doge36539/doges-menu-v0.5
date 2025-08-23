--// Doge’s Menu v3.3 (Dark Kavo, Drawing API) //--

--// Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Doge's Menu v3.3", "DarkTheme")

--// Tabs
local MovementTab = Window:NewTab("Movement")
local CombatTab   = Window:NewTab("Combat")
local VisualsTab  = Window:NewTab("Visuals")
local UtilitiesTab= Window:NewTab("Utilities")
local SettingsTab = Window:NewTab("Settings")

--// Sections
local MovementSection = MovementTab:NewSection("Player Movement")
local VerticalSection = MovementTab:NewSection("Vertical Movement")
local CombatSection   = CombatTab:NewSection("Combat")
local VisualsSection  = VisualsTab:NewSection("ESP Options")
local UtilitiesSection= UtilitiesTab:NewSection("Utilities")
local SettingsSection = SettingsTab:NewSection("ESP Settings")

--// Toggles & Vars
local Toggles = {
    WalkSpeed = 16,
    JumpPower = 50,
    PlayerFOV = 70,
    Noclip = false,
    Aimbot = false,
    FOVCircle = false,
    ESP_Box = false,
    ESP_Name = false,
    ESP_Health = false,
    ESP_Chams = false,
}

local StudsUp = 10
local StudsDown = 10
local ESPColor = Color3.fromRGB(0,255,0)
local ESPOpacity = {
    Box = 1,
    Name = 1,
    Health = 1,
    Chams = 0.5,
}
local FOVSize = 100

--// WalkSpeed + Safety Check
MovementSection:NewSlider("WalkSpeed", "Sets WalkSpeed", 500, 16, function(val)
    if val > 180 then
        Library:Notify("Warning: WalkSpeed above 180 may flag!")
    end
    Toggles.WalkSpeed = val
    LocalPlayer.Character.Humanoid.WalkSpeed = val
end)

MovementSection:NewSlider("JumpPower", "Sets JumpPower", 300, 50, function(val)
    Toggles.JumpPower = val
    LocalPlayer.Character.Humanoid.JumpPower = val
end)

MovementSection:NewSlider("Player FOV", "Sets Field of View", 120, 70, function(val)
    Toggles.PlayerFOV = val
    Camera.FieldOfView = val
end)

--// Go Up / Go Down with TextBox + Button
VerticalSection:NewTextBox("Go Up Studs", "Set studs to go up", tostring(StudsUp), function(val)
    local num = tonumber(val)
    if num then StudsUp = num end
end)
VerticalSection:NewButton("Go Up", "Moves you upward", function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = hrp.CFrame + Vector3.new(0, StudsUp, 0)
    end
end)

VerticalSection:NewTextBox("Go Down Studs", "Set studs to go down", tostring(StudsDown), function(val)
    local num = tonumber(val)
    if num then StudsDown = num end
end)
VerticalSection:NewButton("Go Down", "Moves you downward", function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = hrp.CFrame + Vector3.new(0, -StudsDown, 0)
    end
end)

--// Noclip Toggle + Keybind (Hold N)
MovementSection:NewToggle("Noclip (Hold N)", "Hold N while toggle is on", function(state)
    Toggles.Noclip = state
end)

local holdingN = false

UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.N then
        holdingN = true
    end
end)

UIS.InputEnded:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.N then
        holdingN = false
        -- reset collisions when N is released
        if LocalPlayer.Character then
            for _,part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end)

--// Combat
CombatSection:NewToggle("Aimbot (RMB)", "Locks onto enemies with RMB", function(state)
    Toggles.Aimbot = state
end)
CombatSection:NewToggle("FOV Circle", "Toggle FOV Circle", function(state)
    Toggles.FOVCircle = state
end)
CombatSection:NewSlider("FOV Size", "Adjust FOV Circle Size", 500, 100, function(val)
    FOVSize = val
end)

--// Visuals (ESP)
VisualsSection:NewToggle("Box ESP", "Shows 2D box", function(state) Toggles.ESP_Box = state end)
VisualsSection:NewSlider("Box Opacity", "Opacity for Box", 100, 100, function(val)
    ESPOpacity.Box = val/100
end)

VisualsSection:NewToggle("Name ESP", "Shows player names", function(state) Toggles.ESP_Name = state end)
VisualsSection:NewSlider("Name Opacity", "Opacity for Names", 100, 100, function(val)
    ESPOpacity.Name = val/100
end)

VisualsSection:NewToggle("Health ESP", "Shows health bars", function(state) Toggles.ESP_Health = state end)
VisualsSection:NewSlider("Health Opacity", "Opacity for Health", 100, 100, function(val)
    ESPOpacity.Health = val/100
end)

VisualsSection:NewToggle("Chams ESP", "Shows through walls", function(state) Toggles.ESP_Chams = state end)
VisualsSection:NewSlider("Chams Opacity", "Opacity for Chams", 100, 50, function(val)
    ESPOpacity.Chams = val/100
end)

--// Utilities
UtilitiesSection:NewButton("Rejoin", "Rejoins current server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
UtilitiesSection:NewButton("Server Hop", "Hops to another server", function()
    TeleportService:Teleport(game.PlaceId)
end)
UtilitiesSection:NewButton("Reset Character", "Respawns your character", function()
    LocalPlayer.Character:BreakJoints()
end)

--// Settings
SettingsSection:NewColorPicker("ESP Color", "Pick ESP Color", ESPColor, function(c)
    ESPColor = c
end)

--// ESP + Drawing Loop
local function CreateDrawing(type, props)
    local obj = Drawing.new(type)
    for i,v in pairs(props) do obj[i] = v end
    return obj
end

local FOVCircle = CreateDrawing("Circle", {
    Visible = false,
    Radius = FOVSize,
    Thickness = 1,
    Color = ESPColor,
    NumSides = 64,
    Filled = false,
    Transparency = 1
})

--// Aimbot hold state
local aiming = false
UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    end
end)
UIS.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

RunService.RenderStepped:Connect(function()
    -- FOV
    FOVCircle.Radius = FOVSize
    FOVCircle.Visible = Toggles.FOVCircle
    FOVCircle.Color = ESPColor
    FOVCircle.Position = UIS:GetMouseLocation()

    -- Noclip (only when toggle is on AND N is held)
    if Toggles.Noclip and holdingN and LocalPlayer.Character then
        for _,part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- Aimbot (continuous while holding RMB)
    if Toggles.Aimbot and aiming then
        local closest, dist = nil, math.huge
        for _,plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("Head") then
                local pos,vis = Camera:WorldToViewportPoint(plr.Character.Head.Position)
                if vis then
                    local mousePos = UIS:GetMouseLocation()
                    local mag = (Vector2.new(pos.X,pos.Y)-mousePos).Magnitude
                    if mag < dist and mag < FOVSize then
                        closest, dist = plr, mag
                    end
                end
            end
        end
        if closest then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position)
        end
    end

    -- ESP loop
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChild("Humanoid")

            local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
            if vis then
                if Toggles.ESP_Name then
                    local nameTag = CreateDrawing("Text", {
                        Text = plr.Name,
                        Position = Vector2.new(pos.X, pos.Y - 40),
                        Size = 13,
                        Center = true,
                        Color = ESPColor,
                        Transparency = ESPOpacity.Name,
                        Visible = true
                    })
                    task.delay(0.01,function() nameTag:Remove() end)
                end
                if Toggles.ESP_Health and hum then
                    local hpFrac = hum.Health / hum.MaxHealth
                    local hpBar = CreateDrawing("Square", {
                        Position = Vector2.new(pos.X - 25, pos.Y - 55),
                        Size = Vector2.new(50 * hpFrac, 6),
                        Color = Color3.fromRGB(0,255,0),
                        Filled = true,
                        Transparency = ESPOpacity.Health,
                        Visible = true
                    })
                    task.delay(0.01,function() hpBar:Remove() end)
                end
                if Toggles.ESP_Box and head then
                    local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
                    local hrpPos = Camera:WorldToViewportPoint(hrp.Position)
                    local boxHeight = math.abs(headPos.Y - hrpPos.Y)
                    local boxWidth = boxHeight / 2
                    local box = CreateDrawing("Square", {
                        Position = Vector2.new(headPos.X - boxWidth/2, headPos.Y),
                        Size = Vector2.new(boxWidth, boxHeight),
                        Color = ESPColor,
                        Thickness = 1,
                        Transparency = ESPOpacity.Box,
                        Visible = true
                    })
                    task.delay(0.01,function() box:Remove() end)
                end
                if Toggles.ESP_Chams then
                    for _,part in pairs(plr.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 1 - ESPOpacity.Chams
                            part.Color = ESPColor
                        end
                    end
                end
            end
        end
    end
end)
