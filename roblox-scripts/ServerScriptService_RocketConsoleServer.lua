--[[
	RocketConsoleServer
	Lado servidor de la consola de ensamblaje:
		- Mantiene el estado autoritativo de los componentes seleccionados por jugador.
		- Valida cada solicitud contra el catÃ¡logo (nunca confÃ­a en el cliente).
		- Responde con la lista autoritativa; la telemetrÃ­a se calcula con el
		  mismo mÃ³dulo de catÃ¡logo que usa el cliente.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local consoleFolder = ReplicatedStorage:WaitForChild("RocketConsole")
local remote = consoleFolder:WaitForChild("RemoteEvent")
local catalog = require(consoleFolder:WaitForChild("ComponentCatalog"))
local missionState = require(script.Parent:WaitForChild("RocketMissionState"))

-- Estado: player -> tabla { [componentId] = true }
local configs = {}

-- EnvÃ­a al cliente su lista autoritativa de componentes seleccionados
local function sendState(player)
	local selected = configs[player]
	if not selected then return end
	local list = {}
	for id in pairs(selected) do
		table.insert(list, id)
	end
	remote:FireClient(player, "state", list)
end

remote.OnServerEvent:Connect(function(player, action, id)
	-- Solicitud del estado completo (al abrir la consola)
	if action == "getState" then
		if not configs[player] then
			configs[player] = {}
		end
		sendState(player)

	-- Alternar un componente (agregar / quitar)
	elseif action == "toggle" then
		local selected = configs[player]
		if not selected then
			selected = {}
			configs[player] = selected
		end

		-- ValidaciÃ³n: el id debe existir en el catÃ¡logo
		local component = (typeof(id) == "string") and catalog.GetById(id)
		if component then
			if selected[id] then
				selected[id] = nil
			else
				selected[id] = true
			end
			sendState(player)
		end

	elseif action == "arm" then
		local selected = configs[player] or {}
		local categories = {}
		for id in pairs(selected) do
			local component = catalog.GetById(id)
			if component then
				categories[component.Category] = true
			end
		end

		local missing = {}
		for _, category in ipairs(catalog.Categories) do
			if not categories[category.Id] then
				table.insert(missing, category.Name)
			end
		end

		if #missing > 0 then
			remote:FireClient(player, "armResult", {
				ok = false,
				message = "ADD: " .. table.concat(missing, ", "),
			})
			return
		end

		local missionValue = ReplicatedStorage:FindFirstChild("MisionActivaPlaneta")
		local mission = missionValue and missionValue.Value or ""
		if mission == "" then
			remote:FireClient(player, "armResult", {
				ok = false,
				message = "SELECT MISSION",
			})
			return
		end

		local componentIds = {}
		for id in pairs(selected) do
			table.insert(componentIds, id)
		end
		table.sort(componentIds)
		missionState.Arm(player, componentIds, mission)
		remote:FireClient(player, "armResult", { ok = true, message = "ROCKET ARMED" })
	end
end)

-- Limpieza al salir el jugador
Players.PlayerRemoving:Connect(function(player)
	configs[player] = nil
	missionState.Clear(player)
end)