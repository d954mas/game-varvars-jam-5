
local V3 = vmath.vector3

local M = {}

M.BY_ID = {
	HUB = {
		level = "hub",
		player_spawn = V3(0, 65, 0),

		entities = {},
		spawn_points = {}
	},
}

for k, v in pairs(M.BY_ID) do
	v.id = k
end

return M