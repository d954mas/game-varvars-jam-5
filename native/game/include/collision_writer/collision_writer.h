#ifndef collision_writer_h
#define collision_writer_h

#include "voxels/chunks.h"
#include <dmsdk/sdk.h>

namespace VoxelGame {

void CollisionChunksGet(lua_State *L, Chunks* chunks);

}

#endif