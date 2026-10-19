--!strict

export type IKResult = {
    midJoint: Vector3,
    endJoint: Vector3
}

local TwoBoneIK = {}

function TwoBoneIK.Solve(rootPos: Vector3, targetPos: Vector3, poleTarget: Vector3, upperLength: number, lowerLength: number): IKResult
    local rootToTarget = targetPos - rootPos
    local targetDistance = rootToTarget.Magnitude
    local maxReach = (upperLength + lowerLength) - 0.01
    local clampedTargetPos = targetPos

    if targetDistance > maxReach then
        clampedTargetPos = rootPos + (rootToTarget.Unit * maxReach)
        rootToTarget = clampedTargetPos - rootPos
        targetDistance = maxReach
    end

    local minReach = math.abs(upperLength - lowerLength) + 0.01

    if targetDistance < minReach then
        clampedTargetPos = rootPos + (rootToTarget.Unit * minReach)
        rootToTarget = clampedTargetPos - rootPos
        targetDistance = minReach
    end

    local cosRootAngle = (upperLength^2 + targetDistance^2 - lowerLength^2) / (2 * upperLength * targetDistance)
    local cosEndAngle = (upperLength^2 + lowerLength^2 - targetDistance^2) / (2 * upperLength * lowerLength)

    cosRootAngle = math.clamp(cosRootAngle, -1, 1)
    cosEndAngle = math.clamp(cosEndAngle, -1, 1)

    local rootAngle = math.acos(cosRootAngle)
    local endAngle = math.acos(cosEndAngle)

    local rootCFrame = CFrame.lookAt(rootPos, clampedTargetPos)

    local planeRight = rootToTarget:Cross(poleTarget - rootPos).Unit

    if planeRight.Magnitude < 0.001 then
        planeRight = rootCFrame.RightVector
    end

    local planeUp = planeRight:Cross(rootToTarget).Unit
    local kneeProjectionDistance = upperLength * math.cos(rootAngle)
    local kneeProjectionPoint = rootPos + (rootToTarget.Unit * kneeProjectionDistance)

    local kneeHeight = math.sqrt(upperLength^2 - kneeProjectionDistance^2)
    
    local midJointPos = kneeProjectionPoint + (planeUp * kneeHeight)
    local endJointPos = clampedTargetPos

    return { midJoint = midJointPos, endJoint = endJointPos }
end

return TwoBoneIK