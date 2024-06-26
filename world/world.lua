local COMMON = require "libs.common"
local Storage = require "world.storage.storage"
local GameWorld = require "world.game.game_world"
local Sdk = require "libs.sdk.sdk"
local Sounds = require "libs.sounds"
local Balance = require "world.balance.balance"
local Tasks = require "world.game.tasks"

local TAG = "WORLD"
---@class World
local M = COMMON.class("World")

function M:initialize()
	COMMON.i("init", TAG)
	self.storage = Storage(self)
	self.game = GameWorld(self)
	self.sdk = Sdk(self)
	self.sounds = Sounds(self)
	self.balance = Balance(self)
	self.tasks = Tasks(self)
	self.time = 0
	---@type SceneManager
	self.sm = nil
end

function M:update(dt)
	self.sounds:update(dt)
	self.sm:update(dt)
	self.storage:update(dt)
	self.time = self.time + dt
	self.game:update_always(dt)
end

function M:on_storage_changed()

end

function M:final()

end

return M()