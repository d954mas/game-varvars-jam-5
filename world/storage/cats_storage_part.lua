local COMMON = require "libs.common"
local DEFS = require "world.balance.def.defs"
local ENUMS = require "world.enums.enums"

local StoragePart = require "world.storage.storage_part_base"

---@class CatsPartOptions:StoragePartBase
local Storage = COMMON.class("CatsPartOptions", StoragePart)

function Storage:initialize(...)
	StoragePart.initialize(self, ...)
	self.cats = self.storage.data.cats
end

function Storage:is_collected(id)
	return self.cats[id].collected
end

function Storage:collected(id)
	if not self.cats[id].collected then
		self.cats[id].collected = true
		self:save_and_changed()
	end
end

function Storage:is_look_at_book(id)
	return self.cats[id].look_at_book
end

function Storage:look_at_book(id)
	if not self.cats[id].look_at_book then
		self.cats[id].look_at_book = true
		self:save_and_changed()
	end
end


return Storage