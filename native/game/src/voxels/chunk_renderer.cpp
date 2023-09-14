#include "voxels/chunk_renderer.h"
#include "voxels/debug_renderer.h"
#include "voxels/voxel_atlas.h"
#include "voxels/world.h"

#include<algorithm>
#include <vector>

static const dmhash_t HASH_MESH = dmHashString64("mesh");
static const dmhash_t HASH_AABB = dmHashString64("AABB");
static const dmhash_t HASH_CHUNK_DATA_1 = dmHashString64("data1");
static const dmhash_t HASH_CHUNK_DATA_2 = dmHashString64("data2");
static const dmhash_t HASH_CHUNK_DATA_3 = dmHashString64("data3");

#define MAX_PLANES 25000

namespace VoxelGame {

const dmBuffer::StreamDeclaration chunk_buffer_decl[] = {
    {HASH_CHUNK_DATA_1, dmBuffer::VALUE_TYPE_UINT16, 1},
    {HASH_CHUNK_DATA_2, dmBuffer::VALUE_TYPE_UINT16, 1},
    {HASH_CHUNK_DATA_3, dmBuffer::VALUE_TYPE_UINT16, 1},
};

static void CreateBuffer(int vertices, dmBuffer::HBuffer *buffer,
                        uint16_t **bufferData1, uint32_t *bufferData1Stride,
                        uint16_t **bufferData2, uint32_t *bufferData2Stride,
                        uint16_t **bufferData3, uint32_t *bufferData3Stride
                    ) {
    dmBuffer::Result bufferResult = dmBuffer::Create(vertices, chunk_buffer_decl, 3, buffer);
    if (bufferResult != dmBuffer::RESULT_OK) {
        dmLogError("can't create chunk render buffer");
        return;
    }

    dmBuffer::Result dataResult = dmBuffer::GetStream(*buffer, HASH_CHUNK_DATA_1,
                                                           (void **)bufferData1, NULL, NULL, bufferData1Stride);
    if (dataResult != dmBuffer::RESULT_OK) {
       dmLogError("can't get buffer data1");
    }
    dataResult = dmBuffer::GetStream(*buffer, HASH_CHUNK_DATA_2,
                                                           (void **)bufferData2, NULL, NULL, bufferData2Stride);
    if (dataResult != dmBuffer::RESULT_OK) {
       dmLogError("can't get buffer data2");
    }

    dataResult = dmBuffer::GetStream(*buffer, HASH_CHUNK_DATA_3,
                                                           (void **)bufferData3, NULL, NULL, bufferData3Stride);
    if (dataResult != dmBuffer::RESULT_OK) {
       dmLogError("can't get buffer data3");
    }
}

static void createChunkGo(lua_State *L, GoChunk &item) {
    lua_getglobal(L, "native_create_chunk_renderer_go");
    if (!lua_isfunction(L, -1)) {
        luaL_error(L, "no native_create_chunk_renderer_go function");
    }
    lua_call(L, 0, 1);
    /* get the url */
    dmMessage::URL *url = dmScript::CheckURL(L, -1);
    item.rootUrl = *url;
    item.meshUrl = item.rootUrl;
    item.meshUrl.m_Fragment = HASH_MESH;
    item.goCreated = true;
    dmGameObject::SetPosition(dmScript::CheckGOInstance(L, -1), dmVMath::Point3(item.chunk->x, item.chunk->y, item.chunk->z));
    lua_pop(L, 1);
}

static void updateGoBuffer(lua_State *L, GoChunk &item, dmBuffer::HBuffer buffer) {
    lua_getglobal(L, "native_update_chunk_buffer");
    if (!lua_isfunction(L, -1)) {
        luaL_error(L, "no native_update_chunk_buffer function");
    }
    dmScript::PushURL(L, item.meshUrl);
    dmScript::LuaHBuffer luabuf(buffer, dmScript::OWNER_C);
    dmScript::PushBuffer(L, luabuf);
    lua_call(L, 2, 0);
}

static void removeChunkGo(lua_State *L, GoChunk &item) {
    lua_getglobal(L, "native_delete_chunk_renderer_go");
    if (!lua_isfunction(L, -1)) {
       luaL_error(L, "no native_delete_chunk_renderer_go function");
    }
    dmScript::PushURL(L, item.rootUrl);
    dmScript::PushURL(L, item.meshUrl);
    lua_call(L, 2, 0);
}



ChunkRenderer::ChunkRenderer(World* world) {
    this->world = world;
    drawList.SetCapacity(128);
    renderPlanes = new ChunkVertexPlane[MAX_PLANES]();
}
ChunkRenderer::~ChunkRenderer() {
    delete[] renderPlanes;
}

void ChunkRenderer::addChunk(Chunk *chunk) {
    if (drawList.Full()) {
        drawList.OffsetCapacity(8);
    }
    drawList.Push(GoChunk(chunk));
}

void ChunkRenderer::clear(lua_State *L){
    for (int i = 0; i < drawList.Size(); i++) {
        GoChunk &item = drawList[i];
        if (item.goCreated) {
            removeChunkGo(L, item);
        }
    }
    drawList.SetSize(0);
}



void ChunkRenderer::drawVoxelVertex(ChunkVertexPlane* plane, int x, int y, int z, uint8_t voxel, int uvIdx, int ao) {
     //1-8[0,255] voxel /9-10 uv[0,3] /11-13 side[0,5] //14-15 ao
    int16_t data1value = voxel | (uvIdx<<8) | (plane->side<<10) | (ao<<13);
    bufferData1[vertices * bufferData1Stride] = data1value;



    //1-6[0,63] x // 7-12[0,63] z // 13-16[0,15] y1
    uint16_t data2value = x | (z<<6) | ((y&240)<<8);
    bufferData2[vertices * bufferData2Stride] = data2value;

    //1-6[0,63] tileW 7-12[0,63] tileH // 13-16[0,16] y2
    uint16_t data3value = plane->planeW | (plane->planeH<<6) | y<<12;
    bufferData3[vertices * bufferData3Stride] = data3value;
    vertices++;

   // dmLogInfo("%d == %d",y,(((data2value>>8)&240)|(data3value>>12)));
   // dmLogInfo("w:%d h:%d",plane->planeW,plane->planeH);
    assert(y == (((data2value>>8)&240)|(data3value>>12)));
    assert(x == (data2value&63));
    assert(z == ((data2value>>6)&63));
}

void ChunkRenderer::drawVoxelPlane(Chunk* chunk,float x, float y, float z, uint8_t voxel, uint8_t side) {
    uint8_t ao0,ao1,ao2,ao3;
     //top
    switch (side) {
        case 0: {
            bool vLeft = isBlocked(chunk,x-1,y+1,z);
            bool vLeftTop = isBlocked(chunk,x-1,y+1,z-1);
            bool vTop = isBlocked(chunk,x,y+1,z-1);
            bool vRightTop = isBlocked(chunk,x+1,y+1,z-1);
            bool vRight = isBlocked(chunk,x+1,y+1,z);
            bool vRightBottom = isBlocked(chunk,x+1,y+1,z+1);
            bool vBottom = isBlocked(chunk,x,y+1,z+1);
            bool vBottomLeft = isBlocked(chunk,x-1,y+1,z+1);

            ao0 = vertexAO(vBottom,vLeft,vBottomLeft);
            ao1 = vertexAO(vLeft,vTop,vLeftTop);
            ao2 = vertexAO(vTop,vRight,vRightTop);
            ao3 = vertexAO(vRight,vBottom,vRightBottom);
            break;
        }
        //bottom. Is bottom need AO?
        case 1: {
            bool vLeft = isBlocked(chunk,x-1,y-1,z);
            bool vLeftTop = isBlocked(chunk,x-1,y-1,z-1);
            bool vTop = isBlocked(chunk,x,y-1,z-1);
            bool vRightTop = isBlocked(chunk,x+1,y-1,z-1);
            bool vRight = isBlocked(chunk,x+1,y-1,z);
            bool vRightBottom = isBlocked(chunk,x+1,y-1,z+1);
            bool vBottom = isBlocked(chunk,x,y-1,z+1);
            bool vBottomLeft = isBlocked(chunk,x-1,y-1,z+1);

            ao0 = vertexAO(vBottom,vLeft,vBottomLeft);
            ao1 = vertexAO(vLeft,vTop,vLeftTop);
            ao2 = vertexAO(vTop,vRight,vRightTop);
            ao3 = vertexAO(vRight,vBottom,vRightBottom);
            break;
        }
        //RIGHT(if look on back side(-z forward)
        case 2: {
            bool vLeft = isBlocked(chunk,x+1,y,z+1);
            bool vLeftTop = isBlocked(chunk,x+1,y+1,z+1);
            bool vTop = isBlocked(chunk,x+1,y+1,z);
            bool vRightTop = isBlocked(chunk,x+1,y+1,z-1);
            bool vRight = isBlocked(chunk,x+1,y,z-1);
            bool vRightBottom = isBlocked(chunk,x+1,y-1,z-1);
            bool vBottom = isBlocked(chunk,x+1,y-1,z);
            bool vBottomLeft = isBlocked(chunk,x+1,y-1,z+1);

            ao0 = vertexAO(vBottom,vLeft,vBottomLeft);
            ao1 = vertexAO(vLeft,vTop,vLeftTop);
            ao2 = vertexAO(vTop,vRight,vRightTop);
            ao3 = vertexAO(vRight,vBottom,vRightBottom);
            break;
        }
        //LEFT
        case 3: {
            bool vLeft = isBlocked(chunk,x-1,y,z-1);
            bool vLeftTop = isBlocked(chunk,x-1,y+1,z-1);
            bool vTop = isBlocked(chunk,x-1,y+1,z);
            bool vRightTop = isBlocked(chunk,x-1,y+1,z+1);
            bool vRight = isBlocked(chunk,x-1,y,z+1);
            bool vRightBottom = isBlocked(chunk,x-1,y-1,z+1);
            bool vBottom = isBlocked(chunk,x-1,y-1,z);
            bool vBottomLeft = isBlocked(chunk,x-1,y-1,z-1);

            ao0 = vertexAO(vBottom,vLeft,vBottomLeft);
            ao1 = vertexAO(vLeft,vTop,vLeftTop);
            ao2 = vertexAO(vTop,vRight,vRightTop);
            ao3 = vertexAO(vRight,vBottom,vRightBottom);
            break;
        }
        //front
        case 4: {
            bool vLeft = isBlocked(chunk,x-1,y,z+1);
            bool vLeftTop = isBlocked(chunk,x-1,y+1,z+1);
            bool vTop = isBlocked(chunk,x,y+1,z+1);
            bool vRightTop = isBlocked(chunk,x+1,y+1,z+1);
            bool vRight = isBlocked(chunk,x+1,y,z+1);
            bool vRightBottom = isBlocked(chunk,x+1,y-1,z+1);
            bool vBottom = isBlocked(chunk,x,y-1,z+1);
            bool vBottomLeft = isBlocked(chunk,x-1,y-1,z+1);

            ao0 = vertexAO(vBottom,vLeft,vBottomLeft);
            ao1 = vertexAO(vLeft,vTop,vLeftTop);
            ao2 = vertexAO(vTop,vRight,vRightTop);
            ao3 = vertexAO(vRight,vBottom,vRightBottom);
            break;
        }
        //back
        case 5: {
            bool vLeft = isBlocked(chunk,x+1,y,z-1);
            bool vLeftTop = isBlocked(chunk,x+1,y+1,z-1);
            bool vTop = isBlocked(chunk,x,y+1,z-1);
            bool vRightTop = isBlocked(chunk,x-1,y+1,z-1);
            bool vRight = isBlocked(chunk,x-1,y,z-1);
            bool vRightBottom = isBlocked(chunk,x-1,y-1,z-1);
            bool vBottom = isBlocked(chunk,x,y-1,z-1);
            bool vBottomLeft = isBlocked(chunk,x+1,y-1,z-1);

            ao0 = vertexAO(vBottom,vLeft,vBottomLeft);
            ao1 = vertexAO(vLeft,vTop,vLeftTop);
            ao2 = vertexAO(vTop,vRight,vRightTop);
            ao3 = vertexAO(vRight,vBottom,vRightBottom);
            break;
        }
    }


    renderPlanes[planes] = ChunkVertexPlane(x, y, z, voxel, side, ao0,ao1,ao2,ao3);
    planes++;
}

bool ChunkRenderer::isBlocked(Chunk* chunk, int x, int y, int z) {
    //inside
    if(x>=0 && x<CHUNK_W && z>=0 && z<CHUNK_D){
        return ChunkGetVoxel(chunk, x,y,z) >0;
    }
    //outside
    return world->chunks->isBlocked(chunk->x+x,y, chunk->z + z);
}

int ChunkRenderer::vertexAO(bool side1, bool side2, bool corner) {
    if(side1 && side2) {
        return 0;
    }
    return 3 - (side1 + side2 + corner);
}

void ChunkRenderer::drawChunk(lua_State *L, GoChunk &goChunk) {
    planes = 0;

    Chunk *chunk = goChunk.chunk;
    float* aabb = goChunk.chunk->aabb;
    //iterate only on chunk bbox.
    //actual bbox can be smaller.If we for example remove top tile.
    //actual bbox can't be bigger.When add not air voxel. Update bbox.
    int cx =aabb[0];
    int cxMax =aabb[3];
    int cy =aabb[1];
    int cyMax =aabb[4];
    int cz =aabb[2];
    int czMax =aabb[5];

   // dmLogInfo("aabb (%f %f %f) (%f %f %f)",aabb[0],aabb[1],aabb[2],aabb[3],aabb[4],aabb[5])

    // min
    aabb[0] = cxMax;
    aabb[1] = cyMax;
    aabb[2] = czMax;
    // max
    aabb[3] = 0;
    aabb[4] = 0;
    aabb[5] = 0;

    //dmLogInfo("aabb %f/%f", aabb[1],aabb[4]);

    for (int y = cy; y < cyMax; y++) {
        int chunkRealY = y-chunk->yBegin;
        for (int z = cz; z < czMax; z++) {
            int chunkIdYZ = (z + chunkRealY * CHUNK_D) * CHUNK_W;
            for (int x = cx; x < cxMax; x++) {
                uint8_t voxel = chunk->voxels[chunkIdYZ+x].id;
                //ChunkGetVoxel(chunk,x,y,z);
                if (voxel == 0) {
                    continue;
                }

                if (x < aabb[0])
                    aabb[0] = x;
                if (y < aabb[1])
                    aabb[1] = y;
                if (z < aabb[2])
                    aabb[2] = z;
                if (x + 1 > aabb[3])
                    aabb[3] = x + 1;
                if (y + 1 > aabb[4])
                    aabb[4] = y + 1;
                if (z + 1 > aabb[5])
                    aabb[5] = z + 1;

                /*
                      1 ____ 2
                       |    |
                       |    |
                      0 ‾‾‾‾ 3
                */

                // 0,1,2 triangle 1
                // 0,2,3 triangle 2

                // top
                if (!isBlocked(chunk,x, y + 1, z)) {
                    drawVoxelPlane(chunk,x, y, z, voxel, 0);
                }
                // bottom
               // if (!isBlocked(chunk,x, y - 1, z)) {
               //     drawVoxelPlane(chunk,x, y, z, voxel, 1);
               // }
                // right
                if (!isBlocked(chunk,x + 1, y, z)) {
                    drawVoxelPlane(chunk,x, y, z, voxel, 2);
                }
                // left
                if (!isBlocked(chunk,x - 1, y, z)) {
                    drawVoxelPlane(chunk,x, y, z, voxel, 3);
                }
                // front side
                if (!isBlocked(chunk,x, y, z + 1)) {
                    drawVoxelPlane(chunk,x, y, z, voxel, 4);
                }
                // back. Back side is visible on mobile
                if (!isBlocked(chunk,x, y, z - 1)) {
                    drawVoxelPlane(chunk,x, y, z, voxel, 5);
                }
            }
        }
    }


    if(aabb[3]==0){aabb[0] =0;}
    if(aabb[4]==0){aabb[1] =0;}
    if(aabb[5]==0){aabb[2] =0;}

    if(aabb[0]>aabb[3]){aabb[3] =aabb[0];}
    if(aabb[1]>aabb[4]){aabb[4] =aabb[1];}
    if(aabb[2]>aabb[5]){aabb[5] =aabb[2];}

   // dmLogInfo("aabb %f/%f", aabb[1],aabb[4]);



   // ChunkCheckResize(chunk);
    if ( planes > 0) {
        //dmLogInfo("planes %d", planes);
        //try greedy meshes
        std::vector<ChunkVertexPlane> sidePlanes[6];

        for (int i = 0; i < planes; ++i) {
            ChunkVertexPlane plane = renderPlanes[i];
            sidePlanes[plane.side].push_back(plane);
        }
        for(int i=0;i<6;i++){
            std::vector<ChunkVertexPlane> *planes =  &sidePlanes[i];
            sort(planes->begin(), planes->end(), sortPlanes);
            //if(true) break;
            //if(i==0){
                // dmLogInfo("_________________________");
                //  for(int i=0;i<planes->size();i++){
                  // ChunkVertexPlane plane = planes->at(i);
                  //  dmLogInfo("plane Z:%d Y:%d X:%d",plane.planeZ, plane.planeY, plane.planeX);
                // }

                int greedyIdx = 0;
                while(greedyIdx<planes->size()){
                    ChunkVertexPlane* planeStart = &planes->at(greedyIdx);
                    //max width
                    while(greedyIdx+1<planes->size()){
                         ChunkVertexPlane* planeNext = &planes->at(greedyIdx+1);
                         if(planeStart->planeY == planeNext->planeY && planeStart->planeX+planeStart->planeW == planeNext->planeX
                            && canMergePlanes(planeStart,planeNext)){
                                planeStart->planeW++;
                                planes->erase(planes->begin()+greedyIdx+1);
                                if(planeStart->planeW == CHUNK_W){break;}
                        }else{
                            break;
                        }
                    }
                    greedyIdx++;

                    //try find max H
                    int planeIdx = greedyIdx;
                    while(planeIdx<planes->size()){
                        if(planeStart->planeH == CHUNK_W){break;}
                        //skip current line end
                        while(planeIdx<planes->size()
                            && planes->at(planeIdx).planeZ==planeStart->planeZ
                            && planes->at(planeIdx).planeY==planeStart->planeY+planeStart->planeH-1
                            && planes->at(planeIdx).planeX>=planeStart->planeX+planeStart->planeW)
                            {planeIdx++;}
                        //if(planeIdx==planes->size()){break;}
                        //if(planes->at(planeIdx).planeZ!=planeStart->planeZ){break;}

                        //skip plane to new possible start row
                        while(planeIdx<planes->size()
                            && planes->at(planeIdx).planeZ==planeStart->planeZ
                            && planes->at(planeIdx).planeY==planeStart->planeY+planeStart->planeH
                            && planes->at(planeIdx).planeX<planeStart->planeX)
                            {planeIdx++;}
                        if(planeIdx==planes->size()){break;}
                        //move to new line skipped
                        if(planes->at(planeIdx).planeZ!=planeStart->planeZ){break;}
                        //move to new line skipped
                        if(planes->at(planeIdx).planeY!=planeStart->planeY+planeStart->planeH){break;}
                        //next line start position is bigger then we need
                        if(planes->at(planeIdx).planeX!=planeStart->planeX){break;}

                        
                        //not enough planes to complete line
                        if(planes->size() - planeIdx<planeStart->planeW){break;}
                        int size = 0;
                        for(int i=0;i<planeStart->planeW;i++){
                            ChunkVertexPlane* planeCheck = &planes->at(planeIdx+i);
                            if(planeCheck->planeZ!=planeStart->planeZ){break;}
                            if(planeCheck->planeY!=planeStart->planeY+planeStart->planeH){break;}
                            if(planeCheck->planeX!=planeStart->planeX+i){break;}
                            if(!canMergePlanes(planeStart,planeCheck)){break;}
                            size++;
                        }
                        //add row to plane
                        if(size == planeStart->planeW){
                            //erase [first,last)
                             planes->erase(planes->begin()+planeIdx,planes->begin()+planeIdx+planeStart->planeW);
                             planeStart->planeH++;
                        }else{
                            break;
                        }
                    }
                }
            //}
        }

        planes = 0;
        for(int i=0;i<6;i++){
            std::vector<ChunkVertexPlane> *greedyPlanes =  &sidePlanes[i];
            for(int i=0;i<greedyPlanes->size();i++){
                renderPlanes[planes]= greedyPlanes->at(i);
                planes++;
            }
        }

        float dstVertices = planes*6;



        goChunk.vertices = dstVertices;
        buffer = 0x0;
        CreateBuffer(dstVertices, &buffer,
                    &bufferData1, &bufferData1Stride,
                    &bufferData2, &bufferData2Stride,
                    &bufferData3, &bufferData3Stride
                );
        uint8_t* bytes = 0x0;
        dmBuffer::GetBytes(buffer, (void**)&bytes, &goChunk.bufferMemory);


        vertices = 0;
        for (int i = 0; i < planes; ++i) {
            ChunkVertexPlane plane = renderPlanes[i];
            int x = plane.x;
            int y = plane.y;
            int z = plane.z;
            //top
            switch (plane.side) {
                case 0: {
                    drawVoxelVertex(&plane,x, y + 1.0, z, plane.voxel,1,plane.ao1);
                    drawVoxelVertex(&plane,x, y + 1.0,z + plane.planeH,plane.voxel,0,plane.ao0);
                    drawVoxelVertex(&plane,x + plane.planeW, y + 1.0, z + plane.planeH,plane.voxel,3,plane.ao3);

                    drawVoxelVertex(&plane,x, y + 1.0, z,plane.voxel,1,plane.ao1);
                    drawVoxelVertex(&plane,x + plane.planeW, y + 1.0, z + plane.planeH,plane.voxel,3,plane.ao3);
                    drawVoxelVertex(&plane,x + plane.planeW, y + 1.0, z,plane.voxel,2,plane.ao2);
                    break;
                }
                //bottom. Is bottom need AO?
                case 1: {
                    drawVoxelVertex(&plane,x, y, z,plane.voxel,2,plane.ao1);
                    drawVoxelVertex(&plane,x + plane.planeW, y, z + plane.planeH,plane.voxel,0,plane.ao3);
                    drawVoxelVertex(&plane,x, y, z + plane.planeH,plane.voxel,3,plane.ao0);

                    drawVoxelVertex(&plane,x, y, z,plane.voxel,2,plane.ao1);
                    drawVoxelVertex(&plane,x + plane.planeW, y, z, plane.voxel,1,plane.ao2);
                    drawVoxelVertex(&plane,x + plane.planeW, y, z + plane.planeH,plane.voxel,0,plane.ao3);
                    break;
                }
                //RIGHT(if look on back side(-z forward)
                case 2: {
                    drawVoxelVertex(&plane,x + 1.0, y, z,plane.voxel,3,plane.ao3);
                    drawVoxelVertex(&plane,x + 1.0, y + plane.planeH, z,plane.voxel,2,plane.ao2);
                    drawVoxelVertex(&plane,x + 1.0, y + plane.planeH, z + plane.planeW,plane.voxel,1,plane.ao1);

                    drawVoxelVertex(&plane,x + 1.0, y, z,plane.voxel,3,plane.ao3);
                    drawVoxelVertex(&plane,x + 1.0, y + plane.planeH, z + plane.planeW,plane.voxel,1,plane.ao1);
                    drawVoxelVertex(&plane,x + 1.0, y, z + plane.planeW,plane.voxel,0,plane.ao0);
                    break;
                }
                //LEFT
                case 3: {
                    drawVoxelVertex(&plane,x, y, z, plane.voxel,0,plane.ao0);
                    drawVoxelVertex(&plane,x, y + plane.planeH, z + plane.planeW,plane.voxel,2,plane.ao2);
                    drawVoxelVertex(&plane,x, y + plane.planeH, z,plane.voxel,1,plane.ao1);

                    drawVoxelVertex(&plane,x, y, z,plane.voxel,0,plane.ao0);
                    drawVoxelVertex(&plane,x, y, z + plane.planeW,plane.voxel,3,plane.ao3);
                    drawVoxelVertex(&plane,x, y + plane.planeH, z + plane.planeW,plane.voxel,2,plane.ao2);
                    break;
                }
                //front
                case 4: {
                    drawVoxelVertex(&plane,x, y, z + 1.0, plane.voxel,0,plane.ao0);
                    drawVoxelVertex(&plane,x + plane.planeW, y + plane.planeH, z + 1.0,plane.voxel,2,plane.ao2);
                    drawVoxelVertex(&plane,x, y + plane.planeH, z + 1.0,plane.voxel,1,plane.ao1);

                    drawVoxelVertex(&plane,x, y, z + 1.0,plane.voxel,0,plane.ao0);
                    drawVoxelVertex(&plane,x + plane.planeW, y, z + 1.0,plane.voxel,3,plane.ao3);
                    drawVoxelVertex(&plane,x + plane.planeW, y + plane.planeH, z + 1.0,plane.voxel,2,plane.ao2);
                    break;
                }
                //back
                case 5: {
                    drawVoxelVertex(&plane,x, y, z,plane.voxel,3,plane.ao3);
                    drawVoxelVertex(&plane,x, y + plane.planeH, z,plane.voxel,2,plane.ao2);
                    drawVoxelVertex(&plane,x + plane.planeW, y + plane.planeH, z, plane.voxel,1,plane.ao1);

                    drawVoxelVertex(&plane,x, y, z,plane.voxel,3,plane.ao3);
                    drawVoxelVertex(&plane,x + plane.planeW, y + plane.planeH, z,plane.voxel,1,plane.ao1);
                    drawVoxelVertex(&plane,x + plane.planeW, y, z,plane.voxel,0,plane.ao0);
                    break;
                }
            }
        }

        dmBuffer::Result metaDataResult = dmBuffer::SetMetaData(buffer, HASH_AABB, &goChunk.chunk->aabb, 6, dmBuffer::VALUE_TYPE_FLOAT32);
        if (metaDataResult != dmBuffer::RESULT_OK) {
            dmLogError("dmBuffer can't set AABB metadata");
        }
        updateGoBuffer(L, goChunk, buffer);
        // destroy buffer. Do not need destroy i transfer_ownership
       // dmBuffer::Destroy(buffer);
       //clear data for old buffer
        buffer = NULL;
        bufferData1= NULL;
        bufferData1Stride = 0;
        bufferData2= NULL;
        bufferData2Stride = 0;
        bufferData3= NULL;
        bufferData3Stride = 0;

    }
}

void ChunkRenderer::draw(lua_State *L) {
    for (int i = 0; i < drawList.Size(); i++) {
        GoChunk &item = drawList[i];
        if (!item.goCreated) {
            createChunkGo(L, item);
        }
        if(item.contentVersion != item.chunk->contentVersion && item.chunk->voxelsSize>0){
            item.contentVersion = item.chunk->contentVersion;
            drawChunk(L, item);
        }
    }
}

void ChunkRenderer::drawDebugChunkVertices(lua_State *L, int x,int y, int z) {
    DebugRendererPrepare(L);
    Chunk* chunk = world->chunks->getChunkByPos(x,y,z);
    if(chunk == NULL){ return;}
    GoChunk *item = NULL;
    for (int i = 0; i < drawList.Size(); i++) {
        GoChunk *drawItem = &drawList[i];
        if(drawItem->chunk == chunk){
            item = drawItem;
            break;
        }
    }
   
    if(item!=NULL && item->goCreated){
        lua_getglobal(L, "native_get_chunk_buffer");
        if (!lua_isfunction(L, -1)) {
           luaL_error(L, "no native_get_chunk_buffer function");
        }
        dmScript::PushURL(L, item->meshUrl);
        lua_call(L, 1, 1);
        dmBuffer::HBuffer buffer =  dmScript::CheckBufferUnpack(L, -1);
        lua_pop(L,1);

        uint16_t *bufferData;
        uint32_t bufferDataStride;
        uint16_t *bufferData3;
        uint32_t bufferData3Stride;
        dmBuffer::Result dataResult = dmBuffer::GetStream(buffer, HASH_CHUNK_DATA_2,(void **)&bufferData, NULL, NULL, &bufferDataStride);
        if (dataResult != dmBuffer::RESULT_OK) {
           dmLogError("drawDebugChunkVertices can't get buffer data2");
           return;
        }
        dataResult = dmBuffer::GetStream(buffer, HASH_CHUNK_DATA_3,(void **)&bufferData3, NULL, NULL, &bufferData3Stride);
        if (dataResult != dmBuffer::RESULT_OK) {
           dmLogError("drawDebugChunkVertices can't get buffer data2");
           return;
        }

        int triangles = item->vertices/3;

        for (int t = 0; t < triangles; t++) {
            dmRenderDDF::DrawLine msg;
            msg.m_Color = dmVMath::Vector4(0,1,0,1);
            uint16_t *dataIter = &bufferData[t*3*bufferDataStride];
            uint16_t *dataIterNext = dataIter + bufferDataStride;
            uint16_t *data3Iter = &bufferData3[t*3*bufferData3Stride];
            uint16_t *data3IterNext = data3Iter + bufferData3Stride;
            for(int v =0;v<3;v++){
                //1-4[0,15] x /5-8[0,15] z /9-16[0,255] y
                //int16_t data2value = x | (z<<4) | (y<<8);
                uint16_t dataValue = dataIter[0];
                uint16_t dataNextValue = dataIterNext[0];

                uint16_t data3Value = data3Iter[0];
                uint16_t data3NextValue = data3IterNext[0];
                if(v==2){
                    //draw p3-p1
                    dataNextValue = bufferData[t*3*bufferDataStride];
                    data3NextValue = bufferData3[t*3*bufferData3Stride];
                }
                int x1 = chunk->x+(dataValue&63);
                int y1 = chunk->y+(((dataValue>>8)&240)|(data3Value>>12));
                int z1 = chunk->z+((dataValue>>6)&63);

                int x2 = chunk->x+(dataNextValue&63);
                int y2 = chunk->y+(((dataNextValue>>8)&240)|(data3NextValue>>12));
                int z2 = chunk->z+((dataNextValue>>6)&63);

                msg.m_StartPoint.setX(x1);
                msg.m_StartPoint.setY(y1);
                msg.m_StartPoint.setZ(z1);

                msg.m_EndPoint.setX(x2);
                msg.m_EndPoint.setY(y2);
                msg.m_EndPoint.setZ(z2);

                DebugRendererDrawLine(L,&msg);
                dataIter += bufferDataStride;
                dataIterNext += bufferDataStride;
                data3Iter += bufferData3Stride;
                data3IterNext += bufferData3Stride;
            }
        }
    }
}

void ChunkRenderer::drawDebugChunkFrustum(lua_State *L, int x,int y, int z) {
    DebugRendererPrepare(L);
    Chunk* chunk = world->chunks->getChunkByPos(x,y,z);
    if(chunk == NULL){ return;}
     float *aabb = chunk->aabb;
    dmVMath::Vector3 chunkPos = dmVMath::Vector3(chunk->x, chunk->y, chunk->z);
    DebugRendererDrawAABB(L, chunkPos+dmVMath::Vector3(aabb[0], aabb[1], aabb[2]), chunkPos+dmVMath::Vector3(aabb[3], aabb[4], aabb[5]),
    dmVMath::Vector4(0, 0, 1, 1));

}

void ChunkRenderer::drawDebugChunkBorders(lua_State *L, int x,int y, int z) {
    DebugRendererPrepare(L);
    Chunk* chunk = world->chunks->getChunkByPos(x,y,z);
    if(chunk == NULL){ return;}
    dmVMath::Vector3 chunkPos = dmVMath::Vector3(chunk->x, chunk->y+chunk->yBegin, chunk->z);
    DebugRendererDrawAABB(L, chunkPos, chunkPos+dmVMath::Vector3(CHUNK_W, chunk->yEnd-chunk->yBegin, CHUNK_D),
                                  dmVMath::Vector4(1, 0, 0, 1));
}

uint32_t ChunkRenderer::getChunksCount(){
    return drawList.Size();
}
uint32_t ChunkRenderer::getChunksVisibleCount(){
    return drawList.Size();
}

uint32_t ChunkRenderer::getBuffersCount(){
    uint32_t count = 0;
    for (int i = 0; i < drawList.Size(); i++) {
        GoChunk &item = drawList[i];
        if(item.bufferMemory>0){
            count++;
        }
    }
    return count;
}
uint32_t ChunkRenderer::getBuffersMemoryCount(){
    uint32_t memory = 0;
    for (int i = 0; i < drawList.Size(); i++) {
        GoChunk &item = drawList[i];
        if(item.bufferMemory>0){
            memory+=item.bufferMemory;
        }
    }
    return memory;
}

uint32_t ChunkRenderer::getChunksVisibleVertices(){
    uint32_t vertices = 0;
    for (int i = 0; i < drawList.Size(); i++) {
        GoChunk &item = drawList[i];
        if(item.vertices>0){
            vertices+=item.vertices;
        }
    }
    return vertices;
}



} // namespace VoxelGame
