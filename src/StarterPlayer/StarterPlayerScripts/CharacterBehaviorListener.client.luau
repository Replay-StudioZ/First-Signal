--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local characterBehavior = ReplicatedStorage:WaitForChild("CharacterBehavior")

local FirstPerson = require(characterBehavior:WaitForChild("FirstPerson"):WaitForChild("FirstPerson"))
local LegIKController = require(characterBehavior:WaitForChild("Animation"):WaitForChild("IK"):WaitForChild("LegIKController"))

local function onCharacterAdded(character: Model)
    FirstPerson:Initialize(character)

    local renderConnection: RBXScriptConnection? = nil

    local function updateIK(delta: number)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        LegIKController:Update(character, "Right")
        LegIKController:Update(character, "Left")
    end

    renderConnection = RunService.RenderStepped:Connect(updateIK)

    local function cleanup()
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
    end

    character.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            cleanup()
        end
    end)
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    task.spawn(onCharacterAdded, player.Character)
end