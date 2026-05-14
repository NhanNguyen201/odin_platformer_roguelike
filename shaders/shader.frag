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

    float get_noise = noise(vec2(pixelPos.x * 3. + uTime * .5, pixelPos.y * 3.) );
    
    vec3 distorted = vec3(
        step(0.5,  length(texel.rgb))
        // step(0.5, texel.g * 0.8 + 0.2 * noise(vec2(pixelPos.x * 0.2 + uTime * .5, pixelPos.y * .2) )),
        // step(0.5, texel.b * 0.8 + 0.2 * noise(vec2(pixelPos.x * 0.1 + uTime * .5, pixelPos.y * 0.2) ))
    );
    vec4 outsideColor = vec4(distorted * 0.4 + 0.6 * texel.rgb, 1.);
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