local HttpService = game:GetService("HttpService")

local ENDPOINT = "https://exoplanetarchive.ipac.caltech.edu/TAP/sync"
local QUERY = "SELECT pl_name,disc_year,pl_orbper,pl_rade,sy_dist FROM pscomppars WHERE pl_name='Kepler-186 f'"

local snapshot = {
	name = "Kepler-186 f",
	discoveryYear = 2014,
	orbitalPeriodDays = 129.9,
	radiusEarth = 1.17,
	distanceParsecs = 178.5,
	status = "CACHED",
	source = "NASA Exoplanet Archive",
}

local Catalog = {}

local function finiteNumber(value)
	local number = tonumber(value)
	if not number or number ~= number or number == math.huge or number == -math.huge then
		return nil
	end
	return number
end

function Catalog.GetSnapshot()
	return table.clone(snapshot)
end

function Catalog.Refresh()
	local url = ENDPOINT .. "?query=" .. HttpService:UrlEncode(QUERY) .. "&format=json"
	local requestOk, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = { Accept = "application/json" },
		})
	end)
	if not requestOk then
		warn("[TelescopeNasaCatalog] NASA Exoplanet Archive request failed; retaining cached NASA reference data: " .. tostring(response))
		return false
	end
	if not response.Success then
		warn(string.format("[TelescopeNasaCatalog] NASA Exoplanet Archive returned HTTP %d; retaining cached NASA reference data.", response.StatusCode))
		return false
	end

	local decodeOk, rows = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not decodeOk or typeof(rows) ~= "table" or typeof(rows[1]) ~= "table" then
		warn("[TelescopeNasaCatalog] NASA Exoplanet Archive returned an invalid or empty catalog response; retaining cached NASA reference data.")
		return false
	end

	local row = rows[1]
	local discoveryYear = finiteNumber(row.disc_year)
	local orbitalPeriodDays = finiteNumber(row.pl_orbper)
	local radiusEarth = finiteNumber(row.pl_rade)
	local distanceParsecs = finiteNumber(row.sy_dist)
	if typeof(row.pl_name) ~= "string" or row.pl_name == ""
		or not discoveryYear or discoveryYear < 1900
		or not orbitalPeriodDays or orbitalPeriodDays <= 0
		or not radiusEarth or radiusEarth <= 0
		or not distanceParsecs or distanceParsecs <= 0 then
		warn("[TelescopeNasaCatalog] NASA Exoplanet Archive row failed validation; retaining cached NASA reference data.")
		return false
	end

	snapshot = {
		name = row.pl_name,
		discoveryYear = math.floor(discoveryYear),
		orbitalPeriodDays = orbitalPeriodDays,
		radiusEarth = radiusEarth,
		distanceParsecs = distanceParsecs,
		status = "LIVE",
		source = "NASA Exoplanet Archive",
	}
	return true
end

return Catalog