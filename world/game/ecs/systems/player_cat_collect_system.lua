local ECS = require 'libs.ecs'

local RAY_START = vmath.vector3()
local RAY_END = vmath.vector3()

---@class PlayerFindTargetSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("player")
System.name = "PlayerFindTargetSystem"



---@param e EntityGame
function System:process(e, dt)

	local cats = self.world.game_world.game.level_creator.entities.cats
	for _, cat in ipairs(cats) do
		if not cat.collected and cat.distance_to_player<=e.parameters.cat_collect_radius then
			cat.collected = true
			cat.auto_destroy_delay = 0.2
			self.world:addEntity(cat)
			self.world.game_world.game:cat_collected(cat)
		end
	end

end

return System