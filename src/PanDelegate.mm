//
//  PanDelegate.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/18/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "PanDelegate.h"
#import "EAGLView.h"
#import "SceneRendererES1.h"
#import "PanDelegate.h"

@implementation WhirlyGlobePanDelegate

- (id)initWithGlobeView:(WhirlyGlobeView *)inView
{
	if (self = [super init])
	{
		view = inView;
	}
	
	return self;
}

+ (WhirlyGlobePanDelegate *)panDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView
{
	WhirlyGlobePanDelegate *panDelegate = [[[WhirlyGlobePanDelegate alloc] initWithGlobeView:globeView] autorelease];
	[view addGestureRecognizer:[[[UIPanGestureRecognizer alloc] initWithTarget:panDelegate action:@selector(panAction:)] autorelease]];
	return panDelegate;
}

// Called for pan actions
- (void)panAction:(id)sender
{
	UIPanGestureRecognizer *pan = sender;
	EAGLView *glView = (EAGLView *)pan.view;
	SceneRendererES1 *sceneRender = glView.renderer;
	
	if (pan.numberOfTouches > 1)
	{
		panning = NO;
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
			panning = NO;
			if ([view pointOnSphereFromScreen:[pan locationOfTouch:0 inView:nil] transform:&startTransform 
									frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&startOnSphere])
				panning = YES;

//			if (panning)
//				NSLog(@"Pan start: (%f,%f,%f)\n",startOnSphere.x(),startOnSphere.y(),startOnSphere.z());
		}
			break;
		case UIGestureRecognizerStateChanged:
		{
			if (panning)
			{
				[view cancelAnimation];

				// Figure out where we are now
				Point3f hit;
				[view pointOnSphereFromScreen:[pan locationOfTouch:0 inView:nil] transform:&startTransform 
									frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&hit ];
//				NSLog(@"Pan: (%f,%f,%f)\n",hit.x(),hit.y(),hit.z());

				// This gives us a direction to rotate around
				// And how far to rotate
				Eigen::Quaternion<float> thisRot;
				thisRot.setFromTwoVectors(startOnSphere,hit);
				[view setRotQuat:(startQuat * thisRot)];
			}
		}
			break;
		case UIGestureRecognizerStateEnded:
			panning = NO;
			break;
	}
}

@end
