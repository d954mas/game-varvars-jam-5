local ECS = require 'libs.ecs'
local COMMON = require "libs.common"
local ENUMS = require "world.enums.enums"
local POINTER = require "libs.pointer_lock"

---@class AddRemoveBlockSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("input_info")
System.name = "AddRemoveBlockSystem"

function System:init()
	self.pressed_time = 0
	self.pressed_time_right = 0
	self.input_handler = COMMON.INPUT()

	self.input_handler:add(COMMON.HASHES.INPUT.TOUCH, function(_, action_id, action)
		local camera = self.world.game_world.game.level_creator.player.camera
		if (camera.first_person and not POINTER.locked) then return end
		if (not camera.first_person and POINTER.locked) then return end
		if (action.pressed) then
			self.pressed_time = self.world.game_world.time
		end

		local voxel = self.world.game_world.game.state.building_blocks.voxel
		if (action.pressed or (not action.released and (self.world.game_world.time - self.pressed_time) > 1)) then

			local result = self.world.game_world.game.level_creator.player.select_raycast_result
			if (result) then

				local px, py, pz = result.chunk_pos.x, result.chunk_pos.y, result.chunk_pos.z
				if (voxel ~= 0) then
					if (result.side == ENUMS.CHUNK_SIDE.TOP) then py = py + 1
					elseif (result.side == ENUMS.CHUNK_SIDE.BOTTOM) then py = py - 1
					elseif (result.side == ENUMS.CHUNK_SIDE.RIGHT) then px = px + 1
					elseif (result.side == ENUMS.CHUNK_SIDE.LEFT) then px = px - 1
					elseif (result.side == ENUMS.CHUNK_SIDE.FRONT) then pz = pz - 1
					elseif (result.side == ENUMS.CHUNK_SIDE.BACK) then pz = pz + 1
					end
				end
				--do not autodestroy walking layer
				if (py == 64) then
					if (action.pressed) then
						game.chunks_set_voxel(px, py, pz, self.world.game_world.game.state.building_blocks.voxel)
					end
				else
					game.chunks_set_voxel(px, py, pz, self.world.game_world.game.state.building_blocks.voxel)
				end

			end
		end
	end, false, false, false, true)
	self.input_handler:add(COMMON.HASHES.INPUT.RIGHT_CLICK, function(_, action_id, action)
		local camera = self.world.game_world.game.level_creator.player.camera
		if (camera.first_person and not POINTER.locked) then return end
		if (not camera.first_person and POINTER.locked) then return end
		if (action.pressed) then
			self.pressed_time_right = self.world.game_world.time
		end

		if (action.pressed or (not action.released and (self.world.game_world.time - self.pressed_time_right) > 1)) then

			local result = self.world.game_world.game.level_creator.player.select_raycast_result
			if (result) then
				local px, py, pz = result.chunk_pos.x, result.chunk_pos.y, result.chunk_pos.z
				--do not autodestroy walking layer
				if (py == 64) then
					if (action.pressed) then
						game.chunks_set_voxel(px, py, pz, 0)
					end
				else
					game.chunks_set_voxel(px, py, pz, 0)
				end

			end
		end
	end, false, false, false, true)
	self.input_handler:add(COMMON.HASHES.INPUT.NUMBER_1, function(_, action_id, action)
		local result = self.world.game_world.game.level_creator.player.select_raycast_result
		if (result) then
			local pos = self.world.game_world.game.state.voxel_editor.pos_1
			pos.x, pos.y, pos.z = result.chunk_pos.x, result.chunk_pos.y, result.chunk_pos.z
		end
	end, true, false, false, false)
	self.input_handler:add(COMMON.HASHES.INPUT.NUMBER_2, function(_, action_id, action)
		local result = self.world.game_world.game.level_creator.player.select_raycast_result
		if (result) then
			local pos = self.world.game_world.game.state.voxel_editor.pos_2
			pos.x, pos.y, pos.z = result.chunk_pos.x, result.chunk_pos.y, result.chunk_pos.z
		end
	end, true, false, false, false)
end

---@param e EntityGame
function System:process(e, dt)
	self.input_handler:on_input(self, e.input_info.action_id, e.input_info.action)
end

return System