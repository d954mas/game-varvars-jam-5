local M = {
	CAT_1 = { sprite = "cat_1", },
	CAT_2 = { sprite = "cat_2", origin = vmath.vector3(0, 40, 0) },
	CAT_3 = { sprite = "cat_3", origin = vmath.vector3(0, 40, 0) },
	CAT_4 = { sprite = "cat_4" },
	CAT_5 = { sprite = "cat_5" }
}

for k, v in pairs(M) do
	v.id = k
	v.sprite = hash(v.sprite)
end

return M