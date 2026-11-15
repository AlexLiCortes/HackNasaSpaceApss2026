local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local tool = script.Parent
local feedback = ReplicatedStorage:WaitForChild("OrbitScannerFeedback")
local hud
local statusLabel
local updateLoopId = 0

local function updateStatus(message)
	if statusLabel and message then
		statusLabel.Text = message
	end
end

local function refreshCalibration()
	if not statusLabel then return end
	local expiresAt = player:GetAttribute("OrbitScannerCalibrationExpiresAt")
	local bonus = player:GetAttribute("OrbitScannerAccuracyBonus")
	local remaining = typeof(expiresAt) == "number" and math.max(0, expiresAt - workspace:GetServerTimeNow()) or 0
	if remaining > 0 then
		statusLabel.Text = string.format("CALIBRATED  //  +%d%% ESTIMATE CONFIDENCE  //  %ds", math.floor(tonumber(bonus) or 0), math.ceil(remaining))
	else
		statusLabel.Text = "SCANNER ONLINE  //  SEEK TELEMETRY TERMINAL"
	end
end

local function createHud()
	if hud then hud:Destroy() end
	hud = Instance.new("ScreenGui")	hud.Name = "OrbitScannerHud"
	hud.ResetOnSpawn = false
	hud.DisplayOrder = 25
	hud.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "Readout"
	panel.AnchorPoint = Vector2.new(1, 1)
	panel.Position = UDim2.new(1, -22, 1, -78)
	panel.Size = UDim2.fromOffset(330, 86)
	panel.BackgroundColor3 = Color3.fromRGB(6, 16, 29)
	panel.BorderSizePixel = 0
	panel.Parent = hud
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(41, 218, 255)
	stroke.Thickness = 2
	stroke.Parent = panel
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(12, 8)
	title.Size = UDim2.new(1, -24, 0, 24)
	title.BackgroundTransparency = 1
	title.Text = "HANDHELD ORBIT SCANNER // v1.0"
	title.TextColor3 = Color3.fromRGB(255, 151, 68)
	title.Font = Enum.Font.RobotoMono
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel
	statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.Position = UDim2.fromOffset(12, 36)
	statusLabel.Size = UDim2.new(1, -24, 0, 38)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(92, 228, 255)
	statusLabel.Font = Enum.Font.RobotoMono
	statusLabel.TextSize = 12
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = panel
	refreshCalibration()
end

local function onEquipped()
	if hud then return end
	createHud()
	updateLoopId += 1
	local thisLoop = updateLoopId
	task.spawn(function()
		while hud and hud.Parent and updateLoopId == thisLoop do
			refreshCalibration()
			task.wait(1)
		end
	end)
end

local function onUnequipped()
	updateLoopId += 1
	if hud then hud:Destroy() end
	hud = nil
	statusLabel = nil
end

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)
tool:GetPropertyChangedSignal("Parent"):Connect(function()
	if tool.Parent == player.Character then
		onEquipped()
	else
		onUnequipped()
	end
end)

task.defer(function()
	if tool.Parent == player.Character then
		onEquipped()
	end
end)

tool.Activated:Connect(function()
	if statusLabel then
		updateStatus("SCANNER ACTIVE  //  Approach the terminal and press E to calibrate.")
	end
end)

feedback.OnClientEvent:Connect(function(action, message)
	if not statusLabel then return end
	if action == "Status" then
		updateStatus(tostring(message))
	elseif action == "Calibration" then
		refreshCalibration()
	end
end)

player:GetAttributeChangedSignal("OrbitScannerCalibrationExpiresAt"):Connect(refreshCalibration)
player:GetAttributeChangedSignal("OrbitScannerAccuracyBonus"):Connect(refreshCalibration)
