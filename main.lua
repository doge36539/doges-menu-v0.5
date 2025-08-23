--// Doge's Menu
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Doge's Menu", "DarkTheme")

-- Vars
local wsLoop
local currentWS = 16
local uiVisible = true

-- ESP state
local espObjects = {names = {}, chams = {}}
local chamOpacity = 0.5
local chamColor = nil
local nameColor = nil

-- Notify helper
local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Doge's Menu",
            Text = text,
            Duration = 3
        })
    end)
end

notify("Doge's Menu Loaded - Press F6 to toggle")

-- === Find the Kavo ScreenGui reliably ===
local function findMenuGui()
    local sg = game.CoreGui:FindFirstChild("Doge's Menu")
    if sg and sg:IsA("ScreenGui") then return sg end
    for _, inst in ipairs(game.CoreGui:GetChildren()) do
        if inst:IsA("ScreenGui") then
            local n = inst.Name:lower()
            if n:find("kavo") or n:find("doge") then
                return inst
            end
        end
    end
    for _, d in ipairs(game.CoreGui:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text == "Doge's Menu" then
            local sg2 = d:FindFirst
