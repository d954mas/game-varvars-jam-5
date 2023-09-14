local ECS = require 'libs.ecs'

local TARGET_DIR = vmath.vector3()
local TARGET_V = vmath.vector3()

local QUAT_TEMP = vmath.quat_rotation_z(0)

---@class PlayerMoveSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("player")
System.name = "PlayerMoveSystem"

---@param e EntityGame
function System:ground_movement(e, dt)
	TARGET_DIR.x, TARGET_DIR.y, TARGET_DIR.z = e.movement.direction.x, 0, -e.movement.direction.y
	local max_speed = e.movement.input.z ~= 0 and e.movement.max_speed or e.movement.max_speed * e.movement.strafe_power
	max_speed = max_speed * e.movement.max_speed_limit
	if (vmath.length(TARGET_DIR) > 0) then
		--ignore if normal look up it can be like
		--vmath.vector3(-7.1524499389852e-07, 1, 1.3351240340853e-05) so ignore that
		if (e.ground_normal.y ~= 1) then
			xmath.cross(TARGET_DIR, e.ground_normal, TARGET_DIR)
			xmath.cross(TARGET_DIR, TARGET_DIR, e.ground_normal)
			--if (TARGET_DIR.y > 0) then
			--	TARGET_DIR.y = TARGET_DIR.y * 0.9
			--end
		end
		xmath.normalize(TARGET_DIR, TARGET_DIR)
	end
	xmath.mul(TARGET_V, TARGET_DIR, max_speed)

	local is_accel = vmath.dot(TARGET_V, e.movement.velocity) > 0

	local accel = is_accel and e.movement.accel or e.movement.deaccel
	if (e.movement.direction.x == 0 and e.movement.direction.y == 0) then
		xmath.lerp(e.movement.velocity, e.movement.deaccel_stop, e.physics_linear_velocity, TARGET_V)
		e.movement.velocity.y = 0
	else
		local current_speed = vmath.length(e.physics_linear_velocity)
		local a = current_speed / max_speed
		if a < 0.5 then
			xmath.lerp(e.movement.velocity, accel, e.physics_linear_velocity, TARGET_V)
		else
			xmath.lerp(e.movement.velocity, accel, e.physics_linear_velocity, TARGET_V)

		end
	end


	--	e.movement.velocity = vmath.lerp(accel, e.movement.velocity, target)
	if (vmath.length(e.movement.velocity) < 0.001) then
		e.movement.velocity.x = 0
		e.movement.velocity.y = 0
		e.movement.velocity.z = 0
	end
	--if (self.world.game_world.game.state.time - e.jump_last_time > 1) then
	e.physics_linear_velocity.y = e.movement.velocity.y
	--	end
	e.physics_linear_velocity.x = e.movement.velocity.x
	e.physics_linear_velocity.z = e.movement.velocity.z

end

---@param e EntityGame
function System:process(e, dt)
	if (e.ghost_mode) then return end
	--normalize keyboard input
	if e.movement.input.x ~= 0 or e.movement.input.z ~= 0 then
		e.movement.direction.x = e.movement.input.x * (e.on_ground and e.movement.strafe_power or e.movement.strafe_power_air)
		e.movement.direction.y = -e.movement.input.z
		xmath.normalize(e.movement.direction, e.movement.direction)
	else
		e.movement.direction.x = 0
		e.movement.direction.y = 0
	end

	if(e.die)then
		e.movement.direction.x = 0
		e.movement.direction.y = 0
	end

	--if e.angle then
	xmath.quat_rotation_z(QUAT_TEMP, math.rad(e.angle))
	xmath.rotate(e.movement.direction, QUAT_TEMP, e.movement.direction)

	if (e.movement.direction.x ~= 0 or e.movement.direction.y ~= 0) then
		e.look_at_dir.x = e.movement.direction.x
		e.look_at_dir.z = -e.movement.direction.y
	end

	self:ground_movement(e, dt)


	e.moving = (math.abs(e.movement.velocity.x) > 0 or math.abs(e.movement.velocity.z) > 0)
			and (math.abs(e.movement.direction.x) > 0 or math.abs(e.movement.direction.y) > 0)

	if(e.moving)then
		physics.wakeup(e.player_go.collision)
	end

	--[[if (e.on_ground and not e.moving and e.on_ground_time > 1 and not e.in_jump and e.physics_linear_velocity.y < 0.1) then
		go.set(e.player_go.collision, "linear_damping", 1)
	else
		go.set(e.player_go.collision, "linear_damping", 0)
	end--]]

	--	print(e.position)
end

return System