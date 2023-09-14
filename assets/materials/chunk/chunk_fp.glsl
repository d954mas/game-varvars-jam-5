#include "/assets/materials/light_fp.glsl"

uniform lowp sampler2D DIFFUSE_TEXTURE;
varying mediump vec2 var_texcoord0;
varying mediump vec4 var_uvSize;
varying mediump vec2 var_uvToCenter;
varying mediump vec2 var_tiles;
varying lowp float var_light_power;

//varying highp vec3 var_camera_position;
varying mediump vec3 var_world_position;
varying mediump vec3 var_view_position;
varying lowp vec3 var_world_normal;



// Does not take into account GL_TEXTURE_MIN_LOD/GL_TEXTURE_MAX_LOD/GL_TEXTURE_LOD_BIAS,
// nor implementation-specific flexibility allowed by OpenGL spec
float mip_map_level(in vec2 texture_coordinate)// in texel units
{
    vec2  dx_vtc        = dFdx(texture_coordinate);
    vec2  dy_vtc        = dFdy(texture_coordinate);
    float delta_max_sqr = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));
    float mml = 0.5 * log2(delta_max_sqr);
    return max(0.0, mml);// Thanks @Nims
}