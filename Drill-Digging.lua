local Players = game:GetService("Players")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local PlaceName = game:GetService("AssetService"):GetGamePlacesAsync(game.GameId):GetCurrentPage()[1].Name
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")


getfenv().getgenv().PlaceName = PlaceName

local Window

Rayfield:Notify({
        Title = "UNIX Loaded",
        Content = "Exploiting Shitty Games.. ",
        Duration = 6.5,
        Image = "eye"
})

Window = Rayfield:CreateWindow({
        Name = "U N I X - " .. PlaceName,
        LoadingTitle = "U N I X - " .. PlaceName,
        LoadingSubtitle = "by 0x256",
        Theme = "Default",
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = true,
        ConfigurationSaving = {
            Enabled = true,
            FileName = "UNIX-" .. PlaceName
        },

        Discord = {
            Enabled = true,
            Invite = "2sZV8k3B97",
            RememberJoins = true
        },
})

-- Slider Toggles Cuz Gay 
local moneyLoop = false
local farmWinsLoop = false
local eggOptions = {}
local eggAmount = 0 


if workspace:FindFirstChild("KPets") and workspace.KPets:FindFirstChild("Eggs") then
    eggOptions = {}
    for _, egg in pairs(workspace.KPets.Eggs:GetChildren()) do
        if egg:IsA("Model") then
            table.insert(eggOptions, egg.Name)
        end
    end
end



local function OpenInvite()
    local InviteCode = "2sZV8k3B97"
    local request = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request
    if request then
        request({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://discord.com"
            },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = {code = InviteCode},
                nonce = HttpService:GenerateGUID(false)
            })
        })
    end
end

OpenInvite()



Exploit = Window:CreateTab("Exploits", "eye")

Exploit:CreateSection("Drill")

Exploit:CreateSlider({
    Name = "Drill Power",
    Range = {0, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 10,
    Flag = "DrillPower",
    Callback = function(Value)
        pcall(function()
            local DrillPowerMultiplier = LocalPlayer:FindFirstChild("DrillPowerMultiplier")
            if DrillPowerMultiplier then
                DrillPowerMultiplier.Value = Value
            end
        end)
    end,
})


Exploit:CreateToggle({
    Name = "Farm Money (Better pets = more money)",
    Default = false,
    Callback = function(Value)
        moneyLoop = Value
        
        if Value then
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local tool = character:FindFirstChildOfClass("Tool")
            if not tool then
                tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                if tool then
                    Rayfield:Notify({
                        Title = "Warning",
                        Content = "Please equip your drill",
                        Duration = 5,
                        Image = "eye"
                    })
                    return
                end
            end
            
            if tool then
                Rayfield:Notify({
                    Title = "Success",
                    Content = "Get better pets to get more money!",
                    Duration = 5,
                    Image = "eye"
                })
                while moneyLoop do
                    local args = { [1] = game:GetService("Players").LocalPlayer.Character[tool.Name] }
                    game:GetService("ReplicatedStorage"):WaitForChild("GiveCash"):FireServer(unpack(args))
                    task.wait(0.1)
                end
            else 
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Please have a drill, Better pets will give you more money",
                    Duration = 5,
                    Image = "eye"
                })
            end
        end
    end
})

Exploit:CreateToggle({
    Name = "Farm Wins",
    Default = false,
    Callback = function(Value)
        farmWinsLoop = Value
        
        if Value then
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                local touchParts = {
                    workspace.Worlds.Dinosaur.EndZone.EndCircle.Part,
                    workspace.Worlds.Frozen.EndZone.EndCircle.Part,
                    workspace.Worlds.Jungle.EndZone.EndCircle.Part,
                    workspace.Worlds.Magic.EndZone.EndCircle.Part,
                    workspace.Worlds.Main.EndZone.EndCircle.Part
                }
                
                local function fireTouches()
                    for _, part in ipairs(touchParts) do
                        firetouchinterest(hrp, part, 0)
                        task.wait(0.5)
                        firetouchinterest(hrp, part, 1)
                    end
                end
                
                while farmWinsLoop do
                    fireTouches()
                    task.wait(3)
                end
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Failed to find Player idk why lol... load in lil nigga",
                    Duration = 5,
                    Image = "eye"
                })
            end
        end
    end
})

local EggDropdown = Exploit:CreateDropdown({
    Name = "Select Egg",
    Options = eggOptions,
    CurrentOption = eggOptions[1],
    MultipleOptions = false,
    Flag = "EggSelector",
    Callback = function(Selected)
    end,
})

local EggInput = Exploit:CreateSlider({
    Name = "Egg Amount (dont need a gamepass)",
    Range = {1, 20},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "Egg",
    Callback = function(Amount)
        eggAmount = Amount
    end,
})

Exploit:CreateToggle({
    Name = "Open Egg",
    Default = false,
    Callback = function()
        local selectedEgg = EggDropdown.CurrentOption[1]
        local openAmount = eggAmount
   
        
        local args = {
            [1] = selectedEgg,
            [2] = openAmount
        }
        table.foreach(args, print)
        game:GetService("ReplicatedStorage"):WaitForChild("KPets"):WaitForChild("Events"):WaitForChild("Hatch"):FireServer(unpack(args))
    end,
})

