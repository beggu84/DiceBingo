/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Implementation of our platform independent renderer class, which performs Metal setup and per frame rendering
 */

@import simd;
@import MetalKit;

#import "Renderer.h"

// Header shared between C code here, which executes Metal API commands, and .metal files, which
//   uses these types as inputs to the shaders
#import "ShaderTypes.h"

#import "Math.h"
#import "Scene.h"
#import "Node.h"

#define DEGREE_TO_RADIAN(x) (x) * (M_PI / 180.0f)

static const int BOX_SIZE_IN_A_LINE = 4;
static const float BOX_LENGTH = 4.0f;

// Main class performing the rendering
@implementation Renderer
{
    // The device (aka GPU) we're using to render
    id<MTLDevice> _device;
    
    // Our render pipeline composed of our vertex and fragment shaders in the .metal shader file
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLDepthStencilState> _depthStencilState;
    id<MTLSamplerState> _samplerState;
    
    // The command Queue from which we'll obtain command buffers
    id<MTLCommandQueue> _commandQueue;
    
    // The current size of our view so we can use this in our render pipeline
    vector_uint2 _viewportSize;
    
    float _cameraDepth;
    matrix_float4x4 _viewMatrix;
    matrix_float4x4 _projectionMatrix;
    
    id<MTLBuffer> _diceVertexBuffer;
    id<MTLBuffer> _diceIndexBuffer;
    id<MTLTexture> _diceTexture;
    
    Scene *_scene;
}

/// Initialize with the MetalKit view from which we'll obtain our Metal device
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView {
    self = [super init];
    if(self) {
        _device = mtkView.device;
        [self loadMetalWithView:mtkView];
        [self loadAssets];
        [self setupUniforms];
        [self buildScene];
    }
    
    return self;
}

- (void)loadMetalWithView:(nonnull MTKView *)view; {
    NSError *error = NULL;
    
    // Load all the shader files with a .metal file extension in the project
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    
    // Load the vertex function from the library
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    
    // Load the fragment function from the library
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
    // Configure a pipeline descriptor that is used to create a pipeline state
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Simple Pipeline";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
    pipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat;
    
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                             error:&error];
    if (!_pipelineState) {
        // Pipeline State creation could fail if we haven't properly set up our pipeline descriptor.
        //  If the Metal API validation is enabled, we can find out more information about what
        //  went wrong.  (Metal API validation is enabled by default when a debug build is run
        //  from Xcode)
        NSLog(@"Failed to created pipeline state, error %@", error);
        return;
    }
    
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthStencilState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    
    MTLSamplerDescriptor *samplerDescriptor;
    samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
    samplerDescriptor.normalizedCoordinates = true;
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.mipFilter = MTLSamplerMipFilterLinear;
    _samplerState = [_device newSamplerStateWithDescriptor:samplerDescriptor];
    
    // Create the command queue
    _commandQueue = [_device newCommandQueue];
}

- (void)loadAssets {
    // dice vertices
    const float len = BOX_LENGTH / 2;
    const float fix = len;
    const Vertex triangleVertices[] = {
        // front
        { { -len, -len, fix }, { 1, 0, 0, 1 }, { 0, 1 } }, // 0
        { { len, -len, fix }, { 0, 1, 0, 1 }, { 0.333, 1 } }, // 1
        { { len, len, fix }, { 0, 0, 1, 1 }, { 0.333, 0.667 } }, // 2
        { { -len, len, fix }, { 1, 1, 0, 1 }, { 0, 0.667 } }, // 3
        // back
        { { len, -len, -fix }, { 1, 0, 0, 1 }, { 0.667, 1 } }, // 4
        { { -len, -len, -fix }, { 0, 1, 0, 1 }, { 1, 1 } }, // 5
        { { -len, len, -fix }, { 0, 0, 1, 1 }, { 1, 0.667 } }, // 6
        { { len, len, -fix }, { 1, 1, 0, 1 }, { 0.667, 0.667 } }, // 7
        // top
        { { -len, fix, len }, { 1, 0, 0, 1 }, { 0.334, 1 } }, // 8
        { { len, fix, len }, { 0, 1, 0, 1 }, { 0.666, 1 } }, // 9
        { { len, fix, -len }, { 0, 0, 1, 1 }, { 0.666, 0.667 } }, // 10
        { { -len, fix, -len }, { 1, 1, 0, 1 }, { 0.334, 0.667 } }, // 11
        // bottom
        { { -len, -fix, -len }, { 1, 0, 0, 1 }, { 0, 0.666 } }, // 12
        { { len, -fix, -len }, { 0, 1, 0, 1 }, { 0.333, 0.666 } }, // 13
        { { len, -fix, len }, { 0, 0, 1, 1 }, { 0.333, 0.334 } }, // 14
        { { -len, -fix, len }, { 1, 1, 0, 1 }, { 0, 0.334 } }, // 15
        // left
        { { -fix, -len, -len }, { 1, 0, 0, 1 }, { 0.334, 0.666 } }, // 16
        { { -fix, -len, len }, { 0, 1, 0, 1 }, { 0.666, 0.666 } }, // 17
        { { -fix, len, len }, { 0, 0, 1, 1 }, { 0.666, 0.334 } }, // 18
        { { -fix, len, -len }, { 1, 1, 0, 1 }, { 0.334, 0.334 } }, // 19
        // right
        { { fix, -len, len }, { 1, 0, 0, 1 }, { 0.667, 0.666 } }, // 20
        { { fix, -len, -len }, { 0, 1, 0, 1 }, { 1, 0.666 } }, // 21
        { { fix, len, -len }, { 0, 0, 1, 1 }, { 1, 0.334 } }, // 22
        { { fix, len, len }, { 1, 1, 0, 1 }, { 0.667, 0.334 } }, // 23
    };
    
    _diceVertexBuffer = [_device newBufferWithBytes:triangleVertices
                                             length:sizeof(triangleVertices)
                                            options:MTLResourceStorageModeShared];
    
    // dice indices
    const short triangleIndices[] = {
        // front
        0, 1, 2,
        0, 2, 3,
        // back
        4, 5, 6,
        4, 6, 7,
        // top
        8, 9, 10,
        8, 10, 11,
        // bottom
        12, 13, 14,
        12, 14, 15,
        // left
        16, 17, 18,
        16, 18, 19,
        // right
        20, 21, 22,
        20, 22, 23,
    };
    
    _diceIndexBuffer = [_device newBufferWithBytes:triangleIndices
                                            length:sizeof(triangleIndices)
                                           options:MTLResourceStorageModeShared];
    
    // dice texture
    MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
    
    NSDictionary *textureLoaderOptions = @{
                                           MTKTextureLoaderOptionTextureUsage: @(MTLTextureUsageShaderRead),
                                           MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
                                           };
    
    NSError *error = NULL;
    _diceTexture = [textureLoader newTextureWithName:@"DiceTexture"
                                         scaleFactor:1.0
                                              bundle:nil
                                             options:textureLoaderOptions
                                               error:&error];
    if(!_diceTexture || error) {
        NSLog(@"Error creating texture %@", error.localizedDescription);
    }
}

- (void)setupUniforms {
    _cameraDepth = 50;
    _viewMatrix = matrix4x4_translation(0, 0.0, -_cameraDepth);
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    float aspect = bounds.size.width / (float)bounds.size.height;
    _projectionMatrix = matrix_perspective_right_hand(60.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
}

- (void)buildScene {
    _scene = [[Scene alloc] init];
    
    Node *boxGroupNode = [[Node alloc] initWithName:@"BoxGroup"];
    boxGroupNode.modelMatrix = matrix4x4_identity();
    boxGroupNode.hasMesh = false;
    
    for (int row = 0; row < BOX_SIZE_IN_A_LINE; ++row) {
        for (int col = 0; col < BOX_SIZE_IN_A_LINE; ++col) {
            int index = row * BOX_SIZE_IN_A_LINE + col;
            NSString *nodeName = [NSString stringWithFormat:@"Box%d", index];
            Node *boxNode = [[Node alloc] initWithName:nodeName];
            boxNode.hasMesh = true;
            [boxGroupNode.children addObject:boxNode];
        }
    }
    [_scene.roots addObject:boxGroupNode];
    
    // 2. compute screen size
    // 화면 pixel 사이즈를 구해서 min(0,0)과 max(width,height)를 world coordinate로 변환
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    //vector_float4 worldMinPos = [self screenToWorldPosition:(vector_float2){ 0, 0 }];
    vector_float4 worldMaxPos = [self screenToWorldPosition:(vector_float2){ screenBounds.size.width, screenBounds.size.height }];
    float worldWidth = worldMaxPos[0] * 2;
    float totalBoxAreaPropotion = 0.7f;
    //float markerAreaPropotion = 1 - totalBoxAreaPropotion;
    float totalBoxAreaWidth = worldWidth * totalBoxAreaPropotion;
    
    // 3. compute box size
    float boxDiagonalLength = BOX_LENGTH * sqrt(2.0f);
    float boxAreaLength = totalBoxAreaWidth / BOX_SIZE_IN_A_LINE;
    float boxScale = boxAreaLength / boxDiagonalLength;
    
    // 4. transform cubes
    float centerIndex = (BOX_SIZE_IN_A_LINE - 1) / 2.0f;
    
    for (int row = 0; row < BOX_SIZE_IN_A_LINE; ++row) {
        for (int col = 0; col < BOX_SIZE_IN_A_LINE; ++col) {
            int index = row * BOX_SIZE_IN_A_LINE + col;
            Node* boxNode = boxGroupNode.children[index];
            
            float rowDiff = row - centerIndex;
            float colDiff = col - centerIndex;
            
            matrix_float4x4 translation = matrix4x4_translation(colDiff * boxAreaLength, rowDiff * boxAreaLength, 0.0);
            matrix_float4x4 scaling = matrix4x4_uniform_scaling(boxScale);
            boxNode.modelMatrix = matrix_multiply(translation, scaling);
            
            if (index % 2 == 1) {
                matrix_float4x4 rotation = matrix4x4_rotation_around_x(DEGREE_TO_RADIAN(90.0f));
                boxNode.modelMatrix = matrix_multiply(boxNode.modelMatrix, rotation);
            }
        }
    }
}

- (vector_float4)screenToWorldPosition:(vector_float2)screenPos {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    vector_float4 ndcPos = { screenPos[0] / screenBounds.size.width * 2 - 1, 1 - (screenPos[1] / screenBounds.size.height * 2), 0, 1 };
    vector_float4 clipPos = vector4_scalar_multipy(ndcPos, _cameraDepth);
    
    matrix_float4x4 mvpMatrix = matrix_multiply(_projectionMatrix, _viewMatrix);
    matrix_float4x4 inverseMvpMatrix = simd_inverse(mvpMatrix);
    return matrix_multiply(clipPos, inverseMvpMatrix);
}

/// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    // Save the size of the drawable as we'll pass these
    //   values to our vertex shader when we draw
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

/// Called whenever the view needs to render a frame
- (void)drawInMTKView:(nonnull MTKView *)view {
    // Create a new command buffer for each render pass to the current drawable
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    // Obtain a renderPassDescriptor generated from the view's drawable textures
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if(renderPassDescriptor != nil) {
        // Create a render command encoder so we can render into something
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";
        
        [renderEncoder pushDebugGroup:@"DrawBox"];
        
        // Set the region of the drawable to which we'll draw.
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
        
        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthStencilState];
        
        for (Node *root in _scene.roots) {
            [self drawNodeRecursive:root
                    parentTransform:matrix4x4_identity()
                      renderEncoder:renderEncoder];
        }
        
        [renderEncoder popDebugGroup];
        
        [renderEncoder endEncoding];
        
        // Schedule a present once the framebuffer is complete using the current drawable
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

- (void)drawNodeRecursive:(Node*)node
          parentTransform:(matrix_float4x4)parentTransform
            renderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder {
    
    matrix_float4x4 modelMatrix = matrix_multiply(parentTransform, node.modelMatrix);
    
    if (node.hasMesh) {
        Uniforms uniforms;
        uniforms.modelViewMatrix = matrix_multiply(_viewMatrix, modelMatrix);
        uniforms.projectionMatrix = _projectionMatrix;
        
        [renderEncoder setVertexBuffer:_diceVertexBuffer
                                offset:0
                               atIndex:BufferIndexVertices];
        
        [renderEncoder setVertexBytes:&uniforms
                               length:sizeof(uniforms)
                              atIndex:BufferIndexUniforms];
        
        [renderEncoder setFragmentTexture:_diceTexture
                                  atIndex:TextureIndexColor];
        [renderEncoder setFragmentSamplerState:_samplerState
                                       atIndex:TextureIndexColor];
        
        [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                  indexCount:_diceIndexBuffer.length / sizeof(short)
                                   indexType:MTLIndexTypeUInt16
                                 indexBuffer:_diceIndexBuffer
                           indexBufferOffset:0];
    }
    
    for (Node *child in node.children) {
        [self drawNodeRecursive:child
                parentTransform:modelMatrix
                  renderEncoder:renderEncoder];
    }
}

#pragma gesture event

-(void)tappedWithPoint:(CGPoint)point {
    NSLog(@"tappedWithPoint - point: %f, %f", point.x, point.y);
}

-(void)draggingWithPoint:(CGPoint)delta {
    NSLog(@"draggingWithPoint - delta: %f, %f", delta.x, delta.y);
}

-(void)draggedWithPoint:(CGPoint)delta {
    NSLog(@"draggedWithPoint - delta: %f, %f", delta.x, delta.y);
}

@end
