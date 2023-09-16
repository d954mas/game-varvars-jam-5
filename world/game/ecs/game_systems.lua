local M = {}

--ecs systems created in require.
--so do not cache then

-- luacheck: push ignore require

local require_old = require
local require_no_cache
local require_no_cache_name
require_no_cache = function(k)
	require = require_old
	local m = require_old(k)
	if (k == require_no_cache_name) then
		--        print("load require no_cache_name:" .. k)
		package.loaded[k] = nil
	end
	require_no_cache_name = nil
	require = require_no_cache
	return m
end

local creator = function(name)
	return function(...)
		require_no_cache_name = name
		local system = require_no_cache(name)
		if (system.init) then system.init(system, ...) end
		return system
	end
end

require = creator

M.ActionsUpdateSystem = require "world.game.ecs.systems.actions_update_system"
M.AutoDestroySystem = require "world.game.ecs.systems.auto_destroy_system"
M.InputSystem = require "world.game.ecs.systems.input_system"
M.LockMouseSystem = require "world.game.ecs.systems.lock_mouse_system"
M.LevelCompletedSystem = require "world.game.ecs.systems.level_completed_system"

M.PhysicsUpdateVariablesSystem = require "world.game.ecs.systems.physics_update_variables"
M.PhysicsUpdateLinearVelocitySystem = require "world.game.ecs.systems.physics_update_linear_velocity"

M.PlayerCameraSystem = require "world.game.ecs.systems.player_camera_system"
M.PlayerMoveSystem = require "world.game.ecs.systems.player_move_system"
M.PlayerCheckInteractiveAreaSystem = require "world.game.ecs.systems.player_check_interactive_area_system"
M.PlayerStepSoundSystem = require "world.game.ecs.systems.player_step_sound_system"
M.PlayerCatCollectSystem = require "world.game.ecs.systems.player_cat_collect_system"

M.UpdateDistanceToPlayerSystem = require "world.game.ecs.systems.update_distance_to_player_system"
M.UpdateFrustumBoxSystem = require "world.game.ecs.systems.update_frustum_box"

M.CatAiSystem = require "world.game.ecs.systems.cat_ai_system"
M.CatPathfindingSystem = require "world.game.ecs.systems.cat_pathfinding_system"
M.CatMoveSystem = require "world.game.ecs.systems.cat_move_system"

M.DrawPlayerSystem = require "world.game.ecs.systems.draw_player_system"
M.DrawChunksSystem = require "world.game.ecs.systems.draw_chunks_system"
M.DrawCatSystem = require "world.game.ecs.systems.draw_cat_system"

M.WaterMoveSystem = require "world.game.ecs.systems.water_move_system"

--#IF DEBUG
M.PlayerFlySystem = require "world.game.ecs.systems.player_fly_system"
M.DrawFrustumBoxSystem = require "world.game.ecs.systems.draw_frustum_box_system"
M.DrawInteractAABBDebugSystem = require "world.game.ecs.systems.draw_interact_aabb_debug_system"
M.DrawDebugPathCellSystem = require "world.game.ecs.systems.draw_debug_path_cell_system"
M.DrawDebugPathSystem = require "world.game.ecs.systems.draw_debug_path_system"
--#ENDIF



require = require_old

-- luacheck: pop

return M