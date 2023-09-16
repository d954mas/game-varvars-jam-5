local COMMON = require "libs.common"

---@class Balance
local Balance = COMMON.class("Balance")

---@param world World
function Balance:initialize(world)
	self.world = world
	self.config = {
		frustum_default_distance = -1,

		far_z_base = 150,
		far_z_small = 50,
		lerp_direction_a = 0.2
	}
end

return Balance