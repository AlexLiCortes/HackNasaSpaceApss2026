local HttpService = game:GetService("HttpService")

local AIModule = {}

local API_KEY = "AQ.Ab8RN6Knka-gJXBK6El_EnHyXbdWL5IWn4CuVINfWrY7cwBF3A" -- Pega aquÃ­ tu clave
local MODEL_NAME = "gemini-3.8-flash"
local URL = "https://generativelanguage.googleapis.com/v1beta/models/" .. MODEL_NAME .. ":generateContent?key=" .. API_KEY

function AIModule.Preguntar(promptTexto)
	local cuerpoSolicitud = {
		contents = {
			{
				parts = {
					{ text = promptTexto }
				}
			}
		}
	}

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = URL,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode(cuerpoSolicitud)
		})
	end)

	if success and response.Success then
		local datos = HttpService:JSONDecode(response.Body)
		if datos.candidates and datos.candidates[1] then
			return datos.candidates[1].content.parts[1].text
		end
	else
		warn("Error en AIModule:", response)
	end

	return nil
end

return AIModule