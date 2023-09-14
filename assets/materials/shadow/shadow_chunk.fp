uniform lowp sampler2D DIFFUSE_TEXTURE;

varying mediump vec2 var_texcoord0;




void main(){
    gl_FragColor = vec4(gl_FragCoord.z);
}

