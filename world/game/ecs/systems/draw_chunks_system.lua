local ECS = require 'libs.ecs'

---@class DrawChunksSystem:ECSSystem
local System = ECS.system()
System.name = "DrawChunksSystem"

function System:update(dt)
	game.draw_chunks()
	local p = self.world.game_world.game.level_creator.player.position
	for x = 0, 0 do
		for z = 0, 0 do
			local dx = x * 16
			local dz = z * 16
			if (self.world.game_world.storage.debug:draw_chunk_frustum_is()) then
				game.draw_chunks_debug_frustum(p.x + dx, p.y, p.z + dz)
			end

			if (self.world.game_world.storage.debug:draw_chunk_borders_is()) then
				game.draw_chunks_debug_borders(p.x + dx, p.y, p.z + dz)
			end

			if (self.world.game_world.storage.debug:draw_chunk_vertices_is()) then
				game.draw_chunks_debug_vertices(p.x + dx, p.y, p.z + dz)
			end
		end
	end


end

return System