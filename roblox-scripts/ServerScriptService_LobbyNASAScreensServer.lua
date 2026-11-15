-- Script: LobbyNASAScreensServer (ServerScriptService)
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local API_KEY = "DEMO_KEY" -- Puedes reemplazar con tu clave oficial de la NASA

-- 1. Localizar la pantalla en el Lobby
local screenPart = Workspace:WaitForChild("LobbyScreenNEO", 15)
if not screenPart then
	warn("[NASA LOBBY] No se encontrÃ³ la pieza 'LobbyScreenNEO' en el Workspace.")
	return
end

local surfaceGui = screenPart:FindFirstChildOfClass("SurfaceGui")
if not surfaceGui then
	surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Parent = screenPart
end

-- Limpiar elementos viejos y construir diseÃ±o espacial HUD
for _, child in ipairs(surfaceGui:GetChildren()) do
	child:Destroy()
end

local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(6, 12, 20)
background.BorderSizePixel = 0
background.Parent = surfaceGui

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(0, 255, 170)
uiStroke.Thickness = 3
uiStroke.Parent = background

-- Encabezado
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(12, 20, 32)
header.BorderSizePixel = 0
header.Parent = background

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "/// NASA JPL // NEAR-EARTH OBJECT MONITORING NETWORK (NEO)"
title.TextColor3 = Color3.fromRGB(0, 255, 170)
title.Font = Enum.Font.RobotoMono
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Display de datos
local textDisplay = Instance.new("TextLabel")
textDisplay.Size = UDim2.new(1, -30, 1, -70)
textDisplay.Position = UDim2.new(0, 15, 0, 60)
textDisplay.BackgroundTransparency = 1
textDisplay.TextColor3 = Color3.fromRGB(220, 240, 255)
textDisplay.Font = Enum.Font.RobotoMono
textDisplay.TextSize = 14
textDisplay.TextXAlignment = Enum.TextXAlignment.Left
textDisplay.TextYAlignment = Enum.TextYAlignment.Top
textDisplay.TextWrapped = true
textDisplay.Text = "CONNECTING TO NASA RADAR...\n- Analyzing orbital ephemerides..."
textDisplay.Parent = background

-- 2. FunciÃ³n para obtener datos de Objetos Cercanos a la Tierra (NEO)
local function cargarDatosAsteroides()
	local fechaHoy = os.date("%Y-%m-%d")
	local url = string.format("https://api.nasa.gov/neo/rest/v1/feed?start_date=%s&end_date=%s&api_key=%s", fechaHoy, fechaHoy, API_KEY)

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		local data = HttpService:JSONDecode(response)
		local count = data.element_count or 0
		local asteroideEjemplo = nil

		-- Extraer el primer asteroide de la lista de hoy
		if data.near_earth_objects and data.near_earth_objects[fechaHoy] then
			asteroideEjemplo = data.near_earth_objects[fechaHoy][1]
		end

		if asteroideEjemplo then
		local nombre = asteroideEjemplo.name or "Unknown"
			local diametroMax = asteroideEjemplo.estimated_diameter.meters.estimated_diameter_max or 0
		local esPeligroso = asteroideEjemplo.is_potentially_hazardous_asteroid and "PROXIMITY ALERT!" or "SAFE TRAJECTORY"
			local velocidad = asteroideEjemplo.close_approach_data[1].relative_velocity.kilometers_per_hour or "0"

			textDisplay.Text = string.format(
				"NETWORK STATUS: [ONLINE]\n" ..
					"TRACKING DATE: %s\n" ..
					"TOTAL DETECTED TODAY: %d Objects\n\n" ..
					"------------------------------------------\n" ..
					"  PRIMARY TARGET: Asteroid %s\n" ..
					"  ESTIMATED DIAMETER: %.1f meters\n" ..
					"  VELOCITY: %s km/h\n" ..
					"  ASSESSMENT: %s\n" ..
					"------------------------------------------\n\n" ..
					"[SECURE SYSTEM] Data synced with JPL/Caltech.",
				fechaHoy,
				count,
				nombre,
				diametroMax,
				tostring(math.floor(tonumber(velocidad) or 0)),
				esPeligroso
			)
		else
			textDisplay.Text = "NETWORK STATUS: [NO RECENT DETECTIONS]\n\nSensors report no objects on a close approach during this cycle."
		end
	else
		-- Respaldo local seguro si falla la conexiÃ³n
		textDisplay.Text = "NETWORK STATUS: [SAFE MODE - LOCAL BACKUP]\n\n" ..
			"â€¢ Base radars: 100% operational\n" ..
			"â€¢ Lobby telemetry: awaiting reconnection to the NASA API\n" ..
			"â€¢ Protective shields: Inactive / Normal"
	end
end

-- Ejecutar de inmediato al iniciar el juego
task.spawn(cargarDatosAsteroides)

-- Recargar datos cada 10 minutos
while true do
	task.wait(600)
	cargarDatosAsteroides()
end