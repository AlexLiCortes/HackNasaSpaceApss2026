--[[
	MisionServerHandler - Autoridad sobre la misiÃ³n activa
	Escucha SetMisionEvent y actualiza MisionActivaPlaneta en ReplicatedStorage.
	Solo acepta nombres de planetas vÃ¡lidos o "" para abortar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local setMisionEvent = ReplicatedStorage:WaitForChild("SetMisionEvent")
local misionActiva = ReplicatedStorage:WaitForChild("MisionActivaPlaneta")

-- Planetas vÃ¡lidos (segÃºn la base de datos oficial)
local PLANETAS_VALIDOS = {
	Luna = true,
	Marte = true,
	Venus = true,
	Mercurio = true,
	["JÃºpiter"] = true,
	Saturno = true,
	Urano = true,
	Neptuno = true,
}

setMisionEvent.OnServerEvent:Connect(function(player, nombrePlaneta)
	-- Validar: cadena vacÃ­a (abortar) o nombre de planeta vÃ¡lido
	if nombrePlaneta == "" then
		misionActiva.Value = ""
	elseif typeof(nombrePlaneta) == "string" and PLANETAS_VALIDOS[nombrePlaneta] then
		misionActiva.Value = nombrePlaneta
	end
end)