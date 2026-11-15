local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("TelescopeObservatoryConfig"))
local NasaCatalog = require(script.Parent:WaitForChild("TelescopeNasaCatalog"))
local remote = ReplicatedStorage:WaitForChild(Config.RemoteName)
local observatory = workspace:WaitForChild(Config.ModelName, 60)
if not observatory then
	error("NASA Telescope Observatory model was not found in Workspace.")
end
local terminalFolder = observatory:WaitForChild("Terminal", 30)
local terminal = terminalFolder and terminalFolder:WaitForChild(Config.TerminalName, 30)
local toolDisplays = observatory:WaitForChild("ToolDisplays", 30)
if not terminal or not toolDisplays then
	error("Observatory terminal or collectible display folder is missing.")
end

local selectedFilters = {}
local discoveredByPlayer = {}
local lastActionAt = {}

local function getRoot(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then return root end
	return nil
end

local function isNearTerminal(player)
	local root = getRoot(player)
	return root ~= nil and (root.Position - terminal.Position).Magnitude <= Config.MaximumTerminalDistance
end

local function sendStatus(player, message, colorName)
	remote:FireClient(player, "Status", message, colorName)
end

local function checkCooldown(player, action)
	local now = os.clock()
	local playerActions = lastActionAt[player]
	if not playerActions then
		playerActions = {}
		lastActionAt[player] = playerActions
	end
	local previous = playerActions[action]
	if previous and now - previous < Config.ActionCooldownSeconds then
		return false
	end
	playerActions[action] = now
	return true
end

local function getOwnedTool(player, toolName)
	if typeof(toolName) ~= "string" or (toolName ~= Config.ToolNames.Scanner and toolName ~= Config.ToolNames.CalibrationLens) then
		return nil
	end
	local character = player.Character
	local tool = character and character:FindFirstChild(toolName)
	if tool and tool:IsA("Tool") then return tool end
	return nil
end

local function processRequest(player, action, value)
	if typeof(action) ~= "string" then return end
	if not checkCooldown(player, action) then return end

	if action == "RequestState" then
		selectedFilters[player] = selectedFilters[player] or "Visible"
		remote:FireClient(player, "FilterChanged", selectedFilters[player])
		remote:FireClient(player, "CatalogData", NasaCatalog.GetSnapshot())
		return
	end

	if action == "SetFilter" then
		if not isNearTerminal(player) then
			sendStatus(player, "Move closer to the telescope terminal to change filters.", "Warning")
			return
		end
		if typeof(value) ~= "string" or not Config.Filters[value] then
			sendStatus(player, "That spectral filter is not available.", "Warning")
			return
		end
		selectedFilters[player] = value
		remote:FireClient(player, "FilterChanged", value)
		local status = value == Config.RequiredDiscoveryFilter and "INFRARED BAND ACTIVE // faint thermal signature detected." or string.upper(value .. " BAND ACTIVE // target view updated.")
		sendStatus(player, status, "Normal")
		return
	end

	if action == "Discover" then
		if not isNearTerminal(player) then
			sendStatus(player, "Approach the telescope terminal before logging a discovery.", "Warning")
			return
		end
		if selectedFilters[player] ~= Config.RequiredDiscoveryFilter then
			sendStatus(player, "ANOMALY UNRESOLVED // select the correct spectral filter and scan again.", "Warning")
			return
		end
		if discoveredByPlayer[player] then
			sendStatus(player, "This exoplanet has already been logged during this server session.", "Normal")
			return
		end

		discoveredByPlayer[player] = true
		local currentCount = player:GetAttribute(Config.DiscoveryAttribute)
		if typeof(currentCount) ~= "number" or currentCount ~= currentCount then currentCount = 0 end
		player:SetAttribute(Config.DiscoveryAttribute, math.max(0, currentCount) + 1)
		remote:FireClient(player, "Discovered", player:GetAttribute(Config.DiscoveryAttribute))
		return
	end

	if action == "Analyze" then
		if not isNearTerminal(player) then
			sendStatus(player, "Move within range of the telescope terminal to analyze its target.", "Warning")
			return
		end
		local tool = getOwnedTool(player, value)
		if not tool then
			sendStatus(player, "Equip one of the observatory tools before requesting an analysis.", "Warning")
			return
		end
		local toolType = tool:GetAttribute("ObservatoryToolType")
		if toolType == "Scanner" then
			player:SetAttribute("ObservatoryScannerHintExpiresAt", workspace:GetServerTimeNow() + Config.ScannerHintDurationSeconds)
			remote:FireClient(player, "Hint", "Scanner lock acquired: inspect the bright spot on the planet. Infrared resolves its heat signature.", "Scanner")
		elseif toolType == "CalibrationLens" then
			player:SetAttribute("ObservatoryLensAccuracyBonusPercent", Config.LensAccuracyBonusPercent)
			player:SetAttribute("ObservatoryLensCalibrationExpiresAt", workspace:GetServerTimeNow() + Config.LensCalibrationDurationSeconds)
			remote:FireClient(player, "Hint", "Calibration lens aligned: thermal contrast peaks in the Infrared band.", "CalibrationLens")
		else
			sendStatus(player, "This tool is not configured for observatory analysis.", "Warning")
		end
		return
	end
end

remote.OnServerEvent:Connect(function(player, action, value)
	local ok, err = pcall(processRequest, player, action, value)
	if not ok then
		warn(string.format("Observatory request failed for %s: %s", player.Name, tostring(err)))
		pcall(sendStatus, player, "OBSERVATORY ERROR // request could not be completed.", "Warning")
	end
end)

task.spawn(function()
	local function refreshCatalog()
		if NasaCatalog.Refresh() then
			remote:FireAllClients("CatalogData", NasaCatalog.GetSnapshot())
		end
	end

	refreshCatalog()
	while true do
		task.wait(Config.CatalogRefreshSeconds)
		refreshCatalog()
	end
end)

local function ownsTool(player, toolName)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	return (backpack and backpack:FindFirstChild(toolName) ~= nil)
		or (character and character:FindFirstChild(toolName) ~= nil)
end

local function connectPickup(display)
	if not display:IsA("BasePart") then return end
	local prompt = display:FindFirstChild("PickupPrompt")
	local toolName = display:GetAttribute("ToolName")
	if not prompt or not prompt:IsA("ProximityPrompt") or typeof(toolName) ~= "string" then return end
	local toolTemplate = ServerStorage:FindFirstChild(toolName)
	if not toolTemplate or not toolTemplate:IsA("Tool") then
		warn("Observatory tool template is missing: " .. tostring(toolName))
		return
	end

	prompt.Triggered:Connect(function(player)
		local ok, err = pcall(function()
			local root = getRoot(player)
			if not root or (root.Position - display.Position).Magnitude > Config.MaximumPickupDistance + 2 then return end
			if ownsTool(player, toolName) then
				sendStatus(player, toolName .. " already secured.", "Normal")
				return
			end
			local backpack = player:FindFirstChildOfClass("Backpack")
			if not backpack then
				sendStatus(player, "Inventory is not ready. Try again shortly.", "Warning")
				return
			end
			local clone = toolTemplate:Clone()
			clone.Parent = backpack
			sendStatus(player, toolName .. " collected. Equip it and click to analyze the target.", "Normal")
		end)
		if not ok then
			warn(string.format("Observatory pickup failed for %s: %s", player.Name, tostring(err)))
			sendStatus(player, "TOOL PICKUP ERROR // please try again.", "Warning")
		end
	end)
end

for _, display in ipairs(toolDisplays:GetChildren()) do
	connectPickup(display)
end
toolDisplays.ChildAdded:Connect(connectPickup)

Players.PlayerRemoving:Connect(function(player)
	selectedFilters[player] = nil
	discoveredByPlayer[player] = nil
	lastActionAt[player] = nil
end)
