-- Engineer Bots: simple English chat-bubble dialogue.
-- Each bot shows native Roblox chat bubbles when players interact with it.
local ChatService = game:GetService("Chat")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BOT_FOLDER_NAME = "EngineerBots"
local AMBIENT_MIN_SECONDS = 40
local AMBIENT_MAX_SECONDS = 70
local PLAYER_NEARBY_DISTANCE = 90
local DIALOGUE_COOLDOWN_SECONDS = 3

local BOT_CONFIG = {
	EngineerBotISS = {
		DisplayName = "Orbital Engineer",
		AccentColor = Color3.fromRGB(0, 215, 235),
		DialogueLines = {
			"Hello, engineer! I am the ISS support unit.",
			"My job is to help you verify your orbital calculations before launch.",
			"The ISS completes one orbit around Earth in about 90 minutes.",
			"Check the telemetry panel: thrust, angle and Delta-V must be within limits.",
			"All systems green? You are cleared to proceed. Good luck up there!",
		},
	},
	EngineerBotMars = {
		DisplayName = "Rover Engineer",
		AccentColor = Color3.fromRGB(255, 156, 61),
		DialogueLines = {
			"Hi there! I am the Mars mission support unit.",
			"A Martian day lasts about 24 hours and 39 minutes.",
			"Perseverance landed in Jezero Crater on February 18, 2021.",
			"Rovers like Curiosity and Perseverance scout the surface so humans can follow.",
			"Always verify your mass, fuel and Delta-V margins before launch.",
		},
	},
}

local AMBIENT_LINES = {
	"Mission starts soon!",
	"Help! I dropped my coffee on the server!",
	"Check those Delta-V calculations again.",
	"The coffee is cold and the rockets are hot.",
	"Has anyone seen my anti-gravity wrench?",
}

local botFolder = Workspace:FindFirstChild(BOT_FOLDER_NAME)
if not botFolder then
	botFolder = Instance.new("Folder")
	botFolder.Name = BOT_FOLDER_NAME
	botFolder.Parent = Workspace
end

-- Disable legacy dialogue prompts on duplicate bots outside the managed folder
local function getEngineerModel(instance)
	local current = instance.Parent
	while current and current ~= Workspace do
		if current:IsA("Model") and BOT_CONFIG[current.Name] then
			return current
		end
		current = current.Parent
	end
	return nil
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
	local model = getEngineerModel(descendant)
	if model and model.Parent ~= botFolder and descendant:IsA("ProximityPrompt") and descendant.Name == "TalkPrompt" then
		descendant.Enabled = false
	end
end

local function addRobotPart(model, name, size, relativeCFrame, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = relativeCFrame
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function createBot(name, config)
	local bot = Instance.new("Model")
	bot.Name = name
	bot:SetAttribute("DisplayName", config.DisplayName)
	bot:SetAttribute("Role", "Engineer")

	local dark = Color3.fromRGB(18, 30, 43)
	local metal = Color3.fromRGB(88, 108, 121)
	local root = addRobotPart(bot, "Root", Vector3.new(0.5, 0.5, 0.5), CFrame.new(), dark, Enum.Material.SmoothPlastic)
	root.Transparency = 1
	root.CanQuery = false
	root.CastShadow = false
	bot.PrimaryPart = root

	addRobotPart(bot, "Torso", Vector3.new(2.2, 2.4, 1.3), CFrame.new(0, 0, 0), dark, Enum.Material.Metal)
	local head = addRobotPart(bot, "Head", Vector3.new(1.7, 1.55, 1.35), CFrame.new(0, 1.95, 0), metal, Enum.Material.Metal)
	addRobotPart(bot, "Visor", Vector3.new(1.35, 0.42, 0.08), CFrame.new(0, 2.05, -0.72), config.AccentColor, Enum.Material.Neon)
	addRobotPart(bot, "ChestDisplay", Vector3.new(0.9, 0.48, 0.08), CFrame.new(0, 0.45, -0.69), config.AccentColor, Enum.Material.Neon)
	addRobotPart(bot, "LeftArm", Vector3.new(0.72, 2.0, 0.82), CFrame.new(-1.45, -0.02, 0), metal, Enum.Material.Metal)
	addRobotPart(bot, "RightArm", Vector3.new(0.72, 2.0, 0.82), CFrame.new(1.45, -0.02, 0), metal, Enum.Material.Metal)
	addRobotPart(bot, "LeftLeg", Vector3.new(0.82, 1.55, 1.0), CFrame.new(-0.58, -1.93, 0), dark, Enum.Material.Metal)
	addRobotPart(bot, "RightLeg", Vector3.new(0.82, 1.55, 1.0), CFrame.new(0.58, -1.93, 0), dark, Enum.Material.Metal)

	bot.Parent = botFolder
	return bot, head
end

local function ensureBot(name, config)
	local bot = botFolder:FindFirstChild(name)
	if bot and not bot:IsA("Model") then
		warn(string.format("[EngineerBots] %s exists but is not a Model; skipping it.", name))
		return nil
	end
	local head
	if not bot then
		bot, head = createBot(name, config)
	else
		head = bot:FindFirstChild("Head")
	end

	local root = bot.PrimaryPart or bot:FindFirstChild("Root")
	if not head or not head:IsA("BasePart") or not root or not root:IsA("BasePart") then
		warn(string.format("[EngineerBots] %s needs BasePart children named Head and Root; skipping it.", name))
		return nil
	end
	bot.PrimaryPart = root

	local prompt = head:FindFirstChild("TalkPrompt")
	if prompt and not prompt:IsA("ProximityPrompt") then
		warn(string.format("[EngineerBots] %s.Head.TalkPrompt is not a ProximityPrompt; skipping interaction setup.", name))
		return nil
	end
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TalkPrompt"
		prompt.Parent = head
	end
	prompt.ActionText = "Talk"
	prompt.ObjectText = config.DisplayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true

	return { model = bot, head = head, prompt = prompt, config = config }
end

local bots = {}
for name, config in pairs(BOT_CONFIG) do
	table.insert(bots, ensureBot(name, config))
end

local reference = Workspace:FindFirstChild("LobbyScreenNEO")
local floorY = 3
if reference and reference:IsA("BasePart") then
	floorY = reference.Position.Y - reference.Size.Y / 2 + 2.8
end

local function placeBot(botInfo, screenName)
	if not botInfo then
		return
	end
	local screen = Workspace:FindFirstChild(screenName)
	if not screen or not screen:IsA("BasePart") then
		warn(string.format("[EngineerBots] Could not place %s: %s is missing or not a BasePart.", botInfo.model.Name, screenName))
		return
	end
	local target = screen.CFrame * CFrame.new(0, floorY - screen.Position.Y, -8)
	botInfo.model:PivotTo(target)
end

placeBot(bots[1], "LobbyScreenISS")
placeBot(bots[2], "LobbyScreenMars")

local function speak(botInfo, message, color)
	if not botInfo or not botInfo.head.Parent then
		return
	end
	local ok, err = pcall(function()
		ChatService:Chat(botInfo.head, message, color)
	end)
	if not ok then
		warn(string.format("[EngineerBots] Chat:Chat failed for %s: %s", botInfo.model.Name, tostring(err)))
	end
end

-- Simple interaction: each press shows the next dialogue line as a chat bubble
local lastTalkAt = {}
local lineIndex = {}

local function connectDialogue(botInfo)
	if not botInfo then
		return
	end
	botInfo.prompt.Triggered:Connect(function(player)
		local now = os.clock()
		if lastTalkAt[player] and now - lastTalkAt[player] < DIALOGUE_COOLDOWN_SECONDS then
			return
		end
		lastTalkAt[player] = now
		local lines = botInfo.config.DialogueLines
		local bot = botInfo.model
		lineIndex[bot] = ((lineIndex[bot] or 0) % #lines) + 1
		speak(botInfo, lines[lineIndex[bot]], Enum.ChatColor.Blue)
	end)
end

for _, botInfo in ipairs(bots) do
	connectDialogue(botInfo)
end

Players.PlayerRemoving:Connect(function(player)
	lastTalkAt[player] = nil
end)

-- Occasional ambient bubbles when players are nearby
local function hasPlayerNearby(position, maxDistance)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - position).Magnitude <= maxDistance then
			return true
		end
	end
	return false
end

local lastSpeechAt = 0

task.spawn(function()
	local lastLineIndex = {}
	while true do
		task.wait(math.random(AMBIENT_MIN_SECONDS, AMBIENT_MAX_SECONDS))
		local available = {}
		for _, botInfo in ipairs(bots) do
			if botInfo and botInfo.head.Parent and hasPlayerNearby(botInfo.head.Position, PLAYER_NEARBY_DISTANCE) then
				table.insert(available, botInfo)
			end
		end
		if #available > 0 and os.clock() - lastSpeechAt >= 8 then
			local botInfo = available[math.random(1, #available)]
			local index = math.random(1, #AMBIENT_LINES)
			if #AMBIENT_LINES > 1 and index == lastLineIndex[botInfo.model] then
				index = index % #AMBIENT_LINES + 1
			end
			lastLineIndex[botInfo.model] = index
			lastSpeechAt = os.clock()
			speak(botInfo, AMBIENT_LINES[index], Enum.ChatColor.Green)
		end
	end
end)