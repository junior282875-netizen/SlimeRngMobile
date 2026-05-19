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

local function getRE(serviceName)
    local ok, re = pcall(function()
        return RS.Packages._Index
            :FindFirstChild("leifstout_networker@0.3.1")
            .networker._remotes[serviceName].RemoteEvent
    end)
    return ok and re or nil
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

local function notify(title, content, duration)
    Rayfield:Notify({
        Title    = title,
        Content  = content,
        Duration = duration or 3,
        Image    = 4483362458,
    })
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
    if FlyToggleElement then FlyToggleElement:Set(false) end
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
        local label = bill:FindFirstChildOfClass("TextLabel")
        if label then label.Text = ""; label.Visible = false end
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
                        pcall(function()
                            rf:InvokeServer("requestClaimReward", tier)
                        end)
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
--           AUTO BUY ZONE
-- ========================================

local AutoBuyZoneEnabled = false
local AutoBuyZoneThread  = nil

local function startAutoBuyZone()
    AutoBuyZoneThread = task.spawn(function()
        while AutoBuyZoneEnabled do
            pcall(function()
                RS.Packages._Index
                    :FindFirstChild("leifstout_networker@0.3.1")
                    .networker._remotes.ZonesService.RemoteFunction
                    :InvokeServer("requestPurchaseZone")
            end)
            task.wait(2)
        end
    end)
end

local function stopAutoBuyZone()
    AutoBuyZoneEnabled = false
    if AutoBuyZoneThread then task.cancel(AutoBuyZoneThread); AutoBuyZoneThread = nil end
end

-- ========================================
--         AUTO USE ITEMS / POTIONS
-- ========================================

local ItemEnabled = {
    luck      = false,
    ultraLuck = false,
    rollSpeed = false,
    bigDice   = false,
}

local ItemThreads = {
    luck      = nil,
    ultraLuck = nil,
    rollSpeed = nil,
    bigDice   = nil,
}

local ItemDefs = {
    luck      = { service = "BoostService",     request = "requestUseBoost", arg = "luck"      },
    ultraLuck = { service = "BoostService",     request = "requestUseBoost", arg = "ultraLuck" },
    rollSpeed = { service = "BoostService",     request = "requestUseBoost", arg = "rollSpeed" },
    bigDice   = { service = "InventoryService", request = "requestUseItem",  arg = "bigDice"   },
}

local function startItem(key)
    if ItemThreads[key] then task.cancel(ItemThreads[key]); ItemThreads[key] = nil end
    local def = ItemDefs[key]
    ItemThreads[key] = task.spawn(function()
        while ItemEnabled[key] do
            pcall(function()
                local rf = getRF(def.service)
                if rf then rf:InvokeServer(def.request, def.arg) end
            end)
            task.wait(2)
        end
    end)
end

local function stopItem(key)
    ItemEnabled[key] = false
    if ItemThreads[key] then task.cancel(ItemThreads[key]); ItemThreads[key] = nil end
end

local function stopAllItems()
    for key in pairs(ItemEnabled) do stopItem(key) end
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
    if not rf then notify('Junior Hub', 'CodeService remote not found!', 3); return end
    task.spawn(function()
        local success = 0
        for _, code in ipairs(CODES) do
            local ok = pcall(function() rf:InvokeServer("redeem", code) end)
            if ok then success += 1 end
            task.wait(0.4)
        end
        notify('Codes', 'Attempted: ' .. success .. '/' .. #CODES, 4)
    end)
end

-- ========================================
--         FAKE ROLLS / BEST ROLL
-- ========================================

local FakeRollsEnabled = false
local FakeBestEnabled  = false
local FakeRollValue    = 1
local FakeBestValue    = 1
local FakeRollConn     = nil
local FakeBestConn     = nil

local function applyFakeRolls()
    if FakeRollConn then FakeRollConn:Disconnect(); FakeRollConn = nil end
    FakeRollConn = RunService.Heartbeat:Connect(function()
        if not FakeRollsEnabled then return end
        local l = LocalPlayer:FindFirstChild("leaderstats")
        if l then
            local r = l:FindFirstChild("Rolls")
            if r then r.Value = FakeRollValue end
        end
    end)
end

local function removeFakeRolls()
    if FakeRollConn then FakeRollConn:Disconnect(); FakeRollConn = nil end
end

local function applyFakeBest()
    if FakeBestConn then FakeBestConn:Disconnect(); FakeBestConn = nil end
    FakeBestConn = RunService.Heartbeat:Connect(function()
        if not FakeBestEnabled then return end
        local l = LocalPlayer:FindFirstChild("leaderstats")
        if l then
            local b = l:FindFirstChild("Best Roll")
            if b then b.Value = FakeBestValue end
        end
    end)
end

local function removeFakeBest()
    if FakeBestConn then FakeBestConn:Disconnect(); FakeBestConn = nil end
end

-- ========================================
--           AUTO UPGRADE (FULL)
-- ========================================

local UPGRADE_SLOTS = {
    "lootTree",
    "lootApple", "lootCarrot", "lootCherries", "lootGrapes",
    "lootBanana", "lootWatermelon", "lootPizza", "lootChicken",
    "lootLuck", "lootRollSpeed", "lootUltraLuck",
    "fruits",
    "coinIncome1",  "coinIncome2",  "coinIncome3",  "coinIncome4",
    "coinIncome5",  "coinIncome6",  "coinIncome7",  "coinIncome8",
    "coinIncome9",  "coinIncome10", "coinIncome11", "coinIncome12", "coinIncome13",
    "overkill1", "overkill2", "overkill3", "overkill4",
    "offlineLootAmount1", "offlineLootAmount2", "offlineLootAmount3",
    "offlineLootAmount4", "offlineLootAmount5",
    "rollSpeed1", "rollSpeed2", "rollSpeed3",
    "luck1", "luck2", "luck3",
    "rebirthLuck1", "rebirthLuck2",
    "walkSpeed1", "walkSpeed2", "walkSpeed3",
    "enemyCount1", "enemyCount2", "enemyCount3", "enemyCount4", "enemyCount5",
    "slots2", "slots3", "slots4",
    "petSlots1", "petSlots2",
    "craftSlots1", "craftSlots2",
    "coinMultiplier1", "coinMultiplier2", "coinMultiplier3",
    "xpMultiplier1", "xpMultiplier2",
    "fireOrigin",
    "fireBall1", "fireBall2", "fireBall3", "fireBall4",
    "fireBlast1", "fireBlast2", "fireBlast3", "fireBlast4",
    "iceOrigin",
    "frostShard1", "frostShard2", "frostShard3", "frostShard4",
    "frostSpike1", "frostSpike2", "frostSpike3", "frostSpike4",
    "lightningOrigin",
    "chainLightning1", "chainLightning2", "chainLightning3", "chainLightning4",
    "lightningBlast1", "lightningBlast2", "lightningBlast3", "lightningBlast4",
    "swordOrigin",
    "swordSlash1", "swordSlash2", "swordSlash3", "swordSlash4",
    "skySword1", "skySword2", "skySword3", "skySword4",
    "magicianOrigin",
    "cardThrow1", "cardThrow2", "cardThrow3", "cardThrow4",
    "bowlingHat1", "bowlingHat2", "bowlingHat3", "bowlingHat4",
}

local AutoUpgradeEnabled = false
local AutoUpgradeThread  = nil
local AutoUpgradeDelay   = 0.5
local AutoUpgradeCycle   = 3.0
local UpgradeResults     = { success = 0, failed = 0 }

local function startAutoUpgrade()
    UpgradeResults = { success = 0, failed = 0 }
    AutoUpgradeThread = task.spawn(function()
        while AutoUpgradeEnabled do
            local rf      = getRF("UpgradeService")
            local slimeRF = getRF("SlimeUpgradeService")
            for _, slot in ipairs(UPGRADE_SLOTS) do
                if not AutoUpgradeEnabled then break end
                if rf then
                    local ok = pcall(function()
                        rf:InvokeServer(unpack({ "requestUnlock", slot }))
                    end)
                    if ok then UpgradeResults.success += 1 end
                end
                if slimeRF then
                    pcall(function()
                        slimeRF:InvokeServer(unpack({ "requestUnlock", slot }))
                    end)
                end
                task.wait(AutoUpgradeDelay)
            end
            notify('Auto Upgrade', ('Cycle done. %d slots attempted.'):format(UpgradeResults.success), 3)
            UpgradeResults = { success = 0, failed = 0 }
            task.wait(AutoUpgradeCycle)
        end
    end)
end

local function stopAutoUpgrade()
    AutoUpgradeEnabled = false
    if AutoUpgradeThread then task.cancel(AutoUpgradeThread); AutoUpgradeThread = nil end
end

-- ========================================
--              RAYFIELD UI
-- ========================================

local Window = Rayfield:CreateWindow({
    Name             = "Junior Hub",
    LoadingTitle     = "Junior Hub",
    LoadingSubtitle  = "by Junior",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "JuniorHub",
        FileName = "Config",
    },
    KeySystem = false,
})

-- ========================================
--              TABS
-- ========================================

local MainTab     = Window:CreateTab("Main",     4483362458)
local FlyingTab   = Window:CreateTab("Flying",   4483362458)
local ESPTab      = Window:CreateTab("ESP",      4483362458)
local MiscTab     = Window:CreateTab("Misc",     4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- ========================================
--           MAIN TAB — AUTOMATION
-- ========================================

local AutoSection = MainTab:CreateSection("Automation")

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

MainTab:CreateLabel("Claims: basic → big → huge → shiny → inverted")

MainTab:CreateToggle({
    Name        = "Auto Buy Zone",
    CurrentValue = false,
    Flag        = "AutoBuyZoneToggle",
    Callback    = function(value)
        AutoBuyZoneEnabled = value
        if value then startAutoBuyZone() else stopAutoBuyZone() end
    end,
})

-- ===== FAST ROLL + CODES =====

local RollSection = MainTab:CreateSection("Fast Roll")

MainTab:CreateToggle({
    Name        = "Fast Roll",
    CurrentValue = false,
    Flag        = "FastRollToggle",
    Callback    = function(value)
        FastRollEnabled = value
        if value then startFastRoll() else stopFastRoll() end
    end,
})

MainTab:CreateLabel("Roll delay fixed at 1.0s")

local CodesSection = MainTab:CreateSection("Codes")

MainTab:CreateButton({
    Name     = "Redeem All Codes",
    Callback = redeemAllCodes,
})

MainTab:CreateLabel("sliming • goingBananas • giveMeLuckNOW • SPARKLEZ")
MainTab:CreateLabel("2muchluck • test • craftAway • gullible • time2Grind")

-- ===== AUTO UPGRADE =====

local UpgradeSection = MainTab:CreateSection("Auto Upgrade")

MainTab:CreateToggle({
    Name        = "Auto Upgrade",
    CurrentValue = false,
    Flag        = "AutoUpgradeToggle",
    Callback    = function(value)
        AutoUpgradeEnabled = value
        if value then startAutoUpgrade() else stopAutoUpgrade() end
    end,
})

MainTab:CreateSlider({
    Name         = "Cycle Delay (seconds)",
    Range        = {1, 30},
    Increment    = 1,
    Suffix       = "s",
    CurrentValue = 3,
    Flag         = "UpgradeCycleSlider",
    Callback     = function(value) AutoUpgradeCycle = value end,
})

MainTab:CreateSlider({
    Name         = "Per-Slot Delay (x0.1s)",
    Range        = {1, 20},
    Increment    = 1,
    Suffix       = " x0.1s",
    CurrentValue = 5,
    Flag         = "UpgradeSlotDelaySlider",
    Callback     = function(value) AutoUpgradeDelay = value * 0.1 end,
})

MainTab:CreateButton({
    Name     = "Run One Cycle Now",
    Callback = function()
        local rf      = getRF("UpgradeService")
        local slimeRF = getRF("SlimeUpgradeService")
        if not rf and not slimeRF then notify('Auto Upgrade', 'No upgrade remotes found!', 3); return end
        notify('Auto Upgrade', 'Running one upgrade cycle...', 2)
        task.spawn(function()
            local count = 0
            for _, slot in ipairs(UPGRADE_SLOTS) do
                if rf then
                    pcall(function() rf:InvokeServer(unpack({ "requestUnlock", slot })) end)
                end
                if slimeRF then
                    pcall(function() slimeRF:InvokeServer(unpack({ "requestUnlock", slot })) end)
                end
                count += 1
                task.wait(AutoUpgradeDelay)
            end
            notify('Auto Upgrade', ('Done! Attempted %d slots.'):format(count), 3)
        end)
    end,
})

MainTab:CreateLabel("Covers: Loot Tree, Main, Fire/Ice/Lightning/Sword/Magician trees")

-- ===== AUTO USE ITEMS =====

local ItemsSection = MainTab:CreateSection("Auto Use Items / Potions")

MainTab:CreateToggle({
    Name        = "Luck Potion",
    CurrentValue = false,
    Flag        = "ItemLuckToggle",
    Callback    = function(value)
        ItemEnabled.luck = value
        if value then startItem("luck") else stopItem("luck") end
    end,
})

MainTab:CreateToggle({
    Name        = "Ultra Luck Potion",
    CurrentValue = false,
    Flag        = "ItemUltraLuckToggle",
    Callback    = function(value)
        ItemEnabled.ultraLuck = value
        if value then startItem("ultraLuck") else stopItem("ultraLuck") end
    end,
})

MainTab:CreateToggle({
    Name        = "Roll Speed Potion",
    CurrentValue = false,
    Flag        = "ItemRollSpeedToggle",
    Callback    = function(value)
        ItemEnabled.rollSpeed = value
        if value then startItem("rollSpeed") else stopItem("rollSpeed") end
    end,
})

MainTab:CreateToggle({
    Name        = "Big Dice",
    CurrentValue = false,
    Flag        = "ItemBigDiceToggle",
    Callback    = function(value)
        ItemEnabled.bigDice = value
        if value then startItem("bigDice") else stopItem("bigDice") end
    end,
})

MainTab:CreateButton({
    Name     = "Use All Items Now",
    Callback = function()
        for key in pairs(ItemEnabled) do
            ItemEnabled[key] = true
            startItem(key)
        end
        Rayfield.Flags.ItemLuckToggle:Set(true)
        Rayfield.Flags.ItemUltraLuckToggle:Set(true)
        Rayfield.Flags.ItemRollSpeedToggle:Set(true)
        Rayfield.Flags.ItemBigDiceToggle:Set(true)
        notify('Items', 'All items enabled!', 2)
    end,
})

MainTab:CreateButton({
    Name     = "Stop All Items",
    Callback = function()
        stopAllItems()
        Rayfield.Flags.ItemLuckToggle:Set(false)
        Rayfield.Flags.ItemUltraLuckToggle:Set(false)
        Rayfield.Flags.ItemRollSpeedToggle:Set(false)
        Rayfield.Flags.ItemBigDiceToggle:Set(false)
        notify('Items', 'All items stopped.', 2)
    end,
})

MainTab:CreateLabel("Each item fires its remote every 2 seconds")

-- ===== FAKE STATS =====

local FakeSection = MainTab:CreateSection("Fake Stats (Client-Side Only)")

MainTab:CreateLabel("!! Visual only — NOT real or server-synced !!")

MainTab:CreateToggle({
    Name        = "Fake Roll Count",
    CurrentValue = false,
    Flag        = "FakeRollsToggle",
    Callback    = function(value)
        FakeRollsEnabled = value
        if value then applyFakeRolls() else removeFakeRolls() end
    end,
})

MainTab:CreateInput({
    Name        = "Fake Roll Value",
    PlaceholderText = "Enter roll count...",
    RemoveTextAfterFocusLost = false,
    Flag        = "FakeRollInput",
    Callback    = function(value)
        FakeRollValue = tonumber(value) or 1
    end,
})

MainTab:CreateToggle({
    Name        = "Fake Best Roll",
    CurrentValue = false,
    Flag        = "FakeBestToggle",
    Callback    = function(value)
        FakeBestEnabled = value
        if value then applyFakeBest() else removeFakeBest() end
    end,
})

MainTab:CreateInput({
    Name        = "Fake Best Roll Value",
    PlaceholderText = "Enter best roll...",
    RemoveTextAfterFocusLost = false,
    Flag        = "FakeBestInput",
    Callback    = function(value)
        FakeBestValue = tonumber(value) or 1
    end,
})

MainTab:CreateLabel("Only YOU see the fake values — server unaffected")

-- ========================================
--           FLYING TAB
-- ========================================

local FlightSection = FlyingTab:CreateSection("Flight")

FlyToggleElement = FlyingTab:CreateToggle({
    Name        = "Enable Flight  [F]",
    CurrentValue = false,
    Flag        = "FlyToggle",
    Callback    = function(value) setFly(value) end,
})

FlyingTab:CreateSlider({
    Name         = "Flight Speed",
    Range        = {10, 500},
    Increment    = 1,
    Suffix       = " studs/s",
    CurrentValue = 60,
    Flag         = "FlySpeedSlider",
    Callback     = function(v) FlySpeed = v end,
})

FlyingTab:CreateLabel("W/A/S/D = move  |  Space = up  |  Shift = down")
FlyingTab:CreateLabel("Press F to toggle flight")

-- Fly keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        local new = not FlyEnabled
        setFly(new)
        Rayfield.Flags.FlyToggle:Set(new)
    end
end)

local MovSection = FlyingTab:CreateSection("Movement")

FlyingTab:CreateSlider({
    Name         = "Walk Speed",
    Range        = {1, 300},
    Increment    = 1,
    Suffix       = " studs/s",
    CurrentValue = 16,
    Flag         = "WalkSpeedSlider",
    Callback     = function(value)
        local hum = getHumanoid(); if hum then hum.WalkSpeed = value end
    end,
})

FlyingTab:CreateSlider({
    Name         = "Jump Power",
    Range        = {0, 300},
    Increment    = 1,
    CurrentValue = 50,
    Flag         = "JumpPowerSlider",
    Callback     = function(value)
        local hum = getHumanoid()
        if hum then hum.UseJumpPower = true; hum.JumpPower = value end
    end,
})

FlyingTab:CreateToggle({
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

NoclipToggleElement = FlyingTab:CreateToggle({
    Name        = "Noclip  [N]",
    CurrentValue = false,
    Flag        = "NoclipToggle",
    Callback    = function(value) setNoclip(value) end,
})

-- Noclip keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.N then
        local new = not NoclipEnabled
        setNoclip(new)
        Rayfield.Flags.NoclipToggle:Set(new)
    end
end)

FlyingTab:CreateButton({
    Name     = "Reset Movement to Defaults",
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.UseJumpPower = true end
        Rayfield.Flags.WalkSpeedSlider:Set(16)
        Rayfield.Flags.JumpPowerSlider:Set(50)
        notify('Movement', 'Movement reset to defaults.', 2)
    end,
})

-- ========================================
--           ESP TAB
-- ========================================

local ESPSection = ESPTab:CreateSection("Player ESP")

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
    Name         = "Max Visible Distance",
    Range        = {50, 2000},
    Increment    = 10,
    Suffix       = " studs",
    CurrentValue = 500,
    Flag         = "ESPDistSlider",
    Callback     = function(value)
        ESPMaxDist = value
    end,
})

ESPTab:CreateLabel("Black bold text with white stroke")
ESPTab:CreateLabel("Always visible through walls")
ESPTab:CreateLabel("Hidden beyond max distance")

-- ========================================
--           MISC TAB
-- ========================================

local VisualSection = MiscTab:CreateSection("Visual Tweaks")

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
    Callback    = function(value) if value then removeShadows() else restoreShadows() end end,
})

MiscTab:CreateToggle({
    Name        = "No Grass / Decorations",
    CurrentValue = false,
    Flag        = "NoGrassToggle",
    Callback    = function(value) if value then removeGrass() else restoreGrass() end end,
})

MiscTab:CreateToggle({
    Name        = "No Textures",
    CurrentValue = false,
    Flag        = "NoTexturesToggle",
    Callback    = function(value) if value then removeTextures() else restoreTextures() end end,
})

MiscTab:CreateToggle({
    Name        = "No Post-Processing FX",
    CurrentValue = false,
    Flag        = "NoPostFXToggle",
    Callback    = function(value) if value then removePostFX() else restorePostFX() end end,
})

MiscTab:CreateLabel("Tip: No Shadows + No Grass = big FPS boost")

local LightingSection = MiscTab:CreateSection("Lighting")

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
    Name         = "Time of Day",
    Range        = {0, 24},
    Increment    = 0.5,
    Suffix       = ":00",
    CurrentValue = 14,
    Flag         = "TimeSlider",
    Callback     = function(value) lockTime(value) end,
})

MiscTab:CreateButton({
    Name     = "Unlock Time",
    Callback = function()
        unlockTime(); notify('Lighting', 'Time unlocked.', 2)
    end,
})

MiscTab:CreateLabel("0 = midnight  |  12 = noon  |  18 = dusk")

-- ========================================
--           SETTINGS TAB
-- ========================================

local UtilSection = SettingsTab:CreateSection("Utilities")

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
    Name     = "Copy UserId",
    Callback = function()
        pcall(function() setclipboard(tostring(LocalPlayer.UserId)) end)
        notify('Utilities', 'UserId: ' .. tostring(LocalPlayer.UserId), 2)
    end,
})

SettingsTab:CreateButton({
    Name     = "Copy Game ID",
    Callback = function()
        pcall(function() setclipboard(tostring(game.PlaceId)) end)
        notify('Utilities', 'Place ID: ' .. game.PlaceId, 3)
    end,
})

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
        AutoBuyZoneEnabled    = false
        AutoUpgradeEnabled    = false
        FakeRollsEnabled      = false
        FakeBestEnabled       = false

        setFly(false); setNoclip(false); disableESP()
        stopAutoEquip(); stopAutoRebirth(); stopFastRoll(); stopAutoClaimIndex()
        stopAutoBuyZone(); stopAllItems(); stopAutoUpgrade()
        removeFakeRolls(); removeFakeBest()
        removeNoFog(); restoreShadows(); restoreGrass()
        restoreTextures(); restorePostFX(); removeFullBright(); unlockTime()

        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end

        -- Reset all Rayfield flags
        local flagsToReset = {
            "FlyToggle", "InfiniteJumpToggle", "NoclipToggle", "ESPToggle",
            "AutoEquipToggle", "AutoRebirthToggle", "FastRollToggle",
            "AutoClaimIndexToggle", "AutoBuyZoneToggle", "AutoUpgradeToggle",
            "NoFogToggle", "NoShadowsToggle", "NoGrassToggle",
            "NoTexturesToggle", "NoPostFXToggle", "FullBrightToggle",
            "ItemLuckToggle", "ItemUltraLuckToggle", "ItemRollSpeedToggle",
            "ItemBigDiceToggle", "FakeRollsToggle", "FakeBestToggle",
        }
        for _, flag in ipairs(flagsToReset) do
            if Rayfield.Flags[flag] then
                Rayfield.Flags[flag]:Set(false)
            end
        end
        if Rayfield.Flags.WalkSpeedSlider then Rayfield.Flags.WalkSpeedSlider:Set(16) end
        if Rayfield.Flags.JumpPowerSlider  then Rayfield.Flags.JumpPowerSlider:Set(50) end

        notify('Junior Hub', 'All features stopped and reset.', 2)
    end,
})

SettingsTab:CreateLabel('"Stop All" resets every feature to default')

-- ========================================
--              LOADED
-- ========================================

Rayfield:LoadConfiguration()
notify('Junior Hub', 'Junior Hub loaded successfully!', 3)
