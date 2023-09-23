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
		level = 1,
		mouse_lock = true,
		block_input = false,
		building_blocks = {
			voxel = 1
		},
		first_move = false,
		voxels_collisions = nil,
		location_id = nil,
		cats_collected = 0,
		completed = false
	}

	self.lights:reset()
end

function GameWorld:game_loaded()
	self:load_level(self.world.storage.game:get_level())
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
	if (COMMON.CONSTANTS.TARGET_IS_EDITOR and action_id == COMMON.HASHES.INPUT.N and action.pressed) then
		self.world.game:load_level(self.world.game.state.level + 1)
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

function GameWorld:load_level(level)
	if self.world.sdk.is_yandex then
		self.world.sdk.yagames_sdk:leaderboard_send_cats()
	end
	self.ecs_game.ecs:clear()

	if (self.level_creator) then
		self.level_creator:final()
		self.level_creator = nil
	end

	self.state.level = level
	self.state.cats_collected = 0
	self.state.completed = false

	DEBUG_INFO.game_reset()
	self.ecs_game:add_systems()
	self.level_creator = LevelCreator(self.world)
	self.level_creator:create_level(level)

	--fixed gui was not already created
	timer.delay(0, false, function()
		local ctx = COMMON.CONTEXT:set_context_top_game_gui()
		ctx.data:level_loaded()
		ctx:remove()
	end)

	self:player_update_parameters()
	self:camera_set_first_person(false)

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

---@param cat EntityGame
function GameWorld:cat_collected(cat)
	local ctx = COMMON.CONTEXT:set_context_top_game_gui()
	self.state.cats_collected = self.state.cats_collected + 1
	self.world.storage.cats:collected(cat.cat_data.id)
	ctx.data.views.cats_progress:set_value(self.state.cats_collected)
	ctx.data.views.cats_progress_p:set_value(self.state.cats_collected)
	ctx:remove()
	self.world.sounds:play_sound(self.world.sounds.sounds[DEFS.CATS.CATS[cat.cat_data.id].sound])
	self.world.storage.stats:cat_collected()

end

return GameWorld



