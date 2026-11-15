local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = ReplicatedStorage:WaitForChild("ConfirmarMisionEvent")

remoteEvent.OnServerEvent:Connect(function(player, planeta, dificultad, costo)
    print(player.Name .. " ha seleccionado la misiÃ³n a: " .. planeta)
    
    -- Guardar en atributos del jugador
    player:SetAttribute("MisionSeleccionada", planeta)
    player:SetAttribute("DificultadMision", dificultad)
    player:SetAttribute("CostoMision", costo)
end)
