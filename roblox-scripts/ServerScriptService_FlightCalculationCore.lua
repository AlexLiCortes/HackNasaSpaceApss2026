local FlightCalculationCore = {}

local G0 = 9.80665
local SEA_LEVEL_DENSITY = 1.225
local ATMOSPHERE_SCALE_HEIGHT = 8500
local REQUIRED_DELTA_V = 9400
local TARGET_INSERTION_ANGLE_DEG = 0
local ANGLE_TOLERANCE_DEG = 2
local MAX_DYNAMIC_PRESSURE_PA = 50000
local MAX_BURN_TIME_SECONDS = 1800
local MAX_STEPS = 1200

local function readFiniteNumber(value, fieldName, minimum, maximum)
	if typeof(value) == "string" then
		if #value > 32 then
			return nil, fieldName .. " is too long."
		end
		value = tonumber(value)
	end

	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return nil, fieldName .. " must be a finite number."
	end
	if value < minimum or value > maximum then
		return nil, string.format("%s must be between %g and %g.", fieldName, minimum, maximum)
	end
	return value
end

local function estimateMaxQ(initialMassKg, finalMassKg, thrustNewtons, ispSeconds, burnTimeSeconds)
	local massFlowKgPerSecond = thrustNewtons / (ispSeconds * G0)
	local stepCount = math.clamp(math.ceil(burnTimeSeconds / 0.25), 1, MAX_STEPS)
	local deltaTime = burnTimeSeconds / stepCount
	local velocity = 0
	local altitude = 0
	local maxQ = 0
	local maxQAltitude = 0
	local maxQVelocity = 0

	for step = 1, stepCount do
		local elapsed = (step - 0.5) * deltaTime
		local mass = math.max(finalMassKg, initialMassKg - massFlowKgPerSecond * elapsed)
		local acceleration = thrustNewtons / mass - G0
		velocity = math.max(0, velocity + acceleration * deltaTime)
		altitude = math.max(0, altitude + velocity * deltaTime)

		local density = SEA_LEVEL_DENSITY * math.exp(-altitude / ATMOSPHERE_SCALE_HEIGHT)
		local dynamicPressure = 0.5 * density * velocity * velocity
		if dynamicPressure > maxQ then
			maxQ = dynamicPressure
			maxQAltitude = altitude
			maxQVelocity = velocity
		end
	end

	return maxQ, maxQAltitude, maxQVelocity
end

function FlightCalculationCore.Calculate(inputs, accuracyBonusPercent)
	if typeof(inputs) ~= "table" then
		return nil, "Input must be a table."
	end

	local initialMassKg, initialMassError = readFiniteNumber(inputs.initialMassKg, "Initial mass m0 (kg)", 1, 100000000)
	if not initialMassKg then return nil, initialMassError end
	local finalMassKg, finalMassError = readFiniteNumber(inputs.finalMassKg, "Final mass mf (kg)", 0.1, 100000000)
	if not finalMassKg then return nil, finalMassError end
	local ispSeconds, ispError = readFiniteNumber(inputs.ispSeconds, "Specific impulse Isp (s)", 30, 1000)
	if not ispSeconds then return nil, ispError end
	local thrustNewtons, thrustError = readFiniteNumber(inputs.thrustNewtons, "Thrust (N)", 1, 10000000000)
	if not thrustNewtons then return nil, thrustError end
	local insertionAngleDeg, angleError = readFiniteNumber(inputs.insertionAngleDeg, "Insertion flight-path angle (deg)", -90, 90)
	if not insertionAngleDeg then return nil, angleError end

	if finalMassKg >= initialMassKg then
		return nil, "Final mass mf must be lower than initial mass m0."
	end

	local deltaV = ispSeconds * G0 * math.log(initialMassKg / finalMassKg)
	local thrustToWeight = thrustNewtons / (initialMassKg * G0)
	local massFlowKgPerSecond = thrustNewtons / (ispSeconds * G0)
	local burnTimeSeconds = (initialMassKg - finalMassKg) / massFlowKgPerSecond
	if burnTimeSeconds > MAX_BURN_TIME_SECONDS then
		return nil, string.format("Burn duration exceeds the %d-second model limit.", MAX_BURN_TIME_SECONDS)
	end

	local maxQPa, maxQAltitudeM, maxQVelocityMps = estimateMaxQ(
		initialMassKg,
		finalMassKg,
		thrustNewtons,
		ispSeconds,
		burnTimeSeconds
	)
	local insertionAngleErrorDeg = math.abs(insertionAngleDeg - TARGET_INSERTION_ANGLE_DEG)
	local anglePassed = insertionAngleErrorDeg <= ANGLE_TOLERANCE_DEG
	local thrustPassed = thrustToWeight > 1
	local deltaVPassed = deltaV >= REQUIRED_DELTA_V
	local maxQPassed = maxQPa <= MAX_DYNAMIC_PRESSURE_PA
	local failures = {}

	if not thrustPassed then table.insert(failures, "Liftoff thrust-to-weight ratio must exceed 1.") end
	if not deltaVPassed then table.insert(failures, "Ideal delta-v is below the 9,400 m/s LEO planning target.") end
	if not anglePassed then table.insert(failures, "Insertion angle is outside the +/-2 degree target window.") end
	if not maxQPassed then table.insert(failures, "Estimated Max Q exceeds the 50,000 Pa educational limit.") end

	local accuracyBonus = 0
	if typeof(accuracyBonusPercent) == "number" and accuracyBonusPercent == accuracyBonusPercent then
		accuracyBonus = math.clamp(accuracyBonusPercent, 0, 10)
	end

	return {
		success = #failures == 0,
		failures = failures,
		deltaVMps = deltaV,
		deltaVTargetMps = REQUIRED_DELTA_V,
		initialThrustToWeight = thrustToWeight,
		burnTimeSeconds = burnTimeSeconds,
		maxQPa = maxQPa,
		maxQAltitudeM = maxQAltitudeM,
		maxQVelocityMps = maxQVelocityMps,
		insertionAngleDeg = insertionAngleDeg,
		targetInsertionAngleDeg = TARGET_INSERTION_ANGLE_DEG,
		insertionAngleErrorDeg = insertionAngleErrorDeg,
		angleToleranceDeg = ANGLE_TOLERANCE_DEG,
		accuracyPercent = math.clamp(90 + accuracyBonus, 0, 100),
		maxQModel = "Vertical ascent estimate; exponential atmosphere; drag and steering losses omitted.",
	}
end

return FlightCalculationCore
