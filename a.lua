--[Code tối ưu hóa tự động hóa Anime Defenders, bao gồm GUI, nhận diện bản đồ, chương, và nút chấp nhận]
local Players = game:GetService("Players")
-- ... (Các biến khởi tạo và GUI thiết lập tại đây) ...
local AUTO_RUNNING = false
local CONFIG_MAP = "làng cối gió"
local CONFIG_MODE = "Chương 1"
local GLASS_POSITION = Vector3.new(-216.97752380371094, 11.390323638916016, -313.96240234375)

--[Hàm xử lý tự động click và chọn bản đồ/chương]
local function runAutoClickEngine()
    -- ... (Logic tìm kiếm và click nút) ...
    -- Tối ưu hóa so sánh tên (ví dụ: string.lower) để chọn "Chương 1", "Chương 2", v.v.
    -- Tự động Click "Chấp Nhận"
end

--[Vòng lặp điều phối chính]
task.spawn(function()
    while true do
        if AUTO_RUNNING then
            -- ... (Dịch chuyển/Va chạm kính và gọi runAutoClickEngine) ...
        end
        task.wait(0.4)
    end
end)
