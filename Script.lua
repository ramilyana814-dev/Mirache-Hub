-- âš¡ MIRACLE HUB âš¡
-- Red Edition - Vertical Single Column UI

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

-- ============================================================
-- SERVICES & SAFE CHARACTER WAIT
-- ============================================================
local function waitForCharacter()
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
        return char
    end
    return Player.CharacterAdded:Wait()
end
task.spawn(waitForCharacter)

if not getgenv then getgenv = function() return _G end end

-- ============================================================
-- STATE
-- ============================================================
local Enabled = {
    SpeedBoost        = false,
    AntiRagdoll       = false,
    HitCircle         = false,
    Float             = false,
    SpeedWhileStealing= false,
    AutoSteal         = false,
    Unwalk            = false,
    OptimizerXRay     = false,
    SpamBat           = false,
    Helicopter        = false,
    Vibrance          = false,
    AutoRight         = false,
    AutoLeft          = false,
    GalaxyMode        = false,
    BatAimbot         = false,
    InfiniteJump      = false,
    SafeConfig        = false,
    LockFloatPosition = false,
    Taunt             = false,
    TPLeft            = false,
    TPRight           = false,
}

local Values = {
    BoostSpeed           = 30,
    SpinSpeed            = 30,
    StealingSpeedValue   = 29,
    STEAL_RADIUS         = 20,
    STEAL_DURATION       = 1.3,
    DEFAULT_GRAVITY      = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER            = 35,
    HOP_COOLDOWN         = 0.08,
    BatAimbotSpeed       = 55,
}

local KEYBINDS = {
    SPEED     = Enum.KeyCode.V,
    FLOAT     = Enum.KeyCode.F,
    AUTORIGHT = Enum.KeyCode.E,
    AUTOLEFT  = Enum.KeyCode.Q,
    BATAIMBOT = Enum.KeyCode.X,
}

local Connections   = {}
local isStealing    = false
local lastBatSwing  = 0
local BAT_SWING_COOLDOWN = 0.12

-- Config System
local CONFIG_KEY = "RICKS_DUEL_CONFIG_V1"
local floatButtonPositions = {}
local floatButtonReferences = {}

-- Forward declarations for startup/reset logic
local startSpeedBoost, stopSpeedBoost
local startFloat, stopFloat
local startSpamBat, stopSpamBat
local startHelicopter, stopHelicopter
local startHitCircle, stopHitCircle
local startBatAimbot, stopBatAimbot
local startInfiniteJump, stopInfiniteJump
local startAutoSteal, stopAutoSteal
local startUnwalk, stopUnwalk
local enablePurpleMoon, disablePurpleMoon
local startAntiRagdoll, stopAntiRagdoll
local enableOptimizer, disableOptimizer
local enableXRay, disableXRay
local startGalaxyMode, stopGalaxyMode
local startSpeedWhileStealing, stopSpeedWhileStealing
local startStealPath, stopStealPath

local function saveConfig()
    local configData = {
        enabled = Enabled,
        values = Values,
        floatPositions = floatButtonPositions,
    }
    pcall(function()
        if writefile then
            writefile(CONFIG_KEY .. ".json", HttpService:JSONEncode(configData))
        end
    end)
    pcall(function()
        if setgenv then
            getgenv()[CONFIG_KEY] = configData
        end
    end)
end

local function loadConfig()
    local configData = nil
    pcall(function()
        if getgenv and getgenv()[CONFIG_KEY] then
            configData = getgenv()[CONFIG_KEY]
        end
    end)
    if not configData then
        pcall(function()
            if readfile then
                local json = readfile(CONFIG_KEY .. ".json")
                configData = HttpService:JSONDecode(json)
            end
        end)
    end
    if configData then
        Enabled = configData.enabled or Enabled
        Values = configData.values or Values
        floatButtonPositions = configData.floatPositions or {}
    end
end

loadConfig()

-- ============================================================
-- FIXED SAFE CONFIG LOGIC (Boot Effect)
-- ============================================================
local VisualSetters = {}

local function applyBootEffect()
    task.spawn(function()
        local savedEnabled = {}
        for key, value in pairs(Enabled) do
            savedEnabled[key] = value
        end

        -- SHUTDOWN EVERYTHING
        stopSpeedBoost()
        stopFloat()
        stopSpamBat()
        stopHelicopter()
        stopHitCircle()
        stopBatAimbot()
        stopInfiniteJump()
        stopAutoSteal()
        stopUnwalk()
        disablePurpleMoon()
        stopAntiRagdoll()
        disableOptimizer()
        disableXRay()
        stopGalaxyMode()
        stopSpeedWhileStealing()
        stopStealPath()

        -- Reset Visuals to OFF
        for key, setterFunc in pairs(VisualSetters) do
            pcall(function() setterFunc(false, true) end)
        end
        for key, updateFunc in pairs(floatButtonReferences) do
            pcall(function() updateFunc(false) end)
        end

        task.wait(2)

        -- RESTORE EVERYTHING
        for key, value in pairs(savedEnabled) do
            Enabled[key] = value
            if value == true then
                if key == "SpeedBoost" then startSpeedBoost() end
                if key == "Float" then startFloat() end
                if key == "SpamBat" then startSpamBat() end
                if key == "Helicopter" then startHelicopter() end
                if key == "HitCircle" then startHitCircle() end
                if key == "BatAimbot" then startBatAimbot() end
                if key == "InfiniteJump" then startInfiniteJump() end
                if key == "AutoSteal" then startAutoSteal() end
                if key == "Unwalk" then startUnwalk() end
                if key == "Vibrance" then enablePurpleMoon() end
                if key == "AntiRagdoll" then startAntiRagdoll() end
                if key == "OptimizerXRay" then enableOptimizer() enableXRay() end
                if key == "GalaxyMode" then startGalaxyMode() end
                if key == "SpeedWhileStealing" then startSpeedWhileStealing() end

                -- Update Visuals to ON
                if VisualSetters[key] then VisualSetters[key](true, true) end
                if floatButtonReferences[key] then floatButtonReferences[key](true) end
            end
        end
    end)
end

-- ============================================================
-- HELPERS
-- ============================================================
local function getMovementDirection()
    local c = Player.Character
    if not c then return Vector3.zero end
    local hum = c:FindFirstChildOfClass("Humanoid")
    return hum and hum.MoveDirection or Vector3.zero
end

local SlapList = {
    {1,"Bat"},{2,"Slap"},{3,"Iron Slap"},{4,"Gold Slap"},
    {5,"Diamond Slap"},{6,"Emerald Slap"},{7,"Ruby Slap"},
    {8,"Dark Matter Slap"},{9,"Flame Slap"},{10,"Nuclear Slap"},
    {11,"Galaxy Slap"},{12,"Glitched Slap"}
}

local function findBat()
    local c = Player.Character
    if not c then return nil end
    local bp = Player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    for _, i in ipairs(SlapList) do
        local t = c:FindFirstChild(i[2]) or (bp and bp:FindFirstChild(i[2]))
        if t then return t end
    end
    return nil
end

-- ============================================================
-- FEATURE LOGIC
-- ============================================================

-- Speed Boost
function startSpeedBoost()
    if Connections.speed then return end
    Connections.speed = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedBoost then return end
        pcall(function()
            local c = Player.Character
            if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart")
            if not h then return end
            local md = getMovementDirection()
            if md.Magnitude > 0.1 then
                h.AssemblyLinearVelocity = Vector3.new(md.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, md.Z * Values.BoostSpeed)
            end
        end)
    end)
end
function stopSpeedBoost()
    if Connections.speed then Connections.speed:Disconnect() Connections.speed = nil end
end

-- Speed While Stealing
function startSpeedWhileStealing()
    if Connections.speedWhileStealing then return end
    Connections.speedWhileStealing = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedWhileStealing or not Player:GetAttribute("Stealing") then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local md = getMovementDirection()
        if md.Magnitude > 0.1 then
            h.AssemblyLinearVelocity = Vector3.new(md.X * Values.StealingSpeedValue, h.AssemblyLinearVelocity.Y, md.Z * Values.StealingSpeedValue)
        end
    end)
end
function stopSpeedWhileStealing()
    if Connections.speedWhileStealing then Connections.speedWhileStealing:Disconnect() Connections.speedWhileStealing = nil end
end

-- Anti Ragdoll (v2)
local antiRagdollMode = nil
local ragdollConnections = {}
local cachedCharData = {}
local isBoosting = false
local AR_BOOST_SPEED = 400
local AR_DEFAULT_SPEED = 16

local function arCacheCharacterData()
    local char = Player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    cachedCharData = { character = char, humanoid = hum, root = root }
    return true
end

local function arDisconnectAll()
    for _, conn in ipairs(ragdollConnections) do
        pcall(function() conn:Disconnect() end)
    end
    ragdollConnections = {}
end

local function arIsRagdolled()
    if not cachedCharData.humanoid then return false end
    local state = cachedCharData.humanoid:GetState()
    if state == Enum.HumanoidStateType.Physics or
       state == Enum.HumanoidStateType.Ragdoll or
       state == Enum.HumanoidStateType.FallingDown then return true end
    local endTime = Player:GetAttribute("RagdollEndTime")
    if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then return true end
    return false
end

local function arForceExit()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    pcall(function()
        Player:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow())
    end)
    for _, d in ipairs(cachedCharData.character:GetDescendants()) do
        if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then
            d:Destroy()
        end
    end
    if not isBoosting then
        isBoosting = true
        cachedCharData.humanoid.WalkSpeed = AR_BOOST_SPEED
    end
    if cachedCharData.humanoid.Health > 0 then
        cachedCharData.humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    cachedCharData.root.Anchored = false
end

local function arHeartbeatLoop()
    while antiRagdollMode == "v1" do
        task.wait()
        if not Enabled.AntiRagdoll then break end
        local ragdolled = arIsRagdolled()
        if ragdolled then
            arForceExit()
        elseif isBoosting and not ragdolled then
            isBoosting = false
            if cachedCharData.humanoid then
                cachedCharData.humanoid.WalkSpeed = AR_DEFAULT_SPEED
            end
        end
    end
end

function startAntiRagdoll()
    if antiRagdollMode == "v1" then return end
    if not arCacheCharacterData() then return end
    antiRagdollMode = "v1"
    local camConn = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if cam and cachedCharData.humanoid then
            cam.CameraSubject = cachedCharData.humanoid
        end
    end)
    table.insert(ragdollConnections, camConn)
    local respawnConn = Player.CharacterAdded:Connect(function()
        isBoosting = false
        task.wait(0.5)
        arCacheCharacterData()
    end)
    table.insert(ragdollConnections, respawnConn)
    task.spawn(arHeartbeatLoop)
end

function stopAntiRagdoll()
    antiRagdollMode = nil
    if isBoosting and cachedCharData.humanoid then
        cachedCharData.humanoid.WalkSpeed = AR_DEFAULT_SPEED
    end
    isBoosting = false
    arDisconnectAll()
    cachedCharData = {}
end

-- Spam Bat
function startSpamBat()
    if Connections.spamBat then return end
    Connections.spamBat = RunService.Heartbeat:Connect(function()
        if not Enabled.SpamBat then return end
        local c = Player.Character
        if not c then return end
        local bat = findBat()
        if not bat then return end
        if bat.Parent ~= c then bat.Parent = c end
        local now = tick()
        if now - lastBatSwing < BAT_SWING_COOLDOWN then return end
        lastBatSwing = now
        pcall(function() bat:Activate() end)
    end)
end
function stopSpamBat()
    if Connections.spamBat then Connections.spamBat:Disconnect() Connections.spamBat = nil end
end

-- Helicopter
local helicopterBAV = nil
function startHelicopter()
    local c = Player.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if helicopterBAV then helicopterBAV:Destroy() helicopterBAV = nil end
    helicopterBAV = Instance.new("BodyAngularVelocity")
    helicopterBAV.Name = "HelicopterBAV"
    helicopterBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    helicopterBAV.AngularVelocity = Vector3.new(0, Values.SpinSpeed, 0)
    helicopterBAV.Parent = hrp
end
function stopHelicopter()
    if helicopterBAV then helicopterBAV:Destroy() helicopterBAV = nil end
    local c = Player.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, v in pairs(hrp:GetChildren()) do
                if v.Name == "HelicopterBAV" then v:Destroy() end
            end
        end
    end
end

-- Float
local floatConn = nil
local FLOAT_TARGET_HEIGHT = 10
function startFloat()
    if floatConn then return end
    local c = Player.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local floatOriginY = hrp.Position.Y + FLOAT_TARGET_HEIGHT
    local floatStartTime = tick()
    local floatDescending = false
    floatConn = RunService.Heartbeat:Connect(function()
        if not Enabled.Float then return end
        local c2 = Player.Character
        if not c2 then return end
        local h = c2:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local hum2 = c2:FindFirstChildOfClass("Humanoid")
        if tick() - floatStartTime >= 4 then floatDescending = true end
        local currentY = h.Position.Y
        local vertVel
        if floatDescending then
            vertVel = -20
            if currentY <= floatOriginY - FLOAT_TARGET_HEIGHT + 0.5 then
                h.AssemblyLinearVelocity = Vector3.zero
                Enabled.Float = false
                if floatConn then floatConn:Disconnect() floatConn = nil end
                return
            end
        else
            local diff = floatOriginY - currentY
            if diff > 0.3 then vertVel = math.clamp(diff * 8, 5, 50)
            elseif diff < -0.3 then vertVel = math.clamp(diff * 8, -50, -5)
            else vertVel = 0 end
        end
        -- Keep horizontal velocity unchanged (normal walking speed)
        local horizX = h.AssemblyLinearVelocity.X
        local horizZ = h.AssemblyLinearVelocity.Z
        h.AssemblyLinearVelocity = Vector3.new(horizX, vertVel, horizZ)
    end)
end
function stopFloat()
    if floatConn then floatConn:Disconnect() floatConn = nil end
    local c = Player.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
    end
end

-- Unwalk
local savedAnimations = {}
function startUnwalk()
    local c = Player.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim = c:FindFirstChild("Animate")
    if anim then savedAnimations.Animate = anim:Clone() anim:Destroy() end
end
function stopUnwalk()
    local c = Player.Character
    if c and savedAnimations.Animate then
        savedAnimations.Animate:Clone().Parent = c
        savedAnimations.Animate = nil
    end
end

-- Hit Circle (Melee Aimbot)
local Cebo = { Conn = nil, Circle = nil, Align = nil, Attach = nil }
function startHitCircle()
    if Cebo.Conn then return end
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    Cebo.Attach = Instance.new("Attachment", hrp)
    Cebo.Align = Instance.new("AlignOrientation", hrp)
    Cebo.Align.Attachment0 = Cebo.Attach
    Cebo.Align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    Cebo.Align.RigidityEnabled = true
    Cebo.Circle = Instance.new("Part")
    Cebo.Circle.Shape = Enum.PartType.Cylinder
    Cebo.Circle.Material = Enum.Material.Neon
    Cebo.Circle.Size = Vector3.new(0.05, 14.5, 14.5)
    Cebo.Circle.Color = Color3.fromRGB(120, 120, 120)
    Cebo.Circle.CanCollide = false
    Cebo.Circle.Massless = true
    Cebo.Circle.Parent = workspace
    local weld = Instance.new("Weld")
    weld.Part0 = hrp
    weld.Part1 = Cebo.Circle
    weld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(90))
    weld.Parent = Cebo.Circle
    Cebo.Conn = RunService.RenderStepped:Connect(function()
        if not Enabled.HitCircle then return end
        local target, dmin = nil, 7.25
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d <= dmin then target, dmin = p.Character.HumanoidRootPart, d end
            end
        end
        if target then
            char.Humanoid.AutoRotate = false
            Cebo.Align.Enabled = true
            Cebo.Align.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z))
            local t = char:FindFirstChild("Bat") or char:FindFirstChild("Medusa")
            if t then t:Activate() end
        else
            Cebo.Align.Enabled = false
            char.Humanoid.AutoRotate = true
        end
    end)
end
function stopHitCircle()
    if Cebo.Conn   then Cebo.Conn:Disconnect()   Cebo.Conn   = nil end
    if Cebo.Circle then Cebo.Circle:Destroy()     Cebo.Circle = nil end
    if Cebo.Align  then Cebo.Align:Destroy()      Cebo.Align  = nil end
    if Cebo.Attach then Cebo.Attach:Destroy()     Cebo.Attach = nil end
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.AutoRotate = true
    end
end

-- Bat Aimbot
local function findNearestEnemy(myHRP)
    local nearest, nearestDist, nearestTorso = nil, math.huge, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local eh  = p.Character:FindFirstChild("HumanoidRootPart")
            local torso = p.Character:FindFirstChild
