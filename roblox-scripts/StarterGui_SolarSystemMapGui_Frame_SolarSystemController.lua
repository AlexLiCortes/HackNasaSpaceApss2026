local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local frame = script.Parent
local vp = frame:WaitForChild("ViewportFrame")
local panelInfo = frame:WaitForChild("PanelInfo")
local headerBar = frame:WaitForChild("HeaderBar")
local navBar = frame:WaitForChild("PanelNavegacion")

local txtNombre = panelInfo:WaitForChild("TxtNombre")
local txtCategoria = panelInfo:WaitForChild("TxtCategoria")
local txtDescripcion = panelInfo:WaitForChild("TxtDescripcion")
local txtDatos = panelInfo:WaitForChild("TxtDatos")
local topAccent = panelInfo:WaitForChild("TopAccent")

local txtEstado = headerBar:WaitForChild("TxtEstado")
local btnIzq = navBar:WaitForChild("BtnIzquierda")
local btnDer = navBar:WaitForChild("BtnDerecha")
local txtPlanetaActual = navBar:WaitForChild("TxtPlanetaActual")
local txtSubNav = navBar:WaitForChild("TxtSubNavegacion")

-- Ensure ViewportCamera exists and is assigned
local cam = vp:FindFirstChildOfClass("Camera")
if not cam then
	cam = Instance.new("Camera")
	cam.Name = "ViewportCamera"
	cam.FieldOfView = 50
	cam.Parent = vp
end
vp.CurrentCamera = cam

-- Lista de los 8 Planetas del Sistema Solar (en orden estricto de distancia al Sol)
local PLANETAS = {
	{
		partName = "Mercury", -- NASA: verified info
		nombre = "MERCURY",
		posicion = 1,
		categoria = "â—ˆ 1ST PLANET OF THE SOLAR SYSTEM  //  ROCKY",
		accentColor = Color3.fromRGB(140, 210, 255),
		zoomMult = 3.25,
		descripcion = "The innermost planet and the closest to the Sun. It is the smallest planet in the solar system; its surface is covered in impact craters and it endures the most extreme temperature swings.",
		caracteristicas = {
			{ "Distance from Earth", "77.3 to 221.9 million km" },
			{ "Distance from Sun", "57.9 million km (0.39 AU)" },
			{ "Equatorial Radius", "2440.53 km" },
			{ "Mean Temperature", "440 K (332.33 Â°F)" },
			{ "Equatorial Gravity", "3.701 m/sÂ²" },
			{ "Escape Velocity", "4.435 km/s" },
			{ "Sidereal Day Length", "1407.6 hours" },
			{ "Mass", "3.302 x10^23 kg" },
			{ "Volume", "6.085 x10^10 kmÂ³" },
			{ "Orbital Period (Year)", "87.969 Earth days" },
			{ "Natural Satellites", "0 moons" },
		},
	},
	{
		partName = "Venus", -- NASA: verified info
		nombre = "VENUS",
		posicion = 2,
		categoria = "â—ˆ 2ND PLANET OF THE SOLAR SYSTEM  //  ROCKY",
		accentColor = Color3.fromRGB(255, 210, 120),
		zoomMult = 3.15,
		descripcion = "The second planet from the Sun. Similar in size to Earth, but with a crushing COâ‚‚ atmosphere that drives a runaway greenhouse effect, making it the hottest planet.",
		caracteristicas = {
			{ "Distance from Earth", "38.2 to 261 million km" },
			{ "Distance from Sun", "108.2 million km (0.72 AU)" },
			{ "Equatorial Radius", "6051.8 km" },
			{ "Mean Temperature", "737 K (866.93 Â°F)" },
			{ "Equatorial Gravity", "8.87 m/sÂ²" },
			{ "Escape Velocity", "10.36 km/s" },
			{ "Sidereal Day Length", "5832.6 hours (retrograde)" },
			{ "Mass", "48.675 x10^23 kg" },
			{ "Volume", "92.843 x10^10 kmÂ³" },
			{ "Orbital Period (Year)", "224.701 Earth days" },
			{ "Natural Satellites", "0 moons" },
		},
	},
	{
		partName = "Earth",
		nombre = "EARTH", -- NASA: verified info
		posicion = 3,
		categoria = "â—ˆ 3RD PLANET OF THE SOLAR SYSTEM  //  TERRESTRIAL",
		accentColor = Color3.fromRGB(0, 215, 255),
		zoomMult = 3.15,
		descripcion = "The third planet from the Sun and our home. It is the only known planet with liquid water on its surface, a breathable oxygen-rich atmosphere and abundant life.",
		caracteristicas = {
			{ "Distance from Earth", "0 km (Home planet)" },
			{ "Distance from Sun", "149.6 million km (1.00 AU)" },
			{ "Equatorial Radius", "6378.137 km" },
			{ "Mean Temperature", "288.15 K (59.00 Â°F)" },
			{ "Equatorial Gravity", "9.798 m/sÂ²" },
			{ "Escape Velocity", "11.19 km/s" },
			{ "Sidereal Day Length", "23.934 hours" },
			{ "Mass", "59.724 x10^23 kg" },
			{ "Volume", "108.321 x10^10 kmÂ³" },
			{ "Orbital Period (Year)", "365.256 days" },
			{ "Natural Satellites", "1 (The Moon)" },
		},
	},
	{
		partName = "Mars", -- NASA: verified info
		nombre = "MARS",
		posicion = 4,
		categoria = "â—ˆ 4TH PLANET OF THE SOLAR SYSTEM  //  ROCKY",
		accentColor = Color3.fromRGB(255, 115, 75),
		zoomMult = 3.2,
		descripcion = "The fourth planet from the Sun, known as the Red Planet because of its iron oxide. It has giant canyons, polar ice caps and Olympus Mons, the largest volcano in the solar system.",
		caracteristicas = {
			{ "Distance from Earth", "54.6 to 401 million km" },
			{ "Distance from Sun", "228 million km (1.5 AU)" },
			{ "Equatorial Radius", "3396.19 km" },
			{ "Mean Temperature", "210 K (-81.67 Â°F)" },
			{ "Equatorial Gravity", "3.71 m/sÂ²" },
			{ "Escape Velocity", "5.027 km/s" },
			{ "Sidereal Day Length", "24.6229 hours" },
			{ "Mass", "6.4171 x10^23 kg" },
			{ "Volume", "16.318 x10^10 kmÂ³" },
			{ "Orbital Period (Year)", "686.98 Earth days" },
			{ "Natural Satellites", "2 (Phobos and Deimos)" },
		},
	},
	{
		partName = "Jupiter", --NASA: verified info
		nombre = "JUPITER",
		posicion = 5,
		categoria = "â—ˆ 5TH PLANET OF THE SOLAR SYSTEM  //  GAS GIANT",
		accentColor = Color3.fromRGB(240, 180, 115),
		zoomMult = 3.05,
		descripcion = "The fifth planet and the giant of the solar system: it has more than twice the mass of all the other planets combined. Its iconic Great Red Spot stands out.",
		caracteristicas = {
			{ "Distance from Earth", "588 to 968 million km" },
			{ "Distance from Sun", "778.5 million km (5.20 AU)" },
			{ "Equatorial Radius", "71492 km" },
			{ "Temperature (1 bar)", "165 K (-162.67 Â°F)" },
			{ "Equatorial Gravity", "24.79 m/sÂ²" },
			{ "Escape Velocity", "59.5 km/s" },
			{ "Sidereal Day Length", "9.925 hours" },
			{ "Mass", "18981.87 x10^23 kg" },
			{ "Volume", "143128 x10^10 kmÂ³" },
			{ "Orbital Period (Year)", "11.862 Earth years" },
			{ "Natural Satellites", "95 known moons" },
		},
	},
	{
		partName = "Saturn",
		nombre = "SATURN", -- Nasa verified info
		posicion = 6,
		categoria = "â—ˆ 6TH PLANET OF THE SOLAR SYSTEM  //  GAS GIANT",
		accentColor = Color3.fromRGB(245, 215, 140),
		zoomMult = 3.85,
		descripcion = "The sixth planet from the Sun, famous for its majestic system of bright rings made of ice and rock. It is the second-largest planet and the least dense.",
		caracteristicas = {
			{ "Distance from Earth", "1,200 to 1,670 million km" },
			{ "Distance from Sun", "1,434 million km (9.58 AU)" },
			{ "Equatorial Radius", "60268 km" },
			{ "Temperature (1 bar)", "134 K (-218.47 Â°F)" },
			{ "Equatorial Gravity", "10.44 m/sÂ²" },
			{ "Escape Velocity", "35.5 km/s" },
			{ "Sidereal Day Length", "10.656 hours" },
			{ "Mass", "5683.17 x10^23 kg" },
			{ "Volume", "82713 x10^10 kmÂ³" },
			{ "Orbital Period (Year)", "29.457 Earth years" },
			{ "Natural Satellites", "146 known moons" },
		},
	},
	{
		partName = "Uranus", -- Nasa verified info
		nombre = "URANUS",
		posicion = 7,
		categoria = "â—ˆ 7TH PLANET OF THE SOLAR SYSTEM  //  ICE GIANT",
		accentColor = Color3.fromRGB(110, 235, 255),
		zoomMult = 3.15,
		descripcion = "The seventh planet from the Sun. It is an ice giant with a cyan hue caused by methane. Its most striking feature is that it orbits on its side, with a 98Â° axial tilt.",
		caracteristicas = {
			{ "Distance from Earth", "2,570 to 3,150 million km" },
			{ "Distance from Sun", "2,871 million km (19.2 AU)" },
			{ "Equatorial Radius", "25559 km" },
			{ "Temperature (1 bar)", "76 K (-322.87 Â°F)" },
			{ "Equatorial Gravity", "8.69 m/sÂ²" },
			{ "Escape Velocity", "21.3 km/s" },
			{ "Sidereal Day Length", "17.24 hours (retrograde)" },
			{ "Mass", "868.13 x10^23 kg" },
			{ "Volume", "6833 x10^10 kmÂ³" },
			{ "Orbital Period (Year)", "84.020 Earth years" },
			{ "Natural Satellites", "28 known moons" },
		},
	},
	{
		partName = "Neptune",
		nombre = "NEPTUNE",
		posicion = 8,
		categoria = "â—ˆ 8TH PLANET OF THE SOLAR SYSTEM  //  ICE GIANT",
		accentColor = Color3.fromRGB(60, 155, 255),
		zoomMult = 3.15,
		descripcion = "The eighth and outermost planet of the solar system. It is a distant, frigid world battered by the most extreme supersonic winds in the solar system (over 2,000 km/h).",
		caracteristicas = {
			{ "Distance from Earth", "4,300 to 4,700 million km" },
			{ "Distance from Sun", "4,495 million km (30.1 AU)" },
			{ "Equatorial Radius", "24764 km" },
			{ "Temperature (1 bar)", "72 K (-330.07 Â°F)" },
			{ "Equatorial Gravity", "11.15 m/sÂ²" },
			{ "Escape Velocity", "23.5 km/s" },
			{ "Sidereal Day Length", "16.11 hours" },
			{ "Mass", "1024.09 x10^23 kg" },
			{ "Volume", "6254 x10^10 kmÂ³" },
			{ "Orbital Period (Year)", "164.8 Earth years" },
			{ "Natural Satellites", "16 known moons" },
		},
	},
}

local currentIndex = 3 -- La Tierra (3er Planeta del Sistema Solar)
local activeCameraTween = nil
local isTransitioning = false
local orbitAngle = 0

local function formatCaracteristicas(lista)
	local lines = {}
	for _, item in ipairs(lista) do
		table.insert(lines, string.format('<font color="#4dd2ff">â€¢ %s:</font>  %s', item[1], item[2]))
	end
	return table.concat(lines, "\n")
end

local function getPlanetCameraCFrame(index, extraYaw)
	local data = PLANETAS[index]
	local part = vp:FindFirstChild(data.partName)
	if not part or not part:IsA("BasePart") then
		return cam.CFrame
	end

	local radius = part.Size.X * 0.5
	local dist = radius * (data.zoomMult or 3.0)
	local yaw = math.rad(18) + (extraYaw or 0)
	local pitch = math.rad(14)

	local offset = Vector3.new(
		math.sin(yaw) * math.cos(pitch) * dist,
		math.sin(pitch) * dist,
		math.cos(yaw) * math.cos(pitch) * dist
	)

	local camPos = part.Position + offset
	local lookTarget = part.Position + Vector3.new(-radius * 0.58, -radius * 0.18, 0)
	return CFrame.lookAt(camPos, lookTarget)
end

local function focusPlanet(index, animate)
	if index < 1 then
		index = #PLANETAS
	elseif index > #PLANETAS then
		index = 1
	end
	currentIndex = index

	local data = PLANETAS[currentIndex]

	txtNombre.Text = data.nombre
	txtCategoria.Text = data.categoria
	txtDescripcion.Text = data.descripcion
	txtDatos.Text = formatCaracteristicas(data.caracteristicas)

	txtEstado.Text = string.format("CLOSE-UP CAMERA  [%02d/%02d]", currentIndex, #PLANETAS)
	txtPlanetaActual.Text = data.nombre
	txtSubNav.Text = string.format("â—„ PREVIOUS   â€¢   %d / %d   â€¢   NEXT â–º", currentIndex, #PLANETAS)

	TweenService:Create(topAccent, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = data.accentColor or Color3.fromRGB(0, 215, 255),
	}):Play()

	txtNombre.TextTransparency = 0.45
	txtDescripcion.TextTransparency = 0.45
	TweenService:Create(txtNombre, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()
	TweenService:Create(txtDescripcion, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()

	orbitAngle = 0
	local targetCF = getPlanetCameraCFrame(currentIndex, 0)

	if activeCameraTween then
		activeCameraTween:Cancel()
		activeCameraTween = nil
	end

	if animate then
		isTransitioning = true
		local tweenInfo = TweenInfo.new(0.85, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		activeCameraTween = TweenService:Create(cam, tweenInfo, { CFrame = targetCF })
		activeCameraTween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				isTransitioning = false
			end
		end)
		activeCameraTween:Play()
	else
		isTransitioning = false
		cam.CFrame = targetCF
	end
end

local function setupButtonHover(btn, defaultBg, hoverBg)
	local stroke = btn:FindFirstChildOfClass("UIStroke")
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = hoverBg }):Play()
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.18), { Transparency = 0, Thickness = 2.2 }):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundColor3 = defaultBg }):Play()
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.18), { Transparency = 0.25, Thickness = 1.5 }):Play()
		end
	end)
end

setupButtonHover(btnIzq, Color3.fromRGB(14, 38, 74), Color3.fromRGB(0, 110, 190))
setupButtonHover(btnDer, Color3.fromRGB(14, 38, 74), Color3.fromRGB(0, 110, 190))

btnIzq.MouseButton1Click:Connect(function()
	focusPlanet(currentIndex - 1, true)
end)

btnDer.MouseButton1Click:Connect(function()
	focusPlanet(currentIndex + 1, true)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not frame.Visible then
		return
	end
	if input.KeyCode == Enum.KeyCode.Left then
		focusPlanet(currentIndex - 1, true)
	elseif input.KeyCode == Enum.KeyCode.Right then
		focusPlanet(currentIndex + 1, true)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not frame.Visible then
		return
	end

	for _, data in ipairs(PLANETAS) do
		local p = vp:FindFirstChild(data.partName)
		if p and p:IsA("BasePart") then
			p.Orientation = p.Orientation + Vector3.new(0, dt * 12, 0)
		end
	end

	if not isTransitioning then
		orbitAngle = orbitAngle + dt * 0.45
		local sway = math.sin(orbitAngle) * math.rad(4)
		cam.CFrame = getPlanetCameraCFrame(currentIndex, sway)
	end
end)

-- Iniciar en La Tierra (Planeta 3 de 8)
focusPlanet(3, false)

-- Escuchar evento del servidor para abrir la GUI limpiamente en el cliente cada vez que se interactÃºe
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local abrirMapaEvent = ReplicatedStorage:WaitForChild("AbrirMapaEvent")

abrirMapaEvent.OnClientEvent:Connect(function()
	frame.Visible = true
	-- Reactivar la cÃ¡mara en el planeta actual si es necesario
	focusPlanet(currentIndex, false)
end)
