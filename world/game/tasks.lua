local COMMON = require "libs.common"
local DEFS = require "world.balance.def.defs"


local Tasks = COMMON.class("Tasks")

---@param world World
function Tasks:initialize(world)
	self.world = assert(world)
end

function Tasks:add_resource(resource, value)
	local def = DEFS.TASKS.TASKS_BY_ID[self.world.storage.task:get_id()]
	if (def.type == DEFS.TASKS.TYPE.COLLECT_RESOURCES and def.resource == resource) then
		self.world.storage.task:add_value(value)
	end
end

---@param e EntityGame
function Tasks:kill_enemy(e)
	local def = DEFS.TASKS.TASKS_BY_ID[self.world.storage.task:get_id()]
	if (def.type == DEFS.TASKS.TYPE.KILL_ENEMY and (def.enemy_any or def.enemy_id == e.enemy_id)) then
		self.world.storage.task:add_value(1)
	end
end

return Tasks