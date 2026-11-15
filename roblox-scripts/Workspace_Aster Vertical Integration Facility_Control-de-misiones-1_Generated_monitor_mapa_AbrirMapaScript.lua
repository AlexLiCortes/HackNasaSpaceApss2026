local prompt = script.Parent:WaitForChild("PromptMapa")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local abrirMapaEvent = ReplicatedStorage:WaitForChild("AbrirMapaEvent")

prompt.Triggered:Connect(function(player)
	abrirMapaEvent:FireClient(player)
end)
