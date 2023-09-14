local COMMON = require "libs.common"
local ACTIONS = require "libs.actions.actions"
local TWEEN = require "libs.tween"
local DEFS = require "world.balance.def.defs"

---@class LevelCreator
local Creator = COMMON.class("LevelCreator")

---@param world World
function Creator:initialize(world)
	self.world = world
	self.ecs = world.game.ecs_game
	self.entities = world.game.ecs_game.entities
end

function Creator:create_player(position)
	self.player = self.entities:create_player(position)
	self.ecs:add_entity(self.player)
end

---@param config EntityGame
function Creator:create_portal(config)
	---@type EntityGame
	local e = {}
	e.portal = true
	e.position = vmath.vector3(config.position) - vmath.vector3(0, -0.05, 0)
	e.rotation = config.rotation and vmath.quat(config.rotation) or vmath.quat_rotation_y(0)
	e.portal_config = config


	self.ecs:add_entity(e)
	self.portal = e
	return e
end




---@param config EntityGame
function Creator:create_building(config)
	local def = assert(DEFS.BUILDINGS[config.building])
	---@type EntityGame
	local e = {}
	e.building = true
	e.position = vmath.vector3(config.position)
	e.building_id = def.id
	e.rotation = config.rotation or vmath.quat_rotation_y(0)
	e.config = config
	self.ecs:add_entity(e)


	if (def.id == DEFS.BUILDINGS.HEAL_CIRCLE.id) then
		e.heal_circle = true
		e.heal_circle_radius = 7.5
		e.distance_to_player = math.huge
		e.distance_to_player_vec = vmath.vector3(0, 0, 1)
		e.distance_to_player_vec_normalized = vmath.vector3(0, 0, 1)
		e.distance_to_player_object = game.distance_object_create(e, e.position,e.distance_to_player_vec, e.distance_to_player_vec_normalized)
	end
	self.entities:__create_frustum_bbox(e, e.position + def.frustum.position, def.frustum.size)

	return e
end

---@param config EntityGame
function Creator:create_obstacle(config)
	local def = assert(DEFS.OBSTACLES[config.obstacle])
	---@type EntityGame
	local e = {}
	e.obstacle = true
	e.position = vmath.vector3(config.position)
	e.obstacle_id = def.id
	e.rotation = config.rotation or vmath.quat_rotation_y(0)
	e.config = config
	self.ecs:add_entity(e)
	self.entities:__create_frustum_bbox(e, e.position + def.frustum.position, def.frustum.size)
	return e
end

function Creator:create()

end

return Creator