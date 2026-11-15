local prompt = script.Parent:WaitForChild("PromptSatelites")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("AbrirSatelitesEvent")

prompt.Triggered:Connect(function(player)
	remote:FireClient(player)
end)
