--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local characterBehavior = ReplicatedStorage:WaitForChild("CharacterBehavior")

local TwoBoneIK = require(characterBehavior:WaitForChild("Core"):WaitForChild("Math"):WaitForChild("TwoBoneIK"))

local LegIKController = {}

local CONFIG = {
    RaycastDistance = 10,
    FootOffset = 0,
}

function LegIKController:Update(character: Model, legSide: string)
    local upperLeg = character:WaitForChild(legSide .. "UpperLeg") :: BasePart
    local lowerLeg = character:WaitForChild(legSide .. "LowerLeg") :: BasePart
    local foot = character:WaitForChild(legSide .. "Foot") :: BasePart
    local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

    local hipMotor = upperLeg:FindFirstChildOfClass("Motor6D")
    local kneeMotor = lowerLeg:FindFirstChildOfClass("Motor6D")

    if not hipMotor or not kneeMotor then return end

    local hipWorldPos = hipMotor.Part0.CFrame:PointToWorldSpace(hipMotor.C0.Position)

    local sideMultiplier = (legSide == "Right") and 1 or -1
    local poleTargetPos = hipWorldPos + (rootPart.CFrame.LookVector * 2) + (rootPart.CFrame.RightVector * 0.5 * sideMultiplier)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { character }

    local rayOrigin = hipWorldPos + Vector3.new(0, 2, 0)
    local rayDirection = Vector3.new(0, -CONFIG.RaycastDistance, 0)

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    local targetFootPos: Vector3
    if raycastResult then
        targetFootPos = raycastResult.Position + Vector3.new(0, CONFIG.FootOffset, 0)
    else
        targetFootPos = foot.Position
    end

    local upperLegLength = (hipWorldPos - lowerLeg.Position).Magnitude
    local lowerLegLength = (lowerLeg.Position - foot.Position).Magnitude

    local ikResult = TwoBoneIK.Solve(hipWorldPos, targetFootPos, poleTargetPos, upperLegLength, lowerLegLength)

    local upperLegWorldCFrame = CFrame.lookAt(hipWorldPos, ikResult.midJoint)
    local upperLegLocalCFrame = hipMotor.Part0.CFrame:Inverse() * upperLegWorldCFrame

    hipMotor.Transform = upperLegLocalCFrame * CFrame.Angles(math.rad(90), 0, 0)

    local lowerLegWorldCFrame = CFrame.lookAt(ikResult.midJoint, ikResult.endJoint)
    local lowerLegLocalCFrame = kneeMotor.Part0.CFrame:Inverse() * lowerLegWorldCFrame
    kneeMotor.Transform = lowerLegLocalCFrame * CFrame.Angles(math.rad(90), 0, 0)
end

return LegIKController