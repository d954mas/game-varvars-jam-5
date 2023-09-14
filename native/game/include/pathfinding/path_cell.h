#pragma once
#include <dmsdk/sdk.h>
#include <tuple>
#include "micropather.h"
#include <limits>
#include "math.h"
#include <vector>
#include <functional>
using namespace micropather;

struct PathCell{
	bool blocked = false;
	int x,z,id;
	inline PathCell(){};
	inline PathCell(int x, int z, int id):x(x),z(z),id(id){};
	inline PathCell(int x, int z, int id, bool blocked):x(x),z(z),id(id),blocked(blocked){};
};
