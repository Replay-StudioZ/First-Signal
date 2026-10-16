local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local AddItemEvent = ReplicatedStorage.Inventory.Events:WaitForChild("AddItemEvent")
local EquipItemEvent = ReplicatedStorage.Inventory.Events:WaitForChild("EquipItemEvent")

local ServerItems = ServerStorage.Inventory.Items
local activeAnimations = {}

AddItemEvent.OnServerEvent:Connect(function(player, itemId, currentTarget)
	print("Связь с сервером удалась!")
	
	if not currentTarget or not currentTarget:IsDescendantOf(workspace) then return end
	
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	
	local distance = (character.HumanoidRootPart.Position - currentTarget:GetPivot().Position).Magnitude
	if distance > 10 then return end
	
	if not CollectionService:HasTag(currentTarget, "SpecialItem") then 
		currentTarget:Destroy()
	end
	
	AddItemEvent:FireClient(player, itemId, currentTarget)
end)

EquipItemEvent.OnServerEvent:Connect(function(player, itemId)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then return end
	local humanoid = character.Humanoid
	
	for _, child in pairs(character:GetChildren()) do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end
	
	if activeAnimations[player] then
		activeAnimations[player]:Stop()
		activeAnimations[player] = nil
	end
	
	if not itemId then return end
	
	local targetToolTemplate = nil
	for _, child in pairs(ServerItems:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("ItemId") == itemId then
			targetToolTemplate = child
			break
        end
	end
	
	if not targetToolTemplate then return end
	
	local newTool = targetToolTemplate:Clone()
	
	local handle = newTool:FindFirstChild("Handle")
	if handle then
		local model = newTool:FindFirstChildOfClass("Model")
		if model then
			local gripSettingsModule = newTool:FindFirstChild("GripSettings")
			local targetCFrame = handle.CFrame
			
			if gripSettingsModule and gripSettingsModule:IsA("ModuleScript") then
				local settings = require(gripSettingsModule)
				
				local posOffset = settings.PositionOffset or Vector3.new(0, 0, 0)
				local rotOffset = settings.RotationOffset or Vector3.new(0, 0, 0)
				
				local rotationCFrame = CFrame.Angles(math.rad(rotOffset.X), math.rad(rotOffset.Y), math.rad(rotOffset.Z))
				
				targetCFrame = handle.CFrame * CFrame.new(posOffset) * rotationCFrame
			end
			
			model:PivotTo(targetCFrame) 
		end
	end
	
	for _, descendant in pairs(newTool:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= handle then
			descendant.Anchored = false
			descendant.CanCollide = false
			
			local autoWeld = Instance.new("WeldConstraint")
			autoWeld.Name = "AutoWeld_" .. descendant.Name
			autoWeld.Part0 = handle
			autoWeld.Part1 = descendant
			autoWeld.Parent = descendant
		end
	end
	
	newTool.Parent = character
	
	local holdAnimObject = newTool:FindFirstChild("HoldAnimation")
	if holdAnimObject and holdAnimObject:IsA("Animation") then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local track = animator:LoadAnimation(holdAnimObject)
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = true
			track:Play()
			
			activeAnimations[player] = track
		end
	end
end)