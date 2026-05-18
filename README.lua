-- Junior Hub | Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local RS               = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ========================================
--          REMOTE HELPER
-- ========================================

local function getRF(serviceName)
    local ok, rf = pcall(function()
        return RS.Packages._Index
            :FindFirstChild("leifstout_networker@0.3.1")
            .networker._remotes[serviceName].RemoteFunction
    end)
    return ok and rf or nil
end

-- ========================================
--          HELPER FUNCTIONS
-- ========================================

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ========================================
--               NO FOG
-- ========================================

local NoFogEnabled     = false
local FogConn          = nil
local FogDescConn      = nil
local originalFogEnd   = nil
local originalFogStart = nil
local savedAtmosphere  = {}

local function applyNoFog()
    local L = game:GetService("Lighting")
    originalFogEnd = L.FogEnd; originalFogStart = L.FogStart
    L.FogEnd = 100000; L.FogStart = 100000
    for _, obj in ipairs(L:GetChildren()) do
        if obj:IsA("Atmosphere") then
            savedAtmosphere = { Density = obj.Density, Offset = obj.Offset, Haze = obj.Haze, Glare = obj.Glare }
            obj.Density = 0; obj.Offset = 0; obj.Haze = 0; obj.Glare = 0
        end
    end
    FogConn = L:GetPropertyChangedSignal("FogEnd"):Connect(function()
        if NoFogEnabled then L.FogEnd = 100000 end
    end)
    FogDescConn = L.DescendantAdded:Connect(function(obj)
        if NoFogEnabled and obj:IsA("Atmosphere") then
            obj.Density = 0; obj.Offset = 0; obj.Haze = 0; obj.Glare = 0
        end
    end)
end

local function removeNoFog()
    if FogConn     then FogConn:Disconnect();     FogConn     = nil end
    if FogDescConn then FogDescConn:Disconnect(); FogDescConn = nil end
    local L = game:GetService("Lighting")
    if originalFogEnd   then L.FogEnd   = originalFogEnd   end
    if originalFogStart then L.FogStart = originalFogStart end
    for _, obj in ipairs(L:GetChildren()) do
        if obj:IsA("Atmosphere") and savedAtmosphere.Density then
            obj.Density = savedAtmosphere.Density; obj.Offset = savedAtmosphere.Offset
            obj.Haze    = savedAtmosphere.Haze;    obj.Glare  = savedAtmosphere.Glare
        end
    end
    savedAtmosphere = {}
end

-- ========================================
--         REMOVE TEXTURES / VISUALS
-- ========================================

local savedShadows = nil; local savedGrassLength = nil; local savedDecorations = nil

local function removeShadows()
    local L = game:GetService("Lighting"); savedShadows = L.GlobalShadows; L.GlobalShadows = false
end
local function restoreShadows()
    local L = game:GetService("Lighting"); if savedShadows ~= nil then L.GlobalShadows = savedShadows end
end

local function removeGrass()
    local t = workspace:FindFirstChildOfClass("Terrain")
    if t then savedGrassLength = t.GrassLength; savedDecorations = t.Decoration; t.GrassLength = 0; t.Decoration = false end
end
local function restoreGrass()
    local t = workspace:FindFirstChildOfClass("Terrain")
    if t then
        if savedGrassLength ~= nil then t.GrassLength = savedGrassLength end
        if savedDecorations ~= nil then t.Decoration  = savedDecorations end
    end
end

local savedMaterials = {}; local savedTextures = {}

local function removeTextures()
    savedMaterials = {}; savedTextures = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then savedMaterials[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic end
        if obj:IsA("Texture") or obj:IsA("Decal") then savedTextures[obj] = obj.Transparency; obj.Transparency = 1 end
    end
end
local function restoreTextures()
    for obj, mat   in pairs(savedMaterials) do if obj and obj.Parent then obj.Material     = mat   end end
    for obj, trans in pairs(savedTextures)  do if obj and obj.Parent then obj.Transparency = trans end end
    savedMaterials = {}; savedTextures = {}
end

local savedEffects = {}
local function removePostFX()
    savedEffects = {}
    for _, obj in ipairs(game:GetService("Lighting"):GetChildren()) do
        if obj:IsA("PostEffect") then savedEffects[obj] = obj.Enabled; obj.Enabled = false end
    end
end
local function restorePostFX()
    for obj, state in pairs(savedEffects) do if obj and obj.Parent then obj.Enabled = state end end
    savedEffects = {}
end

-- ========================================
--           FULL BRIGHT
-- ========================================

local FullBrightEnabled  = false
local FB_savedAmbient    = nil; local FB_savedOutdoor    = nil
local FB_savedBrightness = nil; local FB_savedColorShift = nil; local FB_Conn = nil

local function applyFullBright()
    local L = game:GetService("Lighting")
    FB_savedAmbient = L.Ambient; FB_savedOutdoor = L.OutdoorAmbient
    FB_savedBrightness = L.Brightness; FB_savedColorShift = L.ColorShift_Bottom
    L.Ambient = Color3.new(1,1,1); L.OutdoorAmbient = Color3.new(1,1,1)
    L.Brightness = 2; L.ColorShift_Bottom = Color3.new(0,0,0)
    FB_Conn = L:GetPropertyChangedSignal("Brightness"):Connect(function()
        if FullBrightEnabled then L.Brightness = 2 end
    end)
end

local function removeFullBright()
    if FB_Conn then FB_Conn:Disconnect(); FB_Conn = nil end
    local L = game:GetService("Lighting")
    if FB_savedAmbient    then L.Ambient           = FB_savedAmbient    end
    if FB_savedOutdoor    then L.OutdoorAmbient    = FB_savedOutdoor    end
    if FB_savedBrightness then L.Brightness        = FB_savedBrightness end
    if FB_savedColorShift then L.ColorShift_Bottom = FB_savedColorShift end
end

-- ========================================
--         TIME OF DAY CONTROL
-- ========================================

local ClockConn = nil

local function lockTime(hour)
    if ClockConn then ClockConn:Disconnect(); ClockConn = nil end
    local L = game:GetService("Lighting"); L.ClockTime = hour
    ClockConn = RunService.Heartbeat:Connect(function() L.ClockTime = hour end)
end

local function unlockTime()
    if ClockConn then ClockConn:Disconnect(); ClockConn = nil end
end

-- ========================================
--               FLIGHT
-- ========================================

local FlyEnabled = false; local FlySpeed = 60
local FlyConn = nil; local FlyVel = nil; local FlyAlign = nil
local FlyAtt0 = nil; local FlyAtt1 = nil

local function startFly()
    local root = getRoot(); local hum = getHumanoid()
    if not root or not hum then return end
    hum.PlatformStand = true
    FlyAtt0 = Instance.new("Attachment"); FlyAtt0.Parent = root
    FlyAtt1 = Instance.new("Attachment"); FlyAtt1.Parent = workspace.Terrain
    FlyVel = Instance.new("LinearVelocity")
    FlyVel.Attachment0 = FlyAtt0; FlyVel.MaxForce = math.huge
    FlyVel.RelativeTo = Enum.ActuatorRelativeTo.World
    FlyVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    FlyVel.VectorVelocity = Vector3.zero; FlyVel.Parent = root
    FlyAlign = Instance.new("AlignOrientation")
    FlyAlign.Attachment0 = FlyAtt0; FlyAlign.Attachment1 = FlyAtt1
    FlyAlign.MaxTorque = math.huge; FlyAlign.MaxAngularVelocity = math.huge
    FlyAlign.Responsiveness = 200; FlyAlign.RigidityEnabled = true; FlyAlign.Parent = root
    FlyConn = RunService.Heartbeat:Connect(function()
        local r = getRoot(); if not r then return end
        local dir = Vector3.zero; local cf = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir += cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir -= cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis  end
        FlyVel.VectorVelocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * FlySpeed
        local lookDir = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        if lookDir.Magnitude > 0 then FlyAtt1.CFrame = CFrame.new(Vector3.zero, lookDir) end
    end)
end

local function stopFly()
    if FlyConn  then FlyConn:Disconnect();  FlyConn  = nil end
    if FlyVel   then FlyVel:Destroy();      FlyVel   = nil end
    if FlyAlign then FlyAlign:Destroy();    FlyAlign = nil end
    if FlyAtt0  then FlyAtt0:Destroy();     FlyAtt0  = nil end
    if FlyAtt1  then FlyAtt1:Destroy();     FlyAtt1  = nil end
    local hum = getHumanoid(); if hum then hum.PlatformStand = false end
end

local function setFly(state)
    FlyEnabled = state; if state then startFly() else stopFly() end
end

LocalPlayer.CharacterAdded:Connect(function()
    setFly(false); task.wait(0.1)
end)

-- ========================================
--              NOCLIP
-- ========================================

local NoclipEnabled = false; local NoclipConn = nil

local function startNoclip()
    NoclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character; if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end

local function stopNoclip()
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    local char = LocalPlayer.Character; if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
end

local function setNoclip(state)
    NoclipEnabled = state; if state then startNoclip() else stopNoclip() end
end

-- ========================================
--             PLAYER ESP
-- ========================================

local ESPEnabled   = false
local ESPBills     = {}
local ESPMaxDist   = 500

local function removeESP(player)
    if ESPBills[player] then ESPBills[player]:Destroy(); ESPBills[player] = nil end
end

local function createESP(player)
    if player == LocalPlayer then return end
    if ESPBills[player] then return end

    local bill = Instance.new("BillboardGui")
    bill.Name         = "JH_ESP"
    bill.AlwaysOnTop  = true
    bill.Size         = UDim2.new(0, 150, 0, 40)
    bill.StudsOffset  = Vector3.new(0, 3.5, 0)
    bill.ResetOnSpawn = false

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size                   = UDim2.new(1, 0, 1, 0)
    label.TextColor3             = Color3.new(0, 0, 0)
    label.TextStrokeColor3       = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.2
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = 13
    label.LineHeight             = 1.3
    label.RichText               = false
    label.Parent                 = bill

    ESPBills[player] = bill

    local function attach(char)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if root then bill.Adornee = root; bill.Parent = root end
    end

    if player.Character then attach(player.Character) end
    player.CharacterAdded:Connect(function(char) if ESPEnabled then attach(char) end end)

    RunService.Heartbeat:Connect(function()
        if not ESPEnabled then label.Text = ""; return end
        local myRoot    = getRoot()
        local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and theirRoot then
            local dist = math.floor((myRoot.Position - theirRoot.Position).Magnitude)
            if dist <= ESPMaxDist then
                label.Text = player.Name .. "\n" .. dist .. " studs"
                label.Visible = true
            else
                label.Visible = false
            end
        else
            label.Text = player.Name
            label.Visible = true
        end
    end)
end

local function enableESP()
    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
end

local function disableESP()
    for _, bill in pairs(ESPBills) do
        local lbl = bill:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.Text = ""; lbl.Visible = false end
    end
end

Players.PlayerAdded:Connect(function(p) if ESPEnabled then createESP(p) end end)
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

-- ========================================
--           AUTO EQUIP BEST
-- ========================================

local AutoEquipEnabled = false; local AutoEquipThread = nil

local function startAutoEquip()
    AutoEquipThread = task.spawn(function()
        while AutoEquipEnabled do
            pcall(function()
                local rf = getRF("InventoryService")
                if rf then rf:InvokeServer("requestEquipBest") end
            end)
            task.wait(2)
        end
    end)
end

local function stopAutoEquip()
    AutoEquipEnabled = false
    if AutoEquipThread then task.cancel(AutoEquipThread); AutoEquipThread = nil end
end

-- ========================================
--           AUTO REBIRTH
-- ========================================

local AutoRebirthEnabled = false; local AutoRebirthThread = nil

local function startAutoRebirth()
    AutoRebirthThread = task.spawn(function()
        while AutoRebirthEnabled do
            pcall(function()
                local rf = getRF("RebirthService")
                if rf then rf:InvokeServer("requestRebirth") end
            end)
            task.wait(2)
        end
    end)
end

local function stopAutoRebirth()
    AutoRebirthEnabled = false
    if AutoRebirthThread then task.cancel(AutoRebirthThread); AutoRebirthThread = nil end
end

-- ========================================
--            FAST ROLL
-- ========================================

local FastRollEnabled = false
local FastRollThread  = nil
local FastRollDelay   = 1.0

local function startFastRoll()
    FastRollThread = task.spawn(function()
        while FastRollEnabled do
            pcall(function()
                RS.Packages._Index
                    :FindFirstChild("leifstout_networker@0.3.1")
                    .networker._remotes.RollService.RemoteFunction
                    :InvokeServer(unpack({"requestRoll"}))
            end)
            task.wait(FastRollDelay)
        end
    end)
end

local function stopFastRoll()
    FastRollEnabled = false
    if FastRollThread then task.cancel(FastRollThread); FastRollThread = nil end
end

-- ========================================
--           AUTO CLAIM INDEX
-- ========================================

local AutoClaimIndexEnabled = false
local AutoClaimIndexThread  = nil
local INDEX_TIERS = { "basic", "big", "huge", "shiny", "inverted" }

local function startAutoClaimIndex()
    AutoClaimIndexThread = task.spawn(function()
        while AutoClaimIndexEnabled do
            pcall(function()
                local rf = getRF("IndexService")
                if rf then
                    for _, tier in ipairs(INDEX_TIERS) do
                        pcall(function() rf:InvokeServer("requestClaimReward", tier) end)
                        task.wait(0.3)
                    end
                end
            end)
            task.wait(2)
        end
    end)
end

local function stopAutoClaimIndex()
    AutoClaimIndexEnabled = false
    if AutoClaimIndexThread then task.cancel(AutoClaimIndexThread); AutoClaimIndexThread = nil end
end

-- ========================================
--           REDEEM ALL CODES
-- ========================================

local CODES = {
    "sliming", "goingBananas", "giveMeLuckNOW", "SPARKLEZ",
    "2muchluck", "test", "craftAway", "gullible", "time2Grind",
}

local function redeemAllCodes()
    local rf = getRF("CodeService")
    if not rf then Rayfield:Notify({ Title = 'Junior Hub', Content = 'CodeService remote not found!', Duration = 3 }); return end
    task.spawn(function()
        local success = 0
        for _, code in ipairs(CODES) do
            local ok = pcall(function() rf:InvokeServer("redeem", code) end)
            if ok then success += 1 end
            task.wait(0.4)
        end
        Rayfield:Notify({ Title = 'Codes', Content = 'Attempted: ' .. success .. '/' .. #CODES, Duration = 4 })
    end)
end

-- ========================================
--              RAYFIELD UI
-- ========================================

local Window = Rayfield:CreateWindow({
    Name               = "Junior Hub",
    LoadingTitle       = "Junior Hub",
    LoadingSubtitle    = "by junior",
    ConfigurationSaving = { Enabled = true, FolderName = "JuniorHub", FileName = "Config" },
    KeySystem          = false,
})

-- ===== MAIN TAB =====

local MainTab = Window:CreateTab("Main", "zap")

MainTab:CreateSection("Automation")

MainTab:CreateToggle({
    Name        = "Auto Equip Best",
    CurrentValue = false,
    Flag        = "AutoEquipToggle",
    Callback    = function(value)
        AutoEquipEnabled = value
        if value then startAutoEquip() else stopAutoEquip() end
    end,
})

MainTab:CreateToggle({
    Name        = "Auto Rebirth",
    CurrentValue = false,
    Flag        = "AutoRebirthToggle",
    Callback    = function(value)
        AutoRebirthEnabled = value
        if value then startAutoRebirth() else stopAutoRebirth() end
    end,
})

MainTab:CreateToggle({
    Name        = "Auto Claim Index",
    CurrentValue = false,
    Flag        = "AutoClaimIndexToggle",
    Callback    = function(value)
        AutoClaimIndexEnabled = value
        if value then startAutoClaimIndex() else stopAutoClaimIndex() end
    end,
})

MainTab:CreateSection("Fast Roll")

MainTab:CreateToggle({
    Name        = "Fast Roll",
    CurrentValue = false,
    Flag        = "FastRollToggle",
    Callback    = function(value)
        FastRollEnabled = value
        if value then startFastRoll() else stopFastRoll() end
    end,
})

MainTab:CreateSection("Codes")

MainTab:CreateButton({
    Name     = "Redeem All Codes",
    Callback = redeemAllCodes,
})

-- ===== FLIGHT TAB =====

local FlyTab = Window:CreateTab("Flight", "plane")

FlyTab:CreateSection("Flight")

FlyTab:CreateToggle({
    Name        = "Enable Flight",
    CurrentValue = false,
    Flag        = "FlyToggle",
    Callback    = function(value) setFly(value) end,
})

FlyTab:CreateSlider({
    Name        = "Flight Speed",
    Range       = { 10, 500 },
    Increment   = 1,
    Suffix      = " studs/s",
    CurrentValue = 60,
    Flag        = "FlySpeedSlider",
    Callback    = function(value) FlySpeed = value end,
})

FlyTab:CreateSection("Movement")

FlyTab:CreateSlider({
    Name        = "Walk Speed",
    Range       = { 1, 300 },
    Increment   = 1,
    Suffix      = " studs/s",
    CurrentValue = 16,
    Flag        = "WalkSpeedSlider",
    Callback    = function(value)
        local hum = getHumanoid(); if hum then hum.WalkSpeed = value end
    end,
})

FlyTab:CreateSlider({
    Name        = "Jump Power",
    Range       = { 0, 300 },
    Increment   = 1,
    CurrentValue = 50,
    Flag        = "JumpPowerSlider",
    Callback    = function(value)
        local hum = getHumanoid()
        if hum then hum.UseJumpPower = true; hum.JumpPower = value end
    end,
})

FlyTab:CreateToggle({
    Name        = "Infinite Jump",
    CurrentValue = false,
    Flag        = "InfiniteJumpToggle",
    Callback    = function(value) _G.InfJump = value end,
})

UserInputService.JumpRequest:Connect(function()
    if _G.InfJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

FlyTab:CreateToggle({
    Name        = "Noclip",
    CurrentValue = false,
    Flag        = "NoclipToggle",
    Callback    = function(value) setNoclip(value) end,
})

FlyTab:CreateButton({
    Name     = "Reset Movement to Defaults",
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.UseJumpPower = true end
        Rayfield:Notify({ Title = 'Movement', Content = 'Reset to defaults.', Duration = 2 })
    end,
})

-- ===== ESP TAB =====

local ESPTab = Window:CreateTab("ESP", "eye")

ESPTab:CreateSection("Player ESP")

ESPTab:CreateToggle({
    Name        = "Enable Player ESP",
    CurrentValue = false,
    Flag        = "ESPToggle",
    Callback    = function(value)
        ESPEnabled = value
        if value then enableESP() else disableESP() end
    end,
})

ESPTab:CreateSlider({
    Name        = "Max Visible Distance",
    Range       = { 50, 2000 },
    Increment   = 10,
    Suffix      = " studs",
    CurrentValue = 500,
    Flag        = "ESPDistSlider",
    Callback    = function(value) ESPMaxDist = value end,
})

-- ===== MISC TAB =====

local MiscTab = Window:CreateTab("Misc", "sparkles")

MiscTab:CreateSection("Visual Tweaks")

MiscTab:CreateToggle({
    Name        = "No Fog",
    CurrentValue = false,
    Flag        = "NoFogToggle",
    Callback    = function(value)
        NoFogEnabled = value
        if value then applyNoFog() else removeNoFog() end
    end,
})

MiscTab:CreateToggle({
    Name        = "No Shadows",
    CurrentValue = false,
    Flag        = "NoShadowsToggle",
    Callback    = function(value)
        if value then removeShadows() else restoreShadows() end
    end,
})

MiscTab:CreateToggle({
    Name        = "No Grass / Decorations",
    CurrentValue = false,
    Flag        = "NoGrassToggle",
    Callback    = function(value)
        if value then removeGrass() else restoreGrass() end
    end,
})

MiscTab:CreateToggle({
    Name        = "No Textures",
    CurrentValue = false,
    Flag        = "NoTexturesToggle",
    Callback    = function(value)
        if value then removeTextures() else restoreTextures() end
    end,
})

MiscTab:CreateToggle({
    Name        = "No Post-Processing FX",
    CurrentValue = false,
    Flag        = "NoPostFXToggle",
    Callback    = function(value)
        if value then removePostFX() else restorePostFX() end
    end,
})

MiscTab:CreateSection("Lighting")

MiscTab:CreateToggle({
    Name        = "Full Bright",
    CurrentValue = false,
    Flag        = "FullBrightToggle",
    Callback    = function(value)
        FullBrightEnabled = value
        if value then applyFullBright() else removeFullBright() end
    end,
})

MiscTab:CreateSlider({
    Name        = "Time of Day",
    Range       = { 0, 24 },
    Increment   = 0.5,
    Suffix      = ":00",
    CurrentValue = 14,
    Flag        = "TimeSlider",
    Callback    = function(value) lockTime(value) end,
})

MiscTab:CreateButton({
    Name     = "Unlock Time",
    Callback = function()
        unlockTime()
        Rayfield:Notify({ Title = 'Lighting', Content = 'Time unlocked.', Duration = 2 })
    end,
})

-- ===== SETTINGS TAB =====

local SettingsTab = Window:CreateTab("Settings", "settings")

SettingsTab:CreateSection("Utilities")

SettingsTab:CreateButton({
    Name     = "Rejoin",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

SettingsTab:CreateButton({
    Name     = "Reset Character",
    Callback = function()
        local hum = getHumanoid(); if hum then hum.Health = 0 end
    end,
})

SettingsTab:CreateButton({
    Name     = "Copy User ID",
    Callback = function()
        pcall(function() setclipboard(tostring(LocalPlayer.UserId)) end)
        Rayfield:Notify({ Title = 'Copied', Content = 'UserId: ' .. tostring(LocalPlayer.UserId), Duration = 2 })
    end,
})

SettingsTab:CreateButton({
    Name     = "Copy Game ID",
    Callback = function()
        pcall(function() setclipboard(tostring(game.PlaceId)) end)
        Rayfield:Notify({ Title = 'Copied', Content = 'Place ID: ' .. tostring(game.PlaceId), Duration = 2 })
    end,
})

SettingsTab:CreateSection("Stop Everything")

SettingsTab:CreateButton({
    Name     = "Stop All Features",
    Callback = function()
        _G.InfJump            = false
        NoFogEnabled          = false
        FullBrightEnabled     = false
        NoclipEnabled         = false
        ESPEnabled            = false
        AutoEquipEnabled      = false
        AutoRebirthEnabled    = false
        FastRollEnabled       = false
        AutoClaimIndexEnabled = false

        setFly(false); setNoclip(false); disableESP()
        stopAutoEquip(); stopAutoRebirth(); stopFastRoll(); stopAutoClaimIndex()
        removeNoFog(); restoreShadows(); restoreGrass()
        restoreTextures(); restorePostFX(); removeFullBright(); unlockTime()

        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end

        -- Reset Rayfield toggle flags
        RayfieldLibrary = Rayfield
        local flags = {
            "FlyToggle", "InfiniteJumpToggle", "NoclipToggle", "ESPToggle",
            "AutoEquipToggle", "AutoRebirthToggle", "FastRollToggle",
            "AutoClaimIndexToggle", "NoFogToggle", "NoShadowsToggle",
            "NoGrassToggle", "NoTexturesToggle", "NoPostFXToggle", "FullBrightToggle",
        }
        for _, flag in ipairs(flags) do
            if Rayfield.Flags and Rayfield.Flags[flag] then
                Rayfield.Flags[flag]:Set(false)
            end
        end
        if Rayfield.Flags and Rayfield.Flags["WalkSpeedSlider"] then Rayfield.Flags["WalkSpeedSlider"]:Set(16) end
        if Rayfield.Flags and Rayfield.Flags["JumpPowerSlider"]  then Rayfield.Flags["JumpPowerSlider"]:Set(50) end

        Rayfield:Notify({ Title = 'Junior Hub', Content = 'All features stopped and reset.', Duration = 3 })
    end,
})

-- ========================================
--              LOADED
-- ========================================

Rayfield:Notify({ Title = 'Junior Hub', Content = 'Loaded successfully!', Duration = 3 })
