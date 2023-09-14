#ifndef chunks_h
#define chunks_h

#include "voxel.h"
#include "chunk.h"
#include "config.h"
#include <limits>



namespace VoxelGame {

struct RayCastResult {
    dmVMath::Vector3 point;
    dmVMath::Vector3 chunkPos;
    uint8_t side; //0-top 1-bottom 2-right 3-left 4-front 5-back
};

struct Chunks {
    uint32_t volume = 0;
    int chunksWidth, chunksDepth;
    int xMinVoxels, zMinVoxels, xMaxVoxels, zMaxVoxels;
    Chunk* chunks = NULL;
    Chunks();
    ~Chunks();
    void setWorldSize(int xMinVoxels,int zMinVoxels, int xMaxVoxels, int zMaxVoxels);
    uint32_t getChunksMemory();
    Chunk* getChunkByPos(int x, int y, int z);
    void createVoxels();
    uint8_t getVoxel(int x,int y, int z);
    void setVoxel(int x,int y, int z, uint8_t voxel);
    void fillZone(int x1, int y1, int z1,int x2,int y2, int z2, uint8_t voxel);
    void fillHollow();
    void fillZoneMountain(int x1, int y1, int z1,int x2,int y2, int z2, uint8_t voxel,
     float persistence, float frequency, float amplitude, int octaves, int randomseed);
    bool isBlocked(int x,int y, int z);
    bool raycast(dmVMath::Vector3 pos, dmVMath::Vector3 dir, int maxDist, RayCastResult* result);
    void clipWorldSize(int xMinVoxels,int zMinVoxels, int xMaxVoxels, int zMaxVoxels);
    private:
    Chunks(const Chunks&);

};


}

#endif