local COMMON = require "libs.common"
local ECS = require 'libs.ecs'

local TEMP_POS = vmath.vector3()
local TEMP_SIZE = vmath.vector3()

local TEMP_V = vmath.vector3()
local TEMP_V2 = vmath.vector3()

local FACTORY = msg.url("game_scene:/factory#physics_debug_static")

local PARTS = {
	ROOT = COMMON.HASHES.hash("/root"),
}

---@class DrawInteractAABBDebugSystem:ECSSystemProcessing
local System = ECS.processingSystem()
System.filter = ECS.filter("interact_aabb")
System.name = "DrawInteractAABBSystem"

function System:init()
end

function System:update(dt)
	local entities = self.entities
	for i = 1, #entities do
		local e = entities[i]
		TEMP_V.x, TEMP_V.y, TEMP_V.z = e.interact_aabb[1], e.interact_aabb[2], e.interact_aabb[3]
		TEMP_V2.x, TEMP_V2.y, TEMP_V2.z = e.interact_aabb[4], e.interact_aabb[5], e.interact_aabb[6]
		local visible = self.world.game_world.storage.debug:draw_interact_aabb_is()
				and game.frustum_is_box_visible(TEMP_V, TEMP_V2)
		if (not visible and e.debug_interact_aabb_go) then
			go.delete(e.debug_interact_aabb_go.root, true)
			e.debug_interact_aabb_go = nil
		elseif (visible and not e.debug_interact_aabb_go) then

			local w = e.interact_aabb[4] - e.interact_aabb[1]
			local h = e.interact_aabb[5] - e.interact_aabb[2]
			local d = e.interact_aabb[6] - e.interact_aabb[3]
			TEMP_POS.x, TEMP_POS.y, TEMP_POS.z = e.interact_aabb[1] + w / 2, e.interact_aabb[2] + h / 2,
			e.interact_aabb[3] + d / 2
			TEMP_SIZE.x, TEMP_SIZE.y, TEMP_SIZE.z = w, h, d
			xmath.mul(TEMP_SIZE, TEMP_SIZE, 1 / 64)
			local collection = collectionfactory.create(FACTORY, TEMP_POS, nil, nil,
					TEMP_SIZE)
			---@class DebugInteractAABBGo
			e.debug_interact_aabb_go = {
				root = msg.url(assert(collection[PARTS.ROOT]))
			}
		end
	end
end

---@param e EntityGame
function System:process(e, dt)

end

function System:onRemove(e)

end

return System