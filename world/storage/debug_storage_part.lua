local COMMON = require "libs.common"
local StoragePart = require "world.storage.storage_part_base"

---@class DebugStoragePart:StoragePartBase
local Debug = COMMON.class("DebugStoragePart", StoragePart)

function Debug:initialize(...)
	StoragePart.initialize(self, ...)
	self.debug = self.storage.data.debug
end

function Debug:draw_debug_info_is() return self.debug.draw_debug_info end
function Debug:draw_debug_info_set(enable)
	if (self.debug.draw_debug_info ~= enable) then
		self.debug.draw_debug_info = enable
		self:save_and_changed()
	end
end

function Debug:draw_chunk_vertices_is() return self.debug.draw_chunk_vertices end
function Debug:draw_chunk_vertices_set(enable)
	if (self.debug.draw_chunk_vertices ~= enable) then
		self.debug.draw_chunk_vertices = enable
		self:save_and_changed()
	end
end

function Debug:draw_chunk_frustum_is() return self.debug.draw_chunk_frustum end
function Debug:draw_chunk_frustum_set(enable)
	if (self.debug.draw_chunk_frustum ~= enable) then
		self.debug.draw_chunk_frustum = enable
		self:save_and_changed()
	end
end

function Debug:draw_chunk_borders_is() return self.debug.draw_chunk_borders end
function Debug:draw_chunk_borders_set(enable)
	if (self.debug.draw_chunk_borders ~= enable) then
		self.debug.draw_chunk_borders = enable
		self:save_and_changed()
	end
end

function Debug:draw_frustum_box_is() return self.debug.draw_frustum_box end
function Debug:draw_frustum_box_set(enable)
	if (self.debug.draw_frustum_box ~= enable) then
		self.debug.draw_frustum_box = enable
		self:save_and_changed()
	end
end

function Debug:draw_interact_aabb_is() return self.debug.draw_interact_aabb end
function Debug:draw_interact_aabb_set(enable)
	if (self.debug.draw_interact_aabb ~= enable) then
		self.debug.draw_interact_aabb = enable
		self:save_and_changed()
	end
end

function Debug:draw_physics_is() return self.debug.draw_physics end
function Debug:draw_physics_set(enable)
	if (self.debug.draw_physics ~= enable) then
		self.debug.draw_physics = enable
		self:save_and_changed()
	end
end

function Debug:draw_path_cells_is() return self.debug.draw_path_cells end
function Debug:draw_path_cells_set(enable)
	if (self.debug.draw_path_cells ~= enable) then
		self.debug.draw_path_cells = enable
		self:save_and_changed()
	end
end


function Debug:draw_path_is() return self.debug.draw_path end
function Debug:draw_path_set(enable)
	if (self.debug.draw_path ~= enable) then
		self.debug.draw_path = enable
		self:save_and_changed()
	end
end

return Debug