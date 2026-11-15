local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local catalog = require(ReplicatedStorage:WaitForChild("RocketConsole"):WaitForChild("ComponentCatalog"))
local board = Workspace:WaitForChild("Resultados de mision")
local screen = board:WaitForChild("NASAScreenGui")
local display = screen:WaitForChild("DataDisplay")
screen.CanvasSize = Vector2.new(1200, 700)
display.Position = UDim2.fromOffset(24, 24)
display.Size = UDim2.new(1, -48, 1, -48)

local PLANET_NAMES_EN = {
	Luna = "Moon",
	Marte = "Mars",
	Venus = "Venus",
	Mercurio = "Mercury",
	["JÃºpiter"] = "Jupiter",
	Saturno = "Saturn",
	Urano = "Uranus",
	Neptuno = "Neptune",
}

local THRESHOLDS = {
	Luna = { Thrust = 15, Power = 0, Fuel = 1000, Heat = 30, Reliability = 70 },
	Marte = { Thrust = 60, Power = 0, Fuel = 4000, Heat = 45, Reliability = 75 },
	Venus = { Thrust = 70, Power = 500, Fuel = 5000, Heat = 80, Reliability = 78 },
	Mercurio = { Thrust = 100, Power = 1500, Fuel = 8000, Heat = 85, Reliability = 80 },
	["JÃºpiter"] = { Thrust = 140, Power = 3000, Fuel = 12000, Heat = 82, Reliability = 82 },
	Saturno = { Thrust = 170, Power = 4000, Fuel = 16000, Heat = 86, Reliability = 84 },
	Urano = { Thrust = 190, Power = 5000, Fuel = 19000, Heat = 89, Reliability = 86 },
	Neptuno = { Thrust = 230, Power = 7000, Fuel = 23000, Heat = 92, Reliability = 88 },
}

local function calculateMetrics(componentIds)
	local metrics = {
		Cost = 0,
		Power = 0,
		Mass = 0,
		Fuel = 0,
		Thrust = 0,
		Efficiency = 0,
		Heat = 0,
		Reliability = 0,
	}
	local count = 0

	for _, id in ipairs(componentIds) do
		local component = catalog.GetById(id)
		if component then
			count += 1
			metrics.Cost += component.Cost
			metrics.Power += component.Power
			metrics.Mass += component.Mass
			metrics.Fuel += component.Fuel
			metrics.Thrust += component.Thrust or 0
			metrics.Efficiency += component.Efficiency or 0
			metrics.Heat = math.max(metrics.Heat, component.HeatResistance or 0)
			metrics.Reliability += component.Reliability or 0
		end
	end

	if count > 0 then
		metrics.Efficiency = math.floor(metrics.Efficiency / count + 0.5)
		metrics.Reliability = math.floor(metrics.Reliability / count + 0.5)
	end
	return metrics, count
end

local function formatRequirement(label, value, minimum, unit)
	if value >= minimum then
		return string.format("  OK  %s: %d%s / %d%s", label, value, unit, minimum, unit)
	end
	return string.format("  FAIL %s: %d%s / %d%s", label, value, unit, minimum, unit)
end

local function publish(launchRecord)
	local mission = launchRecord.Mission
	local planetName = PLANET_NAMES_EN[mission] or mission
	local threshold = THRESHOLDS[mission] or THRESHOLDS.Luna
	local metrics, componentCount = calculateMetrics(launchRecord.Components)
	local checks = {
		{ Label = "THRUST", Value = metrics.Thrust, Minimum = threshold.Thrust, Unit = " kN" },
		{ Label = "POWER", Value = metrics.Power, Minimum = threshold.Power, Unit = " W" },
		{ Label = "FUEL", Value = metrics.Fuel, Minimum = threshold.Fuel, Unit = " kg" },
		{ Label = "HEAT SHIELD", Value = metrics.Heat, Minimum = threshold.Heat, Unit = "/100" },
		{ Label = "RELIABILITY", Value = metrics.Reliability, Minimum = threshold.Reliability, Unit = "/100" },
	}

	local passed = 0
	local good = {}
	local bad = {}
	for _, check in ipairs(checks) do
		if check.Value >= check.Minimum then
			passed += 1
			table.insert(good, formatRequirement(check.Label, check.Value, check.Minimum, check.Unit))
		else
			table.insert(bad, formatRequirement(check.Label, check.Value, check.Minimum, check.Unit))
		end
	end

	local success = passed == #checks
	local missionDetails = catalog.GetMissionDetails(mission)
	local lines = {
		"MISSION RESULTS // " .. string.upper(planetName),
		string.rep("=", 42),
		success and "STATUS: SUCCESSFUL MISSION" or "STATUS: MISSION FAILED",
		"OBJECTIVE: " .. (missionDetails and missionDetails.Description or "Mission objective unavailable."),
		"",
		string.format("ROCKET: %d COMPONENTS | SCORE: %d/%d", componentCount, passed, #checks),
		string.format("COST $%d | MASS %d kg | EFFICIENCY %d%%", metrics.Cost, metrics.Mass, metrics.Efficiency),
		"CONFIGURATION: " .. table.concat(launchRecord.Components, ", "),
		"",
		"WHAT WENT WELL:",
		#good > 0 and table.concat(good, "\n") or "  NONE",
		"",
		"WHAT WENT WRONG:",
		#bad > 0 and table.concat(bad, "\n") or "  NONE",
	}

	display.Text = table.concat(lines, "\n")
	display.TextColor3 = success and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(255, 90, 90)
	display.TextSize = 24
	display.Font = Enum.Font.RobotoMono
	display.TextWrapped = true
	display.TextStrokeTransparency = 0.35
	display.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	display.TextXAlignment = Enum.TextXAlignment.Left
	display.TextYAlignment = Enum.TextYAlignment.Top
end

return {
	Publish = publish,
}