local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local COOLDOWN = 3 -- segundos de espera tras un teletransporte
local ALTURA_DETECCION = 6 -- studs por encima del pad
local MARGEN = 1 -- margen lateral de deteccion

-- Registro de pares de teletransporte. Los pads se identifican por sus
-- atributos (Par, Rol, Requeridos) sin importar donde esten colocados.
local pares = {}

local function registrarPad(pad)
	if not pad:IsA("BasePart") then return end
	local parNombre = pad:GetAttribute("Par")
	local rol = pad:GetAttribute("Rol")
	local requeridos = pad:GetAttribute("Requeridos")
	if parNombre and rol and requeridos then
		if not pares[parNombre] then
			pares[parNombre] = { requeridos = requeridos, cooldownHasta = 0 }
		end
		pares[parNombre][rol] = pad
	end
end

-- Registrar pads existentes en cualquier parte del Workspace
for _, inst in ipairs(Workspace:GetDescendants()) do
	registrarPad(inst)
end

-- Registrar pads que se agreguen o muevan despues
Workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("BasePart") then
		task.defer(registrarPad, inst)
	end
end)

-- Devuelve la lista de jugadores cuyo personaje esta parado sobre el pad
local function jugadoresSobrePad(pad)
	local jugadores = {}
	local mitadX = pad.Size.X / 2 + MARGEN
	local mitadZ = pad.Size.Z / 2 + MARGEN
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if hrp and humanoid and humanoid.Health > 0 then
			local rel = pad.CFrame:PointToObjectSpace(hrp.Position)
			if math.abs(rel.X) <= mitadX
				and math.abs(rel.Z) <= mitadZ
				and rel.Y >= -1 and rel.Y <= ALTURA_DETECCION then
				table.insert(jugadores, player)
			end
		end
	end
	return jugadores
end

-- Teletransporta a los jugadores al pad de destino
local function teletransportar(jugadores, padDestino)
	local destino = padDestino.CFrame * CFrame.new(0, 4, 0)
	for _, player in ipairs(jugadores) do
		local character = player.Character
		if character then
			character:PivotTo(destino)
		end
	end
end

-- Actualiza el cartel flotante de un pad con el conteo actual (ej. "2/4")
local function actualizarContador(pad, cantidad, requeridos)
	local bb = pad:FindFirstChild("ContadorGui")
	local label = bb and bb:FindFirstChild("Contador")
	if label then
		label.Text = cantidad .. "/" .. requeridos
		-- Verde cuando el cupo esta completo, blanco cuando falta gente
		if cantidad >= requeridos then
			label.TextColor3 = Color3.fromRGB(90, 255, 100)
		else
			label.TextColor3 = Color3.new(1, 1, 1)
		end
	end
end

-- Bucle principal: teletransporta cuando el cupo esta completo
while true do
	local ahora = os.clock()
	for _, par in pairs(pares) do
		local padA, padB = par.A, par.B
		-- Ambos pads deben seguir existiendo en el juego
		if padA and padA.Parent and padB and padB.Parent and ahora >= par.cooldownHasta then
			local jugadoresA = jugadoresSobrePad(padA)
			local jugadoresB = jugadoresSobrePad(padB)

			-- Actualizar carteles flotantes de ambos pads
			actualizarContador(padA, #jugadoresA, par.requeridos)
			actualizarContador(padB, #jugadoresB, par.requeridos)

			if #jugadoresA >= par.requeridos then
				teletransportar(jugadoresA, padB)
			par.cooldownHasta = ahora + COOLDOWN
			elseif #jugadoresB >= par.requeridos then
				teletransportar(jugadoresB, padA)
			par.cooldownHasta = ahora + COOLDOWN
			end
		end
	end
	task.wait(0.4)
end