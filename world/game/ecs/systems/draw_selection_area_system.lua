local ECS = require 'libs.ecs'
local COMMON = require "libs.common"

---@class DrawSelectionAreaSystem:ECSSystem
local System = ECS.system()
System.name = "SelectionBlockSystem"

local FACTORY_URL = msg.url("/factory#selection_area")
local PARTS = {
	ROOT = COMMON.HASHES.hash("/root"),
}

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
	if (COMMON.is_mobile()) then return end
	local p1 = self.world.game_world.game.state.voxel_editor.pos_1
	local p2 = self.world.game_world.game.state.voxel_editor.pos_2
	local show_cube = (p1.x ~= 0 or p1.y ~= 0 or p1.z ~= 0)
			and (p2.x ~= 0 or p2.y ~= 0 or p2.z ~= 0)
	if (self.show_cube ~= show_cube) then
		self.show_cube = show_cube
		msg.post(self.cube_go.root, show_cube and COMMON.HASHES.MSG.ENABLE or COMMON.HASHES.MSG.DISABLE)
	end

	if (self.show_cube) then
		local max_x, min_x = math.max(p1.x,p2.x)+1, math.min(p1.x,p2.x)
		local max_y, min_y = math.max(p1.y,p2.y)+1, math.min(p1.y,p2.y)
		local max_z, min_z = math.max(p1.z,p2.z)+1, math.min(p1.z,p2.z)

		local cx = (max_x-min_x)/2 + min_x
		local cy = (max_y-min_y)/2 + min_y
		local cz = (max_z-min_z)/2 + min_z

		local size_x = (max_x-min_x)/2 +0.05
		local size_y = (max_y-min_y)/2+0.05
		local size_z = (max_z-min_z)/2+0.05

		TEMP_V.x,TEMP_V.y,TEMP_V.z = cx,cy,cz
		go.set_position(TEMP_V, self.cube_go.root)

		TEMP_V.x,TEMP_V.y,TEMP_V.z = size_x,size_y,size_z
		go.set_scale(TEMP_V, self.cube_go.root)
	end
end

return System