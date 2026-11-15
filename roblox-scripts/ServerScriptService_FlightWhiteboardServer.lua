local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local REMOTE_NAME = "ActualizarPizarronVuelo"
local BOARD_NAME = "PizarronEscrituraVuelo"
local MAX_TEXT_BYTES = 400
local SUBMIT_COOLDOWN_SECONDS = 3
local OPEN_COOLDOWN_SECONDS = 1
local MAX_INTERACTION_DISTANCE = 16

local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if remote and not remote:IsA("RemoteEvent") then
	error(REMOTE_NAME .. " exists but is not a RemoteEvent.")
end
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = REMOTE_NAME
	remote.Parent = ReplicatedStorage
end

local board = workspace:WaitForChild("FlightSimulationSystem"):WaitForChild(BOARD_NAME)
local boardLabel = board:WaitForChild("PizarronGui"):WaitForChild("BoardPanel"):WaitForChild("BoardText")
local prompt = board:FindFirstChild("OpenWhiteboardPrompt")
if not prompt then
	prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenWhiteboardPrompt"
	prompt.ActionText = "Open whiteboard"
	prompt.ObjectText = "FLIGHT NOTES"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = board
end

local lastSubmitAt = {}
local lastOpenAt = {}

local function isNearBoard(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - board.Position).Magnitude <= MAX_INTERACTION_DISTANCE
end

local function cleanText(text)
	text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
	text = text:gsub("[%z\1-\8\11\12\14-\31\127]", "")
	return text:match("^%s*(.-)%s*$") or ""
end

prompt.Triggered:Connect(function(player)
	local now = os.clock()
	if lastOpenAt[player] and now - lastOpenAt[player] < OPEN_COOLDOWN_SECONDS then return end
	if not isNearBoard(player) then return end
	lastOpenAt[player] = now
	remote:FireClient(player, "Open", boardLabel.Text)
end)

remote.OnServerEvent:Connect(function(player, action, text)
	if action ~= "Submit" or typeof(text) ~= "string" then return end
	if #text > MAX_TEXT_BYTES then
		remote:FireClient(player, "Status", "Notes are limited to 400 bytes.")
		return
	end
	if not isNearBoard(player) then
		remote:FireClient(player, "Status", "Move closer to the flight whiteboard to submit.")
		return
	end

	local now = os.clock()
	if lastSubmitAt[player] and now - lastSubmitAt[player] < SUBMIT_COOLDOWN_SECONDS then
		remote:FireClient(player, "Status", "Please wait before submitting again.")
		return
	end
	lastSubmitAt[player] = now

	local cleanedText = cleanText(text)
	if cleanedText == "" then
		remote:FireClient(player, "Status", "Enter notes before submitting.")
		return
	end

	local filterSucceeded, filterResult = pcall(function()
		return TextService:FilterStringAsync(cleanedText, player.UserId)
	end)
	if not filterSucceeded then
		warn(string.format("Whiteboard text filtering failed for %s: %s", player.Name, tostring(filterResult)))
		remote:FireClient(player, "Status", "Text filtering failed. Try again shortly.")
		return
	end

	local broadcastSucceeded, filteredText = pcall(function()
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)
	if not broadcastSucceeded then
		warn(string.format("Whiteboard broadcast filtering failed for %s: %s", player.Name, tostring(filteredText)))
		remote:FireClient(player, "Status", "Text filtering failed. Try again shortly.")
		return
	end

	boardLabel.Text = string.format("> TEAM FLIGHT NOTES\nOPERATOR: @%s\n%s", player.Name, filteredText)
	remote:FireAllClients("Updated", boardLabel.Text)
	remote:FireClient(player, "Status", "Notes filtered and synced to the team board.")
end)

Players.PlayerRemoving:Connect(function(player)
	lastSubmitAt[player] = nil
	lastOpenAt[player] = nil
end)
