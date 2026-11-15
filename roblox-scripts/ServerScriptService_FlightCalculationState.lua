local FlightCalculationState = {}

local records = {}

function FlightCalculationState.Set(player, inputs, result)
	records[player] = {
		inputs = table.clone(inputs),
		result = result,
		createdAt = os.clock(),
	}
end

function FlightCalculationState.Get(player)
	return records[player]
end

function FlightCalculationState.Clear(player)
	records[player] = nil
end

return FlightCalculationState
