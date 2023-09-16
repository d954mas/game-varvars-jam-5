local COMMON = require "libs.common"

local MAX_FOV = math.pi - 0.00000001

local Curve = COMMON.class("Curve")


---@param world World
function Curve:initialize(world)
	self.world = assert(world)
	self.constants = {}
	self.curve = vmath.vector4()
	self.curve_origin = vmath.vector4()
end

function Curve:add_constants(constant)
	table.insert(self.constants, constant)
	constant.curve = self.curve
	constant.curve_origin = self.curve_origin
end

function Curve:set_curve(z, x, horiz)
	if z then  self.curve.z = z  end
	if x then  self.curve.x = x  end
	if horiz then  self.curve.w = horiz  end

	for _,constant in ipairs(self.constants)do
		constant.curve = self.curve
	end
end

function Curve:set_origin(position)
	self.curve_origin.x, self.curve_origin.y, self.curve_origin.z = position.x, position.y, position.z
	for _,constant in ipairs(self.constants)do
		constant.curve_origin = self.curve_origin
	end
end

-- Calculate the curved vertex offset for a given delta-pos from the origin point.
function Curve:get_curve_offset(dx, dz)
	local kx, kz = dx*dx, dz*dz
	local ox = -kz*self.curve.w
	local oy = -kz*self.curve.z - kx*self.curve.x
	return ox, oy
end

function Curve:get_cull_extents(hw, hh, far)
	local max_dist = math.sqrt(hw*hw + hh*hh + far*far)
	local max_dx, max_dy = self:get_curve_offset(max_dist, max_dist)
	local new_hw, new_hh = hw + math.abs(max_dx), hh + math.abs(max_dy)
	return new_hw, new_hh
end

function Curve:get_cull_fov(fov, aspect, far)
	local hh = math.tan(fov/2) * far
	local hw = hh * aspect -- aspect = w/h
	local new_hw, new_hh = self:get_cull_extents(hw, hh, far)
	new_hh = math.max(new_hh, new_hw/aspect)
	local new_fov = math.min(math.atan(new_hh/far) * 2, MAX_FOV)
	return new_fov
end


return Curve
