            local prompt = script.Parent:FindFirstChildOfClass("ProximityPrompt")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local openGuiEvent = ReplicatedStorage:WaitForChild("OpenGuiEvent")

            prompt.Triggered:Connect(function(player)
                print("Prompt activado por: " .. player.Name)
                openGuiEvent:FireClient(player)
            end)
        