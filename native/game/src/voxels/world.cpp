#include "voxels/world.h"
#include "voxels/chunk.h"
#include "voxels/chunk_renderer.h"

namespace VoxelGame {

World world;


World::World(){
    chunkRenderer = new ChunkRenderer(this);
    chunks = new Chunks();

    for(int i=0; i< chunks->volume;i++){
        chunkRenderer->addChunk(&chunks->chunks[i]);
    }

  //  ChunkSetVoxel(testChunk,4,4,4,1);
   // ChunkSetVoxel(testChunk,5,5,5,2);
   // ChunkSetVoxel(testChunk,6,6,6,3);
   // ChunkSetVoxel(testChunk,10,7,7,3);


}

World::~World(){
    delete chunkRenderer;
    delete chunks;
}
//vertical columns from top to bottom
//save count + block_id
void World::getWorldLevelData(uint8_t** result, uint32_t* resultLen){
    int w = chunks->xMaxVoxels - chunks->xMinVoxels+1;
    int d = chunks->zMaxVoxels - chunks->zMinVoxels+1;

    int size = 0;
    size++;//uin8_t file version
    size+=4;//int32_t minX
    size+=4;//int32_t minZ
    size+=4;//int32_t maxX
    size+=4;//int32_t maxZ

    // bigger value it real case will be a lot of smaller.
    //1 value for number of different chunks in column
    //4 I always have [size][air]...[size][earth]
    //10 ten possible different tiles
    int columnBufferData = 1 + 4 + 10;
    size+= w*d * columnBufferData;


    dmLogInfo("buffer for save data:%.3f MB", size/1024.0/1024.0);
    uint8_t* buffer = new uint8_t[size];

    uint32_t bufferIdx = 0;
    buffer[bufferIdx] = 1;//file version
    bufferIdx++;

    ((int*)&buffer[bufferIdx])[0] = chunks->xMinVoxels;
    bufferIdx+=4;
    ((int*)&buffer[bufferIdx])[0] = chunks->zMinVoxels;
    bufferIdx+=4;
    ((int*)&buffer[bufferIdx])[0] = chunks->xMaxVoxels;
    bufferIdx+=4;
    ((int*)&buffer[bufferIdx])[0] = chunks->zMaxVoxels;
    bufferIdx+=4;

    uint8_t* bufferColumns = new uint8_t[255*2];
    for (int z = chunks->zMinVoxels; z <= chunks->zMaxVoxels; z++) {
        for (int x = chunks->xMinVoxels; x <= chunks->xMaxVoxels; x++) {
            uint8_t prevVoxel = chunks->getVoxel(x, 254,z);
            uint8_t voxelLen = 1;
            uint8_t bufferColumnsIdx = 0;
            for (int y = 253; y >= 0; y--) {
                uint8_t voxel = chunks->getVoxel(x, y,z);
                if(voxel == prevVoxel){
                    voxelLen++;
                }else{
                    //write line. len + voxel
                    bufferColumns[bufferColumnsIdx] = voxelLen;
                    bufferColumns[bufferColumnsIdx+1] = prevVoxel;
                    bufferColumnsIdx+=2;
                    voxelLen = 1;
                    prevVoxel = voxel;
                }
            }
            //write line. len + voxel
            bufferColumns[bufferColumnsIdx] = voxelLen;
            bufferColumns[bufferColumnsIdx+1] = prevVoxel;
            bufferColumnsIdx+=2;

                //save to level buffer
            buffer[bufferIdx] = bufferColumnsIdx/2;//number of tiles
            bufferIdx++;
            memcpy(&buffer[bufferIdx], bufferColumns, bufferColumnsIdx*sizeof(uint8_t));
            bufferIdx+=bufferColumnsIdx;
        }
    }
    delete[] bufferColumns;
    dmLogInfo("result buffer data:%.3f MB", bufferIdx*sizeof(uint8_t)/1024.0/1024.0);

    *result = buffer;
    *resultLen = bufferIdx;
}

//vertical columns from top to bottom
//save count + block_id
void World::loadWorldLevelData(lua_State *L, const uint8_t* buffer, uint32_t len){
    uint32_t bufferIdx = 0;
    uint8_t fileVersion = buffer[bufferIdx];
    bufferIdx++;

    int xMinVoxels = ((int*)&buffer[bufferIdx])[0];
    bufferIdx+=4;
    int zMinVoxels = ((int*)&buffer[bufferIdx])[0];
    bufferIdx+=4;
    int xMaxVoxels = ((int*)&buffer[bufferIdx])[0];
    bufferIdx+=4;
    int zMaxVoxels = ((int*)&buffer[bufferIdx])[0];
    bufferIdx+=4;

    dmLogInfo("load world:[%d %d] [%d %d]",xMinVoxels,xMaxVoxels,zMinVoxels,zMaxVoxels);

    chunkRenderer->clear(L);
    chunks->setWorldSize(xMinVoxels,zMinVoxels,xMaxVoxels,zMaxVoxels);
    for (int z = chunks->zMinVoxels; z <= chunks->zMaxVoxels; z++) {
        for (int x = chunks->xMinVoxels; x <= chunks->xMaxVoxels; x++) {
            uint8_t bufferColumnHeight = buffer[bufferIdx];
            bufferIdx++;
            int y = 254;
            for(int i=0;i<bufferColumnHeight;i++){
                uint8_t voxelLen = buffer[bufferIdx];
                bufferIdx++;
                uint8_t voxel = buffer[bufferIdx];
                bufferIdx++;
                for(int dy = 0;dy<voxelLen;dy++){
                    chunks->setVoxel(x,y,z,voxel);
                    y--;
                }
            }
        }
    }

   
    for(int i=0; i< chunks->volume;i++){
        chunkRenderer->addChunk(&chunks->chunks[i]);
    }

    map.setChunks(chunks);
}

void World::generateNewWorld(lua_State *L,int minX, int minZ, int maxX, int maxZ){
    dmLogInfo("generate world:[%d %d] [%d %d]",minX,minZ,maxX,maxZ);
    chunkRenderer->clear(L);
    chunks->setWorldSize(minX,minZ,maxX,maxZ);
   // chunks->createVoxels();

    for(int i=0; i< chunks->volume;i++){
        chunkRenderer->addChunk(&chunks->chunks[i]);
    }
}
} // namespace VoxelGame