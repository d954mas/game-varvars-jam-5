local COMMON = require "libs.common"
local ButtonScale = require "libs_project.gui.button_scale"

local IMAGE_DISABLE = hash("btn_disable")

---@class Btn1
local Btn = COMMON.class("Btn1",ButtonScale)

function Btn:initialize(root_name, path)
	ButtonScale.initialize(self,root_name, path)
	self.vh.bg =  gui.get_node(root_name .. "/bg")
	self.bg_image = gui.get_flipbook(self.vh.bg)
end

function Btn:set_ignore_input(ignore)
	ButtonScale.set_ignore_input(self,ignore)
	gui.play_flipbook(self.vh.bg,ignore and IMAGE_DISABLE or self.bg_image)
end


return Btn