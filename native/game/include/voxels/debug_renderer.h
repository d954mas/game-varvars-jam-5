#ifndef debug_render_h
#define debug_render_h

#include <dmsdk/sdk.h>
#include <render/render_ddf.h> // dmRenderDDF::DrawLine

namespace dmRender{
    extern const char* RENDER_SOCKET_NAME;
}

namespace dmMessage{
    Result GetSocket(const char *name, HSocket* out_socket);
}

namespace VoxelGame {

inline dmRenderDDF::DrawLine CreateDrawLineMsg(dmVMath::Vector3 p1,dmVMath::Vector3 p2,dmVMath::Vector4 color){
    dmRenderDDF::DrawLine msg;
    msg.m_StartPoint.setX(p1.getX());
    msg.m_StartPoint.setY(p1.getY());
    msg.m_StartPoint.setZ(p1.getZ());

    msg.m_EndPoint.setX(p2.getX());
    msg.m_EndPoint.setY(p2.getY());
    msg.m_EndPoint.setZ(p2.getZ());
    msg.m_Color = color;
    return msg;
}

void DebugRendererPrepare(lua_State* L);
void DebugRendererDrawLine(lua_State* L,dmRenderDDF::DrawLine *msg);
void DebugRendererDrawLine(lua_State* L,dmVMath::Vector3 p1,dmVMath::Vector3 p2,dmVMath::Vector4 color);
void DebugRendererDrawAABB(lua_State* L,dmVMath::Vector3 min,dmVMath::Vector3 max,dmVMath::Vector4 color);
}

#endif