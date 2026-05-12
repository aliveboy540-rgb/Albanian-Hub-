-- Grow A Garden auto farm script
-- Place this LocalScript in StarterPlayerScripts or a LocalScript-friendly location
-- Requires a WindUI module in ReplicatedStorage named "WindUI" if you want the WindUI controls.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local AUTO_FARM_DELAY = 0.15
local AUTO_COLLECT_DELAY = 0.2
local AUTO_BUY_DELAY = 1.0
local AUTO_PLANT_DELAY = 0.5
local AUTO_SELL_DELAY = 1.0

local chosenSeed = "Apple"
local enabled = {
    autoFarm = false,
    autoCollect = false,
    autoBuySeed = false,
    autoSell = false,
    autoPlant = false,
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
    local folders = {ReplicatedStorage, Workspace, LocalPlayer:FindFirstChild("PlayerGui") or nil}
    for _, folder in ipairs(folders) do
        if folder then
            for _, name in ipairs(nameCandidates) do
                local obj = folder:FindFirstChild(name, true)
                if obj and (obj:IsA("RemoteFunction") or obj:IsA("RemoteEvent")) then
                    return obj
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
        pcall(function()
            remote:FireServer(payload)
        end)
        return true
    end
    return false
end

local function findPlace(nameCandidates)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Part") then
            local name = obj.Name:lower()
            for _, candidate in ipairs(nameCandidates) do
                if name:find(candidate:lower()) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function teleportTo(nameCandidates)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    local destination = findPlace(nameCandidates)
    if not destination then
        return false
    end
    local root = LocalPlayer.Character.HumanoidRootPart
    root.CFrame = destination.CFrame + Vector3.new(0, 5, 0)
    return true
end

local function collectFruit()
    local candidates = {"CollectFruit", "Collect", "HarvestFruit", "PickupFruit", "CollectItem"}
    local fruitCandidates = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("fruit") or name:find("apple") or name:find("banana") or name:find("cherry") or name:find("pumpkin") or name:find("melon") then
                table.insert(fruitCandidates, obj)
            end
        end
    end

    for _, fruit in ipairs(fruitCandidates) do
        fireRemote(candidates, fruit)
    end
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

local function safeTask(fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("AutoFarm error:", err)
    end
end

spawn(function()
    while RunService.Heartbeat:Wait() do
        if enabled.autoCollect then
            safeTask(collectFruit)
            task.wait(AUTO_COLLECT_DELAY)
        elseif enabled.autoFarm then
            safeTask(collectFruit)
            task.wait(AUTO_FARM_DELAY)
        else
            task.wait(0.25)
        end
    end
end)

spawn(function()
    while task.wait(AUTO_BUY_DELAY) do
        if enabled.autoBuySeed then
            safeTask(function()
                teleportTo({"Seed Shop", "SeedShot", "Seed Shot", "SeedVendor", "SeedPurchase", "Shop"})
                buySeed()
            end)
        end
    end
end)

spawn(function()
    while task.wait(AUTO_PLANT_DELAY) do
        if enabled.autoPlant then
            safeTask(plantSeed)
        end
    end
end)

spawn(function()
    while task.wait(AUTO_SELL_DELAY) do
        if enabled.autoSell then
            safeTask(function()
                teleportTo({"Sell Place", "SellStation", "Sell Area", "SellShop", "CashOut", "Cashier"})
                sellInventory()
            end)
        end
    end
end)

-- UI setup
local WindUI
local success, result = pcall(function()
    return require(ReplicatedStorage:WaitForChild("WindUI"))
end)
if success and type(result) == "table" then
    WindUI = result
end

local function createFallbackUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GrowAGardenAutoFarmUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 420)
    frame.Position = UDim2.new(0, 20, 0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Grow A Garden Auto Farm"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local function makeButton(text, position, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 140, 0, 34)
        button.Position = position
        button.BackgroundColor3 = Color3.fromRGB(55, 115, 220)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.Gotham
        button.Text = text
        button.TextScaled = true
        button.Parent = frame
        button.MouseButton1Click:Connect(callback)
        return button
    end

    local statusLabels = {}
    local function makeToggle(name, position, key)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 200, 0, 24)
        label.Position = position
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(235, 235, 235)
        label.Text = name
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 16
        label.Parent = frame

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 110, 0, 28)
        button.Position = position + UDim2.new(0, 0, 0, 22)
        button.BackgroundColor3 = Color3.fromRGB(48, 94, 172)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.Gotham
        button.TextScaled = true
        button.Text = "Off"
        button.Parent = frame
        button.MouseButton1Click:Connect(function()
            enabled[key] = not enabled[key]
            button.Text = enabled[key] and "On" or "Off"
            button.BackgroundColor3 = enabled[key] and Color3.fromRGB(88, 210, 110) or Color3.fromRGB(48, 94, 172)
        end)
        return button
    end

    makeToggle("Auto Farm", UDim2.new(0, 10, 0, 60), "autoFarm")
    makeToggle("Auto Collect", UDim2.new(0, 170, 0, 60), "autoCollect")
    makeToggle("Auto Buy Seed", UDim2.new(0, 10, 0, 130), "autoBuySeed")
    makeToggle("Auto Plant Seed", UDim2.new(0, 170, 0, 130), "autoPlant")
    makeToggle("Auto Sell", UDim2.new(0, 10, 0, 200), "autoSell")

    local seedLabel = Instance.new("TextLabel")
    seedLabel.Size = UDim2.new(0, 320, 0, 26)
    seedLabel.Position = UDim2.new(0, 10, 0, 280)
    seedLabel.BackgroundTransparency = 1
    seedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    seedLabel.Text = "Choose Seed: " .. chosenSeed
    seedLabel.TextXAlignment = Enum.TextXAlignment.Left
    seedLabel.Font = Enum.Font.Gotham
    seedLabel.TextSize = 16
    seedLabel.Parent = frame

    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(0, 320, 0, 36)
    dropdown.Position = UDim2.new(0, 10, 0, 310)
    dropdown.BackgroundColor3 = Color3.fromRGB(40, 50, 63)
    dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.Font = Enum.Font.Gotham
    dropdown.Text = "Change Seed"
    dropdown.TextScaled = true
    dropdown.Parent = frame

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(0, 320, 0, 0)
    listFrame.Position = UDim2.new(0, 10, 0, 358)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = frame

    local function refreshSeedList()
        listFrame:ClearAllChildren()
        for i, seedName in ipairs(seedOptions) do
            local seedButton = Instance.new("TextButton")
            seedButton.Size = UDim2.new(1, 0, 0, 30)
            seedButton.Position = UDim2.new(0, 0, 0, (i - 1) * 34)
            seedButton.BackgroundColor3 = Color3.fromRGB(60, 72, 98)
            seedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            seedButton.Font = Enum.Font.Gotham
            seedButton.Text = seedName
            seedButton.TextScaled = true
            seedButton.Parent = listFrame
            seedButton.MouseButton1Click:Connect(function()
                chosenSeed = seedName
                seedLabel.Text = "Choose Seed: " .. chosenSeed
                listFrame.Size = UDim2.new(0, 320, 0, 0)
            end)
        end
    end

    dropdown.MouseButton1Click:Connect(function()
        if listFrame.Size.Y.Offset == 0 then
            listFrame.Size = UDim2.new(0, 320, 0, #seedOptions * 34)
            refreshSeedList()
        else
            listFrame.Size = UDim2.new(0, 320, 0, 0)
        end
    end)

    local ideas = Instance.new("TextLabel")
    ideas.Size = UDim2.new(0, 320, 0, 58)
    ideas.Position = UDim2.new(0, 10, 0, 370 + #seedOptions * 34)
    ideas.BackgroundTransparency = 1
    ideas.TextColor3 = Color3.fromRGB(190, 190, 190)
    ideas.Text = "Ideas: Auto place fertilizer, auto upgrade tools, auto collect special events."
    ideas.TextWrapped = true
    ideas.Font = Enum.Font.Gotham
    ideas.TextSize = 14
    ideas.TextXAlignment = Enum.TextXAlignment.Left
    ideas.TextYAlignment = Enum.TextYAlignment.Top
    ideas.Parent = frame
end

if WindUI and type(WindUI.CreateWindow) == "function" then
    local window = WindUI:CreateWindow({
        Title = "Grow A Garden Auto Farm",
        Size = UDim2.new(0, 380, 0, 500),
        Theme = "Dark",
    })

    local page = window:AddPage("Main")
    local section = page:AddSection("Automation")

    section:AddToggle("Auto Farm", false, function(value)
        enabled.autoFarm = value
    end)
    section:AddToggle("Auto Collect", false, function(value)
        enabled.autoCollect = value
    end)
    section:AddToggle("Auto Buy Seed", false, function(value)
        enabled.autoBuySeed = value
    end)
    section:AddToggle("Auto Plant Seed", false, function(value)
        enabled.autoPlant = value
    end)
    section:AddToggle("Auto Sell", false, function(value)
        enabled.autoSell = value
    end)

    section:AddDropdown("Choose Seed", seedOptions, 1, function(selected)
        chosenSeed = selected
    end)

    section:AddLabel("Ideas:")
    section:AddLabel("- Auto place fertilizer when planting")
    section:AddLabel("- Auto upgrade tools or farm plots")
    section:AddLabel("- Auto collect special event fruit and bonuses")
else
    createFallbackUI()
end

print("Grow A Garden Auto Farm script loaded. WindUI detected:", WindUI ~= nil)
