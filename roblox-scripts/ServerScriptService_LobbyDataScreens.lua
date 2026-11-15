-- Builds the ISS and Mars HUD screens and refreshes public telemetry with safe fallbacks.
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local REFERENCE_NAME = "LobbyScreenNEO"
local SCREEN_SIZE = Vector3.new(14, 8, 0.6)
local GAP = 2
local ISS_REFRESH_SECONDS = 60
local MARS_REFRESH_SECONDS = 600

local reference = Workspace:WaitForChild(REFERENCE_NAME, 15)
if not reference or not reference:IsA("BasePart") then
	warn("[LobbyDataScreens] Workspace.LobbyScreenNEO must be a BasePart; screen setup stopped.")
	return
end

local function createLabel(parent, name, text, position, size, textSize, color, alignment)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.RobotoMono
	label.Text = text
	label.TextColor3 = color
	label.TextSize = textSize
	label.TextWrapped = true
	label.TextXAlignment = alignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 3
	label.Parent = parent
	return label
end

local function getOrCreateScreen(name, sideOffset, titleText, accentColor, initialText)
	local screen = Workspace:FindFirstChild(name)
	if screen and not screen:IsA("BasePart") then
		warn(string.format("[LobbyDataScreens] %s exists but is not a BasePart; skipping it.", name))
		return nil
	end

	if not screen then
		screen = Instance.new("Part")
		screen.Name = name
		screen.Parent = Workspace
	end

	screen.Anchored = true
	screen.CanCollide = false
	screen.Material = Enum.Material.SmoothPlastic
	screen.Color = Color3.fromRGB(7, 15, 27)
	screen.Size = SCREEN_SIZE
	screen.CFrame = reference.CFrame * CFrame.new(sideOffset, 0, 0)

	local surface = screen:FindFirstChildOfClass("SurfaceGui")
	if not surface then
		surface = Instance.new("SurfaceGui")
		surface.Name = "DataSurface"
		surface.Parent = screen
	end
	surface.Adornee = screen
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surface.CanvasSize = Vector2.new(1200, 720)
	surface.AlwaysOnTop = false
	surface.LightInfluence = 0
	surface.MaxDistance = 300
	surface.Enabled = true
	surface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	for _, child in ipairs(surface:GetChildren()) do
		child:Destroy()
	end

	local background = Instance.new("Frame")
	background.Name = "HUD"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(7, 15, 27)
	background.BorderSizePixel = 0
	background.ZIndex = 1
	background.Parent = surface

	local outline = Instance.new("UIStroke")
	outline.Color = accentColor
	outline.Thickness = 4
	outline.Transparency = 0.12
	outline.Parent = background

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 76)
	header.BackgroundColor3 = Color3.fromRGB(12, 27, 43)
	header.BorderSizePixel = 0
	header.ZIndex = 2
	header.Parent = background

	local accent = Instance.new("Frame")
	accent.Name = "AccentLine"
	accent.Size = UDim2.new(1, 0, 0, 5)
	accent.Position = UDim2.new(0, 0, 1, -5)
	accent.BackgroundColor3 = accentColor
	accent.BorderSizePixel = 0
	accent.ZIndex = 3
	accent.Parent = header

	createLabel(header, "Title", titleText, UDim2.new(0, 28, 0, 0), UDim2.new(0.72, -28, 1, -5), 30, accentColor)
	local status = createLabel(header, "Status", "SYNCING", UDim2.new(0.72, 0, 0, 0), UDim2.new(0.26, -20, 1, -5), 20, Color3.fromRGB(255, 171, 82), Enum.TextXAlignment.Right)

	local content = createLabel(background, "Data", initialText, UDim2.new(0, 32, 0, 104), UDim2.new(1, -64, 1, -170), 32, Color3.fromRGB(220, 237, 250))
	content.TextYAlignment = Enum.TextYAlignment.Top

	local footer = createLabel(background, "Footer", "SOURCE: PUBLIC API // LOCAL BACKUP IF NO LINK", UDim2.new(0, 32, 1, -54), UDim2.new(1, -64, 0, 32), 17, Color3.fromRGB(104, 151, 177))
	footer.TextYAlignment = Enum.TextYAlignment.Center

	return { part = screen, gui = surface, status = status, content = content }
end

local horizontalOffset = reference.Size.X / 2 + SCREEN_SIZE.X / 2 + GAP
local issScreen = getOrCreateScreen("LobbyScreenISS", -horizontalOffset, "/// NASA // ISS ORBITAL TELEMETRY", Color3.fromRGB(0, 215, 235), "Connecting to orbital tracking...\n\nAwaiting International Space Station coordinates.")
local marsScreen = getOrCreateScreen("LobbyScreenMars", horizontalOffset, "/// NASA // MARS ROVER MISSION", Color3.fromRGB(255, 156, 61), "Connecting to the Curiosity mission manifest...")

local lastWarningAt = {}
local function warnRateLimited(source, message)
	local now = os.clock()
	if not lastWarningAt[source] or now - lastWarningAt[source] >= 300 then
		lastWarningAt[source] = now
		warn(string.format("[LobbyDataScreens/%s] %s", source, tostring(message)))
	end
end

local function updateIss()
	if not issScreen or not issScreen.part.Parent then
		return
	end

	local ok, data = pcall(function()
		local response = HttpService:GetAsync("https://api.wheretheiss.at/v1/satellites/25544")
		local payload = HttpService:JSONDecode(response)
		local latitude = tonumber(payload.latitude)
		local longitude = tonumber(payload.longitude)
		local velocity = tonumber(payload.velocity)
		if not latitude or not longitude or not velocity then
			error("ISS response is missing numeric latitude, longitude, or velocity")
		end
		return {
			latitude = latitude,
			longitude = longitude,
			velocity = velocity,
			timestamp = tonumber(payload.timestamp) or os.time(),
		}
	end)

	if ok then
		issScreen.status.Text = "LIVE LINK"
		issScreen.status.TextColor3 = Color3.fromRGB(0, 255, 170)
		issScreen.content.Text = string.format(
			"INTERNATIONAL SPACE STATION\n\nLATITUDE:  %+.4f\u{00B0}\nLONGITUDE: %+.4f\u{00B0}\nVELOCITY: %.0f km/h\n\nUPDATED: %s",
			data.latitude,
			data.longitude,
			data.velocity,
			os.date("!%Y-%m-%d %H:%M:%S UTC", data.timestamp)
		)
		lastWarningAt.ISS = nil
	else
		issScreen.status.Text = "BACKUP MODE"
		issScreen.status.TextColor3 = Color3.fromRGB(255, 171, 82)
		issScreen.content.Text = "INTERNATIONAL SPACE STATION\n\nLATITUDE:  0.0000\u{00B0} (SIMULATED)\nLONGITUDE: 0.0000\u{00B0} (SIMULATED)\nVELOCITY: ~27,600 km/h (REFERENCE)\n\nNO CONNECTION: THESE VALUES ARE NOT LIVE TELEMETRY."
		warnRateLimited("ISS", data)
	end
end

local curiosityLandingEpoch = DateTime.fromUniversalTime(2012, 8, 6, 5, 17, 0).UnixTimestamp
local function estimatedCuriositySol()
	local secondsPerSol = 88775.244
	return math.max(0, math.floor((os.time() - curiosityLandingEpoch) / secondsPerSol))
end

local function updateMars()
	if not marsScreen or not marsScreen.part.Parent then
		return
	end

	local ok, data = pcall(function()
		local response = HttpService:GetAsync("https://api.nasa.gov/mars-photos/api/v1/manifests/curiosity?api_key=DEMO_KEY")
		local payload = HttpService:JSONDecode(response)
		local manifest = payload.photo_manifest
		if type(manifest) ~= "table" then
			error("NASA response did not contain a photo_manifest")
		end
		local sol = tonumber(manifest.max_sol)
		local photos = tonumber(manifest.total_photos)
		if not sol or not photos or type(manifest.status) ~= "string" then
			error("Curiosity manifest is missing status or sol data")
		end
		return {
			status = string.upper(manifest.status),
			sol = sol,
			photos = photos,
			maxDate = tostring(manifest.max_date or "N/A"),
		}
	end)

	if ok then
		marsScreen.status.Text = "NASA / API"
		marsScreen.status.TextColor3 = Color3.fromRGB(0, 255, 170)
		marsScreen.content.Text = string.format(
			"CURIOSITY // GALE CRATER\n\nMISSION STATUS: %s\nLATEST SOL: %d\nPHOTOS IN MANIFEST: %d\nLOG DATE: %s\n\nONE MARTIAN SOL LASTS ~24 h 39 min.",
			data.status,
			data.sol,
			data.photos,
			data.maxDate
		)
		lastWarningAt.Mars = nil
	else
		marsScreen.status.Text = "BACKUP MODE"
		marsScreen.status.TextColor3 = Color3.fromRGB(255, 171, 82)
		marsScreen.content.Text = string.format(
				"CURIOSITY // GALE CRATER\n\nSTATUS: NO LIVE VERIFICATION\nESTIMATED SOL: ~%d (OFFLINE CALCULATION)\n\nCuriosity landed on August 6, 2012.\nOne Martian sol lasts about 24 h 39 min.\n\nOfficial status and sol require a NASA connection.",
			estimatedCuriositySol()
		)
		warnRateLimited("Mars", data)
	end
end

task.spawn(function()
	while issScreen and issScreen.part.Parent do
		updateIss()
		task.wait(ISS_REFRESH_SECONDS)
	end
end)

task.spawn(function()
	while marsScreen and marsScreen.part.Parent do
		updateMars()
		task.wait(MARS_REFRESH_SECONDS)
	end
end)
