#ifndef voxel_atlas_h
#define voxel_atlas_h

#include <dmsdk/sdk.h>

namespace VoxelGame{

struct VoxelAtlasVoxelUV {
    float uv0[2];
    float uv1[2];
    float uv2[2];
    float uv3[2];
    bool valid = false;
};

struct VoxelAtlas {
    int w=0, h=0;
    int maxVoxelId = 0;

    VoxelAtlasVoxelUV errorBlock;
    VoxelAtlasVoxelUV* uvs = NULL;

    VoxelAtlas(){}

    ~VoxelAtlas(){
        if(uvs != NULL){
            delete[] uvs;
        }
    }
     private:
        VoxelAtlas(const VoxelAtlas&);
};

void VoxelAtlasCheck(lua_State *L);
VoxelAtlasVoxelUV VoxelAtlasGetUV(int voxelId);

}

#endif