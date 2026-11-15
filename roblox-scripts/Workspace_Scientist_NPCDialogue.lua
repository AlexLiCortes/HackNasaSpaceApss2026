--[=[
	Scientist NPC Dialogue System
	Shows a room label billboard when the player is close,
	and a detailed dialogue (in English) when the player interacts.
	Reusable: set the attributes on the model to reuse in other rooms.
]=]

local CONFIG = {
	RoomName = "SHIP ASSEMBLY ROOM (VAB)",
	TaskText = "Your mission: select the correct mass and engines for the rocket before moving to the next planning level.",
	DialogueLines = {
		"Welcome aboard, engineer! This is the Ship Assembly Room, our Vehicle Assembly Building.",
		"Your task here is to assemble the rocket: pick the right hull mass and the right set of engines.",
		"Keep this in mind: a lighter hull gives you more speed, while bigger engines give more thrust but burn fuel faster.",
		"Once your build is confirmed, the next planning level will unlock. Good luck!",
	},
	LabelVisibleDistance = 30,
	PromptDistance = 8,
	DialogueDisplayTime = 5,
}

local model = script.Parent
local head = model:FindFirstChild("Head")
local humanoid = model:FindFirstChildOfClass("Humanoid")
if not head or not humanoid then
	warn("[Scientist] Missing Head or Humanoid, dialogue system disabled.")
	return
end

-- Store config as attributes so other NPC instances can reuse this script
model:SetAttribute("RoomName", CONFIG.RoomName)
model:SetAttribute("TaskText", CONFIG.TaskText)

local function createStyledLabel(parent, layoutOrder)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Position = UDim2.fromOffset(0, 0)
	label.Font = Enum.Font.RobotoMono
	label.TextColor3 = Color3.fromRGB(220, 245, 255)
	label.TextScaled = true
	label.TextWrapped = true
	label.LayoutOrder = layoutOrder
	label.Parent = parent
	return label
end

-- // 1. Room label billboard (appears when the player gets close) //
local roomBillboard = Instance.new("BillboardGui")
roomBillboard.Name = "RoomLabel"
roomBillboard.Adornee = head
roomBillboard.Size = UDim2.fromOffset(360, 130)
roomBillboard.StudsOffset = Vector3.new(0, 4, 0)
roomBillboard.AlwaysOnTop = true
roomBillboard.MaxDistance = CONFIG.LabelVisibleDistance -- only renders when the player is near
roomBillboard.LightInfluence = 0

local roomFrame = Instance.new("Frame")
roomFrame.Size = UDim2.fromScale(1, 1)
roomFrame.BackgroundColor3 = Color3.fromRGB(8, 14, 26)
roomFrame.BackgroundTransparency = 0.15
roomFrame.BorderSizePixel = 0
roomFrame.Parent = roomBillboard

local roomStroke = Instance.new("UIStroke")
roomStroke.Color = Color3.fromRGB(0, 220, 255)
roomStroke.Thickness = 2
roomStroke.Parent = roomFrame

local roomPadding = Instance.new("UIPadding")
roomPadding.PaddingTop = UDim.new(0, 8)
roomPadding.PaddingBottom = UDim.new(0, 8)
roomPadding.PaddingLeft = UDim.new(0, 10)
roomPadding.PaddingRight = UDim.new(0, 10)
roomPadding.Parent = roomFrame

local roomLayout = Instance.new("UIListLayout")
roomLayout.FillDirection = Enum.FillDirection.Vertical
roomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
roomLayout.SortOrder = Enum.SortOrder.LayoutOrder
roomLayout.Padding = UDim.new(0, 6)
roomLayout.Parent = roomFrame

local roomNameLabel = createStyledLabel(roomFrame, 1)
roomNameLabel.Text = CONFIG.RoomName
roomNameLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
roomNameLabel.Font = Enum.Font.RobotoMono
roomNameLabel.Size = UDim2.new(1, 0, 0.3, 0)

local roomCorner = Instance.new("UICorner")
roomCorner.CornerRadius = UDim.new(0, 8)
roomCorner.Parent = roomFrame

local taskLabel = createStyledLabel(roomFrame, 2)
taskLabel.Text = CONFIG.TaskText
taskLabel.Size = UDim2.new(1, 0, 0.7, 0)

taskLabel.Parent = roomFrame
roomNameLabel.Parent = roomFrame
roomBillboard.Parent = head

-- // 2. Dialogue billboard (shown on interaction) //
local dialogueBillboard = Instance.new("BillboardGui")
dialogueBillboard.Name = "DialogueLabel"
dialogueBillboard.Adornee = head
dialogueBillboard.Size = UDim2.fromOffset(420, 110)
dialogueBillboard.StudsOffset = Vector3.new(0, 2.5, 0)
dialogueBillboard.AlwaysOnTop = true
dialogueBillboard.MaxDistance = 60
dialogueBillboard.LightInfluence = 0
dialogueBillboard.Enabled = false

local dialogueFrame = Instance.new("Frame")
dialogueFrame.Size = UDim2.fromScale(1, 1)
dialogueFrame.BackgroundColor3 = Color3.fromRGB(8, 14, 26)
dialogueFrame.BackgroundTransparency = 0.05
dialogueFrame.BorderSizePixel = 0
dialogueFrame.Parent = dialogueBillboard
local dialogueStroke = Instance.new("UIStroke")
dialogueStroke.Color = Color3.fromRGB(120, 255, 160)
dialogueStroke.Thickness = 2
dialogueStroke.Parent = dialogueFrame

local dialogueCorner = Instance.new("UICorner")
dialogueCorner.CornerRadius = UDim.new(0, 8)
dialogueCorner.Parent = dialogueFrame

local dialoguePadding = Instance.new("UIPadding")
dialoguePadding.PaddingTop = UDim.new(0, 8)
dialoguePadding.PaddingBottom = UDim.new(0, 8)
dialoguePadding.PaddingLeft = UDim.new(0, 12)
dialoguePadding.PaddingRight = UDim.new(0, 12)
dialoguePadding.Parent = dialogueFrame

local dialogueName = createStyledLabel(dialogueFrame, 1)
dialogueName.Size = UDim2.new(1, 0, 0, 18)
dialogueName.Text = "SCIENTIST"
dialogueName.TextScaled = false
dialogueName.TextSize = 14
dialogueName.TextColor3 = Color3.fromRGB(120, 255, 160)
dialogueName.Font = Enum.Font.RobotoMono
dialogueName.Parent = dialogueFrame

-- Container where dialogue lines stack; old lines fade and get removed
local dialogueLinesFrame = Instance.new("Frame")
dialogueLinesFrame.Name = "LinesFrame"
dialogueLinesFrame.BackgroundTransparency = 1
dialogueLinesFrame.Size = UDim2.new(1, 0, 1, -22)
dialogueLinesFrame.Position = UDim2.new(0, 0, 0, 22)
dialogueLinesFrame.Parent = dialogueFrame

local linesLayout = Instance.new("UIListLayout")
linesLayout.FillDirection = Enum.FillDirection.Vertical
linesLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
linesLayout.SortOrder = Enum.SortOrder.LayoutOrder
linesLayout.Padding = UDim.new(0, 4)
linesLayout.Parent = dialogueLinesFrame

dialogueBillboard.Parent = head

-- // 3. Interaction prompt //
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "TalkPrompt"
prompt.ActionText = "Talk"
prompt.ObjectText = "Scientist"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0
prompt.MaxActivationDistance = CONFIG.PromptDistance
prompt.RequiresLineOfSight = false
prompt.Parent = head

-- // 4. Dialogue cycle logic //
local MAX_VISIBLE_LINES = 3
local TYPEWRITER_SPEED = 0.03
local currentLine = 0
local activeThread = nil
local orderCounter = 0

local function refreshLineFades()
	-- Older lines fade out so the newest one is always the most readable
	local lines = {}
	for _, child in dialogueLinesFrame:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(lines, child)
		end
	end
	table.sort(lines, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	local count = #lines
	for index, line in ipairs(lines) do
		local age = count - index -- 0 = newest
		if age >= MAX_VISIBLE_LINES then
			line:Destroy()
		else
			line.TextTransparency = age * 0.3
			line.TextColor3 = Color3.fromRGB(220, 245, 255)
		end
	end
end

local function typewrite(label, fullText)
	label.Text = ""
	for i = 1, #fullText do
		label.Text = string.sub(fullText, 1, i)
		task.wait(TYPEWRITER_SPEED)
	end
end

prompt.Triggered:Connect(function()
	currentLine = (currentLine % #CONFIG.DialogueLines) + 1
	dialogueBillboard.Enabled = true

	-- Create the new line label
	orderCounter += 1
	local newLine = Instance.new("TextLabel")
	newLine.BackgroundTransparency = 1
	newLine.Size = UDim2.new(1, 0, 0, 28)
	newLine.Font = Enum.Font.RobotoMono
	newLine.TextColor3 = Color3.fromRGB(220, 245, 255)
	newLine.TextSize = 14
	newLine.TextWrapped = true
	newLine.TextXAlignment = Enum.TextXAlignment.Left
	newLine.LayoutOrder = orderCounter
	newLine.Parent = dialogueLinesFrame

	refreshLineFades()

	-- Restart the hide timer each time the player interacts
	if activeThread then
		task.cancel(activeThread)
	end
	activeThread = task.spawn(function()
		typewrite(newLine, CONFIG.DialogueLines[currentLine])
		task.wait(CONFIG.DialogueDisplayTime)
		dialogueBillboard.Enabled = false
		-- Clear all lines so the next conversation starts fresh
		for _, child in dialogueLinesFrame:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		activeThread = nil
	end)
end)
