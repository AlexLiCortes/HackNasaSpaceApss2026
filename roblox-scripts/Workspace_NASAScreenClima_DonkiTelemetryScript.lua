local NASA_API_KEY = "jgg8JzjrD99tg6t7kNmpLzqhm6NGjNNFr7mFDDnz" 
-- DonkiTelemetryScript v3 :: SOLO actualiza .Text / .TextColor3 de la interfaz ya construida en ediciÃ³n.
-- NO crea ni destruye ningÃºn elemento del SurfaceGui "DonkiGui".

local HttpService = game:GetService("HttpService")

local screen = script.Parent
local ROTATION_SECONDS = 15
local REFRESH_SECONDS = 30 * 60
local MAX_EVENTS = 7

---------------------------------------------------------------------
-- REFERENCIAS A LA INTERFAZ EXISTENTE (construida en ediciÃ³n)
---------------------------------------------------------------------
local gui    = screen:WaitForChild("DonkiGui")
local root   = gui:WaitForChild("Root")
local header = root:WaitForChild("Header")
local left   = root:WaitForChild("LeftPanel")
local right  = root:WaitForChild("RightPanel")

local clockLabel     = header:WaitForChild("Clock")
local eventTitle     = left:WaitForChild("EventTitle")
local eventSub       = left:WaitForChild("EventSub")
local countdownLabel = left:WaitForChild("Countdown")
local listFrame      = left:WaitForChild("EventList")
local rowsFrame      = right:WaitForChild("Rows")

local listItems = {}
for i = 1, MAX_EVENTS do
	listItems[i] = listFrame:WaitForChild("Item" .. i)
end
local rowValues = {}
for i = 1, 6 do
	rowValues[i] = rowsFrame:WaitForChild("Row" .. i):WaitForChild("Value")
end

---------------------------------------------------------------------
-- PALETA (solo colores de texto)
---------------------------------------------------------------------
local C = {
	active   = Color3.fromRGB(255, 255, 255),
	value    = Color3.fromRGB(240, 248, 255),
	inactive = Color3.fromRGB(90, 115, 130),
	danger   = Color3.fromRGB(255, 70, 70),
	warning  = Color3.fromRGB(255, 200, 0),
}

---------------------------------------------------------------------
-- RESPALDO: 7 llamaradas reales registradas en NASA DONKI
---------------------------------------------------------------------
local FALLBACK = {
	{ classType = "X5.1", beginTime = "2025-11-11T09:19Z", peakTime = "2025-11-11T10:04Z", activeRegionNum = 14274, cmeSpeed = 1500 },
	{ classType = "X1.8", beginTime = "2024-10-09T01:25Z", peakTime = "2024-10-09T01:56Z", activeRegionNum = 13848, cmeSpeed = 1300 },
	{ classType = "X9.0", beginTime = "2024-10-03T12:08Z", peakTime = "2024-10-03T12:18Z", activeRegionNum = 13842, cmeSpeed = 850 },
	{ classType = "X8.7", beginTime = "2024-05-14T16:46Z", peakTime = "2024-05-14T16:51Z", activeRegionNum = 13664, cmeSpeed = 1100 },
	{ classType = "X5.8", beginTime = "2024-05-11T01:10Z", peakTime = "2024-05-11T01:23Z", activeRegionNum = 13664, cmeSpeed = 1200 },
	{ classType = "X3.9", beginTime = "2024-05-10T06:27Z", peakTime = "2024-05-10T06:54Z", activeRegionNum = 13664, cmeSpeed = 1000 },
	{ classType = "X6.3", beginTime = "2024-02-22T22:08Z", peakTime = "2024-02-22T22:34Z", activeRegionNum = 13590, cmeSpeed = nil },
}

---------------------------------------------------------------------
-- DECODIFICACIÃ“N
---------------------------------------------------------------------
local function fmtTime(t)
	if type(t) ~= "string" or t == "" then return "IN PROGRESS / N/A" end
	local d, h = t:match("^(%d+%-%d+%-%d+)T(%d+:%d+)")
	if d then return d .. " " .. h .. " UTC" end
	return t
end

local function parseClass(classType)
	local letter, mag = tostring(classType or ""):match("^([ABCMX])([%d%.]+)")
	return letter or "?", tonumber(mag) or 0
end

local KP_TEXT = {
	[1] = "Quiet", [2] = "Quiet", [3] = "Unsettled", [4] = "Active",
	[5] = "Minor G1", [6] = "Moderate G2", [7] = "Strong G3",
	[8] = "Severe G4", [9] = "Extreme G5",
}

local function decode(ev)
	local letter, mag = parseClass(ev.classType)
	local kp, solar, rf, intensity, requirement, reqColor, impact
	if letter == "X" then
		kp = mag >= 5 and 8 or 7
		solar, rf = -25 - math.min(math.floor(mag * 2), 20), 40 + math.min(math.floor(mag * 4), 40)
		intensity = mag >= 5 and "Extreme" or "Severe"
		requirement, reqColor, impact = "RADIATION SHIELDING REQUIRED", C.danger, "HIGH"
	elseif letter == "M" then
		kp = mag >= 5 and 6 or 5
		solar, rf = -10 - math.floor(mag), 15 + math.floor(mag * 2)
		intensity = mag >= 5 and "Strong" or "Moderate"
		requirement = mag >= 5 and "RF PROTOCOL + PARTIAL SHIELDING" or "ENHANCED SYSTEMS MONITORING"
		reqColor, impact = C.warning, "MEDIUM"
	elseif letter == "C" then
		kp, solar, rf = 3, -3, 5
		intensity, requirement, reqColor, impact = "Minor", "NOMINAL OPERATIONS", C.value, "LOW"
	else
		kp, solar, rf = 2, 0, 1
		intensity, requirement, reqColor, impact = "Weak", "NOMINAL OPERATIONS", C.value, "MINIMAL"
	end
	if ev.cmeSpeed then kp = math.min(kp + 1, 9) end

	return {
		string.format("Class %s - %s", tostring(ev.classType or "N/D"), intensity),
		fmtTime(ev.peakTime),
		ev.cmeSpeed and string.format("%d km/s", math.floor(ev.cmeSpeed + 0.5)) or "Nominal (no CME)",
		string.format("Kp %d - %s", kp, KP_TEXT[kp]),
		string.format("%d%% Solar Power | +%d%% RF Noise", solar, rf),
		requirement,
	}, reqColor, impact
end

---------------------------------------------------------------------
-- DESCARGA NASA DONKI
---------------------------------------------------------------------
local function getJson(url)
	local ok, res = pcall(function()
		return HttpService:GetAsync(url, true)
	end)
	if not ok then
		warn("[DONKI] Error HTTP: " .. tostring(res))
		return nil
	end
	local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
	if not ok2 or type(data) ~= "table" then
		warn("[DONKI] Respuesta no vÃ¡lida")
		return nil
	end
	return data
end

local function fetchEvents()
	local now = os.time()
	local startDate = os.date("!%Y-%m-%d", now - 30 * 86400)
	local endDate = os.date("!%Y-%m-%d", now)
	local base = "https://api.nasa.gov/DONKI/"
	local range = string.format("?startDate=%s&endDate=%s&api_key=%s", startDate, endDate, NASA_API_KEY)

	-- Intenta: rango de 30 dÃ­as -> URL simple -> servidor directo CCMC
	local flares
	local candidates = {
		base .. "FLR" .. range,
		base .. "FLR?api_key=" .. NASA_API_KEY,
		string.format("https://kauai.ccmc.gsfc.nasa.gov/DONKI/WS/get/FLR?startDate=%s&endDate=%s", startDate, endDate),
	}
	for _, url in ipairs(candidates) do
		local data = getJson(url)
		if type(data) == "table" and #data > 0 then
			flares = data
			break
		end
	end
	if not flares then
		return nil
	end

	-- Velocidades CME (opcional): activityID -> speed
	local cmeSpeeds = {}
	local cmes = getJson(base .. "CME" .. range)
	if cmes then
		for _, cme in ipairs(cmes) do
			local best
			if type(cme.cmeAnalyses) == "table" then
				for _, a in ipairs(cme.cmeAnalyses) do
					if a.isMostAccurate and a.speed then best = a.speed end
					best = best or a.speed
				end
			end
			if cme.activityID and best then cmeSpeeds[cme.activityID] = best end
		end
	end

	table.sort(flares, function(a, b) return tostring(a.beginTime) > tostring(b.beginTime) end)

	local out = {}
	for i = 1, math.min(MAX_EVENTS, #flares) do
		local f = flares[i]
		local ev = {
			classType = f.classType, beginTime = f.beginTime, peakTime = f.peakTime,
			activeRegionNum = f.activeRegionNum,
		}
		if type(f.linkedEvents) == "table" then
			for _, le in ipairs(f.linkedEvents) do
				local id = le.activityID
				if id and id:find("CME") and cmeSpeeds[id] then ev.cmeSpeed = cmeSpeeds[id] end
			end
		end
		table.insert(out, ev)
	end
	return out
end

---------------------------------------------------------------------
-- RENDER (solo .Text / .TextColor3)
---------------------------------------------------------------------
local events = table.clone(FALLBACK)
local index = 1
local countdown = ROTATION_SECONDS

local function renderList()
	for i = 1, MAX_EVENTS do
		local item = listItems[i]
		local ev = events[i]
		if ev then
			local d = fmtTime(ev.beginTime):gsub(" UTC", "")
			local txt = string.format("[%02d] FLR %-4s |  %s", i, tostring(ev.classType or "?"), d)
			if i == index then
				item.Text = "â–¶ " .. txt
				item.TextColor3 = C.active
			else
				item.Text = "  " .. txt
				item.TextColor3 = C.inactive
			end
		else
			item.Text = string.format("  [%02d] ---", i)
			item.TextColor3 = C.inactive
		end
	end
end

local function renderEvent()
	local ev = events[index]
	if not ev then return end
	local values, reqColor, impact = decode(ev)

	eventTitle.Text = "SOLAR FLARE (FLR)"
	eventSub.Text = string.format("SOURCE: AR%s // IMPACT: %s", tostring(ev.activeRegionNum or "N/D"), impact)

	for i, v in ipairs(values) do
		rowValues[i].Text = v
	end
	rowValues[6].TextColor3 = reqColor

	renderList()
end

local function renderCountdown()
	countdownLabel.Text = string.format("NEXT EVENT IN: %ds [%d/%d]", countdown, index, #events)
end

local function renderClock()
	clockLabel.Text = "UTC: " .. os.date("!%Y-%m-%d %H:%M:%S")
end

local function refresh()
	local fresh = fetchEvents()
	if fresh and #fresh > 0 then
		-- Completa con respaldo si la API trae menos de 7 eventos
		local i = 1
		while #fresh < MAX_EVENTS and FALLBACK[i] do
			table.insert(fresh, FALLBACK[i])
			i += 1
		end
		events = fresh
		print(string.format("[DONKI] %d eventos cargados desde la API", #fresh))
	else
		events = table.clone(FALLBACK)
		warn("[DONKI] Usando tabla de respaldo (lÃ­mite de API o sin eventos)")
	end
	if index > #events then index = 1 end
	renderEvent()
	renderCountdown()
end

-- Primera pintura inmediata con respaldo, luego intenta la API
renderEvent()
renderCountdown()
renderClock()
task.spawn(refresh)

-- Reloj UTC
task.spawn(function()
	while true do
		renderClock()
		task.wait(1)
	end
end)

-- RotaciÃ³n automÃ¡tica cada 15 s + refresco periÃ³dico de la API
local sinceRefresh = 0
while true do
	task.wait(1)
	countdown -= 1
	sinceRefresh += 1
	if countdown <= 0 then
		countdown = ROTATION_SECONDS
		index = index % math.max(#events, 1) + 1
		renderEvent()
	end
	renderCountdown()
	if sinceRefresh >= REFRESH_SECONDS then
		sinceRefresh = 0
		task.spawn(refresh)
	end
end
