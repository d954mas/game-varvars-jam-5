local COMMON = require "libs.common"
local ECS = require "libs.ecs"
local SYSTEMS = require "world.game.ecs.game_systems"
local Entities = require "world.game.ecs.entities.entities_game"

---@class GameEcsWorld
local EcsWorld = COMMON.class("EcsWorld")

---@param world World
function EcsWorld:initialize(world)
	self.world = assert(world)

	self.ecs = ECS.world()
	self.ecs.game = self
	self.ecs.game_world = self.world

	self.entities = Entities(world)
	self.ecs.on_entity_added = function(_, ...) self.entities:on_entity_added(...) end
	self.ecs.on_entity_removed = function(_, ...) self.entities:on_entity_removed(...) end
end

function EcsWorld:find_by_id(id)
	return self.entities:find_by_id(assert(id))
end

function EcsWorld:add_systems()
	self.camera_system = SYSTEMS.PlayerCameraSystem()
	self.lock_mouse_system = SYSTEMS.LockMouseSystem()

	self.ecs:addSystem(SYSTEMS.PhysicsUpdateVariablesSystem())
	self.ecs:addSystem(self.camera_system)
	self.ecs:addSystem(SYSTEMS.UpdateDistanceToPlayerSystem())

	self.ecs:addSystem(SYSTEMS.InputSystem())
	self.ecs:addSystem(SYSTEMS.ActionsUpdateSystem())
	self.ecs:addSystem(self.lock_mouse_system)
	self.ecs:addSystem(SYSTEMS.CatAiSystem())
	self.ecs:addSystem(SYSTEMS.CatPathfindingSystem())
	self.ecs:addSystem(SYSTEMS.CatMoveSystem())
	self.ecs:addSystem(SYSTEMS.CatRunAwayRaycastSystem())
	self.ecs:addSystem(SYSTEMS.CatRunAwaySystem())

	--self.ecs:addSystem(SYSTEMS.GroundCheckSystem())
	self.ecs:addSystem(SYSTEMS.PlayerMoveSystem())
	self.ecs:addSystem(SYSTEMS.PlayerCatCollectSystem())

	self.ecs:addSystem(SYSTEMS.PlayerCheckInteractiveAreaSystem())
	self.ecs:addSystem(SYSTEMS.PlayerStepSoundSystem())

	--#IF DEBUG
	if (COMMON.CONSTANTS.PLATFORM_IS_PC) then
		self.ecs:addSystem(SYSTEMS.PlayerFlySystem())
	end
	--#ENDIF

	self.ecs:addSystem(SYSTEMS.PhysicsUpdateLinearVelocitySystem())

	self.ecs:addSystem(SYSTEMS.WaterMoveSystem())
	self.ecs:addSystem(SYSTEMS.UpdateFrustumBoxSystem())

	self.ecs:addSystem(SYSTEMS.DrawChunksSystem())
	self.ecs:addSystem(SYSTEMS.DrawPlayerSystem())
	self.ecs:addSystem(SYSTEMS.DrawCatSystem())

	--#IF DEBUG
	if (COMMON.CONSTANTS.VERSION_IS_DEV) then
		self.ecs:addSystem(SYSTEMS.DrawFrustumBoxSystem())
	end
	--#ENDIF

	--#IF DEBUG
	if (COMMON.CONSTANTS.PLATFORM_IS_PC) then
		self.ecs:addSystem(SYSTEMS.DrawInteractAABBDebugSystem())
		self.ecs:addSystem(SYSTEMS.DrawDebugPathCellSystem())
		self.ecs:addSystem(SYSTEMS.DrawDebugPathSystem())
	end
	--#ENDIF

	self.ecs:addSystem(SYSTEMS.LevelCompletedSystem())
	self.ecs:addSystem(SYSTEMS.AutoDestroySystem())
end

--update when game scene is not on top
function EcsWorld:update_game_not_top(dt)
	if (self.camera_system) then
		self.camera_system:update(dt)
	end
	if (self.lock_mouse_system) then
		self.lock_mouse_system:update(dt)
	end
end

function EcsWorld:update(dt)
	--if dt will be too big. It can create a lot of objects.
	--big dt can be in htlm when change page and then return
	--or when move game window in Windows.
	local max_dt = 0.1
	if (dt > max_dt) then dt = max_dt end
	self.ecs:update(dt)
end

function EcsWorld:clear()
	self.ecs:clear()
	self.ecs:refresh()
end

function EcsWorld:refresh()
	self.ecs:refresh()
end

function EcsWorld:add(...)
	self.ecs:add(...)
end

function EcsWorld:add_entity(e)
	assert(e)
	self.ecs:addEntity(e)
end

function EcsWorld:remove_entity(e)
	assert(e)
	self.ecs:removeEntity(e)
end

return EcsWorld



