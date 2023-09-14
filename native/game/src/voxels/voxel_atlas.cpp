#include "voxels/voxel_atlas.h"

namespace VoxelGame{

static VoxelAtlas atlas;

static float TableGetNumber(lua_State *L, int idx, int n){
    lua_rawgeti(L, idx, n);
    float result = luaL_checknumber(L,-1);
    lua_pop(L,1);
    return result;
}

static VoxelAtlasVoxelUV CheckVoxelAtlasVoxelUV(lua_State *L){
    VoxelAtlasVoxelUV result;
    if (lua_istable(L, -1)) {
        result.valid = true;
        lua_getfield(L, -1, "uvs");
        result.uv0[0] = TableGetNumber(L, -1, 1);
        result.uv0[1] = TableGetNumber(L, -1, 2);
        result.uv1[0] = TableGetNumber(L, -1, 3);
        result.uv1[1] = TableGetNumber(L, -1, 4);
        result.uv2[0] = TableGetNumber(L, -1, 5);
        result.uv2[1] = TableGetNumber(L, -1, 6);
        result.uv3[0] = TableGetNumber(L, -1, 7);
        result.uv3[1] = TableGetNumber(L, -1, 8);
        lua_pop(L,1);
    }else{
        result.valid = false;
    }

    return result;
}

void VoxelAtlasCheck(lua_State *L){
    atlas.w = luaL_checknumber(L, 1);
    atlas.h = luaL_checknumber(L, 2);
    if (!lua_istable(L, 3)){
        luaL_error(L, "atlas images must be table");
    }
    atlas.maxVoxelId = luaL_getn(L, 3);
    //dmLogInfo("maxVoxelId:%d",atlas.maxVoxelId);

    //lua_rawgeti(L, 3, -1);
   // atlas.errorBlock = CheckVoxelAtlasVoxelUV(L);
  //  assert(atlas.errorBlock.valid);
    //lua_pop(L,1);

    atlas.uvs = new VoxelAtlasVoxelUV[atlas.maxVoxelId+1]();
    for (int i = 0; i<=atlas.maxVoxelId; ++i) {
        lua_rawgeti(L, 3, i);
        atlas.uvs[i] = CheckVoxelAtlasVoxelUV(L);
        lua_pop(L,1);
    }
    atlas.errorBlock = atlas.uvs[0];

}

VoxelAtlasVoxelUV VoxelAtlasGetUV(int voxelId){
    if(voxelId<=0){
        return atlas.errorBlock;
    }else if(voxelId>atlas.maxVoxelId){
        return atlas.errorBlock;
    }
    VoxelAtlasVoxelUV block = atlas.uvs[voxelId];
    if(block.valid){
        return block;
    }else{
        return atlas.errorBlock;
    }
}



}
