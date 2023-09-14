#include "voxels/chunk.h"

namespace VoxelGame {

Chunk::Chunk() {
    voxels = new Voxel[0];
    for(int i=0;i<6;++i){
        aabb[i] = 0;
    }
}

Chunk::~Chunk() {
    delete[] voxels;
}

void ChunkSetVoxel(Chunk *chunk, int x, int y, int z, uint8_t id){
    if(y<0||y>254){
         dmLogInfo("can't set voxel outside of world:%d", y);
         return;
    }
    //update bbox sizes
    if(id!=0){
        if (x < chunk->aabb[0]) {chunk->aabb[0] = x;}
        if (y < chunk->aabb[1]){
            chunk->aabb[1] = y;
            ChunkCheckResize(chunk);
        }
        if (z < chunk->aabb[2]){ chunk->aabb[2] = z;}
        if(x + 1 > chunk->aabb[3]) {chunk->aabb[3] = x + 1;}
        if (y + 1 > chunk->aabb[4]){
            chunk->aabb[4] = y + 1;
            ChunkCheckResize(chunk);
        }
        if (z + 1 > chunk->aabb[5]){ chunk->aabb[5] = z + 1;}
    }

    if(id == 0 && (y>=chunk->yEnd||y<chunk->yBegin)){ return; }

    assert(y>=chunk->yBegin);
   // dmLogInfo("y:%d yEnd:%d id:%d", y, chunk->yEnd, id);
    assert(y<chunk->yEnd);
    y-=chunk->yBegin;
    chunk->voxels[ChunkVoxelPosToIdx(x,y,z)].id = id;
    chunk->contentVersion++;
}

} // namespace VoxelGame