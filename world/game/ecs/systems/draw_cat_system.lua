local COMMON = require "libs.common"
local ECS = require 'libs.ecs'
local ENUMS = require 'world.enums.enums'
local DEFS = require "world.balance.def.defs"

local TEMP_V = vmath.vector3(0)
local TEMP_Q = vmath.quat_rotation_z(0)
local QUAT_ROTATION = vmath.quat_rotation_z(0)



---@class DrawCatSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("cat")
System.name = "DrawCatSystem"

---@param e EntityGame
function System:get_animation(e)
	if (e.moving) then
		return ENUMS.ANIMATIONS.RUN
	end
	return ENUMS.ANIMATIONS.IDLE
end

---@param e EntityGame
function System:onAdd(e)

end

---@param e EntityGame
function System:update_walk_animation(e, dt)
	local sp = 15
	e.cat_go.config.animation_time = e.cat_go.config.animation_time + dt
	local amp = 0
	if e.moving then amp = 0.06 end
	local tmp = math.cos(e.cat_go.config.animation_time * sp) * amp + 1

	TEMP_V.x = tmp
	TEMP_V.y = 1 / tmp
	TEMP_V.z = 1
	go.set_scale(TEMP_V, e.cat_go.sprite.root)

	if e.moving then
		tmp = math.cos(e.cat_go.config.animation_time * sp*1.25) * 0.15
		xmath.quat_rotation_z(TEMP_Q, tmp)
		go.set_rotation(self.world.game_world.game.level_creator.player.camera.rotation*TEMP_Q, e.cat_go.sprite.root)
	else
		go.set_rotation(self.world.game_world.game.level_creator.player.camera.rotation, e.cat_go.sprite.root)
	end


	--[[UTILS.draw_line(e.position.x, e.position.y, 0, e.position.x + 16, e.position.y + 35, 0, vmath.vector4(1, 0, 0, 1))
	UTILS.draw_line(e.position.x, e.position.y, 0, e.position.x + e.cat_go.config.stack_dpos_right.x,
			e.position.y + e.cat_go.config.stack_dpos_right.y, 0, vmath.vector4(0, 1, 0, 1))
	UTILS.draw_line(e.position.x, e.position.y, 0, e.position.x + e.cat_go.config.stack_dpos_left.x,
			e.position.y + e.cat_go.config.stack_dpos_left.y, 0, vmath.vector4(0, 0, 1, 1))--]]

end

---@param e EntityGame
function System:process(e, dt)

	local anim = self:get_animation(e)

	self:update_walk_animation(e, dt)


	--go.set_rotation(self.world.game_world.game.level_creator.player.camera.rotation,e.cat_go.sprite.root)

	--go.set_position(e.position, e.player_go.root)

end

return System