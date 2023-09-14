local LUME = require "libs.lume"
local BUFFER = require "libs_project.buffer"
local COMMON = require "libs.common"
local VOXELS = require "world.balance.def.voxels"

local FACTORY_CHUNK_URL = msg.url("game_scene:/factory#chunk")
local ATLAS_TEXTURE
local SHADOW_TEXTURE

local BUFFER_TO_MESH_URL = {}

--REGISTER SOME FUNCTIONS TO CALL THEM FROM C++
function native_create_chunk_renderer_go()
	local root_url = msg.url(factory.create(FACTORY_CHUNK_URL))
	local mesh_url = LUME.url_component_from_url(root_url, "mesh")
	local buffer_data = BUFFER.get()
	BUFFER_TO_MESH_URL[root_url.path] = buffer_data
	go.set(mesh_url, "vertices", buffer_data.buffer)
	go.set(mesh_url, 'texture0', ATLAS_TEXTURE)
	go.set(mesh_url, 'texture1', ATLAS_TEXTURE)
	return root_url
end

--REGISTER SOME FUNCTIONS TO CALL THEM FROM C++
function native_delete_chunk_renderer_go(root_url)
	local buffer_data = assert(BUFFER_TO_MESH_URL[root_url.path])
	BUFFER_TO_MESH_URL[root_url.path] = nil
	BUFFER.free(buffer_data)
	go.delete(root_url, true)
end

function native_update_chunk_buffer(mesh_url, buffer)
	resource.set_buffer(go.get(mesh_url, "vertices"), buffer, { transfer_ownership = true })
end

function native_get_chunk_buffer(mesh_url)
	return resource.get_buffer(go.get(mesh_url, "vertices"))
end

local M = {}

function M.init_atlas()
	SHADOW_TEXTURE = go.get("main:/resources#atlas_handler", "shadow_texture")
	local my_texture_info = resource.get_texture_info(SHADOW_TEXTURE)
	SHADOW_TEXTURE_HANDLE = my_texture_info.handle
	local path = go.get("main:/resources#atlas_handler", "atlas")

	local atlas = resource.get_atlas(path)
	ATLAS_TEXTURE = hash(atlas.texture)
	local texture_info = resource.get_texture_info and resource.get_texture_info(ATLAS_TEXTURE) or {width = 256, height = 256}
	local w, h = texture_info.width, texture_info.height

	local data_by_id = {}

	for i = 1, #atlas.animations do
		local anim = atlas.animations[i]
		data_by_id[anim.id] = { animation = anim, geometry = atlas.geometries[i] }
	end
	local images = {}

	for idx = 0, #VOXELS.VOXELS do
		local block_id = VOXELS.VOXELS[idx].img;
		if (block_id) then
			local data = assert(data_by_id[block_id], "no block with id:" .. block_id)
			local image = {
				uvs = LUME.clone_shallow(assert(data.geometry.uvs))
			}
			--normalize uv
			for i = 0, 3 do
				image.uvs[i * 2 + 1] = image.uvs[i * 2 + 1] / w
				image.uvs[i * 2 + 2] = (h - image.uvs[i * 2 + 2]) / h
			end
			images[idx] = image
		else
			images[idx] = false --not used block
		end
	end
	for i = 0, #images do
		local image = images[i]
		if (image) then
			COMMON.RENDER.chunk_opts.constants.chunks_uv[i * 2 + 1] = vmath.vector4(image.uvs[1], image.uvs[2], image.uvs[3], image.uvs[4]) --0,1
			COMMON.RENDER.chunk_opts.constants.chunks_uv[i * 2 + 2] = vmath.vector4(image.uvs[5], image.uvs[6], image.uvs[7], image.uvs[8]) --2,3
		else
			COMMON.RENDER.chunk_opts.constants.chunks_uv[i * 2 + 1] = vmath.vector4(0)
			COMMON.RENDER.chunk_opts.constants.chunks_uv[i * 2 + 2] = vmath.vector4(0)
		end
	end
	game.register_voxel_atlas(w, h, images)
end

return M
