local COMMON = require "libs.common"
local INPUT = require "libs.input_receiver"
local TAG = "SDK"

---@class Sdks
local Sdk = COMMON.class("Sdk")

---@param world World
function Sdk:initialize(world)
	checks("?", "class:World")
	self.world = world
	self.is_poki = COMMON.CONSTANTS.TARGET_IS_POKI or poki_sdk
	self.data = {
		gameplay_start = false,
		prev_rewarded = 0
	}
end

function Sdk:init(cb)
	cb()
end

function Sdk:gameplay_start()
	if (not self.data.gameplay_start) then
		COMMON.i("gameplay start", TAG)
		self.data.gameplay_start = true
		if (self.is_poki) then
			poki_sdk.gameplay_start()
		end
	end
end

function Sdk:gameplay_stop()
	if (self.data.gameplay_start) then
		COMMON.i("gameplay stop", TAG)
		self.data.gameplay_start = false
		if (self.is_poki) then
			poki_sdk.gameplay_stop()
		end
	end
end

function Sdk:__ads_start()
--	self:gameplay_stop()
	self.world.sounds:pause()
	INPUT.IGNORE = true
end

function Sdk:__ads_stop()
	self.world.sounds:resume()
	INPUT.IGNORE = false
	if html_utils then
		html_utils.focus()
	end
end

function Sdk:ads_rewarded(cb)
	print("ads_rewarded")

	if (self.is_poki) then
		self:__ads_start()
		poki_sdk.rewarded_break(function(_, success)
			print("ads_rewarded success:" .. tostring(success))
			self:__ads_stop()
			if (success) then
				self.data.prev_rewarded = socket.gettime()
			end
			if (cb) then cb(success) end
		end)
	elseif (COMMON.CONSTANTS.TARGET_IS_PLAY_MARKET) then
		self.admob:show_rewarded_ad(cb)
	else
		self.data.prev_rewarded = socket.gettime()
		self:__ads_start()
		self:__ads_stop()
		if (cb) then cb(true) end
	end
end

function Sdk:preload_ads()
	if (COMMON.CONSTANTS.PLATFORM_IS_ANDROID) then
		self.admob:rewarded_load()
	end
end

function Sdk:ads_commercial(cb)
	print("ads_commercial")
	--local dt = socket.gettime()-self.data.prev_rewarded
	--if(dt<4*60)then
	--	print("skip commercial user see rewarded")
	--	if(cb)then cb() end
	--	return
	--end

	if (self.is_poki) then
		self:__ads_start()
		poki_sdk.commercial_break(function(_)
			self:__ads_stop()
			if (cb) then cb() end
		end)
	elseif (COMMON.CONSTANTS.TARGET_IS_PLAY_MARKET) then
		self.admob:show_interstitial_ad(cb)
	else
		self:__ads_start()
		self:__ads_stop()
		if (cb) then cb() end
	end
end

return Sdk
