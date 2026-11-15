local ServerScriptService = game:GetService("ServerScriptService")
local AIModule = require(ServerScriptService:WaitForChild("AIModule"))

local respuesta = AIModule.Preguntar("Hola Gemini, dime un saludo corto.")
if respuesta then
	print("ðŸ¤– Respuesta: " .. respuesta)
end