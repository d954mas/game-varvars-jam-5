local I18N = require "libs.i18n.init"
local LOG = require "libs.log"
local CONSTANTS = require "libs.constants"
local TAG = "LOCALIZATION"
local LUME = require "libs.lume"
local LOCALES = { "en", "ru" }
local DEFAULT = CONSTANTS.LOCALIZATION.DEFAULT
local FALLBACK = DEFAULT

local ct

---@class Localization
local M = {
	onboarding_arrows = { en = "USE ARROWS TO MOVE", ru = "ИСПОЛЬЗУЙТЕ СТРЕЛКИ" },
	onboarding_touch = { en = "DRAG TO MOVE", ru = "ИСПОЛЬЗУЙТЕ ПАЛЕЦ" },
	onboarding_catch_them_all = { en = "CATCH THEM ALL", ru = "ЛОВИТЕ КОТОВ" },

	level_title = { en = "LV.%{level}", ru = "УР.%{level}" },
	setting_title = { en = "SETTINGS", ru = "НАСТРОЙКИ" },
	setting_sound = { en = "Sound", ru = "Звуки" },
	setting_music = { en = "Music", ru = "Музыка" },
	setting_shadows = { en = "Shadow", ru = "Тени" },
	cats_book_title = { en = "CATS BOOK", ru = "КНИГА КОТОВ" },

	--region cats
	cat_CAT_1_name = { en = "Whiskers", ru = "Усатик" },
	cat_CAT_1_description = { en = "Curious and playful, Whiskers loves to explore.", ru = "Любопытный и игривый, любит исследовать." },
	cat_CAT_2_name = { en = "Luna", ru = "Луна" },
	cat_CAT_2_description = { en = "Mysterious and elegant cat.", ru = "Загадочный и элегантный кот." },
	cat_CAT_3_name = { en = "Bella", ru = "Белла" },
	cat_CAT_3_description = { en = "Graceful and affectionate cat who loves cuddling.", ru = "Ласковый кот, обожает обниматься." },
	cat_CAT_4_name = { en = "Simba", ru = "Симба" },
	cat_CAT_4_description = { en = "Brave and adventurous, Simba is wild at heart.", ru = "Авантюрный, настоящий дикарь." },
	cat_CAT_5_name = { en = "Oliver", ru = "Оливер" },
	cat_CAT_5_description = { en = "Mischievous cat who can find his way into all sorts of trouble.", ru = "Попадает во все виды неприятностей." },
	cat_CAT_6_name = { en = "Cleo", ru = "Клео" },
	cat_CAT_6_description = { en = "Regal and dignified, carries herself with poise.", ru = "Королевская кошка, ведет себя с изяществом." },
	cat_CAT_7_name = { en = "Jasper", ru = "Джаспер" },
	cat_CAT_7_description = { en = "Easygoing cat who enjoys lounging in the sun.", ru = "Беззаботный, любит полежать на солнышке." },
	cat_CAT_8_name = { en = "Nala", ru = "Нала" },
	cat_CAT_8_description = { en = "Sweet and gentle cat who is everyone's favorite lap warmer.", ru = "Милый и нежный кот, которого все обожают." },
	cat_CAT_9_name = { en = "Felix", ru = "Феликс" },
	cat_CAT_9_description = { en = "Calm and sleepy, picture of relaxation.", ru = "Спокойный, сонливый и расслабленый." },
	cat_CAT_10_name = { en = "Gizmo", ru = "Гизмо" },
	cat_CAT_10_description = { en = "Playful and inquisitive, loves to investigate.", ru = "Игривый и любознательный исследователь." },
	cat_CAT_11_name = { en = "Shadow", ru = "Тень" },
	cat_CAT_11_description = { en = "Mysterious cat who disappears into the night.", ru = "Таинственный кот, который исчезает ночью." },
	cat_CAT_12_name = { en = "Sophie", ru = "Софи" },
	cat_CAT_12_description = { en = "Friendly and sociable cat, charms everyone.", ru = "Дружелюбный и общительный кот, очаровашка." },
	cat_CAT_13_name = { en = "Leo", ru = "Лео" },
	cat_CAT_13_description = { en = "Proud and fearless cat who rules over his domain.", ru = "Гордый король своей территории." },
	cat_CAT_14_name = { en = "Mocha", ru = "Мокко" },
	cat_CAT_14_description = { en = "Warm and affectionate cat who loves to snuggle up.", ru = "Теплый и нежный кот, который обожает уют." },
	cat_CAT_15_name = { en = "Max", ru = "Макс" },
	cat_CAT_15_description = { en = "Energetic and outgoing cat who is always ready to play.", ru = "Общительный, всегда готов к игре." },
	cat_CAT_16_name = { en = "Barsik", ru = "Барсик" },
	cat_CAT_16_description = { en = "Energetic cat, known for his whirlwind antics.", ru = "Энергичный, известен своими выходками." },
	cat_CAT_17_name = { en = "Willow", ru = "Уиллоу" },
	cat_CAT_17_description = { en = "Gentle cat who brings a sense of calm to any room", ru = "Нежный кот, приносит чувство спокойствия." },
	cat_CAT_18_name = { en = "Bubbles", ru = "Пузырьки" },
	cat_CAT_18_description = { en = "Deep, soulful eyes, quiet and gentle.", ru = "Глубокие, спокойные и нежные глаза." },
	cat_CAT_19_name = { en = "Peach", ru = "Персик" },
	cat_CAT_19_description = { en = "Fiery and spirited cat. Independent and self-reliant.", ru = "Пылкий кот. Независимый и самостоятельный." },
	cat_CAT_20_name = { en = "Daizy", ru = "Дейзи" },
	cat_CAT_20_description = { en = "Fun and fizzy as a bottle of champagne.", ru = "Веселая и игривая, как шампанское." },
	--endregion

	login_auth = { en = "AUTHORIZE TO SAVE GAME DATA IN YOUR ACCOUNT", ru = "АВТОРИЗУЙТЕСЬ, ДЛЯ СОХРАНЕНИЯ ДАННЫХ ИГРЫ В ВАШЕМ АККАУНТЕ" },
	login_name = { en = "Unknown", ru = "Неизвестный" },
	game_in_development = { en = "Game in development\nPlease, do not delete", ru = "Игра в разработке\nПожалуйста, не удаляйте" },
	backpack_coming_soon = { en = "In development", ru = "В разработке" },
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
