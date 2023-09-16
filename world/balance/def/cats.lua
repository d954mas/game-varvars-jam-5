local ENUMS = require "world.enums.enums"

local M = {
	CATS = {
		CAT_1 = { sprite = "cat_1", ai = ENUMS.CAT_AI_TYPE.RANDOM_RUN },
		CAT_2 = { sprite = "cat_2", origin = vmath.vector3(0, 40, 0) },
		CAT_3 = { sprite = "cat_3", origin = vmath.vector3(0, 40, 0) },
		CAT_4 = { sprite = "cat_4", ai = ENUMS.CAT_AI_TYPE.RUN_AWAY },
		CAT_5 = { sprite = "cat_5", ai = ENUMS.CAT_AI_TYPE.RANDOM_RUN }
	}
}

M.LIST = {

}

for i = 1, 5 do
	table.insert(M.LIST, assert(M.CATS["CAT_" .. i]))
end

for k, v in pairs(M.CATS) do
	v.id = k
	v.sprite = hash(v.sprite)
end

return M