#include "objects/box_userdata.h"
#include "utils.h"

#define META_NAME "d954mas::Box"
#define USERDATA_TYPE "d954mas::Box"


namespace VoxelGame {

BoxUserdata::BoxUserdata(): BaseUserData(USERDATA_TYPE, META_NAME){

}

BoxUserdata::~BoxUserdata() {

}


BoxUserdata* BoxUserdataCheck(lua_State *L, int index) {
    BoxUserdata *userdata = (BoxUserdata*) BaseUserData_get_userdata(L, index, USERDATA_TYPE);
	return userdata;
}


void BoxUserdataInitMetaTable(lua_State *L){
    int top = lua_gettop(L);

    luaL_Reg functions[] = {
        { 0, 0 }
    };
    luaL_newmetatable(L, META_NAME);
    luaL_register (L, NULL,functions);
    lua_pushvalue(L, -1);
    lua_setfield(L, -1, "__index");
    lua_pop(L, 1);

    assert(top == lua_gettop(L));
}


void BoxUserdata::Destroy(lua_State *L){
    BaseUserData::Destroy(L);
}

void BoxUserdataPush(lua_State *L){

}

}