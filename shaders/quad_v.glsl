#version 460 core

layout (location = 0) in vec2 position;

//out vec2 pos;
out vec2 frag_coord;



void main() {

    //pos = position;
    frag_coord = position;

    //gl_Position = vec4(position[0], position[1], 0.99999, 1);
    gl_Position = vec4(position[0], position[1], 0, 1);
    
}