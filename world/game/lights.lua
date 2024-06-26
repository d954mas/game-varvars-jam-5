local COMMON = require "libs.common"

local V4 = vmath.vector4()
local VIEW_DIRECTION = vmath.vector3()
local VIEW_RIGHT = vmath.vector3()
local VIEW_UP = vmath.vector3()

local V_UP = vmath.vector3(0, 1, 0)

local Lights = COMMON.class("lights")

local function create_depth_buffer(w, h)
	local color_params = {
		-- format     = render.FORMAT_RGBA,
		format = render.FORMAT_R32F,
		width = w,
		height = h,
		min_filter = render.FILTER_NEAREST,
		mag_filter = render.FILTER_NEAREST,
		u_wrap = render.WRAP_CLAMP_TO_EDGE,
		v_wrap = render.WRAP_CLAMP_TO_EDGE }

	local depth_params = {
		format = render.FORMAT_DEPTH,
		width = w,
		height = h,
		min_filter = render.FILTER_NEAREST,
		mag_filter = render.FILTER_NEAREST,
		u_wrap = render.WRAP_CLAMP_TO_EDGE,
		v_wrap = render.WRAP_CLAMP_TO_EDGE }

	return render.render_target("shadow_buffer", { [render.BUFFER_COLOR_BIT] = color_params, [render.BUFFER_DEPTH_BIT] = depth_params })
end

---@param world World
function Lights:initialize(world)
	self.world = assert(world)
	self.constants = {}
	self.ambient_color = vmath.vector4()
	self.sunlight_color = vmath.vector4()
	self.shadow_color = vmath.vector4()

	self.shadow = {
		-- Size of shadow map. Select value from: 1024/2048/4096. More is better quality.
		BUFFER_RESOLUTION = 1024,
		-- Projection resolution of shadow map to the game world. Smaller size is better shadow quality,
		-- but shadows will cast only around the screen center (or a point that camera looks at).
		-- This value also depends on camera zoom. Feel free to adjust it.
		PROJECTION_RESOLUTION = 75,
		PROJECTION_X1= -40,
		PROJECTION_X2= 5,
		PROJECTION_Y1 = -37.5,
		PROJECTION_Y2 = 37.5,

		PROJECTION_V_X1= -65,
		PROJECTION_V_X2= 10,
		PROJECTION_V_Y1 = -27,
		PROJECTION_V_Y2 = 27,

		pred = nil,
		chunk_pred = nil,
		sprite_pred = nil,
		light_projection = nil,
		light_projection_v = nil,
		bias_matrix = vmath.matrix4(),
		light_matrix = vmath.matrix4(),
		constants = render.constant_buffer(),
		sun_position = vmath.vector3(-10, 0, 0), --delta to root position
		root_position = vmath.vector3(0), --player position
		light_position = vmath.vector3(0), --root_position + sun_position
		light_transform = vmath.matrix4(),
		rt = nil,
		draw_shadow_opts = { frustum = vmath.matrix4() },
		draw_transient = { transient = { render.BUFFER_DEPTH_BIT } },
		draw_clear = { [render.BUFFER_COLOR_BIT] = vmath.vector4(1, 1, 1, 1), [render.BUFFER_DEPTH_BIT] = 1 }

	}
end

function Lights:add_constants(constant)
	table.insert(self.constants, constant)
	constant.sunlight_color = self.ambient_color
	constant.shadow_color = self.shadow_color
	constant.ambient_color = self.ambient_color
	constant.lights_direction = {}
	constant.lights_color = {}
	constant.lights_position = {}
	constant.lights_data1 = {}
	constant.lights = vmath.vector4()
end

---@param render Render
function Lights:set_render(render_obj)
	self.render = assert(render_obj)

	-- all objects that have to cast shadows
	self.shadow.pred = render.predicate({ "shadow" })
	self.shadow.chunk_pred = render.predicate({ "shadow_chunk" })
	self.shadow.sprite_pred = render.predicate({ "shadow_sprite" })

	self.shadow.light_projection = vmath.matrix4_orthographic(self.shadow.PROJECTION_X1, self.shadow.PROJECTION_X2,
			self.shadow.PROJECTION_Y1, self.shadow.PROJECTION_Y2, -50, 150)
	self.shadow.light_projection_v = vmath.matrix4_orthographic(self.shadow.PROJECTION_V_X1, self.shadow.PROJECTION_V_X2,
			self.shadow.PROJECTION_V_Y1, self.shadow.PROJECTION_V_Y2, -50, 150)
	self.shadow.bias_matrix.c0 = vmath.vector4(0.5, 0.0, 0.0, 0.0)
	self.shadow.bias_matrix.c1 = vmath.vector4(0.0, 0.5, 0.0, 0.0)
	self.shadow.bias_matrix.c2 = vmath.vector4(0.0, 0.0, 0.5, 0.0)
	self.shadow.bias_matrix.c3 = vmath.vector4(0.5, 0.5, 0.5, 1.0)


	self:reset()
end

function Lights:reset()
	if (not self.render) then return end
	self:set_sunlight_color(1, 1, 1)
	self:set_sunlight_color_intensity(0.4)
	self:set_shadow_color(0.5, 0.5, 0.5)
	self:set_shadow_color_intensity(1)

	self:set_ambient_color(1, 1, 1)
	self:set_ambient_color_intensity(0.6)

	self:set_sun_position(-4, 10, 0)
end

function Lights:set_ambient_color(r, g, b)
	self.ambient_color.x, self.ambient_color.y, self.ambient_color.z = r, g, b
	for _, constant in ipairs(self.constants) do
		constant.ambient_color = self.ambient_color
	end
end

function Lights:set_ambient_color_intensity(intensity)
	self.ambient_color.w = intensity
	for _, constant in ipairs(self.constants) do
		constant.ambient_color = self.ambient_color
	end
end

function Lights:set_sunlight_color(r, g, b)
	self.sunlight_color.x, self.sunlight_color.y, self.sunlight_color.z = r, g, b
	for _, constant in ipairs(self.constants) do
		constant.sunlight_color = self.sunlight_color
	end
end

function Lights:set_sunlight_color_intensity(intensity)
	self.sunlight_color.w = intensity
	for _, constant in ipairs(self.constants) do
		constant.sunlight_color = self.sunlight_color
	end
end

function Lights:set_shadow_color(r, g, b)
	self.shadow_color.x, self.shadow_color.y, self.shadow_color.z = 1 - r, 1 - g, 1 - b
	for _, constant in ipairs(self.constants) do
		constant.shadow_color = self.shadow_color
	end
end

function Lights:set_shadow_color_intensity(intensity)
	self.shadow_color.w = intensity
	for _, constant in ipairs(self.constants) do
		constant.shadow_color = self.shadow_color
	end
end


function Lights:set_sun_position(x, y, z)
	self.shadow.sun_position.x = x
	self.shadow.sun_position.y = y
	self.shadow.sun_position.z = z
	xmath.add(self.shadow.light_position, self.shadow.root_position, self.shadow.sun_position)

	V4.x = self.shadow.sun_position.x
	V4.y = self.shadow.sun_position.y
	V4.z = self.shadow.sun_position.z
	V4.w = 0
	for _, constant in ipairs(self.constants) do
		constant.sun_position = V4
	end
end

function Lights:set_camera(position)
	local dx = math.abs(self.shadow.root_position.x- position.x)
	local dy = math.abs(self.shadow.root_position.y- position.y)
	local dz = math.abs(self.shadow.root_position.z- position.z)
	local current_projection = COMMON.RENDER.screen_size.aspect>=1 and self.shadow.light_projection or self.shadow.light_projection_v


	if(dx<1 and dy<1 and dz<1 and self.current_projection == current_projection)then return end

	self.current_projection = current_projection


	self.shadow.root_position.x = position.x
	self.shadow.root_position.y = position.y
	self.shadow.root_position.z = position.z

	xmath.add(self.shadow.light_position, self.shadow.root_position, self.shadow.sun_position)

	xmath.sub(VIEW_DIRECTION, self.shadow.root_position, self.shadow.light_position)
	xmath.normalize(VIEW_DIRECTION, VIEW_DIRECTION)
	xmath.cross(VIEW_RIGHT, VIEW_DIRECTION, V_UP)
	xmath.normalize(VIEW_RIGHT, VIEW_RIGHT)
	xmath.cross(VIEW_UP, VIEW_RIGHT, VIEW_DIRECTION)
	xmath.normalize(VIEW_UP, VIEW_UP)

	xmath.matrix_look_at(self.shadow.light_transform, self.shadow.light_position, self.shadow.root_position, VIEW_UP)
	local light_projection = COMMON.RENDER.screen_size.aspect>=1 and self.shadow.light_projection or self.shadow.light_projection_v
	xmath.matrix_mul(self.shadow.light_matrix, self.shadow.bias_matrix, light_projection)
	xmath.matrix_mul(self.shadow.light_matrix, self.shadow.light_matrix, self.shadow.light_transform)
	--local mtx_light = self.shadow.bias_matrix * self.shadow.light_projection * self.shadow.light_transform
	for _, constant in ipairs(self.constants) do
		constant.mtx_light = self.shadow.light_matrix
	end
end

function Lights:render_shadows()
	local draw_shadows = self.world.storage.options:draw_shadows_get()
	if (draw_shadows and not self.shadow.rt) then
		self.shadow.rt = create_depth_buffer(self.shadow.BUFFER_RESOLUTION, self.shadow.BUFFER_RESOLUTION)
	end
	if (not draw_shadows and self.shadow.rt) then
		render.delete_render_target(self.shadow.rt)
		self.shadow.rt = nil
	end
	if (not draw_shadows) then return end

	local light_projection = COMMON.RENDER.screen_size.aspect>=1 and self.shadow.light_projection or self.shadow.light_projection_v
	render.set_projection(light_projection)
	render.set_view(self.shadow.light_transform)
	render.set_viewport(0, 0, self.shadow.BUFFER_RESOLUTION, self.shadow.BUFFER_RESOLUTION)

	render.set_depth_mask(true)
	render.set_depth_func(render.COMPARE_FUNC_LEQUAL)
	render.enable_state(render.STATE_DEPTH_TEST)
	render.enable_state(render.STATE_CULL_FACE)
	render.disable_state(render.STATE_BLEND)
	render.disable_state(render.STATE_STENCIL_TEST)

	render.set_render_target(self.shadow.rt, self.shadow.draw_transient)
	render.clear(self.shadow.draw_clear)
	xmath.matrix_mul(self.shadow.draw_shadow_opts.frustum, light_projection, self.shadow.light_transform)
	render.enable_material("shadow_chunk")
	render.draw(self.shadow.chunk_pred, self.shadow.draw_shadow_opts)
	render.disable_material()
	render.enable_material("shadow")
	render.draw(self.shadow.pred, self.shadow.draw_shadow_opts)
	render.disable_state(render.STATE_CULL_FACE)
	render.draw(self.shadow.sprite_pred, self.shadow.draw_shadow_opts)
	render.enable_state(render.STATE_CULL_FACE)
	render.disable_material()
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

return Lights