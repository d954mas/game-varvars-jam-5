#include "collision_writer/collision_writer.h"
#include "voxels/chunks.h"

#ifdef DM_PLATFORM_WINDOWS
#include "wavefront/obj.h"
#endif


namespace VoxelGame {

#ifdef DM_PLATFORM_WINDOWS

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
    int endY = box->y + box->h-1;
    int endZ = box->z + box->d-1;
    bool canExtend = true;
    for (int y = box->y; y <= endY && canExtend; ++y){
       for (int z = box->z; z <= endZ; ++z){
        if(endX>= CHUNK_W || voxels[VoxelGame::ChunkVoxelPosToIdx(endX,y,z)]==0){
            canExtend = false;
            break;
         }
       }
     }
    box->canExtendX = canExtend;
    //If the box can spread, mark it as tested and increase the box size in the X dimension.
    if (canExtend){
        for (int y = box->y; y <= endY; ++y){
            for (int z = box->z; z <= endZ; ++z){
                voxels[VoxelGame::ChunkVoxelPosToIdx(endX,y,z)]=0;
            }
        }
        box->w++;
    }
}

//Returns whether the box can continue to spread along the positive Y axis.
static void CollisionChunkExtendZ(CollisionBox* box,uint8_t* voxels){
    if(!box->canExtendZ) {return;}
    int endX = box->x + box->w-1;
    int endY = box->y + box->h-1;
    int endZ = box->z + box->d;
    bool canExtend = true;
    for (int x = box->x; x <= endX && canExtend; ++x){
       for (int y = box->y; y <= endY; ++y){
         if(endZ>= CHUNK_D || voxels[VoxelGame::ChunkVoxelPosToIdx(x,y,endZ)]==0){
            canExtend = false;
            break;
         }
       }
    }
    box->canExtendZ = canExtend;
    //If the box can spread, mark it as tested and increase the box size in the X dimension.
    if (canExtend){
        for (int x = box->x; x <= endX; ++x){
            for (int y = box->y; y <= endY; ++y){
                voxels[VoxelGame::ChunkVoxelPosToIdx(x,y,endZ)]=0;
            }
        }
        box->d++;
    }
}

//Returns whether the box can continue to spread along the positive Y axis.
static void CollisionChunkExtendY(CollisionBox* box,uint8_t* voxels){
    if(!box->canExtendY) {return;}
    int endX = box->x + box->w-1;
    int endY = box->y + box->h;
    int endZ = box->z + box->d-1;
    bool canExtend = true;
    for (int x = box->x; x <= endX && canExtend; ++x){
       for (int z = box->z; z <= endZ; ++z){
         if(endY> CHUNK_MAX_H || voxels[VoxelGame::ChunkVoxelPosToIdx(x,endY,z)]==0){
            canExtend = false;
            break;
         }
       }
    }
    box->canExtendY = canExtend;
    //If the box can spread, mark it as tested and increase the box size in the X dimension.
    if (canExtend){
        for (int x = box->x; x <= endX; ++x){
            for (int z = box->z; z <= endZ; ++z){
                voxels[VoxelGame::ChunkVoxelPosToIdx(x,endY,z)]=0;
            }
        }
        box->h++;
    }
}

static CollisionBox CollisionChunkExtendBox(uint8_t* voxels,int x, int y, int z){
   CollisionBox box;
   box.x = x;
   box.y = y;
   box.z = z;

   while(box.canExtendX || box.canExtendZ || box.canExtendY) {
        CollisionChunkExtendX(&box, voxels);
        CollisionChunkExtendZ(&box, voxels);
        CollisionChunkExtendY(&box, voxels);
   }


   return box;
}


static void CollisionChunkSaveBoxObj(wow::Obj *obj, CollisionBox box){
    int endX = box.x + box.w;
    int endY = box.y + box.h;
    int endZ = box.z + box.d;
    //top
    obj->appendVertex(box.x, endY, endZ);
    obj->appendVertex(box.x, endY, box.z);
    obj->appendVertex(endX, endY, box.z);
    obj->appendVertex(endX, endY, endZ);
    obj->closeFace();

    //bottom
    obj->appendVertex(box.x, box.y, endZ);
    obj->appendVertex(box.x, box.y, box.z);
    obj->appendVertex(endX, box.y, box.z);
    obj->appendVertex(endX, box.y, endZ);
    obj->closeFace();

    //right
    obj->appendVertex(endX, box.y, endZ);
    obj->appendVertex(endX, endY, endZ);
    obj->appendVertex(endX, endY, box.z);
    obj->appendVertex(endX, box.y, box.z);
    obj->closeFace();

    //left
    obj->appendVertex(box.x, box.y, endZ);
    obj->appendVertex(box.x, endY, endZ);
    obj->appendVertex(box.x, endY, box.z);
    obj->appendVertex(box.x, box.y, box.z);
    obj->closeFace();

    //front
    obj->appendVertex(box.x, box.y, box.z);
    obj->appendVertex(box.x, endY, box.z);
    obj->appendVertex(endX, endY, box.z);
    obj->appendVertex(endX, box.y, box.z);
    obj->closeFace();

    //back
    obj->appendVertex(box.x, box.y, endZ);
    obj->appendVertex(box.x, endY, endZ);
    obj->appendVertex(endX, endY, endZ);
    obj->appendVertex(endX, box.y, endZ);
    obj->closeFace();
}

static void CollisionChunkSaveBoxCollisions(std::string folder, int chunkIdx,  dmArray<CollisionBox> &boxes){
    std::ofstream file(folder + "collisions/" + "chunk_" + std::to_string(chunkIdx+1) + ".go");
    file << "embedded_components {\n  id: \"collisionobject\"\n  type: \"collisionobject\"\n  data: \"collision_shape: \\\"\\\"\\n\"\n  \"type: COLLISION_OBJECT_TYPE_STATIC\\n\"\n  \"mass: 0.0\\n\"\n  \"friction: 0.1\\n\"\n  \"restitution: 0.5\\n\"\n  \"group: \\\"obstacle\\\"\\n\"\n";
    file << "  \"mask: \\\"obstacle\\\"\\n\"\n  ";
    file << "  \"mask: \\\"player\\\"\\n\"\n  ";
    file << "  \"mask: \\\"enemy\\\"\\n\"\n  ";
    file << "\"embedded_collision_shape {\\n\"";
    for(int i=0; i< boxes.Size(); ++i){
        CollisionBox box = boxes[i];
        file << "\"  shapes {\\n\"\n  \"    shape_type: TYPE_BOX\\n\"\n  \"    position {\\n\"\n  \"      x: ";
        file <<  box.x + box.w/2.0;
        file <<"\\n\"\n  \"      y: ";
        file << box.y + box.h/2.0;
        file <<"\\n\"\n  \"      z: ";
        file << box.z + box.d/2.0;
        file << "\\n\"\n  \"    }\\n\"\n  \"    rotation {\\n\"\n  \"      x: 0.0\\n\"\n  \"      y: 0.0\\n\"\n  \"      z: 0.0\\n\"\n  \"      w: 1.0\\n\"\n  \"    }\\n\"\n  \"    index: ";
        file << i*3;
        file << "\\n\"\n  \"    count: 3\\n\"\n  \"  }\\n\"";
    }

    for(int i=0; i< boxes.Size(); ++i){
        CollisionBox box = boxes[i];
        file << "\"  data: ";
        file << box.w/2.0;
        file << "\\n\"";

        file << "\"  data: ";
        file << box.h/2.0;
        file << "\\n\"";

        file << "\"  data: ";
        file << box.d/2.0;
        file << "\\n\"";
    }

    file << "\"}\\n\"\n  \"linear_damping: 0.0\\n\"\n  \"angular_damping: 0.0\\n\"\n  \"locked_rotation: false\\n\"\n  \"bullet: false\\n\"\n  \"\"\n  position {\n    x: 0.0\n    y: 0.0\n    z: 0.0\n  }\n  rotation {\n    x: 0.0\n    y: 0.0\n    z: 0.0\n    w: 1.0\n  }\n}";
}

static void CollisionChunkSave(Chunk* chunk, dmArray<CollisionBox> &boxes){
    uint8_t voxels[CHUNK_W*CHUNK_D*CHUNK_MAX_H] = {0};
   // for (int y = chunk->yBegin; y <chunk->yEnd; y++) {
    for (int y = 64; y <67; y++) {//make collision only for part of world.
        for (int z = 0; z <CHUNK_D; z++) {
            for (int x = 0; x <CHUNK_W; x++) {
                voxels[VoxelGame::ChunkVoxelPosToIdx(x,y,z)] = chunk->voxels[VoxelGame::ChunkVoxelPosToIdx(x,y-chunk->yBegin,z)].id;
            }
        }
    }

    for (int y = chunk->yBegin; y <chunk->yEnd; y++) {
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

void CollisionChunksSave(const char* folder, VoxelGame::Chunks* chunks){
    dmArray<CollisionBox> boxes;
    boxes.SetCapacity(512);
    wow::Obj obj;
    for(int i=0; i< chunks->volume;i++){
        boxes.SetSize(0);
        CollisionChunkSave(&chunks->chunks[i],boxes);
        for(int i=0; i< boxes.Size(); ++i){
            CollisionChunkSaveBoxObj(&obj, boxes[i]);
        }
        CollisionChunkSaveBoxCollisions(folder,i,boxes);
    }
    std::string path = folder;
    obj.output(path+"level_collisions");

    
    std::ofstream file(path + "collisions/level.collection");

    std::string pathGo = folder;
    pathGo.erase(0,1);
    file << "name: \"level\"";
    for(int i=0; i< chunks->volume;i++){
        file << "instances {\n  id: \"chunk_" << std::to_string(i+1) << "\"\n  prototype: \"";
        file << pathGo << "collisions/chunk_" << std::to_string(i+1) << ".go";
        file << "\"\n  position {\n    x: 0.0\n    y: 0.0\n    z: 0.0\n  }\n  rotation {\n    x: 0.0\n    y: 0.0\n    z: 0.0\n    w: 1.0\n  }\n  scale3 {\n    x: 1.0\n    y: 1.0\n    z: 1.0\n  }\n}";
    }

    file << "scale_along_z: 1";
}


#else

void CollisionChunksSave(const char* filename, VoxelGame::Chunks* chunks){}


#endif
}