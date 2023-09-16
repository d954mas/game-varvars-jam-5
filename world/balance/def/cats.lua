local ENUMS = require "world.enums.enums"

local M = {
	CATS = {
		CAT_2 = { sprite = "cat_2", origin = vmath.vector3(0, 40, 0), min_level = 1 },
		CAT_1 = { sprite = "cat_1", ai = ENUMS.CAT_AI_TYPE.RANDOM_RUN, min_level = 3 },

		CAT_3 = { sprite = "cat_3", origin = vmath.vector3(0, 40, 0), min_level = 5  },
		CAT_4 = { sprite = "cat_4", ai = ENUMS.CAT_AI_TYPE.RUN_AWAY, min_level = 7  },
		CAT_5 = { sprite = "cat_5", ai = ENUMS.CAT_AI_TYPE.RUN_AWAY, min_level = 10  },

		CAT_6 = { sprite = "cat_6", origin = vmath.vector3(0, 40, 0), min_level = 12  },
		CAT_7 = { sprite = "cat_7", ai = ENUMS.CAT_AI_TYPE.RANDOM_RUN, min_level = 15   },
		CAT_8 = { sprite = "cat_8", ai = ENUMS.CAT_AI_TYPE.RANDOM_RUN, min_level = 20  },
		CAT_9 = { sprite = "cat_9", origin = vmath.vector3(0, 30, 0), min_level = 25  },
		CAT_10 = { sprite = "cat_10", origin = vmath.vector3(0, 90, 0), min_level = 30  },
	}
}

M.LIST = {

}

for i = 1, 10 do
	table.insert(M.LIST, assert(M.CATS["CAT_" .. i]))
end

for k, v in pairs(M.CATS) do
	v.id = k
	v.sprite = hash(v.sprite)
end

return M