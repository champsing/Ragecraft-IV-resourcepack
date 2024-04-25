#version 150

#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;
uniform float GameTime;
uniform vec2 ScreenSize;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

out vec2 relCoord;
flat out int actionbar;
flat out int intro;
out float xPos;

void setRelCoord() {
    switch(gl_VertexID % 4) {
        case 0: relCoord = vec2(-1.0, 1.0); break;
        case 1: relCoord = vec2(-1.0,-1.0); break;
        case 2: relCoord = vec2( 1.0,-1.0); break;
        case 3: relCoord = vec2( 1.0, 1.0); break;
    }
}

void main() {
    actionbar = 0; intro = 0;
    vec3 pos = Position;

    bool actionbar_fg = Color.r * 255.0 == 0x27 && Color.g * 255.0 == 0x11;
    bool actionbar_bg = Color.r * 255.0 == 0x09 && Color.g * 255.0 == 0x04;
    if(actionbar_fg || actionbar_bg) {
        int data = int(Color.b * 255.0) / (actionbar_fg ? 4 : 1); //0-8in 9-11stay 12-20out
        float progress = mod(GameTime * 24000.0 - data, 20.0);

        if(progress < 8.9) {
            float displacement = smoothstep(1.0, 0.0, progress / 9.0);
            pos.x -= displacement * displacement * 500.0;
        }

        else if(progress > 11.1) {
            float displacement = smoothstep(0.0, 1.0, (progress - 11.0) / 9.0);
            pos.x -= displacement * displacement * 500.0;
        }

        float gui_scale = ProjMat[0][0] / (2.0 / ScreenSize.x);
        xPos = pos.x - (ScreenSize.x / 2.0) / gui_scale;
        actionbar = int(actionbar_fg) + int(actionbar_bg) * 2;
    }

    bool intro_fg = Color.r * 255.0 == 0xAA && Color.g * 255.0 == 0x27 && Color.b * 255.0 == 0x11;
    bool intro_bg = Color.r * 255.0 == 0x2A && Color.g * 255.0 == 0x09 && Color.b * 255.0 == 0x04;
    if(intro_fg) {
        setRelCoord();
        intro = 1;
    } else if(intro_bg) {
        intro = -1;
    }

    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);

    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * pos, FogShape);
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;
}
