local ECS = require 'libs.ecs'

---@class AutoDestroySystem:ECSSystem
local System = ECS.system()
System.filter = ECS.filter("auto_destroy|auto_destroy_delay")
System.name = "AutoDestroySystem"

function System:init()

end

function System:update(dt)
	local entities = self.entities
	for i=1,#entities do
		local e = entities[i]
		if e.auto_destroy_delay then
			e.auto_destroy_delay = e.auto_destroy_delay - dt
			if e.auto_destroy_delay <= 0 then
				e.auto_destroy = true
			end
		end
		if e.auto_destroy then
			self.world:removeEntity(e)
		end
	end
	self.world:refresh()
end


return System