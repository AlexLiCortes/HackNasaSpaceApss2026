-- SatelliteSimulationController (LocalScript)
-- Control interactivo de cÃ¡mara / rotaciÃ³n con Cursor + 4 Botones de flechas translÃºcidas
-- SimulaciÃ³n trigonomÃ©trica de satÃ©lites matemÃ¡ticamente exacta sobre las lÃ­neas de Ã³rbita
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local frame = script.Parent
local screenGui = frame:FindFirstAncestorOfClass("ScreenGui")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local vp = frame:WaitForChild("ViewportFrame")
local earth = vp:WaitForChild("Earth")
local satFolder = vp:WaitForChild("SatellitesFolder")

-- 1. Garantizar asignaciÃ³n de Camera en runtime (evita que vp.CurrentCamera quede en nil al replicar a PlayerGui)
local cam = vp:FindFirstChildOfClass("Camera")
if not cam then
	cam = Instance.new("Camera")
	cam.Name = "ViewportCamera"
	cam.FieldOfView = 45
	cam.Parent = vp
end
vp.CurrentCamera = cam

local btnCerrar = frame:WaitForChild("BtnCerrar")

local function closeSatellitePanel()
	frame.Visible = false
	if screenGui then
		screenGui.Enabled = false
	end
end

local function closeOverlappingPanels()
	for _, guiName in ipairs({"FlightWhiteboardGui", "SimulaciÃ³nGui"}) do
		local otherGui = playerGui:FindFirstChild(guiName)
		if otherGui and otherGui:IsA("ScreenGui") then
			otherGui.Enabled = false
		end
	end
end

closeSatellitePanel()

btnCerrar.MouseButton1Click:Connect(closeSatellitePanel)

-- 2. ConexiÃ³n del RemoteEvent desde los escritorios
local remote = ReplicatedStorage:WaitForChild("AbrirSatelitesEvent")
remote.OnClientEvent:Connect(function()
	closeOverlappingPanels()
	if screenGui then
		screenGui.Enabled = true
	end
	frame.Visible = true
	vp.CurrentCamera = cam
end)

-- 7 SatÃ©lites con Colores 100% Distintos y Contrastantes:
local SATELLITES = {
	{ id = "ISS", orbitRadius = 2.50, inclinationDeg = 51.64, raanDeg = 110.0, speed = 0.55, angle = 0.4 },
	{ id = "Hubble", orbitRadius = 2.70, inclinationDeg = 28.47, raanDeg = 278.0, speed = 0.48, angle = 2.1 },
	{ id = "Tiangong", orbitRadius = 2.45, inclinationDeg = 41.47, raanDeg = 164.0, speed = 0.58, angle = 4.2 },
	{ id = "NOAA20", orbitRadius = 3.05, inclinationDeg = 98.72, raanDeg = 45.0, speed = 0.38, angle = 1.0 },
	{ id = "Starlink", orbitRadius = 2.75, inclinationDeg = 53.05, raanDeg = 320.0, speed = 0.46, angle = 5.3 },
	{ id = "Landsat9", orbitRadius = 2.90, inclinationDeg = 98.21, raanDeg = 185.0, speed = 0.41, angle = 3.4 },
	{ id = "Envisat", orbitRadius = 2.98, inclinationDeg = 98.54, raanDeg = 85.0, speed = 0.39, angle = 0.0 }
}

-- Matriz de planos de Ã³rbita precalculados
local orbitPlanes = {}
for _, cfg in ipairs(SATELLITES) do
	orbitPlanes[cfg.id] = CFrame.Angles(0, math.rad(cfg.raanDeg), 0)
		* CFrame.Angles(math.rad(cfg.inclinationDeg), 0, 0)
end

-- ========================================================
-- SISTEMA INTERACTIVO DE ROTACIÃ“N (CURSOR + 4 BOTONES)
-- ========================================================
local camDistance = 10.5
local camYaw = math.rad(45)
local camPitch = math.rad(20)

local isDragging = false
local lastMousePos = Vector2.new()

-- Banderas de mantenimiento continuo
local isHoldingUp = false
local isHoldingDown = false
local isHoldingLeft = false
local isHoldingRight = false

local function updateCamera()
	-- Garantizar en cada actualizaciÃ³n que la cÃ¡mara estÃ© enlazada
	if vp.CurrentCamera ~= cam then
		vp.CurrentCamera = cam
	end

	-- Rango amplio de pitch para inspeccionar polos y ecuador
	camPitch = math.clamp(camPitch, math.rad(-82), math.rad(82))

	local camX = math.cos(camPitch) * math.sin(camYaw) * camDistance
	local camY = math.sin(camPitch) * camDistance
	local camZ = math.cos(camPitch) * math.cos(camYaw) * camDistance

	-- Mirar hacia el centro de La Tierra con leve compensaciÃ³n visual
	cam.CFrame = CFrame.lookAt(Vector3.new(camX, camY, camZ), Vector3.new(-0.35, 0, 0))

	-- Sincronizar levemente la textura de La Tierra con el Ã¡ngulo de visiÃ³n
	if earth and earth:IsA("BasePart") then
		earth.CFrame = CFrame.Angles(0, -camYaw * 0.4, 0)
	end
end

updateCamera()

-- A. InteracciÃ³n con Arrastre de RatÃ³n (Click y Drag sobre ViewportFrame)
vp.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = true
		lastMousePos = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local curPos = Vector2.new(input.Position.X, input.Position.Y)
		local delta = curPos - lastMousePos
		lastMousePos = curPos

		camYaw = camYaw - delta.X * 0.007
		camPitch = camPitch + delta.Y * 0.007
		updateCamera()
	end
end)

-- B. InteracciÃ³n con los 4 Botones de Flechas (Esquina Superior Derecha)
local ctrl = frame:WaitForChild("InteractiveControls")
local btnUp = ctrl:WaitForChild("BtnUp")
local btnDown = ctrl:WaitForChild("BtnDown")
local btnLeft = ctrl:WaitForChild("BtnLeft")
local btnRight = ctrl:WaitForChild("BtnRight")

local STEP_ANGLE = math.rad(12) -- Giro instantÃ¡neo al hacer clic rÃ¡pido

local function setupArrow(btn, onStep, setHold)
	-- Al presionar: paso instantÃ¡neo inmediato + iniciar modo hold si se mantiene
	btn.MouseButton1Down:Connect(function()
		onStep()
		updateCamera()
		setHold(true)
		TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = Color3.fromRGB(0, 175, 255), BackgroundTransparency = 0.05 }):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		setHold(false)
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(12, 32, 60), BackgroundTransparency = 0.25 }):Play()
	end)

	btn.MouseLeave:Connect(function()
		setHold(false)
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(12, 32, 60), BackgroundTransparency = 0.25 }):Play()
	end)
end

setupArrow(btnUp, function() camPitch = camPitch + STEP_ANGLE end, function(v) isHoldingUp = v end)
setupArrow(btnDown, function() camPitch = camPitch - STEP_ANGLE end, function(v) isHoldingDown = v end)
setupArrow(btnLeft, function() camYaw = camYaw + STEP_ANGLE end, function(v) isHoldingLeft = v end)
setupArrow(btnRight, function() camYaw = camYaw - STEP_ANGLE end, function(v) isHoldingRight = v end)

-- Atajos de teclado (W, A, S, D o Flechas)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not frame.Visible then return end
	if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.W then
		camPitch = camPitch + STEP_ANGLE
		updateCamera()
		isHoldingUp = true
	elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.S then
		camPitch = camPitch - STEP_ANGLE
		updateCamera()
		isHoldingDown = true
	elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
		camYaw = camYaw + STEP_ANGLE
		updateCamera()
		isHoldingLeft = true
	elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
		camYaw = camYaw - STEP_ANGLE
		updateCamera()
		isHoldingRight = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.W then
		isHoldingUp = false
	elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.S then
		isHoldingDown = false
	elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
		isHoldingLeft = false
	elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
		isHoldingRight = false
	end
end)

-- ========================================================
-- BUCLE DE RENDER: Movimiento orbital exacto y rotaciÃ³n continua
-- ========================================================
RunService.RenderStepped:Connect(function(dt)
	if not frame.Visible then return end

	-- 1. RotaciÃ³n continua fluida si se mantiene presionada una flecha
	local pitchDelta = 0
	local yawDelta = 0

	if isHoldingUp then pitchDelta = pitchDelta + 1 end
	if isHoldingDown then pitchDelta = pitchDelta - 1 end
	if isHoldingLeft then yawDelta = yawDelta + 1 end
	if isHoldingRight then yawDelta = yawDelta - 1 end

	if pitchDelta ~= 0 or yawDelta ~= 0 then
		camPitch = camPitch + pitchDelta * dt * 2.2
		camYaw = camYaw + yawDelta * dt * 2.4
		updateCamera()
	end

	-- 2. Posicionamiento matemÃ¡tico de los satÃ©lites montados en sus Ã³rbitas
	for _, cfg in ipairs(SATELLITES) do
		local satPart = satFolder:FindFirstChild("Sat_" .. cfg.id)
		if satPart then
			cfg.angle = (cfg.angle + cfg.speed * dt) % (2 * math.pi)

			local x = math.cos(cfg.angle) * cfg.orbitRadius
			local z = math.sin(cfg.angle) * cfg.orbitRadius
			local posInPlane = Vector3.new(x, 0, z)

			local planeCF = orbitPlanes[cfg.id]
			local worldPos = planeCF:PointToWorldSpace(posInPlane)

			satPart.CFrame = CFrame.new(worldPos)
		end
	end
end)

-- 3. Control del Panel Desplegable de CÃ¡lculos y FÃ³rmulas TLE (?)
local headerBar = frame:WaitForChild("HeaderBar")
local btnAyuda = headerBar:WaitForChild("BtnCalculos")
local panelCalc = frame:WaitForChild("PanelCalculos")
local btnCerrarCalc = panelCalc:WaitForChild("Header"):WaitForChild("BtnCerrarCalc")

btnAyuda.MouseButton1Click:Connect(function()
	panelCalc.Visible = not panelCalc.Visible
	if panelCalc.Visible then
		TweenService:Create(btnAyuda, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(0, 180, 255), TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	else
		TweenService:Create(btnAyuda, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(12, 32, 60), TextColor3 = Color3.fromRGB(0, 235, 255) }):Play()
	end
end)

btnCerrarCalc.MouseButton1Click:Connect(function()
	panelCalc.Visible = false
	TweenService:Create(btnAyuda, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(12, 32, 60), TextColor3 = Color3.fromRGB(0, 235, 255) }):Play()
end)
