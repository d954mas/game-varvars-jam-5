#include <render/render_ddf.h> // dmRenderDDF::DrawLine
#include "voxels/debug_renderer.h"

namespace VoxelGame {

static dmMessage::URL receiver;

void DebugRendererPrepare(lua_State* L){
    dmMessage::ResetURL(&receiver);
    dmMessage::Result result = dmMessage::GetSocket(dmRender::RENDER_SOCKET_NAME, &receiver.m_Socket);
    if (result != dmMessage::RESULT_OK){
        luaL_error(L,"The socket '%s' could not be found.", dmRender::RENDER_SOCKET_NAME);
    }
}

void DebugRendererDrawLine(lua_State* L,dmRenderDDF::DrawLine *msg){
    //dmMessage::Result result = dmMessage::PostDDF(&msg,0x0, &receiver, (uintptr_t) instance,0, 0);
    dmMessage::Result result = dmMessage::PostDDF(msg,0x0, &receiver, NULL,0, 0);
    if(result!=dmMessage::RESULT_OK){luaL_error(L,"can't draw line");}
}

void DebugRendererDrawLine(lua_State* L,dmVMath::Vector3 p1,dmVMath::Vector3 p2,dmVMath::Vector4 color){
    dmRenderDDF::DrawLine msg = CreateDrawLineMsg(p1,p2,color);
    DebugRendererDrawLine(L, &msg);
}

void DebugRendererDrawAABB(lua_State* L,dmVMath::Vector3 min,dmVMath::Vector3 max,dmVMath::Vector4 color){
    float dx = max.getX() - min.getX();
    float dy = max.getY() - min.getY();
    float dz = max.getZ() - min.getZ();

    dmVMath::Vector3 p1 = min;
    dmVMath::Vector3 p2 = min+dmVMath::Vector3(dx,0,0);
    dmVMath::Vector3 p3 = min+dmVMath::Vector3(dx,0,dz);
    dmVMath::Vector3 p4 = min+dmVMath::Vector3(0,0,dz);

    dmVMath::Vector3 p5 = p1 +dmVMath::Vector3(0,dy,0) ;
    dmVMath::Vector3 p6 = p2 +dmVMath::Vector3(0,dy,0) ;
    dmVMath::Vector3 p7 = p3 +dmVMath::Vector3(0,dy,0) ;
    dmVMath::Vector3 p8 = p4 +dmVMath::Vector3(0,dy,0) ;


    DebugRendererDrawLine(L,p1, p2,color);
    DebugRendererDrawLine(L,p2, p3,color);
    DebugRendererDrawLine(L,p3, p4,color);
    DebugRendererDrawLine(L,p4, p1,color);

    DebugRendererDrawLine(L,p5, p6,color);
    DebugRendererDrawLine(L,p6, p7,color);
    DebugRendererDrawLine(L,p7, p8,color);
    DebugRendererDrawLine(L,p8, p5,color);

    DebugRendererDrawLine(L,p1, p5,color);
    DebugRendererDrawLine(L,p2, p6,color);
    DebugRendererDrawLine(L,p3, p7,color);
    DebugRendererDrawLine(L,p4, p8,color);



}

}