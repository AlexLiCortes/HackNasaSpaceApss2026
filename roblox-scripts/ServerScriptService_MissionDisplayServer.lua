local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local pantalla = Workspace:FindFirstChild("Pantalla_de_mision_seleccionada")
	or Workspace:FindFirstChild("Pantalla_de_mision seleccionada")

if not pantalla then
	error("No se encontrÃ³ la pantalla de misiÃ³n en Workspace")
end

local misionActiva = ReplicatedStorage:WaitForChild("MisionActivaPlaneta")

local function buscarSuperficiePantalla()
	local mejorParte
	local mejorArea = 0

	for _, instancia in ipairs(pantalla:GetDescendants()) do
		if instancia:IsA("BasePart") then
			local area = instancia.Size.X * instancia.Size.Y
			if instancia.Size.Z < 0.4 and area > mejorArea then
				mejorParte = instancia
				mejorArea = area
			end
		end
	end

	if not mejorParte then
		error("No se encontrÃ³ una superficie vÃ¡lida en la pantalla de misiÃ³n")
	end

	return mejorParte
end

local superficie = buscarSuperficiePantalla()
local gui = superficie:FindFirstChild("MissionDisplayGui")
if not gui then
	gui = Instance.new("SurfaceGui")
	gui.Name = "MissionDisplayGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.Parent = superficie
end

local etiqueta = gui:FindFirstChild("MissionText")
if not etiqueta then
	etiqueta = Instance.new("TextLabel")
	etiqueta.Name = "MissionText"
	etiqueta.Size = UDim2.fromScale(1, 1)
	etiqueta.BackgroundTransparency = 1
	etiqueta.Font = Enum.Font.GothamBold
	etiqueta.TextColor3 = Color3.fromRGB(0, 255, 140)
	etiqueta.TextScaled = true
	etiqueta.TextWrapped = true
	etiqueta.Rotation = 180
	etiqueta.Parent = gui
end

-- English display names only (internal keys stay unchanged)
local PLANET_NAMES_EN = { Luna = "Moon", Marte = "Mars", Venus = "Venus", Mercurio = "Mercury", ["JÃºpiter"] = "Jupiter", Saturno = "Saturn", Urano = "Uranus", Neptuno = "Neptune" }

local function actualizarPantalla()
	local planeta = misionActiva.Value
	if planeta == "" then
		etiqueta.Text = "SELECT A MISSION"
	else
		etiqueta.Text = "YOUR MISSION: " .. string.upper(PLANET_NAMES_EN[planeta] or planeta)
	end
end

misionActiva.Changed:Connect(actualizarPantalla)
actualizarPantalla()
