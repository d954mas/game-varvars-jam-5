local lume = require "libs.lume"

local M = {}

M.SYSTEM_INFO = sys.get_sys_info({ignore_secure = true})
M.PLATFORM = M.SYSTEM_INFO.system_name
M.PLATFORM_IS_WEB = M.PLATFORM == "HTML5"
M.PLATFORM_IS_WINDOWS = M.PLATFORM == "Windows"
M.PLATFORM_IS_LINUX = M.PLATFORM == "Linux"
M.PLATFORM_IS_MACOS = M.PLATFORM == "Darwin"
M.PLATFORM_IS_ANDROID = M.PLATFORM == "Android"
M.PLATFORM_IS_IPHONE = M.PLATFORM == "iPhone OS"

M.PLATFORM_IS_PC = M.PLATFORM_IS_WINDOWS or M.PLATFORM_IS_LINUX or M.PLATFORM_IS_MACOS
M.PLATFORM_IS_MOBILE = M.PLATFORM_IS_ANDROID or M.PLATFORM_IS_IPHONE

M.PROJECT_VERSION = sys.get_config("project.version")

M.GAME_VERSION = sys.get_config("game.version")

M.VERSION_IS_DEV = M.GAME_VERSION == "dev"
M.VERSION_IS_RELEASE = M.GAME_VERSION == "release"

M.GAME_TARGET = sys.get_config("game.target")
M.TARGETS = {
	EDITOR = "editor",
	OTHER = "other",
	PLAY_MARKET = "play_market",
	POKI = "poki",
	ITCH_IO = "itch_io",
	GAME_DISTRIBUTION = "game_distribution",
	YANDEX_GAMES = "yandex_games",
	CRAZY_GAMES = "crazy_games"
}

M.SEEDS = {
	LEVEL_DATA = 1489139676,
	LEVEL_GEOMETRY = 3701539625
}

assert(lume.find(M.TARGETS, M.GAME_TARGET), "unknown target:" .. M.GAME_TARGET)

M.TARGET_IS_EDITOR = M.GAME_TARGET == M.TARGETS.EDITOR
M.TARGET_IS_PLAY_MARKET = M.GAME_TARGET == M.TARGETS.PLAY_MARKET
M.TARGET_IS_GAME_DISTRIBUTION = M.GAME_TARGET == M.TARGETS.GAME_DISTRIBUTION
M.TARGET_IS_POKI = M.GAME_TARGET == M.TARGETS.POKI
M.TARGET_IS_ITCH_IO = M.GAME_TARGET == M.TARGETS.ITCH_IO
M.TARGET_IS_YANDEX_GAMES = M.GAME_TARGET == M.TARGETS.YANDEX_GAMES
M.TARGET_IS_CRAZY_GAMES = M.GAME_TARGET == M.TARGETS.CRAZY_GAMES
M.TARGET_OTHER = M.GAME_TARGET == M.TARGETS.OTHER

M.CRYPTO_KEY = "6soZqsCXY4"

M.IS_TESTS = sys.get_config("tests.tests_run")



M.GUI_ORDER = {
	GAME = 2,
	BUILDING_BLOCKS = 3,
	MODAL = 4,
	TOP_PANEL = 5,
	SETTINGS = 6,
	DEBUG = 15,
}

M.COLORS = {
	EMPTY = vmath.vector4(1,1,1,0),
	WHITE = vmath.vector4(1,1,1,1),
	NOT_ENOUGH = lume.color_parse_hexRGBA("#ff0000"),
	ENOUGH = lume.color_parse_hexRGBA("#ffffff"),
	CAT_HIDDEN = lume.color_parse_hexRGBA("#333333"),
	CAT_SHOW = lume.color_parse_hexRGBA("#ffffff")
}

M.LOCALIZATION = {
	DEFAULT = sys.get_config("localization.default") or "en",
	USE_SYSTEM = (sys.get_config("localization.use_system") or "false") == "true",
	FORCE_LOCALE = sys.get_config("localization.force_locale")
}



return M
