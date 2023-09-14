local ECS = require 'libs.ecs'

---@class RemoveInvisibleObjectsSystem:ECSSystem
local System = ECS.system()
System.filter = ECS.filter("invisible_timer&frustum_native")
System.name = "RemoveInvisibleObjectsSystem"

---@param e EntityGame
function System:update(dt)
	local entities = self.entities
	for i = 1, #entities do
		local e = entities[i]

		if (e.ai and e.ai.in_battle) then
			e.invisible_timer.current = 0
		end

		if (e.frustum_native:IsVisible()) then
			e.invisible_timer.current = 0
		else
			e.invisible_timer.current = e.invisible_timer.current + dt
			if (e.invisible_timer.current >= e.invisible_timer.max) then
				e.auto_destroy = true
				self.world:addEntity(e)
			end
		end
	end


end

return System