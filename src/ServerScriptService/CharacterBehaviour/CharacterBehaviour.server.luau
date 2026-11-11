--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local characterBehavior = ReplicatedStorage:WaitForChild("CharacterBehavior")
local events = characterBehavior:WaitForChild("Events")

local HeadLookEvent = events:WaitForChild("HeadLookEvent")

local baseNeckC1 = CFrame.new(0, -0.5, 0)

HeadLookEvent.OnServerEvent:Connect(function(player: Player, yaw: number, pitch: number)
	local character = player.Character
	if not character then return end

	local upperTorso = character:FindFirstChild("UpperTorso")
	if not upperTorso then return end

	local neck = upperTorso:FindFirstChild("Neck")
	if not neck or not neck:IsA("Motor6D") then return end

	neck.C1 = baseNeckC1 * CFrame.Angles(
		math.rad(math.clamp(-pitch, -60, 60)), 
		math.rad(math.clamp(-yaw, -90, 90)), 
		0
	)
end)