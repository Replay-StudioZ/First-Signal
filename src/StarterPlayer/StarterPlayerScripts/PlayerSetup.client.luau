local StarterGui = game:GetService("StarterGui") 
local Players = game:GetService("Players") 
local player = Players.LocalPlayer

-- Disable ResetButtonCallback
local success 
repeat 
	success = pcall(function() StarterGui:SetCore("ResetButtonCallback", false) end) 
	task.wait(0.1)
until success == true 

-- Disable Backpack
repeat 
	success = pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end) 
	task.wait(0.1)
until success == true 

-- Setup Character (Jumping and Shadows)
local function setupCharacter(character)
	if not character:IsDescendantOf(workspace) then
		character.AncestryChanged:Wait()
	end

	task.wait(0.1)

	-- Disable Jumping
	local humanoid = character:WaitForChild("Humanoid") 
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) 
	humanoid.UseJumpPower = false 
	humanoid.JumpHeight = 0 

	-- Remove player shadow
	for _, part in ipairs(character:GetDescendants()) do 
		if part:IsA("BasePart") then 
			part.CastShadow = false 
		end 
	end 

	character.DescendantAdded:Connect(function(descendant) 
		if descendant:IsA("BasePart") then 
			descendant.CastShadow = false 
		end 
	end)
end 

if player.Character then 
	setupCharacter(player.Character) 
end 

player.CharacterAdded:Connect(setupCharacter)