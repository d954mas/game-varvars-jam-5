local reszip = require "liveupdate_reszip.reszip"

local ZIP_FILENAME = sys.get_config_string("liveupdate_reszip.filename")

-- HTML5: use relative path to load the .zip from the game directory
-- Other platforms: load .zip from your remote server.
local ZIP_FILE_LOCATION = (html5 and ZIP_FILENAME) or ("http://localhost:8080/" .. ZIP_FILENAME)

local M = {}

function M.load_proxy(proxy_url, cb)
	local missing_resources = collectionproxy.missing_resources(proxy_url)
	if next(missing_resources) ~= nil then
		print("Load proxy:" .. proxy_url)
		print("Resources are missing, downloading...")
		-- TIP: You can pass the "missing_resources" table instead of "nil" to load only missing resources.
		reszip.request_and_load_zip(ZIP_FILE_LOCATION, nil, function(self, err)
			if not err then
				-- All resources are loaded, finally load the level:
				print("load location done:" .. proxy_url)
				cb(true)
				reszip.clear_cache()
			else
				print("ERROR: " .. err)
				cb(false)
			end
		end)
	else
		print("already loaded")
		cb(true)
	end
end

return M