#include "/assets/materials/shadow/shadow_fp.glsl"
#include "/assets/materials/light_fp.glsl"
#include "/assets/materials/chunk/chunk_fp.glsl"

void main(){
    vec2 texCoord = fract(var_texcoord0.xy*var_tiles);
    //https://stackoverflow.com/questions/34951491/using-floor-function-in-glsl-when-sampling-a-texture-leaves-glitch
   // vec2 uvMipmap = var_uvSize.xy + var_texcoord0.xy*var_uvSize.zw;

    texCoord = var_uvSize.xy + (texCoord.xy*var_uvSize.zw);
    // convert normalized texture coordinates to texel units before calling mip_map_level
    //float mipmapLevel = mip_map_level(uvMipmap * vec2(textureSize(DIFFUSE_TEXTURE, 0).xy));
  //  mipmapLevel = clamp(mipmapLevel, 0.0, 3.0);
    //fixed mipmap bleeding
  //  vec4 texture_color = texture2D(DIFFUSE_TEXTURE, texCoord.xy+var_uvToCenter*mipmapLevel/3.0);
    vec4 texture_color = texture2D(DIFFUSE_TEXTURE, texCoord.xy);
   // vec4 texture_color =textureGrad(DIFFUSE_TEXTURE, texCoord+var_uvToCenter*mipmapLevel/3.0, dFdx(uvMipmap), dFdy(uvMipmap));
   // vec4 texture_color =textureGrad(DIFFUSE_TEXTURE, texCoord+var_uvToCenter*mipmapLevel/3.0, dFdx(uvMipmap), dFdy(uvMipmap));

    vec3 color = texture_color.rgb;
    color = color* var_light_power;//add AO


    //COLOR
    vec3 illuminance_color = vec3(0);
    // Ambient
    vec3 ambient = ambient_color.rgb * ambient_color.w;
    illuminance_color = illuminance_color + ambient;


    //
    // Lights



    //REGION SHADOW -----------------
    // shadow map
    vec4 depth_proj = var_texcoord0_shadow / var_texcoord0_shadow.w;
    float shadow = shadow_calculation_mobile(depth_proj.xyzw);
    vec3 shadow_color = shadow_color.xyz*shadow_color.w*(sunlight_color.w) * shadow;

    vec3 diff_light = vec3(0);

    diff_light += max(direct_light(sunlight_color.rgb, sun_position.xyz, var_world_position.xyz, var_world_normal, shadow_color)*sunlight_color.w,0.0);
    diff_light += vec3(illuminance_color.xyz);
    // diff_light = clamp(diff_light, 0.0, ambient_color.w);

    color.rgb = color.rgb * (min(diff_light, 1.0));

    //endregion


    //
    // Mixing
   // color = color * (min(illuminance_color, 1.0));
   // color = mix(color, fog_color.rgb, fog_factor);

    gl_FragColor = vec4(color, texture_color.a);
}

