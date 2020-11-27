#import "GameViewController.h"
#import "Renderer.h"

@implementation GameViewController
{
    MTKView *_view;
    Renderer *_renderer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _view = (MTKView *)self.view;

    _view.device = MTLCreateSystemDefaultDevice();
    _view.backgroundColor = UIColor.blackColor;
    _view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    //_view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

    if(!_view.device) {
        NSLog(@"Metal is not supported on this device");
        self.view = [[UIView alloc] initWithFrame:self.view.frame];
        return;
    }

    _renderer = [[Renderer alloc] initWithMetalKitView:_view];

    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

    _view.delegate = _renderer;
    
    // touch event
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    //tapGestureRecognizer = self;
    [_view addGestureRecognizer:tapGestureRecognizer];
    //[tapGestureRecognizer requireGestureRecognizerToFail:doubleTap];
    
    UIPanGestureRecognizer *dragGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
    dragGestureRecognizer.maximumNumberOfTouches = 1;
    dragGestureRecognizer.minimumNumberOfTouches = 1;
    [_view addGestureRecognizer:dragGestureRecognizer];
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:recognizer.view];
    [_renderer tappedWithPoint:point];
}

- (IBAction)handleDrag:(UIPanGestureRecognizer *)recognizer {
    //CGPoint point = [recognizer locationInView:recognizer.view];
    CGPoint delta = [recognizer translationInView:recognizer.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [_renderer draggingWithPoint:delta];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [_renderer draggedWithPoint:delta];
    }
    
    //[recognizer setTranslation:CGPointZero inView:recognizer.view];
}

@end
