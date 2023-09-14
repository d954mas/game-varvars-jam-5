local ECS = require 'libs.ecs'
---@class ActionsUpdateSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("actions|action_scale_init")
System.name = "ActionsUpdateSystem"

---@param e EntityGame
function System:process(e, dt)
    local i=1
    if(e.actions)then
        local len = #e.actions
        while(i<=len)do
            local action = e.actions[i]
            action:update(dt)
            if(action:is_finished())then
                table.remove(e.actions,i)
                i=i-1
                len = len-1
            end
            i = i + 1
        end
    end
    if(e.action_scale_init)then
        e.action_scale_init:update(dt)
        if(e.action_scale_init:is_finished())then
            e.action_scale_init = nil
            self.world:addEntity(e)
        end
    end

end

return System