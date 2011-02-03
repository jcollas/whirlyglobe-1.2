//
//  EAGLView.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/5/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "EAGLView.h"
#import <QuartzCore/QuartzCore.h>

@interface EAGLView ()
@property (nonatomic,retain) CADisplayLink *displayLink;
@end

@implementation EAGLView

@synthesize renderer;
@synthesize displayLink;

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)init
{
    self = [super init];
	if (self)
    {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
		
		animating = FALSE;
		frameInterval = 1;
    }
    
    return self;
}

- (void)dealloc
{    
	self.renderer = nil;
	self.displayLink = nil;
	
    [super dealloc];
}

- (NSInteger)frameInterval
{
    return frameInterval;
}

- (void)setFrameInterval:(NSInteger)newFrameInterval
{
    if (newFrameInterval >= 1)
    {
        frameInterval = newFrameInterval;
        
        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
        CADisplayLink *aDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
        [aDisplayLink setFrameInterval:frameInterval];
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
        
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
        animating = FALSE;
    }
}

- (void) drawView:(id)sender
{
    [renderer render];
}

- (void) setFrame:(CGRect)newFrame
{
	[super setFrame:newFrame];
}

- (void) layoutSubviews
{
	[renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

@end
