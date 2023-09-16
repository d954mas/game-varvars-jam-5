local I18N = require "libs.i18n.init"
local LOG = require "libs.log"
local CONSTANTS = require "libs.constants"
local TAG = "LOCALIZATION"
local LUME = require "libs.lume"
local LOCALES = { "en" }
local DEFAULT = CONSTANTS.LOCALIZATION.DEFAULT
local FALLBACK = DEFAULT

local ct

---@class Localization
local M = {
	CATS_BOOK_title = { en = "CATS BOOK" },

	--region cats
	cat_CAT_1_name = { en = "Whiskers" },
	cat_CAT_1_description = { en = "Curious and playful, Whiskers loves to explore" },
	cat_CAT_2_name = { en = "Luna" },
	cat_CAT_2_description = { en = "Mysterious and elegant cat." },
	cat_CAT_3_name = { en = "Bella" },
	cat_CAT_3_description = { en = "Graceful and affectionate cat who loves cuddling." },
	cat_CAT_4_name = { en = "Simba" },
	cat_CAT_4_description = { en = "Brave and adventurous, Simba is a wild at heart." },
	cat_CAT_5_name = { en = "Oliver" },
	cat_CAT_5_description = { en = "Mischievous cat who can find his way into all sorts of trouble." },
	cat_CAT_6_name = { en = "Cleo" },
	cat_CAT_6_description = { en = "Regal and dignified, carries herself with poise." },
	cat_CAT_7_name = { en = "Jasper" },
	cat_CAT_7_description = { en = "Easygoing cat who enjoys lounging in the sun." },
	cat_CAT_8_name = { en = "Nala" },
	cat_CAT_8_description = { en = "Sweet and gentle cat who is everyone's favorite lap warmer." },
	cat_CAT_9_name = { en = "Felix" },
	cat_CAT_9_description = { en = "Calm and sleepy, ready to rest.A picture of relaxation." },
	cat_CAT_10_name = { en = "Gizmo" },
	cat_CAT_10_description = { en = "Playful and inquisitive, loves to investigate." },
	--endregion
}

function M:locale_exist(key)
	local locale = self[key]
	if not locale then
		LOG.w("key:" .. key .. " not found", TAG, 2)
	end
end

function M:set_locale(locale)
	LOG.w("set locale:" .. locale, TAG)
	I18N.setLocale(locale)
end

function M:locale_get()
	return I18N.getLocale()
end

I18N.setFallbackLocale(FALLBACK)
M:set_locale(DEFAULT)
if (CONSTANTS.LOCALIZATION.FORCE_LOCALE) then
	LOG.i("force locale:" .. CONSTANTS.LOCALIZATION.FORCE_LOCALE, TAG)
	M:set_locale(CONSTANTS.LOCALIZATION.FORCE_LOCALE)
elseif (CONSTANTS.LOCALIZATION.USE_SYSTEM) then
	local system_locale = sys.get_sys_info().language
	LOG.i("system locale:" .. system_locale, TAG)
	if (LUME.findi(LOCALES, system_locale)) then
		M:set_locale(system_locale)
	else
		LOG.i("unknown system locale:" .. system_locale, TAG)
		pprint(LOCALES)
	end

end

for _, locale in ipairs(LOCALES) do
	local table = {}
	for k, v in pairs(M) do
		if type(v) ~= "function" then
			table[k] = v[locale]
		end
	end
	I18N.load({ [locale] = table })
end

for k, v in pairs(M) do
	if type(v) ~= "function" then
		M[k] = function(data)
			return I18N(k, data)
		end
	end
end

--return key if value not founded
---@type Localization
local t = setmetatable({ __VALUE = M, }, {
	__index = function(_, k)
		local result = M[k]
		if not result then
			LOG.w("no key:" .. k, TAG, 2)
			result = function() return k end
			M[k] = result
		end
		return result
	end,
	__newindex = function() error("table is readonly", 2) end,
})

return t
