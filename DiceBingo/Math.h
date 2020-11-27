//
//  Math.h
//  DiceBingo
//
//  Created by Delisure1 on 2018. 10. 18..
//  Copyright © 2018년 wooki. All rights reserved.
//

#ifndef Math_h
#define Math_h

#include <simd/simd.h>

static inline vector_float4 vector4_scalar_multipy(vector_float4 vec, float scalar) {
    return (vector_float4) { vec[0] * scalar, vec[1] * scalar, vec[2] * scalar, vec[3] * scalar };
}

static inline matrix_float4x4 matrix4x4_identity() {
    return (matrix_float4x4) {{
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 1 }
    }};
}

static inline matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz) {
    return (matrix_float4x4) {{
        {  1,  0,  0, 0 },
        {  0,  1,  0, 0 },
        {  0,  0,  1, 0 },
        { tx, ty, tz, 1 }
    }};
}

static inline matrix_float4x4 matrix4x4_scaling(float sx, float sy, float sz) {
    return (matrix_float4x4) {{
        { sx,  0,  0, 0 },
        {  0, sy,  0, 0 },
        {  0,  0, sz, 0 },
        {  0,  0,  0, 1 }
    }};
}

static inline matrix_float4x4 matrix4x4_uniform_scaling(float s) {
    return matrix4x4_scaling(s, s, s);
}

static inline matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis) {
    axis = vector_normalize(axis);
    float ct = cosf(radians);
    float st = sinf(radians);
    float ci = 1 - ct;
    float x = axis.x, y = axis.y, z = axis.z;
    
    return (matrix_float4x4) {{
        { ct + x * x * ci,     y * x * ci + z * st, z * x * ci - y * st, 0},
        { x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0},
        { x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0},
        {                   0,                   0,                   0, 1}
    }};
}

static inline matrix_float4x4 matrix4x4_rotation_around_x(float radians) {
    float ct = cosf(radians);
    float st = sinf(radians);
    
    return (matrix_float4x4) {{
        { 1,   0,  0, 0 },
        { 0,  ct, st, 0 },
        { 0, -st, ct, 0 },
        { 0,   0,  0, 1 }
    }};
}

static inline matrix_float4x4 matrix4x4_rotation_around_y(float radians) {
    float ct = cosf(radians);
    float st = sinf(radians);
    
    return (matrix_float4x4) {{
        { ct, 0, -st, 0 },
        {  0, 1,   0, 0 },
        { st, 0,  ct, 0 },
        {  0, 0,   0, 1 }
    }};
}

static inline matrix_float4x4 matrix4x4_rotation_around_z(float radians) {
    float ct = cosf(radians);
    float st = sinf(radians);
    
    return (matrix_float4x4) {{
        {  ct, st,  0, 0 },
        { -st, ct,  0, 0 },
        {   0,  0,  1, 0 },
        {   0,  0,  0, 1 }
    }};
}

static inline matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ) {
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);
    
    return (matrix_float4x4) {{
        { xs,  0,          0,  0 },
        {  0, ys,          0,  0 },
        {  0,  0,         zs, -1 },
        {  0,  0, nearZ * zs,  0 }
    }};
}

#endif /* Math_h */
