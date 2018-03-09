#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

varying vec4 vertTexCoord;
uniform sampler2D texture;

uniform float time;
uniform float width; 
uniform float height;
uniform float phase;
uniform float frequency;
//uniform float frequencyMod;


float avg(vec4 col)
{
	return (col.r + col.g + col.b)/3.;
}

//another way to make cheap noise
vec4 tessnoise(vec2 p, vec4 col, float phase, float frequency) 
{ 
	vec4 base         	= vec4(p, 0., 0.);
	vec4 rotation          	= vec4(0., 0., 0., 0.);
	
	float theta     	= fract(time*.025);
	//float phase		= 0.5;
	//float frequency		= 0.4;
		
	//yo dog, I heard you like fractals
	vec4 result      	= vec4(0.);			    
	for (float i = 0.; i < 16.; i++)	
	{		
		base		+= rotation;		
		rotation	= fract(base.wxyz - base.zwxy + theta).wxyz;		
		rotation	*= (1.-rotation);
		base		*= frequency;
		base		+= base.wxyz * phase ;//* (1. + avg(col)*0.0001);

	}
	return rotation * 2.;
}

void main(void)
{
	vec4 col = vec4(texture2D(texture, vertTexCoord.st).rgb,1.0);

	// gl_FragColor = vec4(col, 1.0);

	vec2 aspect	= vec2(width,height)/min(width, height);
	vec2 fc 	= vertTexCoord.st;
	vec2 uv 	= fc/vec2(width, height);

	vec2 p		= (uv - .5) * aspect;
	float l = ( 1. - length(fc - .5))*0.8;
	p 		*= pow(2., 16.);

	//blend and tweak to avoid repetition
	vec4 a		= tessnoise(p, col, phase, frequency) 
	*(2./3.);
	vec4 b		= tessnoise((p + pow(2., 17.))/8. + a.xy - a.zw, col, phase, frequency*(1. + l*0.0003))
	*(1./3.);
	vec4 c 		= tessnoise((p + pow(2., 9.))/4. + b.xy - b.zw, col, phase, frequency*(1. + l*0.0008))
	*0.0*(1./3.); 
	
	vec4 n		= (a+b+c);//3.;
	//gl_FragColor 	= (n*0.9 + col*0.1)
	gl_FragColor = vec4(vec3(sqrt(l*2.))*n.rgb,1.0)*0.9 + col*0.1;
}
