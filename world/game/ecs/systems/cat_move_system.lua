local ECS = require 'libs.ecs'

local TARGET_DIR = vmath.vector3()
local TARGET_V = vmath.vector3()
local RAY_START = vmath.vector3()
local RAY_END = vmath.vector3()
local DIST_V = vmath.vector3()

---@class EnemyMoveSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("cat")
System.name = "CatMoveSystem"

function System:init()
	self.obstacle_raycast_groups = {
		hash("obstacle")
	}
	self.obstacle_raycast_mask = game.physics_count_mask(self.obstacle_raycast_groups)
end

---@param e EntityGame
function System:ground_movement(e, dt, max_distance_move)
	TARGET_DIR.x, TARGET_DIR.y, TARGET_DIR.z = e.movement.direction.x, 0, -e.movement.direction.y
	local max_speed = e.movement.max_speed
	if (TARGET_DIR.x ~= 0 or TARGET_DIR.y ~= 0) then
		xmath.normalize(TARGET_DIR, TARGET_DIR)
	end
	xmath.mul(TARGET_V, TARGET_DIR, max_speed)

	if (e.movement.direction.x == 0 and e.movement.direction.y == 0) then
		xmath.lerp(e.movement.velocity, e.movement.deaccel_stop, e.physics_linear_velocity, TARGET_V)
		e.movement.velocity.y = 0
	else
		local is_accel = vmath.dot(TARGET_V, e.movement.velocity) > 0
		local accel = is_accel and e.movement.accel or e.movement.deaccel
		xmath.lerp(e.movement.velocity, accel, e.physics_linear_velocity, TARGET_V)
	end

	local vel_len = vmath.length(e.movement.velocity) * dt
	if (max_distance_move and max_distance_move < vel_len) then
		xmath.mul(e.movement.velocity, e.movement.velocity, max_distance_move / vel_len)
		e.ai.target = nil
	end

	--	e.movement.velocity = vmath.lerp(accel, e.movement.velocity, target)
	if (vmath.length(e.movement.velocity) < 0.001) then
		e.movement.velocity.x = 0
		e.movement.velocity.y = 0
		e.movement.velocity.z = 0
	else
		physics.wakeup(e.cat_go.collision)
	end
	e.physics_linear_velocity.y = e.movement.velocity.y
	--	end
	e.physics_linear_velocity.x = e.movement.velocity.x
	e.physics_linear_velocity.z = e.movement.velocity.z

end

---@param e EntityGame
function System:process(e, dt)
	--normalize keyboard input
	if not e.run_away then
		e.movement.direction.x = 0
		e.movement.direction.y = 0
	end
	pprint(e.movement.direction)
	local max_distance_move

	if (e.ai.target) then
		RAY_START.x = e.position.x
		RAY_START.y = 65.25
		RAY_START.z = e.position.z

		RAY_END.x = e.ai.target.position.x
		RAY_END.y = 65.25
		RAY_END.z = e.ai.target.position.z

		xmath.sub(e.movement.direction, RAY_END, RAY_START)
		e.movement.direction.y = -e.movement.direction.z
		e.movement.direction.z = 0

		if (e.path_to_target.cells) then
			if #e.path_to_target.cells > 1 then
				local have_obstacles = game.physics_raycast_single_exist(RAY_START, RAY_END, self.obstacle_raycast_mask)
				if (have_obstacles) then
					local current_cell = e.path_to_target.cells[1]
					local next_cell = e.path_to_target.cells[2]
					e.movement.direction.x = next_cell.x - current_cell.x
					e.movement.direction.y = -(next_cell.z - current_cell.z)
					if #e.path_to_target.cells <= 2 then
						e.ai.target = nil
					end
				end
			else
				e.ai.target = nil
			end
		end

		xmath.sub(DIST_V, RAY_END, RAY_START)
		max_distance_move = vmath.length(DIST_V)
	end

	if (e.die) then
		e.movement.direction.x = 0
		e.movement.direction.y = 0
	end


	--check movement only if player have velocity(moving) or need to move
	if (e.moving or e.movement.direction.x ~= 0 or e.movement.direction.y) then
		self:ground_movement(e, dt, max_distance_move)
	end

	e.moving = (math.abs(e.movement.velocity.x) > 0 or math.abs(e.movement.velocity.z) > 0)
			and (math.abs(e.movement.direction.x) > 0 or math.abs(e.movement.direction.y) > 0)
end

return System