#import "TGModernImageViewModel.h"

#import "TGModernImageView.h"
#import "TGCommon.h"

@implementation TGModernImageViewModel

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self != nil)
    {
        _image = image;
    }
    return self;
}

- (Class)viewClass
{
    return [TGModernImageView class];
}

- (void)_updateViewStateIdentifier
{
    self.viewStateIdentifier = [[NSString alloc] initWithFormat:@"TGModernImageView/%lx", (long)_image];
}

- (void)bindViewToContainer:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage
{
    [self _updateViewStateIdentifier];
    
    [super bindViewToContainer:container viewStorage:viewStorage];
    
    TGModernImageView *view = (TGModernImageView *)[self boundView];
    if (!TGStringCompare(view.viewStateIdentifier, self.viewStateIdentifier))
        view.image = _image;
    
    view.extendedEdges = _extendedEdges;
}

- (void)drawInContext:(CGContextRef)context
{
    [super drawInContext:context];
    
    if (!self.skipDrawInContext && self.alpha > FLT_EPSILON)
        [_image drawInRect:self.bounds blendMode:_blendMode alpha:1.0f];
}

- (void)sizeToFit
{
    CGRect frame = self.frame;
    frame.size = _image.size;
    self.frame = frame;
}

@end
