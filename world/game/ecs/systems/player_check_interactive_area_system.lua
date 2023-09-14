local ECS = require 'libs.ecs'

---@class PlayerCheckInteractiveAreaSystem:ECSSystem
local System = ECS.system()
System.filter = ECS.filter("interact_aabb")
System.name = "PlayerCheckInteractiveAreaSystem"

function System:init()

end

function System:update(dt)
	local player = self.world.game_world.game.level_creator.player
	local pos = player.position

	local result = nil
	local entities = self.entities
	for i = 1, #entities do
		local e = entities[i]
		local aabb = e.interact_aabb
		if (pos.x >= aabb[1] and pos.x <= aabb[4] and
				pos.y >= aabb[2]-0.01 and pos.y <= aabb[5] and
				pos.z >= aabb[3] and pos.z < aabb[6])
		then
			result = e
			break
		end
	end
	self.world.game_world.game:player_set_current_interact_aabb(result)

end

return System