#import "Scene.h"
#import "Node.h"

@implementation Scene

- (instancetype)init {
    self = [super init];
    if (self) {
        _roots = [NSMutableArray array];
    }
    
    return self;
}

@end
