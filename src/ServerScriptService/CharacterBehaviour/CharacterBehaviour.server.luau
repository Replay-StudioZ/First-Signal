local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HeadLookEvent = ReplicatedStorage:WaitForChild("CharacterBehavior"):WaitForChild("Events"):WaitForChild("HeadLookEvent")

local baseNeckC1 = CFrame.new(0, -0.5, 0)

HeadLookEvent.OnServerEvent:Connect(function(player, yaw, pitch)
    local neck = player.Character and player.Character:FindFirstChild("UpperTorso"):FindFirstChild("Neck")

    if neck and neck:IsA("Motor6D") then
        neck.C1 = baseNeckC1 * CFrame.Angles(math.rad(math.clamp(-pitch, -60, 60)), math.rad(math.clamp(-yaw, -90, 90)), 0)
    end
end)