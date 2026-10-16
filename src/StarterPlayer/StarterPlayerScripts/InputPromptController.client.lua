local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local currentPlatform = nil
local AssetData = require(ReplicatedStorage:WaitForChild("AssetData"))

local interactIcon = ReplicatedStorage.Interact:WaitForChild("InteractGui"):FindFirstChildOfClass("Frame"):FindFirstChildOfClass("ImageLabel")

local function updateIcons()
	if interactIcon and currentPlatform then
		local newImageId = AssetData.Icons.CrossPlatformIcons.Interact[currentPlatform]
		
		if newImageId then
			interactIcon.Image = newImageId
		end
	end
end

local function getPlatformFromInput(inputType)
	if inputType == Enum.UserInputType.Gamepad1 or inputType == Enum.UserInputType.Gamepad2 then
		return "Console"
	elseif inputType == Enum.UserInputType.Touch then
		return "Mobile"
	elseif inputType == Enum.UserInputType.Keyboard or inputType == Enum.UserInputType.MouseMovement or inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.MouseButton2 then
		return "PC"
	end
	
	return nil
end

local function onLastInputTypeChanged(lastInputType)
	local platform = getPlatformFromInput(lastInputType)
	
	if platform and platform ~= currentPlatform then
		currentPlatform = platform
		print("Platform changed on: " .. currentPlatform)
		
		updateIcons()
	end
end

UserInputService.LastInputTypeChanged:Connect(onLastInputTypeChanged)

local success, lastType = pcall(function()
	return UserInputService:GetLastInputType()
end)

if success and lastType then
	onLastInputTypeChanged(lastType)
end