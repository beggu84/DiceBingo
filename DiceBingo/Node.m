#import "Node.h"

@implementation Node

- (instancetype)initWithName:(NSString*)name {
    self = [super init];
    if (self) {
        _name = name;
        _children = [NSMutableArray array];
    }
    
    return self;
}

@end
