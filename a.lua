-- ============================================
-- TELEPORT THÔNG MINH - CÓ PHÁT HIỆN SÀN
-- ============================================
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

    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then
        warn("[ASO] Không tìm thấy Humanoid.")
        return false
    end

    -- === Bước 1: Tìm bề mặt vững chắc dưới chân ===
    local function findFloor(position)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

        -- Đặt tia từ vị trí đích xuống dưới 50 đơn vị
        local rayOrigin = position + Vector3.new(0, 5, 0)
        local rayDirection = Vector3.new(0, -50, 0)
        local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

        if result then
            -- Lấy điểm va chạm và thêm một khoảng cách an toàn
            local hitPoint = result.Position
            return hitPoint + Vector3.new(0, 2, 0) -- Đứng lên trên bề mặt 2 đơn vị
        end

        return nil
    end

    -- === Bước 2: Xác định vị trí đáp cuối cùng ===
    local targetPos = Vector3.new(destData.X, destData.Y, destData.Z)
    local floorPos = findFloor(targetPos)

    if floorPos then
        -- Nếu tìm thấy sàn, đáp xuống đó
        targetPos = floorPos
        print("[ASO] Tìm thấy bề mặt vững chắc tại " .. tostring(targetPos))
    else
        -- Nếu không tìm thấy sàn, thử dịch chuyển lên cao hơn để tránh rơi
        targetPos = targetPos + Vector3.new(0, 15, 0)
        warn("[ASO] Không tìm thấy sàn. Di chuyển lên cao để tránh rơi.")
    end

    -- === Bước 3: Teleport đến vị trí đã điều chỉnh ===
    local targetCF = CFrame.new(targetPos)

    if Config.StealthMode then
        -- Di chuyển từ từ để tránh bị phát hiện
        local startPos = root.Position
        local steps = math.random(8, 15)
        for i = 1, steps do
            local t = i / steps
            local interpolated = startPos:Lerp(targetPos, t)
            root.CFrame = CFrame.new(interpolated)
            local delay = Config.RandomDelayMin + math.random() * (Config.RandomDelayMax - Config.RandomDelayMin)
            task.wait(delay)
        end
    else
        root.CFrame = targetCF
    end

    -- === Bước 4: Kiểm tra và giữ nhân vật không bị rơi ===
    task.wait(0.5)
    local confirmPos = root.Position
    if (confirmPos - targetPos).Magnitude > 5 then
        -- Nếu bị đẩy ra xa (có thể do game ghim lại), thử teleport lần nữa
        warn("[ASO] Bị dịch chuyển khỏi vị trí đích. Thử lại...")
        root.CFrame = CFrame.new(targetPos)
        task.wait(0.3)
    end

    -- === Bước 5: Xác nhận đã đến nơi ===
    local startTime = tick()
    while (root.Position - targetPos).Magnitude > 3 and tick() - startTime < Config.ConfirmTimeout do
        root.CFrame = CFrame.new(targetPos)
        task.wait(0.1)
    end

    if (root.Position - targetPos).Magnitude <= 3 then
        print("[ASO] Đã teleport thành công đến " .. destination)
        State.CurrentPosition = destination
        return true
    else
        warn("[ASO] Teleport thất bại. Có thể bị chặn bởi hệ thống chống gian lận.")
        return false
    end
end
