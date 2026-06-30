--[[
    ASO-TELEPORT v1.0 – VIP EDITION
    Bản quyền thuộc về CHỈ HUY ASO và Vertex.
    Tính năng:
    - Teleport tức thời đến các vị trí đã cấu hình (Lobby, Phòng đấu, Cổng đặc biệt).
    - Giao diện đồ họa tối giản, kéo thả, ẩn/hiện bằng phím tắt (F9).
    - Tự động phát hiện cổng và kích hoạt mà không cần tương tác thủ công.
    - Chế độ "Stealth" (ngụy trang) – thêm độ trễ ngẫu nhiên và mô phỏng hành vi di chuyển.
    - Lưu vị trí yêu thích (Favorite Locations) để teleport nhanh.
    - Tương thích với Delta và các executor phổ biến.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

-- ============================================
-- CẤU HÌNH TELEPORT
-- ============================================
local Config = {
    -- Danh sách các điểm đến
    Destinations = {
        Lobby = { X = 0, Y = 10, Z = 0 },        -- Thay bằng tọa độ thực tế
        BattleC1 = { X = 100, Y = 10, Z = 50 },
        BattleC5 = { X = 200, Y = 10, Z = 100 },
        BattleC20 = { X = 300, Y = 10, Z = 150 },
        BattleC50 = { X = 400, Y = 10, Z = 200 },
        AncientPortal = { X = 500, Y = 10, Z = 250 },
        AFKZone = { X = -100, Y = 10, Z = -50 },
    },
    -- Chế độ ngụy trang
    StealthMode = true,
    RandomDelayMin = 0.1,
    RandomDelayMax = 0.3,
    -- Thời gian chờ tối đa để xác nhận teleport
    ConfirmTimeout = 3.0,
}

-- ============================================
-- BIẾN TOÀN CỤC
-- ============================================
local State = {
    IsTeleporting = false,
    CurrentPosition = "Lobby",
    Favorite = "Lobby",
    MenuVisible = true,
}

-- ============================================
-- HÀM HỖ TRỢ
-- ============================================
local function getCharacterRoot()
    local char = LocalPlayer.Character
    if not char or not char.Parent then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getPositionName(pos)
    for name, data in pairs(Config.Destinations) do
        if data.X == pos.X and data.Y == pos.Y and data.Z == pos.Z then
            return name
        end
    end
    return nil
end

local function isInPosition(pos)
    local root = getCharacterRoot()
    if not root then return false end
    local current = root.Position
    local distance = (current - Vector3.new(pos.X, pos.Y, pos.Z)).Magnitude
    return distance < 3.0 -- Ngưỡng xác nhận
end

local function safeTeleport(destination)
    local destData = Config.Destinations[destination]
    if not destData then
        warn("[ASO] Điểm đến không tồn tại: " .. destination)
        return false
    end

    local root = getCharacterRoot()
    if not root then
        warn("[ASO] Không tìm thấy HumanoidRootPart.")
        return false
    end

    -- Xác định tọa độ đích
    local targetCF = CFrame.new(destData.X, destData.Y, destData.Z)

    -- === Chế độ ngụy trang ===
    if Config.StealthMode then
        -- Di chuyển từ từ (mô phỏng chạy bộ) để tránh bị phát hiện
        local startPos = root.Position
        local steps = math.random(5, 10)
        for i = 1, steps do
            local t = i / steps
            local interpolated = startPos:Lerp(Vector3.new(destData.X, destData.Y, destData.Z), t)
            root.CFrame = CFrame.new(interpolated)
            local delay = Config.RandomDelayMin + math.random() * (Config.RandomDelayMax - Config.RandomDelayMin)
            task.wait(delay)
        end
    else
        -- Teleport tức thời
        root.CFrame = targetCF
    end

    -- Xác nhận đã đến nơi
    local startTime = tick()
    while not isInPosition(destData) and tick() - startTime < Config.ConfirmTimeout do
        task.wait(0.1)
        root.CFrame = targetCF
    end

    if isInPosition(destData) then
        print("[ASO] Đã teleport thành công đến " .. destination)
        State.CurrentPosition = destination
        return true
    else
        warn("[ASO] Teleport thất bại. Có thể bị chặn hoặc tọa độ không hợp lệ.")
        return false
    end
end

-- ============================================
-- TỰ ĐỘNG PHÁT HIỆN CỔNG (PORTAL)
-- ============================================
local function findAndActivatePortal(portalName)
    local gui = LocalPlayer.PlayerGui
    -- Tìm kiếm các cổng dựa trên tên hoặc văn bản
    for _, child in ipairs(gui:GetDescendants()) do
        if child:IsA("TextButton") and child.Visible and child.Text then
            if child.Text:find(portalName) or child.Text:find("Portal") then
                local pos = child.AbsolutePosition
                local size = child.AbsoluteSize
                if pos and size then
                    local x = pos.X + size.X / 2
                    local y = pos.Y + size.Y / 2
                    -- Giả lập click
                    VirtualInputManager:SendMouseButtonEvent(Vector2.new(x, y), 1, true, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(Vector2.new(x, y), 1, false, 0)
                    print("[ASO] Đã kích hoạt cổng: " .. portalName)
                    return true
                end
            end
        end
    end
    return false
end

-- ============================================
-- TẠO GIAO DIỆN MENU
-- ============================================
local function createTeleportMenu()
    local oldMenu = LocalPlayer.PlayerGui:FindFirstChild("ASO_TeleportVIP")
    if oldMenu then oldMenu:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ASO_TeleportVIP"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer.PlayerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 320)
    mainFrame.Position = UDim2.new(0.5, -140, 0.4, -160)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10,10,25)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(255,70,70)
    mainFrame.Draggable = true
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Tiêu đề
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.BackgroundTransparency = 1
    title.Text = "⚡ ASO VIP TELEPORT"
    title.TextColor3 = Color3.fromRGB(255,100,100)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = mainFrame

    -- Nút ẩn/hiện
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 25)
    toggleBtn.Position = UDim2.new(1, -55, 0, 5)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
    toggleBtn.Text = "▼"
    toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.Parent = mainFrame

    toggleBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
        toggleBtn.Text = mainFrame.Visible and "▼" or "▲"
    end)

    -- Danh sách điểm đến
    local y = 45
    local btnList = {}
    for name, data in pairs(Config.Destinations) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 32)
        btn.Position = UDim2.new(0.05, 0, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(30,30,50)
        btn.Text = "📍 " .. name
        btn.TextColor3 = Color3.fromRGB(220,220,240)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.Parent = mainFrame
        btnList[name] = btn

        btn.MouseButton1Click:Connect(function()
            if State.IsTeleporting then
                print("[ASO] Đang teleport, vui lòng đợi.")
                return
            end
            State.IsTeleporting = true
            task.spawn(function()
                safeTeleport(name)
                State.IsTeleporting = false
            end)
        end)

        y = y + 36
    end

    -- Nút "Yêu thích" (Favorite)
    local favBtn = Instance.new("TextButton")
    favBtn.Size = UDim2.new(0.4, 0, 0, 30)
    favBtn.Position = UDim2.new(0.05, 0, 0, y + 10)
    favBtn.BackgroundColor3 = Color3.fromRGB(60,60,100)
    favBtn.Text = "⭐ Đặt yêu thích"
    favBtn.TextColor3 = Color3.fromRGB(255,215,0)
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextSize = 13
    favBtn.Parent = mainFrame

    local gotoFavBtn = Instance.new("TextButton")
    gotoFavBtn.Size = UDim2.new(0.4, 0, 0, 30)
    gotoFavBtn.Position = UDim2.new(0.55, 0, 0, y + 10)
    gotoFavBtn.BackgroundColor3 = Color3.fromRGB(50,200,80)
    gotoFavBtn.Text = "🚀 Teleport yêu thích"
    gotoFavBtn.TextColor3 = Color3.fromRGB(255,255,255)
    gotoFavBtn.Font = Enum.Font.GothamBold
    gotoFavBtn.TextSize = 13
    gotoFavBtn.Parent = mainFrame

    favBtn.MouseButton1Click:Connect(function()
        State.Favorite = State.CurrentPosition or "Lobby"
        print("[ASO] Đã đặt yêu thích: " .. State.Favorite)
    end)

    gotoFavBtn.MouseButton1Click:Connect(function()
        if State.IsTeleporting then return end
        State.IsTeleporting = true
        task.spawn(function()
            safeTeleport(State.Favorite)
            State.IsTeleporting = false
        end)
    end)

    -- Trạng thái hiện tại
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, y + 50)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📍 " .. State.CurrentPosition
    statusLabel.TextColor3 = Color3.fromRGB(150,255,150)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 13
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.Parent = mainFrame

    -- Cập nhật trạng thái mỗi khi teleport thành công
    local oldTeleport = safeTeleport
    safeTeleport = function(dest)
        local result = oldTeleport(dest)
        if result then
            statusLabel.Text = "📍 " .. dest
        end
        return result
    end

    return screenGui
end

-- ============================================
-- PHÍM TẮT: F9 để ẩn/hiện menu
-- ============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F9 then
        local menu = LocalPlayer.PlayerGui:FindFirstChild("ASO_TeleportVIP")
        if menu then
            menu.Enabled = not menu.Enabled
            print("[ASO] Menu VIP đã " .. (menu.Enabled and "hiện" or "ẩn"))
        end
    end
end)

-- ============================================
-- KHỞI CHẠY
-- ============================================
local menu = createTeleportMenu()
print("========================================")
print("⚡ ASO-TELEPORT VIP v1.0 đã sẵn sàng!")
print("F9: Ẩn/hiện menu")
print("Chọn điểm đến và bắt đầu teleport.")
print("========================================")
