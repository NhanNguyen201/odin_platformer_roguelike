#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform sampler2D texture0;

uniform vec2 screenSize;
uniform vec2 lightPos;

void main()
{
    vec4 texel = texture(texture0, fragTexCoord);

    vec2 pixelPos = fragTexCoord * screenSize;

    float dist = distance(pixelPos, lightPos);

    // Radius of visible area
    float radius = 180.0;

    // Soft edge
    float softness = 80.0;

    float light = smoothstep(
        radius + softness,
        radius,
        dist
    );
    float mixed_light = mix(0.2, 1., light);
    vec3 darkened = texel.rgb * mixed_light;

    finalColor = vec4(darkened, texel.a);
}