local COMMON = require "libs.common"
local ButtonScale = require "libs_project.gui.button_scale"

local View = COMMON.class("VoxelPosView")

function View:initialize(root_name, position)
	self.root_name = assert(root_name)
	self.position = assert(position)

	self.vh = {
		root = gui.get_node(root_name .. "/root"),
		lbl = gui.get_node(root_name .. "/lbl"),
	}


	self.views = {
		btn_x_up = ButtonScale(self.root_name .. "/x_up"),
		btn_x_down = ButtonScale(self.root_name .. "/x_down"),
		btn_y_up = ButtonScale(self.root_name .. "/y_up"),
		btn_y_down = ButtonScale(self.root_name .. "/y_down"),
		btn_z_up = ButtonScale(self.root_name .. "/z_up"),
		btn_z_down = ButtonScale(self.root_name .. "/z_down"),
	}

	self.views.btn_x_up:set_input_listener(function() self.position.x = self.position.x + 1 end)
	self.views.btn_x_down:set_input_listener(function() self.position.x = self.position.x - 1 end)
	self.views.btn_y_up:set_input_listener(function() self.position.y = self.position.y + 1 end)
	self.views.btn_y_down:set_input_listener(function() self.position.y = self.position.y - 1 end)
	self.views.btn_z_up:set_input_listener(function() self.position.z = self.position.z + 1 end)
	self.views.btn_z_down:set_input_listener(function() self.position.z = self.position.z - 1 end)
end


function View:update(dt)
	gui.set_text(self.vh.lbl,string.format("(%.1f %.1f %.1f)",self.position.x,self.position.y,self.position.z))
end

function View:on_input(action_id, action)
	if (self.views.btn_x_up:on_input(action_id, action)) then return true end
	if (self.views.btn_x_down:on_input(action_id, action)) then return true end
	if (self.views.btn_y_up:on_input(action_id, action)) then return true end
	if (self.views.btn_y_down:on_input(action_id, action)) then return true end
	if (self.views.btn_z_up:on_input(action_id, action)) then return true end
	if (self.views.btn_z_down:on_input(action_id, action)) then return true end
end

return View