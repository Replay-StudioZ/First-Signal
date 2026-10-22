--!strict

local Players = game:GetService("Players")

local CONFIG = {
	HIP_HEIGHT_OFFSET = 0
}

local function configureHumanoid(humanoid: Humanoid)
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.BreakJointsOnDeath = false
	humanoid.AutoJumpEnabled = false
	humanoid.UseJumpPower = false
	humanoid.JumpPower = 0
	humanoid.NameDisplayDistance = 0
	humanoid.HealthDisplayDistance = 0
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.NameOcclusion = Enum.NameOcclusion.NoOcclusion
end

local function replaceHeadWithReal(player: Player, character: Model): boolean
	local layoutHead = character:FindFirstChild("Head") :: BasePart?
	local upperTorso = character:FindFirstChild("UpperTorso") :: BasePart?
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not layoutHead or not upperTorso or not hrp then return false end

	hrp.Anchored = true

	local success, playerModel = pcall(function()
		return Players:CreateHumanoidModelFromUserIdAsync(player.UserId)
	end)

	if not success or not playerModel then
		warn("Failed to load player model for: " .. player.Name)
		hrp.Anchored = false
		return false
	end

	local realHead = playerModel:FindFirstChild("Head") :: BasePart?
	if not realHead then
		warn("The player model has not head: " .. player.Name)
		playerModel:Destroy()
		hrp.Anchored = false
		return false
	end

	local targetCFrame = layoutHead.CFrame
	local canCollide = layoutHead.CanCollide

	local oldNeck = layoutHead:FindFirstChild("Neck") or upperTorso:FindFirstChild("Neck")
	if oldNeck then oldNeck:Destroy() end

	for _, child in ipairs(upperTorso:GetChildren()) do
		if child:IsA("Motor6D") and child.Name == "Neck" then
			child:Destroy()
		end
	end

	layoutHead:Destroy()

	realHead.Parent = character
	realHead.CFrame = targetCFrame
	realHead.CanCollide = canCollide
	realHead:SetNetworkOwner(player)

	local neckAttUpper = upperTorso:FindFirstChild("NeckRigAttachment") :: Attachment?
	local neckAttHead = realHead:FindFirstChild("NeckAttachment") :: Attachment?

	local newNeck = Instance.new("Motor6D")
	newNeck.Name = "Neck"
	newNeck.Part0 = upperTorso
	newNeck.Part1 = realHead

	if neckAttUpper and neckAttHead then
		newNeck.C0 = neckAttUpper.CFrame
		newNeck.C1 = neckAttHead.CFrame
	else
		newNeck.C0 = CFrame.new(0, 0.8, 0)
		newNeck.C1 = CFrame.new(0, -0.5, 0)
	end

	newNeck.Parent = upperTorso

	for _, object in ipairs(playerModel:GetChildren()) do
		if object:IsA("Accessory") then
			local handle = object:FindFirstChild("Handle")

			if handle and (handle:FindFirstChild("HatAttachment") or handle:FindFirstChild("HairAttachment") or handle:FindFirstChild("FaceFrontAttachment") or handle:FindFirstChild("FaceCenterAttachment")) then
				object.Parent = character
			end
		end
	end

	playerModel:Destroy()

	hrp.Anchored = false

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end

	return true
end

local function calculateHipHeight(humanoid: Humanoid, character: Model)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local lowestY = math.huge
	local footPartNames = { "RightFoot", "LeftFoot" }

	for _, partName in ipairs(footPartNames) do
		local part = character:FindFirstChild(partName) :: BasePart?

		if part then
			local bottomY = part.Position.Y - (part.Size.Y / 2)

			if bottomY < lowestY then
				lowestY = bottomY
			end
		end
	end

	if lowestY == math.huge then return end

	local hrpBottomY = hrp.Position.Y - (hrp.Size.Y / 2)
	local calculatedHeight = (hrpBottomY - lowestY) + CONFIG.HIP_HEIGHT_OFFSET

	if calculatedHeight > 0 then
		humanoid.HipHeight = calculatedHeight

		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		task.wait(0.05)
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end
end

local function onCharacterAdded(player: Player, character: Model)
	task.wait(0.1)
	
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	configureHumanoid(humanoid)

	local headSuccess = replaceHeadWithReal(player, character)
	if not headSuccess then
		warn("Skipping physics setup for " .. player.Name .. " due to an issue with the head")
		return
	end

	calculateHipHeight(humanoid, character)

	humanoid.Died:Connect(function()
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end)
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		task.spawn(onCharacterAdded, player, character)
	end)
end)