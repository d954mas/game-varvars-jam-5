local ECS = require 'libs.ecs'
local COMMON = require "libs.common"

---@class SelectionBlockSystem:ECSSystem
local System = ECS.system()
System.name = "SelectionBlockSystem"

local FACTORY_URL = msg.url("/factory#selection_cube")
local PARTS = {
	ROOT = COMMON.HASHES.hash("/root"),
}

local P1 = vmath.vector3()
local P2 = vmath.vector3()
local DIR = vmath.vector3()

local TEMP_V = vmath.vector3()

function System:init()
	self.show_cube = false
end

function System:onAddToWorld()
	local urls = collectionfactory.create(FACTORY_URL, vmath.vector3(0, -150, 0), nil, nil, vmath.vector3(0.52))
	self.cube_go = {
		root = assert(urls[PARTS.ROOT]),
	}
	msg.post(self.cube_go.root, COMMON.HASHES.MSG.DISABLE)
end

function System:onRemoveFromWorld()
	go.delete(self.cube_go.root, true)
	self.cube_go = nil

end

---@param e EntityGame
function System:update(dt)
	if(COMMON.is_mobile())then return end
	local action = COMMON.INPUT.MOUSE_POS
	local raycast_result = nil
	local player = self.world.game_world.game.level_creator.player
	if (not player.camera.first_person and action and not self.world.game_world.game.state.mouse_lock) then
		P1.x, P1.y, P1.z, P2.x, P2.y, P2.z = game.camera_screen_to_world_ray(action.screen_x, action.screen_y)
		xmath.sub(DIR, P2, P1);
		xmath.normalize(DIR, DIR);
		raycast_result = game.raycast(P1, DIR, 25)
	elseif (player.camera.first_person and self.world.game_world.game.state.mouse_lock) then
		P1.x, P1.y, P1.z, P2.x, P2.y, P2.z = game.camera_screen_to_world_ray(COMMON.RENDER.screen_size.w / 2, COMMON.RENDER.screen_size.h / 2)
		xmath.sub(DIR, P2, P1);
		xmath.normalize(DIR, DIR);
		raycast_result = game.raycast(P1, DIR, 8)
	end
	player.select_raycast_result = raycast_result

	if (not raycast_result and self.show_cube) then
		msg.post(self.cube_go.root, COMMON.HASHES.MSG.DISABLE)
		self.show_cube = false
	elseif (raycast_result and not self.show_cube) then
		msg.post(self.cube_go.root, COMMON.HASHES.MSG.ENABLE)
		self.show_cube = true
	end

	if (raycast_result) then
		TEMP_V.x = math.floor(raycast_result.chunk_pos.x) + 0.5
		TEMP_V.y = math.floor(raycast_result.chunk_pos.y) + 0.5
		TEMP_V.z = math.floor(raycast_result.chunk_pos.z) + 0.5
		go.set_position(TEMP_V, self.cube_go.root)
	end
end

return System