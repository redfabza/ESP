local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- State
local ESPEnabled = false
local ShowLine = false
local ShowName = false
local ShowDistance = false
local RainbowEnabled = false

local espObjects = {}

local function getCurrentRGB()
    return Color3.fromHSV((os.clock() * 0.2) % 1, 1, 1)
end

local function getDistance(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and myRoot then
        local studs = (root.Position - myRoot.Position).Magnitude
        return math.floor(studs * 0.28)
    end
    return 0
end

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WackShop"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = CoreGui

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

    -- ล้างของเก่า
    if character:FindFirstChild("PlayerHighlight") then character.PlayerHighlight:Destroy() end
    if head:FindFirstChild("NameBillboard") then head.NameBillboard:Destroy() end

    -- Highlight กรอบสีน้ำเงิน
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerHighlight"
    highlight.Adornee = character
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(0, 120, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    -- Billboard (ชื่อ + ระยะ)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameBillboard"
    billboard.Size = UDim2.new(0, 300, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    billboard.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 13
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.Font = Enum.Font.SourceSansBold
    distLabel.TextSize = 12
    distLabel.Parent = billboard

    local lineFrame = Instance.new("Frame")
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
            if lineFrame then lineFrame:Destroy() end
            espObjects[player] = nil
            return
        end

        local currentColor = RainbowEnabled and getCurrentRGB() or Color3.fromRGB(0, 120, 255)

        highlight.OutlineColor = currentColor
        highlight.Enabled = ESPEnabled
        billboard.Enabled = ESPEnabled and (ShowName or ShowDistance)
        nameLabel.Visible = ShowName
        distLabel.Visible = ShowDistance

        if ShowDistance then
            distLabel.Text = getDistance(character) .. " m"
        end

        if ShowLine and ESPEnabled then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local vp = Camera.ViewportSize
            local fromX, fromY = vp.X / 2, vp.Y
            local dx = rootPos.X - fromX
            local dy = rootPos.Y - fromY
            local length = math.sqrt(dx * dx + dy * dy)
            local angle = math.deg(math.atan2(dy, dx))

            lineFrame.Visible = onScreen and rootPos.Z > 0
            lineFrame.BackgroundColor3 = currentColor
            lineFrame.Size = UDim2.new(0, length, 0, 2)
            lineFrame.Position = UDim2.new(0, fromX + dx/2, 0, fromY + dy/2)
            lineFrame.Rotation = angle
        else
            lineFrame.Visible = false
        end
    end)
end

-- Setup Players
local function setupPlayer(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        applyESP(player, char)
    end)
    if player.Character then
        task.wait(0.5)
        applyESP(player, player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)

-- ==================== GUI ====================
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 255)
frame.AnchorPoint = Vector2.new(1, 0.5)
frame.Position = UDim2.new(1, -20, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BorderSizePixel = 0
frame.ZIndex = 10
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

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
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(0, 120, 255)
titleLabel.ZIndex = 10
titleLabel.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("ImageButton")
closeBtn.Size = UDim2.fromOffset(24, 24)
closeBtn.Position = UDim2.new(1, -32, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(240, 70, 70)
closeBtn.Image = "rbxassetid://10747384394"
closeBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.ZIndex = 11
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    print("⛔ WackShop ESP has been shut down.")
end)

-- ปุ่ม W ลอย
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 44, 0, 44)
toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
toggleBtn.Position = UDim2.new(0, 20, 0.5, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
toggleBtn.Text = "W"
toggleBtn.TextSize = 20
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.fromRGB(0, 120, 255)
toggleBtn.ZIndex = 20
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Drag functions (ย่อให้เรียบร้อย)
-- (ส่วน Drag หน้าต่างและปุ่ม W ฉันเว้นไว้เพื่อความกระชับ ถ้าต้องการเต็มให้บอก)

-- Toggle Buttons
local function createToggle(label, y, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 155, 0, 30)
    btn.Position = UDim2.new(0, 12, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(30, 160, 90) or Color3.fromRGB(160, 45, 45)
    btn.Text = label .. (default and "  ✅" or "  ❌")
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.ZIndex = 10
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(30, 160, 90) or Color3.fromRGB(160, 45, 45)
        btn.Text = label .. (state and "  ✅" or "  ❌")
        callback(state)
    end)
end

createToggle("ESP",          45,  false, function(s) ESPEnabled = s end)
createToggle("เส้นนำทาง",   80,  false, function(s) ShowLine = s end)
createToggle("ชื่อผู้เล่น", 115, false, function(s) ShowName = s end)
createToggle("ระยะห่าง",    150, false, function(s) ShowDistance = s end)
createToggle("โหมด RGB",    185, false, function(s) RainbowEnabled = s end)

print("✅ WackShop ESP Loaded!")
