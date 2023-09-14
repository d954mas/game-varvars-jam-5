#include "collision_writer/collision_writer.h"
#include "voxels/chunks.h"



namespace VoxelGame {

struct CollisionBox{
    int x = 0;
    int y = 0;
    int z = 0;
    int w = 1;
    int h = 1;
    int d = 1;

    bool canExtendX = true;
    bool canExtendY = true;
    bool canExtendZ = true;
};

//Returns whether the box can continue to spread along the positive Y axis.
static void CollisionChunkExtendX(CollisionBox* box,uint8_t* voxels){
    if(!box->canExtendX) {return;}
    int endX = box->x + box->w;
    int endY = box->y - (box->h-1);
    int endZ = box->z + box->d-1;
    bool canExtend = true;
    for (int y = box->y; y >= endY && canExtend; --y){
       for (int z = box->z; z <= endZ; ++z){
        if(endX>= CHUNK_W || voxels[VoxelGame::ChunkVoxelPosToIdx(endX,y,z)]==0){
            canExtend = false;
            break;
         }
       }
     }
    box->canExtendX = canExtend;
}

//Returns whether the box can continue to spread along the positive Y axis.
static void CollisionChunkExtendZ(CollisionBox* box,uint8_t* voxels){
    if(!box->canExtendZ) {return;}
    int endX = box->x + box->w-1;
    int endY = box->y - (box->h-1);
    int endZ = box->z + box->d;
    bool canExtend = true;
    for (int x = box->x; x <= endX && canExtend; ++x){
       for (int y = box->y; y >= endY; --y){
         if(endZ>= CHUNK_D || voxels[VoxelGame::ChunkVoxelPosToIdx(x,y,endZ)]==0){
            canExtend = false;
            break;
         }
       }
    }
    box->canExtendZ = canExtend;
}

//Returns whether the box can continue to spread along the positive Y axis.
static void CollisionChunkExtendY(CollisionBox* box,uint8_t* voxels){
    if(!box->canExtendY) {return;}
    int endX = box->x + box->w-1;
    int endY = box->y - (box->h);
    int endZ = box->z + box->d-1;
    bool canExtend = true;
    for (int x = box->x; x <= endX && canExtend; ++x){
       for (int z = box->z; z <= endZ; ++z){
         if(endY< 0 || voxels[VoxelGame::ChunkVoxelPosToIdx(x,endY,z)]==0){
            canExtend = false;
            break;
         }
       }
    }
    box->canExtendY = canExtend;
}

static CollisionBox CollisionChunkExtendBox(uint8_t* voxels,int x, int y, int z){
   CollisionBox box;
   box.x = x;
   box.y = y;
   box.z = z;

   while(box.canExtendX && box.canExtendZ && box.canExtendY) {
        CollisionChunkExtendX(&box, voxels);
        CollisionChunkExtendZ(&box, voxels);
        CollisionChunkExtendY(&box, voxels);

        if(box.canExtendX && box.canExtendZ && box.canExtendY){
            //X
            int endX = box.x + box.w;
            int endY = box.y - (box.h-1);
            int endZ = box.z + box.d-1;
            for (int y = box.y; y >= endY; --y){
                for (int z = box.z; z <= endZ; ++z){
                    voxels[VoxelGame::ChunkVoxelPosToIdx(endX,y,z)]=0;
                }
            }
            box.w++;
            //Z
            endX = box.x + box.w-1;
            endY = box.y - (box.h-1);
            endZ = box.z + box.d;
            for (int x = box.x; x <= endX; ++x){
                for (int y = box.y; y >= endY; --y){
                    voxels[VoxelGame::ChunkVoxelPosToIdx(x,y,endZ)]=0;
                }
            }
            box.d++;
            //Y
            endX = box.x + box.w-1;
            endY = box.y - box.h;
            endZ = box.z + box.d-1;
            for (int x = box.x; x <= endX; ++x){
                for (int z = box.z; z <= endZ; ++z){
                    voxels[VoxelGame::ChunkVoxelPosToIdx(x,endY,z)]=0;
                }
            }
            box.h++;
        }
   }


   return box;
}



static void CollisionChunkSave(Chunk* chunk, dmArray<CollisionBox> &boxes){
    uint8_t voxels[CHUNK_W*CHUNK_D*CHUNK_MAX_H] = {0};
    for (int y = chunk->yBegin; y <chunk->yEnd; y++) {
    //for (int y = 80; y <0; y--) {//make collision only for part of world.
        for (int z = 0; z <CHUNK_D; z++) {
            for (int x = 0; x <CHUNK_W; x++) {
                voxels[VoxelGame::ChunkVoxelPosToIdx(x,y,z)] = chunk->voxels[VoxelGame::ChunkVoxelPosToIdx(x,y-chunk->yBegin,z)].id;
            }
        }
    }

        for (int y = chunk->yEnd-1; y >64; y--) {
                for (int z = 0; z <CHUNK_D; z++) {
                    for (int x = 0; x <CHUNK_W; x++) {
                        if(voxels[VoxelGame::ChunkVoxelPosToIdx(x,y,z)]!=0){
                            CollisionBox box = CollisionChunkExtendBox(voxels,x,y,z);
                            voxels[VoxelGame::ChunkVoxelPosToIdx(x,y,z)] = 0;

                            box.x += chunk->x;
                            box.y += chunk->y;
                            box.z += chunk->z;

                            if(boxes.Full()){
                                boxes.OffsetCapacity(16);
                            }
                            boxes.Push(box);
                        }
                    }
                }
            }

    for (int y = 64; y >=chunk->yBegin; y--) {
        for (int z = 0; z <CHUNK_D; z++) {
            for (int x = 0; x <CHUNK_W; x++) {
                if(voxels[VoxelGame::ChunkVoxelPosToIdx(x,y,z)]!=0){
                    CollisionBox box = CollisionChunkExtendBox(voxels,x,y,z);
                    voxels[VoxelGame::ChunkVoxelPosToIdx(x,y,z)] = 0;

                    box.x += chunk->x;
                    box.y += chunk->y;
                    box.z += chunk->z;

                    if(boxes.Full()){
                        boxes.OffsetCapacity(16);
                    }
                    boxes.Push(box);
                }
            }
        }
    }


}

void CollisionChunksGet(lua_State *L, VoxelGame::Chunks* chunks){
    dmArray<CollisionBox> boxes;
    boxes.SetCapacity(512);
    lua_newtable(L);
    for(int i=0; i< chunks->volume;i++){
        boxes.SetSize(0);
        CollisionChunkSave(&chunks->chunks[i],boxes);
        lua_newtable(L);
        for(int j=0; j< boxes.Size(); ++j){
            CollisionBox box = boxes[j];
            box.y+=-box.h+1;
            if(box.y + box.h >= 64.9999){
                lua_newtable(L);
                    dmScript::PushVector3(L,dmVMath::Vector3(box.x,box.y,box.z));
                    lua_setfield(L, -2, "position");
                    dmScript::PushVector3(L,dmVMath::Vector3(box.w,box.h,box.d));
                    lua_setfield(L, -2, "size");
                lua_rawseti(L, -2, j+1);
            }
        }
        lua_rawseti(L, -2, i+1);
    }

}

}