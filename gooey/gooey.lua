local core = require "gooey.internal.core"
local checkbox = require "gooey.internal.checkbox"
local button = require "gooey.internal.button"
local list = require "gooey.internal.list"

local M = {}


--- Check if a node is enabled. This is done by not only
-- looking at the state of the node itself but also it's
-- ancestors all the way up the hierarchy
-- @param node
-- @return true if node and all ancestors are enabled
function M.is_enabled(node)
	return core.is_enabled(node)
end


function M.create_theme()
	local theme = {}

	theme.is_enabled = function(component)
		if component.node then
			return M.is_enabled(component.node)
		end
	end

	theme.set_enabled = function(component, enabled)
		if component.node then
			gui.set_enabled(component.node, enabled)
		end
	end

	return theme
end


-- no-operation
-- empty function to use when no component callback function was provided
local function nop() end


function M.button(node_id, action_id, action, fn, refresh_fn)
	local b = button(node_id, action_id, action, fn or nop, refresh_fn)
	return b
end

function M.checkbox(node_id, action_id, action, fn, refresh_fn)
	local c = checkbox(node_id, action_id, action, fn or nop, refresh_fn)
	return c
end

function M.dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
	local l = list.dynamic(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
	return l
end


return M