-- ⚡ MIRACLE HUB ⚡
-- Fixed & Completed Version

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

if not getgenv then getgenv = function() return _G end end

-- =============================
-- STATE
-- =============================
local Enabled = {
    SpeedBoost = false,
    AntiRagdoll = false,
    HitCircle = false,
    Float = false,
    SpamBat = false,
    Helicopter = false,
    BatAimbot = false,
}

local Values = {
    BoostSpeed = 30,
    SpinSpeed = 30,
}

local Connections = {}

-- =============================
-- HELPERS
-- =============================
local function getChar()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function getHRP()
    local c = getChar()
    return c:WaitForChild("HumanoidRootPart")
end

local function findBat()
    local c = getChar()
    local bp = Player:FindFirstChildOfClass("Backpack")

    for _, v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") then return v end
    end

    if bp then
        for _, v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") then return v end
        end
    end
end

-- =============================
-- SPEED BOOST
-- =============================
function startSpeedBoost()
    if Connections.speed then return end

    Connections.speed = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedBoost then return end

        local hrp = getHRP()
        local hum = getChar():FindFirstChildOfClass("Humanoid")

        if hum.MoveDirection.Magnitude > 0 then
            hrp.Velocity = hum.MoveDirection * Values.BoostSpeed
        end
    end)
end

function stopSpeedBoost()
    if Connections.speed then
        Connections.speed:Disconnect()
        Connections.speed = nil
    end
end

-- =============================
-- SPAM BAT
-- =============================
function startSpamBat()
    if Connections.spam then return end

    Connections.spam = RunService.Heartbeat:Connect(function()
        if not Enabled.SpamBat then return end

        local bat = findBat()
        if bat then
            pcall(function()
                bat:Activate()
            end)
        end
    end)
end

function stopSpamBat()
    if Connections.spam then
        Connections.spam:Disconnect()
        Connections.spam = nil
    end
end

-- =============================
-- HELICOPTER
-- =============================
local spin

function startHelicopter()
    local hrp = getHRP()

    if spin then spin:Destroy() end

    spin = Instance.new("BodyAngularVelocity")
    spin.MaxTorque = Vector3.new(0, math.huge, 0)
    spin.AngularVelocity = Vector3.new(0, Values.SpinSpeed, 0)
    spin.Parent = hrp
end

function stopHelicopter()
    if spin then
        spin:Destroy()
        spin = nil
    end
end

-- =============================
-- FLOAT
-- =============================
local floatConn

function startFloat()
    if floatConn then return end

    floatConn = RunService.Heartbeat:Connect(function()
        if not Enabled.Float then return end

        local hrp = getHRP()
        hrp.Velocity = Vector3.new(0, 20, 0)
    end)
end

function stopFloat()
    if floatConn then
        floatConn:Disconnect()
        floatConn = nil
    end
end

-- =============================
-- HIT CIRCLE
-- =============================
local hitConn

function startHitCircle()
    if hitConn then return end

    hitConn = RunService.RenderStepped:Connect(function()
        if not Enabled.HitCircle then return end

        local hrp = getHRP()

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local enemy = p.Character:FindFirstChild("HumanoidRootPart")
                if enemy then
                    if (enemy.Position - hrp.Position).Magnitude < 8 then
                        local bat = findBat()
                        if bat then
                            bat:Activate()
                        end
                    end
                end
            end
        end
    end)
end

function stopHitCircle()
    if hitConn then
        hitConn:Disconnect()
        hitConn = nil
    end
end

-- =============================
-- BAT AIMBOT (FIXED)
-- =============================
local aimbotConn

local function getNearest()
    local hrp = getHRP()
    local nearest, dist = nil, math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local e = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")

            if e and h and h.Health > 0 then
                local d = (e.Position - hrp.Position).Magnitude
                if d < dist then
                    nearest = e
                    dist = d
                end
            end
        end
    end

    return nearest
end

function startBatAimbot()
    if aimbotConn then return end

    aimbotConn = RunService.RenderStepped:Connect(function()
        if not Enabled.BatAimbot then return end

        local hrp = getHRP()
        local target = getNearest()

        if target then
            hrp.CFrame = CFrame.lookAt(hrp.Position, target.Position)

            local bat = findBat()
            if bat then
                pcall(function()
                    bat:Activate()
                end)
            end
        end
    end)
end

function stopBatAimbot()
    if aimbotConn then
        aimbotConn:Disconnect()
        aimbotConn = nil
    end
end

-- =============================
-- SIMPLE KEYBINDS
-- =============================
UserInputService.InputBegan:Connect(function(i, g)
    if g then return end

    if i.KeyCode == Enum.KeyCode.V then
        Enabled.SpeedBoost = not Enabled.SpeedBoost
        if Enabled.SpeedBoost then startSpeedBoost() else stopSpeedBoost() end
    end

    if i.KeyCode == Enum.KeyCode.F then
        Enabled.Float = not Enabled.Float
        if Enabled.Float then startFloat() else stopFloat() end
    end

    if i.KeyCode == Enum.KeyCode.X then
        Enabled.BatAimbot = not Enabled.BatAimbot
        if Enabled.BatAimbot then startBatAimbot() else stopBatAimbot() end
    end
end)
