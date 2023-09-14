local COMMON = require "libs.common"
local ACTIONS = require "libs.actions.actions"
local TWEEN = require "libs.tween"

local COLOR_INVISIBLE = vmath.vector4(1, 1, 1, 0)
local COLOR_WHITE = vmath.vector4(1, 1, 1, 1)

--@class FlyObjectGui
local FlyObject = COMMON.class("FlyObject")

function FlyObject:initialize(nodes)
	self.vh = {
		root = nodes["root"],
		icon = nodes["icon"],
	}
	self.action = ACTIONS.Sequence()
end

function FlyObject:fly(config)
	gui.set_screen_position(self.vh.root, assert(config.from))
	local gui_pos_x, gui_pos_y = config.from.x, config.from.y

	local target = config.to
	local target_gui_x, target_gui_y = target.x, target.y

	local dx = target_gui_x - gui_pos_x
	local dy = target_gui_y - gui_pos_y



	local tween_table = { dx = 0, dy = 0 }

	local dx_time = math.abs(dx / config.speed_x or 500)
	local dy_time = math.abs(dy / config.speed_y or 500)


	local time = math.max(dx_time, dy_time)
	local tween_x = ACTIONS.TweenTable { delay = 0.1, object = tween_table, property = "dx", from = { dx = 0 },
										 to = { dx = dx }, time = time, easing = TWEEN.easing.linear }
	local tween_y = ACTIONS.TweenTable { delay = 0.1, object = tween_table, property = "dy", from = { dy = 0 },
										 to = { dy = dy }, time = time + 0.1, easing = TWEEN.easing.outQuad }
	local move_action = ACTIONS.Parallel()
	move_action:add_action(tween_x)
	move_action:add_action(tween_y)
	move_action:add_action(function()
		local v3 = vmath.vector3()
		while (tween_table.dx ~= dx and tween_table.dy ~= dy) do
			v3.x = gui_pos_x + tween_table.dx
			v3.y = gui_pos_y + tween_table.dy
			gui.set_screen_position(self.vh.root, v3)
			coroutine.yield()
		end
		gui.set_screen_position(self.vh.root, config.to)
	end)

	if (config.delay) then
		self.action:add_action(ACTIONS.Wait { time = config.delay })
	end

	self.action:add_action(function()
		gui.set_enabled(self.vh.root, true)
	end)
	local action_appear = ACTIONS.Parallel()
	if (config.appear) then
		gui.set_color(self.vh.root, vmath.vector4(1, 1, 1, 0))
		local tint = ACTIONS.TweenGui { object = self.vh.root, property = "color", v4 = true,
										from = COLOR_INVISIBLE, to = COLOR_WHITE, time = 0.15,
										easing = TWEEN.easing.inQuad }
		action_appear:add_action(tint)
		local sequenceAction = ACTIONS.Sequence()
		sequenceAction:add_action(ACTIONS.Wait { time = 0.1 })
		sequenceAction:add_action(move_action)
		action_appear:add_action(sequenceAction)
	else
		action_appear:add_action(move_action)
	end

	self.action:add_action(action_appear)
	self.action:add_action(function()
		if (config.cb) then
			config.cb()
		end
		COMMON.coroutine_wait(0.1)
		gui.delete_node(self.vh.root)
		self.vh = nil
	end)
end

function FlyObject:update(dt)
	self.action:update(dt)
end

function FlyObject:is_animated()
	return self.action:is_running()
end

return FlyObject