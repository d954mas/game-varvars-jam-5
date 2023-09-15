local ECS = require 'libs.ecs'
local UTILS = require "libs_project.utils"

local COLOR_BLOCKED = vmath.vector4(1, 0, 0, 1)
local COLOR_NOT_BLOCKED = vmath.vector4(0, 1, 0, 1)
---@class DrawDebugPathCellSystem:ECSSystemProcessing
local System = ECS.system()
System.name = "DrawDebugPathCellSystem"

function System:init()

end

function System:update(dt)
	if not self.world.game_world.storage.debug:draw_path_cells_is() then return end
	local player = self.world.game_world.game.level_creator.player
	local cell_x = math.floor(player.position.x)
	local cell_z = math.floor(player.position.z)
	local dx = 4
	local dz = 4
	for z = cell_z - dz, cell_z + dz do
		for x = cell_x - dx, cell_x + dx do
			local blocked = game.pathfinding_is_blocked(x, z)
			UTILS.draw_line(x+0.5, 64, z+0.5, x+0.5, 255, z+0.5, blocked and COLOR_BLOCKED or COLOR_NOT_BLOCKED)
		end
	end

end

return System