local Rayfield = loadstring(
    game:HttpGet("https://sirius.menu/gen2")
)()

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EquipBest = Remotes:WaitForChild("Plot_EquipBest")
local TrainingStop = Remotes:WaitForChild("Training_Stop")
local StandUpgrade = Remotes:WaitForChild("Stand_Upgrade")

local Throw = {
    Start = Remotes:WaitForChild("Throw_Start"),
    Meter = Remotes:WaitForChild("Throw_MeterStarted"),
    Resolve = Remotes:WaitForChild("Throw_Resolve"),
    Complete = Remotes:WaitForChild("Throw_Complete"),
}

local StarterArea = Workspace:WaitForChild("StarterArea")

local function GetCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function TpPlayerToStarter()
    local char = GetCharacter()
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:PivotTo(StarterArea.CFrame * CFrame.new(0, 0, 10))
    end
end

local function TpPlayerToTraining()
    local char = GetCharacter()
    local localPlotProps = Workspace:FindFirstChild("LocalPlotProps")
    if localPlotProps then
        local trainingArea = localPlotProps:FindFirstChild("TrainingArea")
        if trainingArea then
            local trainingSpot = trainingArea:FindFirstChild("TrainingSpot")
            if trainingSpot and char and char:FindFirstChild("HumanoidRootPart") then
                char:PivotTo(trainingSpot.CFrame * CFrame.new(0, 0, 0))
            end
        end
    end
end

local Window = Rayfield:CreateWindow({
    name = "Throw Food For Animals",
    subtitle = "v1.2.0",
    sidebarLayout = true,

    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "ThrowFoodForAnimals",
    },
})

Window:CreateSection({
    name = "General",
})

local HomeTab = Window:CreateTab({
    name = "Home",
})

Window:CreateSection({
    name = "Auto Farming",
})

local PetsTab = Window:CreateTab({
    name = "Pets",
})

local TrainTab = Window:CreateTab({
    name = "Train",
})

local AutoFarmEnabled = false
local AutoEquipBestEnabled = false
local AutoTrainEnabled = false
local AutoUpgradeBarEnabled = false

HomeTab:CreateSection({
    name = "Welcome",
})

HomeTab:CreateText({
    name = "Throw Food For Animals",
    text = "Welcome! Select a category in the sidebar to access the features.",
})

HomeTab:CreateSection({
    name = "Information",
})

HomeTab:CreateText({
    name = "Version",
    text = "v1.1.0",
})

PetsTab:CreateSection({
    name = "Pet Automation",
})

local AutoFarmPets = PetsTab:CreateToggle({
    name = "Auto Farm Pets",
    description = "Enable or disable Auto Farm Pets.",
    flag = "AutoFarmPets",
    value = false,

    callback = function(value)
        AutoFarmEnabled = value
        print("Auto Farm Pets:", value)
    end,
})

local AutoEquipBestPets = PetsTab:CreateToggle({
    name = "Auto Equip Best",
    description = "Automatically equip your best pets.",
    flag = "AutoEquipBest",
    value = false,

    callback = function(value)
        AutoEquipBestEnabled = value
        print("Auto Equip Best:", value)
    end,
})

TrainTab:CreateSection({
    name = "Training",
})

local AutoTrain = TrainTab:CreateToggle({
    name = "Auto Train",
    description = "Enable or disable Auto Train.",
    flag = "AutoTrain",
    value = false,

    callback = function(value)
        AutoTrainEnabled = value
        print("Auto Train:", value)
        
        if not value then
            pcall(function()
                TrainingStop:InvokeServer()
            end)
        end
    end,
})

local AutoUpgradeBar = TrainTab:CreateToggle({
    name = "Auto Upgrade Bar",
    description = "Automatically upgrade your stand/bar.",
    flag = "AutoUpgradeBar",
    value = false,

    callback = function(value)
        AutoUpgradeBarEnabled = value
        print("Auto Upgrade Bar:", value)
    end,
})

task.spawn(function()
    while true do
        if AutoFarmEnabled then
            pcall(function()
                TpPlayerToStarter()
                task.wait(0.2)
                Throw.Start:InvokeServer()
                task.wait(0.1)
                Throw.Meter:FireServer()
                task.wait(0.1)
                Throw.Resolve:InvokeServer(1)
                task.wait(0.1)
                Throw.Complete:InvokeServer()
                task.wait(1.0)
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if AutoEquipBestEnabled then
            pcall(function()
                EquipBest:InvokeServer()
            end)
        end
        task.wait(3)
    end
end)

task.spawn(function()
    while true do
        if AutoTrainEnabled then
            pcall(function()
                TpPlayerToTraining()
                task.wait(0.5)

                local trainingSequence = Player.PlayerGui:FindFirstChild("TrainingSequence")
                if trainingSequence then
                    local tapBonusLayer = trainingSequence:FindFirstChild("TapBonusLayer")
                    if tapBonusLayer then
                        for _, v in ipairs(tapBonusLayer:GetChildren()) do
                            if v:IsA("GuiButton") or v:FindFirstChild("Activated") or v.ClassName == "TextButton" or v.ClassName == "ImageButton" then
                                firesignal(v.Activated)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

task.spawn(function()
    while true do
        if AutoUpgradeBarEnabled then
            pcall(function()
                StandUpgrade:InvokeServer()
            end)
        end
        task.wait(1)
    end
end)

print("Throw Food For Animals v1.1.0 loaded!")
