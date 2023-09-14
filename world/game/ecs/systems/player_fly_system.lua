local COMMON = require "libs.common"
local ECS = require 'libs.ecs'

local TARGET_DIR = vmath.vector3()
local TARGET_V = vmath.vector3()
local QUAT_TEMP = vmath.quat_rotation_z(0)

---@class PlayerFlySystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("player")
System.name = "PlayerFlySystem"

---@param e EntityGame
function System:process(e, dt)
	if (e.ghost_mode) then
		if (e.player_go.config.collision_enabled) then
			e.player_go.config.collision_enabled = false
			msg.post(e.player_go.collision, COMMON.HASHES.MSG.DISABLE)
			game.physics_object_set_update_position(e.physics_object, false)
		end

		if e.movement.input.x ~= 0 or e.movement.input.z ~= 0 then
			e.movement.direction.x = e.movement.input.x * (e.on_ground and e.movement.strafe_power or e.movement.strafe_power_air)
			e.movement.direction.y = -e.movement.input.z
			xmath.normalize(e.movement.direction, e.movement.direction)
		else
			e.movement.direction.x = 0
			e.movement.direction.y = 0
		end
		if(e.movement.direction.x ~=0 or e.movement.direction.y ~= 0)then
			e.look_at_dir.x = e.movement.direction.x
			e.look_at_dir.z = -e.movement.direction.y
		end

		xmath.quat_rotation_z(QUAT_TEMP, math.rad(e.angle))
		xmath.rotate(e.movement.direction, QUAT_TEMP, e.movement.direction)

		TARGET_DIR.x, TARGET_DIR.y, TARGET_DIR.z = e.movement.direction.x, e.movement.input.y, -e.movement.direction.y
		local max_speed = e.movement.max_speed
		xmath.mul(TARGET_V, TARGET_DIR, max_speed)
		xmath.mul(TARGET_V, TARGET_V, dt)
		xmath.add(e.position, e.position, TARGET_V)

		e.movement.velocity.x = 0;
		e.movement.velocity.y = 0;
		e.movement.velocity.z = 0;

		e.moving = (math.abs(e.movement.direction.x) > 0 or math.abs(e.movement.direction.y) > 0)
	else
		if (not e.player_go.config.collision_enabled) then
			e.player_go.config.collision_enabled = true
			msg.post(e.player_go.collision, COMMON.HASHES.MSG.ENABLE)
			game.physics_object_set_update_position(e.physics_object, true)
		end
	end
end

return System