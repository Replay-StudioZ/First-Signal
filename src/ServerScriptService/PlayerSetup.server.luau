--!strict

local Players = game:GetService("Players")

local CONFIG = {
	NECK_C0 = CFrame.new(0, 0.8, 0),
	NECK_C1 = CFrame.new(0, -0.5, 0),

	LEG_DENSITY = 0.7,
	LEG_FRICTION = 0.8,
	LEG_ELASTICITY = 0,

	HIP_HEIGHT_OFFSET = 0.05,
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
	local layoutHead = character:WaitForChild("Head") :: BasePart
	local upperTorso = character:WaitForChild("UpperTorso") :: BasePart

	local success, playerModel = pcall(function()
		return Players:CreateHumanoidModelFromUserIdAsync(player.UserId)
	end)

	if not success or not playerModel then
		warn("Failed to load player model for: " .. player.Name)
		return false
	end

	local realHead = playerModel:FindFirstChild("Head") :: BasePart?
	if not realHead then
		warn("The player model has no head: " .. player.Name)
		playerModel:Destroy()
		return false
	end

	realHead.Parent = nil
	
	realHead.CFrame = layoutHead.CFrame
	realHead.CanCollide = layoutHead.CanCollide

	local oldNeck = layoutHead:FindFirstChild("Neck") or upperTorso:FindFirstChild("Neck")
	if oldNeck then oldNeck:Destroy() end

	layoutHead:Destroy()

	realHead.Parent = character
	realHead:SetNetworkOwner(player)

	for _, child in ipairs(realHead:GetChildren()) do
		if child:IsA("Motor6D") and child.Name == "Neck" then
			child:Destroy()
		end
	end

	for _, child in ipairs(upperTorso:GetChildren()) do
		if child:IsA("Motor6D") and child.Name == "Neck" then
			child:Destroy()
		end
	end

	local newNeck = Instance.new("Motor6D")
	newNeck.Name = "Neck"
	newNeck.Part0 = upperTorso
	newNeck.Part1 = realHead
	newNeck.C0 = CONFIG.NECK_C0
	newNeck.C1 = CONFIG.NECK_C1
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

	return true
end

local function calculateHipHeight(humanoid: Humanoid, character: Model)
end

local function configureLegPhysics(character: Model)
	local legPartNames = { "RightUpperLeg", "LeftUpperLeg", "RightLowerLeg", "LeftLowerLeg", "RightFoot", "LeftFoot" }

	for _, partName in ipairs(legPartNames) do
		local part = character:FindFirstChild(partName) :: BasePart?

		if part then
			part.CustomPhysicalProperties = PhysicalProperties.new(CONFIG.LEG_DENSITY, CONFIG.LEG_FRICTION, CONFIG.LEG_ELASTICITY, 0, 0)
		end
	end
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	configureHumanoid(humanoid)

	local headSuccess = replaceHeadWithReal(player, character)
	if not headSuccess then
		warn("Skipping physics setup for " .. player.Name .. " due to an issue with the head")
		return
	end

	calculateHipHeight(humanoid, character)
	configureLegPhysics(character)

	humanoid.Died:Connect(function()
		humanoid.PlatformStand = true
	end)
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		task.spawn(onCharacterAdded, player, character)
	end)
end)