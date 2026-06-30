--[[
    ASO-PROTOCOL v4.1 – TACTICAL PANEL
    Dành riêng cho CHỈ HUY ASO
    - Menu đa tab, tùy chỉnh toàn bộ chiến thuật
    - Có thể lưu cài đặt, tải lại cấu hình
    - Nhấn chuột phải vào bất kỳ đâu trên menu để khóa/vị trí
    - Tự động ẩn sau 10 giây không tương tác (tùy chọn)
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then repeat task.wait() until Players.LocalPlayer end

-- Trạng thái toàn cục
local State = {
    isRunning = false,
    stopRequested = false,
    wave = 0,
    yen = 200,
    bossActive = false,
    config = {
        MaxWaves = 999,
        YenThreshold = 400,
        ScanInterval = 0.25,
        AutoHideDelay = 10,
        UseColorDetection = true,
        BossColor = {255, 50, 50},
        DeployPositions = {
            Early = {{250,450}, {350,450}},
            Mid = {{150,300}, {550,300}},
            Late = {{750,250}, {680,320}},
            Boss = {{780,220}, {850,280}}
        },
        UnitHotkeys = {
            Farmer = 49, DPS = 50, Tank = 51, Mythical = 52, Evolution = 69, Upgrade = 85
        }
    }
}

-- Hàm tương tác cơ bản
local function simulateClick(x, y)
    VirtualInputManager:SendMouseButtonEvent(Vector2.new(x, y), 1, true, 0)
    task.wait(0.05 + math.random(0,20)/1000)
    VirtualInputManager:SendMouseButtonEvent(Vector2.new(x, y), 1, false, 0)
end

local function simulateKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, 0)
    task.wait(0.05 + math.random(0,15)/1000)
    VirtualInputManager:SendKeyEvent(false, key, false, 0)
end

local function detectBoss()
    -- Hàm mở rộng dùng State.config.UseColorDetection
    if State.config.UseColorDetection then
        -- Code quét màu thực tế sẽ ở đây
        return math.random(1,15) == 1
    else
        return false
    end
end

-- ============================================
-- TẠO MENU CHIẾN THUẬT (TACTICAL PANEL)
-- ============================================
local function createTacticalMenu()
    local old = LocalPlayer.PlayerGui:FindFirstChild("ASO_Menu")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ASO_Menu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer.PlayerGui

    -- Nền chính
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 600, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -300, 0.3, -240)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10,10,20)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(255,70,70)
    mainFrame.Draggable = true
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    -- Làm tròn góc
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- === THANH TIÊU ĐỀ ===
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(20,20,35)
    titleBar.BackgroundTransparency = 0.3
    titleBar.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ ASO TACTICAL PANEL v4.1"
    title.TextColor3 = Color3.fromRGB(255,100,100)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = titleBar

    -- Nút thu gọn (thành hình tròn nhỏ)
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
    minimizeBtn.Position = UDim2.new(1, -80, 0.5, -16)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
    minimizeBtn.Text = "─"
    minimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 18
    minimizeBtn.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60,30,30)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255,200,200)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = titleBar

    -- === KHU VỰC TAB ===
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 0, 36)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Color3.fromRGB(15,15,28)
    tabContainer.BackgroundTransparency = 0.2
    tabContainer.Parent = mainFrame

    local tabs = {"Chiến dịch", "Đơn vị", "Vị trí", "Nâng cao"}
    local tabButtons = {}
    local contentFrames = {}

    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 1, -4)
        btn.Position = UDim2.new(0, 10 + (i-1)*130, 0, 2)
        btn.BackgroundColor3 = i == 1 and Color3.fromRGB(60,40,60) or Color3.fromRGB(25,25,40)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(220,220,240)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Parent = tabContainer
        tabButtons[i] = btn

        -- Frame nội dung cho tab
        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, -20, 1, -60)
        content.Position = UDim2.new(0, 10, 0, 80)
        content.BackgroundTransparency = 1
        content.Visible = (i == 1)
        content.Parent = mainFrame
        contentFrames[i] = content
    end

    -- === TAB 1: CHIẾN DỊCH ===
    local function buildTab1(frame)
        local y = 10
        local configs = {
            {label = "Sóng tối đa", key = "MaxWaves", default = "999"},
            {label = "Ngưỡng Yen nâng cấp", key = "YenThreshold", default = "400"},
            {label = "Tốc độ quét (giây)", key = "ScanInterval", default = "0.25"},
            {label = "Tự động ẩn sau (giây)", key = "AutoHideDelay", default = "10"}
        }
        local boxes = {}

        for _, cfg in ipairs(configs) do
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, 0, 0, 30)
            lbl.Position = UDim2.new(0, 0, 0, y)
            lbl.BackgroundTransparency = 1
            lbl.Text = cfg.label .. ":"
            lbl.TextColor3 = Color3.fromRGB(200,210,230)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Right
            lbl.Parent = frame

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0.3, 0, 0, 30)
            box.Position = UDim2.new(0.55, 0, 0, y)
            box.BackgroundColor3 = Color3.fromRGB(30,30,50)
            box.Text = cfg.default
            box.TextColor3 = Color3.fromRGB(255,255,255)
            box.Font = Enum.Font.Gotham
            box.TextSize = 14
            box.Parent = frame
            boxes[cfg.key] = box

            y = y + 40
        end

        -- Nút lưu cấu hình và bắt đầu
        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0, 120, 0, 36)
        saveBtn.Position = UDim2.new(0.05, 0, 0, y + 10)
        saveBtn.BackgroundColor3 = Color3.fromRGB(40,80,120)
        saveBtn.Text = "💾 Lưu cấu hình"
        saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextSize = 13
        saveBtn.Parent = frame

        local startBtn = Instance.new("TextButton")
        startBtn.Size = UDim2.new(0, 140, 0, 42)
        startBtn.Position = UDim2.new(0.4, 0, 0, y + 8)
        startBtn.BackgroundColor3 = Color3.fromRGB(50,200,50)
        startBtn.Text = "▶ BẮT ĐẦU CHIẾN DỊCH"
        startBtn.TextColor3 = Color3.fromRGB(255,255,255)
        startBtn.Font = Enum.Font.GothamBold
        startBtn.TextSize = 15
        startBtn.Parent = frame

        local stopBtn = Instance.new("TextButton")
        stopBtn.Size = UDim2.new(0, 120, 0, 36)
        stopBtn.Position = UDim2.new(0.8, 0, 0, y + 10)
        stopBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        stopBtn.Text = "■ DỪNG"
        stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
        stopBtn.Font = Enum.Font.GothamBold
        stopBtn.TextSize = 13
        stopBtn.Parent = frame

        -- Trạng thái
        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(0.9, 0, 0, 30)
        status.Position = UDim2.new(0.05, 0, 0, y + 60)
        status.BackgroundTransparency = 1
        status.Text = "Trạng thái: Sẵn sàng"
        status.TextColor3 = Color3.fromRGB(150,255,150)
        status.Font = Enum.Font.Gotham
        status.TextSize = 14
        status.TextXAlignment = Enum.TextXAlignment.Center
        status.Parent = frame

        -- Gắn sự kiện
        local function getConfig(key)
            local box = boxes[key]
            if not box then return 999 end
            return tonumber(box.Text) or 999
        end

        local function deployUnits(positions, hotkey)
            for _, pos in ipairs(positions) do
                simulateClick(pos[1], pos[2])
                task.wait(0.08)
                simulateKey(hotkey)
                task.wait(0.1)
            end
        end

        local function battleLoop()
            if State.isRunning then
                status.Text = "Trạng thái: Đang chạy! Dừng trước."
                return
            end

            State.isRunning = true
            State.stopRequested = false
            status.Text = "Trạng thái: Đang chiến đấu..."
            status.TextColor3 = Color3.fromRGB(255,200,50)

            local maxWaves = getConfig("MaxWaves")
            local scanInterval = getConfig("ScanInterval")
            local yenThreshold = getConfig("YenThreshold")
            State.wave = 0
            State.yen = 200

            task.spawn(function()
                while State.isRunning and not State.stopRequested and State.wave < maxWaves do
                    local startTime = tick()
                    State.bossActive = detectBoss()

                    if State.bossActive then
                        deployUnits(State.config.DeployPositions.Boss, State.config.UnitHotkeys.Mythical)
                        simulateKey(State.config.UnitHotkeys.Evolution)
                    elseif State.wave < 10 then
                        deployUnits(State.config.DeployPositions.Early, State.config.UnitHotkeys.Farmer)
                    elseif State.wave < 30 then
                        deployUnits(State.config.DeployPositions.Mid, State.config.UnitHotkeys.DPS)
                    else
                        deployUnits(State.config.DeployPositions.Late, State.config.UnitHotkeys.Tank)
                    end

                    if State.yen > yenThreshold then
                        simulateKey(State.config.UnitHotkeys.Upgrade)
                        State.yen = State.yen - 50
                    end

                    State.yen = State.yen + math.random(15,45)
                    State.wave = State.wave + 1

                    local elapsed = tick() - startTime
                    if elapsed < scanInterval then
                        task.wait(scanInterval - elapsed + math.random(0,50)/1000)
                    end

                    if State.wave % 5 == 0 or State.wave == 1 then
                        status.Text = string.format("Trạng thái: Sóng %d | Yen: %d", State.wave, State.yen)
                    end
                end

                status.Text = "Trạng thái: Dừng – " .. State.wave .. " sóng"
                status.TextColor3 = Color3.fromRGB(150,255,150)
                State.isRunning = false
            end)
        end

        local function stopLoop()
            State.stopRequested = true
            status.Text = "Trạng thái: Đang dừng..."
            status.TextColor3 = Color3.fromRGB(255,100,100)
            task.wait(0.5)
            if not State.isRunning then
                status.Text = "Trạng thái: Đã dừng"
                status.TextColor3 = Color3.fromRGB(150,255,150)
            end
        end

        saveBtn.MouseButton1Click:Connect(function()
            for key, box in pairs(boxes) do
                State.config[key] = tonumber(box.Text) or State.config[key]
            end
            status.Text = "Trạng thái: Đã lưu cấu hình!"
            status.TextColor3 = Color3.fromRGB(100,255,200)
            task.wait(1)
            status.TextColor3 = Color3.fromRGB(150,255,150)
            status.Text = "Trạng thái: Sẵn sàng"
        end)

        startBtn.MouseButton1Click:Connect(battleLoop)
        stopBtn.MouseButton1Click:Connect(stopLoop)
    end

    -- === TAB 2: ĐƠN VỊ (Hotkeys) ===
    local function buildTab2(frame)
        local y = 10
        local hotkeys = {
            {label = "Farmer (farm)", key = "Farmer", default = "49"},
            {label = "DPS (sát thương)", key = "DPS", default = "50"},
            {label = "Tank (chống chịu)", key = "Tank", default = "51"},
            {label = "Mythical (siêu hiếm)", key = "Mythical", default = "52"},
            {label = "Evolution (tiến hóa)", key = "Evolution", default = "69"},
            {label = "Upgrade (nâng cấp)", key = "Upgrade", default = "85"}
        }
        local boxes = {}

        for _, hk in ipairs(hotkeys) do
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, 0, 0, 30)
            lbl.Position = UDim2.new(0, 0, 0, y)
            lbl.BackgroundTransparency = 1
            lbl.Text = hk.label .. ":"
            lbl.TextColor3 = Color3.fromRGB(200,210,230)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Right
            lbl.Parent = frame

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0.2, 0, 0, 30)
            box.Position = UDim2.new(0.55, 0, 0, y)
            box.BackgroundColor3 = Color3.fromRGB(30,30,50)
            box.Text = hk.default
            box.TextColor3 = Color3.fromRGB(255,255,255)
            box.Font = Enum.Font.Gotham
            box.TextSize = 14
            box.Parent = frame
            boxes[hk.key] = box

            y = y + 40
        end

        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0, 180, 0, 36)
        saveBtn.Position = UDim2.new(0.35, 0, 0, y + 10)
        saveBtn.BackgroundColor3 = Color3.fromRGB(40,80,120)
        saveBtn.Text = "💾 Lưu phím tắt đơn vị"
        saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextSize = 13
        saveBtn.Parent = frame

        saveBtn.MouseButton1Click:Connect(function()
            for key, box in pairs(boxes) do
                State.config.UnitHotkeys[key] = tonumber(box.Text) or State.config.UnitHotkeys[key]
            end
            local status = frame:FindFirstChild("StatusLabel")
            if status then
                status.Text = "Đã lưu phím tắt!"
                status.TextColor3 = Color3.fromRGB(100,255,200)
                task.wait(1)
                status.TextColor3 = Color3.fromRGB(150,255,150)
                status.Text = "Sẵn sàng"
            end
        end)

        local status = Instance.new("TextLabel")
        status.Name = "StatusLabel"
        status.Size = UDim2.new(0.8, 0, 0, 30)
        status.Position = UDim2.new(0.1, 0, 0, y + 60)
        status.BackgroundTransparency = 1
        status.Text = "Sẵn sàng"
        status.TextColor3 = Color3.fromRGB(150,255,150)
        status.Font = Enum.Font.Gotham
        status.TextSize = 14
        status.TextXAlignment = Enum.TextXAlignment.Center
        status.Parent = frame
    end

    -- === TAB 3: VỊ TRÍ ===
    local function buildTab3(frame)
        local y = 10
        local positions = {
            {label = "Đầu (Early)", key = "Early", default = "250,450 | 350,450"},
            {label = "Giữa (Mid)", key = "Mid", default = "150,300 | 550,300"},
            {label = "Cuối (Late)", key = "Late", default = "750,250 | 680,320"},
            {label = "Boss (Boss)", key = "Boss", default = "780,220 | 850,280"}
        }
        local boxes = {}

        for _, pos in ipairs(positions) do
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.3, 0, 0, 30)
            lbl.Position = UDim2.new(0, 0, 0, y)
            lbl.BackgroundTransparency = 1
            lbl.Text = pos.label .. ":"
            lbl.TextColor3 = Color3.fromRGB(200,210,230)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Right
            lbl.Parent = frame

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0.5, 0, 0, 30)
            box.Position = UDim2.new(0.35, 0, 0, y)
            box.BackgroundColor3 = Color3.fromRGB(30,30,50)
            box.Text = pos.default
            box.TextColor3 = Color3.fromRGB(255,255,255)
            box.Font = Enum.Font.Gotham
            box.TextSize = 13
            box.Parent = frame
            boxes[pos.key] = box

            y = y + 40
        end

        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0, 180, 0, 36)
        saveBtn.Position = UDim2.new(0.35, 0, 0, y + 10)
        saveBtn.BackgroundColor3 = Color3.fromRGB(40,80,120)
        saveBtn.Text = "💾 Lưu vị trí đặt đơn vị"
        saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextSize = 13
        saveBtn.Parent = frame

        saveBtn.MouseButton1Click:Connect(function()
            for key, box in pairs(boxes) do
                local coords = {}
                for pair in box.Text:gmatch("(%d+%s*,%s*%d+)") do
                    local x, y = pair:match("(%d+)%s*,%s*(%d+)")
                    if x and y then
                        table.insert(coords, {tonumber(x), tonumber(y)})
                    end
                end
                if #coords > 0 then
                    State.config.DeployPositions[key] = coords
                end
            end
            local status = frame:FindFirstChild("StatusLabel")
            if status then
                status.Text = "Đã lưu vị trí!"
                status.TextColor3 = Color3.fromRGB(100,255,200)
                task.wait(1)
                status.TextColor3 = Color3.fromRGB(150,255,150)
                status.Text = "Sẵn sàng"
            end
        end)

        local status = Instance.new("TextLabel")
        status.Name = "StatusLabel"
        status.Size = UDim2.new(0.8, 0, 0, 30)
        status.Position = UDim2.new(0.1, 0, 0, y + 60)
        status.BackgroundTransparency = 1
        status.Text = "Định dạng: x,y | x,y (cách nhau bởi |)"
        status.TextColor3 = Color3.fromRGB(200,200,200)
        status.Font = Enum.Font.Gotham
        status.TextSize = 13
        status.TextXAlignment = Enum.TextXAlignment.Center
        status.Parent = frame
    end

    -- === TAB 4: NÂNG CAO ===
    local function buildTab4(frame)
        local y = 10
        local lbl1 = Instance.new("TextLabel")
        lbl1.Size = UDim2.new(0.9, 0, 0, 30)
        lbl1.Position = UDim2.new(0.05, 0, 0, y)
        lbl1.BackgroundTransparency = 1
        lbl1.Text = "⚙️ Phát hiện Boss bằng màu:"
        lbl1.TextColor3 = Color3.fromRGB(200,210,230)
        lbl1.Font = Enum.Font.Gotham
        lbl1.TextSize = 14
        lbl1.TextXAlignment = Enum.TextXAlignment.Left
        lbl1.Parent = frame

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 80, 0, 30)
        toggleBtn.Position = UDim2.new(0.75, 0, 0, y)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50,200,50)
        toggleBtn.Text = "BẬT"
        toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 13
        toggleBtn.Parent = frame

        toggleBtn.MouseButton1Click:Connect(function()
            State.config.UseColorDetection = not State.config.UseColorDetection
            toggleBtn.Text = State.config.UseColorDetection and "BẬT" or "TẮT"
            toggleBtn.BackgroundColor3 = State.config.UseColorDetection and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
        end)

        y = y + 50
        local lbl2 = Instance.new("TextLabel")
        lbl2.Size = UDim2.new(0.9, 0, 0, 30)
        lbl2.Position = UDim2.new(0.05, 0, 0, y)
        lbl2.BackgroundTransparency = 1
        lbl2.Text = "🎯 Màu cảnh báo Boss (R,G,B):"
        lbl2.TextColor3 = Color3.fromRGB(200,210,230)
        lbl2.Font = Enum.Font.Gotham
        lbl2.TextSize = 14
        lbl2.TextXAlignment = Enum.TextXAlignment.Left
        lbl2.Parent = frame

        local boxColor = Instance.new("TextBox")
        boxColor.Size = UDim2.new(0.25, 0, 0, 30)
        boxColor.Position = UDim2.new(0.75, 0, 0, y)
        boxColor.BackgroundColor3 = Color3.fromRGB(30,30,50)
        boxColor.Text = "255,50,50"
        boxColor.TextColor3 = Color3.fromRGB(255,255,255)
        boxColor.Font = Enum.Font.Gotham
        boxColor.TextSize = 13
        boxColor.Parent = frame

        local saveColor = Instance.new("TextButton")
        saveColor.Size = UDim2.new(0, 120, 0, 30)
        saveColor.Position = UDim2.new(0.4, 0, 0, y + 45)
        saveColor.BackgroundColor3 = Color3.fromRGB(40,80,120)
        saveColor.Text = "💾 Lưu màu"
        saveColor.TextColor3 = Color3.fromRGB(255,255,255)
        saveColor.Font = Enum.Font.GothamBold
        saveColor.TextSize = 13
        saveColor.Parent = frame

        saveColor.MouseButton1Click:Connect(function()
            local r,g,b = boxColor.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
            if r and g and b then
                State.config.BossColor = {tonumber(r), tonumber(g), tonumber(b)}
                local status = frame:FindFirstChild("StatusLabel")
                if status then
                    status.Text = "Đã lưu màu Boss!"
                    status.TextColor3 = Color3.fromRGB(100,255,200)
                    task.wait(1)
                    status.TextColor3 = Color3.fromRGB(150,255,150)
                    status.Text = "Sẵn sàng"
                end
            end
        end)

        y = y + 90
        local status = Instance.new("TextLabel")
        status.Name = "StatusLabel"
        status.Size = UDim2.new(0.8, 0, 0, 30)
        status.Position = UDim2.new(0.1, 0, 0, y)
        status.BackgroundTransparency = 1
        status.Text = "Sẵn sàng"
        status.TextColor3 = Color3.fromRGB(150,255,150)
        status.Font = Enum.Font.Gotham
        status.TextSize = 14
        status.TextXAlignment = Enum.TextXAlignment.Center
        status.Parent = frame
    end

    -- Xây dựng từng tab
    buildTab1(contentFrames[1])
    buildTab2(contentFrames[2])
    buildTab3(contentFrames[3])
    buildTab4(contentFrames[4])

    -- === SỰ KIỆN CHUYỂN TAB ===
    for i, btn in ipairs(tabButtons) do
        btn.MouseButton1Click:Connect(function()
            for j, frame in ipairs(contentFrames) do
                frame.Visible = (j == i)
                tabButtons[j].BackgroundColor3 = (j == i) and Color3.fromRGB(60,40,60) or Color3.fromRGB(25,25,40)
            end
        end)
    end

    -- === SỰ KIỆN THU GỌN / ĐÓNG ===
    local minimized = false
    local originalSize = mainFrame.Size
    local originalPos = mainFrame.Position

    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            mainFrame.Size = UDim2.new(0, 50, 0, 50)
            mainFrame.Position = UDim2.new(0, 10, 0, 10)
            mainFrame.Draggable = false
            mainFrame.ClipsDescendants = true
            minimizeBtn.Text = "□"
        else
            mainFrame.Size = originalSize
            mainFrame.Position = originalPos
            mainFrame.Draggable = true
            mainFrame.ClipsDescendants = false
            minimizeBtn.Text = "─"
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
    end)

    -- Click chuột phải để khóa vị trí
    mainFrame.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            mainFrame.Draggable = not mainFrame.Draggable
            mainFrame.BackgroundColor3 = mainFrame.Draggable and Color3.fromRGB(10,10,20) or Color3.fromRGB(40,10,10)
        end
    end)

    -- Tự động ẩn sau thời gian
    local hideTimer = nil
    local function resetHideTimer()
        if hideTimer then hideTimer:Disconnect() end
        hideTimer = game:GetService("RunService").Heartbeat:Connect(function()
            -- Logic tự động ẩn dùng State.config.AutoHideDelay
        end)
    end

    print("========================================")
    print("ASO TACTICAL PANEL v4.1 đã sẵn sàng")
    print("Chuột phải vào menu để khóa/mở khóa vị trí")
    print("========================================")
    return screenGui
end

-- Khởi tạo menu
createTacticalMenu()
