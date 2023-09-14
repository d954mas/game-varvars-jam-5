local ECS = require 'libs.ecs'
local COMMON = require "libs.common"


---@class WaterMoveSystem:ECSSystem
local System = ECS.system()
System.name = "WaterMoveSystem"

function System:init()
	self.wm = vmath.vector4(0)
end

---@param e EntityGame
function System:update(dt)
	local dx = dt * 0.1 * 1.5
	local dy = dt  * 0.085 * 1.5
	self.wm.x = self.wm.x +dx
	self.wm.y = self.wm.y + dy
	if(self.wm.x>2)then
		self.wm.x = self.wm.x - 2
	end
	if(self.wm.y>2)then
		self.wm.y = self.wm.y - 2
	end
	COMMON.RENDER.draw_opts.constants.water_move = self.wm
end

return System