#version 150

#moj_import <fog.glsl>
#moj_import <psrdnoise2.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

in vec2 relCoord;
flat in int actionbar;
flat in int intro;
in float xPos;

out vec4 fragColor;

const vec4 title_color = vec4(1,0,0,1);
const vec4 title_hcolor = vec4(0.87, 0.47, 0.0, 1.0);

void main() {
    vec4 tex = texture(Sampler0, texCoord0);
    vec4 color = tex * vertexColor * ColorModulator;

    if(intro < 0) discard;
    else if(intro > 0) {
        fragColor = title_color;
        fragColor.a = tex.a * vertexColor.a;
        fragColor += title_hcolor * (psrdfbm(relCoord * vec2(5, 1) + GameTime * vec2(500, 200)) + 1) * fragColor.a;
        return;
    }

    if(color.a < 0.01) discard;

    if(actionbar != 0 && xPos < -90.0) discard;

    if(tex.a < 1.0) {
        float distWhite = distance(vertexColor.rgb, vec3(1.0));
        float distBlack = distance(vertexColor.rgb, vec3(0.0));
        float ratio = distWhite / (distWhite + distBlack);
        if(ratio > 0.5) discard;
    }

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);

    if(actionbar == 1) fragColor = vec4(1);
    else if(actionbar == 2) fragColor = vec4(0, 0, 0, 1);
}
