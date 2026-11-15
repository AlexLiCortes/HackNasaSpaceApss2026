local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FlightCalculationCore = require(ServerScriptService:WaitForChild("FlightCalculationCore"))
local FlightCalculationState = require(ServerScriptService:WaitForChild("FlightCalculationState"))
local remoteName = "CalcularVuelo"
local calculateRemote = ReplicatedStorage:FindFirstChild(remoteName)

if calculateRemote and not calculateRemote:IsA("RemoteFunction") then
	error(remoteName .. " exists but is not a RemoteFunction.")
end
if not calculateRemote then
	calculateRemote = Instance.new("RemoteFunction")
	calculateRemote.Name = remoteName
	calculateRemote.Parent = ReplicatedStorage
end

local lastRequestAt = {}
local REQUEST_COOLDOWN_SECONDS = 1

calculateRemote.OnServerInvoke = function(player, inputs)
	local now = os.clock()
	local previousRequest = lastRequestAt[player]
	if previousRequest and now - previousRequest < REQUEST_COOLDOWN_SECONDS then
		return { ok = false, error = "Please wait before running another calculation." }
	end
	lastRequestAt[player] = now

	local bonus = 0
	local expiresAt = player:GetAttribute("OrbitScannerCalibrationExpiresAt")
	local playerBonus = player:GetAttribute("OrbitScannerAccuracyBonus")
	if typeof(expiresAt) == "number" and expiresAt > workspace:GetServerTimeNow() and typeof(playerBonus) == "number" then
		bonus = math.clamp(playerBonus, 0, 10)
	end

	local callSucceeded, result, errorMessage = pcall(FlightCalculationCore.Calculate, inputs, bonus)
	if not callSucceeded then
		warn(string.format("Flight calculation failed for %s: %s", player.Name, tostring(result)))
		return { ok = false, error = "Calculation service encountered an internal error." }
	end
	if not result then
		return { ok = false, error = errorMessage or "Invalid flight inputs." }
	end

	FlightCalculationState.Set(player, inputs, result)
	return { ok = true, result = result }
end

Players.PlayerRemoving:Connect(function(player)
	lastRequestAt[player] = nil
	FlightCalculationState.Clear(player)
end)
