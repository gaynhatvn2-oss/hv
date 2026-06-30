local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- =======================================================
-- ⚙️ KHỞI TẠO BIẾN CẤU HÌNH MẶC ĐỊNH
-- =======================================================
local AUTO_RUNNING = false
local CONFIG_MAP = "Làng cối gió"
local CONFIG_MODE = "Story"
local CONFIG_ACT = "Act 1"

-- Tọa độ kính chuẩn xác bạn đã quét được
local GLASS_POSITION = Vector3.new(-216.97752380371094, 11.390323638916016, -313.96240234375)

-- =======================================================
-- 🎨 THIẾT KẾ GIAO DIỆN MENU SETUP (GUI)
-- =======================================================
-- Xóa Menu cũ nếu lỡ chạy lại script
if CoreGui:FindFirstChild("AnimeDefendersSetup") then
    CoreGui.AnimeDefendersSetup:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnimeDefendersSetup"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Khung nền Menu chính
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UIDimensions and UIDimensions.new(0, 320, 0, 260) or UDim2.new(0, 320, 0, 260)
MainFrame.Position = UDim2.new(0.5, -160, 0.4, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Cho phép kéo menu di chuyển trên màn hình
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Tiêu đề Menu
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.Text = "MENU SETUP ANIME DEFENDERS"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Hàm tạo các nút nhập cấu hình nhanh (Helper)
local function createInputRow(labelName, defaultVal, yPos, callback)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 100, 0, 30)
    Label.Position = UDim2.new(0, 15, 0, yPos)
    Label.BackgroundTransparency = 1
    Label.Text = labelName .. ":"
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.SourceSans
    Label.Parent = MainFrame

    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(0, 180, 0, 30)
    TextBox.Position = UDim2.new(0, 125, 0, yPos)
    TextBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    TextBox.Text = defaultVal
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.TextSize = 14
    TextBox.Font = Enum.Font.SourceSans
    TextBox.BorderSizePixel = 0
    TextBox.Parent = MainFrame
    
    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 5)
    BoxCorner.Parent = TextBox

    TextBox.FocusLost:Connect(function()
        callback(TextBox.Text)
    end)
end

-- Tạo các dòng nhập thông số cấu hình
createInputRow("Chọn Bản Đồ", CONFIG_MAP, 60, function(val) CONFIG_MAP = val print("Đổi Map thành: " .. val) end)
createInputRow("Chế Độ Chơi", CONFIG_MODE, 105, function(val) CONFIG_MODE = val print("Đổi Chế độ thành: " .. val) end)
createInputRow("Cấp Độ / Act", CONFIG_ACT, 150, function(val) CONFIG_ACT = val print("Đổi Cấp độ thành: " .. val) end)

-- Nút Bắt đầu / Dừng Auto
local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(1, -30, 0, 40)
StartBtn.Position = UDim2.new(0, 15, 0, 200)
StartBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
StartBtn.Text = "BẮT ĐẦU AUTO"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.TextSize = 16
StartBtn.Font = Enum.Font.SourceSansBold
StartBtn.BorderSizePixel = 0
StartBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = StartBtn

-- =======================================================
-- ⚙️ LOGIC XỬ LÝ CHẠY TỰ ĐỘNG (ROUTINE)
-- =======================================================
local function autoClickLogic()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local worldsGui = playerGui:FindFirstChild("WorldsGui") or playerGui:FindFirstChild("ElevatorGui") or playerGui:FindFirstChild("LobbyGui")
    
    if worldsGui and worldsGui.Enabled == true then
        local mainFrame = worldsGui:FindFirstChild("MainFrame") or worldsGui:FindFirstChild("Frame")
        if not mainFrame then return end
        
        -- 1. Click chọn Map
        local mapScroll = mainFrame:FindFirstChild("Maps") or mainFrame:FindFirstChild("Worlds") or mainFrame:FindFirstChild("ScrollingFrame")
        if mapScroll then
            for _, child in pairs(mapScroll:GetChildren()) do
                if child:IsA("GuiButton") and (string.find(child.Name, CONFIG_MAP) or (child:FindFirstChild("Title") and string.find(child.Title.Text, CONFIG_MAP))) then
                    for _, conn in pairs(getconnections(child.MouseButton1Click)) do conn:Fire() end
                    task.wait(0.4)
                    break
                end
            end
        end
        
        -- 2. Click chọn Chế độ / Cấp độ
        local rightFrame = mainFrame:FindFirstChild("RightFrame") or mainFrame:FindFirstChild("InfoFrame") or mainFrame
        local modeBtn = rightFrame:FindFirstChild(CONFIG_MODE) or rightFrame:FindFirstChild("StoryButton") or rightFrame:FindFirstChild(CONFIG_ACT)
        if modeBtn and modeBtn:IsA("GuiButton") then
            for _, conn in pairs(getconnections(modeBtn.MouseButton1Click)) do conn:Fire() end
            task.wait(0.3)
        end
        
        -- 3. Bấm Vào Trận
        local startPlayBtn = rightFrame:FindFirstChild("StartButton") or rightFrame:FindFirstChild("PlayButton") or mainFrame:FindFirstChild("Start")
        if startPlayBtn and startPlayBtn:IsA("GuiButton") then
            for _, conn in pairs(getconnections(startPlayBtn.MouseButton1Click)) do conn:Fire() end
            print("[AUTO GUI] Đã bấm nút kích hoạt vào trận thành công!")
        end
    end
end

-- Vòng lặp luồng chính
task.spawn(function()
    while true do
        if AUTO_RUNNING then
            local character = LocalPlayer.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChild("Humanoid")
                
                if rootPart and humanoid then
                    -- Kiểm tra xem bảng UI chọn thế giới đã mở chưa
                    local playerGui = LocalPlayer.PlayerGui
                    local opened = playerGui:FindFirstChild("WorldsGui") or playerGui:FindFirstChild("ElevatorGui")
                    
                    if not (opened and opened.Enabled) then
                        -- Nếu UI chưa mở -> Tiến hành Teleport chạm kính để ép bung UI
                        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                        rootPart.CFrame = CFrame.new(GLASS_POSITION)
                        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                        
                        humanoid.Jump = true -- Nhảy nhẹ để chắc chắn kích hoạt chạm kính
                    else
                        -- Nếu UI đã mở -> Chạy hàm Click chọn thông số
                        autoClickLogic()
                    end
                end
            end
        end
        task.wait(0.5) -- Tốc độ lặp kiểm tra
    end
end)

-- Sự kiện nhấn nút Bắt đầu / Dừng trên Menu
StartBtn.MouseButton1Click:Connect(function()
    AUTO_RUNNING = not AUTO_RUNNING
    if AUTO_RUNNING then
        StartBtn.Text = "ĐANG CHẠY - BẤM ĐỂ DỪNG"
        StartBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        print("[SYSTEM] Đã kích hoạt chu trình Auto Setup!")
    else
        StartBtn.Text = "BẮT ĐẦU AUTO"
        StartBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        print("[SYSTEM] Đã tạm dừng Auto!")
    end
end)
