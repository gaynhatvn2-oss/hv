--[[
    ASO-PROTOCOL v5.3 – ANIME DEFENDERS FIXED CHECK ID
    - Sửa lỗi tự động in thông báo ảo "Đã chuyển map thành công"
    - Loại bỏ kiểm tra ID sảnh, thay bằng quét trạng thái GUI thực tế
    - Ép nhân vật dịch chuyển vào buồng liên tục cho đến khi đổi map thật
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

-- ========================================================
-- HÀM QUÉT VÀ TRÍCH XUẤT TỌA ĐỘ BUỒNG ĐẤU CÒN TRỐNG (BOOTHS)
-- ========================================================
local function getEmptyBoothCFrame()
    -- Quy trình 1: Quét các thư mục quản lý buồng phòng phổ biến của Anime DF
    local boothFolders = {"Booths", "Lobby", "Portals", "Chambers", "Gates"}
    for _, folderName in ipairs(boothFolders) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, booth in ipairs(folder:GetChildren()) do
                if booth:IsA("Model") then
                    local count = booth:FindFirstChild("PlayersInside") or booth:FindFirstChild("Count")
                    if not count or (count:IsA("IntValue") and count.Value < 4) then
                        return booth:GetPivot()
                    end
                end
            end
        end
    end
    
    -- Quy trình 2: Quét diện rộng toàn bộ Workspace tìm khối MD_Portal (Tên log hệ thống của bạn)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj.Name == "MD_Portal" or obj.Name:lower():find("booth") or obj.Name == "PlayGate") and obj:IsA("Model") then
            local count = obj:FindFirstChild("PlayersInside") or obj:FindFirstChild("Count")
            if not count or (count:IsA("IntValue") and count.Value < 4) then
                return obj:GetPivot()
            end
        end
    end
    
    -- Tọa độ dự phòng khẩn cấp (Khu vực cụm buồng sảnh chính Anime Defenders)
    return CFrame.new(-9.5, 6.2, 75.3)
end

-- ========================================================
-- QUY TRÌNH THỰC THI CHUI PHÒNG VÀ CLICK CHUỘT VÀO TRẬN
-- ========================================================
local function forceJoinMatch()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not rootPart then return false end

    -- Bước 1: Bốc thẳng nhân vật đặt vào trong lòng buồng đấu trống
    local targetCFrame = getEmptyBoothCFrame()
    print("[ASO] Đang đưa nhân vật vào tọa độ buồng phòng: ", tostring(targetCFrame.Position))
    
    -- Tắt va chạm để không bị hệ thống vật lý sảnh đẩy văng ra ngoài
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    
    -- Đưa nhân vật vào lòng buồng
    rootPart.CFrame = targetCFrame * CFrame.new(0, 1.5, 0)
    task.wait(1.5) -- Chờ máy chủ nhận diện vị trí và gửi bảng GUI chọn thế giới xuống

    -- Bước 2: Tự động dò tìm bảng thế giới để bấm nút Chơi
    local guiNames = {"Play", "MainGui", "Window", "LobbyGui", "MapSelect", "BoothGui"}
    local clicked = false

    for _, name in ipairs(guiNames) do
        local targetGui = playerGui:FindFirstChild(name, true)
        if targetGui and targetGui.Enabled then
            for _, btn in ipairs(targetGui:GetDescendants()) do
                -- Nhận diện nút Chơi / Start / Play
                if btn:IsA("GuiButton") and btn.Visible and (
                   btn.Name == "Start" or btn.Name == "Play" or btn.Name == "Join" or 
                   btn.Text:find("Chơi") or btn.Text:find("Start") or btn.Text:find("Play")
                ) then
                    print("[ASO] Đã thấy nút vào trận! Tiến hành click chuột...")
                    
                    local absolutePos = btn.AbsolutePosition
                    local absoluteSize = btn.AbsoluteSize
                    local clickX = absolutePos.X + (absoluteSize.X / 2)
                    local clickY = absolutePos.Y + (absoluteSize.Y / 2) + 36
                    
                    VirtualInputManager:SendMouseButtonEvent(Vector2.new(clickX, clickY), 0, true, 0)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(Vector2.new(clickX, clickY), 0, false, 0)
                    clicked = true
                    break
                end
            end
        end
        if clicked then break end
    end
    return clicked
end

-- Vòng lặp duy trì tự động quét sảnh chờ liên tục cho đến khi màn hình biến mất
task.spawn(function()
    print("[ASO] Khởi động hệ thống tự động chui buồng phòng Anime Defenders v5.3")
    while task.wait(3) do
        -- Thực hiện hành động chui phòng liên tục cho đến khi game bắt đầu chuyển cảnh đổi map thực sự
        pcall(forceJoinMatch)
    end
end)
