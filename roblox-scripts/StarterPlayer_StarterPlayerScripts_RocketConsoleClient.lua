--[[
	RocketConsoleClient (VersiÃ³n Corregida & Estetizada)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local consoleFolder = ReplicatedStorage:WaitForChild("RocketConsole")
local remote = consoleFolder:WaitForChild("RemoteEvent")
local catalog = require(consoleFolder:WaitForChild("ComponentCatalog"))
local misionGlobal = ReplicatedStorage:WaitForChild("MisionActivaPlaneta")

-- ============================ PALETA DE COLORES ============================
local COLOR = {
	Fondo     = Color3.fromRGB(8, 12, 16),
	Panel     = Color3.fromRGB(14, 20, 26),
	PanelAlto = Color3.fromRGB(20, 28, 36),
	Cian      = Color3.fromRGB(0, 195, 255),
	Verde     = Color3.fromRGB(0, 255, 140),
	Rojo      = Color3.fromRGB(255, 70, 90),
	Texto     = Color3.fromRGB(200, 235, 255),
	TextoGris = Color3.fromRGB(110, 140, 160),
}

local consola = nil
local prompt = nil
local abierta = false
local camOriginal = nil
local categoriaActual = "hull"
local seleccion = {}
local ui = {}

-- ============================ CÃMARA Y APERTURA =============================

local function enfocarTablet()
	camOriginal = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local foco = consola and consola:FindFirstChild("CameraFocus")
	if foco then
		local meta = { CFrame = foco.CFrame }
		local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(camera, info, meta):Play()
	end
end

local function restaurarCamara()
	camera.CameraType = camOriginal or Enum.CameraType.Custom
	camOriginal = nil
end

local function abrir()
	abierta = true
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = 0 end
	enfocarTablet()
	ui.gui.Enabled = true
	remote:FireServer("getState")
end

local function cerrar()
	abierta = false
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = 16 end
	ui.gui.Enabled = false
	restaurarCamara()
end

-- ============================ CONSTRUCCIÃ“N DE UI =========================

local function crearEsquinas(inst, radio)
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, radio)
	esquinas.Parent = inst
	return esquinas
end

local function crearBorde(inst, color, grosor)
	local borde = Instance.new("UIStroke")
	borde.Color = color
	borde.Thickness = grosor or 1
	borde.Parent = inst
	return borde
end

local function crearTexto(inst, props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.RobotoMono
	label.TextColor3 = COLOR.Texto
	label.TextSize = 14
	for k, v in pairs(props) do
		label[k] = v
	end
	label.Parent = inst
	return label
end

local function construirUI()
	local gui = playerGui:WaitForChild("RocketConsoleGui")
	ui.gui = gui

	local marco = Instance.new("Frame")
	marco.Name = "Tablet"
	marco.Size = UDim2.fromScale(0.76, 0.82)
	marco.Position = UDim2.fromScale(0.5, 0.5)
	marco.AnchorPoint = Vector2.new(0.5, 0.5)
	marco.BackgroundColor3 = COLOR.Fondo
	marco.BorderSizePixel = 0
	marco.ClipsDescendants = true
	marco.Parent = gui
	crearEsquinas(marco, 10)
	crearBorde(marco, COLOR.Cian, 2)
	ui.marco = marco

	-- Cabecera
	local cabecera = Instance.new("Frame")
	cabecera.Size = UDim2.new(1, 0, 0, 44)
	cabecera.BackgroundColor3 = COLOR.Panel
	cabecera.BorderSizePixel = 0
	cabecera.Parent = marco
	crearEsquinas(cabecera, 10)

	crearTexto(cabecera, {
		Text = "VAB // VEHICLE INTEGRATION CONSOLE",
		TextColor3 = COLOR.Cian,
		TextSize = 15,
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local btnCerrar = Instance.new("TextButton")
	btnCerrar.Name = "BtnCerrar"
	btnCerrar.Size = UDim2.fromOffset(32, 32)
	btnCerrar.Position = UDim2.new(1, -40, 0.5, -16)
	btnCerrar.BackgroundColor3 = COLOR.PanelAlto
	btnCerrar.Text = "X"
	btnCerrar.TextColor3 = COLOR.Rojo
	btnCerrar.Font = Enum.Font.RobotoMono
	btnCerrar.TextSize = 16
	btnCerrar.Parent = cabecera
	crearEsquinas(btnCerrar, 6)
	btnCerrar.Activated:Connect(cerrar)

	-- Cuerpo
	local cuerpo = Instance.new("Frame")
	cuerpo.Size = UDim2.new(1, -20, 1, -58)
	cuerpo.Position = UDim2.new(0, 10, 0, 50)
	cuerpo.BackgroundTransparency = 1
	cuerpo.Parent = marco

	-- PestaÃ±as (Izquierda)
	local pestanas = Instance.new("Frame")
	pestanas.Name = "Pestanas"
	pestanas.Size = UDim2.new(0, 115, 1, 0)
	pestanas.BackgroundColor3 = COLOR.Panel
	pestanas.BorderSizePixel = 0
	pestanas.Parent = cuerpo
	crearEsquinas(pestanas, 8)
	ui.pestanas = pestanas

	-- Lista de Componentes (Centro)
	local lista = Instance.new("ScrollingFrame")
	lista.Name = "Lista"
	lista.Size = UDim2.new(1, -315, 1, 0)
	lista.Position = UDim2.new(0, 123, 0, 0)
	lista.BackgroundColor3 = COLOR.Panel
	lista.BorderSizePixel = 0
	lista.ScrollBarThickness = 4
	lista.AutomaticCanvasSize = Enum.AutomaticSize.Y
	lista.CanvasSize = UDim2.new()
	lista.ClipsDescendants = true
	lista.Parent = cuerpo
	crearEsquinas(lista, 8)

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = lista

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 6)
	listPadding.PaddingLeft = UDim.new(0, 6)
	listPadding.PaddingRight = UDim.new(0, 6)
	listPadding.Parent = lista
	ui.lista = lista

	-- TelemetrÃ­a (Derecha)
	local panel = Instance.new("Frame")
	panel.Name = "Telemetria"
	panel.Size = UDim2.new(0, 185, 1, 0)
	panel.Position = UDim2.new(1, -185, 0, 0)
	panel.BackgroundColor3 = COLOR.Panel
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.Parent = cuerpo
	crearEsquinas(panel, 8)
	ui.panel = panel
end

-- ==================== VISTA PREVIA Y TELEMETRÃA ============================

local function animarIntegracion(nombreComponente)
	local vista = ui.panel:FindFirstChild("VistaEnsamblaje")
	if not vista then return end

	local barra = vista:FindFirstChild("Barra")
	local relleno = barra and barra:FindFirstChild("Relleno")
	if relleno then
		relleno.Size = UDim2.new(0, 0, 1, 0)
		local info = TweenInfo.new(0.4, Enum.EasingStyle.Linear)
		TweenService:Create(relleno, info, { Size = UDim2.new(1, 0, 1, 0) }):Play()
	end

	local pila = vista:FindFirstChild("Pila")
	if pila then
		local chip = Instance.new("TextLabel")
		chip.Size = UDim2.new(1, 0, 0, 20)
		chip.BackgroundColor3 = COLOR.PanelAlto
		chip.Text = "Â» " .. nombreComponente
		chip.TextColor3 = COLOR.Verde
		chip.Font = Enum.Font.RobotoMono
		chip.TextSize = 10
		chip.BorderSizePixel = 0
		chip.TextTruncate = Enum.TextTruncate.AtEnd
		chip.Parent = pila
		crearEsquinas(chip, 4)
		crearBorde(chip, COLOR.Verde, 1)

		chip.BackgroundTransparency = 1
		chip.TextTransparency = 1
		local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(chip, info, { BackgroundTransparency = 0, TextTransparency = 0 }):Play()

		-- Limitar mÃ¡ximo 3 chips visibles para evitar desbordamiento
		local items = {}
		for _, child in ipairs(pila:GetChildren()) do
			if child:IsA("TextLabel") then table.insert(items, child) end
		end
		if #items > 3 then
			items[1]:Destroy()
		end
	end
end

local function actualizarTelemetria()
	local ids = {}
	for id in pairs(seleccion) do table.insert(ids, id) end
	local t = catalog.ComputeTelemetry(ids)

	if ui.LblCosto then ui.LblCosto.Text = string.format("$%d", t.Cost) end
	if ui.LblEnergia then
		ui.LblEnergia.Text = string.format("%d W", t.Power)
		ui.LblEnergia.TextColor3 = t.Power >= 0 and COLOR.Verde or COLOR.Rojo
	end
	if ui.LblMasa then ui.LblMasa.Text = string.format("%d kg", t.Mass) end
	if ui.LblCombustible then ui.LblCombustible.Text = string.format("%d kg", t.Fuel) end
end

local function construirPanelTelemetria()
	local panel = ui.panel

	crearTexto(panel, {
		Text = "TELEMETRY",
		TextColor3 = COLOR.Cian,
		TextSize = 13,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 10, 0, 4),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local filas = {
		{ etiqueta = "LblCosto",        titulo = "TOTAL COST",        unidad = "$0" },
		{ etiqueta = "LblEnergia",      titulo = "POWER BALANCE",    unidad = "0 W" },
		{ etiqueta = "LblMasa",        titulo = "ESTIMATED MASS",      unidad = "0 kg" },
		{ etiqueta = "LblCombustible", titulo = "FUEL CAPACITY", unidad = "0 kg" },
	}
	for i, fila in ipairs(filas) do
		local y = 26 + (i - 1) * 40
		local caja = Instance.new("Frame")
		caja.Size = UDim2.new(1, -20, 0, 36)
		caja.Position = UDim2.new(0, 10, 0, y)
		caja.BackgroundColor3 = COLOR.PanelAlto
		caja.BorderSizePixel = 0
		caja.Parent = panel
		crearEsquinas(caja, 6)
		crearBorde(caja, COLOR.Cian, 1)

		crearTexto(caja, {
			Text = fila.titulo,
			TextColor3 = COLOR.TextoGris,
			TextSize = 9,
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.new(0, 8, 0, 2),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		crearTexto(caja, {
			Name = fila.etiqueta,
			Text = fila.unidad,
			TextColor3 = COLOR.Verde,
			TextSize = 14,
			Size = UDim2.new(1, -16, 0, 16),
			Position = UDim2.new(0, 8, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		ui[fila.etiqueta] = caja:FindFirstChild(fila.etiqueta)
	end

	-- Vista previa de ensamblaje en parte inferior
	local vista = Instance.new("Frame")
	vista.Name = "VistaEnsamblaje"
	vista.Size = UDim2.new(1, -20, 0, 180)
	vista.Position = UDim2.new(0, 10, 1, -186)
	vista.BackgroundColor3 = COLOR.Fondo
	vista.BorderSizePixel = 0
	vista.ClipsDescendants = true
	vista.Parent = panel
	crearEsquinas(vista, 6)
	crearBorde(vista, COLOR.Verde, 1)

	crearTexto(vista, {
		Text = "COMPONENT INTEGRATION",
		TextColor3 = COLOR.Verde,
		TextSize = 9,
		Size = UDim2.new(1, -12, 0, 16),
		Position = UDim2.new(0, 6, 0, 2),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local pila = Instance.new("Frame")
	pila.Name = "Pila"
	pila.Size = UDim2.new(1, -12, 0, 62)
	pila.Position = UDim2.new(0, 6, 0, 22)
	pila.BackgroundTransparency = 1
	pila.ClipsDescendants = true
	pila.Parent = vista

	local disposicion = Instance.new("UIListLayout")
	disposicion.Padding = UDim.new(0, 3)
	disposicion.SortOrder = Enum.SortOrder.LayoutOrder
	disposicion.Parent = pila

	local barra = Instance.new("Frame")
	barra.Name = "Barra"
	barra.Size = UDim2.new(1, -12, 0, 4)
	barra.Position = UDim2.new(0, 6, 0, 90)
	barra.BackgroundColor3 = COLOR.Fondo
	barra.BorderSizePixel = 0
	barra.Parent = vista
	crearEsquinas(barra, 2)

	local relleno = Instance.new("Frame")
	relleno.Name = "Relleno"
	relleno.Size = UDim2.new(0, 0, 1, 0)
	relleno.BackgroundColor3 = COLOR.Verde
	relleno.BorderSizePixel = 0
	relleno.Parent = barra
	crearEsquinas(relleno, 2)

	local btnArmar = Instance.new("TextButton")
	btnArmar.Name = "BtnArmarCohete"
	btnArmar.Size = UDim2.new(1, -12, 0, 30)
	btnArmar.Position = UDim2.new(0, 6, 0, 108)
	btnArmar.BackgroundColor3 = COLOR.PanelAlto
	btnArmar.BorderSizePixel = 0
	btnArmar.AutoButtonColor = false
	btnArmar.Text = "ARM ROCKET"
	btnArmar.TextColor3 = COLOR.Cian
	btnArmar.Font = Enum.Font.RobotoMono
	btnArmar.TextSize = 10
	btnArmar.Parent = vista
	crearEsquinas(btnArmar, 5)
	crearBorde(btnArmar, COLOR.Cian, 1)
	ui.btnArmar = btnArmar
	btnArmar.Activated:Connect(function()
		if not abierta then return end
		btnArmar.Text = "ARMING..."
		btnArmar.TextColor3 = COLOR.TextoGris
		remote:FireServer("arm")
	end)
end

-- ==================== PANEL DE MISIÃ“N ACTIVA =============================

-- English display names only (internal keys stay unchanged)
local PLANET_NAMES_EN = { Luna = "Moon", Marte = "Mars", Venus = "Venus", Mercurio = "Mercury", ["JÃºpiter"] = "Jupiter", Saturno = "Saturn", Urano = "Uranus", Neptuno = "Neptune" }

local DIFICULTADES = {
	Luna = "Low",
	Marte = "Medium",
	Venus = "High",
	Mercurio = "Very High",
	["JÃºpiter"] = "Extreme",
	Saturno = "Extreme+",
	Urano = "Critical",
	Neptuno = "Catastrophic",
}

local function actualizarPanelMision()
	local lblMision = ui.panel:FindFirstChild("LblMisionActiva", true)
	local lblDificultad = ui.panel:FindFirstChild("LblMisionDificultad", true)
	if not lblMision or not lblDificultad then return end

	local misionActiva = ReplicatedStorage:FindFirstChild("MisionActivaPlaneta")
	local planeta = misionActiva and misionActiva.Value or ""

	if planeta == "" then
		lblMision.Text = "NO MISSION\nSELECTED"
		lblMision.TextColor3 = COLOR.TextoGris
		lblMision.TextSize = 11
		lblDificultad.Text = ""
	else
		lblMision.Text = "ACTIVE MISSION:\n" .. string.upper(PLANET_NAMES_EN[planeta] or planeta)
		lblMision.TextColor3 = COLOR.Cian
		lblMision.TextSize = 14
		lblDificultad.Text = "DIFFICULTY: " .. (DIFICULTADES[planeta] or "-")
	end
end

local function construirPanelMision()
	local panel = ui.panel

	local caja = Instance.new("Frame")
	caja.Name = "MisionActiva"
	caja.Size = UDim2.new(1, -20, 0, 130)
	caja.Position = UDim2.new(0, 10, 1, -312)
	caja.BackgroundColor3 = COLOR.Fondo
	caja.BorderSizePixel = 0
	caja.ClipsDescendants = true
	caja.Parent = panel
	crearEsquinas(caja, 6)
	crearBorde(caja, COLOR.Cian, 1)

	crearTexto(caja, {
		Text = "MISSION STATUS",
		TextColor3 = COLOR.Cian,
		TextSize = 10,
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 6, 0, 4),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local lblMision = crearTexto(caja, {
		Name = "LblMisionActiva",
		Text = "NO MISSION\nSELECTED",
		TextColor3 = COLOR.TextoGris,
		TextSize = 11,
		Size = UDim2.new(1, -12, 0, 60),
		Position = UDim2.new(0, 6, 0, 24),
		TextWrapped = true,
	})

	local lblDificultad = crearTexto(caja, {
		Name = "LblMisionDificultad",
		Text = "",
		TextColor3 = COLOR.Verde,
		TextSize = 10,
		Size = UDim2.new(1, -12, 0, 14),
		Position = UDim2.new(0, 6, 0, 96),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Escuchar cambios de la misiÃ³n activa
	local misionActiva = ReplicatedStorage:FindFirstChild("MisionActivaPlaneta")
	if misionActiva then
		misionActiva.Changed:Connect(actualizarPanelMision)
	end
	actualizarPanelMision()
end

-- ==================== PESTAÃ‘AS Y LISTA ======================

local function renderizarLista()
	for _, hijo in ipairs(ui.lista:GetChildren()) do
		if hijo:IsA("TextButton") then
			hijo:Destroy()
		end
	end

	local componentes = catalog.GetByCategory(categoriaActual)
	for i, componente in ipairs(componentes) do
			local instalado = seleccion[componente.Id]

		local boton = Instance.new("TextButton")
		boton.Name = componente.Id
		boton.Size = UDim2.new(1, 0, 0, 72)
		boton.BackgroundColor3 = COLOR.PanelAlto
		boton.Text = ""
		boton.AutoButtonColor = false
		boton.LayoutOrder = i
		boton.Parent = ui.lista
		crearEsquinas(boton, 6)
		crearBorde(boton, instalado and COLOR.Verde or COLOR.Cian, 1)

		-- Nombre del componente
		crearTexto(boton, {
			Text = componente.Name,
			TextColor3 = instalado and COLOR.Verde or COLOR.Texto,
			TextSize = 12,
			Size = UDim2.new(1, -12, 0, 18),
			Position = UDim2.new(0, 8, 0, 6),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		-- Especificaciones (acortado a 60% del ancho para no sobreponerse)
		local signo = componente.Power >= 0 and "+" or ""
		crearTexto(boton, {
			Text = string.format("$%d | %s%dW | %dkg", componente.Cost, signo, componente.Power, componente.Mass),
			TextColor3 = COLOR.TextoGris,
			TextSize = 9,
			Size = UDim2.new(0.55, 0, 0, 14),
			Position = UDim2.new(0, 8, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		crearTexto(boton, {
			Text = string.format("THR %d | EFF %d%% | HEAT %d | REL %d", componente.Thrust or 0, componente.Efficiency or 0, componente.HeatResistance or 0, componente.Reliability or 0),
			TextColor3 = COLOR.TextoGris,
			TextSize = 8,
			Size = UDim2.new(1, -16, 0, 14),
			Position = UDim2.new(0, 8, 0, 50),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		-- Estado [INSTALLED] / [+ INSTALL]
		crearTexto(boton, {
			Text = instalado and "[INSTALLED]" or "+ INSTALL",
			TextColor3 = instalado and COLOR.Verde or COLOR.Cian,
			TextSize = 9,
			Size = UDim2.new(0.4, -8, 0, 14),
			Position = UDim2.new(0.6, 0, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Right,
		})

		boton.Activated:Connect(function()
			if abierta then
				remote:FireServer("toggle", componente.Id)
			end
		end)
	end
end

local function construirPestanas()
	local disposicion = Instance.new("UIListLayout")
	disposicion.Padding = UDim.new(0, 6)
	disposicion.Parent = ui.pestanas

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = ui.pestanas

	for _, categoria in ipairs(catalog.Categories) do
		local boton = Instance.new("TextButton")
		boton.Name = categoria.Id
		boton.Size = UDim2.new(1, 0, 0, 38)
		boton.BackgroundColor3 = COLOR.PanelAlto
		boton.Text = string.upper(categoria.Name)
		boton.Font = Enum.Font.RobotoMono
		boton.TextSize = 10
		boton.TextColor3 = COLOR.Texto
		boton.Parent = ui.pestanas
		crearEsquinas(boton, 6)
		crearBorde(boton, COLOR.Cian, 1)

		boton.Activated:Connect(function()
			categoriaActual = categoria.Id
			for _, p in ipairs(ui.pestanas:GetChildren()) do
				if p:IsA("TextButton") then
					local borde = p:FindFirstChildOfClass("UIStroke")
					if borde then
						borde.Color = COLOR.Cian
						borde.Thickness = 1
					end
					p.TextColor3 = COLOR.Texto
				end
			end
			local bordeActivo = boton:FindFirstChildOfClass("UIStroke")
			if bordeActivo then
				bordeActivo.Color = COLOR.Verde
				bordeActivo.Thickness = 2
			end
			boton.TextColor3 = COLOR.Verde
			renderizarLista()
		end)
	end

	local inicial = ui.pestanas:FindFirstChild(categoriaActual)
	if inicial then
		local borde = inicial:FindFirstChildOfClass("UIStroke")
		if borde then
			borde.Color = COLOR.Verde
			borde.Thickness = 2
		end
		inicial.TextColor3 = COLOR.Verde
	end
end

-- ==================== EVENTOS Y PROMPT ==============================

remote.OnClientEvent:Connect(function(accion, datos)
	if accion == "armResult" then
		if ui.btnArmar then
			ui.btnArmar.Text = datos.ok and "ROCKET ARMED" or (datos.message or "ARM FAILED")
			ui.btnArmar.TextColor3 = datos.ok and COLOR.Verde or COLOR.Rojo
		end
	elseif accion == "state" then
		local cambio = {}
		for _, id in ipairs(datos) do
			if not seleccion[id] then
				table.insert(cambio, id)
			end
			seleccion[id] = true
		end
		for id in pairs(seleccion) do
			if not table.find(datos, id) then
				seleccion[id] = nil
			end
		end
		renderizarLista()
		actualizarTelemetria()
		for _, id in ipairs(cambio) do
			local componente = catalog.GetById(id)
			if componente then
				animarIntegracion(componente.Name)
			end
		end
	end
end)

local function conectarConsola(modelo)
	if consola == modelo then return end
	consola = modelo
	task.spawn(function()
		local pantalla = modelo:WaitForChild("TabletScreen", 30)
		if not pantalla then return end
		local p = pantalla:FindFirstChildOfClass("ProximityPrompt")
			or pantalla:WaitForChildOfClass("ProximityPrompt", 30)
		if not p then return end
		prompt = p
		prompt.Triggered:Connect(function()
			if abierta then cerrar() else abrir() end
		end)
	end)
end

for _, modelo in ipairs(CollectionService:GetTagged("RocketAssemblyConsole")) do
	conectarConsola(modelo)
end
CollectionService:GetInstanceAddedSignal("RocketAssemblyConsole"):Connect(conectarConsola)

UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado then return end
	if abierta and input.KeyCode == Enum.KeyCode.E then
		cerrar()
	end
end)

-- ==================== INICIALIZACIÃ“N =======================================
construirUI()
construirPanelTelemetria()
construirPestanas()
renderizarLista()
actualizarTelemetria()
misionGlobal.Changed:Connect(function()
	renderizarLista()
end)