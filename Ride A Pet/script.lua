local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

if CoreGui:FindFirstChild("EggAutomationUI") then
    CoreGui.EggAutomationUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EggAutomationUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -140)
MainFrame.Size = UDim2.new(0, 220, 0, 285)

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(50, 50, 60)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 35)

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local FixFrame = Instance.new("Frame")
FixFrame.Parent = TitleBar
FixFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
FixFrame.BorderSizePixel = 0
FixFrame.Position = UDim2.new(0, 0, 0.5, 0)
FixFrame.Size = UDim2.new(1, 0, 0.5, 0)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.Size = UDim2.new(1, -12, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Egg Automation"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local dragging, dragInput, dragStart, startPos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

local Container = Instance.new("Frame")
Container.Parent = MainFrame
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(0, 12, 0, 45)
Container.Size = UDim2.new(1, -24, 1, -55)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

local function CreateToggleButton(name, callback)
    local Button = Instance.new("TextButton")
    Button.Name = name .. "Button"
    Button.Parent = Container
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    Button.BorderSizePixel = 0
    Button.Size = UDim2.new(1, 0, 0, 42)
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.GothamMedium
    Button.Text = name .. ": OFF"
    Button.TextColor3 = Color3.fromRGB(180, 180, 190)
    Button.TextSize = 13

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Button

    local active = false

    Button.MouseButton1Click:Connect(function()
        active = not active
        if active then
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(46, 204, 113)}):Play()
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.Text = name .. ": ON"
        else
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
            Button.TextColor3 = Color3.fromRGB(180, 180, 190)
            Button.Text = name .. ": OFF"
        end
        callback(active)
    end)

    return Button
end

local function GetPlayerPlot()
    local Plots = Workspace:FindFirstChild("Plots")
    if not Plots then return nil end
    for _, plot in ipairs(Plots:GetChildren()) do
        local Data = plot:FindFirstChild("Data")
        if Data then
            local Owner = Data:FindFirstChild("Owner")
            if Owner and tostring(Owner.Value) == Player.Name then
                return plot
            end
        end
    end
    return nil
end

local farmActive = false
CreateToggleButton("Auto Farm Eggs", function(state)
    farmActive = state
    if farmActive then
        task.spawn(function()
            while farmActive do
                local Character = Player.Character
                local Root = Character and Character:FindFirstChild("HumanoidRootPart")
                local RenderedEggs = Workspace:FindFirstChild("RenderedEggs")
                
                if Root and RenderedEggs then
                    local Egg = RenderedEggs:GetChildren()[1]
                    if Egg then
                        local Handle = Egg:FindFirstChild("Handle", true)
                        local Pickup = Egg:FindFirstChild("Pickup", true)

                        if Handle and Handle:IsA("BasePart") then
                            Root.CFrame = Handle.CFrame + Vector3.new(0, 3, 0)
                            task.wait(0.2)

                            if Pickup and Pickup:IsA("ProximityPrompt") then
                                fireproximityprompt(Pickup)
                                task.wait(0.3)

                                local PlayerPlot = GetPlayerPlot()
                                local Baseplate = PlayerPlot and PlayerPlot:FindFirstChild("Baseplate")
                                if Baseplate and Baseplate:IsA("BasePart") then
                                    Root.CFrame = Baseplate.CFrame + Vector3.new(0, 5, 0)
                                end
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end)

local hatchActive = false
CreateToggleButton("Auto Hatch Eggs", function(state)
    hatchActive = state
    if hatchActive then
        task.spawn(function()
            local Eggs = {}
            while hatchActive do
                table.clear(Eggs)
                local PlayerPlot = GetPlayerPlot()
                if PlayerPlot then
                    local EggsFolder = PlayerPlot:FindFirstChild("Eggs")
                    if EggsFolder then
                        for _, egg in ipairs(EggsFolder:GetChildren()) do
                            local EggKey = egg:GetAttribute("EggKey")
                            local Handle = egg:FindFirstChild("Handle")
                            if EggKey and Handle and Handle:IsA("BasePart") then
                                table.insert(Eggs, { EggKey = EggKey })
                            end
                        end
                    end
                end

                local Event = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes.Game:FindFirstChild("Hatch")
                if Event then
                    for _, egg in ipairs(Eggs) do
                        if not hatchActive then break end
                        Event:FireServer({ EggKey = egg.EggKey })
                        task.wait(0.1)
                    end
                end
                task.wait(1)
            end
        end)
    end
end)

local placeActive = false
CreateToggleButton("Auto Place Eggs", function(state)
    placeActive = state
    if placeActive then
        task.spawn(function()
            while placeActive do
                local PlaceEvent = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes.Game:FindFirstChild("EggPlaced")
                if PlaceEvent then
                    PlaceEvent:FireServer({
                        PlantPosition = Vector3.new(153.81753540039062, 40313.2421875, 1081.5360107421875)
                    })
                end
                task.wait(0.5)
            end
        end)
    end
end)

local upgradeActive = false
CreateToggleButton("Auto Upgrade Luck", function(state)
    upgradeActive = state
    if upgradeActive then
        task.spawn(function()
            while upgradeActive do
                local UpgradeEvent = ReplicatedStorage:FindFirstChild("Remotes") 
                    and ReplicatedStorage.Remotes.Game:FindFirstChild("Plot") 
                    and ReplicatedStorage.Remotes.Game.Plot:FindFirstChild("Upgrades")
                
                if UpgradeEvent then
                    UpgradeEvent:FireServer()
                end
                task.wait(0.5)
            end
        end)
    end
end)
