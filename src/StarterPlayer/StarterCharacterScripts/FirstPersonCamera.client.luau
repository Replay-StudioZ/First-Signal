local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CameraManager = require(ReplicatedStorage.Camera:WaitForChild("CameraManager"))
local player = Players.LocalPlayer

local renderConnection = nil

local function onCharacterAdded(character)
	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not rootPart then return end

	CameraManager.enable()

	if renderConnection then
		renderConnection:Disconnect()
	end

	renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if character and character:FindFirstChild("HumanoidRootPart") then
			CameraManager.update(character, deltaTime)
		end
	end)
end

local function onCharacterRemoving()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	CameraManager.disable()
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(onCharacterRemoving)