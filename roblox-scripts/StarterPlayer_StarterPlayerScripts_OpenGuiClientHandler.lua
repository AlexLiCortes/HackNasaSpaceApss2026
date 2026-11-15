        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local openMisionesEvent = ReplicatedStorage:WaitForChild("OpenGuiEvent")
        local player = game:GetService("Players").LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")
        local gui = playerGui:WaitForChild("MisionesEspacialesGui")

        openMisionesEvent.OnClientEvent:Connect(function()
            if gui then
                gui.Enabled = true
            end
        end)
    