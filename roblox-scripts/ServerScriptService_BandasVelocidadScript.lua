local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ALTURA_DETECCION = 6 -- studs por encima de la banda
local MARGEN = 0.5 -- margen lateral de deteccion

-- Registrar las bandas (partes Conveyor con atributo Multiplicador)
local bandas = {}

local function registrarBanda(inst)
	if inst:IsA("BasePart") and inst.Name == "Conveyor" then
		local mult = inst:GetAttribute("Multiplicador") or 2
		if not table.find(bandas, inst) then
			table.insert(bandas, inst)
		end
		inst:SetAttribute("Multiplicador", mult)
	end
end

for _, inst in ipairs(Workspace:GetDescendants()) do
	registrarBanda(inst)
end
Workspace.DescendantAdded:Connect(function(inst)
	task.defer(registrarBanda, inst)
end)

-- Devuelve la banda bajo la posicion, o nil
local function bandaEnPosicion(pos)
	for _, banda in ipairs(bandas) do
		if banda.Parent then
			local rel = banda.CFrame:PointToObjectSpace(pos)
			if math.abs(rel.X) <= banda.Size.X / 2 + MARGEN
				and math.abs(rel.Z) <= banda.Size.Z / 2 + MARGEN
				and rel.Y >= -1 and rel.Y <= ALTURA_DETECCION then
				return banda
			end
	end
	end
	return nil
end

-- Estado por jugador: velocidad base y si esta boosteado
local estado = {}

local function limpiar(player)
	estado[player] = nil
end

Players.PlayerRemoving:Connect(limpiar)

-- Bucle principal: aplica o quita el boost de velocidad
while true do
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if hrp and humanoid and humanoid.Health > 0 then
			local e = estado[player]
			if not e or e.humanoid ~= humanoid then
				e = { humanoid = humanoid, base = humanoid.WalkSpeed, boosteado = false }
				estado[player] = e
			end

			local banda = bandaEnPosicion(hrp.Position)
			if banda then
				-- Aplicar multiplicador de la banda
				if not e.boosteado then
					e.base = humanoid.WalkSpeed
					e.boosteado = true
			end
				humanoid.WalkSpeed = e.base * (banda:GetAttribute("Multiplicador") or 2)
			else
				-- Restaurar velocidad base al salir de la banda
				if e.boosteado then
				humanoid.WalkSpeed = e.base
				e.boosteado = false
			end
		end
		end
	end
	task.wait(0.25)
end