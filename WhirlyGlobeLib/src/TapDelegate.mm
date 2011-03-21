/*
 *  TapDelegate.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/3/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "TapDelegate.h"
#import "EAGLView.h"
#import "SceneRendererES1.h"
#import "GlobeMath.h"

@implementation WhirlyGlobeTapDelegate

- (id)initWithGlobeView:(WhirlyGlobeView *)inView
{
	if (self = [super init])
	{
		globeView = inView;
	}
	
	return self;
}

+ (WhirlyGlobeTapDelegate *)tapDelegateForView:(UIView *)view globeView:(WhirlyGlobeView *)globeView
{
	WhirlyGlobeTapDelegate *tapDelegate = [[[WhirlyGlobeTapDelegate alloc] initWithGlobeView:globeView] autorelease];
	[view addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:tapDelegate action:@selector(tapAction:)] autorelease]];
	return tapDelegate;
}

// Called for a tap
- (void)tapAction:(id)sender
{
	UITapGestureRecognizer *tap = sender;
	EAGLView *glView = (EAGLView *)tap.view;
	SceneRendererES1 *sceneRender = glView.renderer;

	// Location on the screen
	CGPoint pt = [tap locationOfTouch:0 inView:nil];
	
	// Translate that to the sphere
	// If we hit, then we'll generate a message
	Point3f hit;
	Eigen::Transform3f theTransform = [globeView calcModelMatrix];
	if ([globeView pointOnSphereFromScreen:[tap locationOfTouch:0 inView:nil] transform:&theTransform frameSize:Point2f(sceneRender.framebufferWidth,sceneRender.framebufferHeight) hit:&hit])
	{
		TapMessage *msg = [[[TapMessage alloc] init] autorelease];
		[msg setWorldLoc:hit];
		[msg setWhereGeo:WhirlyGlobe::GeoFromPoint(hit)];
		
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:WhirlyGlobeTapMsg object:msg]];
	}
}

@end
