--[[
	MisionesController - LÃ³gica del menÃº de misiones espaciales
	Seleccionar planeta -> ver detalles -> confirmar / abortar
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = script.Parent

local setMisionEvent = ReplicatedStorage:WaitForChild("SetMisionEvent")

-- Datos oficiales de planetas
local PLANETAS = {
	Luna = { dificultad = "Low", costo = 500, descripcion = "Complete a low-orbit systems test and return with the spacecraft fully operational." },
	Marte = { dificultad = "Medium", costo = 2500, descripcion = "Deliver a remote science package, survive a long-duration flight, and return safely." },
	Venus = { dificultad = "High", costo = 4000, descripcion = "Enter a corrosive, high-temperature atmosphere and transmit readings before extraction." },
	Mercurio = { dificultad = "Very High", costo = 6000, descripcion = "Perform a precision survey through extreme thermal cycles with limited communication windows." },
	["JÃºpiter"] = { dificultad = "Extreme", costo = 12000, descripcion = "Probe the upper atmosphere, withstand intense radiation, and escape before systems fail." },
	Saturno = { dificultad = "Extreme+", costo = 18000, descripcion = "Navigate the ring system, map a target moon, and complete the return burn with no margin for error." },
	Urano = { dificultad = "Critical", costo = 25000, descripcion = "Cross the outer-system darkness, stabilize the spacecraft during a long blackout, and recover the probe." },
	Neptuno = { dificultad = "Catastrophic", costo = 35000, descripcion = "Reach the system frontier, survive violent storms, transmit critical data, and return against the clock." },
}

-- English display names only (internal keys stay unchanged)
local PLANET_NAMES_EN = { Luna = "Moon", Marte = "Mars", Venus = "Venus", Mercurio = "Mercury", ["JÃºpiter"] = "Jupiter", Saturno = "Saturn", Urano = "Uranus", Neptuno = "Neptune" }

local marco = gui:WaitForChild("MainFrame")
local lista = marco:WaitForChild("PlanetsList")
local detalles = marco:WaitForChild("DetailsPanel")
local btnCerrar = marco:FindFirstChild("CloseButton")
	or (marco:FindFirstChild("Header") and marco.Header:FindFirstChild("CloseButton"))

local placeholder = detalles:WaitForChild("Placeholder")
local missionTitle = detalles:WaitForChild("MissionTitle")
local planetLabel = detalles:WaitForChild("PlanetLabel")
local costBox = detalles:WaitForChild("CostBox")
local difficultyBox = detalles:WaitForChild("DifficultyBox")
local btnConfirmar = detalles:WaitForChild("ConfirmButton")
local acceptedMessage = detalles:WaitForChild("AcceptedMessage")
local btnAbortar = detalles:WaitForChild("AbortButton")

local COLOR_CIAN = Color3.fromRGB(0, 195, 255)
local COLOR_VERDE = Color3.fromRGB(0, 255, 140)
local COLOR_TEXTO = Color3.fromRGB(200, 235, 255)

local planetaSeleccionado = nil
local cerrarAutoToken = nil
local ventanaDetalles
local tituloDetalles
local descripcionDetalles
local btnVerDetalles

local function cerrarVentanaDetalles()
	if ventanaDetalles then
		ventanaDetalles.Visible = false
	end
end

local function abrirVentanaDetalles()
	if not planetaSeleccionado or not ventanaDetalles then return end

	local datos = PLANETAS[planetaSeleccionado]
	if not datos then
		return
	end

	tituloDetalles.Text = "MISSION BRIEF: " .. string.upper(PLANET_NAMES_EN[planetaSeleccionado] or planetaSeleccionado)
	descripcionDetalles.Text = datos.descripcion
	ventanaDetalles.Visible = true
end

local function crearVentanaDetalles()
	local overlay = Instance.new("Frame")
	overlay.Name = "MissionDetailsOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.Visible = false
	overlay.ZIndex = 20
	overlay.Parent = gui

	local panel = Instance.new("Frame")
	panel.Name = "MissionDetailsWindow"
	panel.Size = UDim2.fromScale(0.55, 0.48)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(8, 12, 16)
	panel.BorderSizePixel = 0
	panel.ZIndex = 21
	panel.Parent = overlay

	local borde = Instance.new("UIStroke")
	borde.Color = COLOR_CIAN
	borde.Thickness = 2
	borde.Parent = panel
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, 8)
	esquinas.Parent = panel

	local titulo = Instance.new("TextLabel")
	titulo.Name = "Titulo"
	titulo.Size = UDim2.new(1, -60, 0, 42)
	titulo.Position = UDim2.fromOffset(14, 8)
	titulo.BackgroundTransparency = 1
	titulo.Font = Enum.Font.RobotoMono
	titulo.TextColor3 = COLOR_CIAN
	titulo.TextSize = 14
	titulo.TextXAlignment = Enum.TextXAlignment.Left
	titulo.ZIndex = 22
	titulo.Parent = panel

	local cerrar = Instance.new("TextButton")
	cerrar.Size = UDim2.fromOffset(32, 32)
	cerrar.Position = UDim2.new(1, -42, 0, 10)
	cerrar.BackgroundColor3 = Color3.fromRGB(20, 28, 36)
	cerrar.BorderSizePixel = 0
	cerrar.Text = "X"
	cerrar.TextColor3 = Color3.fromRGB(255, 70, 90)
	cerrar.Font = Enum.Font.RobotoMono
	cerrar.TextSize = 14
	cerrar.ZIndex = 22
	cerrar.Parent = panel
	cerrar.Activated:Connect(cerrarVentanaDetalles)

	local descripcionTitulo = Instance.new("TextLabel")
	descripcionTitulo.Size = UDim2.new(1, -28, 0, 20)
	descripcionTitulo.Position = UDim2.fromOffset(14, 58)
	descripcionTitulo.BackgroundTransparency = 1
	descripcionTitulo.Font = Enum.Font.RobotoMono
	descripcionTitulo.Text = "DESCRIPCIÃ“N"
	descripcionTitulo.TextColor3 = COLOR_TEXTO
	descripcionTitulo.TextSize = 10
	descripcionTitulo.TextXAlignment = Enum.TextXAlignment.Left
	descripcionTitulo.ZIndex = 22
	descripcionTitulo.Parent = panel

	local descripcion = Instance.new("TextLabel")
	descripcion.Name = "Descripcion"
	descripcion.Size = UDim2.new(1, -28, 1, -104)
	descripcion.Position = UDim2.fromOffset(14, 78)
	descripcion.BackgroundColor3 = Color3.fromRGB(20, 28, 36)
	descripcion.BorderSizePixel = 0
	descripcion.Font = Enum.Font.RobotoMono
	descripcion.TextColor3 = COLOR_TEXTO
	descripcion.TextSize = 11
	descripcion.TextWrapped = true
	descripcion.TextXAlignment = Enum.TextXAlignment.Left
	descripcion.TextYAlignment = Enum.TextYAlignment.Top
	descripcion.ZIndex = 22
	descripcion.Parent = panel

	ventanaDetalles = overlay
	tituloDetalles = titulo
	descripcionDetalles = descripcion
end

crearVentanaDetalles()

btnVerDetalles = Instance.new("TextButton")
btnVerDetalles.Name = "MissionDetailsButton"
btnVerDetalles.Size = UDim2.new(1, -24, 0, 38)
btnVerDetalles.Position = UDim2.new(0, 12, 0, 204)
btnVerDetalles.BackgroundColor3 = Color3.fromRGB(20, 28, 36)
btnVerDetalles.BorderSizePixel = 0
btnVerDetalles.AutoButtonColor = false
btnVerDetalles.Text = "VER DETALLES DE MISIÃ“N"
btnVerDetalles.TextColor3 = COLOR_CIAN
btnVerDetalles.Font = Enum.Font.RobotoMono
btnVerDetalles.TextSize = 10
btnVerDetalles.Visible = false
btnVerDetalles.Parent = detalles
local detallesBorde = Instance.new("UIStroke")
detallesBorde.Color = COLOR_CIAN
detallesBorde.Thickness = 1
detallesBorde.Parent = btnVerDetalles
local detallesEsquinas = Instance.new("UICorner")
detallesEsquinas.CornerRadius = UDim.new(0, 6)
detallesEsquinas.Parent = btnVerDetalles
btnVerDetalles.Activated:Connect(abrirVentanaDetalles)

-- ==================== Estados del panel derecho ====================

local function mostrarEstadoNinguno()
	planetaSeleccionado = nil
	placeholder.Visible = true
	missionTitle.Visible = false
	planetLabel.Visible = false
	costBox.Visible = false
	difficultyBox.Visible = false
	btnConfirmar.Visible = false
	acceptedMessage.Visible = false
	btnAbortar.Visible = false
	if btnVerDetalles then btnVerDetalles.Visible = false end
	cerrarVentanaDetalles()
end

local function mostrarEstadoDetalles(nombrePlaneta)
	planetaSeleccionado = nombrePlaneta
	local datos = PLANETAS[nombrePlaneta]
	if not datos then return end

	placeholder.Visible = false
	acceptedMessage.Visible = false
	btnAbortar.Visible = false

	missionTitle.Visible = true
	planetLabel.Visible = true
	costBox.Visible = true
	difficultyBox.Visible = true
	btnConfirmar.Visible = true
	if btnVerDetalles then btnVerDetalles.Visible = true end

	planetLabel.Text = string.upper(PLANET_NAMES_EN[nombrePlaneta] or nombrePlaneta)
	costBox.Valor.Text = string.format("$%s", tostring(datos.costo))
	difficultyBox.Valor.Text = datos.dificultad
end

local function mostrarEstadoAceptada(nombrePlaneta)
	placeholder.Visible = false
	missionTitle.Visible = false
	planetLabel.Visible = false
	costBox.Visible = false
	difficultyBox.Visible = false
	btnConfirmar.Visible = false
	if btnVerDetalles then btnVerDetalles.Visible = false end
	cerrarVentanaDetalles()

	acceptedMessage.Visible = true
	btnAbortar.Visible = true
	acceptedMessage.Text = string.format("Mission accepted!\nDestination: %s\n\nGood luck!", string.upper(PLANET_NAMES_EN[nombrePlaneta] or nombrePlaneta))
end

-- ==================== Eventos ====================

if btnCerrar then
	btnCerrar.Activated:Connect(function()
		gui.Enabled = false
	end)
end

for _, card in ipairs(lista:GetChildren()) do
	if card:IsA("TextButton") then
		card.Activated:Connect(function()
			if cerrarAutoToken then
				task.cancel(cerrarAutoToken)
				cerrarAutoToken = nil
			end
			mostrarEstadoDetalles(card.Name)
		end)
	end
end

btnConfirmar.Activated:Connect(function()
	if not planetaSeleccionado then return end
	local nombre = planetaSeleccionado

	-- Guardar la misiÃ³n activa globalmente (el servidor actualiza el StringValue)
	setMisionEvent:FireServer(nombre)

	mostrarEstadoAceptada(nombre)

	-- Cerrar el menÃº automÃ¡ticamente despuÃ©s de 3 segundos
	-- (sin reiniciar el estado: la misiÃ³n aceptada se mantiene al reabrir)
	cerrarAutoToken = task.delay(3, function()
		gui.Enabled = false
		cerrarAutoToken = nil
	end)
end)

btnAbortar.Activated:Connect(function()
	-- Limpiar la misiÃ³n activa globalmente
	setMisionEvent:FireServer("")

	if cerrarAutoToken then
		task.cancel(cerrarAutoToken)
		cerrarAutoToken = nil
	end
	mostrarEstadoNinguno()
end)

-- ==================== SINCRONIZACIÃ“N CON LA MISIÃ“N GLOBAL ====================
-- El menÃº recuerda la misiÃ³n activa: al reabrirse muestra el estado de misiÃ³n
-- aceptada con el botÃ³n ABORTAR MISIÃ“N, en lugar de reiniciarse.

local misionGlobal = ReplicatedStorage:WaitForChild("MisionActivaPlaneta")

local function sincronizarEstado()
	local planeta = misionGlobal.Value
	if planeta ~= "" then
		mostrarEstadoAceptada(planeta)
	else
		mostrarEstadoNinguno()
	end
end

misionGlobal.Changed:Connect(sincronizarEstado)
sincronizarEstado()
