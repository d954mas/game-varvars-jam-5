#ifndef shadow_fp
#define shadow_fp

uniform lowp vec4 shadow_color;
uniform lowp sampler2D SHADOW_TEXTURE;
uniform lowp vec4 sun_position; //sun light position

varying lowp vec4 var_texcoord0_shadow;

vec2 rand(vec2 co){
    return vec2(fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453),
    fract(sin(dot(co.yx, vec2(12.9898, 78.233))) * 43758.5453)) * 0.00047;
}

float shadow_calculation(vec4 depth_data){
    float depth_bias = 0.00025;
    float shadow = 0.0;
    float texel_size = 1.0 / 1024.0;//textureSize(SHADOW_TEXTURE, 0);
    for (int x = -1; x <= 1; ++x)
    {
        for (int y = -1; y <= 1; ++y)
        {
            vec2 uv = depth_data.st + vec2(x, y) * texel_size;
            vec4 rgba = texture2D(SHADOW_TEXTURE, uv + rand(uv));
            // vec4 rgba = texture2D(SHADOW_TEXTURE, uv);
            // float depth = rgba_to_float(rgba);
            float depth = rgba.x;
            shadow += depth_data.z - depth_bias > depth ? 1.0 : 0.0;
        }
    }
    shadow /= 9.0;

    highp vec2 uv = depth_data.xy;
    if (uv.x<0.0) shadow = 0.0;
    if (uv.x>1.0) shadow = 0.0;
    if (uv.y<0.0) shadow = 0.0;
    if (uv.y>1.0) shadow = 0.0;

    return shadow;
}
float shadow_calculation_mobile(vec4 depth_data){
    float depth_bias = 0.00025;
    vec2 uv = depth_data.xy;
    // vec4 rgba = texture2D(SHADOW_TEXTURE, uv + rand(uv));
    vec4 rgba = texture2D(SHADOW_TEXTURE, uv);
    // float depth = rgba_to_float(rgba);
    float depth = rgba.x;
    //float shadow = depth_data.z - depth_bias > depth ? 1.0 : 0.0;
    //float shadow = step(depth,depth_data.z-depth_bias);
    float shadow = 1.0 - step(depth_data.z-depth_bias,depth);

    if (uv.x<0.0 || uv.x>1.0 || uv.y<0.0 || uv.y>1.0) shadow = 0.0;

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