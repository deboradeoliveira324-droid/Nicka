local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")

local function SendChatMessage(message)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local textChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if textChannel then
            textChannel:SendAsync(message)
        end
    else
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
    end
end

local player = Players.LocalPlayer

local function GetNearestPlayerInFront(targetPlayer, maxAngle)
    maxAngle = maxAngle or 60

    if not targetPlayer.Character then return nil end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return nil end

    local targetLook = targetHRP.CFrame.LookVector

    local closest = nil
    local closestDist = math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p ~= targetPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local difference = hrp.Position - targetHRP.Position

                if difference.Magnitude > 0 then
                    local vec = difference.Unit
                    local dot = math.clamp(targetLook:Dot(vec), -1, 1)
                    local angle = math.deg(math.acos(dot))

                    if angle <= maxAngle then
                        local dist = difference.Magnitude

                        if dist < closestDist then
                            closestDist = dist
                            closest = hrp
                        end
                    end
                end
            end
        end
    end

    return closest
end

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")

local standDistance = 3
local sideOffset = 2
local heightOffset = 2
local followSpeed = 0.30
local flingDuration = 3
local followDuration = 0.9

local punchSoundId = "rbxassetid://104126666677335"
local heavyPunchSoundId = "rbxassetid://6164853733"
local blockSoundId = "rbxassetid://71692147895623"

local summonSoundIds = {
    "rbxassetid://92122894424153",
    "rbxassetid://113205846415062"
}

local blockSound = nil

local function startBlockSound()
    if blockSound then
        return
    end

    blockSound = Instance.new("Sound")
    blockSound.SoundId = blockSoundId
    blockSound.Volume = 1
    blockSound.Looped = true
    blockSound.Parent = humanoidRootPart
    blockSound:Play()
end

local function stopBlockSound()
    if blockSound then
        blockSound:Stop()
        blockSound:Destroy()
        blockSound = nil
    end
end

----------------------------------------------------------------
-- JOJO STAND CONTROLLER GUI
----------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StandControllerGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Colors
local JOJO_BLACK = Color3.fromRGB(12, 8, 18)
local JOJO_PURPLE = Color3.fromRGB(80, 20, 120)
local JOJO_DARK_PURPLE = Color3.fromRGB(35, 12, 55)
local JOJO_GOLD = Color3.fromRGB(255, 190, 55)
local JOJO_WHITE = Color3.fromRGB(245, 240, 255)
local JOJO_RED = Color3.fromRGB(180, 35, 55)

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 310)
mainFrame.Position = UDim2.new(0.05, 0, 0.5, -155)
mainFrame.BackgroundColor3 = JOJO_BLACK
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local border = Instance.new("UIStroke")
border.Color = JOJO_PURPLE
border.Thickness = 3
border.Parent = mainFrame

-- Gold inner outline
local innerBorder = Instance.new("UIStroke")
innerBorder.Color = JOJO_GOLD
innerBorder.Thickness = 1
innerBorder.Transparency = 0.25
innerBorder.Parent = mainFrame

-- Top bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 6)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = JOJO_PURPLE
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

-- Side bar
local sideBar = Instance.new("Frame")
sideBar.Size = UDim2.new(0, 4, 1, -6)
sideBar.Position = UDim2.new(0, 0, 0, 6)
sideBar.BackgroundColor3 = JOJO_GOLD
sideBar.BorderSizePixel = 0
sideBar.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -55, 0, 30)
title.Position = UDim2.new(0, 15, 0, 9)
title.BackgroundTransparency = 1
title.Text = "「 STAND 」"
title.TextColor3 = JOJO_GOLD
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 18)
subtitle.Position = UDim2.new(0, 15, 0, 35)
subtitle.BackgroundTransparency = 1
subtitle.Text = "STAR PLATINUM • CONTROL"
subtitle.TextColor3 = JOJO_WHITE
subtitle.TextTransparency = 0.2
subtitle.Font = Enum.Font.GothamBold
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = mainFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 27)
closeBtn.Position = UDim2.new(1, -39, 0, 10)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 14
closeBtn.TextColor3 = JOJO_WHITE
closeBtn.BackgroundColor3 = JOJO_DARK_PURPLE
closeBtn.BorderSizePixel = 0
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 7)
closeCorner.Parent = closeBtn

local closeStroke = Instance.new("UIStroke")
closeStroke.Color = JOJO_RED
closeStroke.Thickness = 1.5
closeStroke.Parent = closeBtn

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -28, 0, 2)
divider.Position = UDim2.new(0, 14, 0, 59)
divider.BackgroundColor3 = JOJO_PURPLE
divider.BorderSizePixel = 0
divider.Parent = mainFrame

-- GUI toggle
local guiToggle = Instance.new("TextButton")
guiToggle.Size = UDim2.new(0, 58, 0, 30)
guiToggle.Position = UDim2.new(0.5, -29, 1, -42)
guiToggle.Text = "「 GUI 」"
guiToggle.Font = Enum.Font.GothamBlack
guiToggle.TextSize = 12
guiToggle.TextColor3 = JOJO_GOLD
guiToggle.BackgroundColor3 = JOJO_BLACK
guiToggle.BorderSizePixel = 0
guiToggle.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = guiToggle

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = JOJO_PURPLE
toggleStroke.Thickness = 2
toggleStroke.Parent = guiToggle

local guiVisible = true

guiToggle.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    mainFrame.Visible = guiVisible
end)

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    guiVisible = false
end)

-- Button creator
local function makeButton(text, y)
    local b = Instance.new("TextButton")

    b.Size = UDim2.new(0.78, 0, 0, 36)
    b.Position = UDim2.new(0.11, 0, 0, y)

    b.Text = "「 " .. text .. " 」"
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 13
    b.TextColor3 = JOJO_WHITE

    b.BackgroundColor3 = JOJO_DARK_PURPLE
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = b

    local stroke = Instance.new("UIStroke")
    stroke.Color = JOJO_PURPLE
    stroke.Thickness = 2
    stroke.Parent = b

    b.MouseEnter:Connect(function()
        b.BackgroundColor3 = JOJO_PURPLE
        b.TextColor3 = JOJO_GOLD
        stroke.Color = JOJO_GOLD
    end)

    b.MouseLeave:Connect(function()
        b.BackgroundColor3 = JOJO_DARK_PURPLE
        b.TextColor3 = JOJO_WHITE
        stroke.Color = JOJO_PURPLE
    end)

    return b
end

local standBtn = makeButton("STAND: OFF", 68)

local targetBox = Instance.new("TextBox")
targetBox.Size = UDim2.new(0.78, 0, 0, 36)
targetBox.Position = UDim2.new(0.11, 0, 0, 112)
targetBox.PlaceholderText = "ENTER TARGET NAME"
targetBox.ClearTextOnFocus = false
targetBox.Font = Enum.Font.GothamBold
targetBox.TextSize = 13
targetBox.BackgroundColor3 = JOJO_DARK_PURPLE
targetBox.TextColor3 = JOJO_WHITE
targetBox.PlaceholderColor3 = Color3.fromRGB(150, 130, 170)
targetBox.BorderSizePixel = 0
targetBox.Parent = mainFrame

local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 9)
targetCorner.Parent = targetBox

local targetStroke = Instance.new("UIStroke")
targetStroke.Color = JOJO_PURPLE
targetStroke.Thickness = 2
targetStroke.Parent = targetBox

targetBox.Focused:Connect(function()
    targetStroke.Color = JOJO_GOLD
end)

targetBox.FocusLost:Connect(function()
    targetStroke.Color = JOJO_PURPLE
end)

local punchBtn = makeButton("MUDA MUDA!", 154)

local function makeSlider(labelText, y, default, min, max, callback)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.72, 0, 0, 16)
    lbl.Position = UDim2.new(0.14, 0, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText .. ": " .. tostring(default)
    lbl.TextColor3 = JOJO_GOLD
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.72, 0, 0, 20)
    box.Position = UDim2.new(0.14, 0, 0, y + 16)
    box.Text = tostring(default)
    box.ClearTextOnFocus = false
    box.BackgroundColor3 = JOJO_DARK_PURPLE
    box.TextColor3 = JOJO_WHITE
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.BorderSizePixel = 0
    box.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box

    local stroke = Instance.new("UIStroke")
    stroke.Color = JOJO_PURPLE
    stroke.Thickness = 1
    stroke.Parent = box

    box.Focused:Connect(function()
        stroke.Color = JOJO_GOLD
    end)

    box.FocusLost:Connect(function()
        stroke.Color = JOJO_PURPLE

        local num = tonumber(box.Text)

        if num then
            num = math.clamp(num, min, max)
            box.Text = tostring(num)
            lbl.Text = labelText .. ": " .. tostring(num)
            callback(num)
        else
            box.Text = tostring(default)
        end
    end)

    return box, lbl
end

local posBox, posLabel = makeSlider(
    "POSITION",
    192,
    standDistance,
    0,
    20,
    function(v)
        standDistance = v
    end
)

local offBox, offLabel = makeSlider(
    "OFFSET",
    220,
    sideOffset,
    -10,
    10,
    function(v)
        sideOffset = v
    end
)

local heightBox, heightLabel = makeSlider(
    "FLOAT HEIGHT",
    248,
    heightOffset,
    0,
    10,
    function(v)
        heightOffset = v
    end
)

-- Dragging
do
    local dragging = false
    local dragStart = Vector2.new()
    local startPos = mainFrame.Position

    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            -- Don't drag when clicking controls
            if input.Target == closeBtn
                or input.Target == guiToggle then
                return
            end

            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local delta = mousePos - dragStart

            local newX = math.clamp(
                startPos.X.Offset + delta.X,
                0,
                workspace.CurrentCamera.ViewportSize.X - mainFrame.Size.X.Offset
            )

            local newY = math.clamp(
                startPos.Y.Offset + delta.Y,
                0,
                workspace.CurrentCamera.ViewportSize.Y - mainFrame.Size.Y.Offset
            )

            mainFrame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end

----------------------------------------------------------------
-- EVERYTHING BELOW IS YOUR ORIGINAL SCRIPT
----------------------------------------------------------------

local function findTargetByName(namePart)
    if not namePart or namePart == "" then
        return nil
    end

    namePart = namePart:lower()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Name:lower():find(namePart) then
            return p
        end
    end

    return nil
end

local standOn = false
local bp, gyro = nil, nil
local floatTime = 0

local vanished = false
local savedCharacterCFrame = nil
local savedCameraSubject = nil

local VANISH_HEIGHT = 1000

local BLOCK_DISTANCE = 3
local blocking = false

local function enableStand()
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    if not bp then
        bp = Instance.new("BodyPosition")
        bp.MaxForce = Vector3.new(4e5, 4e5, 4e5)
        bp.P = 2000
        bp.D = 50
        bp.Position = humanoidRootPart.Position
        bp.Parent = humanoidRootPart
    end

    if not gyro then
        gyro = Instance.new("BodyGyro")
        gyro.P = 2000
        gyro.D = 50
        gyro.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
        gyro.CFrame = humanoidRootPart.CFrame
        gyro.Parent = humanoidRootPart
    end
end

local function disableStand()
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end

    if bp then
        bp:Destroy()
        bp = nil
    end

    if gyro then
        gyro:Destroy()
        gyro = nil
    end
end

standBtn.MouseButton1Click:Connect(function()
    standOn = not standOn

    standBtn.Text = standOn
        and "「 STAND: ON 」"
        or "「 STAND: OFF 」"

    if standOn then
        enableStand()

        local t = findTargetByName(targetBox.Text)

        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            for _, id in ipairs(summonSoundIds) do
                local summon = Instance.new("Sound", humanoidRootPart)
                summon.SoundId = id
                summon.Volume = 1
                summon:Play()
                Debris:AddItem(summon, 5)
            end
        end
        
        )
    else
        blocking = false
        disableStand()
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if standOn and bp and gyro and targetBox.Text ~= "" then

        if vanished and savedCharacterCFrame then
            bp.Position = Vector3.new(
                savedCharacterCFrame.Position.X,
                VANISH_HEIGHT,
                savedCharacterCFrame.Position.Z
            )

            gyro.CFrame = CFrame.new(
                bp.Position,
                bp.Position + savedCharacterCFrame.LookVector
            )

            return
        end

        floatTime += dt * 2
        local floatOffset = math.sin(floatTime) * 0.5

        local t = findTargetByName(targetBox.Text)

        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = t.Character.HumanoidRootPart
            local tcf = targetHRP.CFrame
            local desiredPos

            if blocking then
                desiredPos =
                    tcf.Position
                    + tcf.LookVector * BLOCK_DISTANCE
                    + Vector3.new(0, heightOffset, 0)
            else
                desiredPos =
                    tcf.Position
                    - tcf.LookVector * standDistance
                    + tcf.RightVector * sideOffset
                    + Vector3.new(0, heightOffset + floatOffset, 0)
            end

            bp.Position = bp.Position:Lerp(
                desiredPos,
                math.clamp(followSpeed, 0.01, 1)
            )

            gyro.CFrame = CFrame.new(
                humanoidRootPart.Position,
                humanoidRootPart.Position + tcf.LookVector
            )
        end
    end
end)

local function runPastebinStyleFling(duration)
    local start = tick()
    local movel = 0.1

    while tick() - start < duration do
        RunService.Heartbeat:Wait()

        local c = player.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")

        if hrp then
            local vel = hrp.Velocity

            hrp.Velocity =
                vel * 10000
                + Vector3.new(0, 10000, 0)

            RunService.RenderStepped:Wait()

            hrp.Velocity = vel

            RunService.Stepped:Wait()

            hrp.Velocity =
                vel
                + Vector3.new(0, movel, 0)

            movel = -movel
        end
    end
end

local function punchTarget()
    local punchAnim = Instance.new("Animation")
    punchAnim.AnimationId = "rbxassetid://86464152593138"

    local punchTrack = humanoid:LoadAnimation(punchAnim)
    punchTrack.Priority = Enum.AnimationPriority.Action
    punchTrack:Play()

    task.delay(1, function()
        if punchTrack then
            punchTrack:Stop()
            punchTrack:Destroy()
        end
    end)

    local targetPlayer = findTargetByName(targetBox.Text)

    if not targetPlayer or not targetPlayer.Character then
        return
    end

    local targetHRP =
        targetPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not targetHRP then
        return
    end


    local nearest = GetNearestPlayerInFront(targetPlayer)

    if not nearest then
        return
    end

    local wasStandOn = standOn

    if wasStandOn then
        standOn = false
        standBtn.Text = "「 STAND: OFF 」"
        disableStand()
    end

    humanoidRootPart.CFrame =
        CFrame.new(nearest.Position + Vector3.new(0, 3, 0))

    local tempBP = Instance.new("BodyPosition")
    tempBP.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    tempBP.P = 4000
    tempBP.D = 100
    tempBP.Position = nearest.Position
    tempBP.Parent = humanoidRootPart

    local tempGyro = Instance.new("BodyGyro")
    tempGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    tempGyro.P = 4000
    tempGyro.D = 100
    tempGyro.CFrame = humanoidRootPart.CFrame
    tempGyro.Parent = humanoidRootPart

    local followConnection

    followConnection = RunService.RenderStepped:Connect(function()
        if not (
            tempBP
            and tempGyro
            and nearest
            and nearest.Parent
        ) then
            return
        end

        tempBP.Position = nearest.Position

        local lookVec = nearest.CFrame.LookVector

        tempGyro.CFrame =
            CFrame.new(
                humanoidRootPart.Position,
                humanoidRootPart.Position + lookVec
            )
    end)

    task.delay(followDuration, function()
        if followConnection then
            followConnection:Disconnect()
            followConnection = nil
        end

        if tempBP then
            tempBP:Destroy()
            tempBP = nil
        end

        if tempGyro then
            tempGyro:Destroy()
            tempGyro = nil
        end
    end)

    local effect = Instance.new("ColorCorrectionEffect")
    effect.Saturation = -1
    effect.Parent = game.Lighting

    local s = Instance.new("Sound", humanoidRootPart)
    s.SoundId = punchSoundId
    s.Volume = 1
    s:Play()
    Debris:AddItem(s, 6)

    task.delay(0.2, function()
        local s2 = Instance.new("Sound", humanoidRootPart)
        s2.SoundId = heavyPunchSoundId
        s2.Volume = 1
        s2:Play()
        Debris:AddItem(s5, 0)
    end)

    task.spawn(function()
        runPastebinStyleFling(flingDuration)
    end)

    task.delay(flingDuration + 0.40, function()
        if followConnection then
            followConnection:Disconnect()
            followConnection = nil
        end

        if tempBP then
            tempBP:Destroy()
            tempBP = nil
        end

        if tempGyro then
            tempGyro:Destroy()
            tempGyro = nil
        end

        if effect and effect.Parent then
            effect:Destroy()
        end

        if wasStandOn then
            standOn = true
            standBtn.Text = "「 STAND: ON 」"
            enableStand()

            if bp then
                bp.Position = humanoidRootPart.Position
            end
        end
    end)
end

punchBtn.MouseButton1Click:Connect(punchTarget)

local function onPlayerChatted(otherPlayer, message)
    local targetName = targetBox.Text

    if not targetName or targetName == "" then
        return
    end

    local lowerMessage = message:lower()

    local targetMatches =
        otherPlayer.Name:lower():find(targetName:lower())

    if not targetMatches then
        return
    end

    if standOn and lowerMessage:find("barrage") then
        punchTarget()
        return
    end

    if lowerMessage:find("block")
        and standOn
        and not vanished
        and not blocking then

        blocking = true
        startBlockSound()
        return
    end

    if lowerMessage:find("unblock")
        and standOn
        and blocking then

        blocking = false
        stopBlockSound()
        return
    end

    if lowerMessage:find("vanish")
        and standOn
        and not vanished then

        vanished = true

        savedCharacterCFrame =
            humanoidRootPart.CFrame

        local camera = workspace.CurrentCamera
        savedCameraSubject = camera.CameraSubject

        humanoidRootPart.CFrame =
            CFrame.new(
                humanoidRootPart.Position.X,
                VANISH_HEIGHT,
                humanoidRootPart.Position.Z
            )

        local target =
            findTargetByName(targetBox.Text)

        if target and target.Character then
            local targetHumanoid =
                target.Character:FindFirstChildOfClass("Humanoid")

            if targetHumanoid then
                camera.CameraSubject = targetHumanoid
            end
        end

        return
    end

    if lowerMessage:find("summon") then

        if blocking then
            blocking = false
        end

        if vanished then
            vanished = false

            if savedCharacterCFrame
                and humanoidRootPart
                and humanoidRootPart.Parent then

                humanoidRootPart.CFrame =
                    savedCharacterCFrame
            end

            local camera = workspace.CurrentCamera

            if humanoid then
                camera.CameraSubject = humanoid
            elseif savedCameraSubject then
                camera.CameraSubject = savedCameraSubject
            end

            savedCharacterCFrame = nil
            savedCameraSubject = nil

            SendChatMessage("zawarudo!")
            return
        end

        standOn = not standOn

        standBtn.Text =
            standOn
            and "「 STAND: ON 」"
            or "「 STAND: OFF 」"

        if standOn then
            enableStand()

            local t =
                findTargetByName(targetBox.Text)

            if t
                and t.Character
                and t.Character:FindFirstChild("HumanoidRootPart") then

                for _, id in ipairs(summonSoundIds) do
                    local summon =
                        Instance.new("Sound", humanoidRootPart)

                    summon.SoundId = id
                    summon.Volume = 1
                    summon:Play()

                    Debris:AddItem(summon, 5)
                end
            end

        else
            disableStand()
        end
    end
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= player then
        p.Chatted:Connect(function(msg)
            onPlayerChatted(p, msg)
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= player then
        p.Chatted:Connect(function(msg)
            onPlayerChatted(p, msg)
        end)
    end
end)

player.CharacterAdded:Connect(function(char)
    character = char

    humanoidRootPart =
        character:WaitForChild("HumanoidRootPart")

    humanoid =
        character:FindFirstChildOfClass("Humanoid")
        or character:WaitForChild("Humanoid")

    if vanished then
        vanished = false
        savedCharacterCFrame = nil
        savedCameraSubject = nil

        local camera = workspace.CurrentCamera
        camera.CameraSubject = humanoid
    end

    disableStand()

    standOn = false
    blocking = false

    standBtn.Text = "「 STAND: OFF 」"
end)

local levitateIdle = Instance.new("Animation")
levitateIdle.AnimationId = "rbxassetid://118107321973443"

local moveAnim = Instance.new("Animation")
moveAnim.AnimationId = "rbxassetid://137778422568555"

local levitateTrack
local moveTrack

local function playLevitateIdle()
    if humanoid and not levitateTrack then
        levitateTrack =
            humanoid:LoadAnimation(levitateIdle)

        levitateTrack.Priority =
            Enum.AnimationPriority.Idle

        levitateTrack.Looped = true
        levitateTrack:Play()
    end
end

local function stopLevitateIdle()
    if levitateTrack then
        levitateTrack:Stop()
        levitateTrack:Destroy()
        levitateTrack = nil
    end
end

local function playMoveAnim()
    if humanoid and not moveTrack then
        moveTrack =
            humanoid:LoadAnimation(moveAnim)

        moveTrack.Priority =
            Enum.AnimationPriority.Movement

        moveTrack.Looped = true
        moveTrack:Play()
    end
end

local function stopMoveAnim()
    if moveTrack then
        moveTrack:Stop()
        moveTrack:Destroy()
        moveTrack = nil
    end
end

RunService.RenderStepped:Connect(function(dt)
    if standOn then
        local target =
            findTargetByName(targetBox.Text)

        if target
            and target.Character
            and target.Character:FindFirstChild("HumanoidRootPart") then

            local targetHumanoid =
                target.Character:FindFirstChildOfClass("Humanoid")

            if targetHumanoid then
                if targetHumanoid.MoveDirection.Magnitude > 0 then
                    stopLevitateIdle()
                    playMoveAnim()
                else
                    stopMoveAnim()
                    playLevitateIdle()
                end
            end
        else
            stopMoveAnim()
            playLevitateIdle()
        end
    else
        stopLevitateIdle()
        stopMoveAnim()
    end
end)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local noclip = false

local function setNoclip(enabled)
	noclip = enabled
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.N then
		setNoclip(not noclip)
		print("Noclip:", noclip and "ON" or "OFF")
	end
end)

RunService.Stepped:Connect(function()
	if not noclip then return end

	local character = player.Character
	if not character then return end

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end)