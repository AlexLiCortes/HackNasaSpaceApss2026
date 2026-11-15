-- Script: FlightSimulatorServer (ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local eventEjecutar = Instance.new("RemoteEvent")
eventEjecutar.Name = "EjecutarSimulacion"
eventEjecutar.Parent = ReplicatedStorage

local eventResultado = Instance.new("RemoteEvent")
eventResultado.Name = "ResultadoSimulacion"
eventResultado.Parent = ReplicatedStorage

-- CONSTANTES FÃSICAS DE SIMULACIÃ“N
local GRAVEDAD = 9.81
local DENSIDAD_AIRE_BASE = 1.225

local function calcularTrayectoria(empuje, masa, anguloInclinacion)
	local puntosTrayectoria = {}
	local posX, posY = 0, 0
	local velX = 0
	local velY = 0
	local tiempo = 0
	local dt = 0.5 -- Paso de tiempo en segundos
	local exito = false
	local causaFallo = "Time expired before reaching orbit"

	local rad = math.rad(anguloInclinacion)
	local masaActual = masa

	for step = 1, 120 do
		tiempo = tiempo + dt

		-- PÃ©rdida de masa por consumo de combustible (simulada)
		masaActual = math.max(masa * 0.3, masaActual - (empuje / 3000) * dt)

		-- CÃ¡lculo de Fuerzas
		local fuerzaEmpuje = empuje
		local empujeX = fuerzaEmpuje * math.sin(rad)
		local empujeY = fuerzaEmpuje * math.cos(rad)

		-- Arrastre atmosfÃ©rico simplificado (disminuye con la altitud)
		local altitudFactor = math.clamp(1 - (posY / 100000), 0, 1)
		local arrastre = 0.5 * DENSIDAD_AIRE_BASE * altitudFactor * (velY^2 + velX^2) * 0.05

		-- Aceleraciones (F = m * a  =>  a = F / m)
		local acelX = (empujeX - (arrastre * 0.5)) / masaActual
		local acelY = (empujeY - (masaActual * GRAVEDAD) - arrastre) / masaActual

		-- IntegraciÃ³n de Euler (Velocidad y PosiciÃ³n)
		velX = velX + acelX * dt
		velY = velY + acelY * dt

		posX = posX + velX * dt
		posY = posY + velY * dt

		-- Guardar punto para graficar en pantalla
		table.insert(puntosTrayectoria, {x = posX, y = posY, t = tiempo})

		-- Condiciones de fallo/Ã©xito
		if posY < 0 then
			causaFallo = "GROUND IMPACT: Insufficient thrust to overcome gravity."
			break
		elseif velY < 0 and posY < 80000 then
			causaFallo = "LOSS OF LIFT: Free fall in the lower atmosphere."
			break
		elseif posY >= 100000 and velX >= 7800 then
			exito = true
			causaFallo = "STABLE ORBIT ACHIEVED (APOGEE: 100km+)"
			break
		end
	end

	return {
		trayectoria = puntosTrayectoria,
		exito = exito,
		mensaje = causaFallo,
		altitudMaxima = math.floor(posY),
		velocidadFinal = math.floor(velX)
	}
end

eventEjecutar.OnServerEvent:Connect(function(player, datosInput)
	local empuje = tonumber(datosInput.empuje) or 150000
	local masa = tonumber(datosInput.masa) or 10000
	local angulo = tonumber(datosInput.angulo) or 45

	local resultado = calcularTrayectoria(empuje, masa, angulo)
	eventResultado:FireClient(player, resultado)

	-- Opcional: Actualizar pantalla gigante de la pared para todos los jugadores
	local pantallaPared = Workspace:FindFirstChild("PantallaSimulacionMaster", true)
	if pantallaPared then
		local textLabel = pantallaPared:FindFirstChildWhichIsA("TextLabel", true)
		if textLabel then
			textLabel.Text = string.format(
				"== SIMULATION IN PROGRESS ==\nOPERATOR: @%s\nRESULT: %s\nMAX ALTITUDE: %d m\nVELOCITY: %d m/s",
				player.Name,
				resultado.exito and "SUCCESS" or "FAILURE",
				resultado.altitudMaxima,
				resultado.velocidadFinal
			)
		end
	end
end)