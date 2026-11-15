-- WhiteboardClient: al activar el ProximityPrompt de un pizarron, la camara
-- pasa a una vista de trabajo en primera persona y se abre la interfaz
-- de calculos. Los resultados se sincronizan con el servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local remotes = ReplicatedStorage:WaitForChild("LaunchPlanningRemotes")
local SyncCalculation = remotes:WaitForChild("SyncCalculation")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local room = workspace:WaitForChild("LaunchPlanningRoom")
local whiteboards = room:WaitForChild("Whiteboards")

-- Estado de vista
local activeBoard = nil
local savedCameraType = nil
local cameraTween = nil

-- ===== GUI del pizarron =====
local gui = Instance.new("ScreenGui")
gui.Name = "WhiteboardGui"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(440, 400)
main.Position = UDim2.new(0.5, -220, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui
local mcorner = Instance.new("UICorner")
mcorner.CornerRadius = UDim.new(0, 10)
mcorner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.1)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(120, 220, 255)
title.Font = Enum.Font.Code
title.TextScaled = true
title.Text = ""
title.Parent = main

local inputsHolder = Instance.new("Frame")
inputsHolder.Name = "InputsHolder"
inputsHolder.Size = UDim2.fromScale(0.94, 0.66)
inputsHolder.Position = UDim2.fromScale(0.03, 0.13)
inputsHolder.BackgroundTransparency = 1
inputsHolder.Parent = main
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 0.03)
listLayout.Parent = inputsHolder

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.fromScale(0.94, 0.1)
resultLabel.Position = UDim2.fromScale(0.03, 0.81)
resultLabel.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
resultLabel.TextColor3 = Color3.fromRGB(160, 255, 180)
resultLabel.Font = Enum.Font.Code
resultLabel.TextScaled = true
resultLabel.Text = "> result..."
local rcorner = Instance.new("UICorner")
rcorner.CornerRadius = UDim.new(0, 6)
rcorner.Parent = resultLabel
resultLabel.Parent = main

local calcBtn = Instance.new("TextButton")
calcBtn.Size = UDim2.fromScale(0.45, 0.08)
calcBtn.Position = UDim2.fromScale(0.03, 0.93)
calcBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 60)
calcBtn.TextColor3 = Color3.fromRGB(220, 255, 230)
calcBtn.Font = Enum.Font.Code
calcBtn.TextScaled = true
calcBtn.Text = "CALCULATE"
local ccorner = Instance.new("UICorner")
ccorner.CornerRadius = UDim.new(0, 6)
ccorner.Parent = calcBtn
calcBtn.Parent = main

local exitBtn = Instance.new("TextButton")
exitBtn.Size = UDim2.fromScale(0.45, 0.08)
exitBtn.Position = UDim2.fromScale(0.52, 0.93)
exitBtn.BackgroundColor3 = Color3.fromRGB(90, 45, 45)
exitBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
exitBtn.Font = Enum.Font.Code
exitBtn.TextScaled = true
exitBtn.Text = "EXIT [E]"
local ecorner = Instance.new("UICorner")
ecorner.CornerRadius = UDim.new(0, 6)
ecorner.Parent = exitBtn
exitBtn.Parent = main

-- ===== Definiciones de calculos por pizarron =====
local BOARD_DEFS = {
	["Pizarron_1"] = {
		title = "THRUST CALCULATION",
		fields = {
			{ id = "mdot", label = "Mass flow rate mdot (kg/s)", default = "250" },
			{ id = "Ve", label = "Exhaust velocity Ve (m/s)", default = "3000" },
			{ id = "Pe", label = "Nozzle exit pressure Pe (Pa)", default = "101325" },
			{ id = "Pa", label = "Ambient pressure Pa (Pa)", default = "101325" },
			{ id = "Ae", label = "Nozzle exit area Ae (m^2)", default = "0.7" },
		},
		compute = function(v)
			return v.mdot * v.Ve + (v.Pe - v.Pa) * v.Ae
		end,
		unit = "N",
	},
	["Pizarron_2"] = {
		title = "AERODYNAMICS & DRAG",
		fields = {
			{ id = "rho", label = "Air density rho (kg/m^3)", default = "1.225" },
			{ id = "v", label = "Velocity v (m/s)", default = "340" },
			{ id = "Cd", label = "Drag coefficient Cd", default = "0.3" },
			{ id = "A", label = "Frontal area A (m^2)", default = "10" },
		},
		compute = function(v)
			return 0.5 * v.rho * v.v * v.v * v.Cd * v.A
		end,
		unit = "N",
	},
	["Pizarron_3"] = {
		title = "ORBITAL TRAJECTORY & DELTA-V",
		fields = {
			{ id = "GM", label = "Gravitational parameter GM (m^3/s^2)", default = "3.986e14" },
			{ id = "r", label = "Orbital radius r (m)", default = "6.87e6" },
			{ id = "Isp", label = "Specific impulse Isp (s)", default = "300" },
			{ id = "m0", label = "Initial mass m0 (kg)", default = "500000" },
			{ id = "mf", label = "Final mass mf (kg)", default = "150000" },
		},
		compute = function(v)
			-- Devuelve delta-v (Tsiolkovsky); v orbital se muestra aparte
			return v.Isp * 9.81 * math.log(v.m0 / v.mf)
		end,
		extra = function(v)
			return "v_orb = " .. string.format("%.0f", math.sqrt(v.GM / v.r)) .. " m/s"
		end,
		unit = "m/s",
	},
}

local currentDef = nil
local currentFields = {}

local function clearInputs()
	for _, child in ipairs(inputsHolder:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	currentFields = {}
end

local function buildInputs(def)
	clearInputs()
	for _, field in ipairs(def.fields) do
		local row = Instance.new("Frame")
		row.Size = UDim2.fromScale(1, 0.16)
		row.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
		row.BorderSizePixel = 0
		local rowcorner = Instance.new("UICorner")
		rowcorner.CornerRadius = UDim.new(0, 6)
		rowcorner.Parent = row
		row.Parent = inputsHolder
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(0.55, 1)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(180, 190, 210)
		lbl.Font = Enum.Font.Code
		lbl.TextScaled = true
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = field.label
		lbl.Parent = row
		local box = Instance.new("TextBox")
		box.Size = UDim2.fromScale(0.4, 0.7)
		box.Position = UDim2.fromScale(0.58, 0.15)
		box.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
		box.TextColor3 = Color3.fromRGB(160, 255, 180)
		box.Font = Enum.Font.Code
		box.TextScaled = true
		box.Text = field.default
		box.ClearTextOnFocus = false
		local boxcorner = Instance.new("UICorner")
		boxcorner.CornerRadius = UDim.new(0, 6)
		boxcorner.Parent = box
		box.Parent = row
		currentFields[field.id] = box
	end
end

-- ===== Transicion de camara =====
local function enterBoardView(boardModel)
	local screen = boardModel:FindFirstChild("Screen")
	if not screen then return end
	activeBoard = boardModel
	savedCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local targetCF = screen.CFrame * CFrame.new(0, 0, 9)
	if cameraTween then
		cameraTween:Cancel()
	end
	cameraTween = TweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = targetCF })
	cameraTween:Play()
end

local function exitBoardView()
	if not activeBoard then return end
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if hrp and humanoid and humanoid.Health > 0 then
			camera.CameraType = savedCameraType or Enum.CameraType.Custom
			if cameraTween then cameraTween:Cancel() end
			camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
		end
	else
		camera.CameraType = Enum.CameraType.Custom
	end
	activeBoard = nil
	main.Visible = false
	gui.Enabled = false
end

-- ===== Abrir pizarron =====
local function openBoard(boardModel)
	local def = BOARD_DEFS[boardModel.Name]
	if not def then return end
	currentDef = def
	title.Text = def.title
	resultLabel.Text = "> result..."
	buildInputs(def)
	main.Visible = true
	gui.Enabled = true
	enterBoardView(boardModel)
end

-- ===== Boton calcular =====
calcBtn.MouseButton1Click:Connect(function()
	if not currentDef or not activeBoard then return end
	local values = {}
	local inputsSummary = {}
	for _, field in ipairs(currentDef.fields) do
		local box = currentFields[field.id]
		local num = tonumber(box and box.Text or "")
		if num == nil then
			resultLabel.Text = "> ERROR: invalid value in " .. field.id
			return
		end
		values[field.id] = num
		table.insert(inputsSummary, field.id .. "=" .. tostring(num))
	end
	local result = currentDef.compute(values)
	local extraText = currentDef.extra and ("\n" .. currentDef.extra(values)) or ""
	resultLabel.Text = string.format("> RESULT: %.4g %s%s", result, currentDef.unit, extraText)
	-- Enviar al servidor: sincroniza pizarron local + pantalla maestra
	SyncCalculation:FireServer({
		boardId = activeBoard.Name,
		calcType = currentDef.title,
		inputs = table.concat(inputsSummary, ", "),
		result = result,
	})
end)

exitBtn.MouseButton1Click:Connect(exitBoardView)

-- ===== Conectar prompts de los pizarrones =====
local function connectBoard(boardModel)
	local screen = boardModel:FindFirstChild("Screen")
	local prompt = screen and screen:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function()
			if activeBoard then
				exitBoardView()
			else
				openBoard(boardModel)
			end
		end)
	end
end

for _, board in ipairs(whiteboards:GetChildren()) do
	connectBoard(board)
end
whiteboards.ChildAdded:Connect(connectBoard)

-- ===== Tecla E para salir =====
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if activeBoard and input.KeyCode == Enum.KeyCode.E then
		exitBoardView()
	end
end)

-- Si el personaje muere o reaparece, restaurar camara
player.CharacterAdded:Connect(function()
	if activeBoard then
		exitBoardView()
	end
end)