//
//  PanDelegateFixed.m
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 4/28/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "PanDelegateFixed.h"

@implementation PanDelegateFixed

- (id)initWithGlobeView:(WhirlyGlobeView *)inView
{
	if ((self = [super init]))
	{
		view = inView;
        rotType = RotNone;
	}
	
	return self;
}

+ (PanDelegateFixed *)panDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView
{
	PanDelegateFixed *panDelegate = [[[PanDelegateFixed alloc] initWithGlobeView:globeView] autorelease];
	[view addGestureRecognizer:[[[UIPanGestureRecognizer alloc] initWithTarget:panDelegate action:@selector(panAction:)] autorelease]];
	return panDelegate;
}

// Looking at how the user is moving, decide what kind of rotation we should be doing
- (void)determineState:(CGPoint)touchPt
{
}

// Called for pan actions
- (void)panAction:(id)sender
{
	UIPanGestureRecognizer *pan = sender;
	EAGLView *glView = (EAGLView *)pan.view;
	SceneRendererES1 *sceneRender = glView.renderer;
	
	if (pan.numberOfTouches > 1)
	{
        rotType = RotNone;
		return;
	}
    
	switch (pan.state)
	{
		case UIGestureRecognizerStateBegan:
		{
			[view cancelAnimation];
            
			// Save the first place we touched
			startTransform = [view calcModelMatrix];
			startQuat = view.rotQuat;
            startPoint = [pan locationOfTouch:0 inView:glView];
			if ([view pointOnSphereFromScreen:startPoint transform:&startTransform 
									frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&startOnSphere])
                // We'll start out letting them play with box axes
				rotType = RotFree;                
            else
                rotType = RotNone;
		}
			break;
		case UIGestureRecognizerStateChanged:
		{
			if (rotType != RotNone)
			{
				[view cancelAnimation];
                
				// Figure out where we are now
				Point3f hit;
                CGPoint touchPt = [pan locationOfTouch:0 inView:glView];
				[view pointOnSphereFromScreen:touchPt transform:&startTransform 
									frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&hit ];                
                
                // Figure out what sort of rotation to do
                [self determineState:touchPt];
                
				// This gives us a direction to rotate around
				// And how far to rotate
				Eigen::Quaternion<float> endRot;
				endRot.setFromTwoVectors(startOnSphere,hit);
                Eigen::Quaternion<float> newRotQuat = startQuat * endRot;

#if 0
                // We'd like to keep the north pole pointed up
                // So we look at where the north pole is going
                Vector3f northPole = (newRotQuat * Vector3f(0,0,1)).normalized();
                if (northPole.y() != 0.0)
                {
                    // We need to know where up (facing the user) will be
                    //  so we can rotate around that
                    Vector3f newUp = [WhirlyGlobeView prospectiveUp:newRotQuat];
                    
                    // Then rotate it back on to the YZ axis
                    // This will keep it upward
                    float ang = atanf(northPole.x()/northPole.y());
                    // However, the pole might be down now
                    // If so, rotate it back up
                    if (northPole.y() < 0.0)
                        ang += M_PI;
                    Eigen::AngleAxisf upRot(ang,newUp);
                    newRotQuat = newRotQuat * upRot;
                }
#endif
 
                [view setRotQuat:(newRotQuat)];
			}
		}
			break;
		case UIGestureRecognizerStateEnded:
            rotType = RotNone;
			break;
        default:
            break;
	}
}

@end
