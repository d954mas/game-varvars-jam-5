-- lume
-- Copyright (c) 2018 rxi

local lume = { _version = "2.3.0" }

local pairs, ipairs = pairs, ipairs
local type, assert = type, assert
local tostring, tonumber = tostring, tonumber
local math_floor = math.floor
local math_ceil = math.ceil
local math_atan2 = math.atan2
local math_abs = math.abs
local table_remove = table.remove
local math_random = math.random

local MATH_DEG = math.deg
local PI_HALF = math.pi / 2
local MATH_ATAN2 = math.atan2
local MATH_ASIN = math.asin

function lume.clamp(x, min, max)
	return x < min and min or (x > max and max or x)
end

function lume.round(x, increment)
	if increment then return lume.round(x / increment) * increment end
	return x >= 0 and math_floor(x + .5) or math_ceil(x - .5)
end

function lume.ceil(x, increment)
	if increment then return math.ceil(x / increment) * increment end
	return math.ceil(x)
end
function lume.floor(x, increment)
	if increment then return math.floor(x / increment) * increment end
	return math.floor(x)
end

function lume.sign(x)
	return x < 0 and -1 or 1
end

function lume.angle(x1, y1, x2, y2)
	return math_atan2(y2 - y1, x2 - x1)
end

--counter-clockwise angles [0,360]
--https://stackoverflow.com/questions/14066933/direct-way-of-computing-clockwise-angle-between-2-vectors
function lume.angle2(x1, y1, x2, y2)
	local dot = x1 * x2 + y1 * y2      --# dot product between [x1, y1] and [x2, y2]
	local det = x1 * y2 - y1 * x2      --# determinant
	return math_atan2(det, dot)
end

function lume.angle_vector(x, y)
	return math_atan2(y, x)
end

function lume.normalize_angle_deg(deg)
	deg = deg % 360;
	if (deg < 0) then deg = deg + 360 end
	return deg
end

function lume.normalize_angle_rad(rad)
	return math.rad(lume.normalize_angle_deg(math.deg(rad)))
end

function lume.random(a, b)
	if not a then
		a, b = 0, 1
	end
	if not b then
		b = 0
	end
	return a + math_random() * (b - a)
end

function lume.randomchoice(t)
	return t[math_random(#t)]
end

function lume.randomchoice_remove(t)
	return table_remove(t, math_random(#t))
end

function lume.pcg_randomchoice_remove(t)
	return table_remove(t, rnd.range(1, #t))
end

function lume.weightedchoice_nil(t)
	local sum = 0
	for _, v in pairs(t) do
		assert(v >= 0, "weight value less than zero")
		sum = sum + v
	end
	if (sum == 0) then return nil end
	local rnd = lume.random(sum)
	for k, v in pairs(t) do
		if rnd < v then
			return k
		end
		rnd = rnd - v
	end
end

function lume.weightedchoice(t)
	local result = lume.weightedchoice_nil(t)
	assert(result, "all weights are zero")
end

function lume.removei(t, value)
	for k, v in ipairs(t) do
		if v == value then
			return table_remove(t, k)
		end
	end
end

function lume.clearp(t)
	for k, v in pairs(t) do
		t[k] = nil
	end
	return t
end
function lume.cleari(t)
	for i = 1, #t do
		t[i] = nil
	end
	return t
end

function lume.shuffle(t)
	local rtn = {}
	for i = 1, #t do
		local r = math_random(i)
		if r ~= i then
			rtn[i] = rtn[r]
		end
		rtn[r] = t[i]
	end
	return rtn
end

function lume.iftern(bool, vtrue, vfalse)
	if bool then return vtrue else return vfalse end
end

function lume.find(t, value)
	for k, v in pairs(t) do
		if v == value then
			return k
		end
	end
	return nil
end

function lume.findi(t, value)
	for k, v in ipairs(t) do
		if v == value then
			return k
		end
	end
	return nil
end

---@generic T
---@param t T
---@return T
function lume.clone_shallow(t)
	local rtn = {}
	for k, v in pairs(t) do rtn[k] = v
	end
	return rtn
end

function lume.clone_deep(t)
	local orig_type = type(t)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, t, nil do
			copy[lume.clone_deep(orig_key)] = lume.clone_deep(orig_value)
		end
	else
		-- number, string, boolean, etc
		copy = t
	end
	return copy
end

function lume.merge_table(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == "table" then
			if type(t1[k]) == "table" then
				lume.merge_table(t1[k], v)
			else
				t1[k] = v
			end
		else
			t1[k] = v
		end
	end
	return t1
end

function lume.mix_table(t1, t2)
	local t = {}
	for _, v in ipairs(t1) do
		table.insert(t, v)
	end
	for _, v in ipairs(t2) do
		table.insert(t, v)
	end
	return t
end

function lume.string_split(s, delimiter)
	local result = {};
	for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match);
	end
	return result;
end

function lume.string_replace_pattern(string, pattern, value)
	return string:gsub(pattern, value);
end

function lume.string_start_with(str, start)
	return string.sub(str, 1, string.len(start)) == start
end

function lume.color(str)
	local r, g, b, a
	r, g, b = str:match("#(%x%x)(%x%x)(%x%x)")
	if r then
		r = tonumber(r, 16) / 0xff
		g = tonumber(g, 16) / 0xff
		b = tonumber(b, 16) / 0xff
		a = 1
	elseif str:match("rgba?%s*%([%d%s%.,]+%)") then
		local f = str:gmatch("[%d.]+")
		r = (f() or 0) / 0xff
		g = (f() or 0) / 0xff
		b = (f() or 0) / 0xff
		a = f() or 1
	else
		error(("bad color string '%s'"):format(str))
	end
	return r, g, b, a
end

function lume.color_parse_hexRGBA(hex)
	local r, g, b, a = hex:match("#(%x%x)(%x%x)(%x%x)(%x?%x?)")
	if a == "" then a = "ff" end
	if r and g and b and a then
		return vmath.vector4(tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, tonumber(a, 16) / 255)
	end
	return nil
end

function lume.color_parse_hexARGB(hex)
	local a, r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)(%x?%x?)")
	if r and g and b and a then
		return vmath.vector4(tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255, tonumber(a, 16) / 255)
	end
	return nil
end

---@param url url
function lume.url_component_from_url(url, component)
	return msg.url(url.socket, url.path, component)
end

function lume.get_human_time(seconds)
	if seconds <= 0 then
		return "00:00";
	else
		local hours = string.format("%02.f", math.floor(seconds / 3600));
		local mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)));
		local secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60));
		if hours == '00' then
			return mins .. ":" .. secs
		else
			return hours .. ":" .. mins .. ":" .. secs
		end
	end
end

function lume.get_cost_string(value)
	if (value < 10000) then
		--pass
		return value
	elseif (value < 100000) then
		return string.format("%.2fk", lume.floor(value / 1000, 0.01))
	elseif (value < 1000000) then
		return string.format("%.1fk", lume.floor(value / 1000, 0.1))
	elseif (value < 100000000) then
		return string.format("%.2fm", lume.floor(value / 1000000, 0.01))
	elseif (value < 1000000000) then
		return string.format("%.1fm", lume.floor(value / 1000000, 0.1))
	else
		return string.format("%.1fb", lume.floor(value / 1000000000, 0.1))
	end

end

function lume.equals_float(a, b, epsilon)
	epsilon = epsilon or 0.0001
	return (math_abs(a - b) < epsilon)
end

--[[
https://android.googlesource.com/platform/external/jmonkeyengine/+/59b2e6871c65f58fdad78cd7229c292f6a177578/engine/src/core/com/jme3/math/Quaternion.java
Convert a quaternion into euler angles (roll, pitch, yaw)
roll is rotation around x in radians (counterclockwise)
pitch is rotation around y in radians (counterclockwise)
yaw is rotation around z in radians (counterclockwise)
--]]
function lume.quat_to_euler_degrees(q)
	-- Extract the quaternion components
	local x, y, z, w = q.x, q.y, q.z, q.w

	local sqw = w * w;
	local sqx = x * x;
	local sqy = y * y;
	local sqz = z * z;
	-- normalized is one, otherwise is correction factor
	local unit = sqx + sqy + sqz + sqw

	local test = x * y + z * w;
	local roll, pitch, yaw
	-- singularity at north pole
	if (test > 0.499 * unit) then
		roll = 2 * MATH_ATAN2(x, w);
		pitch = PI_HALF;
		yaw = 0;
		--// singularity at south pole
	elseif (test < -0.499 * unit) then
		roll = -2 * MATH_ATAN2(x, w);
		pitch = -PI_HALF;
		yaw = 0;
	else
		roll = MATH_ATAN2(2 * y * w - 2 * x * z, sqx - sqy - sqz + sqw); -- roll or heading
		pitch = MATH_ASIN(2 * test / unit); -- pitch or attitude
		yaw = MATH_ATAN2(2 * x * w - 2 * y * z, -sqx + sqy - sqz + sqw); -- yaw or bank
	end
	--something wrong with names
	--return roll, pitch, yaw
	return MATH_DEG(yaw), MATH_DEG(roll), MATH_DEG(pitch)
end

function lume.euler_to_quat(roll, pitch, yaw)
	local qx = math.sin(roll / 2) * math.cos(pitch / 2) * math.cos(yaw / 2) - math.cos(roll / 2) * math.sin(pitch / 2) * math.sin(yaw / 2)
	local qy = math.cos(roll / 2) * math.sin(pitch / 2) * math.cos(yaw / 2) + math.sin(roll / 2) * math.cos(pitch / 2) * math.sin(yaw / 2)
	local qz = math.cos(roll / 2) * math.cos(pitch / 2) * math.sin(yaw / 2) - math.sin(roll / 2) * math.sin(pitch / 2) * math.cos(yaw / 2)
	local qw = math.cos(roll / 2) * math.cos(pitch / 2) * math.cos(yaw / 2) + math.sin(roll / 2) * math.sin(pitch / 2) * math.sin(yaw / 2)

	return qx, qy, qz, qw
end

return lume