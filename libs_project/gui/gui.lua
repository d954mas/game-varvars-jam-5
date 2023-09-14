local M = {}
M.ButtonIconTest = require "libs_project.gui.button_icon_text"
M.ButtonScale = require "libs_project.gui.button_scale"
M.Button1 = require "libs_project.gui.button_1"
M.CheckboxWithLabel = require "libs_project.gui.checkbox_with_label"
M.ProgressBar = require "libs_project.gui.progress_bar"
M.Tumbler = require "libs_project.gui.tumbler"

local ACTIONS = require "libs.actions.actions"
local TWEEN = require "libs.tween"
local COMMON = require "libs.common"
local COLORS = COMMON.CONSTANTS.COLORS


function M.set_nodes_to_center(l_node, is_l_node_text, r_node, is_r_node_text, delta)
	if delta == nil then delta = 0 end

	local l_size_x = (is_l_node_text and gui.get_text_metrics_from_node(l_node).width or gui.get_size(l_node).x) * gui.get_scale(l_node).x
	local r_size_x = (is_r_node_text and gui.get_text_metrics_from_node(r_node).width or gui.get_size(r_node).x) * gui.get_scale(r_node).x
	local l_pivot = gui.get_pivot(l_node)
	local r_pivot = gui.get_pivot(r_node)
	local l_pos = gui.get_position(l_node)
	local r_pos = gui.get_position(r_node)

	local text_length = l_size_x + r_size_x + delta
	local l_dx = (text_length / 2) - l_size_x
	local r_dx = (text_length / 2) - r_size_x

	l_pos.x = -l_dx
	if l_pivot == gui.PIVOT_W or l_pivot == gui.PIVOT_NW or l_pivot == gui.PIVOT_SW then
		l_pos.x = l_pos.x - l_size_x
	elseif l_pivot == gui.PIVOT_CENTER then
		l_pos.x = l_pos.x - l_size_x / 2
	end
	r_pos.x = r_dx
	if r_pivot == gui.PIVOT_E or r_pivot == gui.PIVOT_NE or r_pivot == gui.PIVOT_SE then
		r_pos.x = r_pos.x + r_size_x
	elseif r_pivot == gui.PIVOT_CENTER then
		r_pos.x = r_pos.x + r_size_x / 2
	end

	gui.set_position(l_node, l_pos)
	gui.set_position(r_node, r_pos)
	return text_length, l_pos, r_pos, l_size_x, r_size_x
end

function M.autosize_text(node, scale, text)
	local metrics = resource.get_text_metrics(gui.get_font_resource(gui.get_font(node)), tostring(text))
	local size = gui.get_size(node).x
	if (metrics.width > size) then
		local new_scale = scale * size / metrics.width
		gui.set_scale(node, vmath.vector3(new_scale))
	else
		gui.set_scale(node, vmath.vector3(scale))
	end
	gui.set_text(node, text)
end

---@param self BuildSceneGuiScript
function M.window_show_animation(self)
	assert(self.animation_action)
	assert(self.fader_color)
	assert(self.vh)
	assert(self.vh.fader)
	assert(self.vh.root)

	while (not self.animation_action:is_empty()) do self.animation_action:update(1) end

	local start_color = vmath.vector4(self.fader_color)
	start_color.w = 0.3
	gui.set_color(self.vh.fader, start_color)

	gui.set_color(self.vh.root, COLORS.EMPTY)
	gui.set_scale(self.vh.root, vmath.vector4(0.01))

	local show_parallel = ACTIONS.Parallel()

	show_parallel:add_action(ACTIONS.TweenGui {
		object = self.vh.fader, property = "color", v4 = true,
		to = self.fader_color, time = 0.1, easing = TWEEN.easing.outCubic
	})

	show_parallel:add_action(ACTIONS.TweenGui {
		object = self.vh.root, property = "color", v4 = true,
		to = COLORS.WHITE, time = 0.2, easing = TWEEN.easing.outCubic, delay = 0
	})
	show_parallel:add_action(ACTIONS.TweenGui {
		object = self.vh.root, property = "scale", v3 = true,
		from = vmath.vector3(0.01), to = vmath.vector3(1), time = 0.5, easing = TWEEN.easing.outBack, delay = 0.05
	})

	self.animation_action:add_action(show_parallel)
end


function M.window_hide_animation(self)
	assert(self.animation_action)
	assert(self.fader_color)
	assert(self.vh)
	assert(self.vh.fader)
	assert(self.vh.root)
	while (not self.animation_action:is_empty()) do self.animation_action:update(1) end
	local start_color = vmath.vector4(self.fader_color)
	start_color.w = 0
	local show_parallel = ACTIONS.Parallel()

	show_parallel:add_action(ACTIONS.TweenGui {
		object = self.vh.fader, property = "color", v4 = true,
		to = start_color, time = 0.25, easing = TWEEN.easing.outCubic, delay = 0.1
	})

	show_parallel:add_action(ACTIONS.TweenGui {
		object = self.vh.root, property = "color", v4 = true,
		to = COLORS.EMPTY, time = 0.3, easing = TWEEN.easing.outQuad, delay = 0
	})
	show_parallel:add_action(ACTIONS.TweenGui {
		object = self.vh.root, property = "scale", v3 = true,
		from = vmath.vector3(1), to = vmath.vector3(0.01), time = 0.2, easing = TWEEN.easing.outQuad, delay = 0
	})


	self.animation_action:add_action(show_parallel)
end

return M