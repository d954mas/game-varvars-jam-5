local COMMON = require "libs.common"
local EcsGame = require "world.game.ecs.game_ecs"
local ENUMS = require "world.enums.enums"
local DEBUG_INFO = require "debug.debug_info"
local ACTIONS = require "libs.actions.actions"
local DEFS = require "world.balance.def.defs"
local LevelCreator = require "world.game.levels.level_creator"
local Lights = require "world.game.lights"

local IS_DEV = COMMON.CONSTANTS.VERSION_IS_DEV

local TAG = "GAME_WORLD"

---@class GameWorld
local GameWorld = COMMON.class("GameWorld")

---@param world World
function GameWorld:initialize(world)
	self.world = assert(world)
	self.ecs_game = EcsGame(self.world)
	self.lights = Lights(world)
	self:reset_state()
end

function GameWorld:reset_state()
	self.actions = ACTIONS.Parallel()
	self.actions.drop_empty = false
	self.state = {
		time = 0,
		mouse_lock = true,
		block_input = false,
		building_blocks = {
			voxel = 1
		},
		first_move = false,
		voxels_collisions = nil,
		location_id = nil,
		voxel_editor = {
			pos_1 = vmath.vector3(0, 0, 0),
			pos_2 = vmath.vector3(0, 0, 0),
		}
	}

	self.lights:reset()
end

function GameWorld:game_loaded()
	self:load_location(DEFS.LOCATIONS.BY_ID.HUB.id)
end

function GameWorld:update(dt)
	if (IS_DEV) then DEBUG_INFO.ecs_update_dt = socket.gettime() end
	self.ecs_game:update(dt)
	if IS_DEV then DEBUG_INFO.update_ecs_dt(socket.gettime() - DEBUG_INFO.ecs_update_dt) end

	self.state.time = self.state.time + dt
	if (self.actions) then self.actions:update(dt) end
end

--update when game scene not on top
function GameWorld:update_always(dt)

end

function GameWorld:final()
	self:reset_state()
	self.ecs_game:clear()
end

function GameWorld:load_level(level)
	local result = nil
	if (COMMON.CONSTANTS.PLATFORM_IS_PC) then
		local path = "./assets/levels/" .. level .. "/level.bin"
		print("load voxels:" .. path)
		local status, file = pcall(io.open, path, "rb")
		if (not status) then
			COMMON.w("can't open file:" .. tostring(file), TAG)
		else
			if (file) then
				local contents, read_err = file:read("*all")
				if (not contents) then
					COMMON.w("can't read file:\n" .. read_err, TAG)
				else
					result = contents
				end
				file:close()
			else
				COMMON.i("no file", TAG)
			end
		end
	else
		local path = "/assets/custom/" .. level .. "/level.bin"
		result = sys.load_resource(path)
	end

	if (result) then
		game.load_world_level_data(result)
	else
		COMMON.i("can't load level:" .. level, TAG)
	end


end

function GameWorld:on_input(action_id, action)
	if (COMMON.CONSTANTS.TARGET_IS_EDITOR) then
		self.ecs_game:add_entity(self.ecs_game.entities:create_input(action_id, action))
	end
	if (not COMMON.CONSTANTS.TARGET_IS_EDITOR and action_id == COMMON.HASHES.INPUT.ESCAPE and action.pressed) then
		self.world.sm:show(self.world.sm.MODALS.SETTINGS)
		return true
	end
	if (action_id == COMMON.HASHES.INPUT.P and action.pressed) then
		print(self.level_creator.player.position)
	end
	if (COMMON.CONSTANTS.TARGET_IS_EDITOR) then
		if (action_id == COMMON.HASHES.INPUT.F5 and action.pressed) then
			local location_def = assert(DEFS.LOCATIONS.BY_ID[self.state.location_id])
			local path = "./assets/levels/" .. location_def.level .. "/"
			if (COMMON.CONSTANTS.TARGET_IS_EDITOR) then
				local time = socket.gettime()
				local data = game.get_world_level_data()

				local file = io.open(path .. "level.bin", "wb")
				file:write(data)
				file:close()
				print("Level save:" .. (socket.gettime() - time))

				--time = socket.gettime()
				--game.save_wavefront_obj(path)
				--print("Level save wavefront:" .. (socket.gettime()-time))

				--delete current collisions
				local exist = true
				local idx = 1
				while (exist) do
					local file_name = path .. "collisions/chunk_" .. idx .. ".go"
					exist = os.remove(file_name)
					idx = idx + 1
				end

				time = socket.gettime()
				game.save_collision_chunks(path)
				print("Level save collisions:" .. (socket.gettime() - time))
			end
		elseif (action_id == COMMON.HASHES.INPUT.F8 and action.pressed and not self.state.load_world) then
			--local path = "./assets/levels/test_level/level.bin"
			--self:load_level(path)
		end
	end
end

function GameWorld:camera_set_first_person(first_person)
	local camera = self.level_creator.player.camera
	if (camera.first_person ~= first_person) then
		camera.first_person = first_person
		--camera.yaw = 0
		--camera.pitch = 0
		if (COMMON.CONTEXT:exist(COMMON.CONTEXT.NAMES.GAME_GUI)) then
			local ctx = COMMON.CONTEXT:set_context_top_game_gui()
			gui.set_enabled(ctx.data.vh.crosshair, first_person)
			ctx:remove()
		end
	end
end

function GameWorld:player_action()
	local player = self.level_creator.player
	if (player.current_interact_aabb) then
		local area = player.current_interact_aabb
		local object = area.interact_target
	end
end

function GameWorld:player_set_current_interact_aabb(e)
	local player = self.world.game.level_creator.player

	if (not player.moving) then
		if (player.current_interact_aabb ~= e) then
			player.current_interact_aabb = e
			self:player_action()
		end
	else
		player.current_interact_aabb = nil
	end

end

function GameWorld:player_teleport_cor(position, angle)
	local player = self.world.game.level_creator.player
	msg.post(player.player_go.collision, COMMON.HASHES.MSG.DISABLE)
	coroutine.yield()

	go.set(player.player_go.collision, COMMON.HASHES.hash("linear_velocity"), vmath.vector3(0, 0, 0))
	go.set_position(position, player.player_go.root)
	if (angle) then
		player.angle = angle
	end
	msg.post(player.player_go.collision, COMMON.HASHES.MSG.ENABLE)
	coroutine.yield()
end

function GameWorld:load_location(location_id)
	local location_def = assert(DEFS.LOCATIONS.BY_ID[location_id])
	print("LOAD LOCATION:" .. location_id)

	local ctx = COMMON.CONTEXT:set_context_top_game()

	self.ecs_game.ecs:clear()
	if (self.state.voxels_collisions) then
		for k, v in ipairs(self.state.voxels_collisions) do
			go.delete(v)
		end
		self.state.voxels_collisions = nil
	end

	DEBUG_INFO.game_reset()
	self.ecs_game:add_systems()
	self.level_creator = LevelCreator(self.world)

	self.level_creator:create_player(location_def.player_spawn)
	self:player_update_parameters()
	self:camera_set_first_person(false)

	self.state.location_id = location_id

	self:load_level(location_def.level)

	if (location_id == DEFS.LOCATIONS.BY_ID.HUB.id) then
		game.generate_new_level_data(-31, -31, 32, 32)
		game.chunks_fill_zone(-1000, 54, -1000, 1000, 64, 1000, 2)
		game.chunks_fill_zone(-1000, 65, -1000, 1000, 255, 1000, 0)
		local chunks_collisions = game.get_collision_chunks()
		local factory_url = msg.url("game_scene:/factory#chunk_collision")

		self.state.voxels_collisions = {}
		for _, chunk in ipairs(chunks_collisions) do
			for _, box in ipairs(chunk) do
				--skip boxes that not hit y==65
				if(box.position.y + box.size.y>=64.9999)then
					local go = factory.create(factory_url, box.position + box.size / 2, nil, nil,
							box.size)
					--local go = {}
					table.insert(self.state.voxels_collisions,go)
				end
			end
		end
		print("collision objects:" .. #self.state.voxels_collisions)

		--game.chunks_fill_hollow()
		--game.chunks_clip_size(-123,-123+31,93, 62)
	end

	ctx:remove()
	for _, e in ipairs(location_def.entities) do
		if false then
		else
			pprint(e)
			error("unknown entity")
		end
	end

	for _, e in ipairs(location_def.spawn_points) do

	end

	self.ecs_game:refresh()
	--update camera or all enemies will be added to world. Need to add only if visible
	self.ecs_game:update(0)
	self.ecs_game:update(0)

end

function GameWorld:player_update_parameters()
	if not self.level_creator then return end
	local balance = self.world.balance.config

	local player = self.level_creator.player
end

return GameWorld



