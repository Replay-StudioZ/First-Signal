--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local characterBehavior = ReplicatedStorage:WaitForChild("CharacterBehavior")

local FirstPerson = require(characterBehavior:WaitForChild("FirstPerson"):WaitForChild("FirstPerson"))
-- Подключаем новый контроллер IK для ног
local LegIKController = require(characterBehavior:WaitForChild("Animation"):WaitForChild("IK"):WaitForChild("LegIKController"))

local currentLegIK = nil

local function onCharacterAdded(character: Model)
	-- Инициализация вида от первого лица
	FirstPerson:Initialize(character)
	
	-- Очищаем предыдущий контроллер ног при респавне
	if currentLegIK then
		currentLegIK:Destroy()
	end
	
	-- Запускаем IK ног для нового персонажа
	currentLegIK = LegIKController.new(character)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end