#ifndef chunk_h
#define chunk_h

#include "config.h"
#include "voxel.h"
#include <cstring>
#include <cassert>
#include <dmsdk/sdk.h>


namespace VoxelGame {

struct Chunk {
    int x,y,z;
    int voxelsSize = 0;
    Voxel* voxels; //[y][z][x]
    float aabb[6];
    int yBegin=0, yEnd=0;
    //start from 1. goChunk will start from 0. so it will update for first time
    uint32_t contentVersion = 1;
    Chunk();
    ~Chunk();
    private:
    Chunk(const Chunk&);
};

inline int ChunkVoxelPosToIdx(int x, int y, int z){
    return x + (z + y * CHUNK_D) * CHUNK_W;
}

inline void ChunkCheckResize(Chunk *chunk){
    int yBegin = chunk->aabb[1];
    int yEnd = chunk->aabb[4];//exclude end yBegin<=y<End
    //dmLogInfo("yBegin:%d yEnd:%d", yBegin,yEnd);
   // dmLogInfo("chunk yBegin:%d yEnd:%d", chunk->yBegin,chunk->yEnd);
    if(chunk->yBegin!=yBegin || chunk->yEnd !=yEnd){
        //dmLogInfo("yBegin:%d yEnd:%d", yBegin,yEnd);
        int size = (yEnd-yBegin)*CHUNK_W*CHUNK_D;
        Voxel* newVoxels = new Voxel[size]();
        //copy to new array
        if(chunk->voxelsSize!=0 && size != 0){
            Voxel* dst = newVoxels;
            Voxel* src = chunk->voxels;
            int overlapBegin = fmax(yBegin,chunk->yBegin);
            int overlapEnd= fmin(yEnd,chunk->yEnd);
            uint32_t copySize = overlapEnd-overlapBegin;
            if(copySize>0){
                if(overlapBegin>yBegin){
                    dst += (overlapBegin-yBegin)*CHUNK_W*CHUNK_D;
                }
                if(overlapBegin>chunk->yBegin){
                    src += (overlapBegin-chunk->yBegin)*CHUNK_W*CHUNK_D;
                }
                memcpy(dst, src, copySize*CHUNK_W*CHUNK_D*sizeof(Voxel));
            }
          /*  for(int y = fmax(yBegin,chunk->yBegin);y<fmin(yEnd,chunk->yEnd);y++){
                int yDst = (y-yBegin)*CHUNK_W*CHUNK_D;
                int ySrt = (y-chunk->yBegin)*CHUNK_W*CHUNK_D;
                for(int idx=0;idx<CHUNK_W*CHUNK_D;idx++){
                    newVoxels[yDst+idx] = chunk->voxels[ySrt+idx];
                }
            }*/
               // dmLogInfo("size:%d/%d",size,(endIdx-startIdx-1)*sizeof(Voxel));
               // assert(size == (endIdx-startIdx)*sizeof(Voxel));
                //int size = max(yEnd-yBegin,chunk->yBegin-chunk->yBegin)
               // memcpy(dst, src, size);
        }

        delete[] chunk->voxels;


        chunk->voxels = newVoxels;
        chunk->yBegin = yBegin;
        chunk->yEnd = yEnd;
        chunk->voxelsSize = size;
    }
}

void ChunkSetVoxel(Chunk *chunk, int x, int y, int z, uint8_t id);

inline uint8_t ChunkGetVoxel(Chunk *chunk, int x, int y, int z){
    if(y<chunk->yBegin){ return 0; }
    if(y>=chunk->yEnd){ return 0; }
    int id = ChunkVoxelPosToIdx(x,y-chunk->yBegin,z);
    return chunk->voxels[id].id;
}

inline bool ChunkIsPosInside(int x, int y, int z){
    return x >= 0 && x < CHUNK_W &&  z >= 0 && z < CHUNK_D;
}

inline bool ChunkIsBlocked(Chunk *chunk, int x, int y, int z){
    return ChunkIsPosInside(x,y,z) && ChunkGetVoxel(chunk, x,y,z) >0;
}





} // namespace d954Game

#endif