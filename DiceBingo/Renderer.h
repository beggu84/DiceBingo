#import <MetalKit/MetalKit.h>

// Our platform independent renderer class.   Implements the MTKViewDelegate protocol which
//   allows it to accept per-frame update and drawable resize callbacks.
@interface Renderer : NSObject <MTKViewDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

-(void)tappedWithPoint:(CGPoint)point;
-(void)draggingWithPoint:(CGPoint)delta;
-(void)draggedWithPoint:(CGPoint)delta;

@end

