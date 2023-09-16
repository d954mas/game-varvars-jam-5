local COMMON = require "libs.common"
local ECS = require 'libs.ecs'
local DEFS = require "world.balance.def.defs"

local FACTORY = msg.url("game_scene:/factory#arrow")

local ANGLE_PLAYER = vmath.quat_rotation_x(math.rad(90))
local FOLLOW_DPOS_PLAYER = vmath.vector3(0, 3.5, 0)

local TEMP_V = vmath.vector3()
local TEMP_Q = vmath.quat_rotation_z(0)
local TEMP_Q2 = vmath.quat_rotation_z(0)

local Arrow = COMMON.class("ArrowView")

local PARTS = {
	ROOT = COMMON.HASHES.hash("/root"),
	ARROW = COMMON.HASHES.hash("/arrow"),
}

function Arrow:initialize()
	local collection = collectionfactory.create(FACTORY,nil,nil,nil,vmath.vector3(0.66))

	self.go = {
		root = msg.url(assert(collection[PARTS.ROOT])),
		arrow = {
			root = msg.url(assert(collection[PARTS.ARROW])),
			mesh = nil
		}
	}
	self.go.arrow.mesh = COMMON.LUME.url_component_from_url(self.go.arrow.root, COMMON.HASHES.MESH)
	self.follow_dpos = vmath.vector3(0, 2.8, 0)
	self.angle = vmath.quat_rotation_z(0)
	self.angle_deg = 0
	self.visible = true
end

function Arrow:set_visible(visible)
	if self.visible ~= visible then
		self.visible = visible
		msg.post(self.go.root, visible and COMMON.HASHES.MSG.ENABLE or COMMON.HASHES.MSG.DISABLE)
	end
end

---@param e EntityGame
function Arrow:follow(e)
	self.follow_e = e
end

---@param e EntityGame
function Arrow:set_target(e)
	self.target_e = e
end

function Arrow:update(dt)
	if not self.go then return end
	if (self.follow_e) then
		xmath.add(TEMP_V, self.follow_e.position, self.follow_dpos)
		go.set_position(TEMP_V, self.go.root)
	end
	TEMP_Q.x, TEMP_Q.y, TEMP_Q.z, TEMP_Q.w = self.angle.x, self.angle.y, self.angle.z, self.angle.w
	if (self.target_e) then
		xmath.sub(TEMP_V, self.target_e.position, self.follow_e.position)
		TEMP_V.y = 0
		xmath.normalize(TEMP_V, TEMP_V)
		local angle = COMMON.LUME.angle_vector(TEMP_V.x, -TEMP_V.z)

		local dangle = math.deg(self.angle_deg - angle)
		if dangle > 180 then
			dangle = dangle - 360
		elseif dangle < -180 then
			dangle = dangle + 360
		end
		self.angle_deg = math.rad(dangle) + angle

		dangle = math.abs(dangle)
		if dangle < 5 then
			angle = COMMON.LUME.lerp(self.angle_deg, angle, 0.3)
		elseif dangle < 30 then
			angle = COMMON.LUME.lerp(self.angle_deg, angle, 0.2)
		else
			angle = COMMON.LUME.lerp(self.angle_deg, angle, 0.1)
		end
		self.angle_deg = angle

		xmath.quat_rotation_y(TEMP_Q2, angle)
		xmath.quat_mul(TEMP_Q, TEMP_Q, TEMP_Q2)
	end
	go.set_rotation(TEMP_Q, self.go.root)
end

function Arrow:dispose()
	go.delete(self.go.root)
	self.go = nil
end

---@class TutorialSystem:ECSSystem
local System = ECS.system()
System.name = "ArrowSystem"

function System:onAddToWorld()
	self.arrow = Arrow()
	self.target_timer = 0
end

function System:onRemoveFromWorld()
	self.arrow:dispose()
end

---@param e EntityGame
function System:update(dt)
	self.arrow:follow(self.world.game_world.game.level_creator.player)
	local target = self.arrow.target_e
	if target and target.auto_destroy then target = nil end
	if target and target.distance_to_player < 5 then
		self.target_timer = 0
	end
	if target and target.distance_to_player > 10 then
		self.target_timer = math.huge
	end
	self.target_timer = self.target_timer + dt

	if not target then
		--try find new target. reset current target timer
		self.target_timer = math.huge
	end

	if self.target_timer > 5 then
		self.target_timer = 0

		target = nil
		local distance = math.huge
		for _, cat in ipairs(self.world.game_world.game.ecs_game.entities.cats) do
			if not cat.auto_destroy and cat.distance_to_player < distance then
				distance = cat.distance_to_player
				target = cat
			end
		end

		self.arrow:set_target(target)
		self.arrow:set_visible(target ~= nil)
	end

	self.arrow:update(dt)
end

return System