-- ============================================
-- ASO OMEGA V2 – MENU THÔNG MINH + SỰ KIỆN ĐÚNG
-- ============================================

local function createOmegaMenu()
    local old = LocalPlayer.PlayerGui:FindFirstChild("ASO_OmegaMenu")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ASO_OmegaMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer.PlayerGui

    -- Khung chính
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 220)
    frame.Position = UDim2.new(0.5, -150, 0.5, -110)
    frame.BackgroundColor3 = Color3.fromRGB(8, 8, 22)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 70, 70)
    frame.Draggable = true
    frame.Active = true
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    -- Tiêu đề
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 32)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "⚡ ASO OMEGA V2"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = frame

    -- Nút chọn cấp độ (dựa trên ảnh: Cáp 1, Cáp 5, Cáp 20, Cáp 50)
    local levels = {"Cáp 1", "Cáp 5", "Cáp 20", "Cáp 50"}
    local yPos = 45
    local btnWidth = 65
    local spacing = 75
    local startX = (frame.Size.X.Offset - (btnWidth * #levels + spacing * (#levels - 1))) / 2

    for i, lv in ipairs(levels) do
        local lvBtn = Instance.new("TextButton")
        lvBtn.Size = UDim2.new(0, btnWidth, 0, 28)
        lvBtn.Position = UDim2.new(0, startX + (i-1) * (btnWidth + spacing), 0, yPos)
        lvBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
        lvBtn.Text = lv
        lvBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        lvBtn.Font = Enum.Font.GothamBold
        lvBtn.TextSize = 13
        lvBtn.Parent = frame

        -- Gán sự kiện cho từng nút cấp độ
        lvBtn.MouseButton1Click:Connect(function()
            print("[ASO] Đã chọn cấp độ: " .. lv)
            omegaOperation(lv)  -- Gọi hàm chính với cấp đã chọn
        end)
    end

    -- Nút VÀO TRẬN (nút chính, mặc định Cáp 1)
    local enterBtn = Instance.new("TextButton")
    enterBtn.Size = UDim2.new(0, 120, 0, 36)
    enterBtn.Position = UDim2.new(0.15, 0, 0, yPos + 38)
    enterBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    enterBtn.Text = "▶ VÀO TRẬN"
    enterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    enterBtn.Font = Enum.Font.GothamBold
    enterBtn.TextSize = 14
    enterBtn.Parent = frame

    enterBtn.MouseButton1Click:Connect(function()
        print("[ASO] Vào trận mặc định Cáp 1")
        omegaOperation("Cáp 1")
    end)

    -- Nút DỪNG
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, 100, 0, 36)
    stopBtn.Position = UDim2.new(0.55, 0, 0, yPos + 38)
    stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    stopBtn.Text = "■ DỪNG"
    stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 14
    stopBtn.Parent = frame

    stopBtn.MouseButton1Click:Connect(function()
        print("[ASO] Lệnh dừng khẩn cấp")
        stopOmega()
    end)

    -- Trạng thái
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.9, 0, 0, 25)
    status.Position = UDim2.new(0.05, 0, 0, yPos + 85)
    status.BackgroundTransparency = 1
    status.Text = "🟢 Sẵn sàng"
    status.TextColor3 = Color3.fromRGB(150, 255, 150)
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.Parent = frame

    -- Cập nhật trạng thái
    local oldEnter = omegaOperation
    omegaOperation = function(level)
        status.Text = "🔵 Đang vào trận..."
        status.TextColor3 = Color3.fromRGB(255, 200, 50)
        local success = oldEnter(level)
        if success then
            status.Text = "🟢 Đã vào trận"
            status.TextColor3 = Color3.fromRGB(150, 255, 150)
        else
            status.Text = "🔴 Lỗi vào trận"
            status.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end

    local oldStop = stopOmega
    stopOmega = function()
        status.Text = "🟠 Đang dừng..."
        status.TextColor3 = Color3.fromRGB(255, 150, 50)
        oldStop()
        status.Text = "🟢 Đã dừng"
        status.TextColor3 = Color3.fromRGB(150, 255, 150)
    end

    return screenGui
end

-- ============================================
-- GỌI LẠI MENU MỚI
-- ============================================
-- Xóa menu cũ và tạo mới
createOmegaMenu()
print("[ASO] Menu Omega V2 đã được cập nhật. Nhấn F9 để ẩn/hiện.")
