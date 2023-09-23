local COMMON = require "libs.common"
local YA = require "libs.yagames.yagames"
local ACTIONS = require "libs.actions.actions"
local DEFS = require "world.balance.def.defs"

local TAG = "YAGAMES_SDK"

local Sdk = COMMON.class("YAGAMES_SDK")

---@param world World
---@param sdks Sdks
function Sdk:initialize(world, sdks)
	self.world = assert(world)
	self.sdks = assert(sdks)
	self.callback = nil
	self.context = nil
	self.is_initialized = false
	self.ya = YA
	---@type string|nil
	self.ya_storage_data = nil
	self.leaderboard_send_queue = ACTIONS.Sequence()
	self.leaderboard_send_queue.drop_empty = false
	self.subscription = COMMON.RX.SubscriptionsStorage()
	self.scheduler = COMMON.RX.CooperativeScheduler.create()

	self.is_loading_api_ready = false
end

function Sdk:loading_api_ready()
	if not self.is_loading_api_ready then
		self.is_loading_api_ready = true
		self.ya.features_loadingapi_ready()
	end
end

function Sdk:update(dt)
	self.leaderboard_send_queue:update(dt)
	self.scheduler:update(dt)
end

function Sdk:callback_save(cb)
	assert(not self.callback)
	self.callback = cb
	self.context = lua_script_instance.Get()
end

function Sdk:callback_execute(success)
	if (self.callback) then
		local ctx_id = COMMON.CONTEXT:set_context_top_by_instance(self.context)
		self.callback(success)
		COMMON.CONTEXT:remove_context_top(ctx_id)
		self.context = nil
		self.callback = nil

		if (html5) then
			html_utils.focus()
		end
	else
		COMMON.w("no callback to execute", TAG)
	end
end

function Sdk:init(cb)
	assert(yagames_private)
	YA.init(function(...)
		self.is_initialized = true
		--localization
		local locale = YA.environment().i18n.lang
		COMMON.LOCALIZATION:set_locale(locale)
		cb(...)
	end)
end

function Sdk:show_interstitial_ad(cb)
	COMMON.i("interstitial_ad show", TAG)
	if (self.callback) then
		COMMON.w("can't show already have callback")
		return
	else
		if (self.is_initialized) then
			self:callback_save(cb)
			YA.adv_show_fullscreen_adv({
				open = function()
					self.sdks:__ads_start()
				end,
				close = function(wasShown)
					self.sdks:__ads_stop()
					self:callback_execute(wasShown)
				end,
				error = function()
					--self.sdks:__ads_stop()
					--self:callback_execute(false)
				end,
				offline = function()
					--self.sdks:__ads_stop()
					--self:callback_execute(false)
				end })
		else
			if (cb) then cb(false, "not inited") end
		end

	end
end

function Sdk:sticky_banner_hide()
	self.ya.adv_get_banner_adv_status(function(_, error, status)
		if (status.stickyAdvIsShowing) then
			self.ya.adv_hide_banner_adv()
		end

	end)
end

function Sdk:sticky_banner_show()
	self.ya.adv_get_banner_adv_status(function(_, error, status)
		if (not status.stickyAdvIsShowing) then
			self.ya.adv_show_banner_adv()
		end
	end)
end

function Sdk:show_rewarded_ad(cb)
	COMMON.i("interstitial_ad show", TAG)
	if (self.callback) then
		COMMON.w("can't show already have callback")
		return
	else
		if (self.is_initialized) then
			self:callback_save(cb)
			local rewarded = false
			YA.adv_show_rewarded_video({
				open = function()
					self.sdks:__ads_start()
				end
			, rewarded = function()
					rewarded = true
				end, close = function()
					self.sdks:__ads_stop()
					self:callback_execute(rewarded)
				end, error = function()
					self.sdks:__ads_stop()
					self:callback_execute(false)
				end })
		else
			if (cb) then cb(false, "not inited") end
		end

	end
end

function Sdk:ya_save_storage()
	if (YA.player_ready) then
		print("YA SAVE DATA")
		local data = json.encode(self.world.storage.data)
		if (self.ya_storage_data ~= data) then
			print("YA UPDATE DATA")
			local send_data = {
				data = crypt.encode_base64(crypt.encrypt(data, COMMON.CONSTANTS.CRYPTO_KEY)),
				encrypted = true
			}
			YA.player_set_data({ storage = send_data }, true, function()

			end)
		else
			print("YA storage not changed")
		end

	end
end

function Sdk:ya_load_storage(cb)
	YA.player_get_data({ "storage" }, function(_, err, result)
		print("GET STORAGE")
		pprint(result)
		if (not err) then
			local level = self.world.storage.game.game.level
			if (not result.storage) then
				cb()
				return
			end

			---@type StorageData
			local ya_storage_data = result.storage
			local success = true

			if (ya_storage_data.data) then
				if (ya_storage_data.encrypted) then
					ya_storage_data = crypt.decode_base64(ya_storage_data.data)
					ya_storage_data = crypt.decrypt(ya_storage_data, COMMON.CONSTANTS.CRYPTO_KEY)
				else
					ya_storage_data = ya_storage_data.data
				end
			else
				print("bad ya storage")
				cb()
				return
			end

			success, ya_storage_data = pcall(json.decode, ya_storage_data)
			if (not success) then
				print("can't decode ya storage")
				cb()
				return
			end

			local ya_level = ya_storage_data.game.level

			print(string.format("local level:%d ", level))
			print(string.format("ya.level:%d ", ya_level))

			if (ya_level > level) then
				print("rewrite storage.More level.Use ya.")
				self.world.storage.data = ya_storage_data
				self.world.storage:save()
			end

			self.ya_storage_data = json.encode(self.world.storage.data)
		end
		COMMON.EVENT_BUS:event(COMMON.EVENTS.STORAGE_CHANGED)
		if COMMON.CONTEXT:exist(COMMON.CONTEXT.NAMES.GAME)then
			local level = self.world.game.state.level
			if level ~= self.world.storage.game:get_level() then
				print("level changed after load level")
				self.world.game:load_level(self.world.storage.game:get_level())
			end
		end
		cb()
	end)
end

function Sdk:login_player()
	print("player init")
	YA.player_init({ scopes = true }, function(_, err)
		if (err) then
			print("login_player ERROR:" .. tostring(err))
		end
		if (err == "FetchError: Unauthorized" or (YA.player_ready and YA.player_get_mode() == "lite")) then
			print("auth dialog")
			YA.auth_open_auth_dialog(function(_, err)
				print("auth dialog show")
				if (not err) then
					self:login_player()
				else
					print("auth dialog error:" .. tostring(err))
				end
			end)
		elseif (not err) then
			--load storage
			self:ya_load_storage(function()

			end)
		end
	end)
end

function Sdk:leaderboard_send_data(leaderboard_name, score, extra_data, cb)
	print("leaderboard_send_data")
	if (YA.leaderboards_ready) then
		print("leaderboard ready set score")
		YA.leaderboards_set_score(leaderboard_name, score, extra_data, cb)
	else
		YA.leaderboards_init(function(_, err)
			if (not err) then
				print("leaderboard init")
				YA.leaderboards_set_score(leaderboard_name, score, extra_data, cb)
			else
				print(err)
				cb(_, "error", { error = err })
			end
		end)
	end
end

function Sdk:leaderboard_send_stars()
	self.leaderboard_send_queue:add_action(function()
		print("leaderboard send stars")
		local stars = self.world.storage.game:stars_get()
		local delay = 5
		self:leaderboard_send_data("stars", stars, nil,
				function()
					delay = 1
				end)
		while (delay > 0) do delay = delay - coroutine.yield() end
	end)
end

function Sdk:leaderboard_init_send()
	self:leaderboard_send_stars()
end


return Sdk