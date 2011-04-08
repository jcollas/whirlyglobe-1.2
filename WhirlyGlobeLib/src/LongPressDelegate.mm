//
//  LongPressDelegate.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 3/22/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "LongPressDelegate.h"
#import "EAGLView.h"
#import "SceneRendererES1.h"
#import "GlobeMath.h"

@implementation WhirlyGlobeLongPressDelegate

- (id)initWithGlobeView:(WhirlyGlobeView *)inView
{
    if ((self = [super init]))
    {
        globeView = inView;
    }
    
    return self;
}

+ (WhirlyGlobeLongPressDelegate *)longPressDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView
{
    WhirlyGlobeLongPressDelegate *pressDelegate = [[[WhirlyGlobeLongPressDelegate alloc] initWithGlobeView:globeView] autorelease];
    [view addGestureRecognizer:[[[UILongPressGestureRecognizer alloc]
                                 initWithTarget:pressDelegate action:@selector(pressAction:)]
                                autorelease]];
    return pressDelegate;
}

// Called for a tap
- (void)pressAction:(id)sender
{
	UILongPressGestureRecognizer *press = sender;
	EAGLView *glView = (EAGLView *)press.view;
	SceneRendererES1 *sceneRender = glView.renderer;
    
    if (press.state == UIGestureRecognizerStateBegan)
    {
        // Translate that to the sphere
        // If we hit, then we'll generate a message
        Point3f hit;
        Eigen::Transform3f theTransform = [globeView calcModelMatrix];
        if ([globeView pointOnSphereFromScreen:[press locationOfTouch:0 inView:nil] transform:&theTransform frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&hit])
        {
            TapMessage *msg = [[[TapMessage alloc] init] autorelease];
            [msg setWorldLoc:hit];
            [msg setWhereGeo:WhirlyGlobe::GeoFromPoint(hit)];
            msg.heightAboveGlobe = globeView.heightAboveGlobe;
            
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:WhirlyGlobeLongPressMsg object:msg]];
        }
    }
}

@end
