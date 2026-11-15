local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FlightCalculationCore = require(ServerScriptService:WaitForChild("FlightCalculationCore"))
local FlightCalculationState = require(ServerScriptService:WaitForChild("FlightCalculationState"))
local challenges = require(ServerScriptService:WaitForChild("FlightChallengeConfig"))

local runRemote = ReplicatedStorage:FindFirstChild("FlightChallengeRemote")
if runRemote and not runRemote:IsA("RemoteEvent") then
	error("FlightChallengeRemote exists but is not a RemoteEvent.")
end
if not runRemote then
	runRemote = Instance.new("RemoteEvent")
	runRemote.Name = "FlightChallengeRemote"
	runRemote.Parent = ReplicatedStorage
end

local catalogRemote = ReplicatedStorage:FindFirstChild("FlightChallengeCatalog")
if catalogRemote and not catalogRemote:IsA("RemoteFunction") then
	error("FlightChallengeCatalog exists but is not a RemoteFunction.")
end
if not catalogRemote then
	catalogRemote = Instance.new("RemoteFunction")
	catalogRemote.Name = "FlightChallengeCatalog"
	catalogRemote.Parent = ReplicatedStorage
end

local completedByPlayer = {}
local lastRunAt = {}
local CALCULATION_MAX_AGE_SECONDS = 300
local RUN_COOLDOWN_SECONDS = 2

local function findChallenge(id)
	for _, challenge in ipairs(challenges) do
		if challenge.id == id then
			return challenge
		end
	end
	return nil
end

local function isUnlocked(player, challenge)
	if challenge.order == 1 then
		return true
	end
	local completed = completedByPlayer[player] or {}
	local previous = challenges[challenge.order - 1]
	return previous ~= nil and completed[previous.id] == true
end

local function publicCatalog(player)
	local completed = completedByPlayer[player] or {}
	local output = {}
	for _, challenge in ipairs(challenges) do
		table.insert(output, {
			id = challenge.id,
			order = challenge.order,
			title = challenge.title,
			difficulty = challenge.difficulty,
			description = challenge.description,
			requirements = challenge.requirements,
			unlocked = isUnlocked(player, challenge),
			completed = completed[challenge.id] == true,
		})
	end
	return output
end

local function evaluate(challenge, result)
	local requirements = challenge.requirements
	local checks = {
		deltaV = result.deltaVMps >= requirements.minDeltaV,
		thrustToWeight = result.initialThrustToWeight >= requirements.minThrustToWeight,
		angle = result.insertionAngleErrorDeg <= requirements.maxAngleError,
		maxQ = result.maxQPa <= requirements.maxQ,
	}
	local success = checks.deltaV and checks.thrustToWeight and checks.angle and checks.maxQ
	return success, checks
end

catalogRemote.OnServerInvoke = function(player)
	return publicCatalog(player)
end

runRemote.OnServerEvent:Connect(function(player, action, challengeId)
	if action ~= "Run" or typeof(challengeId) ~= "string" then
		return
	end

	local now = os.clock()
	if lastRunAt[player] and now - lastRunAt[player] < RUN_COOLDOWN_SECONDS then
		runRemote:FireClient(player, "Status", "Wait a moment before running another simulation.")
		return
	end
	lastRunAt[player] = now

	local challenge = findChallenge(challengeId)
	if not challenge then
		runRemote:FireClient(player, "Status", "Unknown flight simulation.")
		return
	end
	if not isUnlocked(player, challenge) then
		runRemote:FireClient(player, "Status", "Complete the previous simulation first.")
		return
	end

	local record = FlightCalculationState.Get(player)
	if not record or os.clock() - record.createdAt > CALCULATION_MAX_AGE_SECONDS then
		runRemote:FireClient(player, "Status", "Use the flight calculator first, then run this simulation.")
		return
	end

	local recalculated, errorMessage = FlightCalculationCore.Calculate(record.inputs, 0)
	if not recalculated then
		runRemote:FireClient(player, "Status", "The saved calculation is no longer valid: " .. tostring(errorMessage))
		return
	end

	local success, checks = evaluate(challenge, recalculated)
	if success then
		completedByPlayer[player] = completedByPlayer[player] or {}
		completedByPlayer[player][challenge.id] = true
	end

	runRemote:FireClient(player, "Result", {
		challengeId = challenge.id,
		title = challenge.title,
		success = success,
		checks = checks,
		result = recalculated,
		catalog = publicCatalog(player),
	})
end)

Players.PlayerRemoving:Connect(function(player)
	completedByPlayer[player] = nil
	lastRunAt[player] = nil
end)
