local ECS = require 'libs.ecs'
local COMMON = require "libs.common"
local TWEEN = require "libs.tween"

---@class InputSystem:ECSSystem
local System = ECS.system()
System.name = "InputSystem"

function System:init()
	self.movement = vmath.vector4(0) --forward/back/left/right
	self.movement_up = vmath.vector4(0) --up/down
end

function System:check_movement_input()
	local hashes = COMMON.HASHES.INPUT
	local PRESSED = COMMON.INPUT.PRESSED_KEYS
	self.movement.x = (PRESSED[hashes.ARROW_UP] or PRESSED[hashes.W]) and 1 or 0
	self.movement.y = (PRESSED[hashes.ARROW_DOWN] or PRESSED[hashes.S]) and 1 or 0
	self.movement.w = (PRESSED[hashes.ARROW_LEFT] or PRESSED[hashes.A]) and 1 or 0
	self.movement.z = (PRESSED[hashes.ARROW_RIGHT] or PRESSED[hashes.D]) and 1 or 0
	self.movement_up.x = PRESSED[hashes.SPACE] and 1 or 0
	self.movement_up.y = PRESSED[hashes.LEFT_SHIFT] and 1 or 0
	if COMMON.INPUT.IGNORE then
		self.movement.x = 0
		self.movement.y = 0
		self.movement.w = 0
		self.movement.z = 0
		self.movement_up.x = 0
		self.movement_up.y = 0
	end
end

function System:update_player_direction()
	self:check_movement_input()
	local player = self.world.game_world.game.level_creator.player
	--[[local ctx = COMMON.CONTEXT:set_context_top_game_gui()
	if (ctx.data.views.virtual_pad_1:is_enabled() and ctx.data.views.virtual_pad_1.touch_idx) then
		player.movement.input.x, player.movement.input.y = ctx.data.views.virtual_pad_1:get_data()
	else--]]
	player.movement.input.x = self.movement.z - self.movement.w --right left
	player.movement.input.y = self.movement_up.x - self.movement_up.y
	player.movement.input.z = self.movement.y - self.movement.x-- forward back


	player.movement.max_speed_limit = 1

	if (COMMON.CONTEXT:exist(COMMON.CONTEXT.NAMES.GAME_GUI)) then
		local ctx = COMMON.CONTEXT:set_context_top_game_gui()
		local pad = ctx.data.views.virtual_pad
		if (pad:is_enabled()) then
			if (pad:visible_is()) then
				if (not pad:is_safe()) then
					player.movement.input.x, player.movement.input.z = pad:get_data()
					player.movement.input.z = -player.movement.input.z
					player.movement.input.y = 0

					local min = 0.2
					local a = vmath.length(player.movement.input)
					player.movement.max_speed_limit = min + (1 - min) * TWEEN.easing.outQuad(a, 0, 1, 1)
				end
			end
		end

		if (ctx.data.views.btn_ghost_down:is_pressed()) then
			player.movement.input.y = player.movement.input.y - 1
		end

		if (ctx.data.views.btn_ghost_up:is_pressed()) then
			player.movement.input.y = player.movement.input.y + 1
		end

		ctx:remove()
	end

	if (player.disabled or self.world.game_world.game.state.block_input) then
		player.movement.input.x = 0
		player.movement.input.y = 0
		player.movement.input.z = 0
	end

	--end
	--ctx:remove()
end

function System:update()
	self:update_player_direction()
end

return System