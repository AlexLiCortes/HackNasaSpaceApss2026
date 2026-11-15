--[[
	ComponentCatalog
	CatÃ¡logo compartido de componentes del cohete. Cliente y servidor
	usan este mÃ³dulo como Ãºnica fuente de verdad, por lo que la telemetrÃ­a
	calculada en el cliente siempre coincide con la validada en el servidor.

	Cada componente define:
		Cost  -> costo en $
		Power -> balance de energÃ­a en W (negativo = consumo, positivo = generaciÃ³n)
		Mass  -> masa en kg
		Fuel  -> capacidad de combustible en kg (opcional)
]]

local Catalog = {}

-- CategorÃ­as mostradas como pestaÃ±as en la tablet
Catalog.Categories = {
	{ Id = "hull",    Name = "HULLS",   Short = "CS" },
	{ Id = "engines", Name = "ENGINES",  Short = "MO" },
	{ Id = "power",   Name = "POWER",  Short = "EN" },
	{ Id = "fuel",    Name = "TANKS",  Short = "TN" },
}

-- Componentes disponibles (id Ãºnico por componente)
Catalog.Components = {
	-- CASCOS
	{ Id = "hull_light",     Category = "hull",    Name = "Lightweight Alloy Hull",     Cost = 5000,  Power = -200,  Mass = 800,  Fuel = 0 },
	{ Id = "hull_reinforced", Category = "hull",    Name = "Reinforced Titanium Hull",     Cost = 12000, Power = -350,  Mass = 1500, Fuel = 0 },
	{ Id = "hull_nano",      Category = "hull",    Name = "Carbon Nanotube Hull",           Cost = 25000, Power = -500,  Mass = 1100, Fuel = 0 },

	-- MOTORES
	{ Id = "engine_ion",     Category = "engines", Name = "Ion Propulsion Engine",   Cost = 8000,  Power = -1200, Mass = 400,  Fuel = 0 },
	{ Id = "engine_chem",    Category = "engines", Name = "High-Thrust Chemical Engine", Cost = 15000, Power = -800,  Mass = 900,  Fuel = 0 },
	{ Id = "engine_fusion",  Category = "engines", Name = "Nuclear Fusion Engine",      Cost = 40000, Power = -2500, Mass = 1200, Fuel = 0 },

	-- ENERGÃA / SOLAR
	{ Id = "solar_basic",    Category = "power",   Name = "Rigid Solar Panel",           Cost = 3000,  Power = 1500,  Mass = 200,  Fuel = 0 },
	{ Id = "solar_deploy",  Category = "power",   Name = "Deployable Solar Arrays",  Cost = 7000,  Power = 4000,  Mass = 350,  Fuel = 0 },
	{ Id = "rtg_nuclear",   Category = "power",   Name = "Nuclear RTG Generator",        Cost = 18000, Power = 8000,  Mass = 600,  Fuel = 0 },

	-- TANQUES DE COMBUSTIBLE
	{ Id = "tank_small",     Category = "fuel",    Name = "Small Fuel Tank", Cost = 2000,  Power = -100,  Mass = 500,  Fuel = 2000 },
	{ Id = "tank_medium",    Category = "fuel",    Name = "Medium Fuel Tank",   Cost = 5000,  Power = -150,  Mass = 900,  Fuel = 5000 },
	{ Id = "tank_cryo",      Category = "fuel",    Name = "Cryogenic Fuel Tank",            Cost = 12000, Power = -400,  Mass = 1600, Fuel = 12000 },
	{ Id = "hull_ceramic", Category = "hull", Name = "Ceramic Heatshield Hull", Cost = 32000, Power = -650, Mass = 1900, Fuel = 0, Thrust = 0, Efficiency = 60, HeatResistance = 98, Reliability = 88 },
	{ Id = "hull_deep_space", Category = "hull", Name = "Deep-Space Command Hull", Cost = 48000, Power = -850, Mass = 2300, Fuel = 0, Thrust = 0, Efficiency = 76, HeatResistance = 94, Reliability = 97 },
	{ Id = "engine_methalox", Category = "engines", Name = "Methalox Deep-Space Engine", Cost = 52000, Power = -2200, Mass = 1400, Fuel = 0, Thrust = 190, Efficiency = 81, HeatResistance = 90, Reliability = 89 },
	{ Id = "engine_antimatter", Category = "engines", Name = "Antimatter Torch Engine", Cost = 90000, Power = -5000, Mass = 1600, Fuel = 0, Thrust = 320, Efficiency = 97, HeatResistance = 92, Reliability = 72 },
	{ Id = "power_quantum", Category = "power", Name = "Quantum Battery Core", Cost = 36000, Power = 14000, Mass = 450, Fuel = 0, Thrust = 0, Efficiency = 96, HeatResistance = 78, Reliability = 87 },
	{ Id = "power_antimatter", Category = "power", Name = "Antimatter Reactor", Cost = 75000, Power = 28000, Mass = 900, Fuel = 0, Thrust = 0, Efficiency = 99, HeatResistance = 90, Reliability = 70 },
	{ Id = "tank_large", Category = "fuel", Name = "Long-Range Propellant Tank", Cost = 24000, Power = -700, Mass = 2800, Fuel = 24000, Thrust = 0, Efficiency = 76, HeatResistance = 74, Reliability = 88 },
	{ Id = "tank_antimatter", Category = "fuel", Name = "Antimatter Containment Tank", Cost = 68000, Power = -1200, Mass = 1200, Fuel = 36000, Thrust = 0, Efficiency = 98, HeatResistance = 96, Reliability = 68 },
}

local LEGACY_PROFILES = {
	hull_light = { Thrust = 0, Efficiency = 70, HeatResistance = 35, Reliability = 78 },
	hull_reinforced = { Thrust = 0, Efficiency = 68, HeatResistance = 70, Reliability = 86 },
	hull_nano = { Thrust = 0, Efficiency = 82, HeatResistance = 85, Reliability = 92 },
	engine_ion = { Thrust = 18, Efficiency = 94, HeatResistance = 45, Reliability = 82 },
	engine_chem = { Thrust = 78, Efficiency = 62, HeatResistance = 72, Reliability = 80 },
	engine_fusion = { Thrust = 145, Efficiency = 88, HeatResistance = 86, Reliability = 84 },
	solar_basic = { Thrust = 0, Efficiency = 72, HeatResistance = 40, Reliability = 80 },
	solar_deploy = { Thrust = 0, Efficiency = 84, HeatResistance = 55, Reliability = 78 },
	rtg_nuclear = { Thrust = 0, Efficiency = 91, HeatResistance = 88, Reliability = 94 },
	tank_small = { Thrust = 0, Efficiency = 65, HeatResistance = 35, Reliability = 82 },
	tank_medium = { Thrust = 0, Efficiency = 70, HeatResistance = 48, Reliability = 84 },
	tank_cryo = { Thrust = 0, Efficiency = 82, HeatResistance = 68, Reliability = 86 },
}

for _, component in ipairs(Catalog.Components) do
	local profile = LEGACY_PROFILES[component.Id]
	component.Thrust = component.Thrust or (profile and profile.Thrust) or 0
	component.Efficiency = component.Efficiency or (profile and profile.Efficiency) or 0
	component.HeatResistance = component.HeatResistance or (profile and profile.HeatResistance) or 0
	component.Reliability = component.Reliability or (profile and profile.Reliability) or 0
end

-- Mission descriptions shown in the mission details window.
Catalog.Missions = {
	Luna = {
		Description = "Complete a low-orbit systems test and return with the spacecraft fully operational.",
	},
	Marte = {
		Description = "Deliver a remote science package, survive a long-duration flight, and return safely.",
	},
	Venus = {
		Description = "Enter a corrosive, high-temperature atmosphere and transmit readings before extraction.",
	},
	Mercurio = {
		Description = "Perform a precision survey through extreme thermal cycles with limited communication windows.",
	},
	["JÃºpiter"] = {
		Description = "Probe the upper atmosphere, withstand intense radiation, and escape before systems fail.",
	},
	Saturno = {
		Description = "Navigate the ring system, map a target moon, and complete the return burn with no margin for error.",
	},
	Urano = {
		Description = "Cross the outer-system darkness, stabilize the spacecraft during a long blackout, and recover the probe.",
	},
	Neptuno = {
		Description = "Reach the system frontier, survive violent storms, transmit critical data, and return against the clock.",
	},
}

-- Ãndice rÃ¡pido por id (se construye una sola vez al requerir el mÃ³dulo)
local byId = {}
for _, component in ipairs(Catalog.Components) do
	byId[component.Id] = component
end

-- Devuelve el componente con el id dado, o nil si no existe
function Catalog.GetById(id)
	return byId[id]
end

function Catalog.GetMissionDetails(planet)
	return Catalog.Missions[planet]
end

-- Devuelve los componentes de una categorÃ­a, en orden de catÃ¡logo
function Catalog.GetByCategory(categoryId)
	local result = {}
	for _, component in ipairs(Catalog.Components) do
		if component.Category == categoryId then
			table.insert(result, component)
		end
	end
	return result
end

-- Calcula la telemetrÃ­a total de una lista de ids seleccionados
function Catalog.ComputeTelemetry(selectedIds)
	local telemetry = { Cost = 0, Power = 0, Mass = 0, Fuel = 0 }
	for _, id in ipairs(selectedIds) do
		local component = byId[id]
		if component then
			telemetry.Cost += component.Cost
			telemetry.Power += component.Power
			telemetry.Mass += component.Mass
			telemetry.Fuel += component.Fuel
		end
	end
	return telemetry
end

return Catalog