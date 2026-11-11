--!strict

export type IKResult = {
    midJoint: Vector3,
    endJoint: Vector3,
    upperCFrame: CFrame,
    lowerCFrame: CFrame
}

local TwoBoneIK = {}

function TwoBoneIK.Solve(rootPos: Vector3, targetPos: Vector3, poleTarget: Vector3, upperLength: number, lowerLength: number): IKResult
    upperLength = math.max(upperLength, 0.01)
    lowerLength = math.max(lowerLength, 0.01)

    local rootToTarget = targetPos - rootPos
    local targetDistance = rootToTarget.Magnitude

    if targetDistance < 0.0001 then
        rootToTarget = Vector3.new(0, -0.01, 0)
        targetDistance = rootToTarget.Magnitude
    end

    local maxReach = math.max((upperLength + lowerLength) - 0.001, 0.01)
    local clampedTargetPos = targetPos

    if targetDistance > maxReach then
        clampedTargetPos = rootPos + (rootToTarget.Unit * maxReach)
        rootToTarget = clampedTargetPos - rootPos
        targetDistance = maxReach
    end

    local minReach = math.max(math.abs(upperLength - lowerLength) + 0.01, 0.01)
    if targetDistance < minReach then
        clampedTargetPos = rootPos + (rootToTarget.Unit * minReach)
        rootToTarget = clampedTargetPos - rootPos
        targetDistance = minReach
    end

    local denominator = (2 * upperLength * targetDistance)
    if denominator < 0.0001 then denominator = 0.0001 end

    local cosRootAngle = (upperLength^2 + targetDistance^2 - lowerLength^2) / denominator
    cosRootAngle = math.clamp(cosRootAngle, -1, 1)

    local rootAngle = math.acos(cosRootAngle)
    local rootCFrame = CFrame.lookAt(rootPos, clampedTargetPos)

    local rootToTargetDir = rootToTarget.Unit
    local forwardDir = Vector3.new(poleTarget.X - rootPos.X, 0, poleTarget.Z - rootPos.Z)
    if forwardDir.Magnitude < 0.001 then
        forwardDir = Vector3.new(0, 0, -1)
    else
        forwardDir = forwardDir.Unit
    end

    local planeRight = rootToTargetDir:Cross(forwardDir)
    if planeRight.Magnitude < 0.001 then
        planeRight = rootCFrame.RightVector
    else
        planeRight = planeRight.Unit
    end

    local planeUp = planeRight:Cross(rootToTargetDir).Unit

    local kneeProjectionDistance = upperLength * math.cos(rootAngle)
    local kneeProjectionPoint = rootPos + (rootToTargetDir * kneeProjectionDistance)

    local heightSq = upperLength^2 - kneeProjectionDistance^2
    local kneeHeight = heightSq > 0 and math.sqrt(heightSq) or 0
    
    -- ПЛАВНОЕ ВЫПРЯМЛЕНИЕ: Если нога почти полностью вытянута (на плоскости), убираем выпячивание колена вперёд
    local totalPossibleReach = upperLength + lowerLength
    local reachRatio = targetDistance / totalPossibleReach
    if reachRatio > 0.88 then
        local factor = math.clamp((1.0 - reachRatio) / (1.0 - 0.88), 0, 1)
        kneeHeight = kneeHeight * factor
    end

    local midJointPos = kneeProjectionPoint + (planeUp * kneeHeight)
    local endJointPos = clampedTargetPos

    local upperVector = rootPos - midJointPos
    if upperVector.Magnitude < 0.0001 then
        upperVector = Vector3.new(0, upperLength, 0)
        midJointPos = rootPos - upperVector
    end
    local upperDir = upperVector.Unit

    local lowerVector = midJointPos - endJointPos
    if lowerVector.Magnitude < 0.0001 then
        lowerVector = Vector3.new(0, lowerLength, 0)
        endJointPos = midJointPos - lowerVector
    end
    local lowerDir = lowerVector.Unit

    local upperZ = planeRight:Cross(upperDir)
    if upperZ.Magnitude < 0.001 then
        upperZ = rootCFrame.LookVector
    else
        upperZ = upperZ.Unit
    end
    local upperCFrame = CFrame.fromMatrix(rootPos, planeRight, upperDir, upperZ)

    local lowerZ = planeRight:Cross(lowerDir)
    if lowerZ.Magnitude < 0.001 then
        lowerZ = rootCFrame.LookVector
    else
        lowerZ = lowerZ.Unit
    end
    local lowerCFrame = CFrame.fromMatrix(midJointPos, planeRight, lowerDir, lowerZ)

    return {
        midJoint = midJointPos,
        endJoint = endJointPos,
        upperCFrame = upperCFrame,
        lowerCFrame = lowerCFrame
    }
end

return TwoBoneIK