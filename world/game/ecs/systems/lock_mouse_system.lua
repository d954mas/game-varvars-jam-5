local ECS = require 'libs.ecs'
local COMMON = require "libs.common"
local POINTER = require "libs.pointer_lock"

---@class LockMouseSystem:ECSSystemProcessing
local System = ECS.processingSystem()
System.filter = ECS.filter("input_info")
System.name = "LockMouseSystem"

function System:init()
	self.config = {
		yaw = 0,
		pitch = 0,
	}

	if(COMMON.CONSTANTS.TARGET_IS_EDITOR)then
		self.input_handler = COMMON.INPUT()
		self.input_handler:add_mouse(function(_, _, action)
			self:input_mouse_move(action)
		end)

		self.input_handler:add(COMMON.HASHES.INPUT.TOUCH, function(_, _, action)
			if (action.released and self.world.game_world.game.state.mouse_lock) then
				POINTER.lock_cursor()
			end
		end, true, false, true)

		self.input_handler:add(COMMON.HASHES.INPUT.ESCAPE, function(_, action_id, action)
			POINTER.unlock_cursor()
		end, false, false, true)

		self.input_handler:add(COMMON.HASHES.INPUT.TOUCH_MULTI, function(_, action_id, action)
			self:input_touch_rotation(action)
		end, false, false, false, true)
	end
end

function System:onAddToWorld()
	if(COMMON.CONSTANTS.TARGET_IS_EDITOR)then
		if (self.world.game_world.game.state.mouse_lock) then
			POINTER.lock_cursor()
		end
	end
end

function System:clamp_values()
	local camera = self.world.game_world.game.level_creator.player.camera
	local camera_config = camera.first_person and camera.config_first_person or camera.config
	if self.config.yaw < 0 then
		self.config.yaw = self.config.yaw + 360
	end
	if self.config.yaw >= 360 then
		self.config.yaw = self.config.yaw - 360
	end
	if(camera_config.pitch_portrait and COMMON.RENDER.screen_size.aspect<1)then
		self.config.pitch = COMMON.LUME.clamp(self.config.pitch, camera_config.pitch_portrait.min, camera_config.pitch_portrait.max)
	else
		self.config.pitch = COMMON.LUME.clamp(self.config.pitch, camera_config.pitch.min, camera_config.pitch.max)
	end


end

function System:input_mouse_move(action)
	local player = self.world.game_world.game.level_creator.player
	if (player.disabled or self.world.game_world.game.state.block_input) then return end
	if (not COMMON.is_mobile()) then
		if POINTER.locked then
			local camera= self.world.game_world.game.level_creator.player.camera
			local camera_config = camera.first_person and camera.config_first_person or camera.config

			self.config.yaw = self.config.yaw + (camera_config.yaw.speed * action.dx)
			self.config.pitch = self.config.pitch + (camera_config.pitch.speed * action.dy)
			self:clamp_values()
		end
		self:clamp_values()
	end
end

function System:input_touch_rotation(action)
	local player = self.world.game_world.game.level_creator.player
	if (player.disabled or self.world.game_world.game.state.block_input) then return end
	if (COMMON.is_mobile()) then
		local camera = self.world.game_world.game.level_creator.player.camera
		local camera_config = camera.first_person and camera.config_first_person or camera.config
		for i, touchdata in ipairs(action.touch) do
			local x, y = touchdata.x,touchdata.y
			if (x > 460) then
				self.config.yaw = self.config.yaw + (camera_config.yaw.speed * touchdata.dx * 4)
				self.config.pitch = self.config.pitch + (camera_config.pitch.speed * touchdata.dy * 4)
				break
			end
		end
	end
end

function System:preProcess(dt)
	local player = self.world.game_world.game.level_creator.player
	self.config.yaw = player.camera.yaw
	self.config.pitch = player.camera.pitch
	self:clamp_values()
end

---@param e EntityGame
function System:process(e, dt)
	if(COMMON.CONSTANTS.TARGET_IS_EDITOR)then
		if (self.world.game_world.sm:get_top()._name == self.world.game_world.sm.SCENES.GAME) then
			self.input_handler:on_input(self, e.input_info.action_id, e.input_info.action)
		else
			POINTER.unlock_cursor()
		end
	end
end

function System:postProcess(dt)
	self:clamp_values()
	local player = self.world.game_world.game.level_creator.player
	--	go.set(player.camera_go.root,
	--	COMMON.HASHES.EULER, TEMP_V)
	player.angle = -self.config.yaw
	player.camera.yaw = self.config.yaw
	player.camera.pitch = self.config.pitch
end

function System:onRemoveFromWorld()
	if(COMMON.CONSTANTS.TARGET_IS_EDITOR)then
		POINTER.unlock_cursor()
	end
end

return System