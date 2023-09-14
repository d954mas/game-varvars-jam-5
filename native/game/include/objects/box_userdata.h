#ifndef box_userdata_h
#define box_userdata_h

#include <dmsdk/sdk.h>
#include "base_userdata.h"

namespace VoxelGame {

class BoxUserdata : public BaseUserData {
private:

public:
    BoxUserdata();
	~BoxUserdata();

	virtual void Destroy(lua_State *L);
};

void BoxUserdataInitMetaTable(lua_State *L);
BoxUserdata* BoxUserdataCheck(lua_State *L, int index);
void BoxUserdataPush(lua_State *L);
}
#endif