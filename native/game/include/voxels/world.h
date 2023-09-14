#ifndef world_h
#define world_h

#include "voxel.h"
#include "chunk.h"
#include "chunks.h"
#include "chunk_renderer.h"
#include "pathfinding/map.h"


namespace VoxelGame {

struct World {
    public:
    Chunks* chunks;
    ChunkRenderer* chunkRenderer;
    Map map;

    World();
    ~World();

    void getWorldLevelData(uint8_t** buffer, uint32_t* len);
    void loadWorldLevelData(lua_State *L,const uint8_t* buffer, uint32_t len);
    void generateNewWorld(lua_State *L,int minX, int minZ, int maxX, int maxZ);

};



} // namespace VoxelGame

#endif