/*
Real time PBR Volumetric Clouds by robobo1221.
Single scattering
Also includes volumetric light.
http://shadertoy.com/user/robobo1221

First ever somewhat PBR effect I decided to work on.
It uses the same algorithm to calculate the worldPosition as in: https://www.shadertoy.com/view/lstfR7

Feel free to fork and edit it. (Credit me please.)
Hope you enjoy!
*/

#version 450 core

out vec4 final_color;

in vec2 frag_coord;

uniform float current_time;



#define VOLUMETRIC_LIGHT
//#define SPHERICAL_PROJECTION

#define cameraMode 2 					//1 is free rotation, 2 is still camera but free sun rotation

#define cloudSpeed 0.02
#define cloudHeight 1600.0
#define cloudThickness 500.0
#define cloudDensity 0.03

#define fogDensity 0.00003

#define volumetricCloudSteps 32			//Higher is a better result with rendering of clouds.
#define volumetricLightSteps 8			//Higher is a better result with rendering of volumetric light.

#define cloudShadowingSteps 12			//Higher is a better result with shading on clouds.
#define volumetricLightShadowSteps 4	//Higher is a better result with shading on volumetric light from clouds

#define rayleighCoeff (vec3(0.27, 0.5, 1.0) * 1e-5)	//Not really correct
#define mieCoeff vec3(0.5e-6)						//Not really correct

const float sunBrightness = 3.0;

#define earthRadius 6371000.0

//////////////////////////////////////////////////////////////////

float bayer2(vec2 a) {
    a = floor(a);
    return fract(dot(a, vec2(.5, a.y * .75)));
}

vec2 rsi(vec3 position, vec3 direction, float radius) {
    float PoD = dot(position, direction);
    float radiusSquared = radius * radius;

    float delta = PoD * PoD + radiusSquared - dot(position, position);
    if (delta < 0.0) return vec2(-1.0);
    delta = sqrt(delta);

    return -PoD + vec2(-delta, delta);
}

#define bayer4(a)   (bayer2( .5*(a))*.25+bayer2(a))
#define bayer8(a)   (bayer4( .5*(a))*.25+bayer2(a))
#define bayer16(a)  (bayer8( .5*(a))*.25+bayer2(a))
#define bayer32(a)  (bayer16(.5*(a))*.25+bayer2(a))
#define bayer64(a)  (bayer32(.5*(a))*.25+bayer2(a))
#define bayer128(a) (bayer64(.5*(a))*.25+bayer2(a))

//////////////////////////////////////////////////////////////////

#define cloudMinHeight cloudHeight
#define cloudMaxHeight (cloudThickness + cloudMinHeight)

#define sunPosition vec3(1.0, 1.0, 0.0)

const float pi = acos(-1.0);
const float rPi = 1.0 / pi;
const float hPi = pi * 0.5;
const float tau = pi * 2.0;
const float rLOG2 = 1.0 / log(2.0);

mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    float xx = axis.x * axis.x;
    float yy = axis.y * axis.y;
    float zz = axis.z * axis.z;

    float xy = axis.x * axis.y;
    float xz = axis.x * axis.z;
    float zy = axis.z * axis.y;

    return mat3(oc * xx + c, oc * xy - axis.z * s, oc * xz + axis.y * s,
        oc * xy + axis.z * s, oc * yy + c, oc * zy - axis.x * s,
        oc * xz - axis.y * s, oc * zy + axis.x * s, oc * zz + c);
}

struct positionStruct
{
    vec2 texcoord;
    vec2 mousecoord;
    vec3 worldPosition;
    vec3 worldVector;
    vec3 sunVector;
} pos;

vec3 sphereToCart(vec3 sphere) {
    vec2 c = cos(sphere.xy);
    vec2 s = sin(sphere.xy);

    return sphere.z * vec3(c.x * c.y, s.y, s.x * c.y);
}

vec3 calculateWorldSpacePosition(vec2 p)
{
    p = p * 2.0 - 1.0;

    vec3 worldSpacePosition = vec3(p.x, p.y, 1.0);

#ifdef SPHERICAL_PROJECTION
    worldSpacePosition = sphereToCart(worldSpacePosition * vec3(pi, hPi, 1.0));
#endif

    return worldSpacePosition;
}

void gatherPositions(inout positionStruct pos, vec2 fragCoord, vec2 mouseCoord, vec2 screenResolution)
{
    pos.texcoord = fragCoord / screenResolution;
    pos.mousecoord = mouseCoord / screenResolution;

    pos.mousecoord = pos.mousecoord.x < 0.001 ? vec2(0.4, 0.64) : pos.mousecoord;

    vec2 rotationAngle = radians(vec2(360.0, 180.0) * pos.mousecoord - vec2(0.0, 90.0));

    mat3 rotateH = rotationMatrix(vec3(0.0, 1.0, 0.0), rotationAngle.x);
    mat3 rotateV = rotationMatrix(vec3(1.0, 0.0, 0.0), -rotationAngle.y);

    pos.worldPosition = calculateWorldSpacePosition(pos.texcoord);

    if (cameraMode == 1) {
        pos.worldPosition = rotateH * (rotateV * pos.worldPosition);

        // Sun position
        pos.sunVector = normalize(sunPosition);
    }
    if (cameraMode == 2) {
        vec3 temp;
        temp[0] = 0.0;
        temp[1] = 1.0;
        temp[2] = 1.0;
        //pos.sunVector = normalize(calculateWorldSpacePosition(pos.mousecoord));
        pos.sunVector = normalize(temp);
    }

    pos.worldVector = normalize(pos.worldPosition);
}

///////////////////////////////////////////////////////////////////////////////////

#define d0(x) (abs(x) + 1e-8)
#define d02(x) (abs(x) + 1e-3)

const vec3 totalCoeff = rayleighCoeff + mieCoeff;

vec3 scatter(vec3 coeff, float depth) {
    return coeff * depth;
}

vec3 absorb(vec3 coeff, float depth) {
    return exp2(scatter(coeff, -depth));
}

float calcParticleThickness(float depth) {

    depth = depth * 2.0;
    depth = max(depth + 0.01, 0.01);
    depth = 1.0 / depth;

    return 100000.0 * depth;
}

float calcParticleThicknessH(float depth) {

    depth = depth * 2.0 + 0.1;
    depth = max(depth + 0.01, 0.01);
    depth = 1.0 / depth;

    return 100000.0 * depth;
}

float calcParticleThicknessConst(const float depth) {

    return 100000.0 / max(depth * 2.0 - 0.01, 0.01);
}

float rayleighPhase(float x) {
    return 0.375 * (1.0 + x * x);
}

float hgPhase(float x, float g)
{
    float g2 = g * g;
    return 0.25 * ((1.0 - g2) * pow(1.0 + g2 - 2.0 * g * x, -1.5));
}

float miePhaseSky(float x, float depth)
{
    return hgPhase(x, exp2(-0.000003 * depth));
}

float powder(float od)
{
    return 1.0 - exp2(-od * 2.0);
}

float calculateScatterIntergral(float opticalDepth, float coeff) {
    float a = -coeff * rLOG2;
    float b = -1.0 / coeff;
    float c = 1.0 / coeff;

    return exp2(a * opticalDepth) * b + c;
}

vec3 calculateScatterIntergral(float opticalDepth, vec3 coeff) {
    vec3 a = -coeff * rLOG2;
    vec3 b = -1.0 / coeff;
    vec3 c = 1.0 / coeff;

    return exp2(a * opticalDepth) * b + c;
}


vec3 calcAtmosphericScatter(positionStruct pos, out vec3 absorbLight) {
    const float ln2 = log(2.0);

    float lDotW = dot(pos.sunVector, pos.worldVector);
    float lDotU = dot(pos.sunVector, vec3(0.0, 1.0, 0.0));
    float uDotW = dot(vec3(0.0, 1.0, 0.0), pos.worldVector);

    float opticalDepth = calcParticleThickness(uDotW);
    float opticalDepthLight = calcParticleThickness(lDotU);

    vec3 scatterView = scatter(totalCoeff, opticalDepth);
    vec3 absorbView = absorb(totalCoeff, opticalDepth);

    vec3 scatterLight = scatter(totalCoeff, opticalDepthLight);
    absorbLight = absorb(totalCoeff, opticalDepthLight);

    vec3 absorbSun = abs(absorbLight - absorbView) / d0((scatterLight - scatterView) * ln2);

    vec3 mieScatter = scatter(mieCoeff, opticalDepth) * miePhaseSky(lDotW, opticalDepth);
    vec3 rayleighScatter = scatter(rayleighCoeff, opticalDepth) * rayleighPhase(lDotW);

    vec3 scatterSun = mieScatter + rayleighScatter;

    vec3 sunSpot = smoothstep(0.9999, 0.99993, lDotW) * absorbView * sunBrightness;

    return (scatterSun * absorbSun + sunSpot) * sunBrightness;
}

vec3 calcAtmosphericScatterTop(positionStruct pos) {
    const float ln2 = log(2.0);

    float lDotU = dot(pos.sunVector, vec3(0.0, 1.0, 0.0));

    float opticalDepth = calcParticleThicknessConst(1.0);
    float opticalDepthLight = calcParticleThickness(lDotU);

    vec3 scatterView = scatter(totalCoeff, opticalDepth);
    vec3 absorbView = absorb(totalCoeff, opticalDepth);

    vec3 scatterLight = scatter(totalCoeff, opticalDepthLight);
    vec3 absorbLight = absorb(totalCoeff, opticalDepthLight);

    vec3 absorbSun = d02(absorbLight - absorbView) / d02((scatterLight - scatterView) * ln2);

    vec3 mieScatter = scatter(mieCoeff, opticalDepth) * 0.25;
    vec3 rayleighScatter = scatter(rayleighCoeff, opticalDepth) * 0.375;

    vec3 scatterSun = mieScatter + rayleighScatter;

    return (scatterSun * absorbSun) * sunBrightness;
}



// Gold Noise ©2015 dcerisano@standard3d.com
//random value 0 to 1
float PHI = 1.61803398874989484820459;  // Φ = Golden Ratio   
float gold_noise(vec2 xy, float seed) {
    return fract(tan(distance(xy * PHI, xy) * seed) * xy.x);
}



vec3 permute(vec3 x) { return mod(((x * 34.0) + 1.0) * x, 289.0); }

float snoise(vec2 v) {

    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
        -0.577350269189626, 0.024390243902439);
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
        + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy),
        dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);

}




float Get3DNoise(vec3 pos)
{
    float p = floor(pos.z);
    float f = pos.z - p;

    const float invNoiseRes = 1.0 / 64.0;

    float zStretch = 17.0 * invNoiseRes;

    vec2 coord = pos.xy * invNoiseRes + (p * zStretch);

    //vec2 noise = vec2(texture(iChannel0, coord).x,
    //    texture(iChannel0, coord + zStretch).x);

    vec2 noise;
    //noise[0] = 0;
    //noise[1] = 0;
    noise[0] = snoise(coord * 20.0) * 2.0;
    noise[1] = snoise((coord + zStretch * 1) * 20.0) * 2.0;

    for (int i = 0; i < 2; i++) {
        if (noise[i] > 1) {
            noise[i] = 1;
        }
    }

    //noise[0] = gold_noise(coord, 1);
    //noise[1] = gold_noise(coord + zStretch, 1);


    return mix(noise.x, noise.y, f);
}

float getClouds(vec3 p)
{
    p = vec3(p.x, length(p + vec3(0.0, earthRadius, 0.0)) - earthRadius, p.z);

    if (p.y < cloudMinHeight || p.y > cloudMaxHeight)
        return 0.0;

    //float time = iTime * cloudSpeed;
    float time = current_time * cloudSpeed;
    vec3 movement = vec3(time, 0.0, time);

    vec3 cloudCoord = (p * 0.001) + movement;

    float noise = Get3DNoise(cloudCoord) * 0.5;
    noise += Get3DNoise(cloudCoord * 2.0 + movement) * 0.25;
    noise += Get3DNoise(cloudCoord * 7.0 - movement) * 0.125;
    noise += Get3DNoise((cloudCoord + movement) * 16.0) * 0.0625;

    const float top = 0.004;
    const float bottom = 0.01;

    float horizonHeight = p.y - cloudMinHeight;
    float treshHold = (1.0 - exp2(-bottom * horizonHeight)) * exp2(-top * horizonHeight);

    float clouds = smoothstep(0.55, 0.6, noise);
    clouds *= treshHold;

    return clouds * cloudDensity;
}

float getCloudShadow(vec3 p, positionStruct pos)
{
    const int steps = volumetricLightShadowSteps;
    float rSteps = cloudThickness / float(steps) / abs(pos.sunVector.y);

    vec3 increment = pos.sunVector * rSteps;
    vec3 position = pos.sunVector * (cloudMinHeight - p.y) / pos.sunVector.y + p;

    float transmittance = 0.0;

    for (int i = 0; i < steps; i++, position += increment)
    {
        transmittance += getClouds(position);
    }

    return exp2(-transmittance * rSteps);
}

float getSunVisibility(vec3 p, positionStruct pos)
{
    const int steps = cloudShadowingSteps;
    const float rSteps = cloudThickness / float(steps);

    vec3 increment = pos.sunVector * rSteps;
    vec3 position = increment * 0.5 + p;

    float transmittance = 0.0;

    for (int i = 0; i < steps; i++, position += increment)
    {
        transmittance += getClouds(position);
    }

    return exp2(-transmittance * rSteps);
}

float phase2Lobes(float x)
{
    const float m = 0.6;
    const float gm = 0.8;

    float lobe1 = hgPhase(x, 0.8 * gm);
    float lobe2 = hgPhase(x, -0.5 * gm);

    return mix(lobe2, lobe1, m);
}

vec3 getVolumetricCloudsScattering(float opticalDepth, float phase, vec3 p, vec3 sunColor, vec3 skyLight, positionStruct pos)
{
    float intergal = calculateScatterIntergral(opticalDepth, 1.11);

    float beersPowder = powder(opticalDepth * log(2.0));

    vec3 sunlighting = (sunColor * getSunVisibility(p, pos) * beersPowder) * phase * hPi * sunBrightness;
    vec3 skylighting = skyLight * 0.25 * rPi;

    return (sunlighting + skylighting) * intergal * pi;
}

float getHeightFogOD(float height)
{
    const float falloff = 0.001;

    return exp2(-height * falloff) * fogDensity;
}

vec3 getVolumetricLightScattering(float opticalDepth, float phase, vec3 p, vec3 sunColor, vec3 skyLight, positionStruct pos)
{
    float intergal = calculateScatterIntergral(opticalDepth, 1.11);

    vec3 sunlighting = sunColor * phase * hPi * sunBrightness;
    sunlighting *= getCloudShadow(p, pos);
    vec3 skylighting = skyLight * 0.25 * rPi;

    return (sunlighting + skylighting) * intergal * pi;
}

vec3 calculateVolumetricLight(positionStruct pos, vec3 color, float dither, vec3 sunColor)
{
#ifndef VOLUMETRIC_LIGHT
    return color;
#endif

    const int steps = volumetricLightSteps;
    const float iSteps = 1.0 / float(steps);

    vec3 increment = pos.worldVector * cloudMinHeight / clamp(pos.worldVector.y, 0.1, 1.0) * iSteps;
    vec3 rayPosition = increment * dither;

    float stepLength = length(increment);

    vec3 scattering = vec3(0.0);
    vec3 transmittance = vec3(1.0);

    float lDotW = dot(pos.sunVector, pos.worldVector);
    float phase = hgPhase(lDotW, 0.8);

    vec3 skyLight = calcAtmosphericScatterTop(pos);

    for (int i = 0; i < steps; i++, rayPosition += increment)
    {
        float opticalDepth = getHeightFogOD(rayPosition.y) * stepLength;

        if (opticalDepth <= 0.0)
            continue;

        scattering += getVolumetricLightScattering(opticalDepth, phase, rayPosition, sunColor, skyLight, pos) * transmittance;
        transmittance *= exp2(-opticalDepth);
    }

    return color * transmittance + scattering;
}

vec3 calculateVolumetricClouds(positionStruct pos, vec3 color, float dither, vec3 sunColor)
{
    const int steps = volumetricCloudSteps;
    const float iSteps = 1.0 / float(steps);

    //if (pos.worldVector.y < 0.0)
     //   return color;

    float bottomSphere = rsi(vec3(0.0, 1.0, 0.0) * earthRadius, pos.worldVector, earthRadius + cloudMinHeight).y;
    float topSphere = rsi(vec3(0.0, 1.0, 0.0) * earthRadius, pos.worldVector, earthRadius + cloudMaxHeight).y;

    vec3 startPosition = pos.worldVector * bottomSphere;
    vec3 endPosition = pos.worldVector * topSphere;

    vec3 increment = (endPosition - startPosition) * iSteps;
    vec3 cloudPosition = increment * dither + startPosition;

    float stepLength = length(increment);

    vec3 scattering = vec3(0.0);
    float transmittance = 1.0;

    float lDotW = dot(pos.sunVector, pos.worldVector);
    float phase = phase2Lobes(lDotW);

    vec3 skyLight = calcAtmosphericScatterTop(pos);

    for (int i = 0; i < steps; i++, cloudPosition += increment)
    {
        float opticalDepth = getClouds(cloudPosition) * stepLength;

        if (opticalDepth <= 0.0)
            continue;

        scattering += getVolumetricCloudsScattering(opticalDepth, phase, cloudPosition, sunColor, skyLight, pos) * transmittance;
        transmittance *= exp2(-opticalDepth);
    }

    return mix(color * transmittance + scattering, color, clamp(length(startPosition) * 0.00001, 0.0, 1.0));
}

vec3 robobo1221Tonemap(vec3 color)
{
#define rTOperator(x) (x / sqrt(x*x+1.0))

    float l = length(color);

    color = mix(color, color * 0.5, l / (l + 1.0));
    color = rTOperator(color);

    return color;
}

void main()
{

    vec2 fragCoord;
    fragCoord[0] = (frag_coord[0] / 2 + 0.5);
    fragCoord[1] = (frag_coord[1] / 2 + 0.5);
    //fragCoord[0] = frag_coord[0];
    //fragCoord[1] = frag_coord[1];

    vec3 iResolution;
    iResolution[0] = 1;
    iResolution[1] = 1;

    vec3 iMouse;
    iMouse[0] = 0.0;
    iMouse[1] = 0.0;

    gatherPositions(pos, fragCoord, iMouse.xy, iResolution.xy);

    float dither = bayer16(fragCoord);

    vec3 lightAbsorb = vec3(0.0);

    vec3 color = vec3(0.0);
    color = calcAtmosphericScatter(pos, lightAbsorb);
    color = calculateVolumetricClouds(pos, color, dither, lightAbsorb);
    color = calculateVolumetricLight(pos, color, dither, lightAbsorb);
    color = pow(color, vec3(1.0 / 2.2));
    color = robobo1221Tonemap(color);
    final_color = vec4(color, 1.0);


    //float more_noise;
    //more_noise = snoise(fragCoord * 25);
    //final_color = vec4(more_noise, more_noise, more_noise, 1);

    
}