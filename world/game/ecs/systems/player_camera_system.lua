local ECS = require 'libs.ecs'
local COMMON = require "libs.common"

local SmoothDumpV3 = require "libs.smooth_dump_v3"

local TEMP_DMOVE = vmath.vector3(0)
local TEMP_Q_YAW = vmath.quat_rotation_z(0)
local TEMP_Q_YAW_REVERSE = vmath.quat_rotation_z(0)
local TEMP_Q = vmath.quat_rotation_z(0)

local V_TARGET = vmath.vector3(0)

---@class PlayerCameraSystem:ECSSystem
local System = ECS.system()
System.name = "PlayerCameraSystem"

function System:init()
	self.smooth_dump = SmoothDumpV3.new()
	self.smooth_dump.smoothTime = 0.25
	self.smooth_dump.maxDistance = 3;
	self.fov = math.rad(60)
	self.fov_portrait_h = math.rad(60)
end

function System:onAddToWorld()
	for i = 1, 5 do
		self:update(1)
	end
end

---@param e EntityGame
function System:update(dt)
	local player = self.world.game_world.game.level_creator.player

	self.smooth_dump.maxSpeed = player.movement.max_speed


	local camera = player.camera
	local config = camera.first_person and camera.config_first_person or camera.config
	local yaw_rad = math.rad(camera.yaw)
	local pitch_rad = math.rad(camera.pitch)

	xmath.quat_rotation_y(TEMP_Q_YAW, yaw_rad)
	xmath.quat_rotation_y(TEMP_Q_YAW_REVERSE, -yaw_rad)

	local addPos = COMMON.RENDER.screen_size.aspect > 1 and config.position or config.position_v
	xmath.rotate(TEMP_DMOVE, TEMP_Q_YAW_REVERSE, addPos)

	--xmath.rotate(player.camera.position, TEMP_Q_YAW_REVERSE, player.camera.position)
	--xmath.add(player.camera.position, PLAYER_POS, TEMP_DMOVE)

	--ORIENTATION
	xmath.quat_rotation_x(TEMP_Q, pitch_rad)
	xmath.quat_mul(player.camera.rotation, TEMP_Q_YAW_REVERSE, TEMP_Q)

	
	player.camera.position.y = 0
	V_TARGET.x, V_TARGET.y, V_TARGET.z = player.position.x + TEMP_DMOVE.x, 0, player.position.z + TEMP_DMOVE.z

	self.smooth_dump:update(player.camera.position, V_TARGET, dt)

	if (player.ghost_mode) then
		player.camera.position.y = player.position.y + TEMP_DMOVE.y
	else
		player.camera.position.y = 65 + TEMP_DMOVE.y
	end

	local fov = self.fov
	if (COMMON.RENDER.screen_size.aspect < 1) then
		fov = 2 * math.atan(math.tan(self.fov_portrait_h / 2) * 1 / COMMON.RENDER.screen_size.aspect)
	end

	game.camera_set_fov(fov)
	game.camera_set_view_position(player.camera.position)
	game.camera_set_view_rotation(player.camera.rotation)

	player.camera.rotation_euler.x, player.camera.rotation_euler.y, player.camera.rotation_euler.z = COMMON.LUME.quat_to_euler_degrees(player.camera.rotation)
end

return System