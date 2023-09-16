local COMMON = require "libs.common"
local ECS = require 'libs.ecs'
local TWEEN = require 'libs.tween'

local RAYCAST_FROM = vmath.vector3()
local RAYCAST_TO = vmath.vector3(0, 0, 0)
local POS_V = vmath.vector3(0)
local DIST_V = vmath.vector3(0)

local SAFE_AREA_V = vmath.vector3(0)

local PATH_UP = vmath.vector3(0, 1, 0)
local TWO_PI = math.pi * 2

local MATH_DEG = math.deg

---@class CatRunAwayRaycastSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("cat&run_away")
System.name = "CatRunAwayRaycastSystem"

--tl,t,tr,cl,cr,bl,b,br
local near_cells = {
	vmath.vector3(-1, 1, 0), vmath.vector3(0, 1, 0), vmath.vector3(1, 1, 0),
	vmath.vector3(-1, 0, 0), vmath.vector3(1, 0, 0), --no center cell
	vmath.vector3(-1, -1, 0), vmath.vector3(0, -1, 0), vmath.vector3(1, -1, 0),
}

for _, dir in ipairs(near_cells) do
	dir.x = dir.x * 8
	dir.y = dir.y * 8
	dir.z = dir.z * 8
end

function System:init()
	self.interval = 0.125--8 rays per second
	self.ground_raycast_groups = {
		hash("obstacle"),
	}
	self.ground_raycast_mask = game.physics_count_mask(self.ground_raycast_groups)
end

---@param e EntityGame
function System:update(dt)
	local entities = self.entities
	for ei = 1, #entities, 1 do
		local e = entities[ei]
		local dir = assert(near_cells[e.raycast_idx])
		local raycast_data = e.raycast_results[e.raycast_idx]

		RAYCAST_FROM.x, RAYCAST_FROM.y, RAYCAST_FROM.z = e.position.x, e.position.y + 0.25, e.position.z
		RAYCAST_TO.x, RAYCAST_TO.y, RAYCAST_TO.z = dir.x, 0, -dir.y
		xmath.add(RAYCAST_TO, RAYCAST_FROM, RAYCAST_TO)

		raycast_data.raycast, raycast_data.x,
		raycast_data.y, raycast_data.z = game.physics_raycast_single(RAYCAST_FROM, RAYCAST_TO, self.ground_raycast_mask)
		POS_V.x = RAYCAST_TO.x
		POS_V.y = RAYCAST_TO.y
		POS_V.z = RAYCAST_TO.z

		--[[msg.post("@render:", "draw_line", {
			start_point = RAYCAST_FROM,
			end_point = POS_V,
			color = raycast_data.raycast and vmath.vector4(1, 0, 0, 1) or vmath.vector4(0, 1, 0, 1)
		})--]]

		e.raycast_idx = e.raycast_idx + 1
		if (e.raycast_idx >= 9) then e.raycast_idx = 1 end
	end
end

return System