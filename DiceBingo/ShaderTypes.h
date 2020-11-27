/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Header containing types and enum constants shared between Metal shaders and C/ObjC source
 */

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
typedef enum {
    BufferIndexVertices = 0,
    //BufferIndexViewportSize = 1,
    BufferIndexUniforms = 1
} VertexInputIndex;

typedef enum {
    TextureIndexColor = 0,
} TextureIndex;

typedef struct {
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} Uniforms;

//  This structure defines the layout of each vertex in the array of vertices set as an input to our
//    Metal vertex shader.  Since this header is shared between our .metal shader and C code,
//    we can be sure that the layout of the vertex array in our C code matches the layout that
//    our .metal vertex shader expects
typedef struct {
    // Positions in pixel space
    // (e.g. a value of 100 indicates 100 pixels from the center)
    //vector_float2 position;
    vector_float3 position;
    
    // Floating-point RGBA colors
    vector_float4 color;
    
    vector_float2 texCoord;
} Vertex;

#endif /* ShaderTypes_h */
