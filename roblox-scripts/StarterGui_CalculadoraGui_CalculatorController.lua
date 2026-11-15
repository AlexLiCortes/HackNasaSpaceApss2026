-- LocalScript: CalculatorController (Dentro de StarterGui.CalculadoraGui)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local gui = script.Parent

-- 1. La calculadora inicia oculta al entrar al juego
gui.Enabled = false

-- PALETA DE COLORES NASA HUD
local COLOR = {
	Fondo     = Color3.fromRGB(8, 12, 18),
	Panel     = Color3.fromRGB(14, 22, 32),
	Card      = Color3.fromRGB(20, 30, 44),
	Cian      = Color3.fromRGB(0, 195, 255),
	Verde     = Color3.fromRGB(0, 255, 140),
	Amarillo  = Color3.fromRGB(255, 200, 50),
	Texto     = Color3.fromRGB(220, 240, 255),
	TextoGris = Color3.fromRGB(120, 150, 175)
}

-- ESTRUCTURA DE LA INTERFAZ
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 460, 0, 520)
mainFrame.Position = UDim2.new(0.5, -230, 0.5, -260)
mainFrame.BackgroundColor3 = COLOR.Fondo
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = COLOR.Cian
stroke.Thickness = 2
stroke.Parent = mainFrame

-- BARRA DE TÃTULO Y PESTAÃ‘AS
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = COLOR.Panel
header.BorderSizePixel = 0
header.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 180, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "NASA // AP-CALC v2.4"
titleLabel.TextColor3 = COLOR.Cian
titleLabel.Font = Enum.Font.RobotoMono
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local btnCalcTab = Instance.new("TextButton")
btnCalcTab.Size = UDim2.new(0, 100, 0, 30)
btnCalcTab.Position = UDim2.new(1, -215, 0.5, -15)
btnCalcTab.BackgroundColor3 = COLOR.Card
btnCalcTab.Text = "[ CALC ]"
btnCalcTab.TextColor3 = COLOR.Verde
btnCalcTab.Font = Enum.Font.RobotoMono
btnCalcTab.TextSize = 12
btnCalcTab.Parent = header
Instance.new("UICorner", btnCalcTab).CornerRadius = UDim.new(0, 6)

local btnGuiaTab = Instance.new("TextButton")
btnGuiaTab.Size = UDim2.new(0, 100, 0, 30)
btnGuiaTab.Position = UDim2.new(1, -108, 0.5, -15)
btnGuiaTab.BackgroundColor3 = COLOR.Panel
btnGuiaTab.Text = "[ GUIDE ]"
btnGuiaTab.TextColor3 = COLOR.TextoGris
btnGuiaTab.Font = Enum.Font.RobotoMono
btnGuiaTab.TextSize = 12
btnGuiaTab.Parent = header
Instance.new("UICorner", btnGuiaTab).CornerRadius = UDim.new(0, 6)

-- CONTENEDORES DE PESTAÃ‘AS
local calcFrame = Instance.new("Frame")
calcFrame.Name = "CalcFrame"
calcFrame.Size = UDim2.new(1, -20, 1, -65)
calcFrame.Position = UDim2.new(0, 10, 0, 55)
calcFrame.BackgroundTransparency = 1
calcFrame.Parent = mainFrame

local guiaFrame = Instance.new("ScrollingFrame")
guiaFrame.Name = "GuiaFrame"
guiaFrame.Size = UDim2.new(1, -20, 1, -65)
guiaFrame.Position = UDim2.new(0, 10, 0, 55)
guiaFrame.BackgroundTransparency = 1
guiaFrame.Visible = false
guiaFrame.ScrollBarThickness = 4
guiaFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
guiaFrame.CanvasSize = UDim2.new()
guiaFrame.Parent = mainFrame

local listLayoutGuia = Instance.new("UIListLayout")
listLayoutGuia.Padding = UDim.new(0, 10)
listLayoutGuia.SortOrder = Enum.SortOrder.LayoutOrder
listLayoutGuia.Parent = guiaFrame

-- ==================== PESTAÃ‘A 1: CALCULADORA ====================
local display = Instance.new("TextLabel")
display.Size = UDim2.new(1, 0, 0, 60)
display.BackgroundColor3 = COLOR.Panel
display.TextColor3 = COLOR.Verde
display.Font = Enum.Font.RobotoMono
display.TextSize = 26
display.TextXAlignment = Enum.TextXAlignment.Right
display.Text = "0"
display.Parent = calcFrame
Instance.new("UICorner", display).CornerRadius = UDim.new(0, 6)
local displayPadding = Instance.new("UIPadding")
displayPadding.PaddingRight = UDim.new(0, 15)
displayPadding.Parent = display

local gridFrame = Instance.new("Frame")
gridFrame.Size = UDim2.new(1, 0, 1, -70)
gridFrame.Position = UDim2.new(0, 0, 0, 70)
gridFrame.BackgroundTransparency = 1
gridFrame.Parent = calcFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.23, 0, 0.21, 0)
gridLayout.CellPadding = UDim2.new(0.02, 0, 0.03, 0)
gridLayout.Parent = gridFrame

local botones = {
	"7", "8", "9", "/",
	"4", "5", "6", "*",
	"1", "2", "3", "-",
	"C", "0", "=", "+"
}

local expresion = ""

for _, txt in ipairs(botones) do
	local btn = Instance.new("TextButton")
	btn.Text = txt
	btn.Font = Enum.Font.RobotoMono
	btn.TextSize = 18
	btn.BackgroundColor3 = COLOR.Card
	btn.TextColor3 = (txt == "C") and Color3.fromRGB(255, 80, 80) or ((txt == "=" or txt == "+" or txt == "-" or txt == "*" or txt == "/") and COLOR.Cian or COLOR.Texto)
	btn.Parent = gridFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Click:Connect(function()
		if txt == "C" then
			expresion = ""
			display.Text = "0"
		elseif txt == "=" then
			local func, err = loadstring("return " .. expresion)
			if func and pcall(func) then
				local res = func()
				display.Text = tostring(res)
				expresion = tostring(res)
			else
				display.Text = "ERROR"
				expresion = ""
			end
		else
			expresion = expresion .. txt
			display.Text = expresion
		end
	end)
end

-- ==================== PESTAÃ‘A 2: GUÃA DE FÃ“RMULAS VISUAL ====================
local formulas = {
	{
		titulo = "1. THRUST",
		icono = "ðŸš€",
		eq = "F = (mdot * Ve) + (Pe - Pa) * Ae",
		desc = "â€¢ mdot: Mass flow rate (kg/s)\nâ€¢ Ve: Exhaust velocity (m/s)\nâ€¢ Pe - Pa: Pressure differential\nâ€¢ Ae: Nozzle exit area (mÂ²)"
	},
	{
		titulo = "2. NET FORCE",
		icono = "âš–ï¸",
		eq = "Fnet = Fthrust - Fdrag - (m * g)",
		desc = "â€¢ Fthrust: Total engine thrust\nâ€¢ Fdrag: Atmospheric drag\nâ€¢ m * g: Vehicle weight (Mass Ã— Gravity)"
	},
	{
		titulo = "3. AERODYNAMIC DRAG",
		icono = "ðŸ’¨",
		eq = "Fd = 0.5 * rho * vÂ² * Cd * A",
		desc = "â€¢ rho: Air density (kg/mÂ³)\nâ€¢ v: Rocket velocity (m/s)\nâ€¢ Cd: Drag coefficient\nâ€¢ A: Exposed frontal area (mÂ²)"
	},
	{
		titulo = "4. ORBITAL VELOCITY (DELTA-V)",
		icono = "ðŸŒ",
		eq = "Î”v = Isp * g0 * ln(m0 / mf)",
		desc = "â€¢ Isp: Specific impulse (s)\nâ€¢ g0: Standard gravity (9.81 m/sÂ²)\nâ€¢ m0/mf: Initial mass vs. final mass"
	}
}

for _, info in ipairs(formulas) do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -6, 0, 115)
	card.BackgroundColor3 = COLOR.Card
	card.BorderSizePixel = 0
	card.Parent = guiaFrame
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = COLOR.Cian
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	local cardHeader = Instance.new("TextLabel")
	cardHeader.Size = UDim2.new(1, -12, 0, 24)
	cardHeader.Position = UDim2.new(0, 10, 0, 4)
	cardHeader.BackgroundTransparency = 1
	cardHeader.Text = info.icono .. "  " .. info.titulo
	cardHeader.TextColor3 = COLOR.Amarillo
	cardHeader.Font = Enum.Font.RobotoMono
	cardHeader.TextSize = 13
	cardHeader.TextXAlignment = Enum.TextXAlignment.Left
	cardHeader.Parent = card

	local eqLabel = Instance.new("TextLabel")
	eqLabel.Size = UDim2.new(1, -20, 0, 20)
	eqLabel.Position = UDim2.new(0, 10, 0, 28)
	eqLabel.BackgroundColor3 = COLOR.Panel
	eqLabel.Text = "  " .. info.eq
	eqLabel.TextColor3 = COLOR.Verde
	eqLabel.Font = Enum.Font.RobotoMono
	eqLabel.TextSize = 11
	eqLabel.TextXAlignment = Enum.TextXAlignment.Left
	eqLabel.Parent = card
	Instance.new("UICorner", eqLabel).CornerRadius = UDim.new(0, 4)

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -20, 0, 55)
	descLabel.Position = UDim2.new(0, 10, 0, 52)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = info.desc
	descLabel.TextColor3 = COLOR.TextoGris
	descLabel.Font = Enum.Font.RobotoMono
	descLabel.TextSize = 10
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = card
end

-- INTERCAMBIO DE PESTAÃ‘AS
btnCalcTab.MouseButton1Click:Connect(function()
	calcFrame.Visible = true
	guiaFrame.Visible = false
	btnCalcTab.BackgroundColor3 = COLOR.Card
	btnCalcTab.TextColor3 = COLOR.Verde
	btnGuiaTab.BackgroundColor3 = COLOR.Panel
	btnGuiaTab.TextColor3 = COLOR.TextoGris
end)

btnGuiaTab.MouseButton1Click:Connect(function()
	calcFrame.Visible = false
	guiaFrame.Visible = true
	btnGuiaTab.BackgroundColor3 = COLOR.Card
	btnGuiaTab.TextColor3 = COLOR.Verde
	btnCalcTab.BackgroundColor3 = COLOR.Panel
	btnCalcTab.TextColor3 = COLOR.TextoGris
end)

-- ==================== DETECCIÃ“N DE LA HERRAMIENTA (TECLA 1) ====================
-- Este bloque solo responde a la Calculadora Espacial, ignorando otras Tools (p.ej. el Scanner)
local NOMBRE_HERRAMIENTA = "Calculadora Espacial"

local function conectarPersonaje(character)
	-- Cuando se equipa la Calculadora (pasa del Backpack al Character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == NOMBRE_HERRAMIENTA then
			gui.Enabled = true
		end
	end)

	-- Cuando se guarda la Calculadora (sale del Character de vuelta al Backpack)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == NOMBRE_HERRAMIENTA then
			gui.Enabled = false
		end
	end)
end

if player.Character then
	conectarPersonaje(player.Character)
end

player.CharacterAdded:Connect(conectarPersonaje)
