local ECS = require 'libs.ecs'
local UTILS = require "libs_project.utils"

local COLOR_PATH = vmath.vector4(0, 0, 1, 1)
---@class DrawDebugEnemyPathSystem:ECSSystemProcessing
local System = ECS.processingSystem()
System.filter = ECS.filter("enemy")
System.name = "DrawDebugEnemyPathSystem"

function System:init()

end

---@param e EntityGame
function System:process(e, dt)
	if not self.world.game_world.storage.debug:draw_path_is() then return end
	if not e.path_to_target.cells then return end
	local prev_cell = e.path_to_target.cells[1]
	for i = 2, #e.path_to_target.cells do
		local cell = e.path_to_target.cells[i]
		UTILS.draw_line(prev_cell.x + 0.5, 66, prev_cell.z + 0.5,
				cell.x + 0.5, 66, cell.z + 0.5, COLOR_PATH)

		prev_cell = cell
	end

end

return System