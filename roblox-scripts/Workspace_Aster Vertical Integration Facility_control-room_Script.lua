local HttpService = game:GetService("HttpService")

-- Puedes usar "DEMO_KEY" para pruebas o tu propia API Key personal de api.nasa.gov
local apiKey = "DEMO_KEY" 

-- URL para obtener los asteroides cercanos del dÃ­a actual
local url = "https://api.nasa.gov/neo/rest/v1/feed?start_date=2026-06-15&end_date=2026-06-15&api_key=" .. apiKey

local function consultarAsteroidesNASA()
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		-- Decodificamos el texto JSON recibido a una tabla de Luau
		local data = HttpService:JSONDecode(response)
		print("Â¡ConexiÃ³n exitosa con la API de la NASA!")

		-- Navegamos por la estructura de la respuesta
		local fechaHoy = "2026-06-15"
		local listaAsteroides = data.near_earth_objects[fechaHoy]

		if listaAsteroides then
			print("Total de asteroides detectados hoy: " .. #listaAsteroides)

			for _, asteroide in ipairs(listaAsteroides) do
				local nombre = asteroide.name
				local esPeligroso = asteroide.is_potentially_hazardous_asteroid
				local diametroMax = asteroide.estimated_diameter.meters.estimated_diameter_max
				local velocidadKmS = asteroide.close_approach_data[0] and asteroide.close_approach_data[0].relative_velocity.kilometers_per_second or "N/A"

				print(string.NIL, "Asteroide: " .. nombre .. " | Peligroso: " .. tostring(esPeligroso) .. " | DiÃ¡metro mÃ¡x: " .. math.round(diametroMax) .. "m")

				-- AQUÃ PUEDES:
				-- 1. Mostrar esta info en una pantalla (SurfaceGui / BillboardGui) en la sala de control.
				-- 2. Generar un objeto fÃ­sico en el mapa proporcional al tamaÃ±o del asteroide.
			end
		end
	else
		warn("Error al conectar con la NASA: " .. tostring(response))
	end
end

-- Ejecutar la funciÃ³n al iniciar el servidor
consultarAsteroidesNASA()print("Hello world!")
