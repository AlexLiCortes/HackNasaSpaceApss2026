local Config = {}

Config.RemoteName = "TelescopeObservatoryRemote"
Config.ModelName = "NASA_Telescope_Observatory"
Config.TerminalName = "TelescopeTerminal"
Config.ToolNames = {
	Scanner = "HandheldOrbitalScanner",
	CalibrationLens = "CalibrationLens",
}
Config.RequiredDiscoveryFilter = "Infrared"
Config.DiscoveryAttribute = "ExoplanetDiscoveries"
Config.MaximumTerminalDistance = 36
Config.MaximumPickupDistance = 12
Config.ActionCooldownSeconds = 0.35
Config.ScannerHintDurationSeconds = 15
Config.LensCalibrationDurationSeconds = 60
Config.LensAccuracyBonusPercent = 10
Config.CatalogRefreshSeconds = 21600
Config.Filters = {
	Visible = true,
	Infrared = true,
	Ultraviolet = true,
	["X-Ray"] = true,
}

return Config
