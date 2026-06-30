--[[
    ASO-PROTOCOL v5.2 – ANIME DEFENDERS CHAMBER FORCE JOIN
    - Tự động quét sâu vào cấu trúc map để tìm phòng/buồng (Booths) trống.
    - Ép tọa độ nhân vật vào chính xác trung tâm lòng buồng để Server kích hoạt Map.
    - Tự động Click chuột vào nút Chơi (Play) sau khi bảng Map xuất hiện.
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
    print("[ASO] Đang quét cấu trúc sảnh để tìm buồng đấu trống...")
    
    -- Quy trình 1: Quét các thư mục quản lý buồng phòng phổ biến của Anime DF
    local boothFolders = {"Booths", "Lobby", "Portals", "Chambers", "Gates"}
    for _, folderName in ipairs(boothFolders) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, booth in ipairs(folder:GetChildren()) do
                if booth:IsA("Model") then
                    -- Kiểm tra giá trị đếm người chơi ngầm trong buồng của game
                    local count = booth:FindFirstChild("PlayersInside") or booth:FindFirstChild("Count")
                    if not count or (count:IsA("IntValue") and count.Value < 4) then
                        return booth:GetPivot()
                    end
                end
            end
        end
    end
    
    -- Quy trình 2: Quét diện rộng toàn bộ Workspace tìm khối MD_Portal (Tên log hệ thống)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj.Name == "MD_Portal" or obj.Name:lower():find("booth") or obj.Name == "PlayGate") and obj:IsA("Model") then
            local count = obj:FindFirstChild("PlayersInside") or obj:FindFirstChild("Count")
            if not count or (count:IsA("IntValue") and count.Value < 4) then
                return obj:GetPivot()
            end
        end
    end
    
    -- Tọa độ dự phòng khẩn cấp nếu game ẩn hoàn toàn cấu trúc model (Khu vực buồng sảnh chính)
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
    print("[ASO] Tiến hành đặt nhân vật vào buồng: ", tostring(targetCFrame.Position))
    
    -- Tắt va chạm tạm thời để nhân vật lọt hẳn vào trong vùng cảm biến của buồng đấu
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    
    -- Đưa nhân vật vào lòng buồng (Cộng thêm 1.5 để chân chạm sàn buồng chuẩn xác)
    rootPart.CFrame = targetCFrame * CFrame.new(0, 1.5, 0)
    task.wait(1.5) -- Chờ máy chủ nhận diện bạn đã vào buồng và gửi bảng GUI xuống máy

    -- Bước 2: Tự động dò tìm bảng thế giới để bấm nút Chơi
    local guiNames = {"Play", "MainGui", "Window", "LobbyGui", "MapSelect", "BoothGui"}
    for _, name in ipairs(guiNames) do
        local targetGui = playerGui:FindFirstChild(name, true)
        if targetGui and targetGui.Enabled then
            for _, btn in ipairs(targetGui:GetDescendants()) do
                -- Nhận diện chính xác nút bấm Chơi / Start / Play
                if btn:IsA("GuiButton") and btn.Visible and (
                   btn.Name == "Start" or btn.Name == "Play" or btn.Name == "Join" or 
                   btn.Text:find("Chơi") or btn.Text:find("Start") or btn.Text:find("Play")
                ) then
                    print("[ASO] Đã tìm thấy nút vào trận! Đang thực hiện giả lập bấm chuột...")
                    
                    local absolutePos = btn.AbsolutePosition
                    local absoluteSize = btn.AbsoluteSize
                    -- Tính toán tọa độ tâm nút kèm sai số thanh công cụ Roblox
                    local clickX = absolutePos.X + (absoluteSize.X / 2)
                    local clickY = absolutePos.Y + (absoluteSize.Y / 2) + 36
                    
                    VirtualInputManager:SendMouseButtonEvent(Vector2.new(clickX, clickY), 0, true, 0)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(Vector2.new(clickX, clickY), 0, false, 0)
                    return true
                end
            end
        end
    end
    return false
end

-- Vòng lặp duy trì tự động quét sảnh chờ
task.spawn(function()
    while true do
        -- ID sảnh chờ mặc định gốc của Anime Defenders
        local isInsideLobby = game.PlaceId == 17019449781 or game.PlaceId == 0
        if not isInsideLobby then
            print("[ASO] Nhân vật đã chuyển map vào phòng đấu thành công!")
            break
        end
        
        local success = forceJoinMatch()
        if success then break end
        task.wait(3) -- Quét lại sau mỗi 3 giây nếu chưa vào được trận
    end
end)
