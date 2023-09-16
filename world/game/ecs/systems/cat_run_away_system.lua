local COMMON = require "libs.common"
local ECS = require 'libs.ecs'
local TWEEN = require 'libs.tween'

local POS_V = vmath.vector3(0)
local DIST_V = vmath.vector3(0)
local TEMP_V = vmath.vector3(0)
local TEMP_V2 = vmath.vector3(0)

local PATH_UP = vmath.vector3(0, 1, 0)
local TWO_PI = math.pi * 2

local MATH_DEG = math.deg

---@class CatRunAwaySystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("cat&run_away")
System.name = "CatRunAwaySystem"

--tl,t,tr,cl,cr,bl,b,br
local near_cells = {
	vmath.vector3(-1, 1, 0), vmath.vector3(0, 1, 0), vmath.vector3(1, 1, 0),
	vmath.vector3(-1, 0, 0), vmath.vector3(1, 0, 0), --no center cell
	vmath.vector3(-1, -1, 0), vmath.vector3(0, -1, 0), vmath.vector3(1, -1, 0),
}

local CELLS = {
	top = { 2, 1, 3, 4, 5, 8, 6 }, -- 7
	top_left = { 1, 4, 2, 6, 3, 7, 5 }, --8
	left = { 4, 6, 1, 7, 2, 8, 3 }, --5
	bot_left = { 6, 7, 4, 8, 1, 5, 2 }, --3
	bot = { 7, 8, 6, 5, 4, 3, 1 }, --2
	bot_right = { 8, 5, 7, 3, 6, 2, 4 }, --1
	right = { 5, 3, 8, 2, 7, 1, 6 }, --4,
	top_right = { 3, 2, 5, 1, 8, 4, 7 }, --6
}

local CELLS_ODD = {
	top = { 1, 2, 3, 4, 5, 8, 6 }, -- 7
	top_left = { 2, 1, 4, 6, 3, 7, 5 }, --8
	left = { 4, 6, 1, 7, 2, 8, 3 }, --5
	bot_left = { 8, 6, 7, 8, 1, 5, 2 }, --3
	bot = { 8, 7, 6, 5, 4, 3, 1 }, --2
	bot_right = { 7, 8, 5, 3, 6, 2, 4 }, --1
	right = { 3, 5, 8, 2, 7, 1, 6 }, --4,
	top_right = { 5, 3, 2, 1, 8, 4, 7 }, --6
}

function System:get_path_cells_from_angle(angle, odd)
	local cells = odd and CELLS_ODD or CELLS
	if (angle <= 22.5 or angle >= 337.5) then
		return cells.top
	elseif (angle >= 22.5 and angle <= 67.5) then
		return cells.top_left
	elseif (angle >= 67.5 and angle <= 112.5) then
		return cells.left
	elseif (angle >= 112.5 and angle <= 157.5) then
		return cells.bot_left
	elseif (angle >= 112.5 and angle <= 202.5) then
		return cells.bot
	elseif (angle >= 202.5 and angle <= 247.5) then
		return cells.bot_right
	elseif (angle >= 247.5 and angle <= 292.5) then
		return cells.right
	elseif (angle >= 292.5 and angle <= 337.5) then
		--top right
		return cells.top_right
	else
		assert("bad angle:" .. angle)
	end
end

function System:init()
	self.interval = 2 / 60
end

---@param e EntityGame
function System:update(dt)
	local game_world = self.world.game_world.game
	local location = game_world.level_creator.location
	local entities = self.entities

	for ei = 1, #entities, 1 do
		local e = entities[ei]
		if e.run_away then
			local d_normalized = e.distance_to_player_vec_normalized
			local angle = COMMON.LUME.angle2(PATH_UP.x, PATH_UP.y, -d_normalized.x, d_normalized.z)
			if (angle < 0) then angle = angle + TWO_PI end
			--0-360 anti clocwise angle. 0 is forward.(-z)
			--pprint(math.deg(angle))


			local cells = self:get_path_cells_from_angle(MATH_DEG(angle), e.odd)

			--find direction with hight priority
			local idx_move = 1
			local priority = 0
			--max priority ---100
			--60% is distance
			--40% is priority
			local max_distance_priority = 60
			local max_dir_priority = 40
			for i = 1, #cells do
				local cell_idx = cells[i]
				local raycast_data = e.raycast_results[cell_idx]
				local raycast_priority = max_distance_priority
				--from 0 to 20
				if (raycast_data.raycast) then
					DIST_V.x, DIST_V.y, DIST_V.z = raycast_data.x, 0, raycast_data.z
					POS_V.x, POS_V.y, POS_V.z = e.position.x, 0, e.position.z
					xmath.sub(DIST_V, DIST_V, POS_V)
					local distance = vmath.length(DIST_V)
					local distance_a = distance / 20
					raycast_priority = (max_distance_priority * distance_a) * 0.9
				end
				local idx_priority = max_dir_priority * (9 - i) / 8
				--[[if (i >= 2 and i <= 3) then
					idx_priority = max_dir_priority * 0.75
				elseif (i >= 4 and i <= 5) then
					idx_priority = max_dir_priority * 0.33
				elseif (i >= 6 and i <= 7) then
					idx_priority = max_dir_priority * 0.15
				elseif (i >= 8) then
					idx_priority = 0
				end--]]
				raycast_data.priority = raycast_priority + idx_priority
				if (raycast_priority / max_distance_priority > 0.8 and raycast_data.cell_idx == e.run_away_prev_cell_idx) then
					raycast_data.priority = raycast_data.priority + 5
				end
				if (raycast_data.priority > priority) then
					idx_move = cell_idx
					priority = raycast_data.priority
				end
			end


			--pprint(neighbours_raycasts[idx_move])
			local delta_move = near_cells[idx_move]
			if (not delta_move) then
				delta_move = vmath.vector3(0)
				print("some problem")
			end
			e.run_away_prev_cell_idx = e.raycast_results[idx_move].cell_idx

			if (e.movement.direction.x ~= 0 or e.movement.direction.y ~= 0) then
				TEMP_V.x, TEMP_V.y, TEMP_V.z = e.movement.direction.x, e.movement.direction.y, 0
				TEMP_V2.x, TEMP_V2.y, TEMP_V2.z = delta_move.x, delta_move.y, 0
				xmath.normalize(TEMP_V, TEMP_V)
				xmath.normalize(TEMP_V2, TEMP_V2)
				local a = self.world.game_world.balance.config.lerp_direction_a
				xmath.lerp(e.movement.direction, a, TEMP_V, TEMP_V2)
			else
				e.movement.direction.x = delta_move.x
				e.movement.direction.y = delta_move.y
			end
			print(e.movement.d)


			--[[	msg.post("@render:", "draw_line", {
			start_point = e.position,
			end_point = e.position + vmath.rotate(vmath.quat_rotation_y(angle), FORWARD) * 4,
			color = vmath.vector4(1, 0, 0, 1)
		})

		msg.post("@render:", "draw_line", {
			start_point = e.position,
			end_point = e.position + -DISTANCE_V_NORMALIZED * 2,
			color = vmath.vector4(0, 1, 0, 1)
		})

		msg.post("@render:", "draw_line", {
			start_point = e.position,
			end_point = e.position + vmath.vector3(delta_move.x,0,-delta_move.y)*6,
			color = vmath.vector4(0, 0, 1, 1)
		})--]]
		end
	end
end

return System