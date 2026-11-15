local State = {}

local armedByPlayer = {}
local lastLaunchByPlayer = {}

function State.Arm(player, componentIds, mission)
	local snapshot = table.clone(componentIds)
	armedByPlayer[player] = {
		Components = snapshot,
		Mission = mission or "",
		ArmedAt = os.time(),
	}
	player:SetAttribute("RocketArmed", true)
	player:SetAttribute("ArmedMission", mission or "")
	player:SetAttribute("ArmedComponentCount", #snapshot)
end

function State.ConsumeForLaunch(player)
	local armed = armedByPlayer[player]
	if not armed then
		return nil
	end

	local launchRecord = {
		Components = table.clone(armed.Components),
		Mission = armed.Mission,
		ArmedAt = armed.ArmedAt,
		LaunchedAt = os.time(),
	}
	lastLaunchByPlayer[player] = launchRecord
	armedByPlayer[player] = nil

	player:SetAttribute("RocketArmed", false)
	player:SetAttribute("LastLaunchMission", launchRecord.Mission)
	player:SetAttribute("LastLaunchComponentCount", #launchRecord.Components)
	player:SetAttribute("LastLaunchTimestamp", launchRecord.LaunchedAt)
	player:SetAttribute("LastLaunchConfiguration", table.concat(launchRecord.Components, ","))

	return launchRecord
end

function State.GetLastLaunch(player)
	return lastLaunchByPlayer[player]
end

function State.Clear(player)
	armedByPlayer[player] = nil
	lastLaunchByPlayer[player] = nil
end

return State