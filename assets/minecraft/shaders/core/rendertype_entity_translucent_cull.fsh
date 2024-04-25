#version 150

#moj_import <fog.glsl>
#moj_import <psrdnoise2.glsl>
#moj_import <psrdnoise3.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec2 texCoord1;
in vec4 normal;

flat in int customId;
in vec2 relCoord;
in vec2 groundPos;
in vec3 sphere;
in vec3 wpos;
in vec3 origin;

out vec4 fragColor;

float aastep(float threshold, float value) {
    float afwidth = 0.7 * length(vec2(dFdx(value), dFdy(value)));
    return smoothstep(threshold - afwidth, threshold + afwidth, value);
}

float vec3_angle(vec3 a, vec3 b) {
    return acos(dot(normalize(a), normalize(b)));
}

vec2 rotate(float a, vec2 p) {
    vec2 U = vec2(cos(a), sin(a));
    vec2 V = vec2(-U.y, U.x);
    float u = dot(p, U);
    float v = dot(p, V);
    return vec2(u, v);
}

float level_dist(vec2 v, float l) {
    v = pow(abs(v), vec2(l));
    return pow(v.x + v.y, 1.0 / l);  
}

float segmentDist(vec2 start, vec2 end, vec2 pos) {
    vec2 line = end - start;
    float frac = dot(pos - start, line) / pow(length(line), 2.0);
    return distance(start + line * clamp(frac, 0.0, 1.0), pos);
}

void town_portal_ground() {
    fragColor = vec4(0.0);

    // Rotated and pixelated coords
    vec2 rc = rotate(GameTime * 100.0, relCoord); //6.28318531 / 100 * 24000=1508
    vec2 pc = rc - mod(rc, 1.0 / 16.0 / 6.0);
    vec2 rgr = rotate(-GameTime * 100.0, groundPos);
    vec2 gr = rgr - mod(rgr, 1.0 / 16.0);
    //vec2 rc = relCoord - mod(relCoord, 1.0 / 16.0 / 6.0);
    //vec2 pc = rotate(GameTime * 100.0, rc);

    // Distance and angle from center
    float l = length(pc);
	float theta = atan(pc.y, pc.x) / 6.2831853;

    // Ring glow
    float ring = 1.0 / (distance(l, 0.8) + 1.0);
    fragColor += pow(ring, 6.0) * (1.0 + sin(GameTime * 500.0) * 0.2);

    // Center square star
    float mid = 0.2 / (level_dist(pc, 0.7 + sin(GameTime * 1000.0) * 0.3) + 0.06);
    fragColor += pow(mid, 2.0);

    // Some interference of sorts
    vec2 g;
    fragColor.rgb *= psrdnoise(vec2(l - GameTime * 50.0, theta + l) * 10, vec2(0.0, 1.0), 0.0, g) + 1.0;

    // Small circles
    float smallDist = min(min(distance(pc, vec2( 0.0,  0.8)),
                              distance(pc, vec2( 0.0, -0.8))),
                          min(distance(pc, vec2( 0.8,  0.0)),
                              distance(pc, vec2(-0.8,  0.0))));
    fragColor -= clamp(1.0 - smallDist * 8.0, 0.0, 1.0);
    if(distance(smallDist, 0.1) < 0.01) fragColor = vec4(1.2);

    // Connecting segments
    //float lineDist = min(min(segmentDist(vec2( 0.0,  0.8), vec2( 0.8,  0.0), pc),
    //                         segmentDist(vec2( 0.0,  0.8), vec2(-0.8,  0.0), pc)),
    //                     min(segmentDist(vec2( 0.0, -0.8), vec2( 0.8,  0.0), pc),
    //                         segmentDist(vec2( 0.0, -0.8), vec2(-0.8,  0.0), pc)));
    //if(lineDist < 0.01) fragColor = vec4(1.2);

    // Nearby circle
    float grl = length(gr);
    float closeFactor = 1.0 - clamp(grl * 4.0, 0.0, 1.0);
    fragColor += closeFactor;
    if(distance(grl, 0.5) < 0.01 ||
       distance(grl, 0.3) < 0.02) fragColor = vec4(1.2);

    // Quantize color to make it look less "perfect"
    fragColor.rgb -= mod(fragColor.rgb, 0.1);

    // Make it purple-ish
    //fragColor *= vec4(0.322, 0.102, 0.686, 1.0);
    //fragColor *= vec4(0.7, 0.0, 1.0, 1.0);
    fragColor *= vec4(0.52, 0.0, 1.0, 1.0);

    // Glow
    float wow = length(fragColor);
    fragColor = mix(fragColor, vec4(1.0), smoothstep(0.0, 1.0, clamp(wow - 1.2, 0.0, 1.0)));

    // Fade on edge
    if(l > 0.9) fragColor.a *= clamp(1.0 - (l - 0.9) * 10.0, 0.0, 1.0);
}

void grave() {
    vec3 g;
    const vec4 base_color = vec4(1.0, 0.0, 0.0, 1.0), noise_color = vec4(1.0, 0.45, 0.0, 0.2);
    fragColor = base_color * pow(vec3_angle(wpos, origin) * length(origin) * 2, 2.0);
    fragColor += noise_color * pow(psrd3fbma(sphere + psrdnoise3(sphere * 5, vec3(0), GameTime * 1500.0, g) * 0.3, GameTime * 1000.0) / 2 + 0.8, 5.0);
    fragColor.rgb -= mod(fragColor.rgb, 0.3);
}

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if(color.a < 0.1) discard;

    switch(customId) {
        case 1: town_portal_ground(); return;
        case 2: grave(); return;
    }

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
