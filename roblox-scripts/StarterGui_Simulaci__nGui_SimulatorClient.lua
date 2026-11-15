-- LocalScript: SimulatorClient (En SimulaciÃ³nGui)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventEjecutar = ReplicatedStorage:WaitForChild("EjecutarSimulacion")
local eventResultado = ReplicatedStorage:WaitForChild("ResultadoSimulacion")

local gui = script.Parent
local frame = gui:WaitForChild("MainFrame")

-- Campos de texto para inputs (Crear previamente en la UI o vÃ­a cÃ³digo)
local inputEmpuje = frame:WaitForChild("InputEmpuje") -- TextBox
local inputMasa = frame:WaitForChild("InputMasa")     -- TextBox
local inputAngulo = frame:WaitForChild("InputAngulo") -- TextBox
local btnStart = frame:WaitForChild("BtnStart")       -- TextButton
local txtOutput = frame:WaitForChild("TxtOutput")     -- TextLabel
local graphCanvas = frame:WaitForChild("GraphCanvas") -- Frame para graficar

-- Dibujar lÃ­nea de simulaciÃ³n en el contenedor grÃ¡fico
local function graficarTrayectoria(puntos)
	-- Limpiar puntos anteriores
	for _, child in ipairs(graphCanvas:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local maxDistX = 150000
	local maxDistY = 120000

	for i, pt in ipairs(puntos) do
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 4, 0, 4)

		-- Mapeo de coordenadas reales a espacio UI (0 a 1)
		local pctX = math.clamp(pt.x / maxDistX, 0, 1)
		local pctY = math.clamp(1 - (pt.y / maxDistY), 0, 1)

		dot.Position = UDim2.new(pctX, 0, pctY, 0)
		dot.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
		dot.BorderSizePixel = 0
		dot.Parent = graphCanvas
	end
end

-- Evento de clic en Iniciar SimulaciÃ³n
btnStart.MouseButton1Click:Connect(function()
	txtOutput.Text = "RUNNING TRAJECTORY SIMULATION..."

	eventEjecutar:FireServer({
		empuje = inputEmpuje.Text,
		masa = inputMasa.Text,
		angulo = inputAngulo.Text
	})
end)

-- Recibir el resultado y actualizar UI
eventResultado.OnClientEvent:Connect(function(res)
	if res.exito then
		txtOutput.TextColor3 = Color3.fromRGB(0, 255, 140)
		txtOutput.Text = string.format("âœ” SIMULATION SUCCESSFUL\n%s\nAltitude: %d km | Vel: %d m/s", 
			res.mensaje, math.floor(res.altitudMaxima/1000), res.velocidadFinal)
	else
		txtOutput.TextColor3 = Color3.fromRGB(255, 80, 80)
		txtOutput.Text = string.format("âœ– SIMULATION FAILED\n%s\nAltitude Reached: %d m", 
			res.mensaje, res.altitudMaxima)
	end

	graficarTrayectoria(res.trayectoria)
end)