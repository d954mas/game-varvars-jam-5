local COMMON = require "libs.common"
local ECS = require 'libs.ecs'
local ENUMS = require 'world.enums.enums'
local DEFS = require "world.balance.def.defs"

local ENABLE = hash("enable")
local DISABLE = hash("disable")



---@class DrawCatSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("cat")
System.name = "DrawCatSystem"

---@param e EntityGame
function System:get_animation(e)
	if (e.moving) then
		return ENUMS.ANIMATIONS.RUN
	end
	return ENUMS.ANIMATIONS.IDLE
end

---@param e EntityGame
function System:onAdd(e)

end

---@param e EntityGame
function System:process(e, dt)

	local anim = self:get_animation(e)

	go.set_rotation(self.world.game_world.game.level_creator.player.camera.rotation,e.cat_go.sprite.root)

	--go.set_position(e.position, e.player_go.root)




end

return System