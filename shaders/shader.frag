#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform sampler2D texture0;

uniform vec2 screenSize;
uniform vec2 lightPos;
uniform float uTime;

const vec2 d = vec2(0.0, 1.0);

float rand(float n){return fract(sin(n) * 43758.5453123);}
float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}

void main() {


    vec4 texel = texture(texture0, fragTexCoord);

    vec2 pixelPos = fragTexCoord * screenSize;

    float get_noise = noise(vec2(pixelPos.x * 0.07 , pixelPos.y * 0.07 - uTime * .75) );
    vec2 offset = vec2(0, -.05);
    vec3 distorted = vec3(
       texel.rgb * 0.8 + texture(texture0, fragTexCoord + offset * sin(get_noise) ).rgb * 0.6
     
    );
    vec3 step_vec = texel.rgb;
    step_vec.r *= 0.55;
    step_vec.b *= 0.33;
    vec4 outsideColor = mix(
        vec4(mix(distorted, vec3(0), step(0.1, 1. - length(distorted))) , 1.), 
        vec4(texel.rgb , 1.), 
        step(0.5,  1.- length(step_vec ))
    );
    
    float dist = distance(pixelPos, lightPos);

    // Radius of visible area
    float radius = 450.0;

    // Soft edge
    float softness = 80.0;

    float light = smoothstep(
        radius + softness,
        radius,
        dist
    );
    // float mixed_light = mix(0.6 + .4 * sin(uTime * 2.), 1., light);
    vec4 mixed = mix(outsideColor, texel, light);

    finalColor = mixed;
}