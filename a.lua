--[[
    ASO-OMEGA V5 – FULL AUTO SELECT MAP & CHAPTER
    Dành cho CHỈ HUY ASO
    - Sử dụng bypass teleport mới (từ mẫu của ngài)
    - Tự động chọn thế giới (map) và chương (chapter)
    - Tự động xác nhận và bắt đầu trận đấu
    - Menu trực quan, phím tắt F9 (menu), F10 (bắt đầu), F11 (dừng)
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

-- ============================================
-- CẤU HÌNH (CHỈ HUY CÓ THỂ TÙY CHỈNH)
-- ============================================
local Config = {
    -- Tọa độ đích từ ảnh quét (của chỉ huy)
    TargetPos = Vector3.new(-216.97752380371094, 11.390323638916016, -313.96240234375),
    
    -- Map mặc định (có thể đổi thành "Thành Phố Ami", "Học viện bùng nổ", v.v.)
    DefaultMap = "Lăng cối gió",
    
    -- Chương mặc định (từ 1 đến 500)
    DefaultChapter = "Chương 1",
    
    -- Danh sách từ khóa để tìm nút (dựa trên ảnh)
    MapKeywords = {
        "Lăng cối gió", "Windmill Village",
        "Thành Phố Ami", "Học viện bùng nổ", "Hành tinh xanh"
    },
    ChapterPrefix = "Chương ",  -- Tất cả các chương đều có dạng "Chương X"
    ConfirmKeywords = {"Chấp nhận", "Xác nhận", "Accept", "Bắt đầu"},
    StartKeywords = {"Bắt đầu", "Start", "Play", "Vào trận"}
}

-- ============================================
-- TRẠNG THÁI
-- ============================================
local State = {
    IsRunning = false,
    StopRequested = false,
    InBattle = false,
    SelectedMap = Config.DefaultMap,
    SelectedChapter = Config.DefaultChapter,
    MenuVisible = true
}

-- ============================================
-- HÀM TELEPORT (TỪ MẪU CỦA CHỈ HUY)
-- ============================================
local function bypassTeleport(targetPos)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    
    print("[SYSTEM] Bắt đầu dịch chuyển đồng bộ đến tọa độ mới...")
    
    -- Bước 1: Đóng băng tạm thời trạng thái vật lý rơi tự do
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    
    -- Bước 2: Chia nhỏ quãng đường di chuyển thành các chặng siêu ngắn (8 studs)
    local currentPos = rootPart.Position
    local distance = (targetPos - currentPos).Magnitude
    local steps = math.floor(distance / 8) 
    
    if steps > 0 then
        for i = 1, steps do
            local interpolation = currentPos:Lerp(targetPos, i / steps)
            rootPart.CFrame = CFrame.new(interpolation)
            humanoid:ChangeState(Enum.HumanoidStateType.Running) 
            task.wait(0.015)
        end
    end
    
    -- Bước 3: Đặt nhân vật chuẩn xác tại tọa độ đích
    rootPart.CFrame = CFrame.new(targetPos)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    task.wait(0.1)
    
    print("[SYSTEM] Đã đến vị trí. Đang kích hoạt chuỗi nhảy ép va chạm...")
    
    -- Bước 4: Ép nhân vật nhấc chân/nhảy 3 lần
    for i = 1, 3 do
        humanoid.Jump = true
        task.wait(0.2)
    end
    
    print("[SYSTEM] Teleport hoàn tất!")
end

-- ============================================
-- HÀM TÌM VÀ CLICK NÚT
-- ============================================
local function findButtonByPatterns(patterns, exactMatch)
    local gui = LocalPlayer.PlayerGui
    if not gui then return nil end
    for _, child in ipairs(gui:GetDescendants()) do
        if child:IsA("TextButton") and child.Visible then
            local text = child.Text or ""
            for _, p in ipairs(patterns) do
                if exactMatch then
                    if text == p then return child end
                else
                    if text:find(p) or text:lower():find(p:lower()) then
                        return child
                    end
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
        local x = pos.X + size.X/2
        local y = pos.Y + size.Y/2
        VirtualInputManager:SendMouseButtonEvent(Vector2.new(x, y), 1, true, 0)
        task.wait(0.04)
        VirtualInputManager:SendMouseButtonEvent(Vector2.new(x, y), 1, false, 0)
        return true
    end
    return false
end

-- ============================================
-- CHỌN MAP, CHAPTER, XÁC NHẬN VÀ BẮT ĐẦU
-- ============================================
local function selectMap(mapName)
    -- Tìm nút map dựa trên tên chính xác hoặc từ khóa
    local mapBtn = findButtonByPatterns({mapName}, true)
    if not mapBtn then
        -- Thử với từ khóa
        for _, kw in ipairs(Config.MapKeywords) do
            if kw:lower():find(mapName:lower()) or mapName:lower():find(kw:lower()) then
                mapBtn = findButtonByPatterns({kw}, false)
                if mapBtn then break end
            end
        end
    end
    if mapBtn then
        clickButton(mapBtn)
        print("[ASO] Đã chọn map: " .. mapName)
        task.wait(0.3)
        return true
    end
    return false
end

local function selectChapter(chapterName)
    -- Chương thường có dạng "Chương X" hoặc "Chapter X"
    local chapterBtn = findButtonByPatterns({chapterName}, true)
    if not chapterBtn then
        -- Nếu tên chỉ là số, thêm prefix
        local fullName = Config.ChapterPrefix .. chapterName
        chapterBtn = findButtonByPatterns({fullName}, true)
        if not chapterBtn then
            -- Thử tìm với từ khóa chương
            chapterBtn = findButtonByPatterns({chapterName}, false)
        end
    end
    if chapterBtn then
        clickButton(chapterBtn)
        print("[ASO] Đã chọn chương: " .. chapterName)
        task.wait(0.3)
        return true
    end
    return false
end

local function confirmAndStart()
    -- Tìm nút xác nhận (Chấp nhận, Accept, v.v.)
    local confirmBtn = findButtonByPatterns(Config.ConfirmKeywords, false)
    if confirmBtn then
        clickButton(confirmBtn)
        print("[ASO] Đã nhấn Chấp nhận.")
        task.wait(0.5)
    else
        warn("[ASO] Không tìm thấy nút Chấp nhận.")
        return false
    end
    
    -- Tìm nút Bắt đầu (Start, Play, v.v.)
    local startBtn = findButtonByPatterns(Config.StartKeywords, false)
    if startBtn then
        clickButton(startBtn)
        print("[ASO] Đã nhấn Bắt đầu. Đang load vào map...")
        task.wait(1.5)
        return true
    else
        warn("[ASO] Không tìm thấy nút Bắt đầu.")
        return false
    end
end

-- ============================================
-- QUY TRÌNH CHÍNH: TELEPORT + CHỌN MAP + CHAPTER + VÀO TRẬN
-- ============================================
local function startFullMission(mapName, chapterName)
    if State.IsRunning then
        print("[ASO] Đang chạy, không thể khởi động mới.")
        return
    end
    State.IsRunning = true
    State.StopRequested = false
    
    task.spawn(function()
        print("[ASO] Bắt đầu nhiệm vụ với map: " .. (mapName or "mặc định") .. ", chương: " .. (chapterName or "mặc định"))
        
        -- Bước 1: Teleport đến vị trí
        bypassTeleport(Config.TargetPos)
        task.wait(1)
        
        -- Bước 2: Chọn map
        local mapSelected = selectMap(mapName or Config.DefaultMap)
        if not mapSelected then
            warn("[ASO] Không thể chọn map. Dừng nhiệm vụ.")
            State.IsRunning = false
            return
        end
        task.wait(0.5)
        
        -- Bước 3: Chọn chương
        local chapterSelected = selectChapter(chapterName or Config.DefaultChapter)
        if not chapterSelected then
            warn("[ASO] Không thể chọn chương. Dừng nhiệm vụ.")
            State.IsRunning = false
            return
        end
        task.wait(0.5)
        
        -- Bước 4: Xác nhận và bắt đầu
        local success = confirmAndStart()
        if success then
            State.InBattle = true
            print("[ASO] Đã vào trận thành công!")
            -- Có thể gọi auto battle ở đây nếu có
        else
            warn("[ASO] Không thể vào trận. Dừng nhiệm vụ.")
        end
        
        State.IsRunning = false
    end)
end

local function stopMission()
    State.StopRequested = true
    State.IsRunning = false
    print("[ASO] Đã dừng nhiệm vụ.")
end

-- ============================================
-- MENU GIAO DIỆN
-- ============================================
local function createMenu()
    local gui = LocalPlayer.PlayerGui
    local old = gui:FindFirstChild("ASO_OmegaMenu")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ASO_OmegaMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = gui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 280)
    frame.Position = UDim2.new(0.5, -175, 0.4, -140)
    frame.BackgroundColor3 = Color3.fromRGB(8,8,22)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255,70,70)
    frame.Draggable = true
    frame.Active = true
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    -- Tiêu đề
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,32)
    title.Position = UDim2.new(0,0,0,5)
    title.BackgroundTransparency = 1
    title.Text = "⚡ ASO OMEGA V5"
    title.TextColor3 = Color3.fromRGB(255,100,100)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = frame

    -- Chọn Map (có thể nhập tên)
    local mapLabel = Instance.new("TextLabel")
    mapLabel.Size = UDim2.new(0.4, 0, 0, 28)
    mapLabel.Position = UDim2.new(0.05, 0, 0, 45)
    mapLabel.BackgroundTransparency = 1
    mapLabel.Text = "🗺️ Map:"
    mapLabel.TextColor3 = Color3.fromRGB(200,200,220)
    mapLabel.Font = Enum.Font.Gotham
    mapLabel.TextSize = 14
    mapLabel.TextXAlignment = Enum.TextXAlignment.Right
    mapLabel.Parent = frame

    local mapBox = Instance.new("TextBox")
    mapBox.Size = UDim2.new(0.5, 0, 0, 28)
    mapBox.Position = UDim2.new(0.45, 0, 0, 45)
    mapBox.BackgroundColor3 = Color3.fromRGB(30,30,50)
    mapBox.Text = Config.DefaultMap
    mapBox.TextColor3 = Color3.fromRGB(255,255,255)
    mapBox.Font = Enum.Font.Gotham
    mapBox.TextSize = 14
    mapBox.Parent = frame

    -- Chọn Chương (có thể nhập số hoặc tên)
    local chapterLabel = Instance.new("TextLabel")
    chapterLabel.Size = UDim2.new(0.4, 0, 0, 28)
    chapterLabel.Position = UDim2.new(0.05, 0, 0, 80)
    chapterLabel.BackgroundTransparency = 1
    chapterLabel.Text = "📖 Chương:"
    chapterLabel.TextColor3 = Color3.fromRGB(200,200,220)
    chapterLabel.Font = Enum.Font.Gotham
    chapterLabel.TextSize = 14
    chapterLabel.TextXAlignment = Enum.TextXAlignment.Right
    chapterLabel.Parent = frame

    local chapterBox = Instance.new("TextBox")
    chapterBox.Size = UDim2.new(0.5, 0, 0, 28)
    chapterBox.Position = UDim2.new(0.45, 0, 0, 80)
    chapterBox.BackgroundColor3 = Color3.fromRGB(30,30,50)
    chapterBox.Text = Config.DefaultChapter
    chapterBox.TextColor3 = Color3.fromRGB(255,255,255)
    chapterBox.Font = Enum.Font.Gotham
    chapterBox.TextSize = 14
    chapterBox.Parent = frame

    -- Nút BẮT ĐẦU
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0.4, 0, 0, 38)
    startBtn.Position = UDim2.new(0.05, 0, 0, 125)
    startBtn.BackgroundColor3 = Color3.fromRGB(50,200,50)
    startBtn.Text = "▶ BẮT ĐẦU"
    startBtn.TextColor3 = Color3.fromRGB(255,255,255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 15
    startBtn.Parent = frame
    startBtn.MouseButton1Click:Connect(function()
        local map = mapBox.Text ~= "" and mapBox.Text or Config.DefaultMap
        local chapter = chapterBox.Text ~= "" and chapterBox.Text or Config.DefaultChapter
        startFullMission(map, chapter)
    end)

    -- Nút DỪNG
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0.4, 0, 0, 38)
    stopBtn.Position = UDim2.new(0.55, 0, 0, 125)
    stopBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    stopBtn.Text = "■ DỪNG"
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 15
    stopBtn.Parent = frame
    stopBtn.MouseButton1Click:Connect(stopMission)

    -- Trạng thái
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.9, 0, 0, 25)
    status.Position = UDim2.new(0.05, 0, 0, 180)
    status.BackgroundTransparency = 1
    status.Text = "🟢 Sẵn sàng"
    status.TextColor3 = Color3.fromRGB(150,255,150)
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.Parent = frame

    -- Hướng dẫn
    local help = Instance.new("TextLabel")
    help.Size = UDim2.new(0.9, 0, 0, 30)
    help.Position = UDim2.new(0.05, 0, 0, 215)
    help.BackgroundTransparency = 1
    help.Text = "F9: Menu | F10: Bắt đầu | F11: Dừng"
    help.TextColor3 = Color3.fromRGB(180,180,200)
    help.Font = Enum.Font.Gotham
    help.TextSize = 12
    help.TextXAlignment = Enum.TextXAlignment.Center
    help.Parent = frame

    -- Phím tắt
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F9 then
            screenGui.Enabled = not screenGui.Enabled
        elseif input.KeyCode == Enum.KeyCode.F10 then
            local map = mapBox.Text ~= "" and mapBox.Text or Config.DefaultMap
            local chapter = chapterBox.Text ~= "" and chapterBox.Text or Config.DefaultChapter
            startFullMission(map, chapter)
        elseif input.KeyCode == Enum.KeyCode.F11 then
            stopMission()
        end
    end)

    print("[ASO] Omega V5 đã sẵn sàng! Chỉ huy có thể nhập map và chương bất kỳ.")
    return screenGui
end

-- ============================================
-- KHỞI CHẠY
-- ============================================
createMenu()
