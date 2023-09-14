#ifndef shadow_fp
#define shadow_fp

uniform lowp vec4 shadow_color;
uniform lowp sampler2D SHADOW_TEXTURE;
uniform lowp vec4 sun_position; //sun light position

varying lowp vec4 var_texcoord0_shadow;

float shadow_calculation_mobile(vec4 depth_data){

    return shadow;
}

// SUN! DIRECT LIGHT
vec3 direct_light(vec3 light_color, vec3 light_position, vec3 position, vec3 vnormal, vec3 shadow_color){
    vec3 dist = light_position;
    vec3 direction = normalize(dist);
    float n = max(dot(vnormal, direction), 0.0);
    vec3 diffuse = (light_color - shadow_color) * n;
    return diffuse;
}

#endif