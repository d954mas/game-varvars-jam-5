local M = {}

M.SKINS_BY_ID = {}

M.SKINS_BY_ID.MINE = {
	factory = msg.url("game_scene:/factory/character#char_mine"),
	scale = vmath.vector3(1.95/6.8), --6.8 size of model
}

M.SKINS_BY_ID.ZOMBIE = {
	factory = msg.url("game_scene:/factory/character#char_zombie"),
	scale = vmath.vector3(1.95/6.8), --6.8 size of model
}

M.SKINS_BY_ID.SKELET = {
	factory = msg.url("game_scene:/factory/character#char_skelet"),
	scale = vmath.vector3(1.95/6.8), --6.8 size of model
}

for k, v in pairs(M.SKINS_BY_ID) do
	v.id = k
end


return M