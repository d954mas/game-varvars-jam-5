local COMMON = require "libs.common"

local StoragePart = require "world.storage.storage_part_base"

---@class StatsPartOptions:StoragePartBase
local Storage = COMMON.class("StatsPartOptions", StoragePart)

function Storage:initialize(...)
	StoragePart.initialize(self, ...)
	self.stats = self.storage.data.stats
end

function Storage:cat_collected()
	self.stats.cats = self.stats.cats + 1
end

return Storage