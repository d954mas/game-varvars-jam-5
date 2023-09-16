local ECS = require 'libs.ecs'

---@class EnemyPathfindingSystem:ECSSystem
local System = ECS.system()
System.filter = ECS.filter("cat")
System.name = "CatPathfindingSystem"

function System:init()
	self.target_cell = vmath.vector3()
	self.e_cell = vmath.vector3()
end

function System:update(dt)
	local entities = self.entities
	for i=1,#entities do
		self:process(entities[i],dt)
	end
end

---@param e EntityGame
function System:process(e, dt)
	if (not e.ai.target) then
		if not e.path_to_target.cells then e.path_to_target.cells = {} end
		local cells = e.path_to_target.cells
		for i = 1, #cells do cells[i] = nil end
		return
	end

	self.target = e.ai.target
	self.target_cell.x = math.floor(self.target.position.x)
	self.target_cell.z = math.floor(self.target.position.z)

	self.e_cell.x = math.floor(e.position.x)
	self.e_cell.z = math.floor(e.position.z)

	--same cells path already find
	if e.path_to_target.target_cell.x == self.target_cell.x and e.path_to_target.target_cell.z == self.target_cell.z
			and e.path_to_target.start_cell.x == self.e_cell.x and e.path_to_target.start_cell.z == self.e_cell.z then
			return
	end
	e.path_to_target.target_cell.x = self.target_cell.x
	e.path_to_target.target_cell.z = self.target_cell.z
	e.path_to_target.start_cell.x = self.e_cell.x
	e.path_to_target.start_cell.z = self.e_cell.z

	local dist = vmath.length(self.target_cell, self.e_cell)
	if (dist == 0) then
		e.path_to_target.cells = { vmath.vector3(e.path_to_target.target_cell) }
	elseif (dist <= 1) then
		e.path_to_target.cells = { vmath.vector3(e.path_to_target.start_cell) }
		e.path_to_target.cells = { vmath.vector3(e.path_to_target.target_cell) }
	else
		--print(("find path:(%d %d)->(%d %d)"):format(self.e_cell.x, self.e_cell.z, self.target_cell.x, self.target_cell.z))
		e.path_to_target.cells = game.pathfinding_find_path(self.e_cell.x, self.e_cell.z, self.target_cell.x, self.target_cell.z)
		if not e.path_to_target.cells then e.path_to_target.cells = {} end
		--pprint(e.path_to_target.cells)
	end


end

return System