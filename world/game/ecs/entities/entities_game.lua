local COMMON = require "libs.common"
local DEBUG_INFO = require "debug.debug_info"
local DEFS = require "world.balance.def.defs"
local ENUMS = require "world.enums.enums"
local ACTIONS = require "libs.actions.actions"
local TWEEN = require "libs.tween"

local DIR_UP = vmath.vector3(0, 1, 0)

local TABLE_REMOVE = table.remove
local TABLE_INSERT = table.insert

local TAG = "Entities"

---@class InputInfo
---@field action_id hash
---@field action table

---@class EntityGame
---@field _in_world boolean is entity in world
---@field position vector3
---@field input_info InputInfo
---@field auto_destroy_delay number
---@field auto_destroy boolean
---@field visible boolean

local FACTORY_URL_PLAYER = msg.url("game_scene:/factory#player")
local FACTORY_URL_ENEMY = msg.url("game_scene:/factory#enemy")
local PARTS = {
	ROOT = COMMON.HASHES.hash("/root"),
}

---@class ENTITIES
local Entities = COMMON.class("Entities")

---@param world World
function Entities:initialize(world)
	self.world = world
	---@type EntityGame[]
	self.pool_input = {}
end



--region ecs callbacks
---@param e EntityGame
function Entities:on_entity_removed(e)
	DEBUG_INFO.game_entities = DEBUG_INFO.game_entities - 1
	e._in_world = false
	if (e.input_info) then
		TABLE_INSERT(self.pool_input, e)
	end

	if (e.frustum_native) then
		e.frustum_native:Destroy()
		e.frustum_native = nil
	end

	if (e.debug_frustum_box_go) then
		go.delete(e.debug_frustum_box_go.root, true)
		e.debug_frustum_box_go = nil
	end

	if (e.physics_object) then
		game.physics_object_destroy(e.physics_object)
		e.physics_object = nil
	end
	if (e.distance_to_player_object) then
		game.distance_object_destroy(e.distance_to_player_object)
		e.distance_to_player_object = nil
	end

	if (e.debug_interact_aabb_go) then
		go.delete(e.debug_interact_aabb_go.root, true)
		e.debug_interact_aabb_go = nil
	end

	if (e.player_go) then
		go.delete(e.player_go.root, true)
		e.player_go = nil
	end

end

---@param e EntityGame
function Entities:on_entity_added(e)
	DEBUG_INFO.game_entities = DEBUG_INFO.game_entities + 1
	e._in_world = true
end
--endregion


--region Entities

---@return EntityGame
function Entities:create_player(position)
	---@type EntityGame
	local e = {}
	e.player = true
	e.angle = 0
	e.player_data = {
		skin = DEFS.SKINS.SKINS_BY_ID.MINE.id
	}
	e.ghost_mode = false
	e.look_at_dir = vmath.vector3(0, 0, -1)
	e.position = vmath.vector3(position)
	e.movement = {
		velocity = vmath.vector3(0, 0, 0),
		input = vmath.vector3(0, 0, 0),
		direction = vmath.vector3(0, 0, 0),
		max_speed = DEFS.HERO.STATS.BASE_SPEED,
		max_speed_air_limit = 1,
		max_speed_limit = 1, --[0,1] for virtual pad to make movement more easy
		accel = 50 * 0.016,
		deaccel = 15 * 0.016,
		accel_air = 1.5 * 0.016,
		deaccel_air = 3 * 0.016,
		deaccel_stop = 0.5,
		strafe_power = 1,
		strafe_power_air = 1,

		pressed_jump = false,

		air_control_power = 0,
		air_control_power_a = 0
	}
	e.jump = {
		power = 800
	}
	e.camera = {
		position = vmath.vector3(),
		rotation = vmath.quat_rotation_z(0),
		rotation_euler = vmath.vector3(),
		yaw = 0,
		pitch = 0,
		config = {
			position = vmath.vector3(0, 10, 10),
			position_v = vmath.rotate(vmath.quat_rotation_x(math.rad(-60)), vmath.vector3(0, 0, 1)) * 14,
			yaw = { speed = 0.0, value = 45 },
			pitch = { speed = 0, min = -45, max = -45 },
			pitch_portrait = { speed = 0, min = -55, max = -55 },
		},
		config_first_person = {
			position = vmath.vector3(0, 1.75, 0),
			position_v = vmath.vector3(0, 1.75, 0),
			yaw = { speed = 0.1 },
			pitch = { speed = 0.1, min = -70, max = 70 },
		},
		first_person = nil,
	}
	e.visible = true

	local urls = collectionfactory.create(FACTORY_URL_PLAYER, e.position)
	e.player_go = {
		root = msg.url(assert(urls[PARTS.ROOT])),
		model = {
			root = nil,
			model = nil,
		},
		config = {
			scale = vmath.vector3(1),
			skin = nil,
			animation = nil,
			visible = true,
			look_dir = vmath.vector3(0, 0, -1),
		},
	}
	e.player_go.collision = COMMON.LUME.url_component_from_url(e.player_go.root, "collision")
	e.mass = go.get(e.player_go.collision, COMMON.HASHES.MASS)

	e.physics_linear_velocity = vmath.vector3()
	e.on_ground = true
	e.ground_normal = vmath.vector3(DIR_UP)
	e.on_ground_time = 0
	e.jump_last_time = -1

	e.physics_object = game.physics_object_create(e.player_go.root, e.player_go.collision, e.position, e.physics_linear_velocity)

	e.parameters = {
		
	}

	e.current_interact_aabb = nil
	return e
end

function Entities:__create_frustum_bbox(e, position, size, dynamic, frustum_native_dynamic_delta_pos)
	if (dynamic == true) then
		e.frustum_native_dynamic = true
		e.frustum_native_dynamic_delta_pos = frustum_native_dynamic_delta_pos or vmath.vector3()
		position = position + e.frustum_native_dynamic_delta_pos
	end
	e.frustum_native = game.frustum_object_create()
	e.frustum_native:SetPosition(position)
	e.frustum_native:SetSize(size)
	e.frustum_native:SetDistance(self.world.balance.config.frustum_default_distance)

end

---@return EntityGame
function Entities:create_input(action_id, action)
	local input = TABLE_REMOVE(self.pool_input)
	if (not input) then
		input = { input_info = {}, auto_destroy = true }
	end
	input.input_info.action_id = action_id
	input.input_info.action = action
	return input
end

--endregion

return Entities




