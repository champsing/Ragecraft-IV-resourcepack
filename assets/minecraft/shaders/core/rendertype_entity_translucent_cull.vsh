#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

uniform float GameTime;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec2 texCoord1;
out vec2 texCoord2;
out vec4 normal;

flat out int customId;
out vec2 relCoord;
out vec2 groundPos;
out vec3 sphere;
out vec3 wpos;
out vec3 origin;

vec3 pos;
vec3 norm;

mat3 getWorldMat(vec3 light0, vec3 light1) {    
    mat3 V = mat3(normalize(vec3(0.2, 1.0, -0.7)), normalize(vec3(-0.2, 1.0, 0.7)), normalize(cross(vec3(0.2, 1.0, -0.7), vec3(-0.2, 1.0, 0.7))));
    mat3 W = mat3(normalize(light0), normalize(light1), normalize(cross(light0, light1)));
    return W * inverse(V);
}

vec3 rotatevec3(vec3 p, vec3 axis, float a) {
    return mix(dot(axis, p) * axis, p, cos(a)) + cross(axis, p) * sin(a);
}

void setRelCoord() {
    switch(gl_VertexID % 4) {
        case 0: relCoord = vec2(-1.0, 1.0); break;
        case 1: relCoord = vec2(-1.0,-1.0); break;
        case 2: relCoord = vec2( 1.0,-1.0); break;
        case 3: relCoord = vec2( 1.0, 1.0); break;
    }
}

void town_portal_ground() {
    mat3 worldMat = getWorldMat(Light0_Direction, Light1_Direction);
    pos *= worldMat;

    pos.y += 0.09 * sin(GameTime * 1000.0);
    groundPos = vec2(pos.xz);

    pos *= inverse(worldMat);

    setRelCoord();
}

void grave() {
    origin = pos;

    int face = (gl_VertexID / 4) % 256;
    int vertex = gl_VertexID % 4;

    float ax = ((face % 16) + int(vertex > 1)) * 0.3926990817;
    float ay = ((face / 16) + int(vertex > 0 && vertex <3 )) * 0.19634954085;

    sphere = rotatevec3(vec3(1, 0, 0), vec3(0, 1, 0), ax) * sin(ay);
    sphere.y = cos(ay);
    norm = rotatevec3(sphere, vec3(0, 1, 0), GameTime * 500.0);

    pos += norm * (0.5 + pow(sin(GameTime * 4000.0), 2.0) * 0.03);
    wpos = pos;
}

void main() {
    pos = Position;
    norm = Normal;
    customId = 0;

    vec4 colorB = texture(Sampler0, UV0);
    if(int(colorB.a * 255) == 253) {
        if(int(colorB.r * 255) == 187 && int(colorB.g * 255) == 0 && int(colorB.b * 255) == 187) {
            customId = 1;
            town_portal_ground();
        }

        if(int(colorB.r * 255) == 170 && int(colorB.g * 255) == 0 && int(colorB.b * 255) == 170) {
            customId = 2;
            grave();
        }
    }

    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);

    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * pos, FogShape);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, norm, Color) * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;
    texCoord1 = UV1;
    texCoord2 = UV2;
    normal = ProjMat * ModelViewMat * vec4(norm, 0.0);
}
