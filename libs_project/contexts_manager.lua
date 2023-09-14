local CLASS = require "libs.middleclass"
local ContextManager = require "libs.contexts_manager"

---@class ContextManagerProject:ContextManager
local Manager = CLASS.class("ContextManagerProject", ContextManager)

Manager.NAMES = {
	MAIN = "MAIN",
	GAME = "GAME",
	GAME_GUI = "GAME_GUI",
	TOP_PANEL = "TOP_PANEL",
	CHOOSE_LOCATION_GUI = "CHOOSE_LOCATION_GUI",
	SETTINGS_GUI = "SETTINGS_GUI",
	UPGRADES_GUI = "UPGRADES_GUI",
	BLACKSMITH_GUI = "BLACKSMITH_GUI",
	PORTAL_NOT_WORKED_GUI = "PORTAL_NOT_WORKED_GUI",
	BUILD_GUI = "BUILD_GUI",
	DESTROY_GUI = "DESTROY_GUI",
	GAME_WORLD_GUI = "GAME_WORLD_GUI",
	BUILDING_BLOCKS = "BUILDING_BLOCKS",
}

---@class ContextStackWrapperMain:ContextStackWrapper
-----@field data ScriptMain

---@return ContextStackWrapperMain
function Manager:set_context_top_main()
	return self:set_context_top_by_name(self.NAMES.MAIN)
end

---@class ContextStackWrapperGame:ContextStackWrapper
-----@field data ScriptGame

---@return ContextStackWrapperGame
function Manager:set_context_top_game()
	return self:set_context_top_by_name(self.NAMES.GAME)
end

---@class ContextStackWrapperGameGui:ContextStackWrapper
-----@field data GameSceneGuiScript

---@return ContextStackWrapperGameGui
function Manager:set_context_top_game_gui()
	return self:set_context_top_by_name(self.NAMES.GAME_GUI)
end

---@class ContextStackWrapperGameWorldGui:ContextStackWrapper
-----@field data GameWorldGuiScript

---@return ContextStackWrapperGameWorldGui
function Manager:set_context_top_game_world_gui()
	return self:set_context_top_by_name(self.NAMES.GAME_WORLD_GUI)
end

---@class ContextStackWrapperChooseLocationGui:ContextStackWrapper
-----@field data ChooseLocationSceneGuiScript

---@return ContextStackWrapperChooseLocationGui
function Manager:set_context_top_choose_location_gui()
	return self:set_context_top_by_name(self.NAMES.CHOOSE_LOCATION_GUI)
end

---@class ContextStackWrapperSettingsGui:ContextStackWrapper
-----@field data SettingsSceneGuiScript

---@return ContextStackWrapperSettingsGui
function Manager:set_context_top_settings_gui()
	return self:set_context_top_by_name(self.NAMES.SETTINGS_GUI)
end

---@class ContextStackWrapperUpgradesGui:ContextStackWrapper
-----@field data UpgradesSceneGuiScript

---@return ContextStackWrapperUpgradesGui
function Manager:set_context_top_upgrades_gui()
	return self:set_context_top_by_name(self.NAMES.UPGRADES_GUI)
end

---@class ContextStackWrapperTopPanelGui:ContextStackWrapper
-----@field data TopPanelGuiScript

---@return ContextStackWrapperTopPanelGui
function Manager:set_context_top_top_panel_gui()
	return self:set_context_top_by_name(self.NAMES.TOP_PANEL)
end



return Manager()