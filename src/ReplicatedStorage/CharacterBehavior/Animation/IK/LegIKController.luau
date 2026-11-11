--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local characterBehavior = ReplicatedStorage:WaitForChild("CharacterBehavior")
local TwoBoneIK = require(characterBehavior:WaitForChild("Core"):WaitForChild("Math"):WaitForChild("TwoBoneIK"))

local LegIKController = {}
LegIKController.__index = LegIKController

function LegIKController.new(character: Model)
    local self = setmetatable({}, LegIKController)
    self.character = character
    self.active = true

    self.humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
    self.lowerTorso = character:WaitForChild("LowerTorso") :: BasePart

    -- Левая нога (R15)
    self.leftUpperLeg = character:WaitForChild("LeftUpperLeg") :: BasePart
    self.leftLowerLeg = character:WaitForChild("LeftLowerLeg") :: BasePart
    self.leftFoot = character:WaitForChild("LeftFoot") :: BasePart
    self.leftHipMotor = self.lowerTorso:WaitForChild("LeftHip") :: Motor6D
    self.leftKneeMotor = self.leftUpperLeg:WaitForChild("LeftKnee") :: Motor6D

    -- Правая нога (R15)
    self.rightUpperLeg = character:WaitForChild("RightUpperLeg") :: BasePart
    self.rightLowerLeg = character:WaitForChild("RightLowerLeg") :: BasePart
    self.rightFoot = character:WaitForChild("RightFoot") :: BasePart
    self.rightHipMotor = self.lowerTorso:WaitForChild("RightHip") :: Motor6D
    self.rightKneeMotor = self.rightUpperLeg:WaitForChild("RightKnee") :: Motor6D

    -- ЖЕСТКОЕ И ТОЧНОЕ ОПРЕДЕЛЕНИЕ ДЛИНЫ КОСТЕЙ ПО РАЗМЕРАМ R15 (без зависимости от кадра анимации)
    self.boneLengths = {
        [self.leftUpperLeg] = self.leftUpperLeg.Size.Y,
        [self.leftLowerLeg] = self.leftLowerLeg.Size.Y,
        [self.rightUpperLeg] = self.rightUpperLeg.Size.Y,
        [self.rightLowerLeg] = self.rightLowerLeg.Size.Y,
    }

    -- Кэшируем исходное смещение стоп относительно RootPart, исключая дрожание аниматора
    self.leftFootOffset = self.humanoidRootPart.CFrame:PointToObjectSpace(self.leftFoot.Position)
    self.rightFootOffset = self.humanoidRootPart.CFrame:PointToObjectSpace(self.rightFoot.Position)

    self.raycastParams = RaycastParams.new()
    self.raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    self.raycastParams.FilterDescendantsInstances = {character}

    self.connection = RunService.RenderStepped:Connect(function(dt)
        if not self.active or not self.character.Parent then
            self:Destroy()
            return
        end

        self:UpdateLegIK(dt)
    end)

    return self
end

function LegIKController:SolveLeg(
    upperLeg: BasePart, 
    lowerLeg: BasePart, 
    foot: BasePart, 
    hipMotor: Motor6D, 
    kneeMotor: Motor6D,
    isLeft: boolean,
    dt: number
)
    local part0Hip = hipMotor.Part0
    local part0Knee = kneeMotor.Part0
    if not part0Hip or not part0Knee then return end

    local hipPos = part0Hip.CFrame:PointToWorldSpace(hipMotor.C0.Position)
    
    -- Базовая позиция стопы в мире относительно RootPart
    local footOffset = isLeft and self.leftFootOffset or self.rightFootOffset
    local defaultFootPos = self.humanoidRootPart.CFrame:PointToWorldSpace(footOffset)
    
    -- Надежный рейкаст для поиска опоры под ногой
    local rayOrigin = Vector3.new(defaultFootPos.X, hipPos.Y + 1.0, defaultFootPos.Z)
    local rayDirection = Vector3.new(0, -6.0, 0)
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, self.raycastParams)
    
    local targetPos = defaultFootPos
    if raycastResult then
        targetPos = raycastResult.Position + Vector3.new(0, foot.Size.Y / 2, 0)
    end

    local upperLength = self.boneLengths[upperLeg] or 1.4
    local lowerLength = self.boneLengths[lowerLeg] or 1.4
    
    local lookVector: Vector3 = self.humanoidRootPart.CFrame.LookVector
    local lookFlat = Vector3.new(lookVector.X, 0, lookVector.Z)
    if lookFlat.Magnitude > 0.001 then
        lookFlat = lookFlat.Unit
    else
        lookFlat = Vector3.new(0, 0, -1)
    end
    
    local poleTarget = hipPos + (lookFlat * 3.0)

    local ikResult = TwoBoneIK.Solve(hipPos, targetPos, poleTarget, upperLength, lowerLength)

    if (ikResult.midJoint - hipPos).Magnitude < 0.001 or (ikResult.endJoint - ikResult.midJoint).Magnitude < 0.001 then 
        return 
    end

    local targetHipC0 = part0Hip.CFrame:Inverse() * ikResult.upperCFrame * hipMotor.C1
    local targetKneeC0 = ikResult.upperCFrame:Inverse() * ikResult.lowerCFrame * kneeMotor.C1

    local alpha = math.clamp(dt * 20, 0, 1)
    hipMotor.C0 = hipMotor.C0:Lerp(targetHipC0, alpha)
    kneeMotor.C0 = kneeMotor.C0:Lerp(targetKneeC0, alpha)
end

function LegIKController:UpdateLegIK(dt: number)
    self:SolveLeg(
        self.leftUpperLeg, self.leftLowerLeg, self.leftFoot, 
        self.leftHipMotor, self.leftKneeMotor, 
        true, dt
    )
    
    self:SolveLeg(
        self.rightUpperLeg, self.rightLowerLeg, self.rightFoot, 
        self.rightHipMotor, self.rightKneeMotor, 
        false, dt
    )
end

function LegIKController:Destroy()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

return LegIKController