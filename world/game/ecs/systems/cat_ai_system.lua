local COMMON = require "libs.common"
local ECS = require 'libs.ecs'
local DEFS = require "world.balance.def.defs"
local ENUMS = require "world.enums.enums"

local COROUTINE_YIELD = coroutine.yield
local COROUTINE_RESUME = COMMON.coroutine_resume

---@class EnemyAISystem:ECSSystemProcessing
local System = ECS.system()
System.filter = ECS.filter("cat")
System.name = "CatAISystem"

---@param e EntityGame
function System:ai_run_away(e)
	self.world:addEntity(e)
	e.player_checked_path = {

	}
	while (true) do
		local dt = COROUTINE_YIELD()
		local player = self.world.game_world.game.level_creator.player
		--idle.human_run_away_system.lua
		while (true) do
			if (e.distance_to_player < 5) then
				local player_cell_x = math.floor(player.position.x)
				local player_cell_z = math.floor(player.position.z)
				local cell_x = math.floor(e.position.x)
				local cell_z = math.floor(e.position.z)
				if (e.player_checked_path.player_x ~= player_cell_x
						or e.player_checked_path.player_z ~= player_cell_z
						or e.player_checked_path.x ~= cell_x
						or e.player_checked_path.z ~= cell_z) then

					e.player_checked_path.player_x = player_cell_x
					e.player_checked_path.player_z = player_cell_z
					e.player_checked_path.x = cell_x
					e.player_checked_path.z = cell_z
					e.player_checked_path.path = game.pathfinding_find_path(cell_x, cell_z, player_cell_x, player_cell_z)
					if (#e.player_checked_path < 4) then
						break
					end
				end

			end
			coroutine.yield()
		end
		--player near need run away
		e.run_away = true
		e.ai.run_away_timer = 0
		self.world:addEntity(e)
		while (e.run_away) do
			e.ai.run_away_timer = e.ai.run_away_timer + coroutine.yield()
			if (e.distance_to_player < 5) then e.ai.run_away_timer = 0 end
			if (e.ai.run_away_timer > 5) then
				e.run_away = nil
				e.ai.run_away_timer = 0
				self.world:addEntity(e)
			end
		end
	end
end

---@param e EntityGame
function System:ai_random_run(e)
	while (true) do
		local target = COMMON.LUME.randomchoice(self.world.game_world.game.level_creator.level_config.spawn_cells)

		local time = 0--
		local max_time = 6 + COMMON.LUME.random(0, 4)
		e.ai.target = { position = vmath.vector3(target.x, 65, target.z) }
		while (e.ai.target and time < max_time) do
			time = time + coroutine.yield()
		end
		e.ai.target = nil
		COMMON.coroutine_wait(COMMON.LUME.random(0.1, 2.5))


	end
end

function System:init()

end

function System:onAdd(e)
	if (e.ai.ai == ENUMS.CAT_AI_TYPE.RUN_AWAY) then
		e.ai.ai_cor = coroutine.create(self.ai_run_away)
		coroutine.resume(e.ai.ai_cor, self, e)
	elseif (e.ai.ai == ENUMS.CAT_AI_TYPE.RANDOM_RUN) then
		e.ai.ai_cor = coroutine.create(self.ai_random_run)
		coroutine.resume(e.ai.ai_cor, self, e)
	elseif (e.ai.ai == ENUMS.CAT_AI_TYPE.NONE) then
		--pass
	else
		error("unknown ai:" .. e.ai.ai)
	end
end

function System:update(dt)
	local entities = self.entities

	for i = 1, #entities do
		local e = entities[i]
		if e.ai.ai_cor then
			COROUTINE_RESUME(e.ai.ai_cor, dt)
		end
	end
end

return System