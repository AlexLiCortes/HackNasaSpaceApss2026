-- LaunchPlanningServer: valida y sincroniza los calculos de los jugadores
-- hacia las pizarras y la pantalla maestra en tiempo real.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage:WaitForChild("LaunchPlanningRemotes")
local SyncCalculation = remotes:WaitForChild("SyncCalculation")
local BoardsUpdated = remotes:WaitForChild("BoardsUpdated")

local room = workspace:WaitForChild("LaunchPlanningRoom")
local whiteboards = room:WaitForChild("Whiteboards")
local masterDisplay = room:WaitForChild("MasterDisplay")

-- Historial de calculos para la pantalla maestra (ultimos 8)
local masterHistory = {}
local MAX_HISTORY = 8

-- Validacion: solo tipos y textos permitidos, nada ejecutable
local function sanitizeText(value, maxLen)
	if typeof(value) ~= "string" then return nil end
	if #value > maxLen then return nil end
	return value
end

local function sanitizeNumber(value)
	if typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then
		return value
	end
	return nil
end

local function getBoardDataLabel(boardModel)
	local screen = boardModel and boardModel:FindFirstChild("Screen")
	local gui = screen and screen:FindFirstChild("BoardGui")
	return gui and gui:FindFirstChild("DataLabel")
end

local function getMasterDataLabel()
	local screen = masterDisplay:FindFirstChild("Screen")
	local gui = screen and screen:FindFirstChild("MasterGui")
	return gui and gui:FindFirstChild("MasterDataLabel")
end

local function updateMasterDisplay()
	local label = getMasterDataLabel()
	if not label then return end
	if #masterHistory == 0 then
		label.Text = "> SYNC STANDBY..."
	else
		label.Text = table.concat(masterHistory, "\n")
	end
end

SyncCalculation.OnServerEvent:Connect(function(player, payload)
	-- payload = { boardId: string, calcType: string, inputs: string, result: number, resultText: string }
	if typeof(payload) ~= "table" then return end

	local calcType = sanitizeText(payload.calcType, 40)
	local inputs = sanitizeText(payload.inputs, 160)
	local result = sanitizeNumber(payload.result)
	if not calcType or not inputs or result == nil then return end

	local playerName = player.Name

	-- Actualizar la pizarra local del jugador si el boardId es valido
	local boardId = sanitizeText(payload.boardId, 40)
	if boardId then
		for _, board in ipairs(whiteboards:GetChildren()) do
			if board.Name == boardId then
				local label = getBoardDataLabel(board)
				if label then
					label.Text = string.format("> %s\n> Type: %s\n> Inputs: %s\n> RESULT: %.4g", playerName, calcType, inputs, result)
				end
				break
				end
			end
		end

	-- Agregar al historial de la pantalla maestra
		table.insert(masterHistory, 1, string.format("> [%s] %s :: %.6g", playerName, calcType, result))
	if #masterHistory > MAX_HISTORY then
		table.remove(masterHistory, MAX_HISTORY + 1)
	end
	updateMasterDisplay()

	-- Notificar a todos los clientes (por si muestran datos locales adicionales)
	BoardsUpdated:FireAllClients({
		player = playerName,
		boardId = boardId,
		calcType = calcType,
		result = result,
	})
end)

-- Estado inicial
updateMasterDisplay()