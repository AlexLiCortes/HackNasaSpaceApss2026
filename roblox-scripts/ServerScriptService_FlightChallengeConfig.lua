return {
	{
		id = "suborbital_hop",
		order = 1,
		title = "SUBORBITAL HOP",
		difficulty = "CADET",
		description = "Reach a controlled high-altitude test flight without exceeding the safety envelope.",
		requirements = {
			minDeltaV = 4500,
			minThrustToWeight = 1.15,
			maxAngleError = 5,
			maxQ = 80000,
		},
	},
	{
		id = "precision_ascent",
		order = 2,
		title = "PRECISION ASCENT",
		difficulty = "FLIGHT ENGINEER",
		description = "Reach the planning velocity while keeping the insertion corridor tight.",
		requirements = {
			minDeltaV = 7000,
			minThrustToWeight = 1.25,
			maxAngleError = 3,
			maxQ = 65000,
		},
	},
	{
		id = "leo_insertion",
		order = 3,
		title = "LEO INSERTION",
		difficulty = "ORBITAL",
		description = "Meet the educational low-orbit target with a stable flight path and acceptable Max Q.",
		requirements = {
			minDeltaV = 9400,
			minThrustToWeight = 1.35,
			maxAngleError = 2,
			maxQ = 50000,
		},
	},
	{
		id = "precision_orbit",
		order = 4,
		title = "PRECISION ORBIT",
		difficulty = "MISSION CONTROL",
		description = "Demonstrate an efficient orbital insertion with very little guidance error.",
		requirements = {
			minDeltaV = 10500,
			minThrustToWeight = 1.45,
			maxAngleError = 1,
			maxQ = 45000,
		},
	},
}
