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
	e.run_away = true
	self.world:addEntity(e)
	while (true) do
		local dt = COROUTINE_YIELD()

	end
end

---@param e EntityGame
function System:ai_random_run(e)
	while (true) do
		local target = COMMON.LUME.randomchoice(self.world.game_world.game.level_creator.level_config.spawn_cells)

		local time = 0--
		local max_time = 6 + COMMON.LUME.random(0,4)
		e.ai.target = { position = vmath.vector3(target.x, 65, target.z) }
		while(e.ai.target and time<max_time) do
			time = time + coroutine.yield()
		end
		e.ai.target = nil
		COMMON.coroutine_wait(COMMON.LUME.random(0.1,2.5))


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