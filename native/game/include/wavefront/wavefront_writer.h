#ifndef wavefront_writer_h
#define wavefront_writer_h

#ifdef DM_PLATFORM_WINDOWS
#include "wavefront/obj.h"
#include "voxels/chunks.h"

inline void drawVoxelPlane(wow::Obj *obj, int x, int y, int z, uint8_t voxel, int side){
    switch (side) {
        case 0: {
            obj->appendVertex(x, y + 1.0, z+1);
            obj->appendVertex(x, y + 1.0, z);
            obj->appendVertex(x+1, y + 1.0, z);
            obj->appendVertex(x+1, y + 1.0, z+1);
            obj->closeFace();
            break;
        }
        //bottom.
        case 1: {
            obj->appendVertex(x, y, z+1);
            obj->appendVertex(x, y, z);
            obj->appendVertex(x+1, y, z);
            obj->appendVertex(x+1, y, z+1);
            obj->closeFace();
            break;
        }
        //RIGHT(if look on back side(-z forward)
        case 2: {
            obj->appendVertex(x+1, y, z+1);
            obj->appendVertex(x+1, y+1, z+1);
            obj->appendVertex(x+1, y+1, z);
            obj->appendVertex(x+1, y, z);
            obj->closeFace();
            break;
        }
        //LEFT
        case 3: {
            obj->appendVertex(x, y, z+1);
            obj->appendVertex(x, y+1, z+1);
            obj->appendVertex(x, y+1, z);
            obj->appendVertex(x, y, z);
            obj->closeFace();
            break;
        }
        //front
        case 4: {
            obj->appendVertex(x, y, z+1);
            obj->appendVertex(x, y+1, z+1);
            obj->appendVertex(x+1, y+1, z+1);
            obj->appendVertex(x+1, y, z+1);
            obj->closeFace();
            break;
        }
        //back
        case 5: {
            obj->appendVertex(x, y, z);
            obj->appendVertex(x, y+1, z);
            obj->appendVertex(x+1, y+1, z);
            obj->appendVertex(x+1, y, z);
            obj->closeFace();
            break;
        }
    }
}

inline void WavefrontSaveChunks(const char* folder, VoxelGame::Chunks* chunks){
    wow::Obj obj;
    for (int z = chunks->zMinVoxels; z <= chunks->zMaxVoxels; z++) {
        for (int x = chunks->xMinVoxels; x <= chunks->xMaxVoxels; x++) {
            VoxelGame::Chunk* chunk = chunks->getChunkByPos(x,0,z);
            for (int y = chunk->yEnd-1; y >= chunk->yBegin; y--) {
                uint8_t voxel = chunks->getVoxel(x, y,z);
                if(voxel!=0){
                    if (!chunks->isBlocked(x, y + 1, z)) {
                        drawVoxelPlane(&obj,x, y, z, voxel, 0);
                    }
                    // bottom
                    if (!chunks->isBlocked(x, y - 1, z)) {
                        drawVoxelPlane(&obj,x, y, z, voxel, 1);
                    }
                    // right
                    if (!chunks->isBlocked(x + 1, y, z)) {
                        drawVoxelPlane(&obj,x, y, z, voxel, 2);
                    }
                    // left
                    if (!chunks->isBlocked(x - 1, y, z)) {
                        drawVoxelPlane(&obj,x, y, z, voxel, 3);
                    }
                    // front side
                    if (!chunks->isBlocked(x, y, z + 1)) {
                        drawVoxelPlane(&obj,x, y, z, voxel, 4);
                    }
                    // back
                    if (!chunks->isBlocked(x, y, z - 1)) {
                        drawVoxelPlane(&obj,x, y, z, voxel, 5);
                    }
                }
            }
        }
    }
    std::string path = folder;
    path+="level";
    obj.output(path);
}


#else
inline void WavefrontSaveChunks(const char* folder, VoxelGame::Chunks* chunks){

}
#endif

#endif