local COMMON = require "libs.common"
local ECS = require 'libs.ecs'
local ENUMS = require 'world.enums.enums'
local DEFS = require "world.balance.def.defs"

local ENABLE = hash("enable")
local DISABLE = hash("disable")

local PARTS = {
	ROOT = COMMON.HASHES.hash("/root"),
	ARROW_SPOT = COMMON.HASHES.hash("/arrow_spot"),
}

local V_FORWARD = vmath.vector3(0, 0, -1)
local LOOK_DIFF = vmath.vector3(0, 0, -1)
local DMOVE = vmath.vector3(0, 0, -1)

local V_LOOK_DIR = vmath.vector3(0, 0, -1)
local Q_ROTATION = vmath.quat_rotation_z(0)

local BASE_BLEND = { blend_duration = 0.1 }
local BASE_BLEND_SPEED = { blend_duration = 0.1, playback_rate = 1 }

local ANIMATIONS = {
	IDLE = hash("Standing Idle 02 Looking"),
	RUN = hash("Standing Run Forward"),
	DRAW_ARROW = hash("Standing Draw Arrow"),
	DIE = hash("Falling Back Death"),
	GATHERING = hash("Standing Melee Attack Horizontal"),
}

---@class DrawPlayerSystem:ECSSystem
local System = ECS.processingSystem()
System.filter = ECS.filter("player")
System.name = "PlayerDrawSystem"

---@param e EntityGame
function System:get_animation(e)
	if (e.die) then
		return ENUMS.ANIMATIONS.DIE
	end
	if (e.moving) then
		return ENUMS.ANIMATIONS.RUN
	end
	if (e.target) then
		return ENUMS.ANIMATIONS.ATTACK
	end
	if (e.target_gathering) then
		return ENUMS.ANIMATIONS.GATHERING
	end
	return ENUMS.ANIMATIONS.IDLE
end

---@param e EntityGame
function System:onAdd(e)

end

---@param e EntityGame
function System:process(e, dt)
	if (e.target) then
		e.look_at_dir.x = -e.target.distance_to_player_vec_normalized.x
		e.look_at_dir.z = -e.target.distance_to_player_vec_normalized.z
	elseif (e.target_gathering) then
		e.look_at_dir.x = -e.target_gathering.distance_to_player_vec_normalized.x
		e.look_at_dir.z = -e.target_gathering.distance_to_player_vec_normalized.z
	end

	if (e.player_data.skin ~= e.player_go.config.skin) then
		e.player_go.config.skin = e.player_data.skin
		e.player_go.config.animation = nil
		--DELETE PREV SKIN
		if (e.player_go.model.root) then
			go.delete(e.player_go.model.root)
			e.player_go.model.root = nil
			e.player_go.model.model = nil
		end
	end

	if (e.player_go.model.root == nil) then
		local skin_def = assert(DEFS.SKINS.SKINS_BY_ID[e.player_go.config.skin])
		local urls = collectionfactory.create(skin_def.factory, nil, nil, nil,
				skin_def.scale)
		local go_url = urls[PARTS.ROOT]
		go.set_parent(go_url, e.player_go.root, false)
		e.player_go.model.root = msg.url(go_url)
		e.player_go.model.model = COMMON.LUME.url_component_from_url(e.player_go.model.root, COMMON.HASHES.MODEL)
		e.player_go.config.visible = true
	end

	local visible = not e.camera.first_person
	if (visible ~= e.player_go.config.visible) then
		e.player_go.config.visible = visible
		msg.post(e.player_go.model.root, visible and ENABLE or DISABLE)
	end

	local anim = self:get_animation(e)

	if (e.player_go.config.animation ~= anim) then
		local prev = e.player_go.config.animation
		e.player_go.config.animation = anim
		if (anim == ENUMS.ANIMATIONS.IDLE) then
			if (prev == ENUMS.ANIMATIONS.DIE) then
				model.play_anim(e.player_go.model.model, ANIMATIONS.IDLE, go.PLAYBACK_ONCE_FORWARD)
			else
				model.play_anim(e.player_go.model.model, ANIMATIONS.IDLE, go.PLAYBACK_ONCE_FORWARD, BASE_BLEND)
			end

		elseif (anim == ENUMS.ANIMATIONS.RUN) then
			model.play_anim(e.player_go.model.model, ANIMATIONS.RUN, go.PLAYBACK_LOOP_FORWARD, BASE_BLEND)
		elseif (anim == ENUMS.ANIMATIONS.ATTACK) then
			BASE_BLEND_SPEED.playback_rate = e.parameters.weapon.animation_speed
			model.play_anim(e.player_go.model.model, ANIMATIONS.DRAW_ARROW, go.PLAYBACK_ONCE_FORWARD, BASE_BLEND_SPEED)
		elseif (anim == ENUMS.ANIMATIONS.DIE) then
			model.play_anim(e.player_go.model.model, ANIMATIONS.DIE, go.PLAYBACK_ONCE_FORWARD,
					{ blend_duration = 0.1 })
		elseif (anim == ENUMS.ANIMATIONS.GATHERING) then
			if (e.target_gathering.gathering_hp > 0) then
				local item_def = e.target_gathering.tree and e.parameters.axe
				BASE_BLEND_SPEED.playback_rate = item_def.animation_speed
				model.play_anim(e.player_go.model.model, ANIMATIONS.GATHERING, go.PLAYBACK_ONCE_FORWARD, BASE_BLEND_SPEED)
			else
				model.play_anim(e.player_go.model.model, ANIMATIONS.IDLE, go.PLAYBACK_ONCE_FORWARD, BASE_BLEND)
			end
		end
	end

	--[[if (e.player_go.weapon.arrow.visible and not e.target) then
		msg.post(e.player_go.weapon.arrow.root,DISABLE)
		e.player_go.weapon.arrow.visible = false
	elseif (not e.player_go.weapon.arrow.visible and e.target) then
		msg.post(e.player_go.weapon.arrow.root, ENABLE)
		e.player_go.weapon.arrow.visible = true
	end--]]

	go.set_position(e.position, e.player_go.root)

	--if (e.player_go.model.root) then
	V_LOOK_DIR.x, V_LOOK_DIR.y, V_LOOK_DIR.z = e.look_at_dir.x, 0, e.look_at_dir.z
	if (vmath.length(V_LOOK_DIR) == 0) then
		V_LOOK_DIR.x = V_FORWARD.x
		V_LOOK_DIR.y = V_FORWARD.y
		V_LOOK_DIR.z = V_FORWARD.z
	end
	xmath.normalize(V_LOOK_DIR, V_LOOK_DIR)

	xmath.sub(LOOK_DIFF, V_LOOK_DIR, e.player_go.config.look_dir)
	local diff_len = vmath.length(LOOK_DIFF)
	if (diff_len > 1.9) then
		xmath.quat_rotation_y(Q_ROTATION, math.rad(1))
		xmath.rotate(e.player_go.config.look_dir, Q_ROTATION, e.player_go.config.look_dir)
		xmath.lerp(e.player_go.config.look_dir, 0.3, e.player_go.config.look_dir, V_LOOK_DIR)
	elseif (diff_len > 1) then
		xmath.lerp(e.player_go.config.look_dir, 0.3, e.player_go.config.look_dir, V_LOOK_DIR)
	elseif (diff_len > 0.6) then
		xmath.lerp(e.player_go.config.look_dir, 0.2, e.player_go.config.look_dir, V_LOOK_DIR)
	elseif (diff_len > 0.1) then
		xmath.normalize(DMOVE, LOOK_DIFF)
		local scale = 3 --diff_len>0.1 and 0.8 or 0.6
		xmath.mul(DMOVE, DMOVE, scale * dt)
		if (vmath.length(DMOVE) > diff_len) then
			DMOVE.x = LOOK_DIFF.x
			DMOVE.y = LOOK_DIFF.y
			DMOVE.z = LOOK_DIFF.z
		end
		xmath.add(e.player_go.config.look_dir, e.player_go.config.look_dir, DMOVE)
	end

	xmath.normalize(e.player_go.config.look_dir, e.player_go.config.look_dir)
	xmath.quat_from_to(Q_ROTATION, V_FORWARD, e.player_go.config.look_dir)

	if (Q_ROTATION.x ~= Q_ROTATION.x or Q_ROTATION.y ~= Q_ROTATION.y or Q_ROTATION.z ~= Q_ROTATION.z) then
		xmath.quat_rotation_y(Q_ROTATION, math.pi)
	end
	if (e.player_go.model) then
		go.set_rotation(Q_ROTATION, e.player_go.model.root)
	end


end

return System