uniform lowp vec4 ambient_color;
uniform lowp vec4 sunlight_color;

varying mediump vec3 var_world_position;
varying mediump vec3 var_view_position;
varying mediump vec3 var_world_normal;


void main() {
    vec3 color = vec3(0.4,0.4,0.4);

    //COLOR
    vec3 illuminance_color = vec3(0);
    // Ambient
    vec3 ambient = ambient_color.rgb * ambient_color.w;
    illuminance_color = illuminance_color + ambient;

    //REGION SHADOW -----------------
    vec3 diff_light = vec3(0);
    diff_light += sunlight_color.rgb*sunlight_color.w;
    diff_light += vec3(illuminance_color.xyz);

    color.rgb = color.rgb * min(diff_light, 1.0);
    //endregion


    gl_FragColor = vec4(color.rgb, 1.0);
}