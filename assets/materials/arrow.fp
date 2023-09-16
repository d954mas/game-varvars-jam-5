uniform lowp sampler2D DIFFUSE_TEXTURE;

#include "/assets/materials/shadow/shadow_fp.glsl"
#include "/assets/materials/light_fp.glsl"

varying mediump vec2 var_texcoord0;
//varying highp vec3 var_camera_position;
varying mediump vec3 var_world_position;
varying mediump vec3 var_view_position;
varying mediump vec3 var_world_normal;

uniform mediump vec4 tint;




void main() {
    vec3 color = tint.rgb;

    //
    // Defold Editor
    if (sun_position.xyz == vec3(0)) {

        gl_FragColor = vec4(color.rgb * vec3(0.8), 1.0);

        // If the first byte is zero, it's the editor,
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
    vec3 shadow_color = shadow_color.xyz*shadow_color.w*(sunlight_color.w) * 1.0;
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

    gl_FragColor = vec4(color, tint.a);

}