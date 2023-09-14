local COMMON = require "libs.common"
local ECS = require 'libs.ecs'

local TEMP_POS = vmath.vector3()
local TEMP_SIZE = vmath.vector3()

local FACTORY = msg.url("game_scene:/factory#physics_debug_static")

local PARTS = {
	ROOT = COMMON.HASHES.hash("/root"),
}

---@class DrawFrustumBoxSystem:ECSSystemProcessing
local System = ECS.processingSystem()
System.filter = ECS.filter("frustum_native")
System.name = "DrawFrustumBoxSystem"

function System:init()
end

function System:update(dt)
	local entities = self.entities
	for i = 1, #entities do
		local e = entities[i]
		--local visible = e.visible and self.world.game_world.storage.debug:draw_frustum_box_is()
		if (e.frustum_box_ignore_draw) then return end
		local visible = self.world.game_world.storage.debug:draw_frustum_box_is()
		visible = visible and e.frustum_native:IsVisible()
		if (not visible and e.debug_frustum_box_go) then
			go.delete(e.debug_frustum_box_go.root, true)
			e.debug_frustum_box_go = nil
		elseif (visible and not e.debug_frustum_box_go) then
			TEMP_POS.x, TEMP_POS.y, TEMP_POS.z = e.frustum_native:GetPositionRaw()
			TEMP_SIZE.x, TEMP_SIZE.y, TEMP_SIZE.z = e.frustum_native:GetSizeRaw()
			xmath.mul(TEMP_SIZE, TEMP_SIZE, 1 / 64)
			local collection = collectionfactory.create(FACTORY, TEMP_POS, nil, nil,
					TEMP_SIZE)
			---@class FrustumBoxGo
			e.debug_frustum_box_go = {
				root = msg.url(assert(collection[PARTS.ROOT]))
			}
		end
		if (e.debug_frustum_box_go) then
			TEMP_POS.x, TEMP_POS.y, TEMP_POS.z = e.frustum_native:GetPositionRaw()
			go.set_position(TEMP_POS, e.debug_frustum_box_go.root)
		end
	end
end

---@param e EntityGame
function System:process(e, dt)

end

function System:onRemove(e)
	if (e.debug_frustum_box_go) then
		go.delete(e.debug_frustum_box_go.root, true)
		e.debug_frustum_box_go = nil
	end
end

return System