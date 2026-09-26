local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Clan = nil
pcall(function()
    local CAM = ReplicatedStorage:WaitForChild("CAM", 5)
    local Global = CAM and CAM:WaitForChild("Global", 5)
    local Spinners = Global and Global:WaitForChild("Spinners", 5)
    if Spinners then
        Clan = require(Spinners).Clan
    end
end)

if not Clan then
    warn("[Raijin] Could not require Spinners module. Clan list will be empty.")
end

local PlayerClan = nil

local DEBUG = true
local function debug(...)
    if DEBUG then
        print("[DEBUG]", ...)
    end
end

local CHEST_NAMES = {
    ["Common Chest"] = true,
    ["Rare Chest"] = true,
    ["Ice Chest"] = true,
    ["World Events Chest"] = true,
}

local FarmState = {
    State = "IDLE",
    CurrentBoss = nil,
    FollowConn = nil,
    Combo = 1,
    WaitingForHumanoid = 0,
    HadValidHumanoid = false,
}

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "Raijin",
    subtitle = "Slayers 2",
    sidebarLayout = true,
})

local AutomationTab = window:CreateTab({ name = "Automation", icon = 93364949241311 })
local PlayerTab     = window:CreateTab({ name = "Player",     icon = 93364949241311 })
local TeleportTab   = window:CreateTab({ name = "Teleport",   icon = 93364949241311 })
local UtilsTab      = window:CreateTab({ name = "Utilities",  icon = 93364949241311 })
local MiscTab       = window:CreateTab({ name = "Misc",       icon = 93364949241311 })
local CreditsTab    = window:CreateTab({ name = "Credits",    icon = 93364949241311 })

local CombatEvent = ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent.Event
local SkillEvent  = CombatEvent
local ShopFunction = ReplicatedStorage.Communication.ServerAndClient.Signals.SignalFunction.Function

local function notify(title, content, duration)
    window:Notify({
        title = title,
        content = content,
        duration = duration or 4,
    })
end

local function addText(tab, name, text)
    tab:CreateText({
        name = name,
        text = text,
    })
end

local function getMyRoot()
    local char = Players.LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getMyHumanoid()
    local char = Players.LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function teleportTo(position)
    local myRoot = getMyRoot()
    if myRoot and position then
        myRoot.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

local function pressT()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
    task.wait(0.02)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
end

local function cleanShopName(itemName)
    return (itemName:gsub("%s*%(%d+m%)$", ""))
end

local function purchaseFromShop(itemName, quantity)
    local cleaned = cleanShopName(itemName)
    quantity = quantity or 1

    local ok, result = pcall(function()
        return ShopFunction:InvokeServer("PurchaseFromShopWithOre", cleaned, quantity, nil)
    end)

    if not ok then
        debug("[Shop] Failed to purchase " .. cleaned .. ": " .. tostring(result))
        return false
    end

    debug("[Shop] Purchased " .. cleaned .. " x" .. quantity)
    return true, result
end

local function getClanValueObject()
    local playerName = Players.LocalPlayer.Name
    local data = ReplicatedStorage:WaitForChild("Player_Service", 5)
        and ReplicatedStorage.Player_Service:WaitForChild("Data", 5)
    if not data then return nil end

    local playerFolder = data:FindFirstChild(playerName)
    if not playerFolder then return nil end

    local slot = playerFolder:FindFirstChild("slots")
        and playerFolder.slots:FindFirstChild("Slot1")
    if not slot then return nil end

    return slot:FindFirstChild("Clan")
end

local function setClan(newClan)
    local clan = getClanValueObject()
    if not clan then
        notify("Clan Error", "Could not find your Clan value.", 4)
        return false
    end

    if newClan then
        if PlayerClan == nil then
            PlayerClan = clan.Value
        end
        clan.Value = newClan
        return true
    else
        if PlayerClan ~= nil then
            clan.Value = PlayerClan
            PlayerClan = nil
            return true
        end
    end
    return false
end

local function getPlayerRace()
    local playerName = Players.LocalPlayer.Name
    local data = ReplicatedStorage:FindFirstChild("Player_Service")
        and ReplicatedStorage.Player_Service:FindFirstChild("Data")
    if not data then return nil end

    local playerFolder = data:FindFirstChild(playerName)
    if not playerFolder then return nil end

    local slot = playerFolder:FindFirstChild("slots")
        and playerFolder.slots:FindFirstChild("Slot1")
    if not slot then return nil end

    local race = slot:FindFirstChild("Race")
    return race and race.Value or nil
end

local function getPowers()
    local playerName = Players.LocalPlayer.Name
    local data = ReplicatedStorage:FindFirstChild("Player_Service")
        and ReplicatedStorage.Player_Service:FindFirstChild("Data")
    if not data then return nil end

    local playerFolder = data:FindFirstChild(playerName)
    if not playerFolder then return nil end

    local slot = playerFolder:FindFirstChild("slots")
        and playerFolder.slots:FindFirstChild("Slot1")
    if not slot then return nil end

    return slot:FindFirstChild("Powers")
end

local function getCurrentSkillFolder()
    local race = getPlayerRace()
    if not race then return nil, nil, nil end

    local powers = getPowers()
    if not powers then return nil, nil, race end

    local skillsFolder = ReplicatedStorage:FindFirstChild("Skills")
    if not skillsFolder then return nil, nil, race end

    local skillName, folderName

    if race == "Human" then
        local breathing = powers:FindFirstChild("Breathing")
        if not breathing then return nil, nil, race end
        skillName = breathing.Value
        folderName = skillName .. " Breathing"
    elseif race == "Demon" then
        local demonArt = powers:FindFirstChild("DemonArt")
        if not demonArt then return nil, nil, race end
        skillName = demonArt.Value
        folderName = skillName
    else
        return nil, nil, race
    end

    return skillName, skillsFolder:FindFirstChild(folderName), race
end

local function getSkillList()
    local _, skillFolder = getCurrentSkillFolder()
    if not skillFolder then return {} end

    local list = {}
    for _, skill in ipairs(skillFolder:GetChildren()) do
        table.insert(list, skill.Name)
    end
    return list
end

local function getSkillState()
    local char = Players.LocalPlayer.Character
    if not char then return nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil end
    return root.Position, root.CFrame
end

local function castSkill(skillName, action)
    local pos, cf = getSkillState()
    if not pos or not cf then
        warn("[Skill] Character not ready")
        return false
    end

    if action == "UnHoldAfterClient" then
        SkillEvent:FireServer(
            "server_skill_controller_signaler",
            skillName,
            action,
            pos, nil, cf
        )
    elseif action == "UnHold" then
        SkillEvent:FireServer(
            "server_skill_controller_signaler",
            skillName,
            action,
            pos, nil
        )
    else
        SkillEvent:FireServer(
            "server_skill_controller_signaler",
            skillName,
            action,
            pos
        )
    end

    return true
end

local SEQUENCES = {
    A = { "Hold", "UnHold", "Cancel" },
    B = { "Hold", "UnHold", "UnHoldAfterClient" },
    C = { "Hold", "UnHoldAfterClient" },
}

local SKILL_SEQUENCE_OVERRIDES = {
    ["Thunder Clap and Flash"] = "A",
}

local DEFAULT_SEQUENCE = "B"

local function useSkill(skillName, holdTime)
    holdTime = holdTime or 0.1

    local key = SKILL_SEQUENCE_OVERRIDES[skillName] or DEFAULT_SEQUENCE
    local seq = SEQUENCES[key]
    if not seq then return false end

    for i, action in ipairs(seq) do
        castSkill(skillName, action)
        if i < #seq then
            task.wait(holdTime)
        end
    end

    return true
end

local function getWorldEventsSpawnedBosses()
    local spawned = {}
    local folder = workspace.Humanoids.Regions.Misc.ActiveNpcs
    if not folder then return spawned end

    local now = os.time()

    for _, boss in ipairs(folder:GetChildren()) do
        local despawnedAt = boss:GetAttribute("DespawnedAt")
        local bossInfo = boss:FindFirstChild("BossInfo")
        local spawnTime = bossInfo and bossInfo:GetAttribute("SpawnTime")

        if not spawnTime then continue end

        local isSpawned
        if not despawnedAt then
            isSpawned = true
        else
            isSpawned = now >= (despawnedAt + spawnTime)
        end

        if isSpawned then
            local npcModel = boss:FindFirstChild(boss.Name)
            local humanoid = npcModel and npcModel:FindFirstChildOfClass("Humanoid")

            table.insert(spawned, {
                Folder = boss,
                Model = npcModel,
                Humanoid = humanoid,
                Name = boss.Name,
                Title = bossInfo and bossInfo:GetAttribute("Title"),
                NpcCode = bossInfo and bossInfo:GetAttribute("NpcCode"),
                Chest = bossInfo and bossInfo:GetAttribute("Chest"),
                ChestRarity = bossInfo and bossInfo:GetAttribute("ChestRarity"),
                SpawnTime = spawnTime,
                DespawnedAt = despawnedAt,
                Center = bossInfo and bossInfo:GetAttribute("Center"),
                Health = humanoid and humanoid.Health,
                MaxHealth = humanoid and humanoid.MaxHealth,
                BaseMaxHealth = npcModel and npcModel:GetAttribute("MaxHealth"),
                Position = npcModel
                    and npcModel:FindFirstChild("HumanoidRootPart")
                    and npcModel.HumanoidRootPart.Position,
            })
        end
    end

    return spawned
end

local function getNearbyChest()
    local maxDistance = _G.ChestRange or 50

    local chestsFolder = workspace:FindFirstChild("Chests")
    if not chestsFolder then return nil end

    local myRoot = getMyRoot()
    if not myRoot then return nil end

    local nearest, nearestPart, nearestDist = nil, nil, maxDistance

    for _, chest in ipairs(chestsFolder:GetChildren()) do
        if CHEST_NAMES[chest.Name] then
            local part = chest:IsA("BasePart") and chest
                or chest:FindFirstChildWhichIsA("BasePart")
                or chest:FindFirstChild("HumanoidRootPart")

            if part then
                local dist = (part.Position - myRoot.Position).Magnitude
                if dist < nearestDist then
                    nearest = chest
                    nearestPart = part
                    nearestDist = dist
                end
            end
        end
    end

    return nearest, nearestPart, nearestDist
end

local function getNearbyLoot()
    local maxDistance = _G.LootRange or 50

    local lootFolder = workspace:FindFirstChild("LootDrops")
    if not lootFolder then return nil end

    local myRoot = getMyRoot()
    if not myRoot then return nil end

    local nearest, nearestDist = nil, maxDistance

    for _, loot in ipairs(lootFolder:GetChildren()) do
        if loot:IsA("BasePart") then
            local dist = (loot.Position - myRoot.Position).Magnitude
            if dist < nearestDist then
                nearest = loot
                nearestDist = dist
            end
        end
    end

    return nearest, nearestDist
end

local FOLDER_OVERRIDES = {
    ["Shrine - Frost Veil Shrine"] = "Iceveil Valley",
}

local function teleportToShrine(buttonName)
    local folderName = buttonName:gsub("^Shrine %- ", ""):gsub(" Shrine$", "")
    folderName = FOLDER_OVERRIDES[buttonName] or folderName

    local map = workspace:FindFirstChild("Map")
    local regions = map and map:FindFirstChild("Regions")
    if not regions then
        warn("[Shrine] workspace.Map.Regions not found")
        return
    end

    local folder = regions:FindFirstChild(folderName)
    if not folder then
        warn("[Shrine] Folder not found: " .. folderName)
        return
    end

    local model = folder:FindFirstChild(buttonName)
    if not model then
        warn("[Shrine] Model not found: " .. buttonName)
        return
    end

    local target = model.WorldPivot.Position + Vector3.new(0, 5, 0)

    local root = getMyRoot()
    if root then
        root.CFrame = CFrame.new(target)
    end
end

local DELAYS = {
    ["Katana"] = {
        [1] = 0.1315789473684211,
        [2] = 0.06842105263157898,
        [3] = 0.06842105263157898,
        [4] = 0.10526315789473685,
        [5] = 0.078947368421052641,
    },
    ["Combat"] = {
        [1] = 0.1368421052631579,
        [2] = 0.05,
        [3] = 0.05,
        [4] = 0.05,
        [5] = 0.15789473684210523,
    },
}

local ATTACK_NAME = {
    ["Katana"] = "Regular Katana",
    ["Combat"] = "Combat",
}

local function fireM1(method, combo)
    local name = ATTACK_NAME[method] or "Combat"
    local delay = DELAYS[method][combo] or 0.1

    CombatEvent:FireServer(
        "Combat_Service",
        name,
        combo,
        false,
        delay,
        false,
        nil
    )

    return delay
end

local function stopCharacterAnimations()
    local char = Players.LocalPlayer.Character
    if not char then return end

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("Motor6D") then
            obj.Transform = CFrame.new()
        end
    end
end

local function refreshBossModel(boss)
    if not boss or not boss.Folder or not boss.Folder.Parent then return end
    if boss.Model and boss.Model.Parent then return end

    local model = boss.Folder:FindFirstChild(boss.Name)
    if model then
        boss.Model = model
    end
end

local function getBossCenter(boss)
    if not boss or not boss.Folder or not boss.Folder.Parent then
        return nil
    end
    local bossInfo = boss.Folder:FindFirstChild("BossInfo")
    return bossInfo and bossInfo:GetAttribute("Center")
end

local function getBossHRP(boss)
    if not boss or not boss.Folder or not boss.Folder.Parent then
        return nil
    end
    refreshBossModel(boss)
    if not boss.Model or not boss.Model.Parent then return nil end
    return boss.Model:FindFirstChild("HumanoidRootPart")
end

local function getBossHumanoid(boss)
    if not boss or not boss.Folder or not boss.Folder.Parent then
        return nil
    end
    refreshBossModel(boss)
    if not boss.Model or not boss.Model.Parent then return nil end
    return boss.Model:FindFirstChildOfClass("Humanoid")
end

local function isBossFolderSpawned(bossFolder)
    if not bossFolder or not bossFolder.Parent then return false end

    local bossInfo = bossFolder:FindFirstChild("BossInfo")
    local spawnTime = bossInfo and bossInfo:GetAttribute("SpawnTime")
    if not spawnTime then return false end

    local despawnedAt = bossFolder:GetAttribute("DespawnedAt")
    if not despawnedAt then return true end

    return os.time() >= (despawnedAt + spawnTime)
end

local function attachToTarget(boss)
    if FarmState.FollowConn then
        FarmState.FollowConn:Disconnect()
        FarmState.FollowConn = nil
    end

    FarmState.CurrentBoss = boss
    FarmState.WaitingForHumanoid = os.clock()
    FarmState.HadValidHumanoid = false

    local root = getMyRoot()
    local humanoid = getMyHumanoid()

    if not root or not humanoid then return end

    humanoid.AutoRotate = false
    root.Anchored = false

    stopCharacterAnimations()

    local center = getBossCenter(boss)
    if center then
        teleportTo(center)
    end

    local heartbeatCount = 0

    FarmState.FollowConn = RunService.Heartbeat:Connect(function()
        local b = FarmState.CurrentBoss
        if not b then return end
        if not b.Folder or not b.Folder.Parent then return end
        if not root or not root.Parent then return end

        local trackPart = getBossHRP(b)
        if not trackPart then
            heartbeatCount = heartbeatCount + 1
            return
        end

        local offset = _G.FarmOffset or Vector3.new(0, -5, 0)
        local pitch = _G.FarmPitch or 90

        local pos = trackPart.Position

        root.CFrame = CFrame.new(
            pos.X + offset.X,
            pos.Y + offset.Y,
            pos.Z + offset.Z
        ) * CFrame.Angles(math.rad(pitch), 0, 0)

        heartbeatCount = heartbeatCount + 1
    end)
end

local function detachFromTarget()
    if FarmState.FollowConn then
        FarmState.FollowConn:Disconnect()
        FarmState.FollowConn = nil
    end

    FarmState.WaitingForHumanoid = 0
    FarmState.HadValidHumanoid = false

    local humanoid = getMyHumanoid()
    if humanoid then
        humanoid.AutoRotate = true
    end

    local root = getMyRoot()
    if root then
        root.Anchored = false
    end
end

local function resetFarmOnDeath()
    detachFromTarget()
    FarmState.State = "IDLE"
    FarmState.Combo = 1
end

local function watchCharacter(char)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.Died:Connect(resetFarmOnDeath)
    end
end

if Players.LocalPlayer.Character then
    watchCharacter(Players.LocalPlayer.Character)
end
Players.LocalPlayer.CharacterAdded:Connect(watchCharacter)

AutomationTab:CreateSection({ name = "Boss Farm" })

AutomationTab:CreateToggle({
    name = "Enabled",
    description = "Enable or disable Auto Farming.",
    currentValue = false,
    flag = "AutoFarmEnabled",
    callback = function(state)
        _G.AutoFarmEnabled = state
        if not state then
            detachFromTarget()
            FarmState.State = "IDLE"
            FarmState.CurrentBoss = nil
            FarmState.Combo = 1
        end
        notify("Auto Farm", state and "Enabled." or "Disabled.", 3)
    end,
})

AutomationTab:CreateDropdown({
    name = "Attack Method",
    description = "Choose how the Auto Farm attacks NPCs and bosses.",
    options = { "Combat", "Katana" },
    currentOption = { "Combat" },
    multiSelect = false,
    flag = "AttackMethod",
    callback = function(selected)
        local value = type(selected) == "table" and selected[1] or selected
        _G.AttackMethod = value
        notify("Attack Method", "Set to: " .. tostring(value), 3)
    end,
})

AutomationTab:CreateSection({ name = "Farm Position" })

AutomationTab:CreateSlider({
    name = "Offset X",
    range = { -30, 30 },
    increment = 1,
    currentValue = 0,
    suffix = " studs",
    flag = "FarmOffsetX",
    callback = function(value)
        _G.FarmOffsetX = value
        local y = _G.FarmOffsetY or -5
        local z = _G.FarmOffsetZ or 0
        _G.FarmOffset = Vector3.new(value, y, z)
    end,
})

AutomationTab:CreateSlider({
    name = "Offset Y",
    range = { -30, 30 },
    increment = 1,
    currentValue = -5,
    suffix = " studs",
    flag = "FarmOffsetY",
    callback = function(value)
        _G.FarmOffsetY = value
        local x = _G.FarmOffsetX or 0
        local z = _G.FarmOffsetZ or 0
        _G.FarmOffset = Vector3.new(x, value, z)
    end,
})

AutomationTab:CreateSlider({
    name = "Offset Z",
    range = { -30, 30 },
    increment = 1,
    currentValue = 0,
    suffix = " studs",
    flag = "FarmOffsetZ",
    callback = function(value)
        _G.FarmOffsetZ = value
        local x = _G.FarmOffsetX or 0
        local y = _G.FarmOffsetY or -5
        _G.FarmOffset = Vector3.new(x, y, value)
    end,
})

AutomationTab:CreateSlider({
    name = "Pitch",
    range = { 0, 180 },
    increment = 5,
    currentValue = 90,
    suffix = "°",
    flag = "FarmPitch",
    callback = function(value)
        _G.FarmPitch = value
    end,
})

_G.FarmOffset = Vector3.new(0, -5, 0)
_G.FarmPitch = 90
_G.AttackMethod = "Combat"
_G.FarmTargets = _G.FarmTargets or {}

local bossList = getWorldEventsSpawnedBosses()
local bossNames = {}
for _, b in ipairs(bossList) do
    table.insert(bossNames, b.Name)
end
if #bossNames == 0 then
    bossNames = { "No boss spawned" }
end

local BossDropdown = AutomationTab:CreateDropdown({
    name = "Bosses",
    description = "Select which bosses the Auto Farm should target.",
    options = bossNames,
    currentOption = {},
    multiSelect = true,
    callback = function(selected)
        local list = type(selected) == "table" and selected or { selected }
        local clean = {}
        for _, name in ipairs(list) do
            if name ~= "No boss spawned" then
                table.insert(clean, name)
            end
        end
        _G.FarmTargets = clean
        if #clean == 0 then
            notify("Farm Targets", "No targets selected.", 3)
        else
            notify("Farm Targets", table.concat(clean, ", "), 3)
        end
    end,
})

_G.SpawnedBosses = bossList

local knownBosses = {}
for _, b in ipairs(bossList) do
    knownBosses[b.Name] = true
end

task.spawn(function()
    while task.wait(5) do
        local newList = getWorldEventsSpawnedBosses()
        _G.SpawnedBosses = newList

        local names = {}
        for _, b in ipairs(newList) do
            table.insert(names, b.Name)
            if not knownBosses[b.Name] then
                notify("Boss Spawned", b.Name .. " has spawned!", 5)
            end
            knownBosses[b.Name] = true
        end

        for name in pairs(knownBosses) do
            if not table.find(names, name) then
                knownBosses[name] = nil
            end
        end

        if #names > 0 then
            BossDropdown:Refresh(names)
        end
    end
end)

AutomationTab:CreateSection({ name = "Auto Chest" })

AutomationTab:CreateToggle({
    name = "Enabled",
    description = "Automatically teleports to chests and opens them.",
    currentValue = false,
    flag = "AutoChestEnabled",
    callback = function(state)
        _G.AutoChestEnabled = state
        notify("Auto Chest", state and "Enabled." or "Disabled.", 3)
    end,
})

AutomationTab:CreateSlider({
    name = "Chest Detection Range",
    range = { 10, 500 },
    increment = 5,
    currentValue = 50,
    suffix = " studs",
    flag = "ChestRange",
    callback = function(value)
        _G.ChestRange = value
    end,
})

AutomationTab:CreateSection({ name = "Auto Loot" })

AutomationTab:CreateToggle({
    name = "Enabled",
    description = "Automatically teleports to loot drops and picks them up.",
    currentValue = false,
    flag = "AutoLootEnabled",
    callback = function(state)
        _G.AutoLootEnabled = state
        notify("Auto Loot", state and "Enabled." or "Disabled.", 3)
    end,
})

AutomationTab:CreateSlider({
    name = "Loot Detection Range",
    range = { 10, 500 },
    increment = 5,
    currentValue = 50,
    suffix = " studs",
    flag = "LootRange",
    callback = function(value)
        _G.LootRange = value
    end,
})

AutomationTab:CreateSection({ name = "Auto Skills" })

AutomationTab:CreateToggle({
    name = "Auto Power Skills",
    description = "Automatically detects your Race (Human/Demon) and current power (Breathing/Demon Art), then casts every skill in sequence.",
    currentValue = false,
    flag = "AutoSkillsEnabled",
    callback = function(state)
        _G.AutoSkillsEnabled = state
        if state then
            skillList = getSkillList()
        end
        notify("Auto Power Skills", state and "Enabled." or "Disabled.", 3)
    end,
})

AutomationTab:CreateSlider({
    name = "Skill Hold Time",
    description = "How long to hold each skill before releasing.",
    range = { 0, 1 },
    increment = 0.05,
    currentValue = 0.1,
    suffix = "s",
    flag = "SkillHoldTime",
    callback = function(value)
        _G.SkillHoldTime = value
    end,
})

AutomationTab:CreateSlider({
    name = "Skill Cooldown",
    description = "Delay between each skill in the sequence.",
    range = { 0, 3 },
    increment = 0.1,
    currentValue = 0.5,
    suffix = "s",
    flag = "SkillCooldown",
    callback = function(value)
        _G.SkillCooldown = value
    end,
})

AutomationTab:CreateButton({
    name = "Refresh Skill List",
    description = "Re-scan the Skills for your current abilities.",
    callback = function()
        local name, folder, race = getCurrentSkillFolder()
        if folder then
            skillList = getSkillList()
            notify("Skills", string.format("Found %d skills for %s.", #skillList, tostring(name)), 4)
        else
            notify("Skills", "Could not find skill folder.", 4)
        end
    end,
})

local skillList = getSkillList()

PlayerTab:CreateSection({ name = "Clan" })

local ClanOptions = {}

if Clan and type(Clan.Pool) == "function" then
    local ok, pool = pcall(Clan.Pool)
    if ok and type(pool) == "table" then
        for _, clan in ipairs(pool) do
            table.insert(ClanOptions, clan)
        end
    end
end

if #ClanOptions == 0 then
    ClanOptions = {
        "Kamado", "Agatsuma", "Hashibira", "Rengoku",
        "Uzui", "Shinazugawa", "Tokito", "Kanroji", "Iguro",
    }
end

table.insert(ClanOptions, 1, "None")

PlayerTab:CreateDropdown({
    name = "Clan Selector",
    description = "Sets your clan to the selected one. Choose \"None\" to restore your original clan.",
    options = ClanOptions,
    currentOption = { "None" },
    multiSelect = false,
    flag = "SelectedClan",
    callback = function(selected)
        local value = type(selected) == "table" and selected[1] or selected

        if value == "None" or value == nil then
            if setClan(nil) then
                notify("Clan", "Restored to your original clan.", 3)
            end
        else
            if setClan(value) then
                notify("Clan", "Set to: " .. value, 3)
            end
        end

        _G.SelectedClan = value
    end,
})

PlayerTab:CreateSection({ name = "Sun Immunity" })

PlayerTab:CreateToggle({
    name = "Kamado Method",
    description = "Sets your clan to Kamado. Disabling it restores your previous clan.",
    currentValue = false,
    flag = "SunImmunity",
    callback = function(state)
        if state then
            if setClan("Kamado") then
                notify("Sun Immunity", "Kamado applied. Sun damage blocked.", 4)
            end
        else
            if setClan(nil) then
                notify("Sun Immunity", "Restored your original clan.", 3)
            end
        end
    end,
})

PlayerTab:CreateToggle({
    name = "Black Amigasa Method",
    description = "Alternative sun immunity method using the Black Amigasa Hat. Requires 10,000 Money and the Elara task completed.",
    currentValue = false,
    flag = "HatMethod",
    callback = function(state)
        if state then
            notify("Sun Immunity", "Hat Method enabled. Make sure you have 10k Money and the Elara task completed.", 5)
        else
            notify("Sun Immunity", "Hat Method disabled.", 3)
        end
    end,
})

PlayerTab:CreateSection({ name = "Character" })

_G.WalkSpeedValue = 16
_G.JumpPowerValue = 50

PlayerTab:CreateSlider({
    name = "Walk Speed",
    description = "Sets your character's walk speed (kept applied in background).",
    range = { 16, 200 },
    increment = 1,
    currentValue = 16,
    suffix = " studs/s",
    flag = "WalkSpeed",
    callback = function(value)
        _G.WalkSpeedValue = value
        local humanoid = getMyHumanoid()
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end,
})

PlayerTab:CreateSlider({
    name = "Jump Power",
    description = "Sets your character's jump power (kept applied in background).",
    range = { 50, 500 },
    increment = 5,
    currentValue = 50,
    suffix = " studs",
    flag = "JumpPower",
    callback = function(value)
        _G.JumpPowerValue = value
        local humanoid = getMyHumanoid()
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = value
        end
    end,
})

task.spawn(function()
    while task.wait(0.1) do
        local humanoid = getMyHumanoid()
        if humanoid and humanoid.Health > 0 then
            if humanoid.WalkSpeed ~= _G.WalkSpeedValue then
                humanoid.WalkSpeed = _G.WalkSpeedValue
            end
            if humanoid.UseJumpPower and humanoid.JumpPower ~= _G.JumpPowerValue then
                humanoid.JumpPower = _G.JumpPowerValue
            end
        end
    end
end)

TeleportTab:CreateSection({ name = "Shrines" })

TeleportTab:CreateButton({
    name = "Shrine - Butterfly Estate Shrine",
    callback = function()
        teleportToShrine("Shrine - Butterfly Estate Shrine")
    end,
})

TeleportTab:CreateButton({
    name = "Shrine - Hidden Mist Village Shrine",
    callback = function()
        teleportToShrine("Shrine - Hidden Mist Village Shrine")
    end,
})

TeleportTab:CreateButton({
    name = "Shrine - Frost Veil Shrine",
    callback = function()
        teleportToShrine("Shrine - Frost Veil Shrine")
    end,
})

TeleportTab:CreateButton({
    name = "Shrine - Mistfall Harbor Shrine",
    callback = function()
        teleportToShrine("Shrine - Mistfall Harbor Shrine")
    end,
})

TeleportTab:CreateButton({
    name = "Shrine - Windy Peak Shrine",
    callback = function()
        teleportToShrine("Shrine - Windy Peak Shrine")
    end,
})

TeleportTab:CreateSection({ name = "Players" })

local selectedPlayer = nil

local PlayerDropdown = TeleportTab:CreateDropdown({
    name = "Teleport To Player",
    description = "Select a player to teleport to.",
    options = { "None" },
    currentOption = { "None" },
    multiSelect = false,
    flag = "TeleportTarget",
    callback = function(selected)
        selectedPlayer = type(selected) == "table" and selected[1] or selected
        if selectedPlayer == "None" then selectedPlayer = nil end
    end,
})

TeleportTab:CreateButton({
    name = "Teleport",
    description = "Teleports you to the selected player.",
    callback = function()
        if not selectedPlayer then
            notify("Teleport", "No player selected.", 3)
            return
        end

        local target = Players:FindFirstChild(selectedPlayer)
        if not target then
            notify("Teleport", "Player not found.", 3)
            return
        end

        local targetChar = target.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if not targetRoot then
            notify("Teleport", "Player has no character.", 3)
            return
        end

        teleportTo(targetRoot.Position)
        notify("Teleport", "Teleported to " .. selectedPlayer, 3)
    end,
})

task.spawn(function()
    while task.wait(3) do
        local names = { "None" }
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Players.LocalPlayer then
                table.insert(names, plr.Name)
            end
        end
        pcall(function()
            PlayerDropdown:Refresh(names)
        end)
    end
end)

UtilsTab:CreateSection({ name = "Shop" })

UtilsTab:CreateDropdown({
    name = "Boosts",
    description = "Select which boosts to purchase using Ores.",
    options = { "2x EXP (30m)", "2x Wen (15m)", "2x Mastery (15m)", "2x Souls (30m)", "2x Luck" },
    multiSelect = true,
    flag = "SelectedBoosts",
    callback = function(selected)
        local list = type(selected) == "table" and selected or { selected }
        _G.SelectedBoosts = list
        print("[Boosts] Selected:", table.concat(list, ", "))
    end,
})

UtilsTab:CreateDropdown({
    name = "Resets",
    description = "Select which resets to purchase using Ores.",
    options = { "Reset Breathing", "Reset Fighting Style", "Reset Evil Art", "Reset Race", "Reset Reputation" },
    multiSelect = true,
    flag = "SelectedResets",
    callback = function(selected)
        local list = type(selected) == "table" and selected or { selected }
        _G.SelectedResets = list
        print("[Resets] Selected:", table.concat(list, ", "))
    end,
})

UtilsTab:CreateDropdown({
    name = "Spins",
    description = "Select how many spins to purchase using Ores.",
    options = { "1 Spin", "15 Spins", "25 Spins", "50 Spins", "100 Spins", "250 Spins" },
    multiSelect = false,
    flag = "SpinsAmount",
    callback = function(selected)
        local value = type(selected) == "table" and selected[1] or selected
        _G.SpinsValue = value
        print("[Spins] Selected:", _G.SpinsValue)
    end,
})

UtilsTab:CreateToggle({
    name = "Auto Buy Selected Shop Items",
    description = "Automatically purchases the selected Boosts, Resets, and Spins using Ores.",
    currentValue = false,
    flag = "AutoBuyShopEnabled",
    callback = function(state)
        _G.AutoBuyShopEnabled = state
        notify("Auto Buy Shop", state and "Enabled." or "Disabled.", 3)
    end,
})

UtilsTab:CreateSection({ name = "Camera" })

UtilsTab:CreateSlider({
    name = "Field of View",
    description = "Adjust your camera FOV.",
    range = { 70, 120 },
    increment = 1,
    currentValue = 70,
    suffix = "",
    flag = "CameraFOV",
    callback = function(value)
        workspace.CurrentCamera.FieldOfView = value
    end,
})

UtilsTab:CreateSection({ name = "Visual" })

local savedLighting = nil
local fullbrightEnabled = false
local noFogEnabled = false

UtilsTab:CreateToggle({
    name = "Fullbright",
    description = "Removes all shadows and makes the map fully lit.",
    currentValue = false,
    flag = "Fullbright",
    callback = function(state)
        fullbrightEnabled = state
        local lighting = game:GetService("Lighting")

        if state then
            savedLighting = {
                Brightness = lighting.Brightness,
                ClockTime = lighting.ClockTime,
                GlobalShadows = lighting.GlobalShadows,
                Ambient = lighting.Ambient,
                OutdoorAmbient = lighting.OutdoorAmbient,
            }
            notify("Fullbright", "Enabled.", 3)
        else
            if savedLighting then
                lighting.Brightness = savedLighting.Brightness
                lighting.ClockTime = savedLighting.ClockTime
                lighting.GlobalShadows = savedLighting.GlobalShadows
                lighting.Ambient = savedLighting.Ambient
                lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
                savedLighting = nil
            end
            notify("Fullbright", "Disabled.", 3)
        end
    end,
})

UtilsTab:CreateToggle({
    name = "No Fog",
    description = "Removes all fog from the map.",
    currentValue = false,
    flag = "NoFog",
    callback = function(state)
        noFogEnabled = state
        notify("No Fog", state and "Enabled." or "Disabled.", 3)
    end,
})

task.spawn(function()
    while task.wait(0.5) do
        local lighting = game:GetService("Lighting")

        if fullbrightEnabled then
            lighting.Brightness = 3
            lighting.ClockTime = 14
            lighting.GlobalShadows = false
            lighting.Ambient = Color3.fromRGB(178, 178, 178)
            lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        end

        if noFogEnabled then
            lighting.FogEnd = 100000
            lighting.FogStart = 100000
        end
    end
end)

MiscTab:CreateSection({ name = "Server" })

MiscTab:CreateButton({
    name = "Reset Character",
    description = "Kills your character so it respawns.",
    callback = function()
        local humanoid = getMyHumanoid()
        if humanoid then
            humanoid.Health = 0
            notify("Character", "Character reset.", 3)
        else
            notify("Character", "No character found.", 3)
        end
    end,
})

MiscTab:CreateButton({
    name = "Copy Job ID",
    description = "Copies the current server Job ID to your clipboard.",
    callback = function()
        if setclipboard then
            setclipboard(game.JobId)
            notify("Misc", "Job ID copied: " .. game.JobId, 4)
        else
            notify("Misc", "Clipboard not supported.", 4)
        end
    end,
})

MiscTab:CreateSection({ name = "Character" })

MiscTab:CreateToggle({
    name = "Anti-AFK",
    description = "Prevents you from being kicked for idling.",
    currentValue = false,
    flag = "AntiAFK",
    callback = function(state)
        if state then
            local vu = game:GetService("VirtualUser")
            Players.LocalPlayer.Idled:Connect(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
            notify("Anti-AFK", "Enabled.", 3)
        else
            notify("Anti-AFK", "Disabled (relog to fully disable).", 3)
        end
    end,
})

MiscTab:CreateSection({ name = "Info" })

addText(MiscTab, "Hub", "Raijin")
addText(MiscTab, "Game", "Slayers 2")

CreditsTab:CreateSection({ name = "Raijin Hub" })

addText(CreditsTab, "About",
    "Raijin is a Slayers 2 utility hub built for farming bosses, chests, loot and auto-casting skills. Version 1.0.0.")

addText(CreditsTab, "Author",
    "Developed by realinkdev.")

addText(CreditsTab, "UI Library",
    "Rayfield Gen2 (sirius.menu)")

CreditsTab:CreateSection({ name = "Links" })

CreditsTab:CreateButton({
    name = "Copy Discord Invite",
    callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/yourinvite")
            notify("Credits", "Discord invite copied.", 3)
        end
    end,
})

CreditsTab:CreateButton({
    name = "Copy Script URL",
    callback = function()
        if setclipboard then
            setclipboard("https://raw.githubusercontent.com/yourname/yourrepo/main/raijin.lua")
            notify("Credits", "Script URL copied.", 3)
        end
    end,
})

CreditsTab:CreateSection({ name = "Changelog" })

addText(CreditsTab, "v1.0.0",
    "- Initial release.\n- Boss Farm.\n- Auto Chest / Auto Loot.\n- Auto Power Skills (Breathing / Demon Art).\n- Clan selector + Sun Immunity.\n- Shrine teleports.")

task.spawn(function()
    while task.wait(0.1) do
        if not _G.AutoChestEnabled then continue end

        local chest, part = getNearbyChest()
        if not chest or not part then continue end

        teleportTo(part.Position)
        task.wait(0.05)
        pressT()
        task.wait(0.3)

        if chest and chest.Parent then
            pcall(function() chest:Destroy() end)
        end

        task.wait(0.1)
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not _G.AutoLootEnabled then continue end

        local loot = getNearbyLoot()
        if not loot then continue end

        teleportTo(loot.Position)
        task.wait(0.05)
        pressT()
        task.wait(0.1)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if not _G.AutoSkillsEnabled then continue end

        if #skillList == 0 then
            skillList = getSkillList()
            if #skillList == 0 then
                task.wait(2)
                continue
            end
        end

        local holdTime = _G.SkillHoldTime or 0.1
        local cooldown = _G.SkillCooldown or 0.5

        for _, skillName in ipairs(skillList) do
            if not _G.AutoSkillsEnabled then break end

            useSkill(skillName, holdTime)
            task.wait(cooldown)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if not _G.AutoBuyShopEnabled then continue end

        local bought = 0

        for _, display in ipairs(_G.SelectedBoosts or {}) do
            if not _G.AutoBuyShopEnabled then break end
            if purchaseFromShop(display, 1) then
                bought = bought + 1
            end
            task.wait(0.15)
        end

        for _, display in ipairs(_G.SelectedResets or {}) do
            if not _G.AutoBuyShopEnabled then break end
            if purchaseFromShop(display, 1) then
                bought = bought + 1
            end
            task.wait(0.15)
        end

        if _G.SpinsValue then
            if purchaseFromShop(_G.SpinsValue, 1) then
                bought = bought + 1
            end
        end

        if bought > 0 then
            debug("[Auto Buy Shop] Purchased " .. bought .. " item(s).")
        end
    end
end)

task.spawn(function()
    while true do
        if not _G.AutoFarmEnabled then
            task.wait(0.2)
            continue
        end

        if FarmState.State == "IDLE" then
            local targets = _G.FarmTargets or {}
            local spawned = _G.SpawnedBosses or {}

            local resumed = false

            local prev = FarmState.CurrentBoss
            if prev
                and prev.Folder and prev.Folder.Parent
                and table.find(targets, prev.Name)
                and isBossFolderSpawned(prev.Folder)
            then
                attachToTarget(prev)
                FarmState.State = "ATTACKING"
                FarmState.Combo = 1
                resumed = true
            end

            if not resumed then
                local found = nil
                for _, boss in ipairs(spawned) do
                    local isTarget = table.find(targets, boss.Name) ~= nil
                    local hasFolder = boss.Folder and boss.Folder.Parent
                    local hasCenter = boss.Center ~= nil

                    if isTarget and hasFolder and hasCenter then
                        found = boss
                        break
                    end
                end

                if found then
                    attachToTarget(found)
                    FarmState.State = "ATTACKING"
                    FarmState.Combo = 1
                else
                    task.wait(1)
                end
            end

        elseif FarmState.State == "ATTACKING" then
            local boss = FarmState.CurrentBoss

            local myHumanoid = getMyHumanoid()
            local myRoot = getMyRoot()

            if not myHumanoid or not myRoot or myHumanoid.Health <= 0 then
                detachFromTarget()
                FarmState.State = "IDLE"
                FarmState.Combo = 1
                task.wait(0.5)
            else
                local folderAlive = boss
                    and boss.Folder and boss.Folder.Parent

                if not folderAlive then
                    detachFromTarget()
                    FarmState.State = "LOOTING"
                    task.wait(0.6)
                else
                    local bossHumanoid = getBossHumanoid(boss)
                    local hrp = getBossHRP(boss)

                    local humanoidReady = bossHumanoid
                        and bossHumanoid.Parent
                        and bossHumanoid.Health > 0
                        and hrp ~= nil

                    if humanoidReady then
                        FarmState.HadValidHumanoid = true

                        local method = _G.AttackMethod or "Combat"
                        local delay = fireM1(method, FarmState.Combo)
                        task.wait(delay)

                        FarmState.Combo = FarmState.Combo + 1
                        if FarmState.Combo > 5 then
                            FarmState.Combo = 1
                        end
                    else
                        local bossGoneOrDead = FarmState.HadValidHumanoid and (
                            not bossHumanoid
                            or not bossHumanoid.Parent
                            or bossHumanoid.Health <= 0
                            or not hrp
                        )

                        if bossGoneOrDead then
                            detachFromTarget()
                            FarmState.State = "LOOTING"
                            task.wait(0.6)
                        else
                            local waited = os.clock() - FarmState.WaitingForHumanoid
                            if waited > 10 then
                                detachFromTarget()
                                FarmState.State = "IDLE"
                                task.wait(1)
                            else
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end

        elseif FarmState.State == "LOOTING" then
            detachFromTarget()

            local chest, part = getNearbyChest()
            if chest and part then
                teleportTo(part.Position)
                task.wait(0.1)
                pressT()
                task.wait(0.4)

                if chest and chest.Parent then
                    pcall(function() chest:Destroy() end)
                end
            end

            task.wait(0.2)

            local lootStartTime = os.clock()
            local LOOT_TIMEOUT = 8
            local NO_LOOT_LIMIT = 8
            local noLootStreak = 0
            local totalPicked = 0

            while os.clock() - lootStartTime < LOOT_TIMEOUT do
                local loot = getNearbyLoot()

                if loot then
                    teleportTo(loot.Position)
                    task.wait(0.08)
                    pressT()
                    task.wait(0.15)
                    noLootStreak = 0
                    totalPicked = totalPicked + 1
                else
                    noLootStreak = noLootStreak + 1
                    if noLootStreak >= NO_LOOT_LIMIT then
                        break
                    end
                    task.wait(0.1)
                end
            end

            debug(string.format("[LOOTING] Picked up %d loot(s)", totalPicked))

            FarmState.CurrentBoss = nil
            FarmState.State = "WAITING"

        elseif FarmState.State == "WAITING" then
            task.wait(1)
            FarmState.State = "IDLE"
        end
    end
end)
