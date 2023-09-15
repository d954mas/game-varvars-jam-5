local ECS = require 'libs.ecs'
local COMMON = require "libs.common"

---@class PlayerFindTargetSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("player")
System.name = "PlayerCatCollectSystem"

---@param e EntityGame
function System:process(e, dt)

	local cats = self.world.game_world.game.level_creator.entities.cats
	for _, cat in ipairs(cats) do
		if not cat.collected and cat.distance_to_player <= e.parameters.cat_collect_radius then
			cat.collected = true
			cat.auto_destroy = true
			self.world:addEntity(cat)
			self.world.game_world.game:cat_collected(cat)
			msg.post(cat.cat_go.collision, COMMON.HASHES.MSG.DISABLE)
			--msg.post(cat.cat_go.sprite, COMMON.HASHES.MSG.DISABLE)

			local ctx = COMMON.CONTEXT:set_context_top_top_panel_gui()
			ctx.data:fly_cat(cat)
			ctx:remove()
		end
	end

end

return System