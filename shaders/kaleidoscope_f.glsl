#version 450 core

out vec4 final_color;

in vec2 frag_coord;

uniform float current_time;


// Neon circles blooming into a fractal hexagonal grid.
// Inspiration:
// - https://www.shadertoy.com/view/mly3Dd - Glowing concentric circles + square grid folding
// - https://www.shadertoy.com/view/NtBSRV - Hexagonal cells

//#define TETRASKELION  // if hexagons offend you

vec3 pal(float a) { return 0.5 + cos(3.0 * a + vec3(2, 1, 0)); }  // Biased rainbow color map. Will be squared later.

vec2 fold(vec2 p) {  // Shift and fold into a vertex-centered grid.
#ifdef TETRASKELION
    return fract(p) - 0.5;
#else
    vec4 m = vec4(2, -1, 0, sqrt(3.0));
    p.y += m.w / 3.0;      // center at vertex
    vec2 t = mat2(m) * p;  // triangular coordinates (x →, y ↖, x+y ↗)
    return p - 0.5 * mat2(m.xzyw) * floor((ceil(t) + ceil(t.x + t.y)) / 3.0);  // fold into hexagonal cells
#endif
}

void main() {
    float t = current_time / 4.0, t2 = t * 0.618034, t3 = t * 1.4142135;  // dissonant timers
    mat2 M = mat2(cos(t), sin(t), -sin(t), cos(t)) * (1.0 - 0.1 * cos(t2));  // rotation and scale: 0.9 [smooth] .. 1.1 [fractal]

    vec3 iResolution;
    iResolution[0] = 1;
    iResolution[1] = 1;

    vec2 new_pos;
    new_pos[0] = frag_coord[0] + 0.5;
    new_pos[1] = frag_coord[1] + 0.5;

    vec2 p = (2.0 * new_pos - iResolution.xy) / iResolution.y;  // y: -1 .. 1
    float d = 0.5 * length(p);  // animation phase is based on distance to center

    vec3 sum = vec3(0);
    for (float i = 0.0; i < 24.0; i++) {
        p = fold(M * p);                                            // rotate and scale, fold
        sum += pal(0.01 * i - d + t2) / cos(d - t3 + 5.0 * length(p));  // interfering concentric circles
        // Use pal(...)/abs(cos(...)) for additive circles. I like the interference effect without the abs.
    }

    final_color = vec4(0.0002 * sum * sum, 1);  // square the sum for better contrast
}