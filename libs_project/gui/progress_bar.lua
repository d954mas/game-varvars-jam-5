local COMMON = require "libs.common"
local SmoothDump = require "libs.smooth_dump"

---@class ProgressBar
local Bar = COMMON.class("Bar")

function Bar:initialize(vh)
	self.vh = {
		root = assert(vh.root),
		bg = assert(vh.bg),
		progress = assert(vh.progress),
		--center = gui.get_node(root_name .. "/center"),
		lbl = vh.lbl
	}
	self.smooth_dump = SmoothDump.new()
	self.smooth_dump.maxSpeed = 3
	self.smooth_dump.smoothTime = 0.15

	self.value_max = 100
	--self.value = 0

	self.nine_texture_size = gui.get_slice9(self.vh.progress)
	self.nine_texture_size_origin = gui.get_slice9(self.vh.progress)
	self.nine_texture_size_max = self.nine_texture_size_origin.x + self.nine_texture_size_origin.z
	self.animation = {
		value = 0,
	}
	self.size = gui.get_size(self.vh.progress)
	self.progress_width_max = self.size.x

	self:set_value(0)
	self.size.x = 0--gui_update
	self:gui_update()

	self.position = gui.get_position(self.vh.root)
end

function Bar:set_value_max(value)
	assert(value > 0)
	self.value_max = value
	self:gui_update()
end

function Bar:update(dt)
	if (self.animation.value ~= self.value) then
		local a = self.animation.value / self.value_max
		local b = self.value / self.value_max
		local r = self.smooth_dump:update(a, b, dt)
		self.animation.value = self.value_max * r
		self:gui_update()
	end
end

function Bar:lbl_format_value()
	local f = self.animation.value > self.value_max / 2 and math.ceil or math.floor
	return (f(self.animation.value) .. "/" .. self.value_max)
end

function Bar:gui_update()
	local size = math.floor(self.progress_width_max * self.animation.value / self.value_max)
	if self.vh.lbl then gui.set_text(self.vh.lbl, self:lbl_format_value()) end
	if (self.size.x == size) then
		return
	end
	self.size.x = size

	if (size == 0) then
		if (not self.progress_disabled) then
			self.progress_disabled = true
			gui.set_enabled(self.vh.progress, false)
		end
	elseif (size < self.nine_texture_size_max) then
		local delta = (self.nine_texture_size_max - size) / 2
		local nx = self.nine_texture_size_origin.x - delta
		local nz = self.nine_texture_size_origin.z - delta
		if (nz < 0) then
			nz = 0
		end
		if (nx < 0) then
			nx = 0
		end

		if (nx ~= self.nine_texture_size.x or nz ~= self.nine_texture_size.z) then
			self.nine_texture_size.x = nx
			self.nine_texture_size.z = nz
			gui.set_slice9(self.vh.progress, self.nine_texture_size)
		end
	else
		if (self.nine_texture_size.x ~= self.nine_texture_size_origin.x or self.nine_texture_size.z ~= self.nine_texture_size_origin.z) then
			self.nine_texture_size.x = self.nine_texture_size_origin.x
			self.nine_texture_size.z = self.nine_texture_size_origin.z
			gui.set_slice9(self.vh.progress, self.nine_texture_size)
		end
	end

	if (size ~= 0 and self.progress_disabled) then
		self.progress_disabled = nil
		gui.set_enabled(self.vh.progress, true)
	end

	gui.set_size(self.vh.progress, self.size)
end

function Bar:set_enabled(enabled)
	gui.set_enabled(self.vh.root, enabled)
end

function Bar:set_value(value, force)
	if (self.value == value) then return end
	self.value = COMMON.LUME.clamp(value, 0, self.value_max)
	if (force) then
		self.animation.value = self.value
	end
	self:gui_update()
end

function Bar:set_position(position)
	self.position.x, self.position.y, self.position.z = position.x, position.y, position.z
	gui.set_position(self.vh.root, self.position)
end

function Bar:destroy()
	gui.delete_node(self.vh.root)
	self.vh = nil
end

return Bar