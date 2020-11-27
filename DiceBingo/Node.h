#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface Node : NSObject

@property (readonly) NSString *name;
@property (weak, nullable) Node *parent;
@property NSMutableArray *children;
@property matrix_float4x4 modelMatrix;
@property BOOL hasMesh;

- (instancetype)initWithName:(NSString*)name;

@end

NS_ASSUME_NONNULL_END
