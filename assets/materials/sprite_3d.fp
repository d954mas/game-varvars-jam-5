uniform lowp sampler2D DIFFUSE_TEXTURE;



#include "/assets/materials/shadow/no_shadow_fp.glsl"
#include "/assets/materials/light_fp.glsl"




varying mediump vec2 var_texcoord0;
//varying highp vec3 var_camera_position;
varying mediump vec3 var_world_position;
varying mediump vec3 var_view_position;
varying mediump vec3 var_world_normal;


void main() {
    vec4 texture_color = texture2D(DIFFUSE_TEXTURE, var_texcoord0);
    vec3 color = texture_color.rgb;

    if(texture_color.a < 0.1) discard;

    //
    // Defold Editor
    if (sun_position.xyz == vec3(0)) {
   
        gl_FragColor = vec4(color.rgb * vec3(0.8), texture_color.a);

         //If the first byte is zero, it's the editor,
        // so just shade the sides according to the normal.
        return;
    }

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
    diff_light += max(sunlight_color.rgb*sunlight_color.w*0.5,0.0);
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