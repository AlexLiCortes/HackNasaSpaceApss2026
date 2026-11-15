-- Script: NASATelemetryScript (ServerScriptService)
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local API_KEY = "BLwMjpBDPBm6khfRLHbgmHgjB6GFdzLqLtMRtmBH"

local screenPart = Workspace:WaitForChild("NASAScreenPart", 15)
if not screenPart then return end

local surfaceGui = screenPart:FindFirstChildOfClass("SurfaceGui")
if not surfaceGui then return end

-- Limpiar diseÃ±o anterior
for _, child in ipairs(surfaceGui:GetChildren()) do
	child:Destroy()
end

-- Fondo general
local backgroundFrame = Instance.new("Frame")
backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
backgroundFrame.BackgroundColor3 = Color3.fromRGB(8, 14, 24)
backgroundFrame.BorderSizePixel = 0
backgroundFrame.Parent = surfaceGui

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(0, 195, 255)
uiStroke.Thickness = 3
uiStroke.Parent = backgroundFrame

-- Encabezado
local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, 0, 0, 45)
headerFrame.BackgroundColor3 = Color3.fromRGB(14, 24, 38)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = backgroundFrame

local headerText = Instance.new("TextLabel")
headerText.Size = UDim2.new(1, -20, 1, 0)
headerText.Position = UDim2.new(0, 15, 0, 0)
headerText.BackgroundTransparency = 1
headerText.TextColor3 = Color3.fromRGB(0, 255, 170)
headerText.Font = Enum.Font.RobotoMono
headerText.TextSize = 16
headerText.TextXAlignment = Enum.TextXAlignment.Left
headerText.Text = "/// NASA JPL // MONITORING & ORBITS CENTER"
headerText.Parent = headerFrame

-- CONTENEDOR IZQUIERDO: Texto de Datos (Ocupa el 55% del ancho)
local dataDisplay = Instance.new("TextLabel")
dataDisplay.Name = "DataDisplay"
dataDisplay.Size = UDim2.new(0.55, -25, 1, -60)
dataDisplay.Position = UDim2.new(0, 15, 0, 52)
dataDisplay.BackgroundTransparency = 1
dataDisplay.TextColor3 = Color3.fromRGB(200, 235, 255)
dataDisplay.Font = Enum.Font.RobotoMono
dataDisplay.TextSize = 13
dataDisplay.TextXAlignment = Enum.TextXAlignment.Left
dataDisplay.TextYAlignment = Enum.TextYAlignment.Top
dataDisplay.TextWrapped = true
dataDisplay.Text = "ESTABLISHING LINK WITH THE NASA NETWORK...\n\n- Synchronizing telemetry...\n- Verifying planetary defense status..."
dataDisplay.Parent = backgroundFrame

-- CONTENEDOR DERECHO: Marco de Imagen Espacial
local imageFrame = Instance.new("Frame")
imageFrame.Size = UDim2.new(0.42, 0, 1, -70)
imageFrame.Position = UDim2.new(0.57, 0, 0, 52)
imageFrame.BackgroundColor3 = Color3.fromRGB(15, 30, 48) -- Un azul un poco mÃ¡s claro para distinguir el cuadro
imageFrame.BorderSizePixel = 0
imageFrame.Parent = backgroundFrame

local imageStroke = Instance.new("UIStroke")
imageStroke.Color = Color3.fromRGB(0, 195, 255)
imageStroke.Thickness = 1.5
imageStroke.Parent = imageFrame

-- Imagen que mostrarÃ¡ el grÃ¡fico espacial
local spaceImage = Instance.new("ImageLabel")
spaceImage.Name = "SpaceImage"
spaceImage.Size = UDim2.new(1, -10, 1, -30)
spaceImage.Position = UDim2.new(0, 5, 0, 5)
spaceImage.BackgroundTransparency = 1

-- Usaremos un ID de textura oficial garantizado de Roblox Studio (GrÃ¡fico de estrellas/patrÃ³n espacial)
spaceImage.Image = "6023426915" 
spaceImage.ScaleType = Enum.ScaleType.Crop
spaceImage.Parent = imageFrame

local imgCaption = Instance.new("TextLabel")
imgCaption.Size = UDim2.new(1, 0, 0, 20)
imgCaption.Position = UDim2.new(0, 0, 1, -20)
imgCaption.BackgroundTransparency = 1
imgCaption.TextColor3 = Color3.fromRGB(110, 140, 160)
imgCaption.Font = Enum.Font.RobotoMono
imgCaption.TextSize = 10
imgCaption.Text = "CAM_01 // ACTIVE EARTH ORBIT"
imgCaption.Parent = imageFrame

-- FunciÃ³n de actualizaciÃ³n con la API de la NASA (APOD)
local function actualizarPantallaNASA()
	local url = "https://api.nasa.gov/planetary/apod?api_key=" .. API_KEY

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		local data = HttpService:JSONDecode(response)
		local titulo = data.title or "Orbital Report"
		local fecha = data.date or "Hoy"
		local explicacion = data.explanation or "No data."

		if #explicacion > 280 then
			explicacion = string.sub(explicacion, 1, 277) .. "..."
		end

		dataDisplay.Text = string.format(
			"STATUS: [ONLINE]\nDATE: %s\n\n[TARGET]\n> %s\n\n[DESCRIPTION]\n%s",
			fecha,
			titulo,
			explicacion
		)
	else
		dataDisplay.Text = "STATUS: [LOCAL SAFE MODE]\n\n[DEFENSE TELEMETRY]\n- Radars actively tracking NEOs.\n- Trajectories stable.\n- Power systems at 100%."
	end
end

task.spawn(actualizarPantallaNASA)

while true do
	task.wait(600)
	actualizarPantallaNASA()
end