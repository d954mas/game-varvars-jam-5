local COMMON = require "libs.common"
local DEFS = require "world.balance.def.defs"
local ENUMS = require "world.enums.enums"

local StoragePart = require "world.storage.storage_part_base"

---@class GamePartOptions:StoragePartBase
local Storage = COMMON.class("GamePartOptions", StoragePart)

function Storage:initialize(...)
	StoragePart.initialize(self, ...)
	self.game = self.storage.data.game
end

function Storage:get_level()
	return self.game.level
end

function Storage:level_completed()
	self.game.level = self.game.level + 1
	self:save_and_changed()
end

return Storage