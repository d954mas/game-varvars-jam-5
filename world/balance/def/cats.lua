local ENUMS = require "world.enums.enums"

local M = {
	CATS = {
		CAT_2 = { sprite = "cat_2", min_level = 1, sound = "cat_1" },
		CAT_1 = { sprite = "cat_1", ai = ENUMS.CAT_AI_TYPE.RANDOM_RUN, min_level = 3, sound = "cat_2" },

		CAT_3 = { sprite = "cat_3", min_level = 5, sound = "cat_3" },
		CAT_4 = { sprite = "cat_4", ai = ENUMS.CAT_AI_TYPE.RUN_AWAY, min_level = 7, sound = "cat_4" },
		CAT_5 = { sprite = "cat_5", ai = ENUMS.CAT_AI_TYPE.RUN_AWAY, min_level = 10, sound = "cat_5" },

	}
}

M.LIST = {

}

table.insert(M.LIST, assert(M.CATS["CAT_" .. 2]))
table.insert(M.LIST, assert(M.CATS["CAT_" .. 1]))
for i = 3, 5 do
	table.insert(M.LIST, assert(M.CATS["CAT_" .. i]))
end

for k, v in pairs(M.CATS) do
	v.id = k
	v.sprite = hash(v.sprite)
end

return M