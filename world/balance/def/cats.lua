local M = {
	CAT_1 = {sprite = "cat_1",}
}

for k, v in pairs(M) do
	v.id = k
	v.sprite = hash(v.sprite)
end


return M