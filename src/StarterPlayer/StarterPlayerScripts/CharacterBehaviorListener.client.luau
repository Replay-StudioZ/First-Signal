local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local characterBehavior = ReplicatedStorage:WaitForChild("CharacterBehavior")
local FirstPerson = require(characterBehavior:WaitForChild("FirstPerson"):WaitForChild("FirstPerson"))

local function onCharacterAdded(character)
    FirstPerson:Initialize(character)
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    task.spawn(onCharacterAdded, player.Character)
end