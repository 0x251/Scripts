local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local PlaceName = game:GetService("AssetService"):GetGamePlacesAsync(game.GameId):GetCurrentPage()[1].Name
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")


getfenv().getgenv().PlaceName = PlaceName

local Window
local Esp
local Teleport
local ESPCache = {}

local PlayerESP = {
    Enabled = false,
    Color = Color3.new(1, 1, 1),
    Font = Enum.Font.SourceSansBold,
    TextSize = 18,
    ShowDistance = true,
    ShowHealth = true
}

local CharmsESP = {
    Enabled = false,
    Color = Color3.new(1, 0, 0),
    FillTransparency = 0.5,
    OutlineTransparency = 0,
    DepthMode = "AlwaysOnTop"
}


local function CreateMainWindow()
    Rayfield:Notify({
        Title = "UNIX Loaded",
        Content = "ESP features activated for "..PlaceName,
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

    Esp = Window:CreateTab("ESP", "eye")
    Teleport = Window:CreateTab("Teleports", "arrow-right")
    Mobs = Window:CreateTab("Mobs", "axe")
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


local function SetupTeleportTab()
    local function fetchValidTargets()
        local validNames = {}
        for _, user in ipairs(Players:GetPlayers()) do
            if user ~= LocalPlayer then
                table.insert(validNames, user.Name)
            end
        end
        return validNames
    end

    local selectedPlayer = nil
    local movementLoop = nil
    local walkLoop = nil
    local originalPhysics = nil
    local travelRate = 16.5
    local baseSpeed = 8.5
    local walkSpeed = 16

    Teleport:CreateSlider({
        Name = "Teleport Speed",
        Range = {5, 60},
        Increment = 0.5,
        Suffix = " studs/s",
        CurrentValue = 16.5,
        Flag = "TeleportSpeed",
        Callback = function(newValue)
            travelRate = newValue
            baseSpeed = newValue / 2
        end
    })

    Teleport:CreateSlider({
        Name = "Walk Speed",
        Range = {16, 100},
        Increment = 1,
        Suffix = " studs/s",
        CurrentValue = 16,
        Flag = "WalkSpeed",
        Callback = function(newValue)
            walkSpeed = newValue
            if walkLoop then
                walkLoop:Disconnect()
                walkLoop = nil
            end
            
            if newValue > 16 then
                walkLoop = RunService.Heartbeat:Connect(function()
                    if LocalPlayer.Character then
                        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        
                        if root and humanoid then
                            local moveDirection = humanoid.MoveDirection
                            if moveDirection.Magnitude > 0 then
                                local velocity = moveDirection.Unit * walkSpeed
                                root.Velocity = Vector3.new(velocity.X, root.Velocity.Y, velocity.Z)
                                root.CFrame = CFrame.lookAt(root.Position, root.Position + moveDirection)
                            end
                        end
                    end
                end)
            end
        end
    })

    local PlayerSelector = Teleport:CreateDropdown({
        Name = "Select Player",
        Options = fetchValidTargets(),
        CurrentOption = {"Select a Player"},
        MultipleOptions = false,
        Flag = "PlayerTeleportList",
        Callback = function(choice)
            if choice[1] == selectedPlayer then
                if movementLoop then
                    movementLoop:Disconnect()
                    movementLoop = nil
                end
                if originalPhysics and LocalPlayer.Character then
                    LocalPlayer.Character:FindFirstChild("HumanoidRootPart").CanCollide = originalPhysics
                end
                selectedPlayer = nil
                PlayerSelector:Set({})
                return
            end

            selectedPlayer = choice[1]
            local destinationUser = Players:FindFirstChild(selectedPlayer)
            
            if destinationUser and destinationUser.Character then
                local playerTorso = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if playerTorso then
                    originalPhysics = playerTorso.CanCollide
                    playerTorso.CanCollide = false
                end

                movementLoop = RunService.Heartbeat:Connect(function()
                    local playerTorso = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local targetTorso = destinationUser.Character:FindFirstChild("HumanoidRootPart")
                    local body = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    
                    if not playerTorso or not targetTorso or not body then
                        if movementLoop then
                            movementLoop:Disconnect()
                            movementLoop = nil
                        end
                        selectedPlayer = nil
                        PlayerSelector:Set({})
                        return
                    end

                    for _, component in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if component:IsA("BasePart") then
                            component.CanCollide = false
                            component.CanTouch = false
                        end
                    end

                    local trajectory = (targetTorso.Position - playerTorso.Position).Unit
                    local gap = (targetTorso.Position - playerTorso.Position).Magnitude
                    
                    local heightMod = math.sin(tick()*5)*0.12 + 0.25
                    local positionJitter = Vector3.new(math.random(-0.3,0.3), 0, math.random(-0.3,0.3))
                    
                    body.PlatformStand = true
                    playerTorso.Velocity = trajectory * travelRate + Vector3.new(0, heightMod, 0)
                    
                    local smoothPosition = CFrame.lookAt(
                        playerTorso.Position + (trajectory * (travelRate * 0.15)) + positionJitter,
                        targetTorso.Position + positionJitter
                    ) * CFrame.Angles(
                        math.rad(math.random(-2,2)), 
                        math.rad(math.random(-15,15)), 
                        math.rad(math.random(-2,2))
                    )

                    playerTorso.CFrame = smoothPosition:Lerp(playerTorso.CFrame, 0.7)

                    if gap < 18 then
                        playerTorso.CFrame = targetTorso.CFrame + Vector3.new(
                            math.random(-1.2,1.2), 
                            2.75 + math.random()*0.3, 
                            math.random(-1.2,1.2)
                        )
                        task.wait(math.random() * 0.15 + 0.05)
                        playerTorso.Velocity = Vector3.new(0, -9.5, 0)
                        task.wait(math.random() * 0.15 + 0.05)
                        playerTorso.CFrame = targetTorso.CFrame + Vector3.new(0, 0.85, 0)
                        
                        if movementLoop then
                            movementLoop:Disconnect()
                            movementLoop = nil
                        end
                        if originalPhysics then
                            playerTorso.CanCollide = originalPhysics
                        end
                        body.PlatformStand = false
                        selectedPlayer = nil
                        PlayerSelector:Set({})
                    end
                end)
            end
        end
    })

    local BoardSelector = Teleport:CreateDropdown({
        Name = "Select Board",
        Options = (function()
            local boards = {}
            for _, child in ipairs(workspace.Boards:GetChildren()) do
                table.insert(boards, child.Name)
            end
            return boards
        end)(),
        CurrentOption = {"Select a Board"},
        MultipleOptions = false,
        Flag = "BoardTeleportList",
        Callback = function(choice)
            if choice[1] == selectedBoard then
                if movementLoop then
                    movementLoop:Disconnect()
                    movementLoop = nil
                end
                if originalPhysics and LocalPlayer.Character then
                    LocalPlayer.Character:FindFirstChild("HumanoidRootPart").CanCollide = originalPhysics
                end
                selectedBoard = nil
                BoardSelector:Set({})
                return
            end

            selectedBoard = choice[1]
            local targetBoard = workspace.Boards:FindFirstChild(selectedBoard)
            
            if targetBoard then
                local playerTorso = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if playerTorso then
                    originalPhysics = playerTorso.CanCollide
                    playerTorso.CanCollide = false
                end

                movementLoop = RunService.Heartbeat:Connect(function()
                    local playerTorso = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local body = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    local boardPosition = targetBoard.PrimaryPart.Position
                    
                    if not playerTorso or not body or not targetBoard.Parent then
                        if movementLoop then
                            movementLoop:Disconnect()
                            movementLoop = nil
                        end
                        selectedBoard = nil
                        BoardSelector:Set({})
                        return
                    end

                    for _, component in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if component:IsA("BasePart") then
                            component.CanCollide = false
                            component.CanTouch = false
                        end
                    end

                    local trajectory = (boardPosition - playerTorso.Position).Unit
                    local gap = (boardPosition - playerTorso.Position).Magnitude
                    
                    local heightMod = math.sin(tick()*5)*0.12 + 0.25
                    local positionJitter = Vector3.new(math.random(-0.3,0.3), 0, math.random(-0.3,0.3))
                    
                    body.PlatformStand = true
                    playerTorso.Velocity = trajectory * travelRate + Vector3.new(0, heightMod, 0)
                    
                    local smoothPosition = CFrame.lookAt(
                        playerTorso.Position + (trajectory * (travelRate * 0.15)) + positionJitter,
                        boardPosition + positionJitter
                    ) * CFrame.Angles(
                        math.rad(math.random(-2,2)), 
                        math.rad(math.random(-15,15)), 
                        math.rad(math.random(-2,2))
                    )

                    playerTorso.CFrame = smoothPosition:Lerp(playerTorso.CFrame, 0.7)

                    if gap < 18 then
                        playerTorso.CFrame = CFrame.new(boardPosition) + Vector3.new(
                            math.random(-1.2,1.2), 
                            2.75 + math.random()*0.3, 
                            math.random(-1.2,1.2)
                        )
                        task.wait(math.random() * 0.15 + 0.05)
                        playerTorso.Velocity = Vector3.new(0, -9.5, 0)
                        task.wait(math.random() * 0.15 + 0.05)
                        playerTorso.CFrame = CFrame.new(boardPosition) + Vector3.new(0, 0.85, 0)
                        
                        if movementLoop then
                            movementLoop:Disconnect()
                            movementLoop = nil
                        end
                        if originalPhysics then
                            playerTorso.CanCollide = originalPhysics
                        end
                        body.PlatformStand = false
                        selectedBoard = nil
                        BoardSelector:Set({})
                    end
                end)
            end
        end
    })

    local function updatePlayerOptions()
        task.wait(math.random(0.3, 0.7))
        PlayerSelector:Refresh(fetchValidTargets())
        if selectedPlayer and not Players:FindFirstChild(selectedPlayer) then
            PlayerSelector:Set({})
            selectedPlayer = nil
        end
    end

    Players.PlayerAdded:Connect(updatePlayerOptions)
    Players.PlayerRemoving:Connect(updatePlayerOptions)
end
local function SetupMobsTab()
    Mobs:CreateSection("Mobs")

    local initialHitboxSize = 10
    local hitboxConnection
    local mobFilter = function(mob)
        return mob:IsA("Model") and not game.Players:GetPlayerFromCharacter(mob)
    end

    local autoFarmEnabled = false
    local farmConnection
    local currentMob
    local targetMobs = {}
    local travelSpeed = 60
    local nameLookup = {}
    local cleanedNames = {}
    local currentMobTime = 0
    local lastMobFoundTime = 0

    local mobDropdown = Mobs:CreateDropdown({
        Name = "Select Mobs",
        Options = {"No mobs available"},
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "MobTargetList",
        Callback = function(Options)
            targetMobs = Options
            currentMob = nil
            if autoFarmEnabled and farmConnection then
                farmConnection:Disconnect()
                farmConnection = RunService.Heartbeat:Connect(autoFarmLoop)
                
                if #targetMobs == 0 and LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if humanoid and rootPart then
                        humanoid.PlatformStand = false
                        rootPart.Velocity = Vector3.new(0,0,0)
                        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = true
                                part.CanTouch = true
                            end
                        end
                    end
                end
            end
        end
    })

    local function refreshMobList()
        local mobNames = {}
        local existing = {}
        local currentNames = {}

        for _, mob in ipairs(workspace.Alive:GetChildren()) do
            if mobFilter(mob) and mob.Name:find("%S") then
                local cleanName = mob.Name:gsub("%..*", "")
                currentNames[cleanName] = true
                if not existing[cleanName] then
                    table.insert(mobNames, cleanName)
                    existing[cleanName] = true
                end
                nameLookup[cleanName] = nameLookup[cleanName] or {}
                if not table.find(nameLookup[cleanName], mob.Name) then
                    table.insert(nameLookup[cleanName], mob.Name)
                end
                cleanedNames[mob.Name] = cleanName
            end
        end

        for cleanName in pairs(nameLookup) do
            if not currentNames[cleanName] and not table.find(mobNames, cleanName) then
                table.insert(mobNames, cleanName)
            end
        end

        mobDropdown:Refresh(#mobNames > 0 and mobNames or {"No mobs available"})
    end

    local function getMobRootPart(mob)
        return mob.PrimaryPart or mob:FindFirstChild("HumanoidRootPart")
    end

    local function updateMobHitbox(mob)
        local rootPart = getMobRootPart(mob)
        if rootPart and rootPart:IsA("BasePart") then
            rootPart.Size = Vector3.new(initialHitboxSize, initialHitboxSize, initialHitboxSize)
        end
    end

    local function processExistingMobs()
        for _, mob in ipairs(workspace.Alive:GetChildren()) do
            if mobFilter(mob) then
                updateMobHitbox(mob)
            end
        end
    end

    Mobs:CreateSlider({
        Name = "Hitbox Size",
        Range = {1, 200},
        Increment = 1,
        CurrentValue = initialHitboxSize,
        Flag = "HitboxSize",
        Callback = function(newSize)
            initialHitboxSize = newSize
            processExistingMobs()
        end
    })

    Mobs:CreateSlider({
        Name = "Auto Farm Speed",
        Range = {10, 200},
        Increment = 10,
        CurrentValue = travelSpeed,
        Flag = "FarmSpeed",
        Callback = function(value)
            travelSpeed = value
        end
    })

    Mobs:CreateToggle({
        Name = "Mobs Hitbox Expander",
        CurrentValue = false,
        Flag = "MobsHitboxExpanderEnabled",
        Callback = function(enabled)
            if enabled then
                processExistingMobs()
                hitboxConnection = workspace.Alive.ChildAdded:Connect(function(newMob)
                    if mobFilter(newMob) then
                        local attempts = 0
                        repeat 
                            task.wait(0.1)
                            attempts = attempts + 1
                        until getMobRootPart(newMob) or attempts >= 10
                        
                        if getMobRootPart(newMob) then
                            updateMobHitbox(newMob)
                            refreshMobList()
                        end
                    end
                end)
            else
                if hitboxConnection then
                    hitboxConnection:Disconnect()
                    hitboxConnection = nil
                end
            end
        end
    })

    local function autoFarmLoop()
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local now = tick()
        
        if not rootPart or not humanoid then return end
        if #targetMobs == 0 then
            for _, component in ipairs(character:GetDescendants()) do
                if component:IsA("BasePart") then
                    component.CanCollide = true
                    component.CanTouch = true
                end
            end
            humanoid.PlatformStand = false
            rootPart.Velocity = Vector3.new(0,0,0)
            return
        end

        for _, component in ipairs(character:GetDescendants()) do
            if component:IsA("BasePart") then
                component.CanCollide = false
                component.CanTouch = false
            end
        end

        if currentMob and (not currentMob:FindFirstChild("Humanoid") or currentMob.Humanoid.Health <= 0 or (rootPart.Position - currentMob:GetPivot().Position).Magnitude > 150 or (now - currentMobTime) > 3) then
            currentMob = nil
        end

        local closestDistance = math.huge
        local potentialTargets = {}
        for _, mob in ipairs(workspace.Alive:GetChildren()) do
            if mobFilter(mob) and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and getMobRootPart(mob) then
                local cleanName = mob.Name:gsub("%..*", "")
                if table.find(targetMobs, cleanName) then
                    local distance = (rootPart.Position - mob:GetPivot().Position).Magnitude
                    table.insert(potentialTargets, {mob = mob, distance = distance})
                end
            end
        end

        table.sort(potentialTargets, function(a, b) return a.distance < b.distance end)
        local hasAliveTargets = #potentialTargets > 0

         if hasAliveTargets then
            currentMob = potentialTargets[1].mob
            currentMobTime = now
            lastMobFoundTime = now
        else
            currentMob = nil
        end

        if currentMob then
            local mobPosition = currentMob:GetPivot().Position
            local gap = (rootPart.Position - mobPosition).Magnitude
            
            local trajectory = (mobPosition - rootPart.Position).Unit
            local heightMod = math.sin(tick()*5)*0.12 + 0.25
            local positionJitter = Vector3.new(math.random(-0.3,0.3), 0, math.random(-0.3,0.3))
            local dodgeMod = math.sin(tick()*3) * 1.5
            
            humanoid.PlatformStand = true
            rootPart.Velocity = trajectory * (travelSpeed + dodgeMod) + Vector3.new(0, heightMod, 0)
            
            local smoothPosition = CFrame.lookAt(
                rootPart.Position + (trajectory * (travelSpeed * 0.15)) + positionJitter,
                mobPosition + positionJitter
            ) * CFrame.Angles(
                math.rad(math.random(-2,2)), 
                math.rad(math.random(-15,15)), 
                math.rad(math.random(-2,2))
            )

            rootPart.CFrame = smoothPosition:Lerp(rootPart.CFrame, 0.7)

            if gap < 18 then
                local orbitAngle = math.rad(tick() * 180 % 360)
                local orbitOffset = Vector3.new(math.cos(orbitAngle)*3, 2.75 + math.sin(tick()*5)*0.3, math.sin(orbitAngle)*3)
                rootPart.CFrame = CFrame.new(mobPosition + orbitOffset) * CFrame.Angles(0, orbitAngle, 0)
                rootPart.Velocity = Vector3.new(0, math.sin(tick()*4)*4, 0)
            end
        else
            if not hasAliveTargets then
                humanoid.PlatformStand = false
                rootPart.Velocity = Vector3.new(0, 0, 0)
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                        part.CanTouch = true
                    end
                end
            else
                humanoid.PlatformStand = true
                rootPart.Velocity = Vector3.new(0, 5, 0)
                local hoverCFrame = CFrame.new(rootPart.Position) * CFrame.new(math.sin(tick()*5)*2, 3 + math.sin(tick()*3), math.cos(tick()*5)*2)
                rootPart.CFrame = hoverCFrame:Lerp(rootPart.CFrame, 0.7)

                for _, mob in ipairs(workspace.Alive:GetChildren()) do
                    if mobFilter(mob) and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and getMobRootPart(mob) then
                        local cleanName = cleanedNames[mob.Name]
                        if table.find(targetMobs, cleanName) then
                            currentMob = mob
                            currentMobTime = now
                            lastMobFoundTime = now
                            break
                        end
                    end
                end
            end
        end
    end

    Mobs:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = false,
        Flag = "AutoFarmEnabled",
        Callback = function(enabled)
            autoFarmEnabled = enabled
            if enabled then
                lastMobFoundTime = tick()
                farmConnection = RunService.Heartbeat:Connect(autoFarmLoop)
            else
                if farmConnection then
                    farmConnection:Disconnect()
                    farmConnection = nil
                end
                if LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.PlatformStand = false
                    end
                end
                currentMob = nil
            end
        end
    })

    local autoClickerEnabled = false
    local autoClickerConnection
    Mobs:CreateKeybind({
        Name = "Auto Attack",
        CurrentKeybind = "Zero",
        HoldToInteract = false,
        Flag = "AutoClickerKeybind",
        Callback = function()
            autoClickerEnabled = not autoClickerEnabled
            if autoClickerEnabled then
                autoClickerConnection = RunService.Heartbeat:Connect(function()
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, nil, false)
                end)
            else
                if autoClickerConnection then
                    autoClickerConnection:Disconnect()
                    autoClickerConnection = nil
                end
            end
        end
    })

    refreshMobList()
    task.spawn(function()
        while task.wait(30) do
            refreshMobList()
        end
    end)
end

local function SetupESPTab()
    
    local function CreatePlayerESPControls()
        Esp:CreateSection("Player ESP Settings")
        Esp:CreateToggle({
            Name = "Enable Player ESP",
            CurrentValue = false,
            Flag = "PlayerESPEnabled",
            Callback = function(Value)
                PlayerESP.Enabled = Value
                for _, espData in pairs(ESPCache) do
                    if espData.billboard then
                        espData.billboard.Enabled = Value
                    end
                end
            end
        })

        Esp:CreateColorPicker({
            Name = "Text Color",
            Color = PlayerESP.Color,
            Flag = "PlayerESPColor",
            Callback = function(Value)
                PlayerESP.Color = Value
            end
        })

        Esp:CreateSlider({
            Name = "Text Size",
            Range = {10, 24},
            Increment = 1,
            Suffix = "px",
            CurrentValue = 18,
            Flag = "PlayerESPSize",
            Callback = function(Value)
                PlayerESP.TextSize = Value
            end
        })
    end

    local function CreateDisplayOptions()
        Esp:CreateSection("Display Options")
        Esp:CreateToggle({
            Name = "Show Distance",
            CurrentValue = true,
            Flag = "PlayerESPDistance",
            Callback = function(Value)
                PlayerESP.ShowDistance = Value
            end
        })

        Esp:CreateToggle({
            Name = "Show Health",
            CurrentValue = true,
            Flag = "PlayerESPHealth",
            Callback = function(Value)
                PlayerESP.ShowHealth = Value
            end
        })
    end
    local function CreateCharmsControls()
        Esp:CreateSection("Charms Settings")
        Esp:CreateToggle({
            Name = "Charms ESP",
            CurrentValue = false,
            Flag = "CharmsESPEnabled",
            Callback = function(Value)
                CharmsESP.Enabled = Value
                for _, espData in pairs(ESPCache) do
                    if espData.highlight then
                        espData.highlight.Enabled = Value
                        espData.highlight.DepthMode = CharmsESP.DepthMode
                    end
                end
            end
        })

        Esp:CreateColorPicker({
            Name = "Charms Color",
            Color = CharmsESP.Color,
            Flag = "CharmsESPColor",
            Callback = function(Value)
                CharmsESP.Color = Value
                for _, espData in pairs(ESPCache) do
                    if espData.highlight then
                        espData.highlight.FillColor = Value
                        espData.highlight.OutlineColor = Value
                    end
                end
            end
        })

        Esp:CreateDropdown({
            Name = "Outline Mode",
            Options = {"Solid", "Neon", "Classic"},
            CurrentValue = "Solid",
            Flag = "CharmsOutlineMode",
            Callback = function(Value)
                for _, espData in pairs(ESPCache) do
                    if espData.highlight then
                        if Value == "Neon" then
                            espData.highlight.OutlineTransparency = 0
                            espData.highlight.FillTransparency = 0.2
                        elseif Value == "Classic" then
                            espData.highlight.OutlineTransparency = 0.5
                        end
                    end
                end
            end
        })

        Esp:CreateSlider({
            Name = "Fill Transparency",
            Range = {0, 1},
            Increment = 0.1,
            CurrentValue = 0.5,
            Flag = "CharmsFill",
            Callback = function(Value)
                CharmsESP.FillTransparency = Value
                for _, espData in pairs(ESPCache) do
                    if espData.highlight then
                        espData.highlight.FillTransparency = Value
                    end
                end
            end
        })

        Esp:CreateSlider({
            Name = "Outline Transparency",
            Range = {0, 1},
            Increment = 0.1,
            CurrentValue = 0,
            Flag = "CharmsOutline",
            Callback = function(Value)
                CharmsESP.OutlineTransparency = Value
                for _, espData in pairs(ESPCache) do
                    if espData.highlight then
                        espData.highlight.OutlineTransparency = Value
                    end
                end
            end
        })

        Esp:CreateSection("Advanced Charms")
        Esp:CreateToggle({
            Name = "Pulse Effect",
            CurrentValue = false,
            Flag = "CharmsPulse",
            Callback = function(Value)
                CharmsESP.PulseEnabled = Value
            end
        })

        Esp:CreateSlider({
            Name = "Pulse Speed",
            Range = {1, 10},
            Increment = 1,
            CurrentValue = 5,
            Flag = "CharmsPulseSpeed",
            Callback = function(Value)
                CharmsESP.PulseSpeed = Value
            end
        })

        Esp:CreateToggle({
            Name = "Dynamic Glow",
            CurrentValue = false,
            Flag = "CharmsGlow",
            Callback = function(Value)
                CharmsESP.GlowEnabled = Value
                for _, espData in pairs(ESPCache) do
                    if espData.highlight then
                        espData.highlight.FillTransparency = Value and 0.8 or CharmsESP.FillTransparency
                    end
                end
            end
        })
        Esp:CreateSection("Mob ESP")
        
        local MobESP = {
            Color = Color3.new(1, 0, 0),
            FillTransparency = 0.5,
            OutlineTransparency = 0.5,
            TrackedMobs = {}
        }

        local function UpdateMobText(mob, humanoid, textLabel)
            local health = humanoid and humanoid.Health or 0
            local player = game.Players.LocalPlayer
            local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            
            local distance = (playerRoot and mobRoot) and (playerRoot.Position - mobRoot.Position).Magnitude or 0
            
            local healthColor = health > 50 and Color3.new(0, 1, 0) or health > 20 and Color3.new(1, 1, 0) or Color3.new(1, 0, 0)
            
            textLabel.Text = string.format("» %s «\n❤ HP: %d\n📏 Dist: %dm", 
                mob.Name:match("^[^.]+"):upper(),
                math.floor(health),
                math.floor(distance)
            )
            
            textLabel.TextColor3 = healthColor
            textLabel.TextStrokeTransparency = 0.5
            textLabel.TextXAlignment = Enum.TextXAlignment.Center
            textLabel.TextYAlignment = Enum.TextYAlignment.Center
        end

        local function ApplyMobESP(mob)
            if not mob:IsA("Model") then return end
            
            local humanoidRootPart = mob:FindFirstChild("HumanoidRootPart")
            local humanoid = mob:FindFirstChildOfClass("Humanoid")
            
            if not humanoidRootPart or not humanoid then return end

            local highlight = Instance.new("Highlight")
            highlight.Adornee = mob
            highlight.FillColor = MobESP.Color
            highlight.OutlineColor = MobESP.Color
            highlight.FillTransparency = MobESP.FillTransparency
            highlight.OutlineTransparency = MobESP.OutlineTransparency
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = humanoidRootPart

            local billboard = Instance.new("BillboardGui")
            billboard.Adornee = humanoidRootPart
            billboard.Size = UDim2.new(6, 0, 3, 0)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = humanoidRootPart
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = mob.Name:gsub("%..*", "")
            textLabel.TextColor3 = MobESP.Color
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.TextSize = 18
            textLabel.Parent = billboard
            
            local connection
            connection = game:GetService("RunService").Heartbeat:Connect(function()
                if MobESP.TrackedMobs[mob] and mob:FindFirstChild("HumanoidRootPart") then
                    if humanoid then
                        UpdateMobText(mob, humanoid, textLabel)
                    end
                else
                    connection:Disconnect()
                end
            end)
            MobESP.TrackedMobs[mob] = {highlight = highlight, billboard = billboard, connection = connection}
        end

        local function RemoveMobESP(mob)
            local espData = MobESP.TrackedMobs[mob]
            if espData then
                if espData.highlight then
                    espData.highlight:Destroy()
                end
                if espData.billboard then
                    espData.billboard:Destroy()
                end
                if espData.connection then
                    espData.connection:Disconnect()
                end
                MobESP.TrackedMobs[mob] = nil
            end
        end

        Esp:CreateToggle({
            Name = "Mob ESP",
            CurrentValue = false,
            Flag = "MobESPEnabled",
            Callback = function(Value)
                local function ProcessMobs()
                    for _, mob in ipairs(workspace.Alive:GetChildren()) do
                        if Value then
                            if not game.Players:GetPlayerFromCharacter(mob) then
                                ApplyMobESP(mob)
                            end
                        else
                            RemoveMobESP(mob)
                        end
                    end
                end
                
                ProcessMobs()
                
                if Value then
                    MobESP.ChildAddedConn = workspace.Alive.ChildAdded:Connect(function(mob)
                        repeat task.wait() until mob:FindFirstChild("HumanoidRootPart")
                        if not game.Players:GetPlayerFromCharacter(mob) then
                            ApplyMobESP(mob)
                        end
                    end)
                elseif MobESP.ChildAddedConn then
                    MobESP.ChildAddedConn:Disconnect()
                end
            end
        })

        Esp:CreateColorPicker({
            Name = "Mob Color",
            Color = Color3.new(1, 0, 0),
            Flag = "MobESPColor",
            Callback = function(Value)
                MobESP.Color = Value
                for mob, espData in pairs(MobESP.TrackedMobs) do
                    espData.highlight.FillColor = Value
                    espData.highlight.OutlineColor = Value
                    espData.billboard.TextLabel.TextColor3 = Value
                end
            end
        })

        Esp:CreateSlider({
            Name = "Mob Transparency",
            Range = {0, 1},
            Increment = 0.1,
            CurrentValue = 0.5,
            Flag = "MobESPTransparency",
            Callback = function(Value)
                MobESP.FillTransparency = Value
                MobESP.OutlineTransparency = Value
                for mob, espData in pairs(MobESP.TrackedMobs) do
                    espData.highlight.FillTransparency = Value
                    espData.highlight.OutlineTransparency = Value
                end
            end
        })
    end

    CreatePlayerESPControls()
    CreateDisplayOptions()
    CreateCharmsControls()
    SetupMobsTab()
end

local function InitializeESP()
    local function CreateESPComponents(player)
        if player == LocalPlayer then return end
        
        local success, character = pcall(function()
            return player.Character or player.CharacterAdded:Wait()
        end)
        if not success or not character then return end

        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoidRootPart or not humanoid then return end

        local head = character:FindFirstChild("Head")
        if not head then return end

        local function createInstance(className, properties)
            local instance = Instance.new(className)
            for property, value in pairs(properties) do
                instance[property] = value
            end
            return instance
        end

        local billboard = createInstance("BillboardGui", {
            Adornee = head,
            Size = UDim2.new(0, 200, 0, 50),
            StudsOffset = Vector3.new(0, 2.5, 0),
            AlwaysOnTop = true,
            ResetOnSpawn = false,
            Enabled = PlayerESP.Enabled,
            Parent = game:GetService("CoreGui")
        })

        local textLabel = createInstance("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            TextColor3 = PlayerESP.Color,
            TextSize = PlayerESP.TextSize,
            Font = PlayerESP.Font,
            Parent = billboard
        })

        local highlight = createInstance("Highlight", {
            Adornee = character,
            FillColor = CharmsESP.Color,
            OutlineColor = CharmsESP.Color,
            FillTransparency = CharmsESP.FillTransparency,
            OutlineTransparency = CharmsESP.OutlineTransparency,
            DepthMode = CharmsESP.DepthMode,
            Enabled = CharmsESP.Enabled,
            Parent = character
        })

        return {
            billboard = billboard,
            textLabel = textLabel,
            highlight = highlight,
            humanoid = humanoid,
            rootPart = humanoidRootPart
        }
    end

    local function UpdateESP(espData, player)
        return RunService.RenderStepped:Connect(function()
            if not PlayerESP.Enabled and not CharmsESP.Enabled then return end
            
            local isValid = espData.rootPart and espData.humanoid and espData.humanoid.Health > 0
            local billboardVisible = isValid and PlayerESP.Enabled
            local highlightVisible = isValid and CharmsESP.Enabled

            if espData.billboard then
                espData.billboard.Enabled = billboardVisible
            end
            if espData.highlight then
                espData.highlight.Enabled = highlightVisible
                if CharmsESP.PulseEnabled then
                    local pulse = math.sin(tick() * CharmsESP.PulseSpeed) * 0.5 + 0.5
                    espData.highlight.FillColor = Color3.new(
                        CharmsESP.Color.R * pulse,
                        CharmsESP.Color.G * pulse,
                        CharmsESP.Color.B * pulse
                    )
                    espData.highlight.OutlineColor = espData.highlight.FillColor
                end
            end

            if billboardVisible and espData.textLabel and LocalPlayer.Character then
                local rootPos = espData.rootPart.Position
                local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not localRoot then return end
                
                local distance = (localRoot.Position - rootPos).Magnitude
                local infoParts = { player.Name }
                
                if PlayerESP.ShowDistance then
                    table.insert(infoParts, string.format("[%dm]", math.floor(distance)))
                end
                if PlayerESP.ShowHealth and espData.humanoid then
                    table.insert(infoParts, string.format("[%dhp]", math.floor(espData.humanoid.Health)))
                end
                
                espData.textLabel.Text = table.concat(infoParts, " ")
                espData.textLabel.TextColor3 = PlayerESP.Color
                espData.textLabel.TextSize = PlayerESP.TextSize
            end
        end)
    end

    local function CleanupPlayer(player)
        if not ESPCache[player] then return end
        
        if ESPCache[player].connection then
            ESPCache[player].connection:Disconnect()
        end
        if ESPCache[player].billboard then
            ESPCache[player].billboard:Destroy()
        end
        if ESPCache[player].highlight then
            ESPCache[player].highlight:Destroy()
        end
        
        ESPCache[player] = nil
    end

    local function ManagePlayerESP(player)
        if player == LocalPlayer or ESPCache[player] then return end
        
        local function HandleCharacterAdded(character)
            CleanupPlayer(player)
            
            local espData = CreateESPComponents(player)
            if not espData then return end
            
            espData.connection = UpdateESP(espData, player)
            ESPCache[player] = espData

            local function HandleCharacterRemoval()
                CleanupPlayer(player)
            end

            if espData.humanoid then
                espData.humanoid.Died:Connect(HandleCharacterRemoval)
            end
            player.CharacterRemoving:Connect(HandleCharacterRemoval)
        end

        if player.Character then
            HandleCharacterAdded(player.Character)
        end
        player.CharacterAdded:Connect(HandleCharacterAdded)
    end

    local function PlayerCheckLoop()
        for _, player in ipairs(Players:GetPlayers()) do
            if not ESPCache[player] and player ~= LocalPlayer then
                task.spawn(ManagePlayerESP, player)
            end
        end
    end

    Players.PlayerAdded:Connect(ManagePlayerESP)
    Players.PlayerRemoving:Connect(CleanupPlayer)

    while true do
        PlayerCheckLoop()
        task.wait(2)
    end
end

CreateMainWindow()
SetupESPTab()
SetupTeleportTab()
InitializeESP()
