local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local systemFolder = workspace:WaitForChild("FlightSimulationSystem")
local pickup = systemFolder:WaitForChild("ScannerPickup")
local terminal = systemFolder:WaitForChild("TelemetryTerminal")
local scannerTemplate = ServerStorage:WaitForChild("HandheldOrbitScanner")
local feedback = ReplicatedStorage:FindFirstChild("OrbitScannerFeedback")
if feedback and not feedback:IsA("RemoteEvent") then
	error("OrbitScannerFeedback exists but is not a RemoteEvent.")
end
if not feedback then
	feedback = Instance.new("RemoteEvent")
	feedback.Name = "OrbitScannerFeedback"
	feedback.Parent = ReplicatedStorage
end

local pickupPrompt = pickup:WaitForChild("PickupPrompt")
local terminalPrompt = terminal:WaitForChild("CalibratePrompt")
local CALIBRATION_DURATION_SECONDS = 120
local ACCURACY_BONUS_PERCENT = 5
local lastCalibrationAt = {}

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function ownsScanner(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	return (backpack and backpack:FindFirstChild(scannerTemplate.Name) ~= nil)
		or (character and character:FindFirstChild(scannerTemplate.Name) ~= nil)
end

pickupPrompt.Triggered:Connect(function(player)
	local root = getRoot(player)
	if not root or (root.Position - pickup.Position).Magnitude > pickupPrompt.MaxActivationDistance + 3 then return end
	if ownsScanner(player) then
		feedback:FireClient(player, "Status", "Orbit Scanner already secured.")
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		feedback:FireClient(player, "Status", "Inventory is not ready. Try again shortly.")
		return
	end

	local cloneSucceeded, scanner = pcall(function()
		return scannerTemplate:Clone()
	end)
	if not cloneSucceeded then
		warn(string.format("Could not clone Orbit Scanner for %s: %s", player.Name, tostring(scanner)))
		feedback:FireClient(player, "Status", "Scanner pickup failed. Try again shortly.")
		return
	end

	scanner.Parent = backpack
	feedback:FireClient(player, "Status", "Handheld Orbit Scanner added to inventory.")
end)

terminalPrompt.Triggered:Connect(function(player)
	local root = getRoot(player)
	local character = player.Character
	local equippedTool = character and character:FindFirstChild(scannerTemplate.Name)
	if not root or (root.Position - terminal.Position).Magnitude > terminalPrompt.MaxActivationDistance + 3 then return end
	if not equippedTool or not equippedTool:IsA("Tool") then
		feedback:FireClient(player, "Status", "Equip the Handheld Orbit Scanner first.")
		return
	end

	local now = os.clock()
	if lastCalibrationAt[player] and now - lastCalibrationAt[player] < 5 then return end
	lastCalibrationAt[player] = now
	player:SetAttribute("OrbitScannerAccuracyBonus", ACCURACY_BONUS_PERCENT)
	player:SetAttribute("OrbitScannerCalibrationExpiresAt", workspace:GetServerTimeNow() + CALIBRATION_DURATION_SECONDS)
	feedback:FireClient(player, "Calibration", CALIBRATION_DURATION_SECONDS, ACCURACY_BONUS_PERCENT)
end)

Players.PlayerRemoving:Connect(function(player)
	lastCalibrationAt[player] = nil
end)
