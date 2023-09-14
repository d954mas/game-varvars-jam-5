#ifndef collision_writer_h
#define collision_writer_h

#include "voxels/chunks.h"

namespace VoxelGame {

void CollisionChunksSave(const char* folder, Chunks* chunks);

}

#endif