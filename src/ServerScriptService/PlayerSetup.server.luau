local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local layoutHead = character:WaitForChild("Head")
		local humanoid = character:WaitForChild("Humanoid")
		local upperTorso = character:WaitForChild("UpperTorso")

		if not layoutHead or not humanoid or not upperTorso then return end

		humanoid.RigType = Enum.HumanoidRigType.R15
		humanoid.BreakJointsOnDeath = false
		humanoid.AutoJumpEnabled = false
		humanoid.UseJumpPower = false
		humanoid.JumpPower = 0
		humanoid.NameDisplayDistance = 0
		humanoid.HealthDisplayDistance = 0
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.NameOcclusion = Enum.NameOcclusion.NoOcclusion

		local success, playerModel = pcall(function()
			return Players:CreateHumanoidModelFromUserIdAsync(player.UserId)
		end)

		if not success or not playerModel then return end

		local realHead = playerModel:FindFirstChild("Head")
		if not realHead then
			playerModel:Destroy()
			return
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
			if child:IsA("Motor6D") and child.Name == "Neck" then child:Destroy() end
		end
		for _, child in ipairs(upperTorso:GetChildren()) do
			if child:IsA("Motor6D") and child.Name == "Neck" then child:Destroy() end
		end

		local newNeck = Instance.new("Motor6D")
		newNeck.Name = "Neck"
		newNeck.Part0 = upperTorso
		newNeck.Part1 = realHead
		newNeck.C0 = CFrame.new(0, 0.8, 0)
		newNeck.C1 = CFrame.new(0, -0.5, 0)
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

		-- HipHeight Calculation
		local leftLowerLeg = character:FindFirstChild("LeftLowerLeg")
		local leftFoot = character:FindFirstChild("LeftFoot")

		if leftLowerLeg and leftFoot then
			humanoid.AutomaticScalingEnabled = false

			local lowerLegHeight = leftLowerLeg.Size.Y
			local footHeight = leftFoot.Size.Y

			humanoid.HipHeight = lowerLegHeight + footHeight + 0.4
		end

		humanoid.Died:Connect(function()
			humanoid.PlatformStand = true
		end)
	end)
end)