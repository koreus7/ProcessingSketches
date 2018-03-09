#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

varying vec4 vertTexCoord;
uniform sampler2D texture;

void main(void)
{
  	vec2 p = vertTexCoord.st;
	vec3 col = vec3(1.0) - texture2D(texture, p).rgb;
	col.x = 0.0; 
	col.y = 0.0;
	col.z = 1.0;
	gl_FragColor = vec4(col, 1.0);
}
