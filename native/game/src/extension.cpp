#define EXTENSION_NAME Game
#define LIB_NAME "Game"
#define MODULE_NAME "game"

#include <dmsdk/sdk.h>

#include "camera.h"
#include "utils.h"
#include "frustum_cull.h"
#include "voxels/world.h"
#include "voxels/voxel_atlas.h"
#include "voxels/debug_renderer.h"
#include "objects/frustum_object.h"
#include "wavefront/wavefront_writer.h"
#include "collision_writer/collision_writer.h"
#include "objects/physics_object.h"
#include "objects/distance_object.h"
#include "physics_defold.h"

using namespace VoxelGameUtils;
using namespace VoxelGame;

static const char PHYSICS_CONTEXT_NAME[] = "__PhysicsContext";
static const uint32_t PHYSICS_CONTEXT_HASH = dmHashBuffer32(PHYSICS_CONTEXT_NAME,strlen(PHYSICS_CONTEXT_NAME));

static char* COLLISION_OBJECT_EXT = "collisionobjectc";

namespace dmGameObject {
    void GetComponentUserDataFromLua(lua_State* L, int index, HCollection collection, const char* component_ext, uintptr_t* out_user_data, dmMessage::URL* out_url, void** world);
    PropertyResult GetProperty(HInstance instance, dmhash_t component_id, dmhash_t property_id, PropertyOptions options, PropertyDesc& out_value);
    void* GetWorld(HCollection collection, uint32_t component_type_index);
}

namespace dmScript {
    dmMessage::URL* CheckURL(lua_State* L, int index);
    bool GetURL(lua_State* L, dmMessage::URL& out_url);
    bool GetURL(lua_State* L, dmMessage::URL* out_url);
    void GetGlobal(lua_State*L, uint32_t name_hash);
}


namespace dmGameSystem
{
    struct BufferResource
    {
        void* m_BufferDDF;
        dmBuffer::HBuffer        m_Buffer;
        dmhash_t                 m_NameHash;
        uint32_t                 m_ElementCount;    // The number of vertices
        uint32_t                 m_Stride;          // The vertex size (bytes)
        uint32_t                 m_Version;
    };
}

namespace dmGameSystem{
    struct PhysicsScriptContext
    {
       dmMessage::HSocket m_Socket;
       uint32_t m_ComponentIndex;
    };
     uint16_t CompCollisionGetGroupBitIndex(void* world, uint64_t group_hash);
      void RayCast(void* world, const dmPhysics::RayCastRequest& request, dmArray<dmPhysics::RayCastResponse>& results);
}

namespace VoxelGame {
    extern World world;
}

static int SetScreenSizeLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 2);
    d954Camera::setScreenSize(luaL_checknumber(L, 1), luaL_checknumber(L, 2));
    return 0;
}

static int CameraSetZFarLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 1);
    d954Camera::setZFar(luaL_checknumber(L, 1));
    return 0;
}

static int CameraSetFovLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 1);
    d954Camera::setFov(luaL_checknumber(L, 1));
    return 0;
}

static int CameraSetViewPositionLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 1);
    d954Camera::setViewPosition(*dmScript::CheckVector3(L, 1));
    return 0;
}

static int CameraSetViewRotationLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 1);
    d954Camera::setViewRotation(*dmScript::CheckQuat(L, 1));
    return 0;
}

static int CameraGetViewLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 1);
    d954Camera::getCameraView(dmScript::CheckMatrix4(L, 1));
    return 0;
}

static int CameraGetPerspectiveLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 1);
    d954Camera::getCameraPerspective(dmScript::CheckMatrix4(L, 1));
    return 0;
}

static int CameraScreenToWorldRayLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 6);
    VoxelGameUtils::check_arg_count(L, 2);
    int x = luaL_checknumber(L,1);
    int y = luaL_checknumber(L,2);
    dmVMath::Vector3 pStart;
    dmVMath::Vector3 pEnd;
    d954Camera::screenToWorldRay(x,y,&pStart,&pEnd);
    lua_pushnumber(L,pStart.getX());
    lua_pushnumber(L,pStart.getY());
    lua_pushnumber(L,pStart.getZ());

    lua_pushnumber(L,pEnd.getX());
    lua_pushnumber(L,pEnd.getY());
    lua_pushnumber(L,pEnd.getZ());
    return 6;
}

static int DrawChunksLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 0);
    world.chunkRenderer->draw(L);
    return 0;
}

static int DrawChunksDebugBordersLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 3);
    world.chunkRenderer->drawDebugChunkBorders(L, luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3));
    return 0;
}

static int DrawChunksDebugFrustumLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 3);
    world.chunkRenderer->drawDebugChunkFrustum(L, luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3));
    return 0;
}

static int DrawChunksDebugVerticesLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 3);
    world.chunkRenderer->drawDebugChunkVertices(L, luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3));
    return 0;
}

static int RegisterVoxelAtlasLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 3);
    VoxelAtlasCheck(L);
    return 0;
}

static int DebugGetTotalChunks(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 2);
    lua_pushnumber(L,world.chunks->volume);
    lua_pushnumber(L,world.chunks->getChunksMemory());
    return 2;
}

static int DebugGetTotalBuffers(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 2);
    lua_pushnumber(L,world.chunkRenderer->getBuffersCount());
    lua_pushnumber(L,world.chunkRenderer->getBuffersMemoryCount());
    return 2;
}

static int DebugGetDrawChunks(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 2);
    lua_pushnumber(L,world.chunkRenderer->getChunksCount());
    lua_pushnumber(L,world.chunkRenderer->getChunksVisibleCount());
    return 2;
}
static int DebugGetDrawChunksVertices(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 1);
    lua_pushnumber(L,world.chunkRenderer->getChunksVisibleVertices());
    return 1;
}


static int RaycastLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 1);
    VoxelGameUtils::check_arg_count(L, 3);
    dmVMath::Vector3* position = dmScript::CheckVector3(L, 1);
    dmVMath::Vector3* dir = dmScript::CheckVector3(L, 2);
    int maxDist = luaL_checknumber(L,3);
    RayCastResult result;
    bool collide = world.chunks->raycast(*position,*dir, maxDist,&result);

    if(collide){
        lua_newtable(L);
        dmScript::PushVector3(L,result.point);
        lua_setfield(L, -2, "point");
        dmScript::PushVector3(L,result.chunkPos);
        lua_setfield(L, -2, "chunk_pos");
        lua_pushnumber(L,result.side);
        lua_setfield(L, -2, "side");
    }else{
        lua_pushnil(L);
    }
    return 1;
}

static int ChunksSetVoxelLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 4);
    int x = luaL_checknumber(L,1);
    int y = luaL_checknumber(L,2);
    int z = luaL_checknumber(L,3);
    int voxel = luaL_checknumber(L,4);
    world.chunks->setVoxel(x, y, z, voxel);
    return 0;
}

static int ChunksFillZoneLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 7);
    world.chunks->fillZone(luaL_checknumber(L,1), luaL_checknumber(L,2), luaL_checknumber(L,3),
    luaL_checknumber(L,4),luaL_checknumber(L,5),luaL_checknumber(L,6),luaL_checknumber(L,7));
    return 0;
}

static int ChunksFillZoneMountainLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 12);
    world.chunks->fillZoneMountain(luaL_checknumber(L,1), luaL_checknumber(L,2), luaL_checknumber(L,3),
    luaL_checknumber(L,4),luaL_checknumber(L,5),luaL_checknumber(L,6),luaL_checknumber(L,7),
    luaL_checknumber(L,8),luaL_checknumber(L,9),luaL_checknumber(L,10),luaL_checknumber(L,11),luaL_checknumber(L,12));
    return 0;
}

static int ChunksClipWorldSizeLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 4);
    world.chunks->clipWorldSize(luaL_checknumber(L,1), luaL_checknumber(L,2), luaL_checknumber(L,3),luaL_checknumber(L,4));
    return 0;
}

static int ChunksFillHollowLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 0);
    world.chunks->fillHollow();
    return 0;
}

static int ChunksGetVoxelLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 1);
    VoxelGameUtils::check_arg_count(L, 3);
    int x = luaL_checknumber(L,1);
    int y = luaL_checknumber(L,2);
    int z = luaL_checknumber(L,3);
    lua_pushnumber(L,world.chunks->getVoxel(x, y, z));
    return 1;
}

static int GetWorldLevelDataLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 1);
    VoxelGameUtils::check_arg_count(L, 0);
    uint8_t *buffer;
    uint32_t bufferLen;
    world.getWorldLevelData(&buffer, &bufferLen);
    lua_pushlstring(L, (char*)buffer,bufferLen);

    delete[] buffer;
    return 1;
}

static int LoadWorldLevelDataLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 1);

    size_t len;
    const char* data =  luaL_checklstring(L, 1, &len);

    dmLogInfo("load size:%.3f Mb",len/1024.0/1024.0);
    world.loadWorldLevelData(L,(const uint8_t*)data,len);
    return 0;
}

static int GenerateNewLevelDataLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 4);

    world.generateNewWorld(L,lua_tonumber(L,1),lua_tonumber(L,2),lua_tonumber(L,3),lua_tonumber(L,4));
    return 0;
}

static int SaveWavefrontObjLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 1);

    const char* folder =  luaL_checkstring(L, 1);
    WavefrontSaveChunks(folder, world.chunks);
    return 0;
}

static int SaveCollisionChunksLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 1);

    const char* path =  luaL_checkstring(L, 1);
    CollisionChunksSave(path, world.chunks);
    return 0;
}

namespace VoxelGame {
    extern dmArray<FrustumObject*> frustum_list;
}

static Frustum g_Frustum;

static int Frustum_Set(lua_State* L){
    dmVMath::Matrix4* m = dmScript::CheckMatrix4(L, 1);
    g_Frustum           = Frustum(*m);
    return 0;
}

static int Frustum_Is_Box_Visible(lua_State* L){
    dmVMath::Vector3* v1 = dmScript::CheckVector3(L, 1);
    dmVMath::Vector3* v2 = dmScript::CheckVector3(L, 2);

    const bool visible = g_Frustum.IsBoxVisible(*v1, *v2);

    lua_pushboolean(L, visible);
    return 1;
}

static int FrustumObjectCreateLua(lua_State *L) {
	VoxelGameUtils::check_arg_count(L, 0);
    VoxelGame::FrustumObject* obj = new  VoxelGame::FrustumObject();
    obj->Push(L);
	return 1;
}

static int FrustumObjectsListUpdateLua(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
    VoxelGameUtils::check_arg_count(L, 1);
    Vectormath::Aos::Vector3 *camera_pos = dmScript::CheckVector3(L, 1);
    for(int i=0;i<VoxelGame::frustum_list.Size();i++){
        VoxelGame::FrustumObject* obj = VoxelGame::frustum_list[i];
        bool visible = true;
        if(obj->maxDistance !=-1){
            Vectormath::Aos::Vector3 distv = *camera_pos-obj->position;
            visible = Vectormath::Aos::length(distv)<=obj->maxDistance;
        }

        if(visible){
            visible = g_Frustum.IsBoxVisible(obj->minp, obj->maxp);
        }
        obj->setVisible(L,visible);
    }
	return 0;
}

static int PhysicsCountMask(lua_State *L){
    DM_LUA_STACK_CHECK(L, 1);
    VoxelGameUtils::check_arg_count(L, 1);
    uint32_t mask = 0;
    luaL_checktype(L, 1, LUA_TTABLE);


    dmScript::GetGlobal(L, PHYSICS_CONTEXT_HASH);
    dmGameSystem::PhysicsScriptContext* context = (dmGameSystem::PhysicsScriptContext*)lua_touserdata(L, -1);
    lua_pop(L, 1);

    dmGameObject::HInstance sender_instance = dmScript::CheckGOInstance(L);
    dmGameObject::HCollection collection = dmGameObject::GetCollection(sender_instance);
    void* world = dmGameObject::GetWorld(collection, context->m_ComponentIndex);
    if (world == 0x0)
    {
        return DM_LUA_ERROR("Physics world doesn't exist. Make sure you have at least one physics component in collection.");
    }

    lua_pushnil(L);
    while (lua_next(L, 1) != 0)
    {
        mask |= dmGameSystem::CompCollisionGetGroupBitIndex(world, dmScript::CheckHash(L, -1));
        lua_pop(L, 1);
    }
    lua_pushnumber(L,mask);
    return 1;
}

int Physics_RayCastSingleExist(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 1);

    dmMessage::URL sender;
    if (!dmScript::GetURL(L, &sender)) {
        return luaL_error(L, "could not find a requesting instance for physics.raycast");
    }

    dmScript::GetGlobal(L, PHYSICS_CONTEXT_HASH);
    dmGameSystem::PhysicsScriptContext* context = (dmGameSystem::PhysicsScriptContext*)lua_touserdata(L, -1);
    lua_pop(L, 1);

    dmGameObject::HInstance sender_instance = dmScript::CheckGOInstance(L);
    dmGameObject::HCollection collection = dmGameObject::GetCollection(sender_instance);
    void* world = dmGameObject::GetWorld(collection, context->m_ComponentIndex);
    if (world == 0x0)
    {
        return DM_LUA_ERROR("Physics world doesn't exist. Make sure you have at least one physics component in collection.");
    }

    dmVMath::Point3 from( *dmScript::CheckVector3(L, 1) );
    dmVMath::Point3 to( *dmScript::CheckVector3(L, 2) );

    uint32_t mask = luaL_checknumber(L,3);


    dmArray<dmPhysics::RayCastResponse> hits;
    hits.SetCapacity(32);

    dmPhysics::RayCastRequest request;
    request.m_From = from;
    request.m_To = to;
    request.m_Mask = mask;
    request.m_ReturnAllResults = 0;

    dmGameSystem::RayCast(world, request, hits);
    lua_pushboolean(L,!hits.Empty());
    return 1;
}

int Physics_RayCastSingle(lua_State* L)
{
  //  DM_LUA_STACK_CHECK(L, 4);

    dmMessage::URL sender;
    if (!dmScript::GetURL(L, &sender)) {
        return luaL_error(L, "could not find a requesting instance for physics.raycast");
    }

    dmScript::GetGlobal(L, PHYSICS_CONTEXT_HASH);
    dmGameSystem::PhysicsScriptContext* context = (dmGameSystem::PhysicsScriptContext*)lua_touserdata(L, -1);
    lua_pop(L, 1);

    dmGameObject::HInstance sender_instance = dmScript::CheckGOInstance(L);
    dmGameObject::HCollection collection = dmGameObject::GetCollection(sender_instance);
    void* world = dmGameObject::GetWorld(collection, context->m_ComponentIndex);
    if (world == 0x0)
    {
        return luaL_error(L,"Physics world doesn't exist. Make sure you have at least one physics component in collection.");
    }

    dmVMath::Point3 from( *dmScript::CheckVector3(L, 1) );
    dmVMath::Point3 to( *dmScript::CheckVector3(L, 2) );

    uint32_t mask = luaL_checknumber(L,3);

    dmArray<dmPhysics::RayCastResponse> hits;
    hits.SetCapacity(32);

    dmPhysics::RayCastRequest request;
    request.m_From = from;
    request.m_To = to;
    request.m_Mask = mask;
    request.m_ReturnAllResults = 0;

    dmGameSystem::RayCast(world, request, hits);
    lua_pushboolean(L,!hits.Empty());
    if(hits.Empty()){
        return 1;
    }else{
        dmPhysics::RayCastResponse& resp1 = hits[0];
        lua_pushnumber(L,resp1.m_Position.getX());
        lua_pushnumber(L,resp1.m_Position.getY());
        lua_pushnumber(L,resp1.m_Position.getZ());

        lua_pushnumber(L,resp1.m_Normal.getX());
        lua_pushnumber(L,resp1.m_Normal.getY());
        lua_pushnumber(L,resp1.m_Normal.getZ());
        return 7;
    }
}

static int PathfindingIsBlockedData(lua_State *L) {
	VoxelGameUtils::check_arg_count(L, 2);
    PathCell* cell = world.map.getCell(lua_tonumber(L,1),lua_tonumber(L,2));
    if(cell == NULL){
        lua_pushboolean(L,true);
    }else{
          lua_pushboolean(L,cell->blocked);
    }
	return 1;
}

static int PathfindingSetBlockedData(lua_State *L) {
	VoxelGameUtils::check_arg_count(L, 3);
    PathCell* cell = world.map.getCell(lua_tonumber(L,1),lua_tonumber(L,2));
    cell->blocked = lua_toboolean(L,3);
    world.map.Reset();
	return 0;
}

static int PathfindingFindPath(lua_State *L) {
	VoxelGameUtils::check_arg_count(L, 4);
    dmArray<PathCell> cells;
    cells.SetCapacity(16);
    int result = world.map.findPath(lua_tonumber(L,1),lua_tonumber(L,2),lua_tonumber(L,3),lua_tonumber(L,4),&cells);
    if(result == MicroPather::MicroPather::SOLVED){
        lua_newtable(L);
        for(int i=0;i<cells.Size();i++){
            PathCell cell = cells[i];
            dmScript::PushVector3(L,dmVMath::Vector3(cell.x,0,cell.z));
            lua_rawseti(L, -2, i+1);
        }
    }else{
        lua_pushnil(L);
    }

	return 1;
}

static int SmoothDumpV3(lua_State *L) {
    DM_LUA_STACK_CHECK(L, 0);
	VoxelGameUtils::check_arg_count(L, 7);

    dmVMath::Vector3 *currentV3 = dmScript::CheckVector3(L, 1);
    dmVMath::Vector3 current = *currentV3;
    dmVMath::Vector3 target = *dmScript::CheckVector3(L, 2);
    dmVMath::Vector3 *currentVelocity = dmScript::CheckVector3(L, 3);
    dmVMath::Vector3 velocity = *currentVelocity;

    float smoothTime = luaL_checknumber(L,4);
    float maxSpeed = luaL_checknumber(L,5);
    float maxDistance = luaL_checknumber(L,6);
    float dt = luaL_checknumber(L,7);


    smoothTime = fmax(0.0001, smoothTime);

    float num = (2.0 / smoothTime);
    float num2 = (num * dt);
    float d = (1.0 / (1.0 + num2 + 0.48 * num2 * num2 + 0.235 * num2 * num2 * num2));



    dmVMath::Vector3 vector = (current - target);
    dmVMath::Vector3 vector2 = target;

    float maxLength = (maxSpeed * smoothTime);

    vector = Vectormath::Aos::length(vector) > maxLength ? (Vectormath::Aos::normalize(vector) * maxLength) : vector; // Clamp magnitude.
    dmVMath::Vector3 distance = (current - vector);

    dmVMath::Vector3 vector3 = ((velocity + num * vector) * dt);
    velocity = ((velocity - num * vector3) * d);

    dmVMath::Vector3 vector4 = (distance + (vector + vector3) * d);
    if(Vectormath::Aos::dot(vector2 - current,vector4 - vector2)>0){
        vector4 = vector2;
        velocity = ((vector4 - vector2) / dt);
    }

    *currentV3 = vector4;
    *currentVelocity = velocity;

    //check maxDistance
    vector = vector4-target;
    if(Vectormath::Aos::length(vector)>maxDistance){
        dmVMath::Vector3 dmove = Vectormath::Aos::normalize(vector) * maxDistance;
        *currentV3 =  target+dmove;
    }

	return 0;
}







// Functions exposed to Lua
static const luaL_reg Module_methods[] = {
    {"set_screen_size", SetScreenSizeLua},
    {"camera_set_view_position", CameraSetViewPositionLua},
    {"camera_set_z_far", CameraSetZFarLua},
    {"camera_set_fov", CameraSetFovLua},
    {"camera_set_view_rotation", CameraSetViewRotationLua},
	{"camera_get_view", CameraGetViewLua},
	{"camera_get_perspective", CameraGetPerspectiveLua},
	{"camera_screen_to_world_ray", CameraScreenToWorldRayLua},

	{"debug_get_total_chunks", DebugGetTotalChunks},
	{"debug_get_total_buffers", DebugGetTotalBuffers},
	{"debug_get_draw_chunks", DebugGetDrawChunks},
	{"debug_get_draw_chunks_vertices", DebugGetDrawChunksVertices},

	{"draw_chunks", DrawChunksLua},
	{"draw_chunks_debug_borders", DrawChunksDebugBordersLua},
	{"draw_chunks_debug_frustum", DrawChunksDebugFrustumLua},
	{"draw_chunks_debug_vertices", DrawChunksDebugVerticesLua},

	{"register_voxel_atlas", RegisterVoxelAtlasLua},

	{"chunks_set_voxel", ChunksSetVoxelLua},
	{"chunks_get_voxel", ChunksGetVoxelLua},
	{"chunks_fill_zone", ChunksFillZoneLua},
    {"chunks_fill_zone_mountain", ChunksFillZoneMountainLua},
	{"chunks_clip_size", ChunksClipWorldSizeLua},
	{"chunks_fill_hollow", ChunksFillHollowLua},


	{"get_world_level_data", GetWorldLevelDataLua},
	{"load_world_level_data", LoadWorldLevelDataLua},
	{"save_wavefront_obj", SaveWavefrontObjLua},
	{"save_collision_chunks", SaveCollisionChunksLua},
	{"generate_new_level_data",GenerateNewLevelDataLua},

    { "frustum_set", Frustum_Set },
    { "frustum_is_box_visible", Frustum_Is_Box_Visible },
    { "frustum_object_create", FrustumObjectCreateLua },
    { "frustum_objects_list_update", FrustumObjectsListUpdateLua },

    { "physics_object_create", VoxelGame::PhysicsObjectCreate},
    { "physics_object_destroy", VoxelGame::PhysicsObjectDestroy},
    { "physics_object_set_update_position", VoxelGame::PhysicsObjectSetUpdatePosition},
    { "physics_objects_update_variables", VoxelGame::PhysicsObjectsUpdateVariables},
    { "physics_objects_update_linear_velocity", VoxelGame::PhysicsObjectsUpdateLinearVelocity},

    { "distance_object_create", VoxelGame::DistanceObjectCreate},
    { "distance_object_destroy", VoxelGame::DistanceObjectDestroy},
    { "distance_objects_update", VoxelGame::DistanceObjectsUpdate},


    { "physics_raycast_single_exist", Physics_RayCastSingleExist },
    { "physics_raycast_single", Physics_RayCastSingle},
    { "physics_count_mask", PhysicsCountMask},


    { "pathfinding_is_blocked", PathfindingIsBlockedData},
    { "pathfinding_set_blocked", PathfindingSetBlockedData},
    { "pathfinding_find_path", PathfindingFindPath},

    { "smooth_dump_v3", SmoothDumpV3},


	{"raycast", RaycastLua},

    {0, 0}

};

static void LuaInit(lua_State *L) {
    int top = lua_gettop(L);
    luaL_register(L, MODULE_NAME, Module_methods);
    lua_pop(L, 1);
    VoxelGame::FrustumObjectInitMetaTable(L);
    assert(top == lua_gettop(L));
}

static dmExtension::Result AppInitializeMyExtension(dmExtension::AppParams *params) { return dmExtension::RESULT_OK; }
static dmExtension::Result InitializeMyExtension(dmExtension::Params *params) {
    // Init Lua
    LuaInit(params->m_L);
    d954Camera::reset();

    printf("Registered %s Extension\n", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

static dmExtension::Result AppFinalizeMyExtension(dmExtension::AppParams *params) { return dmExtension::RESULT_OK; }

static dmExtension::Result FinalizeMyExtension(dmExtension::Params *params) { return dmExtension::RESULT_OK; }

DM_DECLARE_EXTENSION(EXTENSION_NAME, LIB_NAME, AppInitializeMyExtension, AppFinalizeMyExtension, InitializeMyExtension, 0, 0, FinalizeMyExtension)