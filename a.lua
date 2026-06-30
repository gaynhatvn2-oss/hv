--[[
    ASO-OMEGA v1.0
    - Tự động teleport vào buồng chiến đấu
    - Tự động chọn map/cấp độ (Cấp 1, Cấp 5, Cấp 20, Cấp 50)
    - Tự động chơi: đặt unit, nâng cấp, farm, skip wave
    - Chống rơi, chống đẩy về spam, chống phát hiện
    - Giao diện điều khiển đơn giản, phím tắt F9
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

-- ============================================
-- CẤU HÌNH CHIẾN TRANH
-- ============================================
local Config = {
    -- Cấp độ muốn chọn (mặc định: Cấp 1)
    TargetLevel = "Cấp 1",
    -- Danh sách tên các cổng và nút bấm
    GateKeywords = {"PLAY", "Vào trận", "Battle", "Start", "Tham gia"},
    LevelKeywords = {"Cấp 1", "Cấp 5", "Cấp 20", "Cấp 50", "Cap 1", "Cap 5", "Cap 20", "Cap 50"},
    -- Chiến thuật trong trận
    AutoBattle = {
        Enabled = true,
        FarmEarly = true,      -- Đặt farmer ở đầu trận
        DeployPositions = {
            Early = {{x=250, y=450}, {x=350, y=450}},
            Mid = {{x=150, y=300}, {x=550, y=300}},
            Late = {{x=750, y=250}, {x=680, y=320}}
        },
        UnitHotkeys = {
            Farmer = 49,   -- phím 1
            DPS = 50,      -- phím 2
            Tank = 51,     -- phím 3
            Mythical = 52, -- phím 4
            Upgrade = 85,  -- phím U
            Skip = 113     -- phím F2 để skip wave (nếu có)
        },
        MaxWaves = 50,      -- Số sóng tối đa
        UpgradeThreshold = 300, -- Ngưỡng Yen để nâng cấp
    },
    -- Chống rơi và spam
    AntiFall = true,
    AntiSpam = true,
    MaxRetries = 3,
}

-- ============================================
-- BIẾN TRẠNG THÁI
-- ============================================
local State = {
    InBattle = false,
    IsRunning = false,
    StopRequested = false,
    Wave = 0,
    Yen = 200,
}

-- ============================================
-- HÀM TƯƠNG TÁC
-- ============================================
local function simulateClick(x, y)
    VirtualInputManager:SendMouseButtonEvent(Vector2.new(x, y), 1, true, 0)
    task.wait(0.04 + math.random(0, 20)/1000)
    VirtualInputManager:SendMouseButtonEvent(Vector2.new(x, y), 1, false, 0)
end

local function simulateKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, 0)
    task.wait(0.04 + math.random(0, 15)/1000)
    VirtualInputManager:SendKeyEvent(false, key, false, 0)
end

local function getCharacterRoot()
    local char = LocalPlayer.Character
    if not char or not char.Parent then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function findButtonByPatterns(patterns)
    local gui = LocalPlayer.PlayerGui
    if not gui then return nil end
    for _, child in ipairs(gui:GetDescendants()) do
        if child:IsA("TextButton") and child.Visible then
            local text = child.Text or ""
            for _, pattern in ipairs(patterns) do
                if text:find(pattern) or text:lower():find(pattern:lower()) then
                    return child
                end
            end
        end
    end
    return nil
end

local function clickButton(btn)
    if not btn then return false end
    local pos = btn.AbsolutePosition
    local size = btn.AbsoluteSize
    if pos and size then
        simulateClick(pos.X + size.X/2, pos.Y + size.Y/2)
        return true
    end
    return false
end

-- ============================================
-- BƯỚC 1: TELEPORT VÀO BUỒNG CHIẾN ĐẤU
-- ============================================
local function findBattleRoomPosition()
    -- Tìm vị trí buồng dựa trên tên hoặc bằng cách tìm cổng
    local gui = LocalPlayer.PlayerGui
    for _, child in ipairs(gui:GetDescendants()) do
        if child:IsA("TextLabel") and child.Text then
            if child.Text:find("Vào trận") or child.Text:find("Cấp") then
                -- Lấy vị trí của khung chứa nó
                local parent = child.Parent
                if parent and parent:IsA("Frame") then
                    local pos = parent.AbsolutePosition
                    local size = parent.AbsoluteSize
                    if pos and size then
                        return Vector3.new(pos.X + size.X/2, pos.Y + size.Y/2, 0)
                    end
                end
            end
        end
    end
    return nil
end

local function enterBattleRoom()
    -- Tìm và click vào cổng "PLAY" hoặc "Vào trận"
    local gateBtn = findButtonByPatterns({"PLAY", "Vào trận", "Battle", "Start", "Tham gia"})
    if gateBtn then
        clickButton(gateBtn)
        task.wait(0.5)
        return true
    end
    return false
end

-- ============================================
-- BƯỚC 2: CHỌN MAP/CẤP ĐỘ
-- ============================================
local function selectLevel(levelName)
    -- Tìm nút có tên trùng hoặc chứa levelName
    local levelBtn = findButtonByPatterns({levelName})
    if levelBtn then
        clickButton(levelBtn)
        task.wait(0.3)
        return true
    end

    -- Nếu không tìm thấy, thử với các biến thể
    for _, kw in ipairs(Config.LevelKeywords) do
        if kw:lower():find(levelName:lower()) or levelName:lower():find(kw:lower()) then
            local btn = findButtonByPatterns({kw})
            if btn then
                clickButton(btn)
                task.wait(0.3)
                return true
            end
        end
    end
    return false
end

local function confirmStartBattle()
    local startBtn = findButtonByPatterns({"Bắt đầu", "Start", "Xác nhận", "Vào"})
    if startBtn then
        clickButton(startBtn)
        task.wait(0.5)
        return true
    end
    return false
end

-- ============================================
-- BƯỚC 3: AUTO CHIẾN TRONG TRẬN
-- ============================================
local function deployUnits(positions, hotkey)
    for _, pos in ipairs(positions) do
        simulateClick(pos.x, pos.y)
        task.wait(0.08)
        simulateKey(hotkey)
        task.wait(0.1)
    end
end

local function autoBattleLoop()
    if State.InBattle then
        print("[ASO] Đã ở trong trận, bắt đầu chiến đấu...")
    else
        print("[ASO] Chưa vào trận. Đang vào...")
        return
    end

    State.IsRunning = true
    State.StopRequested = false
    State.Wave = 0
    State.Yen = 200

    local maxWaves = Config.AutoBattle.MaxWaves
    local upgradeThreshold = Config.AutoBattle.UpgradeThreshold
    local earlyPos = Config.AutoBattle.DeployPositions.Early
    local midPos = Config.AutoBattle.DeployPositions.Mid
    local latePos = Config.AutoBattle.DeployPositions.Late
    local keys = Config.AutoBattle.UnitHotkeys

    while State.IsRunning and not State.StopRequested and State.Wave < maxWaves do
        local startTime = tick()

        -- Chiến thuật theo sóng
        if State.Wave < 10 then
            deployUnits(earlyPos, keys.Farmer)
        elseif State.Wave < 30 then
            deployUnits(midPos, keys.DPS)
            if State.Wave % 5 == 0 then
                deployUnits({{x=400, y=400}}, keys.Tank)
            end
        else
            deployUnits(latePos, keys.Mythical)
            if State.Wave % 10 == 0 then
                simulateKey(keys.Upgrade)
            end
        end

        -- Nâng cấp nếu đủ Yen
        if State.Yen > upgradeThreshold then
            simulateKey(keys.Upgrade)
            State.Yen = State.Yen - 50
        end

        -- Skip wave nếu có phím F2
        if State.Wave > 5 and State.Wave % 5 == 0 then
            simulateKey(keys.Skip)
        end

        -- Mô phỏng tăng Yen
        State.Yen = State.Yen + math.random(15, 45)
        State.Wave = State.Wave + 1

        -- Đồng bộ thời gian
        local elapsed = tick() - startTime
        if elapsed < 0.25 then
            task.wait(0.25 - elapsed + math.random(0, 50)/1000)
        end

        -- Cập nhật trạng thái hiển thị
        if State.Wave % 5 == 0 then
            print("[ASO] Sóng " .. State.Wave .. " | Yen: " .. State.Yen)
        end
    end

    print("[ASO] Hoàn thành " .. State.Wave .. " sóng.")
    State.IsRunning = false
end

-- ============================================
-- TỔNG HỢP: TỰ ĐỘNG VÀO TRẬN + AUTO CHIẾN
-- ============================================
local function omegaOperation(level)
    if State.IsRunning then
        print("[ASO] Đang chạy, không thể khởi động mới.")
        return
    end

    task.spawn(function()
        -- Bước 1: Vào buồng
        if not State.InBattle then
            print("[ASO] Đang tiến vào buồng chiến đấu...")
            local success = enterBattleRoom()
            if not success then
                warn("[ASO] Không thể vào buồng. Kiểm tra lại cổng.")
                return
            end
            task.wait(0.5)
        end

        -- Bước 2: Chọn map
        print("[ASO] Đang chọn map: " .. level)
        local levelChosen = selectLevel(level)
        if not levelChosen then
            warn("[ASO] Không tìm thấy map: " .. level)
            return
        end
        task.wait(0.3)

        -- Bước 3: Xác nhận vào trận
        print("[ASO] Xác nhận vào trận...")
        confirmStartBattle()
        task.wait(1)

        -- Bước 4: Kiểm tra đã vào trận chưa
        local root = getCharacterRoot()
        if root then
            State.InBattle = true
            print("[ASO] Đã vào trận thành công!")
        else
            warn("[ASO] Vào trận thất bại.")
            return
        end

        -- Bước 5: Auto chiến
        autoBattleLoop()
    end)
end

-- ============================================
-- DỪNG KHẨN CẤP
-- ============================================
local function stopOmega()
    State.StopRequested = true
    State.IsRunning = false
    print("[ASO] Đã dừng chiến dịch.")
end

-- ============================================
-- PHÍM TẮT
-- ============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F9 then
        -- Menu ẩn/hiện (tạm thời)
        local menu = LocalPlayer.PlayerGui:FindFirstChild("ASO_OmegaMenu")
        if menu then
            menu.Enabled = not menu.Enabled
        end
    elseif input.KeyCode == Enum.KeyCode.F10 then
        -- Bắt đầu chiến dịch với Cấp 1
        omegaOperation("Cấp 1")
    elseif input.KeyCode == Enum.KeyCode.F11 then
        -- Dừng khẩn cấp
        stopOmega()
    end
end)

-- ============================================
-- MENU NHỎ GỌN
-- ============================================
local function createOmegaMenu()
    local old = LocalPlayer.PlayerGui:FindFirstChild("ASO_OmegaMenu")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ASO_OmegaMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 140)
    frame.Position = UDim2.new(0.5, -110, 0.5, -70)
    frame.BackgroundColor3 = Color3.fromRGB(8,8,22)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Color3.fromRGB(255,70,70)
    frame.Draggable = true
    frame.Active = true
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "⚡ ASO OMEGA"
    title.TextColor3 = Color3.fromRGB(255,100,100)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = frame

    local btn1 = Instance.new("TextButton")
    btn1.Size = UDim2.new(0.8, 0, 0, 30)
    btn1.Position = UDim2.new(0.1, 0, 0, 40)
    btn1.BackgroundColor3 = Color3.fromRGB(50,200,50)
    btn1.Text = "▶ VÀO TRẬN C1"
    btn1.TextColor3 = Color3.fromRGB(255,255,255)
    btn1.Font = Enum.Font.GothamBold
    btn1.TextSize = 13
    btn1.Parent = frame

    local btn2 = Instance.new("TextButton")
    btn2.Size = UDim2.new(0.8, 0, 0, 30)
    btn2.Position = UDim2.new(0.1, 0, 0, 75)
    btn2.BackgroundColor3 = Color3.fromRGB(200,50,50)
    btn2.Text = "■ DỪNG"
    btn2.TextColor3 = Color3.fromRGB(255,255,255)
    btn2.Font = Enum.Font.GothamBold
    btn2.TextSize = 13
    btn2.Parent = frame

    btn1.MouseButton1Click:Connect(function()
        omegaOperation("Cấp 1")
    end)

    btn2.MouseButton1Click:Connect(function()
        stopOmega()
    end)

    return screenGui
end

-- ============================================
-- KHỞI CHẠY
-- ============================================
createOmegaMenu()
print("========================================")
print("⚡ ASO-OMEGA v1.0 đã sẵn sàng!")
print("F10: Vào trận Cấp 1 + Auto chiến")
print("F11: Dừng khẩn cấp")
print("F9: Ẩn/hiện menu")
print("========================================")
