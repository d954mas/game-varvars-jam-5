#include "voxels/chunks.h"
#include "perlin.h"
#include <math.h>
#include <dmsdk/sdk.h>

namespace VoxelGame {

Chunks::Chunks() {
    setWorldSize(0,0,0,0);
}

void Chunks::setWorldSize(int xMinVoxels,int zMinVoxels, int xMaxVoxels, int zMaxVoxels){
    if(chunks!=NULL){
        delete[] chunks;
    }
    this->xMinVoxels = xMinVoxels;
    this->zMinVoxels = zMinVoxels;
    this->xMaxVoxels = xMaxVoxels;
    this->zMaxVoxels = zMaxVoxels;

    int width = (xMaxVoxels-xMinVoxels+1);
    int depth = (zMaxVoxels-zMinVoxels+1);

    chunksWidth = ceil(width/float(CHUNK_W));
    chunksDepth = ceil(depth/float(CHUNK_D));
    dmLogInfo("chunks:[%d %d]" ,chunksWidth,chunksDepth);
    dmLogInfo("Chunks: X[%d,%d] Z[%d %d]",xMinVoxels,xMaxVoxels,zMinVoxels,zMaxVoxels);

    volume = chunksWidth * chunksDepth;
    chunks = new Chunk[volume]();
    int idx=0;
    for (int z = 0; z < chunksDepth; z++) {
        for (int x = 0; x < chunksWidth; x++) {
            Chunk *c = &chunks[idx];
            c->x = xMinVoxels+x*(CHUNK_W);
            c->y = 0;
            c->z = zMinVoxels+ z * (CHUNK_D);
            idx++;
        }
    }
}

//copy of getVoxel
//use it when make clip
static uint8_t getVoxelForClip(Chunk* chunks,int x, int y, int z, int xMinVoxels,int xMaxVoxels,
        int zMinVoxels, int zMaxVoxels ){

    int width = (xMaxVoxels-xMinVoxels+1);
    int chunksWidth = ceil(width/float(CHUNK_W));

    if(x<xMinVoxels || x >xMaxVoxels || z <zMinVoxels || z>zMaxVoxels){return 0;}
    int chunkX = (x - xMinVoxels)/CHUNK_W;
    int chunkZ = (z - zMinVoxels)/CHUNK_D;
    Chunk* chunk = &chunks[chunkX+chunkZ*chunksWidth];
    int localX = x - chunk->x;
    int localZ = z - chunk->z;
    assert(localX>=0 && localX < CHUNK_W);
    assert(localZ>=0 && localZ < CHUNK_D);

    return ChunkGetVoxel(chunk,localX,y,localZ);
}

void Chunks::clipWorldSize(int xMinVoxels,int zMinVoxels, int xMaxVoxels, int zMaxVoxels){
    int prevXMinVoxels = this->xMinVoxels;
    int prevZMinVoxels = this->zMinVoxels;
    int prevXMaxVoxels = this->xMaxVoxels;
    int prevZMaxVoxels = this->xMaxVoxels;
    Chunk* prevChunks = chunks;
    chunks = NULL;
    setWorldSize(xMinVoxels,zMinVoxels,xMaxVoxels,zMaxVoxels);

    for (int z = zMinVoxels; z <= zMaxVoxels; z++) {
        for (int x = xMinVoxels; x <= xMaxVoxels; x++) {
            for (int y =0; y <= CHUNK_MAX_H; y++) {
                setVoxel(x,y,z,getVoxelForClip(prevChunks,x,y,z,prevXMinVoxels,prevXMaxVoxels,
                prevZMinVoxels,prevZMaxVoxels));
            }
        }
    }

}

Chunk* Chunks::getChunkByPos(int x, int y, int z){
    if(x<xMinVoxels || x >xMaxVoxels || z <zMinVoxels || z>zMaxVoxels){return NULL;}
    int chunkX = (x - xMinVoxels)/CHUNK_W;
    int chunkZ = (z - zMinVoxels)/CHUNK_D;
    return &chunks[chunkX+chunkZ*chunksWidth];
}

uint8_t Chunks::getVoxel(int x, int y, int z){
    if(x<xMinVoxels || x >xMaxVoxels || z <zMinVoxels || z>zMaxVoxels){return 0;}
    int chunkX = (x - xMinVoxels)/CHUNK_W;
    int chunkZ = (z - zMinVoxels)/CHUNK_D;
    Chunk* chunk = &chunks[chunkX+chunkZ*chunksWidth];
    int localX = x - chunk->x;
    int localZ = z - chunk->z;
    assert(localX>=0 && localX < CHUNK_W);
    assert(localZ>=0 && localZ < CHUNK_D);

    return ChunkGetVoxel(chunk,localX,y,localZ);
}

void Chunks::setVoxel(int x, int y, int z, uint8_t voxel){
    if(x<xMinVoxels || x >xMaxVoxels || z <zMinVoxels || z>zMaxVoxels
        || y<0 || y>CHUNK_MAX_H){
        dmLogError("try to set voxel outside of the world[%d %d %d]",x,y,z);
        return;
    }

    int chunkX = (x - xMinVoxels)/CHUNK_W;
    int chunkZ = (z - zMinVoxels)/CHUNK_D;
    int chunkId = chunkX+chunkZ*chunksWidth;
    assert(chunkId>=0 && chunkId < volume);
    Chunk* chunk = &chunks[chunkId];
   
  
    int localX = x - chunk->x;
    int localZ = z - chunk->z;


    assert(localX>=0 && localX < CHUNK_W);
    assert(localZ>=0 && localZ < CHUNK_D);

    ChunkSetVoxel(chunk, localX,y,localZ, voxel);
    //if change voxel on borders of chunk need recalculate neighbours.
    //some hiden edges can be visible now
    if(localX==0 && chunk->x!= xMinVoxels){chunks[chunkId-1].contentVersion++;}
    if(localX==CHUNK_W-1 && chunk->x!= xMaxVoxels-CHUNK_W+1){chunks[chunkId+1].contentVersion++;}
    if(localZ==0 && chunk->z!= zMinVoxels){chunks[chunkId-chunksWidth].contentVersion++;}
    if(localZ==CHUNK_D-1 && chunk->z!= zMaxVoxels-CHUNK_D+1){chunks[chunkId+chunksWidth].contentVersion++;}
}

void Chunks::fillZone(int x1, int y1, int z1,int x2,int y2, int z2, uint8_t voxel){
    for (int z = fmax(zMinVoxels,z1); z <= fmin(zMaxVoxels,z2); z++) {
            for (int x = fmax(xMinVoxels,x1); x <= fmin(xMaxVoxels,x2); x++) {
                for (int y =fmax(0,y1); y <= fmin(CHUNK_MAX_H,y2); y++) {
                    setVoxel(x,y,z,voxel);
                }
            }
        }
}

void Chunks::fillZoneMountain(int x1, int y1, int z1,int x2,int y2, int z2, uint8_t voxel,
    float persistence, float frequency, float amplitude, int octaves, int randomseed){

    PerlinNoise perlinNoise(persistence, frequency, amplitude, octaves, randomseed);
    for (int z = fmax(zMinVoxels,z1); z <= fmin(zMaxVoxels,z2); z++) {
        for (int x = fmax(xMinVoxels,x1); x <= fmin(xMaxVoxels,x2); x++) {
            int maxY = fmin(CHUNK_MAX_H,y2);
            int perlinH = y1+perlinNoise.GetHeight(x,z);
            for (int y =fmax(0,y1); y <= maxY; y++) {
                setVoxel(x,y,z, y<=perlinH ? voxel : 0);
            }

        }
    }
}

void Chunks::createVoxels(){
    double persistence = 1;
    double frequency = 0.25;
    double amplitude = 48;
    int octaves = 1;
    int randomseed = 23;
    PerlinNoise perlinNoise(persistence, frequency, amplitude, octaves, randomseed);

    for (int z = zMinVoxels; z <= zMaxVoxels; z++) {
        for (int x = xMinVoxels; x <= xMaxVoxels; x++) {
            for (int y = 64; y >= 0; y--) {
                setVoxel(x,y,z,2);
            }
            int height = 64 + perlinNoise.GetHeight(x,z);
            for (int y = height; y > 64; y--) {
                setVoxel(x,y,z,1);
            }
        }
    }
}

int countId(Chunks* chunks, int x, int y, int z){
    if(x<chunks->xMinVoxels || x >chunks->xMaxVoxels 
        || z <chunks->zMinVoxels || z>chunks->zMaxVoxels
        || y<0 || y>CHUNK_MAX_H){return 0;}
    x = x - chunks->xMinVoxels;
    z = z - chunks->zMinVoxels;
    int width = (chunks->xMaxVoxels-chunks->xMinVoxels+1);
    int depth = (chunks->zMaxVoxels-chunks->zMinVoxels+1);
    int id = x + z* width + y * width * depth+1;
    assert(id>0);
    return id;
}

bool tryFillHollow(dmArray<dmVMath::Vector3>* result, Chunks* chunks, bool* visited, int x, int y, int z){
    dmArray<dmVMath::Vector3> cells;
    cells.OffsetCapacity(1024);
    cells.Push( dmVMath::Vector3(x,y,z));
    result->Push( dmVMath::Vector3(x,y,z));
    bool touchEdge = false;
    while (!cells.Empty()){
        dmVMath::Vector3 cell = cells.Back();
        cells.Pop();
        for(int dx=-1;dx<=1;dx++){
            for(int dz=-1;dz<=1;dz++){
                //ignore diagonals
                if(dx!=0 && dz!=0){continue;}
                for(int dy=-1;dy<=1;dy++){
                    int id = countId(chunks, cell.getX()+dx,cell.getY()+dy,cell.getZ()+dz);
                    if(id == 0){
                        touchEdge = true;
                        continue;
                    }

                    if(!visited[id]){
                        visited[id] = true;
                        uint8_t voxel = chunks->getVoxel(cell.getX()+dx,cell.getY()+dy,cell.getZ()+dz);
                        if(voxel==0){
                            if(cells.Full()){
                                cells.OffsetCapacity(cells.Capacity()*0.25);
                            }
                            if(result->Full()){
                                result->OffsetCapacity(result->Capacity()*0.25);
                            }
                            cells.Push(dmVMath::Vector3(cell.getX()+dx,cell.getY()+dy,cell.getZ()+dz));
                            result->Push(dmVMath::Vector3(cell.getX()+dx,cell.getY()+dy,cell.getZ()+dz));
                        }

                    }
                }
            }
        }
    }


    return touchEdge;
}


void Chunks::fillHollow(){
    bool* visited = new bool[countId(this,xMaxVoxels,CHUNK_MAX_H,zMaxVoxels)+1];
    for (int y =63; y <= CHUNK_MAX_H; y++) {
        for (int z = zMinVoxels; z <= zMaxVoxels; z++) {
            for (int x = xMinVoxels; x <= xMaxVoxels; x++) {
                uint8_t voxel = this->getVoxel(x,y,z);
                if(voxel==0){
                    int id = countId(this,x,y,z);
                    if(!visited[id]){
                        dmArray<dmVMath::Vector3> result;
                        result.OffsetCapacity(128);
                        visited[id] = true;
                        bool touchEdge = tryFillHollow(&result, this,visited,x,y,z);
                        if (!touchEdge){
                            dmLogInfo("size:%d",result.Size());
                            for(int i = 0; i < result.Size(); i++){
                                dmVMath::Vector3 pos = result[i];
                                this->setVoxel(pos.getX(),pos.getY(),pos.getZ(),3);
                            }
                        }else{
                            dmLogInfo("touchEdge size:%d",result.Size());
                        }
                    }
                }
            }
        }
    }
}

bool Chunks::raycast(dmVMath::Vector3 pos, dmVMath::Vector3 dir, int maxDist, RayCastResult* result){
    float px = pos.getX();
    float py = pos.getY();
    float pz = pos.getZ();

    float dx = dir.getX();
    float dy = dir.getY();
    float dz = dir.getZ();

    float t = 0.0f;
    int ix = floor(px);
    int iy = floor(py);
    int iz = floor(pz);

    float stepx = (dx > 0.0f) ? 1.0f : -1.0f;
    float stepy = (dy > 0.0f) ? 1.0f : -1.0f;
    float stepz = (dz > 0.0f) ? 1.0f : -1.0f;

    float infinity = std::numeric_limits<float>::infinity();

    float txDelta = (dx == 0.0f) ? infinity : abs(1.0f / dx);
    float tyDelta = (dy == 0.0f) ? infinity : abs(1.0f / dy);
    float tzDelta = (dz == 0.0f) ? infinity : abs(1.0f / dz);

    float xdist = (stepx > 0) ? (ix + 1 - px) : (px - ix);
    float ydist = (stepy > 0) ? (iy + 1 - py) : (py - iy);
    float zdist = (stepz > 0) ? (iz + 1 - pz) : (pz - iz);

    float txMax = (txDelta < infinity) ? txDelta * xdist : infinity;
    float tyMax = (tyDelta < infinity) ? tyDelta * ydist : infinity;
    float tzMax = (tzDelta < infinity) ? tzDelta * zdist : infinity;

    int steppedIndex = -1;

    while (t <= maxDist){
        uint8_t voxel = getVoxel(ix, iy, iz);
        if (voxel!=0){
            result->point.setX(px + t * dx);
            result->point.setY(py + t * dy);
            result->point.setZ(pz + t * dz);

            result->chunkPos.setX(ix);
            result->chunkPos.setY(iy);
            result->chunkPos.setZ(iz);

            if(steppedIndex == 0){
                result->side = stepx<0 ? 2 : 3;
            }
            if(steppedIndex == 1){
                result->side = stepy<0 ? 0 : 1;
            }
             if(steppedIndex == 2){
                result->side = stepz<0 ? 5 : 4;
            }
         //   norm.x = norm.y = norm.z = 0.0f;
            //if (steppedIndex == 0) norm.x = -stepx;
          //  if (steppedIndex == 1) norm.y = -stepy;
            //if (steppedIndex == 2) norm.z = -stepz;
            return true;
        }
        if (txMax < tyMax) {
            if (txMax < tzMax) {
                ix += stepx;
                t = txMax;
                txMax += txDelta;
                steppedIndex = 0;
            } else {
                iz += stepz;
                t = tzMax;
                tzMax += tzDelta;
                steppedIndex = 2;
            }
        } else {
            if (tyMax < tzMax) {
                iy += stepy;
                t = tyMax;
                tyMax += tyDelta;
                steppedIndex = 1;
            } else {
                iz += stepz;
                t = tzMax;
                tzMax += tzDelta;
                steppedIndex = 2;
            }
        }
    }

    return false;
}

bool Chunks::isBlocked(int x, int y, int z){
    uint8_t voxel = getVoxel(x,y,z);
    return voxel!= 0;
}

uint32_t Chunks::getChunksMemory(){
    uint32_t memory = volume* sizeof(Chunk);
    for(int i=0; i<volume; ++i){
        memory += chunks[i].voxelsSize *  sizeof(Voxel);
    }
    return memory;
}

Chunks::~Chunks() {
    delete[] chunks;
}

} // namespace VoxelGame