local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local boardRemote = ReplicatedStorage:WaitForChild("ActualizarPizarronVuelo")
local calculateRemote = ReplicatedStorage:WaitForChild("CalcularVuelo")
local scannerFeedback = ReplicatedStorage:WaitForChild("OrbitScannerFeedback")

local COLORS = {
	background = Color3.fromRGB(7, 14, 25),
	panel = Color3.fromRGB(13, 25, 39),
	input = Color3.fromRGB(9, 18, 30),
	cyan = Color3.fromRGB(47, 220, 255),
	orange = Color3.fromRGB(255, 150, 65),
	text = Color3.fromRGB(220, 238, 245),
	muted = Color3.fromRGB(132, 165, 181),
	green = Color3.fromRGB(112, 255, 174),
	red = Color3.fromRGB(255, 112, 112),
}

local gui = Instance.new("ScreenGui")
gui.Name = "FlightWhiteboardGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Enabled = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.9, 0, 0.88, 0)
panel.BackgroundColor3 = COLORS.background
panel.BorderSizePixel = 0
panel.Parent = gui
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(320, 420)
sizeConstraint.MaxSize = Vector2.new(620, 740)
sizeConstraint.Parent = panel
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = COLORS.cyan
panelStroke.Thickness = 2
panelStroke.Parent = panel
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Position = UDim2.fromOffset(14, 14)
content.Size = UDim2.new(1, -28, 1, -28)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = COLORS.cyan
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.Parent = panel
local padding = Instance.new("UIPadding")
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = content
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

local function makeLabel(name, text, height, color, order)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, height)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.Font = Enum.Font.RobotoMono
	label.TextSize = 17
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.LayoutOrder = order
	label.Parent = content
	return label
end

local title = makeLabel("Title", "FLIGHT DYNAMICS // TEAM WHITEBOARD", 36, COLORS.cyan, 1)
title.TextSize = 20
local subtitle = makeLabel("Subtitle", "Tsiolkovsky Î”v â€¢ estimated Max Q â€¢ insertion-angle check", 28, COLORS.muted, 2)
subtitle.TextSize = 13

local fields = {}
local fieldDefinitions = {
	{ key = "initialMassKg", label = "INITIAL MASS m0 (kg)", default = "500000" },
	{ key = "finalMassKg", label = "FINAL MASS mf (kg)", default = "150000" },
	{ key = "ispSeconds", label = "SPECIFIC IMPULSE Isp (s)", default = "300" },
	{ key = "thrustNewtons", label = "THRUST (N)", default = "7000000" },
	{ key = "insertionAngleDeg", label = "INSERTION ANGLE Î¸ (deg; target 0Â°)", default = "0" },
}

for index, definition in ipairs(fieldDefinitions) do
	local row = Instance.new("Frame")
	row.Name = "Input_" .. definition.key
	row.Size = UDim2.new(1, 0, 0, 54)
	row.BackgroundColor3 = COLORS.panel
	row.BorderSizePixel = 0
	row.LayoutOrder = index + 2
	row.Parent = content
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent = row
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.56, -8, 1, 0)
	label.Position = UDim2.fromOffset(10, 0)
	label.BackgroundTransparency = 1
	label.Text = definition.label
	label.TextColor3 = COLORS.text
	label.Font = Enum.Font.RobotoMono
	label.TextSize = 12
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row
	local box = Instance.new("TextBox")
	box.Name = definition.key
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, -10, 0.5, 0)
	box.Size = UDim2.new(0.4, 0, 0, 36)
	box.BackgroundColor3 = COLORS.input
	box.TextColor3 = COLORS.green
	box.PlaceholderColor3 = COLORS.muted
	box.Font = Enum.Font.RobotoMono
	box.TextSize = 15
	box.Text = definition.default
	box.ClearTextOnFocus = false
	box.Parent = row
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = COLORS.cyan
	boxStroke.Thickness = 1
	boxStroke.Parent = box
	fields[definition.key] = box
end

local notesLabel = makeLabel("NotesLabel", "TEAM NOTES / TARGET ANSWER (max 400 bytes)", 24, COLORS.orange, 8)
notesLabel.TextSize = 13
local notesBox = Instance.new("TextBox")
notesBox.Name = "NotesBox"
notesBox.Size = UDim2.new(1, 0, 0, 96)
notesBox.BackgroundColor3 = COLORS.input
notesBox.TextColor3 = COLORS.text
notesBox.PlaceholderColor3 = COLORS.muted
notesBox.PlaceholderText = "Record a maneuver, result, or mission note..."
notesBox.Font = Enum.Font.RobotoMono
notesBox.TextSize = 15
notesBox.TextWrapped = true
notesBox.TextXAlignment = Enum.TextXAlignment.Left
notesBox.TextYAlignment = Enum.TextYAlignment.Top
notesBox.ClearTextOnFocus = false
notesBox.MultiLine = true
notesBox.LayoutOrder = 9
notesBox.Parent = content
local notesStroke = Instance.new("UIStroke")
notesStroke.Color = COLORS.cyan
notesStroke.Thickness = 1
notesStroke.Parent = notesBox

local actions = Instance.new("Frame")
actions.Name = "Actions"
actions.Size = UDim2.new(1, 0, 0, 44)
actions.BackgroundTransparency = 1
actions.LayoutOrder = 10
actions.Parent = content
local function makeButton(name, text, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = UDim2.new(0.49, 0, 1, 0)
	button.BackgroundColor3 = color
	button.TextColor3 = COLORS.background
	button.Font = Enum.Font.RobotoMono
	button.TextSize = 14
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = actions
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	return button
end
local calculateButton = makeButton("CalculateButton", "CALCULATE", UDim2.new(0, 0, 0, 0), COLORS.cyan)
local submitButton = makeButton("SubmitButton", "SHARE NOTES", UDim2.new(0.51, 0, 0, 0), COLORS.orange)

local resultLabel = makeLabel("Result", "Awaiting server calculation...", 132, COLORS.text, 11)
resultLabel.BackgroundColor3 = COLORS.panel
resultLabel.BackgroundTransparency = 0
resultLabel.TextSize = 13
resultLabel.TextYAlignment = Enum.TextYAlignment.Top
local resultPadding = Instance.new("UIPadding")
resultPadding.PaddingTop = UDim.new(0, 8)
resultPadding.PaddingLeft = UDim.new(0, 8)
resultPadding.PaddingRight = UDim.new(0, 8)
resultPadding.Parent = resultLabel

local previewLabel = makeLabel("TeamBoardPreview", "TEAM BOARD: no notes submitted yet", 100, COLORS.muted, 12)
previewLabel.BackgroundColor3 = COLORS.panel
previewLabel.BackgroundTransparency = 0
previewLabel.TextSize = 12
previewLabel.TextYAlignment = Enum.TextYAlignment.Top
local previewPadding = Instance.new("UIPadding")
previewPadding.PaddingTop = UDim.new(0, 8)
previewPadding.PaddingLeft = UDim.new(0, 8)
previewPadding.PaddingRight = UDim.new(0, 8)
previewPadding.Parent = previewLabel

local statusLabel = makeLabel("Status", "E: open â€¢ Esc: close", 28, COLORS.orange, 13)
statusLabel.TextSize = 12
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.fromOffset(32, 32)
closeButton.BackgroundColor3 = COLORS.orange
closeButton.TextColor3 = COLORS.background
closeButton.Font = Enum.Font.RobotoMono
closeButton.TextSize = 18
closeButton.Text = "X"
closeButton.Parent = panel
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local function setBoardPreview(text)
	if typeof(text) == "string" then
		previewLabel.Text = "TEAM BOARD\n" .. text
	end
end

local function makeResultText(result)
	local failureText = #result.failures > 0 and table.concat(result.failures, "\nâ€¢ ") or "All configured checks passed."
	return string.format(
		"STATUS: %s\nÎ”v: %.0f / %.0f m/s\nInitial T/W: %.2f\nEstimated Max Q: %.0f Pa @ %.0f m\nInsertion Î¸ error: %.2fÂ° (Â±%.1fÂ°)\nEstimate confidence: %.0f%%\n%s\nMODEL: %s",
		result.success and "SUCCESS" or "FAILURE",
		result.deltaVMps,
		result.deltaVTargetMps,
		result.initialThrustToWeight,
		result.maxQPa,
		result.maxQAltitudeM,
		result.insertionAngleErrorDeg,
		result.angleToleranceDeg,
		result.accuracyPercent,
		failureText,
		result.maxQModel
	)
end

calculateButton.Activated:Connect(function()
	local payload = {}
	for key, box in pairs(fields) do
		local number = tonumber(box.Text)
		if not number then
			resultLabel.TextColor3 = COLORS.red
			resultLabel.Text = "INPUT ERROR: " .. key .. " must be numeric."
			return
		end
		payload[key] = number
	end

	calculateButton.Active = false
	calculateButton.Text = "CALCULATING..."
	local invokeSucceeded, response = pcall(function()
		return calculateRemote:InvokeServer(payload)
	end)
	calculateButton.Active = true
	calculateButton.Text = "CALCULATE"

	if not invokeSucceeded then
		warn("Flight calculation request failed: " .. tostring(response))
		resultLabel.TextColor3 = COLORS.red
		resultLabel.Text = "SERVER ERROR: Calculation could not be completed."
		return
	end
	if typeof(response) ~= "table" then
		resultLabel.TextColor3 = COLORS.red
		resultLabel.Text = "SERVER ERROR: Invalid response from the calculation service."
		return
	end
	if not response.ok then
		resultLabel.TextColor3 = COLORS.red
		resultLabel.Text = "INPUT / SERVICE ERROR: " .. tostring(response.error or "Unknown response")
		return
	end

	local result = response.result
	resultLabel.TextColor3 = result.success and COLORS.green or COLORS.orange
	resultLabel.Text = makeResultText(result)
	if notesBox.Text == "" then
		notesBox.Text = string.format("Î”v %.0f m/s | Max Q %.0f Pa | Î¸ error %.2fÂ° | %s", result.deltaVMps, result.maxQPa, result.insertionAngleErrorDeg, result.success and "GO" or "NO-GO")
	end
end)

submitButton.Activated:Connect(function()
	boardRemote:FireServer("Submit", notesBox.Text)
end)

closeButton.Activated:Connect(function()
	gui.Enabled = false
end)

boardRemote.OnClientEvent:Connect(function(action, value)
	if action == "Open" then
		setBoardPreview(value)
		gui.Enabled = true
		statusLabel.Text = "Enter notes or calculate, then share with the team."
	elseif action == "Updated" then
		setBoardPreview(value)
	elseif action == "Status" then
		statusLabel.Text = tostring(value)
	end
end)

scannerFeedback.OnClientEvent:Connect(function(action, message)
	if action == "Status" then
		statusLabel.Text = tostring(message)
	end
end)

local challengeRemote = ReplicatedStorage:WaitForChild("FlightChallengeRemote")
local challengeCatalog = ReplicatedStorage:WaitForChild("FlightChallengeCatalog")

local simulationToggle = Instance.new("TextButton")
simulationToggle.Name = "SimulationToggle"
simulationToggle.Position = UDim2.fromOffset(48, 12)
simulationToggle.Size = UDim2.fromOffset(142, 32)
simulationToggle.BackgroundColor3 = COLORS.cyan
simulationToggle.TextColor3 = COLORS.background
simulationToggle.Font = Enum.Font.RobotoMono
simulationToggle.TextSize = 12
simulationToggle.Text = "SIMULATIONS"
simulationToggle.ZIndex = 10
simulationToggle.Parent = panel
Instance.new("UICorner", simulationToggle).CornerRadius = UDim.new(0, 6)

local simulationPanel = Instance.new("Frame")
simulationPanel.Name = "SimulationPanel"
simulationPanel.Position = UDim2.fromOffset(14, 52)
simulationPanel.Size = UDim2.new(1, -28, 1, -66)
simulationPanel.BackgroundColor3 = COLORS.background
simulationPanel.BorderSizePixel = 0
simulationPanel.Visible = false
simulationPanel.ZIndex = 5
simulationPanel.Parent = panel

local simulationTitle = Instance.new("TextLabel")
simulationTitle.Size = UDim2.new(1, -150, 0, 30)
simulationTitle.BackgroundTransparency = 1
simulationTitle.Text = "FLIGHT SIMULATIONS // TRAINING LADDER"
simulationTitle.TextColor3 = COLORS.cyan
simulationTitle.Font = Enum.Font.RobotoMono
simulationTitle.TextSize = 16
simulationTitle.TextXAlignment = Enum.TextXAlignment.Left
simulationTitle.ZIndex = 6
simulationTitle.Parent = simulationPanel

local calculatorButton = Instance.new("TextButton")
calculatorButton.AnchorPoint = Vector2.new(1, 0)
calculatorButton.Position = UDim2.new(1, 0, 0, 0)
calculatorButton.Size = UDim2.fromOffset(140, 30)
calculatorButton.BackgroundColor3 = COLORS.orange
calculatorButton.TextColor3 = COLORS.background
calculatorButton.Font = Enum.Font.RobotoMono
calculatorButton.TextSize = 11
calculatorButton.Text = "OPEN CALCULATOR"
calculatorButton.ZIndex = 6
calculatorButton.Parent = simulationPanel
Instance.new("UICorner", calculatorButton).CornerRadius = UDim.new(0, 6)

local simulationStatus = Instance.new("TextLabel")
simulationStatus.Position = UDim2.fromOffset(0, 36)
simulationStatus.Size = UDim2.new(1, 0, 0, 32)
simulationStatus.BackgroundTransparency = 1
simulationStatus.Text = "Calculate a flight first. Then run the unlocked simulation."
simulationStatus.TextColor3 = COLORS.muted
simulationStatus.Font = Enum.Font.RobotoMono
simulationStatus.TextSize = 12
simulationStatus.TextWrapped = true
simulationStatus.TextXAlignment = Enum.TextXAlignment.Left
simulationStatus.ZIndex = 6
simulationStatus.Parent = simulationPanel

local simulationList = Instance.new("ScrollingFrame")
simulationList.Name = "SimulationList"
simulationList.Position = UDim2.fromOffset(0, 74)
simulationList.Size = UDim2.new(1, 0, 1, -74)
simulationList.BackgroundTransparency = 1
simulationList.BorderSizePixel = 0
simulationList.ScrollBarThickness = 4
simulationList.ScrollBarImageColor3 = COLORS.cyan
simulationList.AutomaticCanvasSize = Enum.AutomaticSize.Y
simulationList.CanvasSize = UDim2.new()
simulationList.ZIndex = 6
simulationList.Parent = simulationPanel
local simulationLayout = Instance.new("UIListLayout")
simulationLayout.Padding = UDim.new(0, 8)
simulationLayout.SortOrder = Enum.SortOrder.LayoutOrder
simulationLayout.Parent = simulationList

local function clearSimulationCards()
	for _, child in ipairs(simulationList:GetChildren()) do
		if child:IsA("GuiObject") and child ~= simulationLayout then
			child:Destroy()
		end
	end
end

local function makeSimulationCard(item)
	local card = Instance.new("Frame")
	card.Name = item.id
	card.Size = UDim2.new(1, -8, 0, 156)
	card.BackgroundColor3 = COLORS.panel
	card.BorderSizePixel = 0
	card.LayoutOrder = item.order
	card.ZIndex = 6
	card.Parent = simulationList
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = item.completed and COLORS.green or (item.unlocked and COLORS.cyan or COLORS.muted)
	stroke.Thickness = 1
	stroke.Parent = card

	local header = Instance.new("TextLabel")
	header.Position = UDim2.fromOffset(12, 8)
	header.Size = UDim2.new(1, -170, 0, 24)
	header.BackgroundTransparency = 1
	header.Text = string.format("%d. %s  [%s]", item.order, item.title, item.difficulty)
	header.TextColor3 = item.unlocked and COLORS.text or COLORS.muted
	header.Font = Enum.Font.RobotoMono
	header.TextSize = 13
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.ZIndex = 7
	header.Parent = card

	local description = Instance.new("TextLabel")
	description.Position = UDim2.fromOffset(12, 36)
	description.Size = UDim2.new(1, -24, 0, 34)
	description.BackgroundTransparency = 1
	description.Text = item.description
	description.TextColor3 = COLORS.muted
	description.Font = Enum.Font.RobotoMono
	description.TextSize = 11
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.ZIndex = 7
	description.Parent = card

	local req = item.requirements
	local requirements = Instance.new("TextLabel")
	requirements.Position = UDim2.fromOffset(12, 76)
	requirements.Size = UDim2.new(1, -162, 0, 62)
	requirements.BackgroundTransparency = 1
	requirements.Text = string.format("TARGETS\nÎ”v â‰¥ %.0f m/s | T/W â‰¥ %.2f\nANGLE ERROR â‰¤ %.1fÂ° | MAX Q â‰¤ %.0f Pa", req.minDeltaV, req.minThrustToWeight, req.maxAngleError, req.maxQ)
	requirements.TextColor3 = COLORS.orange
	requirements.Font = Enum.Font.RobotoMono
	requirements.TextSize = 11
	requirements.TextWrapped = true
	requirements.TextXAlignment = Enum.TextXAlignment.Left
	requirements.TextYAlignment = Enum.TextYAlignment.Top
	requirements.ZIndex = 7
	requirements.Parent = card

	local runButton = Instance.new("TextButton")
	runButton.AnchorPoint = Vector2.new(1, 0.5)
	runButton.Position = UDim2.new(1, -12, 0.5, 16)
	runButton.Size = UDim2.fromOffset(132, 38)
	runButton.BackgroundColor3 = item.unlocked and COLORS.cyan or COLORS.panel
	runButton.TextColor3 = item.unlocked and COLORS.background or COLORS.muted
	runButton.Font = Enum.Font.RobotoMono
	runButton.TextSize = 11
	runButton.Text = item.completed and "COMPLETED" or (item.unlocked and "RUN SIMULATION" or "LOCKED")
	runButton.Active = item.unlocked
	runButton.AutoButtonColor = item.unlocked
	runButton.ZIndex = 7
	runButton.Parent = card
	Instance.new("UICorner", runButton).CornerRadius = UDim.new(0, 6)

	if item.unlocked then
		runButton.Activated:Connect(function()
			runButton.Active = false
			runButton.Text = "RUNNING..."
			simulationStatus.TextColor3 = COLORS.orange
			simulationStatus.Text = "Server is validating the latest calculator result..."
			challengeRemote:FireServer("Run", item.id)
		end)
	end
end

local function renderSimulationCatalog(catalog)
	clearSimulationCards()
	if typeof(catalog) ~= "table" then
		simulationStatus.TextColor3 = COLORS.red
		simulationStatus.Text = "Simulation catalog unavailable. Try again."
		return
	end
	for _, item in ipairs(catalog) do
		makeSimulationCard(item)
	end
end

local function showSimulations()
	content.Visible = false
	simulationPanel.Visible = true
	simulationToggle.Text = "WHITEBOARD"
	local succeeded, catalog = pcall(function()
		return challengeCatalog:InvokeServer()
	end)
	if not succeeded then
		simulationStatus.TextColor3 = COLORS.red
		simulationStatus.Text = "Could not load simulations from the server."
		return
	end
	simulationStatus.TextColor3 = COLORS.muted
	simulationStatus.Text = "Calculate a flight first. Then run the unlocked simulation."
	renderSimulationCatalog(catalog)
end

simulationToggle.Activated:Connect(function()
	if simulationPanel.Visible then
		simulationPanel.Visible = false
		content.Visible = true
		simulationToggle.Text = "SIMULATIONS"
	else
		showSimulations()
	end
end)

calculatorButton.Activated:Connect(function()
	simulationPanel.Visible = false
	content.Visible = true
	simulationToggle.Text = "SIMULATIONS"
	statusLabel.Text = "Calculate your flight, then return to SIMULATIONS."
end)

challengeRemote.OnClientEvent:Connect(function(action, payload)
	if action == "Status" then
		simulationStatus.TextColor3 = COLORS.orange
		simulationStatus.Text = tostring(payload)
	elseif action == "Result" and typeof(payload) == "table" then
		local result = payload.result
		simulationStatus.TextColor3 = payload.success and COLORS.green or COLORS.red
		simulationStatus.Text = string.format(
			"%s: %s\nÎ”v %.0f m/s | T/W %.2f | Max Q %.0f Pa | angle error %.2fÂ°",
			payload.success and "SIMULATION PASSED" or "SIMULATION FAILED",
			payload.title,
			result.deltaVMps,
			result.initialThrustToWeight,
			result.maxQPa,
			result.insertionAngleErrorDeg
		)
		renderSimulationCatalog(payload.catalog)
	end
end)
