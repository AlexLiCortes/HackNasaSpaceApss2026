local prompt = script.Parent:FindFirstChildOfClass("ProximityPrompt")
local replicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = replicatedStorage:WaitForChild("AbrirMenuMisiones")

if not prompt then
	warn("No se encontrÃ³ el ProximityPrompt en", script.Parent:GetFullName())
	return
end

-- AquÃ­ es donde va la lÃ­nea que mencionas, cerrada correctamente con su 'end'
prompt.Triggered:Connect(function(player)
	remoteEvent:FireClient(player)
end)