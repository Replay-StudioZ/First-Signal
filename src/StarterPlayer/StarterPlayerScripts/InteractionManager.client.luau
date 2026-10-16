local CollectionService = game:GetService("CollectionService") 
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players") 
local RunService = game:GetService("RunService") 
local ReplicatedStorage = game:GetService("ReplicatedStorage") 

local Inputs = require(ReplicatedStorage:WaitForChild("Input"):WaitForChild("Inputs"))
local AddItemEvent = ReplicatedStorage.Inventory.Events:WaitForChild("AddItemEvent")

local interactTemplate = ReplicatedStorage.Interact:WaitForChild("InteractGui")
local interactMobileTemplate = ReplicatedStorage.Interact:WaitForChild("InteractMobileGui")

local bind = Inputs.Actions.Interact
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera 

local MAX_DISTANCE = 6
local DOT_THRESHOLD = 0.5
local currentTarget = nil 
local currentGui = nil
local mobileGui = nil

local activeHighlight = nil
local highlight = Instance.new("Highlight")
highlight.Name = "highlight"
highlight.FillTransparency = 1
highlight.OutlineTransparency = 0
highlight.OutlineColor = Color3.fromHex("#00E5FF")

local function handleInteract(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and currentTarget then
		if currentGui then
			currentGui:Destroy()
			currentGui = nil
			
			activeHighlight:Destroy()
		end
		
		if mobileGui then
			mobileGui:Destroy()
			mobileGui = nil
		end
		
		local itemId = currentTarget:GetAttribute("ItemId")
		
		AddItemEvent:FireServer(itemId, currentTarget)
		
		currentTarget = nil
	end
end

local function getClosestInteractable() 
	local character = player.Character 
	if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end 

	local closestObj = nil 
	local closestDist = MAX_DISTANCE 

	for _, obj in pairs(CollectionService:GetTagged("Interactable")) do 
		local targetPosition = obj:GetPivot().Position
		local distance = (character.HumanoidRootPart.Position - targetPosition).Magnitude 
		
		if distance < closestDist then 
			local dirToObj = (targetPosition - camera.CFrame.Position).Unit 
			local camDirection = camera.CFrame.LookVector 
			local dotProduct = camDirection:Dot(dirToObj) 

			if dotProduct > DOT_THRESHOLD then 
				closestObj = obj 
				closestDist = distance 
			end 
		end 
	end 
	return closestObj 
end 

RunService.RenderStepped:Connect(function() 
	local newTarget = getClosestInteractable() 

	if newTarget ~= currentTarget then 
		if currentTarget then 
			if currentGui then
				currentGui:Destroy()
				currentGui = nil
				
				activeHighlight:Destroy()
			end
			
			if mobileGui then
				mobileGui:Destroy()
				mobileGui = nil
				
				ContextActionService:UnbindAction("InteractAction")
			end
		end 

		currentTarget = newTarget 

		if currentTarget then
			activeHighlight = highlight:Clone()
			activeHighlight.Parent = currentTarget
			
			currentGui = interactTemplate:Clone()
			
			local actionTextLabel = currentGui.MainFrame:FindFirstChild("ActionText")
			if actionTextLabel and currentTarget:GetAttribute("ActionText") then
				actionTextLabel.Text = currentTarget:GetAttribute("ActionText")
			end
			
			currentGui.Adornee = currentTarget
			currentGui.Parent = player:WaitForChild("PlayerGui")
			
			if UserInputService.TouchEnabled then
				mobileGui = interactMobileTemplate:Clone()
				mobileGui.Parent = player:WaitForChild("PlayerGui")
				
				local interactButton = mobileGui:FindFirstChild("InteractButton", true)
				
				if interactButton then
					interactButton.Position = UDim2.new(0.85, 0, 0.6, 0)
					
					interactButton.Activated:Connect(function()
						handleInteract("InteractAction", Enum.UserInputState.Begin, nil)
					end)
				end
			end
			
			ContextActionService:BindAction("InteractAction", handleInteract, false, bind.PC, bind.Console)
		end
	end 
end)