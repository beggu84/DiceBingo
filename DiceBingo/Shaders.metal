/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Metal shaders used for this sample
 */

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands
#import "ShaderTypes.h"

// Vertex shader outputs and fragment shader inputs
typedef struct {
    // The [[position]] attribute of this member indicates that this value is the clip space
    // position of the vertex when this structure is returned from the vertex function
    float4 clipSpacePosition [[position]];
    
    // Since this member does not have a special attribute, the rasterizer interpolates
    // its value with the values of the other triangle vertices and then passes
    // the interpolated value to the fragment shader for each fragment in the triangle
    float4 color;
    
    float2 texCoord;
    
} RasterizerData;

// Vertex function
vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                                   constant Vertex *vertices [[buffer(BufferIndexVertices)]],
                                   constant Uniforms& uniforms [[buffer(BufferIndexUniforms)]]) {
    
    RasterizerData out;
    
    float4 position = float4(vertices[vertexID].position, 1);
    out.clipSpacePosition = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    
    out.color = vertices[vertexID].color;
    
    out.texCoord = vertices[vertexID].texCoord;
    
    return out;
}

// Fragment function
fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorMap [[texture(TextureIndexColor)]]) {
    
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    half4 colorSample = colorMap.sample(colorSampler, in.texCoord);
    
    return float4(colorSample);
}

