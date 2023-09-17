local ECS = require 'libs.ecs'
local COMMON = require "libs.common"


---@class LevelCompletedSystem:ECSSystem
local System = ECS.system()
System.name = "WaterMoveSystem"

function System:init()
	self.cor = coroutine.create(function()
		while(self.world.game_world.game.state.cats_collected<self.world.game_world.game.level_creator.level_config.cats)do
			coroutine.yield()
		end
		COMMON.coroutine_wait(0.5)
		local win_fx = self.world.game_world.game.level_creator.player.player_go.particles.win_fx
		particlefx.play(win_fx)
		self.world.game_world.sounds:play_sound(self.world.game_world.sounds.sounds.win)
		self.world.game_world.game.state.completed = true
		COMMON.coroutine_wait(3)
		--change level
		self.world.game_world.storage.game:level_completed()
		self.world.game_world.game:load_level(self.world.game_world.storage.game:get_level())
	end)
end

---@param e EntityGame
function System:update(dt)
	COMMON.coroutine_resume(self.cor,dt)
end

return System