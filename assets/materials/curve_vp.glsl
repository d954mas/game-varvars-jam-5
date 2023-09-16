#ifndef curve_fp
#define curve_fp

uniform highp vec4 curve_origin;
uniform mediump vec4 curve;

vec4 countCurve(vec4 world_pos){
    return world_pos;
	/*vec4 to_cam = curve_origin - world_pos;
	float kz = to_cam.z*to_cam.z;
	float kx = to_cam.x*to_cam.x;
	world_pos.y = world_pos.y - kz*curve.z - kx*curve.x;
	world_pos.x = world_pos.x - kz*curve.w;
	return world_pos;*/
}

#endif