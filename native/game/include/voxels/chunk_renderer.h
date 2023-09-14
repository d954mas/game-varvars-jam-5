#ifndef chunk_renderer_h
#define chunk_renderer_h

#include <dmsdk/sdk.h>
#include "chunk.h"
#include "voxel.h"
#include "dmsdk_internal.h"


namespace VoxelGame {

struct World;

struct GoChunk {
    int vertices = 0;
    uint32_t contentVersion = 0;
    uint32_t bufferMemory = 0;
    dmMessage::URL rootUrl;
    dmMessage::URL meshUrl;
    Chunk* chunk = NULL;
    bool goCreated = false;

    GoChunk(Chunk* chunk) : chunk(chunk){}
    private:
        GoChunk(const GoChunk&);
};

//saved plane data. Then draw that plane on new created buffer
struct ChunkVertexPlane {
    int x,y,z;//voxel coords
    uint8_t voxel;
    uint8_t side; //0-top 1-bottom 2-right 3-left 4-front 5-back
    uint8_t ao0,ao1,ao2,ao3;
    //for greedy meshing(sort 2d quads)
    int planeX, planeY; //upper left
    int planeZ; // in 2d quads. Can merge only quads with same Z
    int  planeW, planeH;
    ChunkVertexPlane(int x,int y,int z,uint8_t voxel,uint8_t side, uint8_t ao0,uint8_t ao1, uint8_t ao2, uint8_t ao3)
        : x(x), y(y), z(z), voxel(voxel), side(side), ao0(ao0), ao1(ao1), ao2(ao2), ao3(ao3) {
            planeW = 1;
            planeH = 1;
            switch(side){
                //top/bottom
                case 0:
                case 1:{
                    planeX = x;
                    planeY = z;
                    planeZ = y;
                    break;
                }
                //right/left
                case 2:
                case 3:{
                    planeX = z;
                    planeY = y;
                    planeZ = x;
                    break;
                }
                //front/bottom
                case 4:
                case 5:{
                    planeX = x;
                    planeY = y;
                    planeZ = z;
                    break;

                }

            }

        }
    ChunkVertexPlane(){}
};


// Compares two intervals according to starting times.
inline bool sortPlanes(ChunkVertexPlane p0, ChunkVertexPlane p1){
    if ( p0.planeZ != p1.planeZ )   return p0.planeZ < p1.planeZ;
    if ( p0.planeY != p1.planeY )   return p0.planeY < p1.planeY;
    return p0.planeX < p1.planeX;
}

// Compares two intervals according to starting times.
inline bool canMergePlanes(ChunkVertexPlane* p0, ChunkVertexPlane* p1){
    return p0->voxel == p1->voxel && p0->planeZ == p1->planeZ &&
        p0->ao0 == p1->ao0 &&
        p0->ao1 == p1->ao1  &&
        p0->ao2 == p1->ao2  &&
        p0->ao3 == p1->ao3;
}

class ChunkRenderer {
    World* world;
    dmArray<GoChunk> drawList;


    ChunkVertexPlane* renderPlanes = NULL;
    int planes = 0;

    //region for current chunk buffer draw
    dmBuffer::HBuffer buffer = 0x0;
    int vertices = 0;
    uint16_t* bufferData1= NULL;
    uint32_t  bufferData1Stride = 0;
    uint16_t* bufferData2= NULL;
    uint32_t  bufferData2Stride = 0;
    uint16_t* bufferData3= NULL;
    uint32_t  bufferData3Stride = 0;

    public:
    void addChunk(Chunk *chunk);
    void clear(lua_State *L);
    void draw(lua_State *L);
    void drawDebugChunkBorders(lua_State *L, int x, int y, int z);
    void drawDebugChunkFrustum(lua_State *L, int x, int y, int z);
    void drawDebugChunkVertices(lua_State *L, int x, int y, int z);
    void drawChunk(lua_State *L,GoChunk &goChunk);
    void drawVoxelPlane(Chunk* chunk, float x, float y, float z, uint8_t voxel, uint8_t plane);
    void drawVoxelVertex(ChunkVertexPlane* plane, int x, int y, int z, uint8_t voxel, int uvIdx,int ao);
    bool isBlocked(Chunk* chunk, int x, int y, int z);
    int vertexAO(bool side1, bool side2, bool corner);

    uint32_t getChunksCount();
    uint32_t getChunksVisibleCount();
    uint32_t getChunksVisibleVertices();

    uint32_t getBuffersCount();
    uint32_t getBuffersMemoryCount();

    ChunkRenderer(World* world);
    ~ChunkRenderer();
};

} // namespace d954Game

#endif