local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("TelescopeObservatoryConfig"))
local remote = ReplicatedStorage:WaitForChild(Config.RemoteName)
local observatory = workspace:WaitForChild(Config.ModelName, 60)
if not observatory then
	return -- Observatory not present in this place; do not run the client UI.
end
local terminal
local deadline = os.clock() + 30
repeat
	local terminalFolder = observatory:FindFirstChild("Terminal")
	terminal = terminalFolder and terminalFolder:FindFirstChild(Config.TerminalName)
	if not terminal and os.clock() < deadline then
		task.wait(0.5)
	end
until terminal or os.clock() >= deadline
if not terminal then return end
local template = ReplicatedStorage:FindFirstChild("TelescopeSurfaceTemplate")
if not template then return end

local PALETTES = {
	Visible = {planet = Color3.fromRGB(54, 118, 196), accent = Color3.fromRGB(72, 196, 255), haze = Color3.fromRGB(25, 82, 148)},
	Infrared = {planet = Color3.fromRGB(180, 90, 58), accent = Color3.fromRGB(255, 164, 72), haze = Color3.fromRGB(130, 48, 36)},
	Ultraviolet = {planet = Color3.fromRGB(130, 75, 190), accent = Color3.fromRGB(205, 132, 255), haze = Color3.fromRGB(82, 40, 142)},
	["X-Ray"] = {planet = Color3.fromRGB(40, 155, 150), accent = Color3.fromRGB(88, 255, 222), haze = Color3.fromRGB(22, 98, 102)},
}

local gui = template:Clone()
gui.Name = "TelescopeObservatorySurfaceGui"
gui.Adornee = terminal
gui.Face = Enum.NormalId.Front
gui.Active = true
gui.Enabled = true
gui.MaxDistance = 90
gui.Parent = playerGui

local main = gui:WaitForChild("Main")
local planet = main.TargetImage:WaitForChild("Planet")
local planetGlow = main.TargetImage:WaitForChild("PlanetGlow")
local hotspot = main.TargetImage:WaitForChild("AnomalyHotspot")
local hotspotStroke = hotspot:FindFirstChildOfClass("UIStroke")
local statusLabel = main:WaitForChild("StatusText")
local catalogReadout = main:WaitForChild("CatalogReadout")
local targetTitle = main.TargetImage:WaitForChild("TargetTitle")
local targetFooter = main.TargetImage:WaitForChild("TargetFooter")
local selectedFilter = "Visible"
local revealToken = 0
local boundTools = {}
local activeHud
local activeHudStatus

local function setStatus(message, kind)
	statusLabel.Text = "> " .. tostring(message)
	if kind == "Warning" then
		statusLabel.TextColor3 = Color3.fromRGB(255, 160, 95)
	elseif kind == "Success" then
		statusLabel.TextColor3 = Color3.fromRGB(120, 255, 180)
	else
		statusLabel.TextColor3 = Color3.fromRGB(77, 222, 255)
	end
	if activeHudStatus then
		activeHudStatus.Text = tostring(message)
	end
end

local function formatCatalogNumber(value, decimals)
	local number = tonumber(value)
	if not number or number ~= number or number == math.huge or number == -math.huge then
		return "--"
	end
	return string.format("%." .. decimals .. "f", number)
end

local function applyCatalog(data)
	if typeof(data) ~= "table" or typeof(data.name) ~= "string" then
		return
	end

	local name = string.sub(data.name, 1, 48)
	local year = tonumber(data.discoveryYear)
	local yearText = year and tostring(math.floor(year)) or "--"
	local sourceState = data.status == "LIVE" and "LIVE NASA API" or "CACHED NASA REFERENCE"
	catalogReadout.Text = table.concat({
		"NASA EXOPLANET ARCHIVE // " .. name,
		name .. " | YEAR " .. yearText,
		"ORBIT " .. formatCatalogNumber(data.orbitalPeriodDays, 1) .. " d | RADIUS " .. formatCatalogNumber(data.radiusEarth, 2) .. " R_EARTH",
		"DISTANCE " .. formatCatalogNumber(data.distanceParsecs, 1) .. " pc",
		"DATA: " .. sourceState,
	}, "\n")
	targetTitle.Text = "TARGET FIELD // " .. name
	targetFooter.Text = "NASA EXOPLANET ARCHIVE TAP // " .. sourceState
end

local function applyFilter(filterName)
	local palette = PALETTES[filterName]
	if not palette then return end
	selectedFilter = filterName
	planet.BackgroundColor3 = palette.planet
	planetGlow.BackgroundColor3 = palette.haze
	for name in pairs(Config.Filters) do
		local button = main.FilterPanel:FindFirstChild("Filter_" .. name)
		if button and button:IsA("TextButton") then
			local stroke = button:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = name == filterName and palette.accent or Color3.fromRGB(33, 89, 113)
				stroke.Thickness = name == filterName and 3 or 1
			end
			button.BackgroundColor3 = name == filterName and Color3.fromRGB(18, 54, 72) or Color3.fromRGB(10, 24, 38)
		end
	end
end

for filterName in pairs(Config.Filters) do
	local button = main.FilterPanel:WaitForChild("Filter_" .. filterName)
	button.Activated:Connect(function()
		remote:FireServer("SetFilter", filterName)
	end)
end

hotspot.Activated:Connect(function()
	remote:FireServer("Discover")
end)

local function revealAnomaly()
	revealToken += 1
	local thisToken = revealToken
	if hotspotStroke then hotspotStroke.Enabled = true end
	hotspot.BackgroundTransparency = 0.72
	task.delay(Config.ScannerHintDurationSeconds, function()
		if revealToken == thisToken then
			if hotspotStroke then hotspotStroke.Enabled = false end
			hotspot.BackgroundTransparency = 1
		end
	end)
end

remote.OnClientEvent:Connect(function(action, value, extra)
	if action == "FilterChanged" and typeof(value) == "string" then
		applyFilter(value)
	elseif action == "Status" then
		setStatus(value, extra)
	elseif action == "CatalogData" then
		local ok, err = pcall(applyCatalog, value)
		if not ok then
			warn("[TelescopeObservatoryClient] Could not display NASA catalog data: " .. tostring(err))
		end
	elseif action == "Discovered" then
		setStatus("EXOPLANET CONFIRMED // discovery count: " .. tostring(value) .. " // reward credited.", "Success")
		if hotspotStroke then hotspotStroke.Enabled = true end
		hotspot.BackgroundTransparency = 0.72
	elseif action == "Hint" then
		setStatus(value, "Normal")
		if extra == "Scanner" then revealAnomaly() end
	end
end)

local function showToolHud(tool)
	if activeHud then activeHud:Destroy() end
	activeHud = Instance.new("ScreenGui")
	activeHud.Name = "ObservatoryToolHud"
	activeHud.ResetOnSpawn = false
	activeHud.DisplayOrder = 15
	activeHud.Parent = playerGui
	local panel = Instance.new("Frame")
	panel.Name = "Readout"
	panel.AnchorPoint = Vector2.new(1, 1)
	panel.Position = UDim2.new(1, -22, 1, -72)
	panel.Size = UDim2.fromOffset(330, 76)
	panel.BackgroundColor3 = Color3.fromRGB(5, 15, 27)
	panel.BorderSizePixel = 0
	panel.Parent = activeHud
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(43, 216, 255)
	stroke.Thickness = 2
	stroke.Parent = panel
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -18, 0, 25)
	title.Position = UDim2.fromOffset(9, 6)
	title.BackgroundTransparency = 1
	title.Text = string.upper(tool.Name) .. " // ACTIVE"
	title.TextColor3 = Color3.fromRGB(255, 155, 72)
	title.Font = Enum.Font.RobotoMono
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel
	activeHudStatus = Instance.new("TextLabel")
	activeHudStatus.Size = UDim2.new(1, -18, 0, 35)
	activeHudStatus.Position = UDim2.fromOffset(9, 34)
	activeHudStatus.BackgroundTransparency = 1
	activeHudStatus.Text = "Click to analyze the telescope target."
	activeHudStatus.TextColor3 = Color3.fromRGB(86, 223, 255)
	activeHudStatus.Font = Enum.Font.RobotoMono
	activeHudStatus.TextSize = 11
	activeHudStatus.TextWrapped = true
	activeHudStatus.TextXAlignment = Enum.TextXAlignment.Left
	activeHudStatus.Parent = panel
end

local function hideToolHud()
	if activeHud then activeHud:Destroy() end
	activeHud = nil
	activeHudStatus = nil
end

local function bindTool(instance)
	if not instance:IsA("Tool") or boundTools[instance] then return end
	if instance.Name ~= Config.ToolNames.Scanner and instance.Name ~= Config.ToolNames.CalibrationLens then return end
	boundTools[instance] = true
	instance.Equipped:Connect(function()
		showToolHud(instance)
	end)
	instance.Unequipped:Connect(hideToolHud)
	instance.Activated:Connect(function()
		if instance.Parent == player.Character then
			remote:FireServer("Analyze", instance.Name)
		end
	end)
	instance.AncestryChanged:Connect(function(_, parent)
		if not parent then
			boundTools[instance] = nil
		end
	end)
end

local backpack = player:WaitForChild("Backpack")
backpack.ChildAdded:Connect(bindTool)
for _, child in ipairs(backpack:GetChildren()) do bindTool(child) end

local function bindCharacter(character)
	character.ChildAdded:Connect(bindTool)
	for _, child in ipairs(character:GetChildren()) do bindTool(child) end
end
if player.Character then bindCharacter(player.Character) end
player.CharacterAdded:Connect(bindCharacter)

applyFilter("Visible")
remote:FireServer("RequestState")
