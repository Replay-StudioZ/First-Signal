local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local FirstPerson = {}

local camera = Workspace.CurrentCamera

local Inputs = require(ReplicatedStorage:WaitForChild("Input"):WaitForChild("Inputs"))
local HeadLookEvent = ReplicatedStorage:WaitForChild("CharacterBehavior"):WaitForChild("Events"):WaitForChild("HeadLookEvent")
local PlayerModule = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

FirstPerson.Sensitivity = 0.4
FirstPerson.Smoothness = 0.2
FirstPerson.InvertY = false
FirstPerson.InvertX = false
FirstPerson.FreeLookMode = "Hold"

local yaw = 0
local pitch = 0
local smoothYaw = 0
local smoothPitch = 0

local freeLookYaw = 0
local freeLookPitch = 0
local smoothFreeLookYaw = 0
local smoothFreeLookPitch = 0
local smoothHeadYaw = 0
local smoothHeadPitch = 0

local baseYaw = 0
local basePitch = 0

local currentCharacter = nil
local isHeadTurnActive = false

local lastServerFireTime = 0

local function HideHeadAndAccessory(character)
	local head = character:FindFirstChild("Head")
	if not head then return end
	head.LocalTransparencyModifier = 1
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle then
				handle.LocalTransparencyModifier = 1
			end
		end
	end
end

local function UpdateCamera(rootPart)
	freeLookYaw = freeLookYaw * 0.85
	freeLookPitch = freeLookPitch * 0.85

	smoothYaw = smoothYaw + (yaw - smoothYaw) * FirstPerson.Smoothness
	smoothPitch = smoothPitch + (pitch - smoothPitch) * FirstPerson.Smoothness

	smoothFreeLookYaw = smoothFreeLookYaw + (freeLookYaw - smoothFreeLookYaw) * FirstPerson.Smoothness
	smoothFreeLookPitch = smoothFreeLookPitch + (freeLookPitch - smoothFreeLookPitch) * FirstPerson.Smoothness

	local finalCameraYaw = smoothYaw + smoothFreeLookYaw
	local finalCameraPitch = smoothPitch + smoothFreeLookPitch

	local lookDirection = CFrame.Angles(0, math.rad(smoothYaw), 0).LookVector
	local eyeOffset = Vector3.new(0, 2, 0) + lookDirection * 0.75
	local cameraPosition = rootPart.Position + eyeOffset

	local cameraRotation = CFrame.Angles(0, math.rad(finalCameraYaw), 0) * CFrame.Angles(math.rad(finalCameraPitch), 0, 0)
	camera.CFrame = CFrame.new(cameraPosition) * cameraRotation

	rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(smoothYaw), 0)
end

local function HeadRotation(rootPart, humanoid)
	local totalYaw = baseYaw + freeLookYaw
	totalYaw = math.clamp(totalYaw, baseYaw - 60, baseYaw + 60)
	freeLookYaw = totalYaw - baseYaw

	local totalPitch = basePitch + freeLookPitch
	totalPitch = math.clamp(totalPitch, -89.9, 89.9)
	freeLookPitch = totalPitch - basePitch

	smoothFreeLookYaw = smoothFreeLookYaw + (freeLookYaw - smoothFreeLookYaw) * FirstPerson.Smoothness
	smoothFreeLookPitch = smoothFreeLookPitch + (freeLookPitch - smoothFreeLookPitch) * FirstPerson.Smoothness

	smoothYaw = smoothYaw + (yaw - smoothYaw) * FirstPerson.Smoothness
	smoothPitch = smoothPitch + (pitch - smoothPitch) * FirstPerson.Smoothness

	local finalCameraYaw = baseYaw + smoothFreeLookYaw
	local finalCameraPitch = basePitch + smoothFreeLookPitch

	local lookDirection = CFrame.Angles(0, math.rad(smoothYaw), 0).LookVector
	local eyeOffset = Vector3.new(0, 2, 0) + lookDirection * 0.75
	local cameraPosition = rootPart.Position + eyeOffset

	local cameraRotation = CFrame.Angles(0, math.rad(finalCameraYaw), 0) * CFrame.Angles(math.rad(finalCameraPitch), 0, 0)
	camera.CFrame = CFrame.new(cameraPosition) * cameraRotation

	if humanoid and humanoid.Parent then
		local inputVector = Controls:GetMoveVector()

		if inputVector.Magnitude > 0 then
			local forward = CFrame.Angles(0, math.rad(baseYaw), 0).LookVector
			local right = CFrame.Angles(0, math.rad(baseYaw), 0).RightVector

			local moveVector = (forward * -inputVector.Z) + (right * inputVector.X)
			humanoid:Move(moveVector.Unit, false)
		end
	end
end

local function ProcessGamepadInput()
	local gamepadState = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
	if not gamepadState then return end

	for _, input in ipairs(gamepadState) do
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			local pos = input.Position
			local deadzone = 0.15

			if pos.Magnitude > deadzone then
				local sensitivity = FirstPerson.Sensitivity * 5
				local invertYMultiplier = FirstPerson.InvertY and -1 or 1
				local invertXMultiplier = FirstPerson.InvertX and -1 or 1

				if isHeadTurnActive then
					freeLookYaw = freeLookYaw - (pos.X * sensitivity * invertXMultiplier)
					freeLookPitch = freeLookPitch + (pos.Y * sensitivity * invertYMultiplier)
				else
					yaw = yaw - (pos.X * sensitivity * invertXMultiplier)
					pitch = math.clamp(pitch + (pos.Y * sensitivity * invertYMultiplier), -89.9, 89.9)
					freeLookYaw = freeLookYaw * 0.8
					freeLookPitch = freeLookPitch * 0.8
				end
			end
		end
	end
end

local function InitializeContext()
	ContextActionService:BindAction("FirstPersonCamera", function(actionName, inputState, inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = inputObject.Delta
			local sensitivity = FirstPerson.Sensitivity

			local invertYMultiplier = FirstPerson.invertY and -1 or 1
			local invertXMultiplier = FirstPerson.invertX and -1 or 1

			if isHeadTurnActive then
				freeLookYaw = freeLookYaw - (delta.X * sensitivity * invertXMultiplier)
				freeLookPitch = freeLookPitch - (delta.Y * sensitivity * invertYMultiplier)
			else
				yaw = yaw - (delta.X * sensitivity * invertXMultiplier)
				pitch = math.clamp(pitch - (delta.Y * sensitivity * invertYMultiplier), -89.9, 89.9)

				freeLookYaw = freeLookYaw * 0.8
				freeLookPitch = freeLookPitch * 0.8
			end
		end

		return Enum.ContextActionResult.Pass
	end, false, Enum.UserInputType.MouseMovement)

	ContextActionService:BindAction("HeadTurnAxis", function(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin then
			isHeadTurnActive = true

			baseYaw = smoothYaw
			basePitch = smoothPitch
		elseif inputState == Enum.UserInputState.Cancel or inputState == Enum.UserInputState.End then
			isHeadTurnActive = false
		end

		return Enum.ContextActionResult.Pass
	end, false, Inputs.Axis.HeadTurn.PC, Inputs.Axis.HeadTurn.Console)

	UserInputService.TouchMoved:Connect(function(touch, gameProcessedEvent)
		if gameProcessedEvent then return end

		local delta = touch.Delta
		local sensitivity = FirstPerson.Sensitivity
		local invertYMultiplier = FirstPerson.InvertY and -1 or 1
		local invertXMultiplier = FirstPerson.InvertX and -1 or 1

		if isHeadTurnActive then
			freeLookYaw = freeLookYaw - (delta.X * sensitivity * invertXMultiplier)
			freeLookPitch = freeLookPitch - (delta.Y * sensitivity * invertYMultiplier)
		else
			yaw = yaw - (delta.X * sensitivity * invertXMultiplier)
			pitch = math.clamp(pitch - (delta.Y * sensitivity * invertYMultiplier), -89.9, 89.9)
			freeLookYaw = freeLookYaw * 0.8
			freeLookPitch = freeLookPitch * 0.8
		end
	end)

	if UserInputService.TouchEnabled then
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "MobileFreeLookGUI"
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.Parent = playerGui

		local freeLookButton = Instance.new("ImageButton")
		freeLookButton.Name = "FreeLookButton"
		freeLookButton.Size = UDim2.new(0.2, 0, 0.2, 0)
		freeLookButton.AnchorPoint = Vector2.new(1, 0.5)
		freeLookButton.Position = UDim2.new(0.9, 0, 0.4, 0)
		freeLookButton.Parent = screenGui

		local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		uiAspectRatioConstraint.Parent = freeLookButton

		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 50)
		uiCorner.Parent = freeLookButton

		freeLookButton.MouseButton1Click:Connect(function()
			isHeadTurnActive = not isHeadTurnActive

			if isHeadTurnActive then
				baseYaw = smoothYaw
				basePitch = smoothPitch
			end
		end)
	end

	if UserInputService.MouseEnabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end

function FirstPerson:Initialize(character)
    local head = character:WaitForChild("Head")
    local upperTorso = character:WaitForChild("UpperTorso")
    local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
    if not head or not upperTorso or not humanoid or not rootPart then return end

	currentCharacter = character

    humanoid.AutoRotate = false
    camera.CameraType = Enum.CameraType.Scriptable

	InitializeContext()

    RunService:BindToRenderStep("FirstPersonCamera", Enum.RenderPriority.Camera.Value, function()
        HideHeadAndAccessory(character)

		ProcessGamepadInput()

		if isHeadTurnActive then
			HeadRotation(rootPart, humanoid)
		else
			UpdateCamera(rootPart)
		end

		local currentTime = tick()
		if currentTime - lastServerFireTime > 0.016 then
			if isHeadTurnActive then
				local absPitch = basePitch + freeLookPitch
				absPitch = math.clamp(absPitch, -89.9, 89.9)

				local targetHeadYaw = smoothFreeLookYaw * (60 / 60)
				local targetHeadPitch = absPitch * (60 / 89.9)

				smoothHeadYaw = smoothHeadYaw + (targetHeadYaw - smoothHeadYaw) * FirstPerson.Smoothness
				smoothHeadPitch = smoothHeadPitch + (targetHeadPitch - smoothHeadPitch) * FirstPerson.Smoothness

				HeadLookEvent:FireServer(smoothHeadYaw, smoothHeadPitch)
			else
				smoothHeadYaw = smoothHeadYaw + (0 - smoothHeadYaw) * FirstPerson.Smoothness
				smoothHeadPitch = smoothHeadPitch + (0 - smoothHeadPitch) * FirstPerson.Smoothness

				HeadLookEvent:FireServer(smoothHeadYaw, smoothHeadPitch)
			end
			
			lastServerFireTime = currentTime
		end
    end)

	humanoid.Died:Connect(function()
		self:Disable()
	end)
end

function FirstPerson:Disable()
	ContextActionService:UnbindAction("FirstPersonCamera")
	ContextActionService:UnbindAction("HeadTurnAxis")
	RunService:UnbindFromRenderStep("FirstPersonCamera")

	if currentCharacter then
		local humanoid = currentCharacter:FindFirstChild("Humanoid")
		if humanoid then humanoid.AutoRotate = true end

		local head = currentCharacter:FindFirstChild("Head")
		if head then head.LocalTransparencyModifier = 0 end

		for _, child in ipairs(currentCharacter:GetChildren()) do
			if child:IsA("Accessory") then
				local handle = child:FindFirstChild("Handle")
				if handle then handle.LocalTransparencyModifier = 0 end
			end
		end
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	camera.CameraType = Enum.CameraType.Custom
	currentCharacter = nil
end

return FirstPerson