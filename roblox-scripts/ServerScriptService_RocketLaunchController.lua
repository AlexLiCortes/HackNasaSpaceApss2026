local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local missionState = require(ServerScriptService:WaitForChild("RocketMissionState"))
local missionResults = require(ServerScriptService:WaitForChild("MissionResultsService"))

local boton = Workspace:WaitForChild("Boton de lanzamineto")
local cohete = Workspace:WaitForChild("Aster Vertical Integration Facility"):WaitForChild("Cohete_espacial")
local clickDetector = boton:FindFirstChildWhichIsA("ClickDetector", true)

if not clickDetector then
	error("No se encontrÃ³ ClickDetector en el botÃ³n de lanzamiento")
end

local cuerpo = cohete:FindFirstChildWhichIsA("BasePart", true)
if not cuerpo then
	error("No se encontrÃ³ una pieza fÃ­sica en Cohete_espacial")
end

local lanzado = false
local DISTANCIA_LANZAMIENTO = 220
local DURACION_LANZAMIENTO = 8
local TIEMPO_ESPERA_RETORNO = 15
local DURACION_RETORNO = 4

local function crearEfectos()
	local attachment = cuerpo:FindFirstChild("LaunchEffects")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "LaunchEffects"
		attachment.Position = Vector3.new(0, -cuerpo.Size.Y / 2, 0)
		attachment.Parent = cuerpo
	end

	local fuego = attachment:FindFirstChild("LaunchFire")
	if not fuego then
		fuego = Instance.new("ParticleEmitter")
		fuego.Name = "LaunchFire"
		fuego.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 80, 20))
		fuego.LightEmission = 1
		fuego.Lifetime = NumberRange.new(0.25, 0.45)
		fuego.Rate = 180
		fuego.Speed = NumberRange.new(25, 45)
		fuego.SpreadAngle = Vector2.new(12, 12)
		fuego.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 5),
			NumberSequenceKeypoint.new(1, 0),
		})
		fuego.Parent = attachment
	end

	local humo = attachment:FindFirstChild("LaunchSmoke")
	if not humo then
		humo = Instance.new("ParticleEmitter")
		humo.Name = "LaunchSmoke"
		humo.Color = ColorSequence.new(Color3.fromRGB(110, 110, 110), Color3.fromRGB(35, 35, 35))
		humo.Lifetime = NumberRange.new(1.2, 2)
		humo.Rate = 80
		humo.Speed = NumberRange.new(8, 18)
		humo.SpreadAngle = Vector2.new(25, 25)
		humo.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 8),
			NumberSequenceKeypoint.new(1, 18),
		})
		humo.Parent = attachment
	end

	fuego.Enabled = true
	humo.Enabled = true
end

local function devolverCohete(posicionInicial)
	local attachment = cuerpo:FindFirstChild("LaunchEffects")
	if attachment then
		for _, efecto in ipairs(attachment:GetChildren()) do
			if efecto:IsA("ParticleEmitter") then
				efecto.Enabled = false
			end
		end
	end

	local pivotAnimado = Instance.new("CFrameValue")
	pivotAnimado.Value = cohete:GetPivot()
	pivotAnimado:GetPropertyChangedSignal("Value"):Connect(function()
		cohete:PivotTo(pivotAnimado.Value)
	end)

	local tween = TweenService:Create(
		pivotAnimado,
		TweenInfo.new(DURACION_RETORNO, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Value = posicionInicial}
	)
	tween.Completed:Connect(function()
		cohete:PivotTo(posicionInicial)
		pivotAnimado:Destroy()
		lanzado = false
		clickDetector.MaxActivationDistance = 32
	end)
	tween:Play()
end

local function lanzarCohete(player)
	if lanzado then return end

	local launchRecord = missionState.ConsumeForLaunch(player)
	if not launchRecord then
		warn("Rocket launch rejected: the player must arm a rocket first")
		return
	end

	lanzado = true
	clickDetector.MaxActivationDistance = 0
	cohete:SetAttribute("LaunchMission", launchRecord.Mission)
	cohete:SetAttribute("LaunchConfiguration", table.concat(launchRecord.Components, ","))
	cohete:SetAttribute("LaunchTimestamp", launchRecord.LaunchedAt)
	cohete:SetAttribute("LaunchPlayerUserId", player.UserId)
	crearEfectos()

	local posicionInicial = cohete:GetPivot()
	local posicionFinal = posicionInicial + Vector3.new(0, DISTANCIA_LANZAMIENTO, 0)
	local pivotAnimado = Instance.new("CFrameValue")
	pivotAnimado.Value = posicionInicial
	pivotAnimado:GetPropertyChangedSignal("Value"):Connect(function()
		cohete:PivotTo(pivotAnimado.Value)
	end)

	local tween = TweenService:Create(
		pivotAnimado,
		TweenInfo.new(DURACION_LANZAMIENTO, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Value = posicionFinal}
	)
	tween.Completed:Connect(function()
		pivotAnimado:Destroy()
		missionResults.Publish(launchRecord)
		task.delay(TIEMPO_ESPERA_RETORNO, function()
			devolverCohete(posicionInicial)
		end)
	end)
	tween:Play()
end

clickDetector.MouseClick:Connect(lanzarCohete)
