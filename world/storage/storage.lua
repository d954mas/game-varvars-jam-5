local COMMON = require "libs.common"
local CONSTANTS = require "libs.constants"
local JSON = require "libs.json"
local DEFS = require "world.balance.def.defs"
local OptionsStoragePart = require "world.storage.options_storage_part"
local DebugStoragePart = require "world.storage.debug_storage_part"
local GameStoragePart = require "world.storage.game_storage_part"

local TAG = "Storage"

---@class Storage
local Storage = COMMON.class("Storage")

Storage.FILE_PATH = "d954mas_varvar5"
Storage.VERSION = 30
Storage.AUTOSAVE = 90 --seconds
Storage.CLEAR = CONSTANTS.VERSION_IS_DEV and false --BE CAREFUL. Do not use in prod
Storage.LOCAL = CONSTANTS.VERSION_IS_DEV and CONSTANTS.PLATFORM_IS_PC
		and CONSTANTS.TARGET_IS_EDITOR  --BE CAREFUL. Do not use in prod

---@param world World
function Storage:initialize(world)
	checks("?", "class:World")
	self.world = world
	local status, error = pcall(self._load_storage, self)
	if (not status) then
		COMMON.i("error load storage:" .. tostring(error), TAG)
		self:_init_storage()
		self:_migration()
		self:_on_load()
		self:save(true)
	end
	self.prev_save_time = socket.gettime()
	self.save_on_update = false

	self:update_data()
end

function Storage:update_data()
	self.options = OptionsStoragePart(self)
	self.debug = DebugStoragePart(self)
	self.game = GameStoragePart(self)

end

function Storage:changed()
	self.change_flag = true
end

function Storage:_get_path()
	if (Storage.LOCAL) then
		return "./" .. "storage.json"
	end
	local path = Storage.FILE_PATH
	if (CONSTANTS.VERSION_IS_DEV) then
		path = path .. "_dev"
	end
	if (html5) then
		return path
	end
	return sys.get_save_file(path, "storage.json")
end

function Storage:_load_storage()
	local path = self:_get_path()
	local data = nil
	if (Storage.CLEAR) then
		COMMON.i("clear storage", TAG)
	else
		if (html5) then
			local html_data = html5.run([[(function(){try{return window.localStorage.getItem(']] .. path .. [[')||'{}'}catch(e){return'{}'}})()]])
			if (not html_data or html_data == "{}" or html_data == "nil") then
				COMMON.i("html5 data. Empty or error:" .. tostring(html_data), TAG)
			else
				COMMON.i("html5 data:" .. tostring(html_data), TAG)
				local status_json, file_data = pcall(JSON.decode, html_data)
				if (not status_json) then
					COMMON.i("can't parse json:" .. tostring(file_data), TAG)
				else
					data = file_data
				end
			end


		else
			local status, file = pcall(io.open, path, "r")
			if (not status) then
				COMMON.i("can't open file:" .. tostring(file), TAG)
			else
				if (file) then
					COMMON.i("load", TAG)
					local contents, read_err = file:read("*a")
					if (not contents) then
						COMMON.i("can't read file:\n" .. read_err, TAG)
					else
						COMMON.i("from file:\n" .. contents, TAG)
						local status_json, file_data = pcall(JSON.decode, contents)
						if (not status_json) then
							COMMON.i("can't parse json:" .. tostring(file_data), TAG)
						else
							data = file_data
						end
					end
					file:close()
				else
					COMMON.i("no file", TAG)
				end
			end
		end
	end

	if (data) then
		if (data.encrypted) then
			data.data = crypt.decode_base64(data.data)
			data = crypt.decrypt(data.data, CONSTANTS.CRYPTO_KEY)
		else
			data = data.data
		end

		local result, storage = pcall(JSON.decode, data)
		if (result) then
			self.data = assert(storage)
		else
			COMMON.i("can't parse json:" .. tostring(storage), TAG)
			self:_init_storage()
		end
		COMMON.i("data:\n" .. tostring(data), TAG)
	else
		COMMON.i("no data.Init storage", TAG)
		self:_init_storage()
	end

	self:_migration()
	self:_on_load()
	self:save(true)
	COMMON.i("loaded", TAG)
end

function Storage:update(dt)
	self.game.game.last_time = socket.gettime()

	if (self.change_flag) then
		self.world:on_storage_changed()
		COMMON.EVENT_BUS:event(COMMON.EVENTS.STORAGE_CHANGED)
		self.change_flag = false
	end
	if (self.save_on_update) then
		self:save(true)
	end
	if (Storage.AUTOSAVE and Storage.AUTOSAVE ~= -1) then
		if (socket.gettime() - self.prev_save_time > Storage.AUTOSAVE) then
			COMMON.i("autosave", TAG)
			self:save(true)
		end
	end

end

function Storage:_init_storage()
	COMMON.i("init new", TAG)
	---@class StorageData
	local data = {
		debug = {
			draw_debug_info = true,
			draw_chunk_vertices = false,
			draw_chunk_frustum = false,
			draw_chunk_borders = false,
			draw_frustum_box = false,
			draw_interact_aabb = false,
			draw_physics = false,
		},
		options = {
			sound = true,
			music = true,
			draw_shadows = not html5 or not COMMON.is_mobile()
		},
		game = {
			level = 1
		},
		version = Storage.VERSION
	}

	self.data = data
	self:init_defs_data()
end

function Storage:init_defs_data()

end

function Storage:reset()
	self:_init_storage()
	self:update_data()
	self:__save()
	self:changed()
end

function Storage:_migration()
	self:init_defs_data()
	if (self.data.version < Storage.VERSION) then
		COMMON.i(string.format("migrate from:%s to %s", self.data.version, Storage.VERSION), TAG)

		if (self.data.version < 30) then
			self:_init_storage()
		end


		self.data.version = Storage.VERSION
	end
end

function Storage:_on_load()

end

function Storage:__save()
	local time = socket.gettime()
	local data = {
		data = JSON.encode(self.data),
	}
	data.encrypted = not Storage.LOCAL

	if (data.encrypted) then
		data.data = crypt.encrypt(data.data, CONSTANTS.CRYPTO_KEY)
		data.data = crypt.encode_base64(data.data)
	end

	local encoded_data = JSON.encode(data, false)
	encoded_data:gsub("'", "\'") -- escape ' character

	if (html5) then
		html5.run("try{window.localStorage.setItem('" .. self:_get_path() .. "', '" .. encoded_data .. "')}catch(e){}")
	else
		local file = io.open(self:_get_path(), "w+")
		file:write(encoded_data)
		file:close()
	end
	print("save time:" .. (socket.gettime() - time))
end

function Storage:save(force)
	if (force) then
		COMMON.i("save", TAG)
		self.prev_save_time = socket.gettime()
		local status, error = pcall(self.__save, self)
		if (not status) then
			COMMON.i("error save storage:" .. tostring(error), TAG)
		end
		self.save_on_update = false
		COMMON.EVENT_BUS:event(COMMON.EVENTS.STORAGE_SAVED)
	else
		self.save_on_update = true
	end
end

return Storage

