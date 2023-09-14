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
	self.collisions = {}
end

function Creator:create_level(level)
	local size = { x1 = -31, x2 = 32, z1 = -31, z2 = 32 }

	game.generate_new_level_data(size.x1, size.z1, size.z2, size.x2)
	game.chunks_fill_zone(-1000, 64 - 30, -1000, 1000, 64, 1000, 2)
	game.chunks_fill_zone(-1000, 65, -1000, 1000, 255, 1000, 0)
	game.chunks_fill_zone(-15, -15, -1000, 4, 255, 4, 0)
	for i=1,10 do
		game.chunks_fill_zone(math.random(size.x1,size.x2), 65, math.random(size.x1,size.x2), math.random(size.z1,size.z2), 65+math.random(1,5), math.random(size.z1,size.z2), 2)
	end
	local chunks_collisions = game.get_collision_chunks()
	local factory_url = msg.url("game_scene:/factory#chunk_collision")

	self.collisions = {}
	for _, chunk in ipairs(chunks_collisions) do
		for _, box in ipairs(chunk) do
			local go = factory.create(factory_url, box.position + box.size / 2, nil, nil,
					box.size)
			table.insert(self.collisions, go)
		end
	end
	print("collision objects:" .. #self.collisions)
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
		e.distance_to_player_object = game.distance_object_create(e, e.position, e.distance_to_player_vec, e.distance_to_player_vec_normalized)
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

function Creator:final()
	if (self.collisions) then
		for _, c in ipairs(self.collisions) do
			go.delete(c)
		end
		self.collisions = nil
	end
end

return Creator