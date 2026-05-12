-- Grow A Garden auto farm script
-- Place this LocalScript in StarterPlayerScripts or another LocalScript-friendly location.
-- This script uses a built-in Roblox GUI and does not require WindUI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

if RunService:IsServer() then
    warn("Grow A Garden Auto Farm must run in a LocalScript on the client.")
    return
end

local function getLocalPlayer(timeout)
    local player = Players.LocalPlayer
    if player then
        return player
    end

    local startTime = tick()
    while tick() - startTime < (timeout or 10) do
        player = Players.LocalPlayer
        if player then
            return player
        end
        task.wait(0.1)
    end
    return nil
end

local LocalPlayer = getLocalPlayer()
if not LocalPlayer then
    warn("Grow A Garden Auto Farm could not find LocalPlayer. This script must run as a LocalScript.")
    return
end

local AUTO_FARM_DELAY = 0.15
local AUTO_COLLECT_DELAY = 0.2
local AUTO_BUY_DELAY = 1.0
local AUTO_PLANT_DELAY = 0.5
local AUTO_SELL_DELAY = 1.0
local AUTO_FERTILIZE_DELAY = 2.0
local AUTO_UPGRADE_DELAY = 3.0

local chosenSeed = "Apple"
local auraRadius = 45
local enabled = {
    autoFarm = false,
    autoCollect = false,
    autoBuySeed = false,
    autoSell = false,
    autoPlant = false,
    autoFertilize = false,
    autoUpgrade = false,
}

local seedOptions = {
    "Apple",
    "Banana",
    "Cherry",
    "Pumpkin",
    "Melon",
    "Mystery",
}

local function findRemote(nameCandidates)
    local searchParents = {
        ReplicatedStorage,
        ReplicatedFirst,
        LocalPlayer:FindFirstChild("PlayerGui"),
        LocalPlayer:FindFirstChild("Backpack"),
    }

    for _, parent in ipairs(searchParents) do
        if parent then
            for _, obj in ipairs(parent:GetDescendants()) do
                if obj:IsA("RemoteFunction") or obj:IsA("RemoteEvent") then
                    local objName = obj.Name:lower()
                    for _, candidate in ipairs(nameCandidates) do
                        if objName:find(candidate:lower(), 1, true) then
                            return obj
                        end
                    end
                end
            end
        end
    end

    return nil
end

local function fireRemote(nameCandidates, payload)
    local remote = findRemote(nameCandidates)
    if not remote then
        return false
    end

    if remote:IsA("RemoteFunction") then
        local success, result = pcall(function()
            return remote:InvokeServer(payload)
        end)
        return success, result
    elseif remote:IsA("RemoteEvent") then
        local success = pcall(function()
            remote:FireServer(payload)
        end)
        return success
    end

    return false
end

local function findPlace(nameCandidates)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            for _, candidate in ipairs(nameCandidates) do
                if name:find(candidate:lower(), 1, true) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function teleportTo(nameCandidates)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    local destination = findPlace(nameCandidates)
    if not destination then
        return false
    end

    root.CFrame = destination.CFrame + Vector3.new(0, 5, 0)
    return true
end

local function buySeed()
    local candidates = {"BuySeed", "PurchaseSeed", "SeedPurchase", "BuyItem"}
    local payload = {
        SeedName = chosenSeed,
        Seed = chosenSeed,
        name = chosenSeed,
        seed = chosenSeed,
    }
    fireRemote(candidates, payload)
end

local function sellInventory()
    local candidates = {"SellAll", "Sell", "SellFruit", "SellCrops", "CashOut"}
    fireRemote(candidates, {})
end

local function plantSeed()
    local candidates = {"PlantSeed", "Plant", "SpawnCrop", "CreatePlant"}
    local payload = {
        SeedName = chosenSeed,
        Seed = chosenSeed,
        name = chosenSeed,
        seed = chosenSeed,
    }
    fireRemote(candidates, payload)
end

local function applyFertilizer()
    local candidates = {"Fertilize", "ApplyFertilizer", "UseFertilizer", "Fertilizer", "FeedPlants"}
    fireRemote(candidates, {})
end

local function upgradePlot()
    local candidates = {"UpgradePlot", "UpgradeFarm", "UpgradeGarden", "UpgradeTool", "Upgrade"}
    fireRemote(candidates, {})
end

local function teleportToFarm()
    return teleportTo({"Farm", "Field", "Garden", "Plot", "FarmPlot", "Fruit Field", "Harvest Area"})
end

local function safeTask(fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("Grow A Garden Auto Farm error:", err)
    end
end

task.spawn(function()
    while true do
        if enabled.autoCollect then
            safeTask(collectFruitRemoteOnly)
            task.wait(AUTO_COLLECT_DELAY)
        elseif enabled.autoFarm then
            safeTask(collectFruit)
            task.wait(AUTO_FARM_DELAY)
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while task.wait(AUTO_BUY_DELAY) do
        if enabled.autoBuySeed then
            safeTask(function()
                teleportTo({"Seed Shop", "SeedShot", "Seed Shop", "Seed Vendor", "SeedVendor", "SeedPurchase", "Shop"})
                buySeed()
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(AUTO_PLANT_DELAY) do
        if enabled.autoPlant then
            safeTask(plantSeed)
        end
    end
end)

task.spawn(function()
    while task.wait(AUTO_FERTILIZE_DELAY) do
        if enabled.autoFertilize then
            safeTask(applyFertilizer)
        end
    end
end)

task.spawn(function()
    while task.wait(AUTO_UPGRADE_DELAY) do
        if enabled.autoUpgrade then
            safeTask(upgradePlot)
        end
    end
end)

task.spawn(function()
    while task.wait(AUTO_SELL_DELAY) do
        if enabled.autoSell then
            safeTask(function()
                teleportTo({"Sell Place", "SellStation", "Sell Area", "SellShop", "CashOut", "Cashier"})
                sellInventory()
            end)
        end
    end
end)

local function isCollectibleFruit(obj)
    if not obj:IsA("BasePart") then
        return false
    end

    local name = obj.Name:lower()
    return name:find("fruit", 1, true)
        or name:find("apple", 1, true)
        or name:find("banana", 1, true)
        or name:find("cherry", 1, true)
        or name:find("pumpkin", 1, true)
        or name:find("melon", 1, true)
end

local function collectFruit()
    local candidates = {"CollectFruit", "Collect", "HarvestFruit", "PickupFruit", "CollectItem"}
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isCollectibleFruit(obj) then
            if root then
                local distance = (root.Position - obj.Position).Magnitude
                if distance > auraRadius then
                    root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 4, 0))
                    task.wait(0.06)
                end
            end

            local payload = {
                fruit = obj,
                FruitName = obj.Name,
                Name = obj.Name,
                Position = obj.Position,
            }
            fireRemote(candidates, payload)
            task.wait(0.04)
        end
    end
end

local function collectFruitRemoteOnly()
    local candidates = {"CollectFruit", "Collect", "HarvestFruit", "PickupFruit", "CollectItem"}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isCollectibleFruit(obj) then
            local payload = {
                fruit = obj,
                FruitName = obj.Name,
                Name = obj.Name,
                Position = obj.Position,
            }
            fireRemote(candidates, payload)
            task.wait(0.04)
        end
    end
end

local function createGui()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    if not playerGui then
        warn("Grow A Garden Auto Farm UI could not find PlayerGui.")
        return
    end

    local existingGui = playerGui:FindFirstChild("GrowAGardenAutoFarmUI")
    if existingGui then
        existingGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GrowAGardenAutoFarmUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 760)
    frame.Position = UDim2.new(0, 16, 0.08, 0)
    frame.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 14)
    frameCorner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 44)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Grow A Garden Auto Farm"
    title.TextColor3 = Color3.fromRGB(235, 235, 235)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 20)
    subtitle.Position = UDim2.new(0, 0, 0, 46)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Aura fruit collection + full farm automation"
    subtitle.TextColor3 = Color3.fromRGB(175, 175, 175)
    subtitle.TextScaled = false
    subtitle.TextSize = 16
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = frame

    local function makeToggle(name, position, key)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 180, 0, 24)
        label.Position = position
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(235, 235, 235)
        label.Text = name
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 16
        label.Parent = frame

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 140, 0, 30)
        button.Position = position + UDim2.new(0, 0, 0, 26)
        button.BackgroundColor3 = Color3.fromRGB(54, 104, 189)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.Gotham
        button.TextScaled = true
        button.Text = "Off"
        button.BorderSizePixel = 0
        button.Parent = frame

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = button

        button.MouseButton1Click:Connect(function()
            enabled[key] = not enabled[key]
            button.Text = enabled[key] and "On" or "Off"
            button.BackgroundColor3 = enabled[key] and Color3.fromRGB(88, 210, 110) or Color3.fromRGB(54, 104, 189)
        end)
    end

    makeToggle("Auto Farm", UDim2.new(0, 12, 0, 84), "autoFarm")
    makeToggle("Auto Collect", UDim2.new(0, 198, 0, 84), "autoCollect")
    makeToggle("Auto Buy Seed", UDim2.new(0, 12, 0, 164), "autoBuySeed")
    makeToggle("Auto Plant Seed", UDim2.new(0, 198, 0, 164), "autoPlant")
    makeToggle("Auto Sell", UDim2.new(0, 12, 0, 244), "autoSell")
    makeToggle("Auto Fertilize", UDim2.new(0, 198, 0, 244), "autoFertilize")
    makeToggle("Auto Upgrade", UDim2.new(0, 12, 0, 324), "autoUpgrade")

    local auraRadiusLabel = Instance.new("TextLabel")
    auraRadiusLabel.Size = UDim2.new(0, 160, 0, 24)
    auraRadiusLabel.Position = UDim2.new(0, 198, 0, 324)
    auraRadiusLabel.BackgroundTransparency = 1
    auraRadiusLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
    auraRadiusLabel.Text = "Aura Radius"
    auraRadiusLabel.TextXAlignment = Enum.TextXAlignment.Left
    auraRadiusLabel.Font = Enum.Font.Gotham
    auraRadiusLabel.TextSize = 16
    auraRadiusLabel.Parent = frame

    local auraRadiusBox = Instance.new("TextBox")
    auraRadiusBox.Size = UDim2.new(0, 160, 0, 32)
    auraRadiusBox.Position = UDim2.new(0, 198, 0, 354)
    auraRadiusBox.BackgroundColor3 = Color3.fromRGB(36, 46, 64)
    auraRadiusBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    auraRadiusBox.Font = Enum.Font.Gotham
    auraRadiusBox.TextScaled = true
    auraRadiusBox.Text = tostring(auraRadius)
    auraRadiusBox.ClearTextOnFocus = false
    auraRadiusBox.TextXAlignment = Enum.TextXAlignment.Center
    auraRadiusBox.BorderSizePixel = 0
    auraRadiusBox.Parent = frame

    local auraRadiusBoxCorner = Instance.new("UICorner")
    auraRadiusBoxCorner.CornerRadius = UDim.new(0, 8)
    auraRadiusBoxCorner.Parent = auraRadiusBox

    auraRadiusBox.FocusLost:Connect(function()
        local newRadius = tonumber(auraRadiusBox.Text)
        if newRadius and newRadius > 0 then
            auraRadius = newRadius
        else
            auraRadiusBox.Text = tostring(auraRadius)
        end
    end)

    local seedLabel = Instance.new("TextLabel")
    seedLabel.Size = UDim2.new(0, 340, 0, 24)
    seedLabel.Position = UDim2.new(0, 20, 0, 414)
    seedLabel.BackgroundTransparency = 1
    seedLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
    seedLabel.Text = "Selected Seed: " .. chosenSeed
    seedLabel.TextXAlignment = Enum.TextXAlignment.Left
    seedLabel.Font = Enum.Font.Gotham
    seedLabel.TextSize = 16
    seedLabel.Parent = frame

    local seedButton = Instance.new("TextButton")
    seedButton.Size = UDim2.new(0, 340, 0, 36)
    seedButton.Position = UDim2.new(0, 20, 0, 444)
    seedButton.BackgroundColor3 = Color3.fromRGB(36, 46, 64)
    seedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    seedButton.Font = Enum.Font.Gotham
    seedButton.Text = "Change Seed"
    seedButton.TextScaled = true
    seedButton.BorderSizePixel = 0
    seedButton.Parent = frame

    local seedButtonCorner = Instance.new("UICorner")
    seedButtonCorner.CornerRadius = UDim.new(0, 8)
    seedButtonCorner.Parent = seedButton

    local seedList = Instance.new("Frame")
    seedList.Size = UDim2.new(0, 340, 0, 0)
    seedList.Position = UDim2.new(0, 20, 0, 486)
    seedList.BackgroundColor3 = Color3.fromRGB(34, 44, 60)
    seedList.BorderSizePixel = 0
    seedList.ClipsDescendants = true
    seedList.Parent = frame

    local seedListCorner = Instance.new("UICorner")
    seedListCorner.CornerRadius = UDim.new(0, 8)
    seedListCorner.Parent = seedList

    local function refreshSeedList()
        seedList:ClearAllChildren()
        local innerCorner = Instance.new("UICorner")
        innerCorner.CornerRadius = UDim.new(0, 8)
        innerCorner.Parent = seedList

        for i, seedName in ipairs(seedOptions) do
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, 0, 0, 34)
            option.Position = UDim2.new(0, 0, 0, (i - 1) * 40)
            option.BackgroundColor3 = Color3.fromRGB(48, 62, 86)
            option.TextColor3 = Color3.fromRGB(255, 255, 255)
            option.Font = Enum.Font.Gotham
            option.Text = seedName
            option.TextScaled = true
            option.BorderSizePixel = 0
            option.Parent = seedList

            option.MouseButton1Click:Connect(function()
                chosenSeed = seedName
                seedLabel.Text = "Selected Seed: " .. chosenSeed
                seedList.Size = UDim2.new(0, 340, 0, 0)
            end)
        end
    end

    seedButton.MouseButton1Click:Connect(function()
        if seedList.Size.Y.Offset == 0 then
            seedList.Size = UDim2.new(0, 340, 0, #seedOptions * 40)
            refreshSeedList()
        else
            seedList.Size = UDim2.new(0, 340, 0, 0)
        end
    end)

    local function createAction(name, position, callback)
        local action = Instance.new("TextButton")
        action.Size = UDim2.new(0, 172, 0, 36)
        action.Position = position
        action.BackgroundColor3 = Color3.fromRGB(76, 124, 202)
        action.TextColor3 = Color3.fromRGB(255, 255, 255)
        action.Font = Enum.Font.Gotham
        action.Text = name
        action.TextScaled = true
        action.BorderSizePixel = 0
        action.Parent = frame

        local actionCorner = Instance.new("UICorner")
        actionCorner.CornerRadius = UDim.new(0, 8)
        actionCorner.Parent = action

        action.MouseButton1Click:Connect(callback)
        return action
    end

    createAction("Collect Now", UDim2.new(0, 20, 0, 540), function()
        safeTask(collectFruit)
    end)
    createAction("Plant Now", UDim2.new(0, 198, 0, 540), function()
        safeTask(plantSeed)
    end)
    createAction("Buy Seed", UDim2.new(0, 20, 0, 588), function()
        safeTask(function()
            teleportTo({"Seed Shop", "SeedShot", "Seed Shop", "Seed Vendor", "SeedVendor", "SeedPurchase", "Shop"})
            buySeed()
        end)
    end)
    createAction("Sell Now", UDim2.new(0, 198, 0, 588), function()
        safeTask(function()
            teleportTo({"Sell Place", "SellStation", "Sell Area", "SellShop", "CashOut", "Cashier"})
            sellInventory()
        end)
    end)
    createAction("Teleport Farm", UDim2.new(0, 20, 0, 636), function()
        safeTask(teleportToFarm)
    end)
    createAction("Teleport Shop", UDim2.new(0, 198, 0, 636), function()
        safeTask(function()
            teleportTo({"Seed Shop", "SeedShot", "Seed Shop", "Seed Vendor", "SeedVendor", "SeedPurchase", "Shop"})
        end)
    end)

    local helpText = Instance.new("TextLabel")
    helpText.Size = UDim2.new(0, 340, 0, 40)
    helpText.Position = UDim2.new(0, 20, 0, 684)
    helpText.BackgroundTransparency = 1
    helpText.TextColor3 = Color3.fromRGB(170, 170, 170)
    helpText.Text = "Auto Farm uses aura-style collection. Use Buy Seed and Plant to keep your field active."
    helpText.TextWrapped = true
    helpText.Font = Enum.Font.Gotham
    helpText.TextSize = 14
    helpText.TextXAlignment = Enum.TextXAlignment.Left
    helpText.TextYAlignment = Enum.TextYAlignment.Top
    helpText.Parent = frame
end

createGui()

print("Grow A Garden Auto Farm script loaded.")
