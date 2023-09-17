local COMMON = require "libs.common"
local ACTIONS = require "libs.actions.actions"
local TWEEN = require "libs.tween"
local DEFS = require "world.balance.def.defs"

local LEVEL_SIZE = {
	START_1 = {
		w = 8, d = 20, min_level = 1, weight = 0, cats_min = 1, cats_max = 1
	},
	START_2 = {
		w = 16, d = 16, min_level = 1, weight = 0, cats_min = 5, cats_max = 5
	},


	SMALL_1 = {
		w = 16, d = 16, min_level = 1, weight = 6, cats_min = 5, cats_max = 10
	},

	SMALL_2 = {
		w = 20, d = 20, min_level = 1, weight = 5, cats_min = 5, cats_max = 10
	},

	MEDIUM_1 = {
		w = 31, d = 31, min_level = 5, weight = 4, cats_min = 15, cats_max = 20
	},
	MEDIUM_2 = {
		w = 35, d = 35, min_level = 10, weight = 3, cats_min = 20, cats_max = 25
	},

	BIG = {
		w = 40, d = 40, min_level = 10, weight = 0, cats_min = 30, cats_max = 30
	}
}

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
	--generate geometry
	rnd.seed(COMMON.CONSTANTS.SEEDS.LEVEL_DATA, level)

	local size_list = { }
	for k, v in pairs(LEVEL_SIZE) do
		if v.min_level <= level and v.weight > 0 then
			size_list[v] = v.weight
		end
	end
	if level % 10 == 1 then
		size_list[LEVEL_SIZE.MEDIUM_2]= nil
	end
	local size = assert(COMMON.LUME.pcg_weightedchoice(size_list))

	if level % 10 == 9 then
		size = LEVEL_SIZE.SMALL_2
	end

	if level % 10 == 0 then
		size = LEVEL_SIZE.BIG
	end

	if level == 1 then
		size = LEVEL_SIZE.START_1
	elseif level == 2 then
		size = LEVEL_SIZE.START_2
	end

	---@class LevelConfig
	self.level_config = {
		level = assert(level),
		size = {
			x1 = -math.floor(size.w / 2), x2 = math.ceil(size.w / 2),
			z1 = -math.floor(size.d / 2), z2 = math.ceil(size.d / 2),
		},
		spawn_point = vmath.vector3(0, 65, 0),
		cats = rnd.range(size.cats_min, size.cats_max),
		cells = {},
		spawn_cells = {},
	}

	if(level%10==0)then
		--pass
	elseif(level%5==0)then
		--self.level_config.cats = math.floor(size.cats_max*1.5)
	end

	for z = self.level_config.size.z1 - 1, self.level_config.size.z2 + 1 do
		self.level_config.cells[z] = {}
		for x = self.level_config.size.x1 - 1, self.level_config.size.x2 + 1 do
			self.level_config.cells[z][x] = { tile = 0 }
		end
	end

	self:create_level_geometry()
	self:init_pathfinding()
	self.level_config.spawn_point.x = self.level_config.spawn_point.x + 0.5
	self.level_config.spawn_point.z = self.level_config.spawn_point.z - 0.5


	if level == 1 then
		self.level_config.spawn_point = vmath.vector3(-3, 65, 4)
	end
	self:create_player()
	self:create_cats()


end

function Creator:_level_cellular()
	local lc = self.level_config
	for z = lc.size.z1, lc.size.z2 do
		for x = lc.size.x1, lc.size.x2 do
			local cell = lc.cells[z][x]
			local filled_near = 0
			for dz = -1, 1 do
				for dx = -1, 1 do
					if dx ~= 0 or dz ~= 0 then
						local neighbour = lc.cells[z + dz][x + dx]
						if neighbour.tile ~= 0 then filled_near = filled_near + 1 end
					end
				end
			end
			if cell.tile == 0 and filled_near >= 4 then cell.tile = 2 end
		end
	end
end

function Creator:create_level_geometry()
	local lc = self.level_config
	local size = lc.size

	local step_x = lc.spawn_point.x
	local step_z = lc.spawn_point.z
	local total_cells = (size.x2 - size.x1 + 1) * (size.z2 - size.z1 + 1)

	--generate geometry
	rnd.seed(COMMON.CONSTANTS.SEEDS.LEVEL_GEOMETRY, self.level_config.level)

	local target_cells = math.floor(total_cells * 0.55)
	local empty_cells = 0
	local step = 0
	local dir_table = { 1, 2, 3, 4 }--L,T,R,B
	while (step < 200000 and empty_cells < target_cells) do

		local dir = COMMON.LUME.pcg_randomchoice_remove(dir_table)
		local dx, dy = 0, 0
		if (dir == 1) then dx = -1
		elseif (dir == 2) then dy = 1
		elseif (dir == 3) then dx = 1
		elseif (dir == 4) then dy = -1 end

		local nx, ny = step_x + dx, step_z + dy
		if (nx >= size.x1 and nx <= size.x2 and ny >= size.z1 and ny <= size.z2) then
			step_x = nx
			step_z = ny
			if lc.cells[step_z][step_x].tile == 0 then
				lc.cells[step_z][step_x].tile = 2
				empty_cells = empty_cells + 1
			end
			step = step + 1
			dir_table = { 1, 2, 3, 4 }--L,T,R,B
		end

	end
	print("step:" .. step .. " fill_cells:" .. empty_cells)

	self:_level_cellular()
	self:_level_cellular()

	game.generate_new_level_data(size.x1, size.z1, size.z2, size.x2)
	--game.chunks_fill_zone(-1000, 64 - 30, -1000, 1000, 64, 1000, 2)
	--game.chunks_fill_zone(-1000, 65, -1000, 1000, 255, 1000, 0)

	--fill ground
	for z = lc.size.z1, lc.size.z2 do
		for x = lc.size.x1, lc.size.x2 do
			local cell = lc.cells[z][x]
			game.chunks_fill_zone(x, 64 - 30, z, x, 64, z, cell.tile)
		end
	end

	local chunks_collisions = game.get_collision_chunks()
	local factory_url = msg.url("game_scene:/factory#chunk_collision")
	local factory_border_url = msg.url("game_scene:/factory#chunk_border_collision")

	self.collisions = {}

	--create borders for level
	--far
	table.insert(self.collisions, factory.create(factory_border_url, vmath.vector3(0, 64, lc.size.z1 - 5)))
	--near
	table.insert(self.collisions, factory.create(factory_border_url, vmath.vector3(0, 64, lc.size.z2 + 5 + 1)))
	--left
	table.insert(self.collisions, factory.create(factory_border_url, vmath.vector3(lc.size.x1 - 5, 64, 0), vmath.quat_rotation_y(math.rad(90))))
	--right
	table.insert(self.collisions, factory.create(factory_border_url, vmath.vector3(lc.size.x2 + 5 + 1, 64, 0), vmath.quat_rotation_y(math.rad(90))))

	for _, chunk in ipairs(chunks_collisions) do
		for _, box in ipairs(chunk) do
			local go = factory.create(factory_url, box.position + box.size / 2, nil, nil,
					box.size)
			table.insert(self.collisions, go)
		end
	end
	print("collision objects:" .. #self.collisions)


	--create_collision for empty areas
	local areas = {}
	for z = lc.size.z1, lc.size.z2 do
		areas[z] = {}
		for x = lc.size.x1, lc.size.x2 do
			local cell = lc.cells[z][x]
			--mark all empty cells

			if cell.tile == 0 then
				local filled_near = 0
				for dz = -1, 1 do
					for dx = -1, 1 do
						local neighbour = lc.cells[z + dz][x + dx]
						if neighbour.tile ~= 0 then filled_near = filled_near + 1 end
					end
				end
				if filled_near > 0 then
					areas[z][x] = true
				end
			end

		end
	end

	local boxes = {}
	factory_url = msg.url("game_scene:/factory#chunk_line_collision")
	for z = lc.size.z1, lc.size.z2 do
		for x = lc.size.x1, lc.size.x2 do
			if areas[z][x] then
				table.insert(boxes, {
					position = vmath.vector3(x, 64, z),
					size = vmath.vector3(1, 1, 1)
				})
			end
		end
	end

	for _, box in ipairs(boxes) do
		local go = factory.create(factory_url, box.position + box.size / 2, nil, nil,
				box.size)
		table.insert(self.collisions, go)
	end
	print("collision all:" .. #self.collisions)

end

function Creator:create_player()
	self.player = self.entities:create_player(self.level_config.spawn_point)
	self.ecs:add_entity(self.player)
end

function Creator:init_pathfinding()
	game.pathfinding_init_map()
	local lc = self.level_config
	lc.spawn_cells = {}
	for z = lc.size.z1, lc.size.z2 do
		for x = lc.size.x1, lc.size.x2 do
			if not game.pathfinding_is_blocked(x, z) then
				table.insert(lc.spawn_cells, { z = z, x = x, cell = lc.cells[z][x] })
			end
		end
	end
end

function Creator:create_cats()
	local lc = self.level_config
	local free_cells = COMMON.LUME.clone_shallow(lc.spawn_cells)
	if self.level_config.level == 1 then
		free_cells = {{ z = 2, x = 4, cell = lc.cells[-3][4] }}
	end
	lc.cats = math.min(lc.cats, math.ceil(#free_cells * 0.66))

	local cats_created = 0
	local cats = {  }

	--spawn cat when it first appeared
	local forced_cats = { }
	for _,v in ipairs(DEFS.CATS.LIST) do
		if v.min_level<= lc.level then
			table.insert(cats,v)
			if v.min_level == lc.level then
				table.insert(forced_cats,v)
			end
		end
	end

	for i = 1, lc.cats do
		local cell
		--do not spawn near player
		while (#free_cells > 0) do
			cell = COMMON.LUME.randomchoice_remove(free_cells)
			local dx = cell.x + 0.5 - lc.spawn_point.x
			local dz = cell.z + 0.5 - lc.spawn_point.z
			if math.abs(dx) >= 2 or math.abs(dz) >= 2 then break end
		end

		local x = cell.x + 0.5
		local y = 65.01
		local z = cell.z + 0.5 + COMMON.LUME.random(-0.1, 0.1)

		local cat_def = table.remove(forced_cats) or COMMON.LUME.randomchoice(cats)
		local cat = self.entities:create_cat(vmath.vector3(x, y, z), cat_def.id)
		self.ecs:add_entity(cat)
		cats_created = cats_created + 1
	end

	lc.cats = cats_created
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