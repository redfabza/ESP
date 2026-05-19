local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- State
local ESPEnabled = true
local ShowLine = true
local ShowName = true
local ShowDistance = true

local espObjects = {}

local function getDistance(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and myRoot then
        return math.floor((root.Position - myRoot.Position).Magnitude)
    end
    return 0
end

-- ScreenGui หลัก
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WackShop"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = CoreGui

-- Canvas เส้น
local lineCanvas = Instance.new("Frame")
lineCanvas.Name = "LineCanvas"
lineCanvas.Size = UDim2.new(1, 0, 1, 0)
lineCanvas.BackgroundTransparency = 1
lineCanvas.BorderSizePixel = 0
lineCanvas.ZIndex = 1
lineCanvas.Parent = screenGui

local function applyESP(player, character)
    if not character or player == LocalPlayer then return end

    local head = character:WaitForChild("Head", 5)
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not head or not root then return end

    if character:FindFirstChild("PlayerHighlight") then character.PlayerHighlight:Destroy() end
    if head:FindFirstChild("NameBillboard") then head.NameBillboard:Destroy() end

    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerHighlight"
    highlight.Adornee = character
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameBillboard"
    billboard.Size = UDim2.new(0, 300, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = math.huge
    billboard.Adornee = head
    billboard.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 13
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.Font = Enum.Font.SourceSansBold
    distLabel.TextSize = 12
    distLabel.Parent = billboard

    local lineFrame = Instance.new("Frame")
    lineFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    lineFrame.BorderSizePixel = 0
    lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    lineFrame.Size = UDim2.new(0, 2, 0, 2)
    lineFrame.ZIndex = 2
    lineFrame.Visible = false
    lineFrame.Parent = lineCanvas

    espObjects[player] = {
        highlight = highlight,
        billboard = billboard,
        nameLabel = nameLabel,
        distLabel = distLabel,
        lineFrame = lineFrame,
        character = character,
    }

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not character or not character.Parent then
            conn:Disconnect()
            lineFrame:Destroy()
            espObjects[player] = nil
            return
        end

        highlight.Enabled = ESPEnabled
        billboard.Enabled = ESPEnabled and (ShowName or ShowDistance)
        nameLabel.Visible = ShowName
        distLabel.Visible = ShowDistance

        if ShowDistance then
            distLabel.Text = getDistance(character) .. " studs"
        end

        if ShowLine and ESPEnabled and root and root.Parent then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local vp = Camera.ViewportSize
            local fromX = vp.X / 2
            local fromY = vp.Y
            local toX = rootPos.X
            local toY = rootPos.Y
            local dx = toX - fromX
            local dy = toY - fromY
            local length = math.sqrt(dx * dx + dy * dy)
            local angle = math.deg(math.atan2(dy, dx))

            lineFrame.Visible = onScreen and rootPos.Z > 0
            lineFrame.Size = UDim2.new(0, length, 0, 2)
            lineFrame.Position = UDim2.new(0, fromX + dx / 2, 0, fromY + dy / 2)
            lineFrame.Rotation = angle
        else
            lineFrame.Visible = false
        end
    end)
end

local function cleanupPlayer(player)
    local obj = espObjects[player]
    if obj then
        if obj.lineFrame then obj.lineFrame:Destroy() end
        espObjects[player] = nil
    end
end

local function setupPlayer(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        applyESP(player, character)
    end)
    if player.Character then
        applyESP(player, player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

-- ==========================================
-- GUI
-- ==========================================
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 220)
frame.Position = UDim2.new(0, 20, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BorderSizePixel = 0
frame.ZIndex = 10
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = Color3.fromRGB(255, 255, 0)
frameStroke.Thickness = 1.5

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 10
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ WackShop ESP"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 10
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 11
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 40, 0, 40)
toggleBtn.Position = UDim2.new(0, 20, 0.5, -20)
toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
toggleBtn.Text = "W"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 0)
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.AutoButtonColor = false
toggleBtn.Visible = false
toggleBtn.ZIndex = 10
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
local tStroke = Instance.new("UIStroke", toggleBtn)
tStroke.Color = Color3.fromRGB(255, 255, 0)
tStroke.Thickness = 1.5

closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    toggleBtn.Visible = true
end)

toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    toggleBtn.Visible = false
end)

-- Draggable
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local function createToggleBtn(labelText, yPos, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 155, 0, 30)
    btn.Position = UDim2.new(0, 12, 0, yPos)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.ZIndex = 10
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = defaultState
    local function updateStyle()
        btn.BackgroundColor3 = state and Color3.fromRGB(30, 160, 90) or Color3.fromRGB(160, 45, 45)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = labelText .. (state and "  ✅" or "  ❌")
    end
    updateStyle()

    btn.MouseButton1Click:Connect(function()
        state = not state
        updateStyle()
        callback(state)
    end)
end

createToggleBtn("ESP",          45,  true, function(s) ESPEnabled = s end)
createToggleBtn("เส้นนำทาง",   83,  true, function(s) ShowLine = s end)
createToggleBtn("ชื่อผู้เล่น", 118, true, function(s) ShowName = s end)
createToggleBtn("ระยะห่าง",    153, true, function(s) ShowDistance = s end)