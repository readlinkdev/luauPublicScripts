local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local paperRemote = ReplicatedStorage:WaitForChild("Paper"):WaitForChild("Remotes")
local remoteEvent = paperRemote:WaitForChild("__remoteevent")
local remoteFunction = paperRemote:WaitForChild("__remotefunction")

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local SECTION_EGGS = "Eggs"
local SECTION_CASH = "Cash"
local SECTION_CHICKENS = "Chickens"
local SECTION_MISC = "Misc"
local SECTION_SETTINGS = "Settings"
local SECTION_LANGUAGE = "Language"

local TXT_AUTOMATION = "Automation"
local TXT_COLLECT_EGGS = "Auto Collect Eggs"
local TXT_COLLECT_EGGS_DESC = "Automatically collects all eggs on the ground"

local TXT_DEPOSIT_EGGS = "Auto Deposit Eggs"
local TXT_DEPOSIT_EGGS_DESC = "Automatically deposits the collected eggs"

local TXT_COLLECT_CASH = "Auto Collect Cash"
local TXT_COLLECT_CASH_DESC = "Automatically collects the available cash"

local TXT_UPGRADE_CASH = "Auto Upgrade Cash"
local TXT_UPGRADE_CASH_DESC = "Automatically upgrades the cash process level"

local TXT_BUY_QUANTITY = "Buy Quantity"
local TXT_BUY_QUANTITY_DESC = "Amount of chickens bought per purchase"

local TXT_BUY_CHICKENS = "Auto Buy Chickens"
local TXT_BUY_CHICKENS_DESC = "Automatically buys chickens in the selected quantity"

local TXT_MERGE_CHICKENS = "Auto Merge Chickens"
local TXT_MERGE_CHICKENS_DESC = "Automatically merges matching chickens"

local TXT_AUTO_REBIRTH = "Auto Rebirth"
local TXT_AUTO_REBIRTH_DESC = "Automatically rebirths when possible"

local TXT_AUTO_BUY_TIER = "Auto Upgrade Buy Tier"
local TXT_AUTO_BUY_TIER_DESC = "Automatically upgrades the buy tier level"

local TXT_LANGUAGE = "Language"
local TXT_LANGUAGE_DESC = "Choose the interface language"

local translations = {
    ["pt-br"] = {
        [TXT_AUTOMATION] = "Automação",
        [SECTION_SETTINGS] = "Configurações",
        [SECTION_LANGUAGE] = "Idioma",

        [SECTION_EGGS] = "Ovos",
        [TXT_COLLECT_EGGS] = "Coletar Ovos Automático",
        [TXT_COLLECT_EGGS_DESC] = "Coleta automaticamente todos os ovos do chão",
        [TXT_DEPOSIT_EGGS] = "Depositar Ovos Automático",
        [TXT_DEPOSIT_EGGS_DESC] = "Deposita automaticamente os ovos coletados",

        [SECTION_CASH] = "Dinheiro",
        [TXT_COLLECT_CASH] = "Coletar Dinheiro Automático",
        [TXT_COLLECT_CASH_DESC] = "Coleta automaticamente o dinheiro disponível",
        [TXT_UPGRADE_CASH] = "Melhorar Dinheiro Automático",
        [TXT_UPGRADE_CASH_DESC] = "Melhora automaticamente o nível de processamento de dinheiro",

        [SECTION_CHICKENS] = "Galinhas",
        [TXT_BUY_QUANTITY] = "Quantidade de Compra",
        [TXT_BUY_QUANTITY_DESC] = "Quantidade de galinhas compradas por vez",
        [TXT_BUY_CHICKENS] = "Comprar Galinhas Automático",
        [TXT_BUY_CHICKENS_DESC] = "Compra galinhas automaticamente na quantidade selecionada",
        [TXT_MERGE_CHICKENS] = "Fundir Galinhas Automático",
        [TXT_MERGE_CHICKENS_DESC] = "Funde automaticamente as galinhas iguais",

        [SECTION_MISC] = "Diversos",
        [TXT_AUTO_REBIRTH] = "Renascimento Automático",
        [TXT_AUTO_REBIRTH_DESC] = "Renascimento automático quando possível",
        [TXT_AUTO_BUY_TIER] = "Melhorar Nível de Compra Automático",
        [TXT_AUTO_BUY_TIER_DESC] = "Melhora automaticamente o nível de compra de galinhas",

        [TXT_LANGUAGE] = "Idioma",
        [TXT_LANGUAGE_DESC] = "Escolha o idioma da interface",
    },
    ["en-us"] = {
        [TXT_AUTOMATION] = "Automation",
        [SECTION_SETTINGS] = "Settings",
        [SECTION_LANGUAGE] = "Language",

        [SECTION_EGGS] = "Eggs",
        [TXT_COLLECT_EGGS] = "Auto Collect Eggs",
        [TXT_COLLECT_EGGS_DESC] = "Automatically collects all eggs on the ground",
        [TXT_DEPOSIT_EGGS] = "Auto Deposit Eggs",
        [TXT_DEPOSIT_EGGS_DESC] = "Automatically deposits the collected eggs",

        [SECTION_CASH] = "Cash",
        [TXT_COLLECT_CASH] = "Auto Collect Cash",
        [TXT_COLLECT_CASH_DESC] = "Automatically collects the available cash",
        [TXT_UPGRADE_CASH] = "Auto Upgrade Cash",
        [TXT_UPGRADE_CASH_DESC] = "Automatically upgrades the cash process level",

        [SECTION_CHICKENS] = "Chickens",
        [TXT_BUY_QUANTITY] = "Buy Quantity",
        [TXT_BUY_QUANTITY_DESC] = "Amount of chickens bought per purchase",
        [TXT_BUY_CHICKENS] = "Auto Buy Chickens",
        [TXT_BUY_CHICKENS_DESC] = "Automatically buys chickens in the selected quantity",
        [TXT_MERGE_CHICKENS] = "Auto Merge Chickens",
        [TXT_MERGE_CHICKENS_DESC] = "Automatically merges matching chickens",

        [SECTION_MISC] = "Misc",
        [TXT_AUTO_REBIRTH] = "Auto Rebirth",
        [TXT_AUTO_REBIRTH_DESC] = "Automatically rebirths when possible",
        [TXT_AUTO_BUY_TIER] = "Auto Upgrade Buy Tier",
        [TXT_AUTO_BUY_TIER_DESC] = "Automatically upgrades the buy tier level",

        [TXT_LANGUAGE] = "Language",
        [TXT_LANGUAGE_DESC] = "Choose the interface language",
    },
}

local window = Rayfield:CreateWindow({
    name = "Astra",
    subtitle = "Chicken Farm",
    sidebarLayout = true,
    theme = "cobalt",
    translations = translations,

    configuration = {
        enabled = true,
        name = "Astra_ChickenFarm"
    }
})

local tabAutomation = window:CreateTab({ name = TXT_AUTOMATION, icon = 93364949241311 })
local tabSettings = window:CreateTab({ name = SECTION_SETTINGS, icon = 93364949241311 })

local loops = {}

local function runLoop(key, fn, interval)
    if loops[key] then return end
    loops[key] = true

    task.spawn(function()
        while loops[key] do
            local ok, err = pcall(fn)
            if not ok then
                warn(("[Astra] erro em %s: %s"):format(key, err))
            end
            task.wait(interval or 1)
        end
    end)
end

local function stopLoop(key)
    loops[key] = false
end

local buyQuantity = 1

tabAutomation:CreateSection({ name = SECTION_EGGS })

tabAutomation:CreateToggle({
    name = TXT_COLLECT_EGGS,
    description = TXT_COLLECT_EGGS_DESC,
    flag = "collectEggs",
    default = false,
    callback = function(value)
        if value then
            runLoop("collectEggs", function()
                local eggs = Workspace:FindFirstChild("Eggs")
                if not eggs then return end

                for _, egg in ipairs(eggs:GetChildren()) do
                    if egg:IsA("Model") or egg:IsA("BasePart") then
                        remoteEvent:FireServer("Collect Egg", egg.Name)
                        egg:Destroy()
                    end
                end
            end, 0.5)
        else
            stopLoop("collectEggs")
        end
    end,
})

tabAutomation:CreateToggle({
    name = TXT_DEPOSIT_EGGS,
    description = TXT_DEPOSIT_EGGS_DESC,
    flag = "depositEggs",
    default = false,
    callback = function(value)
        if value then
            runLoop("depositEggs", function()
                remoteFunction:InvokeServer("Deposit Eggs")
            end, 1)
        else
            stopLoop("depositEggs")
        end
    end,
})

tabAutomation:CreateSection({ name = SECTION_CASH })

tabAutomation:CreateToggle({
    name = TXT_COLLECT_CASH,
    description = TXT_COLLECT_CASH_DESC,
    flag = "collectCash",
    default = false,
    callback = function(value)
        if value then
            runLoop("collectCash", function()
                remoteFunction:InvokeServer("Collect Cash")
            end, 1)
        else
            stopLoop("collectCash")
        end
    end,
})

tabAutomation:CreateToggle({
    name = TXT_UPGRADE_CASH,
    description = TXT_UPGRADE_CASH_DESC,
    flag = "upgradeCash",
    default = false,
    callback = function(value)
        if value then
            runLoop("upgradeCash", function()
                remoteFunction:InvokeServer("Upgrade Process Level")
            end, 2)
        else
            stopLoop("upgradeCash")
        end
    end,
})

tabAutomation:CreateSection({ name = SECTION_CHICKENS })

tabAutomation:CreateDropdown({
    name = TXT_BUY_QUANTITY,
    description = TXT_BUY_QUANTITY_DESC,
    flag = "buyQuantity",
    options = { "1 Chicken", "5 Chickens", "25 Chickens", "100 Chickens" },
    currentOption = { "1 Chicken" },
    callback = function(option)
        local opt = type(option) == "table" and option[1] or option
        buyQuantity = tonumber(opt:match("%d+")) or 1
    end,
})

tabAutomation:CreateToggle({
    name = TXT_BUY_CHICKENS,
    description = TXT_BUY_CHICKENS_DESC,
    flag = "buyChickens",
    default = false,
    callback = function(value)
        if value then
            runLoop("buyChickens", function()
                remoteFunction:InvokeServer("Buy Chickens", buyQuantity)
            end, 1)
        else
            stopLoop("buyChickens")
        end
    end,
})

tabAutomation:CreateToggle({
    name = TXT_MERGE_CHICKENS,
    description = TXT_MERGE_CHICKENS_DESC,
    flag = "mergeChickens",
    default = false,
    callback = function(value)
        if value then
            runLoop("mergeChickens", function()
                remoteFunction:InvokeServer("Merge Chickens")
            end, 1.5)
        else
            stopLoop("mergeChickens")
        end
    end,
})

tabAutomation:CreateSection({ name = SECTION_MISC })

tabAutomation:CreateToggle({
    name = TXT_AUTO_REBIRTH,
    description = TXT_AUTO_REBIRTH_DESC,
    flag = "autoRebirth",
    default = false,
    callback = function(value)
        if value then
            runLoop("autoRebirth", function()
                remoteFunction:InvokeServer("Rebirth")
            end, 3)
        else
            stopLoop("autoRebirth")
        end
    end,
})

tabAutomation:CreateToggle({
    name = TXT_AUTO_BUY_TIER,
    description = TXT_AUTO_BUY_TIER_DESC,
    flag = "autoBuyTier",
    default = false,
    callback = function(value)
        if value then
            runLoop("autoBuyTier", function()
                remoteFunction:InvokeServer("Upgrade Buy Tier Level")
            end, 3)
        else
            stopLoop("autoBuyTier")
        end
    end,
})

tabSettings:CreateSection({ name = SECTION_LANGUAGE })

tabSettings:CreateDropdown({
    name = TXT_LANGUAGE,
    description = TXT_LANGUAGE_DESC,
    flag = "language",
    options = { "en-us", "pt-br" },
    currentOption = { "en-us" },
    callback = function(option)
        local opt = type(option) == "table" and option[1] or option
        window:SetLocale(opt)
    end,
})
