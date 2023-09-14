local ECS = require 'libs.ecs'
local COMMON = require "libs.common"

---@class PlayerStepSoundSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("player")
System.name = "PlayerStepSoundSystem"

---@param self PlayerStepSoundSystem
---@param player EntityGame
local function cor_sound(self, player)
	while (true) do
		while (not player.moving or not player.on_ground) do coroutine.yield() end
		self.world.game_world.sounds:play_step_sound()
		local time = 0
		while (time < 0.4) do
			local dt = coroutine.yield()
			time = time + dt --* player.movement.max_speed / DEFS.HERO.STATS.BASE_SPEED
		end
	end
end


function System:onAdd(e)
	e.speed_sound_cor = coroutine.create(cor_sound)
	COMMON.coroutine_resume(e.speed_sound_cor, self, e)
end

---@param e EntityGame
function System:process(e, dt)
	COMMON.coroutine_resume(e.speed_sound_cor, dt)
end

return System