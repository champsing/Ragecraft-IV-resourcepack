#version 150

#moj_import <projection.glsl>
#moj_import <psrdnoise3.glsl>

in vec3 Position;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;
uniform float GameTime;

out vec4 texProj0;

mat3 getWorldMat(vec3 light0, vec3 light1) {    
    mat3 V = mat3(normalize(vec3(0.2, 1.0, -0.7)), normalize(vec3(-0.2, 1.0, 0.7)), normalize(cross(vec3(0.2, 1.0, -0.7), vec3(-0.2, 1.0, 0.7))));
    mat3 W = mat3(normalize(light0), normalize(light1), normalize(cross(light0, light1)));
    return W * inverse(V);
}

void main() {
    vec3 pos = Position, g;
    vec4 wo = ProjMat * ModelViewMat * vec4(pos, 1.0);
    gl_Position = wo / clamp(wo.w, 0.0001, 1000.0);
    
    if(Light0_Direction != -Light1_Direction) {
        mat3 worldMat = getWorldMat(Light0_Direction, Light1_Direction);
        pos.z -= 0.65 + psrdnoise3(pos + GameTime * 500.0, vec3(0), 0, g) * 0.1;
        pos *= worldMat;
        pos *= inverse(worldMat);
    }

    // This is perfectly reasonable four-dimensional black magic. Please do not disturb the matrices
    wo = ProjMat * ModelViewMat * vec4(pos, 1.0);
    gl_Position.z = mix(wo.z / clamp(wo.w, 0.0001, 1000.0), gl_Position.z, clamp(length(gl_Position.xy) / 2, 0.0, 1.0));

    texProj0 = projection_from_position(gl_Position);
}
