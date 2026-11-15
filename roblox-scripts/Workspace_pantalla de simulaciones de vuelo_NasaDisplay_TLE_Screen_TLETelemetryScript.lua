-- Script: TLETelemetryScript
-- Visualizador Informativo Continuo de TelemetrÃ­a TLE (NORAD)
local HttpService = game:GetService("HttpService")
local screen = script.Parent
local mg = screen:WaitForChild("MasterGui")
local bg = mg:WaitForChild("Background")
local header = bg:WaitForChild("HeaderBar")
local body = bg:WaitForChild("Body")
local leftCol = body:WaitForChild("LeftColumn")
local rightCol = body:WaitForChild("RightColumn")
local bottom = bg:WaitForChild("BottomPanel")

local txtRelojUTC = header:WaitForChild("TxtRelojUTC")
local txtStatusBadge = header:WaitForChild("TxtStatusBadge")

local txtSatName = leftCol:WaitForChild("TxtSatName")
local txtSatSubtitle = leftCol:WaitForChild("TxtSatSubtitle")
local txtCatalogList = leftCol:WaitForChild("TxtCatalogList")
local txtProgressInfo = leftCol:WaitForChild("TxtProgressInfo")
local progressBarFill = leftCol:WaitForChild("ProgressBarBg"):WaitForChild("ProgressBarFill")

local txtMetricsTable = rightCol:WaitForChild("TxtMetricsTable")
local txtLine1 = bottom:WaitForChild("TxtLine1")
local txtLine2 = bottom:WaitForChild("TxtLine2")

-- CatÃ¡logo de SatÃ©lites bajo monitoreo con sus datos TLE reales
local SATELLITES = {
	{
		noradId = 25544,
		name = "INTERNATIONAL SPACE STATION (ISS)",
		intDes = "1998-067A",
		category = "Crewed Space Station (LEO)",
		line1 = "1 25544U 98067A   24080.52183981  .00014235  00000-0  25142-3 0  9998",
		line2 = "2 25544  51.6425 110.2314 0005124  45.1235 315.0124 15.49812450445213"
	},
	{
		noradId = 20580,
		name = "HUBBLE SPACE TELESCOPE (HST)",
		intDes = "1990-037B",
		category = "Optical Space Observatory (LEO)",
		line1 = "1 20580U 90037B   24079.89234120  .00001240  00000-0  56230-4 0  9992",
		line2 = "2 20580  28.4692 278.4512 0002841 120.4512 239.6741 15.09214580874120"
	},
	{
		noradId = 48274,
		name = "TIANGONG SPACE STATION (CSS)",
		intDes = "2021-035A",
		category = "Modular Space Station (LEO)",
		line1 = "1 48274U 21035A   24080.23410291  .00008920  00000-0  18230-3 0  9995",
		line2 = "2 48274  41.4721 164.2140 0003512  85.2310 274.8912 15.58912340165431"
	},
	{
		noradId = 43013,
		name = "NOAA-20 WEATHER SATELLITE",
		intDes = "2017-073A",
		category = "Polar Weather Satellite (SSO)",
		line1 = "1 43013U 17073A   24080.11245120  .00000085  00000-0  45120-4 0  9997",
		line2 = "2 43013  98.7154  45.1245 0001245  92.4150 267.7412 14.19541200325410"
	},
	{
		noradId = 44713,
		name = "STARLINK-1007 CONSTELLATION",
		intDes = "2019-074A",
		category = "Telecommunications Constellation (LEO)",
		line1 = "1 44713U 19074A   24080.35412089  .00003512  00000-0  14520-3 0  9993",
		line2 = "2 44713  53.0542 320.1450 0001520  65.1240 294.9512 15.06412000241520"
	},
	{
		noradId = 49260,
		name = "LANDSAT 9 EARTH OBSERVATION SATELLITE",
		intDes = "2021-088A",
		category = "Earth Resources Observation (SSO)",
		line1 = "1 49260U 21088A   24079.91245012  .00000115  00000-0  65120-4 0  9996",
		line2 = "2 49260  98.2140 185.3412 0001180 110.2145 249.9142 14.57115200135412"
	},
	{
		noradId = 27386,
		name = "ENVISAT SCIENCE SATELLITE",
		intDes = "2002-009A",
		category = "Global Environmental Monitoring (SSO)",
		line1 = "1 27386U 02009A   24080.05412034  .00000045  00000-0  28140-4 0  9991",
		line2 = "2 27386  98.5412  85.4120 0001085  75.4120 284.7124 14.37541200112450"
	}
}

local currentIndex = 1
local CYCLE_TIME = 12
local cycleElapsed = 0

-- FunciÃ³n para decodificar las lÃ­neas TLE
local function decodificarTLE(line1, line2)
	-- Line 2 parse
	-- Pos 9-16: Inclination (degrees)
	local incStr = string.sub(line2, 9, 16)
	local inc = tonumber(incStr) or 0

	-- Pos 18-25: Right Ascension of Ascending Node (RAAN)
	local raanStr = string.sub(line2, 18, 25)
	local raan = tonumber(raanStr) or 0

	-- Pos 27-33: Eccentricity (decimal point assumed)
	local eccStr = string.sub(line2, 27, 33)
	local ecc = tonumber("0." .. eccStr) or 0

	-- Pos 35-42: Argument of Perigee
	local argPerStr = string.sub(line2, 35, 42)
	local argPer = tonumber(argPerStr) or 0

	-- Pos 44-51: Mean Anomaly
	local meanAnomStr = string.sub(line2, 44, 51)
	local meanAnom = tonumber(meanAnomStr) or 0

	-- Pos 53-63: Mean Motion (revolutions per day)
	local mmStr = string.sub(line2, 53, 63)
	local meanMotion = tonumber(mmStr) or 15.0

	-- CÃ¡lculos orbitales derivados
	local periodMin = 1440 / meanMotion
	-- Semieje mayor a = (mu / (n_rad)^2)^(1/3)
	-- mu = 398600.4418 km^3/s^2, n_rad = meanMotion * 2*pi / 86400
	local n_rad = meanMotion * (2 * math.pi) / 86400
	local mu = 398600.4418
	local semiMayor = (mu / (n_rad^2))^(1/3)
	local rEarth = 6378.137
	local perigeeAlt = semiMayor * (1 - ecc) - rEarth
	local apogeeAlt = semiMayor * (1 + ecc) - rEarth
	local meanAlt = (perigeeAlt + apogeeAlt) / 2

	-- Velocidad orbital media v = 2 * pi * a / T
	local speedKmh = ((2 * math.pi * semiMayor) / (periodMin * 60)) * 3600

	-- Ã‰poca (de lÃ­nea 1, cols 19-32)
	local epochStr = string.sub(line1, 19, 32)
	local epochYear = tonumber(string.sub(epochStr, 1, 2)) or 0
	local fullYear = (epochYear < 57) and (2000 + epochYear) or (1900 + epochYear)
	local epochDay = tonumber(string.sub(epochStr, 3)) or 0

	return {
		inclination = inc,
		raan = raan,
		eccentricity = ecc,
		argPerigee = argPer,
		meanAnomaly = meanAnom,
		meanMotion = meanMotion,
		periodMinutes = periodMin,
		meanAltitude = meanAlt,
		apogee = apogeeAlt,
		perigee = perigeeAlt,
		speed = speedKmh,
		epochYear = fullYear,
		epochDay = epochDay
	}
end

-- Intentar consultar la API en vivo
local function consultarAPI(noradId)
	local url = "https://tle.ivanstanojevic.me/api/tle/" .. tostring(noradId)
	local success, res = pcall(function()
		return HttpService:GetAsync(url)
	end)
	if success then
		local dataSuccess, decoded = pcall(function()
			return HttpService:JSONDecode(res)
		end)
		if dataSuccess and decoded.line1 and decoded.line2 then
			return true, decoded.line1, decoded.line2, decoded.name
		end
	end
	return false, nil, nil, nil
end

-- Renderizar la lista de satÃ©lites en la columna izquierda
local function actualizarListaCatalogo(activoIdx)
	local lines = {}
	for i, sat in ipairs(SATELLITES) do
		if i == activoIdx then
			table.insert(lines, string.format('<font color="#00ffff"><b>â–º [%02d] %s</b></font>', i, sat.name))
		else
			table.insert(lines, string.format('<font color="#709ab8">  [%02d] %s</font>', i, sat.name))
		end
	end
	txtCatalogList.Text = table.concat(lines, "\n")
end

-- Actualizar la ficha completa del satÃ©lite
local function mostrarSatelite(index)
	local sat = SATELLITES[index]
	local line1 = sat.line1
	local line2 = sat.line2
	local nombre = sat.name

	-- Intenta refrescar datos en vivo desde la API
	local ok, apiL1, apiL2, apiName = consultarAPI(sat.noradId)
	if ok then
		line1 = apiL1
		line2 = apiL2
		nombre = apiName or sat.name
		txtStatusBadge.Text = "â— LIVE TELEMETRY (API)"
		txtStatusBadge.TextColor3 = Color3.fromRGB(0, 255, 180)
	else
		txtStatusBadge.Text = "â— ACTIVE TRACKING (NORAD TLE)"
		txtStatusBadge.TextColor3 = Color3.fromRGB(0, 215, 255)
	end

	local t = decodificarTLE(line1, line2)

	txtSatName.Text = nombre
	txtSatSubtitle.Text = string.format("NORAD ID: #%d  //  INT DES: %s  //  %s", sat.noradId, sat.intDes, sat.category)

	local orbitType = "Low Earth Orbit (LEO)"
	if t.inclination > 85 and t.inclination < 105 then
		orbitType = "Near-Polar Sun-Synchronous Orbit (SSO)"
	end

	txtMetricsTable.Text = table.concat({
		string.format('<font color="#00e5ff">â€¢ Orbital Inclination (i):</font>      <b>%.4fÂ°</b>', t.inclination),
		string.format('<font color="#00e5ff">â€¢ Mean Altitude (h):</font>             <b>%.1f km</b> (Perigee: %.1f km | Apogee: %.1f km)', t.meanAltitude, t.perigee, t.apogee),
		string.format('<font color="#00e5ff">â€¢ Mean Orbital Velocity:</font>        <b>%.1f km/h</b> (~%.2f km/s)', t.speed, t.speed / 3600),
		string.format('<font color="#00e5ff">â€¢ Orbital Period (T):</font>            <b>%.2f minutes</b> (~%.2f hours)', t.periodMinutes, t.periodMinutes / 60),
		string.format('<font color="#00e5ff">â€¢ Mean Motion (n):</font>               <b>%.8f rev/day</b>', t.meanMotion),
		string.format('<font color="#00e5ff">â€¢ Orbital Eccentricity (e):</font>      <b>%.7f</b> (%s)', t.eccentricity, t.eccentricity < 0.01 and "Near-Circular" or "Elliptical"),
		string.format('<font color="#00e5ff">â€¢ Right Ascension (RAAN):</font>         <b>%.4fÂ°</b>', t.raan),
		string.format('<font color="#00e5ff">â€¢ Argument of Perigee (Ï‰):</font>      <b>%.4fÂ°</b>', t.argPerigee),
		string.format('<font color="#00e5ff">â€¢ Mean Anomaly (M):</font>              <b>%.4fÂ°</b>', t.meanAnomaly),
		string.format('<font color="#00e5ff">â€¢ TLE Element Epoch:</font>              <b>Year %d, Day %.4f</b>', t.epochYear, t.epochDay),
		string.format('<font color="#00e5ff">â€¢ Operational Class:</font>              <b>%s</b>', orbitType)
	}, "\n")

	txtLine1.Text = "LINE 1: " .. line1
	txtLine2.Text = "LINE 2: " .. line2

	actualizarListaCatalogo(index)
end

-- Inicializar primera vista
mostrarSatelite(currentIndex)

-- Bucle principal: actualiza reloj UTC cada segundo y maneja la rotaciÃ³n automÃ¡tica
while true do
	task.wait(1)
	cycleElapsed = cycleElapsed + 1

	-- Reloj en hora UTC explÃ­cita
	local utcString = os.date("!%Y-%m-%d %H:%M:%S")
	txtRelojUTC.Text = "UTC TIME: " .. utcString .. " UTC"

	-- Actualizar barra de progreso y cuenta regresiva
	local remain = math.max(0, CYCLE_TIME - cycleElapsed)
	txtProgressInfo.Text = string.format("AUTO-ROTATION IN: %02ds  [%d/%d]", remain, currentIndex, #SATELLITES)
	local progressRatio = math.clamp(cycleElapsed / CYCLE_TIME, 0, 1)
	progressBarFill.Size = UDim2.new(progressRatio, 0, 1, 0)

	-- Al cumplir el ciclo de tiempo, pasar al siguiente satÃ©lite
	if cycleElapsed >= CYCLE_TIME then
		cycleElapsed = 0
		currentIndex = (currentIndex % #SATELLITES) + 1
		mostrarSatelite(currentIndex)
	end
end
